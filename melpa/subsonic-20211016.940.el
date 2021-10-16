;;; subsonic.el --- Browse and play music from subsonic servers with mpv  -*- lexical-binding: t; -*-

;; Author: Alex McGrath <amk@amk.ie>
;; URL: https://git.sr.ht/~amk/subsonic.el
;; Package-Version: 20211016.940
;; Package-Commit: a070cff3f802796dd0dbab4b2ebfbb9f05c36b0b
;; Version: 0.2.0
;; Keywords: multimedia
;; Package-Requires: ((emacs "27.1") (transient "0.2"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package is meant to act as a simple subsonic frontend that
;; uses mpv for playing the actual music.  Use a ~/.authinfo.gpg file with
;; contents like the following to setup auth
;;
;; machine SUBSONIC_HOST login USERNAME password PASSWORD

;;; Code:
(require 'json)
(require 'url)
(require 'tq)
(require 'seq)

(require 'transient)

;; Credit & thanks to the mpv.el and docker-mode projects for examples
;; and much of the code here :)

(defgroup subsonic nil "Customization group for mpv." :prefix "subsonic-" :group 'external)

(defcustom subsonic-host ""
  "Hostname for the subsonic service.
Used to find the correct authinfo entry."
  :type 'string
  :group 'subsonic)

(defcustom subsonic-mpv (executable-find "mpv")
  "Path to the mpv executable."
  :type 'string
  :group 'subsonic)

(defcustom subsonic-default-volume 100
  "Default  volume for mpv to use."
  :type 'integer
  :group 'subsonic)

(defcustom subsonic-enable-art nil
  "Enable displaying album art in supported frames."
  :type 'boolean
  :group 'subsonic)

(defcustom subsonic-art-size 100
  "Set size for the subsonic album art download query."
  :type 'integer
  :group 'subsonic)

(defcustom subsonic-art-cache-path (expand-file-name "subsonic-cache" user-emacs-directory)
  "Path to store cached subsonic art."
  :type 'string
  :group 'subsonic)

(defcustom subsonic-ssl t
  "Choose either a https or http connection to subsonic."
  :type 'boolean
  :group 'subsonic)

(defcustom subsonic-curl-image-download nil
  "Use curl for downloading album images, can be a performance improvement."
  :type 'boolean
  :group 'subsonic)

(defcustom subsonic-curl-image-parallel t
  "Use --parallel when calling curl."
  :type 'boolean
  :group 'subsonic)

(defcustom subsonic-album-list-count 50
  "Number of albums to display in random/newest albums etc."
  :type 'integer
  :group 'subsonic)

(defvar subsonic-mpv--volume subsonic-default-volume)
(defvar subsonic-mpv--process nil)
(defvar subsonic-mpv--queue nil)

(defun subsonic-mpv-kill ()
  "Kill the mpv process."
  (interactive)
  (when subsonic-mpv--queue
    (tq-close subsonic-mpv--queue))
  (when (subsonic-mpv-live-p)
    (kill-process subsonic-mpv--process))
  (with-timeout (0.5 (error "Failed to kill mpv"))
    (while (subsonic-mpv-live-p)
      (sleep-for 0.05)))
  (setq subsonic-mpv--process nil)
  (setq subsonic-mpv--queue nil))

(defun subsonic-mpv-live-p ()
  "Return non-nil if inferior mpv is running."
  (and subsonic-mpv--process (eq (process-status subsonic-mpv--process) 'run)))

(defun subsonic-mpv-start (args)
  "Used to start mpv.
ARGS are any extra arguments to provide to mpv, in
this case usually track lists"
  (subsonic-mpv-kill)
  (let ((socket (make-temp-name (expand-file-name "subsonic-mpv-" temporary-file-directory))))
    (setq subsonic-mpv--process
      (apply #'start-process
        (append
          (list
            "mpv-player"
            nil
            subsonic-mpv
            ;; "--no-terminal" leave this out, breaks on debian?
            "--really-quiet"
            "--no-video"
            (format "--volume=%d" subsonic-mpv--volume)
            (concat "--input-ipc-server=" socket))
          args)))
    (set-process-query-on-exit-flag subsonic-mpv--process nil)
    (set-process-sentinel
      subsonic-mpv--process
      (lambda (process _event)
        (when (memq (process-status process) '(exit signal))
          (subsonic-mpv-kill)
          (when (file-exists-p socket)
            (with-demoted-errors (delete-file socket))))))
    (with-timeout (0.5 (subsonic-mpv-kill) (error "Failed to connect to mpv"))
      (while (not (file-exists-p socket))
        (sleep-for 0.05)))
    (setq subsonic-mpv--queue
      (tq-create
        (make-network-process :name "subsonic-mpv-socket" :family 'local :service socket)))
    (set-process-filter (tq-process subsonic-mpv--queue) (lambda (_proc _string)))
    t))

(defvar subsonic-auth
  (let ((auth (auth-source-search :host subsonic-host)))
    (when auth
      (car auth))))

(defun subsonic-alist->query (al)
  "Convert an alist -- AL to a set of url query parameters."
  (seq-reduce
    (lambda (accu q)
      (if (string-empty-p accu)
        (concat "?" (car q) "=" (cdr q))
        (concat accu "&" (car q) "=" (cdr q))))
    al ""))

(defun subsonic-get-json (url)
  "Return a parsed json response from URL."
  (condition-case nil
    (let*
      (
        (json-array-type 'list)
        (json-key-type 'string))
      (json-read-from-string
        (with-temp-buffer
          (url-insert-file-contents url)
          (prog1 (buffer-string)
            (kill-buffer)))))
    (json-readtable-error (error "Failed to read json"))))

;; fix byte-compiler complaints
(defvar url-http-end-of-headers)

(defun subsonic-image-propertize (id)
  "Generate a property for a subsonic ID."
  (propertize
    " "
    'display
    (create-image (expand-file-name id subsonic-art-cache-path) nil nil :height 100)))

(defun subsonic-get-image (id vec n buff)
  "Update a tablist VEC entry with an image from ID.
BUFF is used to specify the buffer that will be
reverted upon image load and N specifies the index"
  (if (file-exists-p (expand-file-name id subsonic-art-cache-path))
    (aset vec n (subsonic-image-propertize id))
    (url-retrieve
      (subsonic-build-url
        "/getCoverArt.view"
        `(("id" . ,id) ("size" . ,(int-to-string subsonic-art-size))))
      (lambda (_status)
        (write-region
          (+ url-http-end-of-headers 1)
          (point-max)
          (expand-file-name id subsonic-art-cache-path))
        (aset vec n (subsonic-image-propertize id))
        (set-buffer buff)
        (when (derived-mode-p 'tabulated-list-mode)
          (tabulated-list-revert))))))

(defun subsonic-curl-images (entries n buff)
  "Use curl to download images for each of the ENTRIES.
N specifies the tablist index and BUFF is the buffer to be
reverted."
  (let ((curl-args (list "curl")))
    (when subsonic-curl-image-parallel
      (setq curl-args (append curl-args '("-Z"))))
    (dolist (entry entries)
      (let
        (
          (id (car entry))
          (vec (nth 1 entry)))
        (if (file-exists-p (expand-file-name id subsonic-art-cache-path))
          (aset vec n (subsonic-image-propertize id))
          (setq curl-args
            (append
              curl-args
              `
              ("-o"
                ,(expand-file-name id subsonic-art-cache-path)
                ,
                (subsonic-build-url
                  "/getCoverArt.view"
                  `(("id" . ,id) ("size" . ,(int-to-string subsonic-art-size))))))))))
    (let ((curl-process (apply #'start-process (append (list "subsonic-curl" nil) curl-args))))
      (set-process-sentinel
        curl-process
        (lambda (process _signal)
          (when (memq (process-status process) '(exit signal))
            (dolist (entry entries)
              (let
                (
                  (id (car entry))
                  (vec (nth 1 entry)))
                (when (file-exists-p (expand-file-name id subsonic-art-cache-path))
                  (aset vec n (subsonic-image-propertize id))))
              (set-buffer buff)
              (when (derived-mode-p 'tabulated-list-mode)
                (tabulated-list-revert)))))))))

(defun subsonic-get-images (entries n buff)
  (if (or (not subsonic-enable-art) (not (display-graphic-p)))
    (dolist (entry tabulated-list-entries)
      (aset (nth 1 entry) n ""))
    (progn
      (when (not (file-exists-p subsonic-art-cache-path))
        (mkdir subsonic-art-cache-path))
      (if subsonic-curl-image-download
        (subsonic-curl-images entries n (current-buffer))
        (dolist (entry tabulated-list-entries)
          (subsonic-get-image (car entry) (nth 1 entry) n buff))))))


(defun subsonic-recursive-assoc (data keys)
  "Recursively assoc DATA from a list of KEYS."
  (if keys
    (subsonic-recursive-assoc (assoc-default (car keys) data) (cdr keys))
    data))

(defun subsonic-build-url (endpoint extra-query)
  "Build a valid subsonic url for a given ENDPOINT.
EXTRA-QUERY is used for any extra query parameters"
  (if subsonic-auth
    (concat
      (if subsonic-ssl
        "https://"
        "http://")
      (plist-get subsonic-auth :host) "/rest" endpoint
      (subsonic-alist->query
        (append
          `
          (("u" . ,(plist-get subsonic-auth :user))
            ("p" . ,(funcall (plist-get subsonic-auth :secret)))
            ("c" . "ElSonic")
            ("v" . "1.16.0")
            ("f" . "json"))
          extra-query)))
    (error
      "Failed to load .authinfo, please provide auth configuration for
subsonic, and ensure subsonic-host is set correctly")))

(defun subsonic-mpv-command (&rest args)
  "Generate a mpv ipc command using ARGS."
  (tq-enqueue
    subsonic-mpv--queue
    (concat (json-serialize (list 'command (apply #'vector args))) "\n")
    ""
    nil
    (lambda (_x _y))))

;;;###autoload
(defun subsonic-toggle-playing ()
  "Toggle playing/paused state in mpv."
  (interactive)
  (subsonic-mpv-command "cycle" "pause"))

;;;###autoload
(defun subsonic-skip-track ()
  "Toggle playing/paused state in mpv."
  (interactive)
  (subsonic-mpv-command "playlist-next"))

;;;###autoload
(defun subsonic-prev-track ()
  "Toggle playing/paused state in mpv."
  (interactive)
  (subsonic-mpv-command "playlist-prev"))

;;;###autoload
(defun subsonic-seek-forward ()
  "Toggle playing/paused state in mpv."
  (interactive)
  (subsonic-mpv-command "seek" "30" "relative")
  (subsonic))

(defun subsonic-seek-back ()
  "Toggle playing/paused state in mpv."
  (interactive)
  (subsonic-mpv-command "seek" "-30" "relative")
  (subsonic))

;;;
;;; Search
;;;
(defun subsonic-search-parse (data)
  "Retrieve a list of search results from some parsed json DATA."
  (let*
    (
      (search-results (subsonic-recursive-assoc data '("subsonic-response" "searchResult3")))
      (result
        (append
          (mapcar
            (lambda (artist)
              (list
                `(,(assoc-default "id" artist) . "artist")
                (vector "Artist" (assoc-default "name" artist))))
            (assoc-default "artist" search-results))
          (mapcar
            (lambda (album)
              (list
                `(,(assoc-default "id" album) . "album")
                (vector "Album" (assoc-default "name" album))))
            (assoc-default "album" search-results))
          (mapcar
            (lambda (song)
              (list
                `(,(assoc-default "id" song) . "song")
                (vector "Song" (assoc-default "title" song))))
            (assoc-default "song" search-results)))))
    result))

(defun subsonic-search-refresh (query)
  "Refresh the list of search results from QUERY."
  (setq tabulated-list-entries
    (subsonic-search-parse
      (subsonic-get-json (subsonic-build-url "/search3.view" `(("query" . ,query)))))))

(defun subsonic-open-search-appropriate-result (result)
  "Opens the RESULT from a search in the appropriate buffer."
  (let ((type (cdr result)))
    (cond
      ((string-equal type "artist")
        (subsonic-albums (car result)))
      ((string-equal type "album")
        (subsonic-tracks (car result)))
      ((string-equal type "song")
        (subsonic-mpv-start
          (list (subsonic-build-url "/stream.view" `(("id" . ,(car result))))))))))

(defun subsonic-open-search-result ()
  "Open a view of the result from the result at point."
  (interactive)
  (subsonic-open-search-appropriate-result (tabulated-list-get-id)))

(defvar subsonic-search-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'subsonic-open-search-result)
    map))

;;;###autoload
(defun subsonic-search ()
  "List subsonic search results."
  (interactive)
  (let ((new-buff (get-buffer-create "*subsonic-search*")))
    (set-buffer new-buff)
    (setq buffer-read-only t)
    (subsonic-search-mode)
    (pop-to-buffer (current-buffer))))

(define-derived-mode
  subsonic-search-mode
  tabulated-list-mode
  "Subsonic search mode"
  ;;  type: artist|album|track
  (setq tabulated-list-format [("Type" 10 t) ("Name" 30 t)])
  (setq tabulated-list-padding 2)
  (subsonic-search-refresh (url-hexify-string (read-string "Query: ")))
  (tabulated-list-revert)
  (tabulated-list-init-header))


;;;
;;; Tracks
;;;

(defun subsonic-get-tracklist-id (id)
  "Get a tracklist for a given ID."
  (reverse
    (seq-reduce
      (lambda (accu current)
        (if (equal (car current) id)
          (list (car current))
          (if (null accu)
            '()
            (cons (car current) accu))))
      tabulated-list-entries '())))

(defun subsonic-tracks-parse (data)
  "Parse tracks from json DATA."
  (let*
    (
      (tracks (subsonic-recursive-assoc data '("subsonic-response" "directory" "child")))
      (result
        (mapcar
          (lambda (track)
            (let* ((duration (assoc-default "duration" track)))
              (list
                (assoc-default "id" track)
                (vector
                  (assoc-default "title" track)
                  (format-seconds "%m:%.2s" duration)
                  (format "%d" (assoc-default "track" track))))))
          tracks)))
    result))

(defun subsonic-tracks-refresh (id)
  "Refresh the list of subsonic tracks from ID."
  (setq tabulated-list-entries
    (subsonic-tracks-parse
      (subsonic-get-json (subsonic-build-url "/getMusicDirectory.view" `(("id" . ,id)))))))


(defun subsonic-play-tracks ()
  "Play all the tracks after the point in the list."
  (interactive)
  (subsonic-mpv-start
    (mapcar
      (lambda (id) (subsonic-build-url "/stream.view" `(("id" . ,id))))
      (subsonic-get-tracklist-id (tabulated-list-get-id)))))

(defvar subsonic-tracks-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'subsonic-play-tracks)
    map))

(defun subsonic-tracks (id)
  "Create a buffer with a list of tracks from ID."
  (let ((new-buff (get-buffer-create "*subsonic-tracks*")))
    (set-buffer new-buff)
    (subsonic-tracks-mode)
    (subsonic-tracks-refresh id)
    (tabulated-list-revert)
    (pop-to-buffer-same-window (current-buffer))))

(define-derived-mode
  subsonic-tracks-mode
  tabulated-list-mode
  "Subsonic Tracks"
  (setq tabulated-list-format [("Title" 30 t) ("Duration" 10 t) ("Track" 10 t)])
  (setq tabulated-list-padding 2)
  (tabulated-list-init-header))

;;;
;;; Albums
;;;

(defun subsonic-albums-parse (data)
  "Retrieve a list of albums from some parsed json DATA."
  (let*
    (
      (albums (subsonic-recursive-assoc data '("subsonic-response" "artist" "album")))
      (result
        (mapcar
          (lambda (album)
            (list
              (assoc-default "id" album)
              (vector
                (format "%d" (or (assoc-default "year" album) 0))
                (assoc-default "name" album)
                "")))
          albums)))
    result))

(defun subsonic-albums-type-parse (data)
  "Retrieve a list of albums from some parsed json DATA."
  (let*
    (
      (albums (subsonic-recursive-assoc data '("subsonic-response" "albumList2" "album")))
      (result
        (mapcar
          (lambda (album)
            (list
              (assoc-default "id" album)
              (vector (assoc-default "name" album) (assoc-default "artist" album) "")))
          albums)))
    result))

(defun subsonic-albums-refresh (id)
  "Refresh the albums list for a given artist ID."
  (setq tabulated-list-entries
    (subsonic-albums-parse
      (subsonic-get-json (subsonic-build-url "/getArtist.view" `(("id" . ,id))))))
  (subsonic-get-images tabulated-list-entries 2 (current-buffer)))


(defun subsonic-albums-refresh-type (type)
  "Refresh the albums list for a given albumlist TYPE."
  (setq tabulated-list-entries
    (subsonic-albums-type-parse
      (subsonic-get-json
        (subsonic-build-url
          "/getAlbumList2.view"
          `(("type" . ,type) ("size" . ,(number-to-string subsonic-album-list-count)))))))
  (subsonic-get-images tabulated-list-entries 2 (current-buffer)))

(defun subsonic-open-tracks ()
  "Open a list of tracks at point."
  (interactive)
  (subsonic-tracks (tabulated-list-get-id)))

(defvar subsonic-album-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'subsonic-open-tracks)
    map))

(defvar subsonic-album-type-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'subsonic-open-tracks)
    map))

(defun subsonic-recent-albums ()
  "Show a list of recently played subsonic albums."
  (interactive)
  (subsonic-albums nil "recent"))

(defun subsonic-random-albums ()
  "Show a list of random subsonic albums."
  (interactive)
  (subsonic-albums nil "random"))

(defun subsonic-newest-albums ()
  "Show a list of recently added subsonic albums."
  (interactive)
  (subsonic-albums nil "newest"))

(defun subsonic-albums (&optional id type)
  "Open a buffer of albums for artist ID or list TYPE."
  (let ((new-buff (get-buffer-create "*subsonic-albums*")))
    (set-buffer new-buff)
    (cond
      (id
        (subsonic-album-mode)
        (subsonic-albums-refresh id))
      (type
        (subsonic-album-type-mode)
        (subsonic-albums-refresh-type type)))
    (tabulated-list-revert)
    (pop-to-buffer-same-window (current-buffer))))

(define-derived-mode
  subsonic-album-type-mode
  tabulated-list-mode
  "Subsonic Album List"
  (setq tabulated-list-format [("Albums" 30 t) ("Artists" 30 t) ("Art" 30 nil)])
  (setq tabulated-list-padding 2)
  (tabulated-list-init-header))

(define-derived-mode
  subsonic-album-mode
  tabulated-list-mode
  "Subsonic Albums"
  (setq tabulated-list-format [("Year" 5 t) ("Albums" 40 t) ("Art" 30 nil)])
  (setq tabulated-list-padding 2)
  (tabulated-list-init-header))

;;;
;;; Artists
;;;
(defun subsonic-open-album ()
  "Open the albums for the artist at point."
  (interactive)
  (subsonic-albums (tabulated-list-get-id)))

(defun subsonic-artists-parse (data)
  "Retrieve a list of artists from some parsed json DATA."
  (let*
    (
      (artists (subsonic-recursive-assoc data '("subsonic-response" "artists" "index")))
      (result
        (seq-reduce
          (lambda (accu artist-index)
            (append
              accu
              (mapcar
                (lambda (artist)
                  (list (assoc-default "id" artist) (vector (assoc-default "name" artist))))
                (assoc-default "artist" artist-index))))
          artists '())))
    result))

(defun subsonic-artists-refresh ()
  "Refresh the list of subsonic artists."
  (setq tabulated-list-entries
    (subsonic-artists-parse (subsonic-get-json (subsonic-build-url "/getArtists.view" '())))))

(defvar subsonic-artist-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'subsonic-open-album)
    map))

;;;###autoload
(defun subsonic-artists ()
  "List subsonic artists."
  (interactive)
  (let ((new-buff (get-buffer-create "*subsonic-artists*")))
    (set-buffer new-buff)
    (setq buffer-read-only t)
    (subsonic-artist-mode)
    (tabulated-list-revert)
    (pop-to-buffer (current-buffer))))

(define-derived-mode
  subsonic-artist-mode
  tabulated-list-mode
  "Subsonic Artists"
  (setq tabulated-list-format [("Artist" 30 t)])
  (setq tabulated-list-padding 2)
  (add-hook 'tabulated-list-revert-hook #'subsonic-artists-refresh nil t)
  (tabulated-list-init-header))

;;;
;;; Podcasts
;;;
(defun subsonic-podcasts-parse (data)
  "Retrieve a list of podcasts from some parsed json DATA."
  (let*
    (
      (podcasts (subsonic-recursive-assoc data '("subsonic-response" "podcasts" "channel")))
      (result
        (mapcar
          (lambda (channel)
            (list (assoc-default "id" channel) (vector (assoc-default "title" channel) "")))
          podcasts)))
    result))

(defun subsonic-podcasts-refresh ()
  "Refresh the list of podcasts."
  (setq tabulated-list-entries
    (subsonic-podcasts-parse
      (subsonic-get-json
        (subsonic-build-url "/getPodcasts.view" '(("includeEpisodes" . "false"))))))
  (subsonic-get-images tabulated-list-entries 1 (current-buffer)))


(defun subsonic-open-podcast-episodes ()
  "Open a view of podcasts episodes from the podcast at point."
  (interactive)
  (subsonic-podcast-episodes (tabulated-list-get-id)))

(defun subsonic-add-podcast ()
  "Add a new subsonic podcast."
  (interactive)
  (subsonic-get-json
    (subsonic-build-url
      "/createPodcastChannel.view"
      `(("url" . ,(url-hexify-string (read-string "feed url: ")))))))

(transient-define-prefix
  subsonic-podcast-help () "Help transient for subsonic podcasts."
  ["Subsonic podcast help"
    ("a" "Add a podcast" subsonic-add-podcast)
    ("RET" "Open a podcast" subsonic-open-podcast-episodes)])

(defvar subsonic-podcast-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'subsonic-open-podcast-episodes)
    (define-key map (kbd "?") #'subsonic-podcast-help)
    (define-key map (kbd "a") #'subsonic-add-podcast)
    map))

;;;###autoload
(defun subsonic-podcasts ()
  "List subsonic podcasts."
  (interactive)
  (let ((new-buff (get-buffer-create "*subsonic-podcasts*")))
    (set-buffer new-buff)
    (setq buffer-read-only t)
    (subsonic-podcast-mode)
    (subsonic-podcasts-refresh)
    (tabulated-list-revert)
    (pop-to-buffer (current-buffer))))

(define-derived-mode
  subsonic-podcast-mode
  tabulated-list-mode
  "Subsonic Podcasts"
  (setq tabulated-list-format [("Podcasts" 30 t) ("Art" 20 nil)])
  (setq tabulated-list-padding 2)
  (tabulated-list-init-header))

;;;
;;; Podcast episodes
;;;

(defun subsonic-podcast-episodes-parse (data)
  "Retrieve a list of podcast episodes from some parsed json DATA."
  (let*
    (
      (episodes
        (assoc-default
          "episode"
          (car (subsonic-recursive-assoc data '("subsonic-response" "podcasts" "channel")))))
      (result
        (mapcar
          (lambda (episode)
            (list
              (assoc-default "id" episode)
              (vector
                (assoc-default "title" episode)
                (format-seconds "%h:%.2m:%.2s" (assoc-default "duration" episode))
                (assoc-default "status" episode))))
          episodes)))
    result))

(defun subsonic-play-podcast ()
  "Play a podcast episode at point."
  (interactive)
  (subsonic-mpv-start
    (list (subsonic-build-url "/stream.view" `(("id" . ,(tabulated-list-get-id)))))))

(defun subsonic-podcasts-episode-refresh (id)
  "Refresh the list of podcast episodes for a podcast ID."
  (setq tabulated-list-entries
    (subsonic-podcast-episodes-parse
      (subsonic-get-json
        (subsonic-build-url "/getPodcasts.view" `(("id" . ,id) ("includeEpisodes" . "true")))))))

(defun subsonic-download-podcast-episode ()
  "Tell the subsonic server to download an episode at point."
  (interactive)
  (subsonic-get-json
    (subsonic-build-url "/downloadPodcastEpisode.view" `(("id" . ,(tabulated-list-get-id))))))

(transient-define-prefix
  subsonic-podcast-episode-help
  ()
  "Help transient for subsonic podcast episodes."
  ["Subsonic podcast episode help"
    ("d" "Download" subsonic-download-podcast-episode)
    ("RET" "Start playing" subsonic-play-podcast)])


(defvar subsonic-podcast-episodes-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "?") #'subsonic-podcast-episode-help)
    (define-key map (kbd "RET") #'subsonic-play-podcast)
    (define-key map (kbd "d") #'subsonic-download-podcast-episode)
    map))

(defun subsonic-podcast-episodes (id)
  "Open a buffer with a list of podcast episodes from podcast ID."
  (let ((new-buff (get-buffer-create "*subsonic-podcast-episodes*")))
    (set-buffer new-buff)
    (subsonic-podcast-episodes-mode)
    (subsonic-podcasts-episode-refresh id)
    (tabulated-list-revert)
    (pop-to-buffer-same-window (current-buffer))))

(define-derived-mode
  subsonic-podcast-episodes-mode
  tabulated-list-mode
  "Subsonic Podcast Episodes"
  (setq tabulated-list-format [("Title" 50 t) ("Duration" 10 t) ("Status" 24 t)])
  (setq tabulated-list-padding 2)
  (tabulated-list-init-header))

;;;###autoload (autoload 'subsonic "subsonic" nil t)
(transient-define-prefix
  subsonic () "Help transient for subsonic."
  ["Subsonic"
    ("p" "Podcasts" subsonic-podcasts)
    ("a" "Artists" subsonic-artists)
    ("r" "Random Albums" subsonic-random-albums)
    ("n" "Newest Albums" subsonic-newest-albums)
    ("s" "Search subsonic" subsonic-search)]
  ["Controls"
    ("t" "Toggle playing" subsonic-toggle-playing)
    ("f" "Skip track" subsonic-skip-track)
    ("b" "Previous track" subsonic-prev-track)
    ("F" "Seek forward" subsonic-seek-forward)
    ("B" "Seek back" subsonic-seek-back)])

(provide 'subsonic)

;;; subsonic.el ends here
