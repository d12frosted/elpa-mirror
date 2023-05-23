;;; orgmdb.el --- An OMDb API client with some convenience functions -*- lexical-binding: t -*-

;; Copyright (C) 2021 Isa Mert Gurbuz

;; Author: Isa Mert Gurbuz <isamert@protonmail.com>
;; Version: 0.5
;; Package-Version: 20230522.1817
;; Package-Commit: 292a58b3bd19b61d24d897efefeee1a309a666fd
;; URL: https://github.com/isamert/orgmdb
;; Package-Requires: ((emacs "27.1") (dash "2.11.0") (s "1.12.0") (org "8.0.0"))

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

;; Tools for managing your watchlist in org-mode and some functions
;; for interacting with OMDb API.

;;; Code:

(require 's)
(require 'dash)
(require 'seq)
(require 'org)
(require 'json)

(defgroup orgmdb nil
  "An OMDb client and watchlist manager for `org-mode'."
  :group 'multimedia)

;;;###autoload
(defcustom orgmdb-omdb-apikey
  nil
  "OMDb API key."
  :type 'string
  :group 'orgmdb)

(defcustom orgmdb-video-dir
  (if (boundp 'empv-video-dir)
      empv-video-dir
    (or (getenv "XDG_VIDEOS_DIR") "~/Videos"))
  "A directory (or list of directories) containing your video collection.
Used while searching for video files for given title."
  :type '(choice (directory :tag "Video directory")
                 (list :tag "List of video directories"))
  :group 'orgmdb)

(defcustom orgmdb-video-file-extensions
  (if (boundp 'empv-video-file-extensions)
      empv-video-file-extensions
    '("mkv" "mp4" "avi" "mov"))
  "List of movie file extensions.
Used while searching for video files for given title."
  :type 'list
  :group 'orgmdb)

(defcustom orgmdb-player-function
  #'orgmdb-play
  "Player function to play given file."
  :type 'function
  :group 'orgmdb)

(defcustom orgmdb-fill-property-list
  '(genre runtime director imdb-id)
  "List of properties for `orgmdb-fill-movie-properties'.
When `orgmdb-fill-movie-properties' is called, these properties will be
  fetched and set to the headers property drawer.  Possible properties are:

- actors
- awards
- box-office
- country
- director
- dvd
- episode
- genre
- imdb
- imdb-id
- imdb-link
- imdb-rating
- imdb-votes
- language
- metacritic
- metascore
- play
- plot
- poster
- production
- rated
- released
- runtime
- season
- title
- tomatometer
- type
- website
- writer
- year

If you add `image' to this list, orgmdb will download and save
the movie poster into `orgmdb-poster-folder' and embed it right
under the header."
  :type 'list
  :group 'orgmdb)

(defcustom orgmdb-poster-folder
  "~/.cache"
  "Where should orgmdb download the poster files?"
  :type 'file
  :group 'orgmdb)

(defcustom orgmdb-type-prop nil
  "If non-nil use this property for entry type instead of tags."
  :type 'string
  :group 'orgmdb)

(defcustom orgmdb-upcase-properties t
  "If non-nil property names are inserted in upper case."
  :type 'bool
  :group 'orgmdb)

(defcustom orgmdb-imdb-link-format "[[https://www.imdb.com/title/%1$s][%1$s]]"
  "Format used when inserting imdb-link."
  :type 'string
  :group 'orgmdb)

;;;###autoload
(defvar orgmdb-omdb-url
  "https://www.omdbapi.com"
  "OMDb URL.")

(defvar orgmdb-show-tag "series")
(defvar orgmdb-movie-tag "movie")
(defvar orgmdb-episode-tag "episode")

(defvar orgmdb--movie-actions (make-hash-table :size 10))
(defvar orgmdb--show-actions (make-hash-table :size 10))
(defvar orgmdb--episode-actions (make-hash-table :size 10))

(defconst orgmdb--episode-matcher "[sS][0-9]\\{2\\}[eE][0-9]\\{2\\}")

(defconst orgmdb--types '("movie" "series" "episode"))

(defun orgmdb--url-retrieve-sync (url)
  "Retrieve URL synchronously as string."
  (with-current-buffer (url-retrieve-synchronously url)
    (let ((result (decode-coding-string (buffer-string) 'utf-8)))
      (kill-buffer)
      result)))

(defun orgmdb--request (url params)
  "Send a GET request to given URL and return the response body.
PARAMS should be an alist.  Pairs with nil values are skipped."
  (->> params
       (--filter (cadr it))
       (url-build-query-string)
       (format "%s/?%s" url)
       (orgmdb--url-retrieve-sync)
       (s-split "\n\n")
       (cadr)))

(cl-defun orgmdb--completing-read-object
    (prompt objects &key (formatter #'identity) category (sort? t) def multiple?)
  "`completing-read' with formatter and sort control.
Applies FORMATTER to every object in OBJECTS Also adds CATEGORY
metadata to each candidate, if given.  PROMPT passed to
`completing-read' as is."
  (let* ((object-table
          (make-hash-table :test 'equal :size (length objects)))
         (object-strings
          (mapcar
           (lambda (object)
             (let ((formatted-object (funcall formatter object)))
               (puthash formatted-object object object-table)))
           objects))
         (selected
          (funcall
           (if multiple? #'completing-read-multiple #'completing-read)
           (format "%s " prompt)
           (lambda (string predicate action)
             (if (eq action 'metadata)
                 `(metadata
                   ,(when category (cons 'category category))
                   ,@(unless sort?
                       '((display-sort-function . identity)
                         (cycle-sort-function . identity))))
               (complete-with-action
                action object-strings string predicate))))))
    (if multiple?
        (or (mapcar (lambda (it) (gethash it object-table)) selected) def)
      (gethash selected object-table def))))

;;;###autoload
(cl-defun orgmdb (&key title imdb year type season episode plot)
  "Search for a movie in OMDb with ARGS.

All parameters, TITLE IMDB YEAR TYPE SEASON EPISODE PLOT, are
optional but you need to provide at least one of TITLE or IMDB.

EPISODE can be a number or \\='all which makes this function to
retrieve all episode information for the show (not just for the
SEASON).

Examples:
  (orgmdb :title \"in the mood for love\")
  (orgmdb :title \"in the mood for love\" :year 2000)
  (orgmdb :title \"in the mood for love\" :type \\='movie)
  (orgmdb :imdb \"tt0118694\")
  (orgmdb :imdb \"tt10574558\" :season 1)
  (orgmdb :imdb \"tt10574558\" :season 1 :episode 3)
  (orgmdb :imdb \"tt0944947\" :episode \\='all)"
  (let* ((req-params
          `(("t" ,title)
            ("i" ,imdb)
            ("y" ,year)
            ("type" ,type)
            ("season" ,season)
            ("plot" ,plot)
            ("apikey" ,(s-trim orgmdb-omdb-apikey)))))
    (pcase episode
      ('all
       (let* ((response (json-read-from-string
                         (orgmdb--request orgmdb-omdb-url req-params)))
              (total-seasons (ignore-errors
                               (string-to-number (alist-get 'totalSeasons response))))
              (episodes '()))
         (if total-seasons
             (progn
               (dolist (current-season (number-sequence 1 total-seasons))
                 (setq
                  episodes
                  (seq-concatenate
                   json-array-type
                   episodes
                   (->>
                    (orgmdb--request orgmdb-omdb-url `(,@req-params ("season" ,current-season)))
                    (json-read-from-string)
                    (alist-get 'Episodes)
                    (seq-map (lambda (it) (map-insert it 'Season (number-to-string current-season))))))))
               (setq response (map-insert response 'Episodes episodes))
               (map-delete response 'Season))
           response)))
      (episode-no
       (json-read-from-string
        (orgmdb--request orgmdb-omdb-url `(,@req-params ("episode" ,episode-no))))))))

(defun orgmdb--get (f r &optional d)
  "Get key F from response R and default to D if F does not exist or is null/na."
  (let ((result (alist-get f r d)))
    (if (equal result "N/A")
        d
      result)))

(defun orgmdb--score-of (rating-type r)
  "Get RATING-TYPE from R.
Right now RATING-TYPE could be one of the following (as omdb API
only returns these):
- Internet Movie Database
- Rotten Tomatoes
- Metacritic"
  (->>
   (alist-get 'Ratings r)
   (seq-find (lambda (it) (s-equals? (alist-get 'Source it) rating-type)))
   (alist-get 'Value)))

(defmacro orgmdb--def-getters (&rest symbols)
  `(progn
     ,@(mapcar (lambda (sym)
                 `(defun ,(intern
                       (format "orgmdb-%s"
                               (s-join
                                "-"
                                (mapcar #'downcase (s-split-words (symbol-name sym))))))
                      (r &optional d)
                    ,(format "Get `%s' from OMBD response R and default to D if it does not exist." sym)
                    (orgmdb--get ',sym r d)))
               symbols)))

(orgmdb--def-getters
 Title Year Genre Rated Runtime
 Released imdbID imdbRating Poster Director
 Actors Plot Country Language imdbVotes
 DVD BoxOffice Production Website Awards
 Type Season Episode Metascore Writer)

;;;###autoload
(defun orgmdb-imdb-link (r &optional d)
  "Get imdb-id as a link in format `orgmdb-imdb-link-format'.
If there is an omdb response R, insert it for %s, else insert D."
  (format orgmdb-imdb-link-format (orgmdb--get 'imdbID r d)))

;;;###autoload
(defun orgmdb-imdb (r &optional d)
  "Get IMDb score from omdb response R and default to D if it does not exist.
The difference between this function and `orgmdb-imdb-rating' is
that this returns in the \"X/10\" format while
`orgmdb-imdb-rating' returns just \"X\"."
  (or (orgmdb--score-of "Internet Movie Database" r) d))

;;;###autoload
(defun orgmdb-metacritic (r &optional d)
  "Get metacritic score from omdb response R and default to D if it does not exist.
The difference between this function and `orgmdb-metascore' is
that this returns in the \"X/100\" format while
`orgmdb-metascore' returns just \"X\"."
  (or (orgmdb--score-of "Metacritic" r) d))

;;;###autoload
(defun orgmdb-tomatometer (r &optional d)
  "Get tomatometer score from R and default to D if it does not exist."
  (or (orgmdb--score-of "Rotten Tomatoes" r) d))

(defun orgmdb--episode-to-marker (episode)
  "Convert given EPISODE to S00E00 format."
  (format "S%02dE%02d"
          (string-to-number (orgmdb-season episode))
          (string-to-number (orgmdb-episode episode))))

(defun orgmdb--episode-to-title (episode)
  "Convert given EPISODE to `S00E00 - Title' format."
  (format "%s - %s"
          (orgmdb--episode-to-marker episode)
          (orgmdb-title episode)))

(defun orgmdb--ask-for-type ()
  "Simply ask for a type."
  (completing-read "Type: " orgmdb--types))

(defun orgmdb--ask-for-title-and-year ()
  "Simply ask for title and year from interactively."
  `(,(read-string "Title: ")
    ,(read-string "Year (can be empty): ")))

(defun orgmdb--detect-type-from-header ()
  "Detect whether current heading is a movie or a series or an episode."
  (let* ((type-prop (org-entry-get nil (or orgmdb-type-prop "TYPE")))
         (type-tag (--first (member it orgmdb--types) (org-get-tags))))
    (cond
     (type-tag type-tag)
     (type-prop type-prop)
     (t (orgmdb--ask-for-type)))))

(defun orgmdb--extract-imdb-id (str)
  (when str
    (when-let (match (s-match "tt[0-9]\\{7,8\\}" str))
      (car match))))

(defun orgmdb--detect-params-from-header ()
  "Get parameters for `orgmdb' function from current org header.
If not on a org header, simpy ask from user."
  (-let* ((header (or (org-entry-get nil "ITEM") ""))
          (imdb-id (or (orgmdb--extract-imdb-id header)
                       (orgmdb--extract-imdb-id (org-entry-get nil "IMDB-ID"))))
          (type (when (not imdb-id)
                  (orgmdb--detect-type-from-header)))
          ((title year) (when (not imdb-id)
                          (if (s-blank? header)
                              (orgmdb--ask-for-title-and-year)
                            (-if-let ((_ title year) (s-match "\\(.+\\)(\\([0-9]\\{4\\}\\))" header))
                                `(,(s-trim title) ,year)
                              `(,(s-trim (car (s-split "(" header)))))))))
    `(:imdb ,imdb-id :type ,type :title ,title :year ,year)))

(defun orgmdb-is-response-successful (response)
  "Check if the returned RESPONSE is successful or not."
  (not (string-equal (alist-get 'Response response) "False")))

(defun orgmdb--ensure-response-is-successful (response)
  (when (not (orgmdb-is-response-successful response))
    (user-error "The search did not return any results")))

(defun orgmdb--download (path url)
  "Download the image at the given URL and save it to the given PATH."
  (with-current-buffer (url-retrieve-synchronously url)
    (goto-char (point-min))
    (search-forward "\n\n")
    (delete-region (point-min) (point))
    (write-region nil nil path)
    (kill-buffer)))

(defun orgmdb--download-image-for (info)
  (let ((path (format "%s/orgmdb_poster_%s_%s.jpg"
                      orgmdb-poster-folder
                      (s-snake-case (orgmdb-title info))
                      (orgmdb-year info))))
    (unless (file-exists-p path)
      (orgmdb--download path (orgmdb-poster info)))
    path))

;;;###autoload
(defun orgmdb-movie-properties (&rest args)
  "Open new org-buffer containing movie info and poster of given ARGS.
ARGS should be in the same form with `orgmdb' function.

If this function is called on an org heading then it'll try to
detect parameters based on that heading.  If not, it'll simply ask
for title and year.  See `orgmdb-fill-movie-properties' function
for check how parameter detection works."
  (interactive (orgmdb--detect-params-from-header))
  (let ((info (apply #'orgmdb `(,@args :episode all :plot full))))
    (orgmdb--ensure-response-is-successful info)
    (switch-to-buffer (format "*orgmdb: %s*" (orgmdb-title info)))
    (insert (format "#+TITLE: [[imdb:%s][%s]] (%s)\n" (orgmdb-imdb-id info) (orgmdb-title info) (orgmdb-year info)))
    (insert "\n")
    (insert (format "[[file:%s]]\n\n" (orgmdb--download-image-for info)))
    (insert (format "- Genre :: %s\n" (orgmdb-genre info)))
    (insert (format "- Runtime :: %s\n" (orgmdb-runtime info)))
    (insert (format "- Released :: %s\n" (orgmdb-released info)))
    (insert (format "- Rated :: %s\n" (orgmdb-rated info)))
    (insert "\n")
    (insert (format "- Director :: %s\n" (orgmdb-director info)))
    (insert (format "- Writer :: %s\n" (orgmdb-writer info)))
    (insert (format "- Production :: %s\n" (orgmdb-writer info)))
    (insert (format "- Actors :: %s\n" (orgmdb-actors info)))
    (insert "\n")
    (insert (format "- Language :: %s\n" (orgmdb-language info)))
    (insert (format "- Country :: %s\n" (orgmdb-country info)))
    (insert (format "- Awards :: %s\n" (orgmdb-awards info)))
    (insert "\n")
    (insert (format "- Metacritic :: %s\n" (orgmdb-metacritic info)))
    (insert (format "- IMDb Rating :: %s (%s votes)\n" (orgmdb-imdb-rating info) (orgmdb-imdb-votes info)))
    (insert (format "- Tomatometer :: %s\n" (orgmdb-tomatometer info)))
    (insert "\n")
    (insert (format "- Plot :: %s\n" (orgmdb-plot info)))
    (insert "\n")
    (let (last-season)
      (seq-do
       (lambda (episode)
         (let-alist episode
           (let ((curr-season (string-to-number .Season)))
             (insert (format "%s** [[imdb:%s][%s]]\n"
                             (if (and last-season (eq curr-season last-season))
                                 ""
                               (setq last-season curr-season)
                               (format "* Session %s\n" curr-season))
                             .imdbID
                             (orgmdb--episode-to-title episode)))
             (insert (format "- IMDb Rating :: %s\n" .imdbRating))
             (insert (format "- Released :: %s\n" .Released))
             (insert "\n"))))
       (alist-get 'Episodes info)))
    (org-mode)
    (org-display-inline-images)
    (goto-char (point-min))
    (outline-hide-sublevels 1)
    (org-cycle)))

(defun orgmdb--fill-properties (info should-set-title)
  (orgmdb--ensure-response-is-successful info)
  (--each
      (remq 'poster orgmdb-fill-property-list)
    (-as->
     (format "orgmdb-%s" it) fn
     (intern fn)
     (apply fn `(,info "N/A"))
     (org-entry-put nil
                    (if orgmdb-upcase-properties
                        (upcase (format "%s" it))
                      (format "%s" it))
                    fn)))
  (when (memq 'poster orgmdb-fill-property-list)
    (let ((path (orgmdb--download-image-for info)))
      (save-excursion
        (save-restriction
          (org-narrow-to-subtree)
          (org-end-of-meta-data)
          (when (not (search-forward (format "[[file:%s]]" path) nil t))
            (insert (format "\n#+ATTR_ORG: :width 300\n[[file:%s]]\n" path))
            (org-redisplay-inline-images))))))
  (when should-set-title
    (org-edit-headline
     (pcase (orgmdb-type info)
       ("movie" (format "%s (%s)" (orgmdb-title info) (orgmdb-year info)))
       ("series" (format "%s (%s)" (orgmdb-title info) (orgmdb-year info)))
       ("episode" (orgmdb--episode-to-title info))))
    (if orgmdb-type-prop
        (org-set-property orgmdb-type-prop (orgmdb-type info))
      (org-toggle-tag (orgmdb-type info) 'on)))
  (message "Done."))

;;;###autoload
(defun orgmdb-fill-movie-properties (should-set-title)
  "Fetch and set pre-defined properties to current org header.
See `orgmdb-fill-property-list' for which properties will be set.

It will automatically try to automatically detect what to search
for based on the current org header.  Following formats are
recognized:

- TITLE
- TITLE (YEAR)
- IMDB-ID

It also checks if the header contains one of the following tags:
\"movie\", \"series\", \"episode\" or checks if the TYPE property
of the current header is one of these. If so, searches for that
particular type only.

If the format of the header is unrecognized, it will ask for
title and year from user.

If SHOULD-SET-TITLE is non-nil, then also set the text of current
org header using the following formats:

- For movies: TITLE (YEAR)
- For series: TITLE (YEAR-YEAR)
- For episodes: S01E01 - TITLE"
  (interactive "P")
  (orgmdb--fill-properties
   (apply #'orgmdb (orgmdb--detect-params-from-header))
   should-set-title))

;;;###autoload
(defun orgmdb-fill-movie-properties-with-title (should-set-title)
  "Fetch and set pre-defined properties to current org header.
Like `orgmdb-fill-movie-properties' but instead of automatically
detecting what to search for, it asks for title and year.  See
`orgmdb-fill-movie-properties' documentation for what
SHOULD-SET-TITLE does."
  (interactive "P")
  (-let ((type (orgmdb--ask-for-type))
         ((title year) (orgmdb--ask-for-title-and-year)))
    (orgmdb--fill-properties
     (orgmdb :type type :title title :year year)
     should-set-title)))

;;;###autoload
(defun orgmdb-fill-movie-properties-with-imdb-id (should-set-title)
  "Fetch and set pre-defined properties to current org header.
Like `orgmdb-fill-movie-properties' but instead of automatically
detecting what to search for, it asks for IMDb id.  See
`orgmdb-fill-movie-properties' documentation for what
SHOULD-SET-TITLE does."
  (interactive "P")
  (orgmdb--fill-properties
   (orgmdb :imdb (read-string "IMDb id: "))
   should-set-title))

(defun orgmdb--extract-episode (str)
  (-some->> str
    (s-match orgmdb--episode-matcher)
    (car)
    (s-downcase)))

(defun orgmdb--info-at-point ()
  `(:episode
    ,(or (orgmdb--extract-episode (org-entry-get nil "ITEM"))
         (orgmdb--extract-episode (thing-at-point 'symbol)))
    ,@(save-excursion
        (catch 'break
          (while t
            (if (--any?
                 (-contains? (list orgmdb-show-tag orgmdb-movie-tag orgmdb-episode-tag) it)
                 (if orgmdb-type-prop
                     (list (org-entry-get nil orgmdb-type-prop))
                   (org-get-tags nil t)))
                (throw
                 'break
                 (list
                  :title (org-entry-get nil "ITEM")
                  :imdb-id (org-entry-get nil "IMDB-ID")))
              (when (not (ignore-errors
                           (if (not (org-at-heading-p))
                               (org-back-to-heading)
                             (outline-up-heading 1 t))))
                (throw 'break nil))))))))

(defun orgmdb-act ()
  "Act on the current movie/series/episode object.
It'll display several actions (like filling proprties etc.)
related to the current object."
  (interactive)
  (let ((tags (if orgmdb-type-prop
                  (list (org-entry-get nil orgmdb-type-prop))
                (org-get-tags))))
    (cond
     ((or (-contains? tags orgmdb-episode-tag)
          (orgmdb--extract-episode (thing-at-point 'symbol)))
      (orgmdb-act-on-episode))
     ((-contains? tags orgmdb-movie-tag)
      (orgmdb-act-on-movie))
     ((-contains? tags orgmdb-show-tag)
      (orgmdb-act-on-show))
     ((org-at-heading-p)
      (setq tags (completing-read
                  "What is this? "
                  (list orgmdb-movie-tag orgmdb-show-tag orgmdb-episode-tag)))
      (if orgmdb-type-prop
          (org-set-property orgmdb-type-prop tags)
        (org-set-tags tags))
      (orgmdb-act))
     (t
      (user-error "Not on an org header or an episode object")))))

(defun orgmdb-act-on-movie ()
  "List possible actions on the movie at point."
  (interactive)
  (orgmdb--act-on 'movie))

(defun orgmdb-act-on-show ()
  "List possible actions on the show at point."
  (interactive)
  (orgmdb--act-on 'show))

(defun orgmdb-act-on-episode (&optional episode)
  "List possible actions on the EPISODE at point."
  (interactive)
  (orgmdb--act-on 'episode :episode (orgmdb--extract-episode episode)))

(defun orgmdb--act-on (type &rest args)
  (apply
   (cdr (orgmdb--completing-read-object
         (format "Act on %s: " 'movie)
         (map-values (symbol-value (intern (concat "orgmdb--" (symbol-name type) "-actions"))))
         :formatter #'car
         :sort? nil))
   type
   (append
    args
    (orgmdb--info-at-point))))

(cl-defun orgmdb-defaction (&key name on act definition)
  (--each on
    (puthash
     name
     (cons definition act)
     (symbol-value (intern (concat "orgmdb--" (symbol-name it) "-actions"))))))

(orgmdb-defaction
 :name 'open-local-video
 :definition "Open local video"
 :on '(movie show episode)
 :act (cl-function
       (lambda (type &key title episode &allow-other-keys)
         (pcase type
           ((or 'movie 'show) (orgmdb--open-video title))
           ('episode (orgmdb--open-video title episode))))))

(orgmdb-defaction
 :name 'select-episode
 :definition "Select an episode..."
 :on '(show)
 :act (cl-function
       (lambda (_type &key imdb-id &allow-other-keys)
         (let* ((episodes
                 (--map (cons (orgmdb--episode-to-title it) it)
                        (alist-get 'Episodes (orgmdb :imdb imdb-id :episode 'all))))
                (selected-episode
                 (cdr (orgmdb--completing-read-object
                       "Select an episode: "
                       episodes
                       :formatter #'car
                       :sort? nil))))
           (orgmdb--act-on
            'episode
            :episode (orgmdb--episode-to-marker selected-episode))))))

(orgmdb-defaction
 :name 'show-detailed-info
 :definition "Show detailed info"
 :on '(movie show)
 :act (lambda (&rest _)
        (apply #'orgmdb-movie-properties (orgmdb--detect-params-from-header))))

(orgmdb-defaction
 :name 'fill-properties
 :definition "Fill properties"
 :on '(movie show episode)
 :act (lambda (&rest _)
        (orgmdb-fill-movie-properties t)))

(defun orgmdb--open-video (name &optional episode)
  (->>
   (if (listp orgmdb-video-dir)
       (--mapcat (orgmdb--search-video it name episode) (-filter #'file-directory-p orgmdb-video-dir))
     (orgmdb--search-video orgmdb-video-dir name episode))
   (completing-read "Select file to play: ")
   (funcall orgmdb-player-function)))

(defun orgmdb--run-command (program &rest args)
  "Run PROGRAM synchronously and return it's output.
ARGS are strings passed as command arguments to PROGRAM."
  (with-temp-buffer
    (apply #'call-process program nil t nil args)
    (buffer-string)))

(defun orgmdb--search-video (dir name &optional episode)
  (let ((video-dir (expand-file-name dir))
        (user-dir (expand-file-name "~")))
    (->>
     name
     (s-trim)
     ((lambda (it) (string-trim-right it " *(.+)")))
     (s-replace "'" " ")
     (s-replace " " "*")
     (s-downcase)
     ((lambda (name)
        `("fd" "--absolute-path" "--type=file"
          ,@(--map (format "--extension=%s" it) orgmdb-video-file-extensions)
          "--glob"
          ,(format "*%s*%s" name (if (not (s-blank? episode)) (concat (s-downcase episode) "*") ""))
          ,video-dir)))
     (apply #'orgmdb--run-command)
     (s-trim)
     (s-split "\n")
     (-filter (-compose #'not #'string-empty-p))
     (--map (replace-regexp-in-string (concat "^" user-dir) "~" it)))))

(declare-function empv-play "empv")
(defun orgmdb-play (path)
  (if (require 'empv nil t)
      (empv-play path)
    (org-open-file path)))

(provide 'orgmdb)
;;; orgmdb.el ends here
