;;; lastfm.el --- Last.fm API for Emacs Lisp -*- lexical-binding: t -*-

;; Copyright (C) 2019-2020 Mihai Olteanu

;; Author: Mihai Olteanu <mihai_olteanu@fastmail.fm>
;; Version: 1.2
;; Package-Version: 20211018.838
;; Package-Commit: b4b19f0aadc5087febeeb3f59944a89c4cdcf325
;; Package-Requires: ((emacs "26.1") (request "0.3.0") (anaphora "1.0.4") (memoize "1.1") (elquery "0.1.0") (s "1.12.0"))
;; Keywords: multimedia, api
;; URL: https://github.com/mihaiolteanu/lastfm.el/

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; lastfm.el provides a complete interface to the Last.fm API as defined by URL
;; `https://www.last.fm/api/'.  An API account, obtainable for free from
;; Last.fm, is needed to use the majority of provided services.  A one-time
;; authentication process is needed to access the rest of the methods.
;; 
;; Example usage to get the top tracks tagged as "rock" from last.fm, based on
;; user preferences,
;; 
;; (lastfm-tag-get-top-tracks "rock" :limit 3)
;; => (("Nirvana" "Smells Like Teen Spirit")
;;     ("The Killers" "Mr Brightside")
;;     ("Oasis" "Wonderwall"))
;; 
;; Or add a track to your list of loved songs,
;; 
;; (lastfm-track-love "anathema" "springfield")
;; => ("")

;; See the package URL for the full Last.fm API documentation.

;;; Code:

(require 'request)
(require 'cl-lib)
(require 'anaphora)
(require 'memoize)
(require 'elquery)
(require 'xdg)
(require 's)

(defgroup lastfm ()
  "Customize Last.fm API."
  :group 'music)

(defcustom lastfm-enable-doc-generation nil
  "If t, generate markdown documentation at load time.
Only used for development purposes."
  :type 'boolean
  :group 'lastfm)

(defconst lastfm--api-doc-string ""
  "Holds the documentation for all exported functions into this variable.
It is filled at load time by each `lastfm--defmethod' and saved in
README_api.md if `lastfm-enable-doc-generation' is t.")

;;;; Configuration and setup
(defconst lastfm--url "http://ws.audioscrobbler.com/2.0/"
  "The URL for the last.fm API version 2.")

(defconst lastfm--config-file-name "/.lastfmrc"
  "Name of the user config file for lastfm.")

(defconst lastfm--config-file-path nil
  "Complete path of the user config file for lastfm.")

;; The values of these configs are taken from the user config file.
(defconst lastfm--api-key nil)
(defconst lastfm--shared-secret nil)
(defconst lastfm--username nil)
(defconst lastfm--sk nil)

(defun lastfm--config-file ()
  "Return the config file or create it if it doesn't exits."
  (unless lastfm--config-file-path
    (let ((f (concat (xdg-config-home)
                     lastfm--config-file-name)))
      (unless (file-exists-p f)
        (message f)
        (with-temp-file f
          (insert "(CONFIG
  :API-KEY \"\"
  :SHARED-SECRET \"\"
  :USERNAME \"\")")))
      (setf lastfm--config-file-path f)))
  lastfm--config-file-path)

(defun lastfm--read-config-file ()
  "Return the config file contents as a Lisp object."
  (with-temp-buffer
    (insert-file-contents (lastfm--config-file))
    (read (buffer-string))))

(defun lastfm--set-config-parameters ()
  "Initialize the variables used by all Last.fm requests."
  (let ((config (cl-rest (lastfm--read-config-file))))
    (cl-mapcar (lambda (key value)
                 (pcase key
                   (:API-KEY       (setq lastfm--api-key value))
                   (:SHARED-SECRET (setq lastfm--shared-secret value))
                   (:USERNAME      (setq lastfm--username value))
                   (:SK            (setq lastfm--sk value))))
               (cl-remove-if #'stringp config)
               (cl-remove-if #'symbolp config))))

(defun lastfm--api-key ()
  "Return the api key or read it from the config file."
  (unless lastfm--api-key
    (lastfm--set-config-parameters))
  lastfm--api-key)

(defun lastfm--shared-secret ()
  "Return the shared secret or read it from the config file."
  (unless lastfm--shared-secret
    (lastfm--set-config-parameters))
  lastfm--shared-secret)

(defun lastfm--username ()
  "Return the username or read it from the config file."
  (unless lastfm--username
    (lastfm--set-config-parameters))
  lastfm--username)

(defun lastfm--sk ()
  "Return the session key or read it from the config file."
  (unless lastfm--sk
    (lastfm--set-config-parameters))
  lastfm--sk)

(defun lastfm-generate-session-key ()
  "Generate a session key and save it in the .lastfmrc file.
The user needs to grant Last.fm access to his/her application.
Both `lastfm-auth-get-token' and `lastfm-auth-get-session' methods used
here are generated with 'lastfm--defmethod'."
  ;; Reload after the user updated the empty .lastfmrc file.
  (lastfm--set-config-parameters)
  (let ((token (car (lastfm-auth-get-token))))
    ;; Ask the user to allow access.
    (browse-url (concat "http://www.last.fm/api/auth/?api_key="
                        (lastfm--api-key)
                        "&token=" token))
    (when (yes-or-no-p "Did you grant the application persmission
to access your Last.fm account? ")
      ;; If permission granted, get the sk and update the config file.
      (let* ((sk (car (lastfm-auth-get-session token)))
             (config (lastfm--read-config-file))
             (config-with-sk (append config (list :SK sk))))
        (with-temp-file (lastfm--config-file)
          (insert (prin1-to-string config-with-sk))))
      ;; Reload the file after the sk update.
      (lastfm--set-config-parameters)
      (message "Session Key succesfully saved in %s" (lastfm--config-file)))))

;;;; API methods definition.
(eval-and-compile
  (defun lastfm--api-fn-name (method)
    "Turn the METHOD into an API function name.
Example: artist.addTags -> lastfm-artist-add-tags"
    (intern
     (concat "lastfm-"
             (--reduce (concat acc "-" it)
                       (--map (downcase it)
                              (s-split-words (symbol-name method)))))))

  (defun lastfm--cleanup-query-string (str)
    "Transform the STR query string for doc purposes."
    (s-replace " " ""
               ;; Some queries contain ' > ' others only ' '. Replace
               ;; both of them with '-'.
               (if (s-contains-p ">" str)
                   (s-replace ">" "-" str)
                 (s-replace " " "-" str)))))

(defmacro lastfm--defmethod (name params docstring auth query-strings)
  "Build the lastfm API function with the given NAME.
This is the workhorse of this package and is used to build all
the API functions.

PARAMS are the function parameters and can be required parameters
or keyword parameters but without the &key keyword, but a list
of (param default_value) pairs.

DOCSTRING is used as the documentation string for the generated
function.

AUTH is passed along to the request method that needs to decide
what parameters to add to the last.fm request based on the type
of authentication needed for that method, and can be :no (no
authentication), :yes (the method requires authentication) or :sk
which is a special authentication method needed for obtaining the
session key(sk)).

QUERY-STRINGS are passed along to the parser to decide what to
extract and to build the request response."
  (declare (indent defun))
  (let* ((fn-name (lastfm--api-fn-name name))
         (required-params (cl-remove-if #'consp params))
         (keyword-params (cl-remove-if #'atom params))
         ;; Combine params to form a valid cl-defun signature.
         (all-params-cl (if keyword-params
                            `(,@required-params &key ,@keyword-params)
                          `(,@required-params)) )
         ;; Same as above, but without the &key keyword.
         (all-params (--map (if (consp it) (car it) it) params)))
    `(progn
       (cl-defun ,fn-name ,all-params-cl
         ,docstring
         ;; Send the request method to Last.fm and parse the response.
         (lastfm--parse-response
          (lastfm--request ,(symbol-name name)
                           ,auth ',all-params ,@all-params)
          ',query-strings))
       ;; Generate documentation for README.md.
       (setq lastfm--api-doc-string
             (concat lastfm--api-doc-string
                     (format "**%s** %s\n\n    %s\n    => %s\n\n"
                             (symbol-name ',fn-name)
                             ',all-params-cl ,docstring
                             ',(--map (lastfm--cleanup-query-string it)
                                      query-strings))))
       ;; Memoize, if possible.
       (when (eq ,auth :no)
         (condition-case nil
             (memoize #',fn-name)
           ;; Memoizing a function a second time returns an error.
           ;; Ignore the error and do nothing.
           (user-error nil))))))

(lastfm--defmethod album.getInfo (artist album)
  "Get the metadata and tracklist for an album on Last.fm using the album name."
  :no ("track artist name" "track > name" "duration"))

(lastfm--defmethod album.getTags (artist album)
  "Get the tags applied by an individual user to an album on Last.fm."
  :yes ("tag name" "tag count"))

(lastfm--defmethod album.getTopTags (artist album)
  "Get the top tags for an album on Last.fm, ordered by popularity."
  :no ("tag name" "tag count"))

(lastfm--defmethod album.removeTag (artist album tag)
  "Remove a user's tag from an album."
  :yes ("lfm"))

(lastfm--defmethod album.search (album (limit 10))
  "Search for an album by name. Returns album matches sorted by relevance."
  :no ("album artist" "album name"))

(lastfm--defmethod artist.addTags (artist tags)
  "Tag an artist with one or more user supplied tags."
  :yes ("lfm"))

(lastfm--defmethod artist.getCorrection (artist)
  "Check whether the artist has a correction to a canonical artist."
  :no ("artist name"))

(lastfm--defmethod artist.getInfo (artist)
  "Get the metadata for an artist. Includes biography, max 300 characters."
  :no ("bio summary" "listeners" "playcount" "similar artist name" "tags tag name"))

(lastfm--defmethod artist.getSimilar (artist (limit 10) (user (lastfm--username)))
  "Get all the artists similar to this artist."
  :no ("artist name"))

(lastfm--defmethod artist.getTags (artist)
  "Get the tags applied by an individual user to an artist on Last.fm."
  :yes ("tag name"))

(lastfm--defmethod artist.getTopAlbums (artist (limit 10))
  "Get the top albums for an artist, ordered by popularity."
  :no ("album > name"))

(lastfm--defmethod artist.getTopTags (artist)
  "Get the top tags for an artist, ordered by popularity."
  :no ("tag name"))

(lastfm--defmethod artist.getTopTracks (artist (limit 10) (page 1))
  "Get the top tracks by an artist, ordered by popularity."
  :no ("track artist name" "track > name" "playcount" "listeners"))

(lastfm--defmethod artist.removeTag (artist tag)
  "Remove a user's tag from an artist."
  :yes ("lfm"))

(lastfm--defmethod artist.search (artist (limit 10))
  "Search for an artist by name. Returns artist matches sorted by relevance."
  :no ("artist name"))

(lastfm--defmethod auth.getToken ()
  "Fetch a session key for a user (3rd step in the auth process)."
  :sk ("token"))

(lastfm--defmethod auth.getSession (token)
  "Fetch an unathorized request token (2nd step of the auth process)."
  :sk ("session key"))

(lastfm--defmethod chart.getTopArtists ((limit 10))
  "Get the top artists chart."
  :no ("artist name" "playcount" "listeners"))

(lastfm--defmethod chart.getTopTags ((limit 10))
  "Get the top tags chart."
  :no ("tag-name"))

(lastfm--defmethod chart.getTopTracks ((limit 10))
  "Get the top tracks chart."
  :no ("artist > name" "track > name" "playcount" "listeners"))

(lastfm--defmethod geo.getTopArtists (country (limit 10) (page 1))
  "Get the most popular artists on Last.fm by country."
  :no ("artist name" "playcount"))

(lastfm--defmethod geo.getTopTracks (country (limit 10) (page 1))
  "Get the most popular tracks on Last.fm last week by country."
  :no ("artist > name" "track > name" "playcount"))

(lastfm--defmethod library.getArtists ((user (lastfm--username)) (limit 50) (page 1))
  "A list of all the artists in a user's library."
  :no ("artist name" "playcount" "tagcount"))

(lastfm--defmethod tag.getInfo (tag)
  "Get the metadata for a TAG."
  :no ("tag summary"))

(lastfm--defmethod tag.getSimilar (tag)
  "Search for tags similar to this one, based on listening data."
  :no ("tag name"))

(lastfm--defmethod tag.getTopAlbums (tag (limit 10) (page 1))
  "Get the top albums tagged by this tag, ordered by tag count."
  :no ("artist > name" "album > name"))

(lastfm--defmethod tag.getTopArtists (tag (limit 10) (page 1))
  "Get the top artists tagged by this tag, ordered by tag count."
  :no ("artist name"))

(lastfm--defmethod tag.getTopTags ()
  "Fetches the top global tags on Last.fm, sorted by number of times used."
  :no ("tag name"))

(lastfm--defmethod tag.getTopTracks (tag (limit 10) (page 1))
  "Get the top tracks tagged by this tag, ordered by tag count."
  :no ("artist > name" "track > name"))

(lastfm--defmethod track.addTags (artist track tags)
  "Tag an album using a list of user supplied tags."
  :yes ("lfm"))

(lastfm--defmethod track.getCorrection (artist track)
  "Check whether the supplied track has a correction to a canonical track."
  :no ("artist > name" "track > name"))

(lastfm--defmethod track.getInfo (artist track)
  "Get the track metadata."
  :no ("album title" "tag name" "playcount" "listeners"))

(lastfm--defmethod track.getSimilar (artist track (limit 10))
  "Get similar tracks to this one, based on listening data."
  :no ("artist > name" "track > name"))

(lastfm--defmethod track.getTags (artist track)
  "Get the tags applied by an individual user to a track."
  :yes ("name"))

(lastfm--defmethod track.getTopTags (artist track)
  "Get the top tags for this track, ordered by tag count."
  :no ("name"))

(lastfm--defmethod track.love (artist track)
  "Love a track for a user profile."
  :yes ("lfm"))

(lastfm--defmethod track.removeTag (artist track tag)
  "Remove a user's tag from a track."
  :yes ("lfm"))

(lastfm--defmethod track.scrobble (artist track timestamp)
  "Add a track to the user listened tracks."
  :yes ("lfm"))

(lastfm--defmethod track.search (track (artist nil) (limit 10) (page 1))
  "Search for a track by track name. Returned matches are sorted by relevance."
  :no ("track > artist" "track > name"))

(lastfm--defmethod track.unlove (artist track)
  "UnLove a track for a user profile."
  :yes ("lfm"))

(lastfm--defmethod track.updateNowPlaying
  (artist track (album nil) (tracknumber nil) (context nil)
          (duration nil) (albumartist nil))
  "Notify Last.fm that a user has started listening to a track."
  :yes ("lfm"))

(lastfm--defmethod user.getfriends (user (limit 10) (page 1))
  "Get a list of the user's friends on Last.fm."
  :no ("name" "realname" "country" "age" "gender" "subscriber" "playcount"))

(lastfm--defmethod user.getInfo ((user (lastfm--username)))
  "Get information about a USER profile."
  :no ("name" "realname" "country" "age" "gender" "subscriber" "playcount"))

(lastfm--defmethod user.getLovedTracks ((user (lastfm--username)) (limit 10) (page 1))
  "Get the last LIMIT number of tracks loved by a USER."
  :no ("artist > name" "track > name"))

(lastfm--defmethod user.getPersonalTags
  (tag taggingtype (user (lastfm--username)) (limit 10) (page 1))
  "Get the user's personal TAGs."
  :no ("artist name"))

(lastfm--defmethod user.getRecentTracks
  ((user (lastfm--username)) (limit 10) (page 1) (from nil) (to nil) (extended 0))
  "Get a list of the recent tracks listened to by this user."
  :no ("track > artist" "track > name" "date"))

(lastfm--defmethod user.getTopAlbums
  ((user (lastfm--username)) (period nil) (limit nil) (page nil))
  "Get the top albums listened to by a user"
  :no ("artist > name" "album > name" "playcount"))

(lastfm--defmethod user.getTopArtists
  ((user (lastfm--username)) (period nil) (limit nil) (page nil))
  "Get the top artists listened to by a user."
  :no ("artist name" "playcount"))

(lastfm--defmethod user.getTopTags
  ((user (lastfm--username)) (limit 10))
  "Get the top tags used by this user."
  :no ("tag name"))

(lastfm--defmethod user.getTopTracks
  ((user (lastfm--username)) (period nil) (limit nil) (page nil))
  "Get the top tracks listened to by a user. "
  :no ("artist > name" "track > name" "playcount"))

(lastfm--defmethod user.getWeeklyAlbumChart
  ((user (lastfm--username)) (from nil) (to nil))
  "Get an album chart for a user profile, for a given date range."
  :no ("album > artist" "album > name" "playcount"))

(lastfm--defmethod user.getWeeklyArtistChart
  ((user (lastfm--username)) (from nil) (to nil))
  "Get an artist chart for a user profile, for a given date range."
  :no ("artist > name" "playcount"))

(lastfm--defmethod user.getWeeklyTrackChart
  ((user (lastfm--username)) (from nil) (to nil))
  "Get a track chart for a user profile, for a given date range."
  :no ("track > artist" "track > name" "playcount"))

(defun lastfm--group-params-for-signing (params)
  "Return all the PARAMS in one string.
The signing procedure for authentication needs all the parameters
and values lumped together in one big string without equal or
ampersand symbols between them."
  (let ((res ""))
    (mapc (lambda (s)
            (setf res (concat res (car s) (cdr s))))
          params)
    (concat res (lastfm--shared-secret))))

(defun lastfm--build-params (method auth params values)
  "Build the Last.fm POST request for the given METHOD.
METHOD is the Last.fm method in the request URL.  If AUTH is :yes
or :sk this method needs authentication, so the parameters need
to be group in alphabetical order, signed and the signature
appended at the end.  PARAMS are the parameters sent in the
request to Last.fm and are grouped, one by one, with the given
VALUES."
  (let ((result
         `(;; The api key and method is needed for all calls.
           ("api_key" . ,(lastfm--api-key))
           ("method" . ,method)
           ;; Pair the user supplied values with the method parameters.  If no
           ;; value supplied for a given param, do not include it in the
           ;; request, meaning, the default value specified by the Last.fm API
           ;; will be used instead.
           ,@(cl-remove-if #'null (cl-mapcar (lambda (param value)
                                        (when value
                                          (cons (symbol-name param) value)))
                                      params
                                      values)))))
    ;; The Session Key (SK) is needed for all auth services, but not for
    ;; the services used to actually obtain the SK.
    (when (eq auth :yes)
      (push `("sk" . ,(lastfm--sk)) result))
    ;; If the method needs authentication, then signing is necessary.
    (when (or (eq auth :sk)
              (eq auth :yes))
      ;; Params need to be in alphabetical order before signing.
      (setq result (cl-sort result #'string-lessp
                            :key #'cl-first))
      ;; Sign and append the signature.
      (alet (lastfm--group-params-for-signing result)
        (setq result (append result (list `("api_sig" . ,(md5 it)))))))
    result))

(defun lastfm--request (method auth params &rest values)
  "Send and return the Last.fm request for METHOD.
AUTH, PARAMS and VALUES are only passed allong to
'lastfm--build-params'.  See the documentation for that method."
  (let ((data (lastfm--build-params method auth params values)))    
    (if (eql auth :yes)
        (lastfm--post-request data)
      (lastfm--get-request data))))

(defun lastfm--post-request (data)
  "POST lastfm request for DATA."
  (let (resp)
    (request lastfm--url
             :type   "POST"
             :data   data
             :parser 'buffer-string             
             :sync   t
             :complete (cl-function
                        (lambda (&key data &allow-other-keys)
                          (setq resp data))))
    resp))

(defun lastfm--get-request (data)
  "GET lastfm request for DATA."  
  (let (resp)
    (request lastfm--url
             :params data
             :parser 'buffer-string
             :sync   t
             :complete (cl-function
                        (lambda (&key data &allow-other-keys)
                          (setq resp data))))
    resp))

(defun lastfm--parse-response (response query-strings)
  "Extract the relevant data from the RESPONSE.
Each string from the QUERY-STRINGS list of strings contains one
CSS selector to extract the given HTML elements from the Last.fm
RESPONSE string."
  (let ((raw-response (elquery-read-string response)))
    (awhen (s-present-p (elquery-text
                         (cl-first (elquery-$ "error" raw-response))))
      (error it))
    (let ((parsed-response
           ;; Parse the last.fm raw response with each of the query-strings
           ;; and extract the html text elements.
           (mapcar (lambda (query-str)
                     (reverse  ;Keep the original ordering.
                      (--map (elquery-text it)
                             (elquery-$ query-str raw-response))))
                   query-strings)))

      ;; Transform a response of the type '((artist1 artist2) (track1 track2))
      ;; into '((artist1 track1) (artist2 track2)).
      (if (cl-some (lambda (e)
                     (= (length e) 1))
                   parsed-response)
          ;; Responses with only one entry, such as artist-info, don't need to
          ;; be transformed but returned as a simple list of strings.
          (-flatten parsed-response)
        (if (= (length query-strings) 2)
            ;; Workaround for -zip returning a cons cell instead of
            ;; a list when only two lists are provided to it.
            (-zip-with #'list
                       (cl-first parsed-response)
                       (cl-second parsed-response))
          (apply #'-zip parsed-response))))))

;; Generate the README.md documentation, if needed.
(defun lastfm--generate-documentation (folder)
  "Generate and save the package documentation in the FOLDER.
Usually this step is done by the developer(s)."
  (when lastfm-enable-doc-generation
    ;; Save the api specification.
    (with-temp-file (expand-file-name "README_api.md" folder)
      (insert lastfm--api-doc-string))
    ;; Combine the api specification with the package overview.
    (with-temp-file (expand-file-name "README.md" folder)
      (insert-file-contents
       (expand-file-name "README_api.md" folder))
      (insert-file-contents
       (expand-file-name "README_overview.md" folder)))))

(lastfm--generate-documentation
 (if load-file-name
     ;; Package was evaluated by calling load.
     (file-name-directory load-file-name)
   ;; Package was evaluated by calling eval-buffer.
   default-directory))

(provide 'lastfm)

;; Keep for development purposes for now.
;; (add-to-list 'load-path "~/.emacs.d/lisp/lastfm")
;; (progn
;;   (unload-feature 'lastfm)
;;   (setq lastfm-enable-doc-generation t)
;;   (require 'lastfm))

;;; lastfm.el ends here

