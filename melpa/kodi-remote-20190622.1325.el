;;; kodi-remote.el --- Remote Control for Kodi  -*- lexical-binding:t -*-

;; Copyright (C) 2015-2019 Stefan Huchler

;; Author: Stefan Huchler <stefan.huchler@mail.de>
;; URL: http://github.com/spiderbit/kodi-remote.el
;; Package-Version: 20190622.1325
;; Package-Commit: f5e932036c16e2b61a63020e006fc601e38d181e
;; Package-Requires: ((request "0.2.0")(let-alist "1.0.4")(json "1.4")(cl-lib "0.5")(f "20190109.906"))
;; Keywords: kodi tools convinience
;; Version: 0

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; A major to remote control kodi instances.

;; First specify the hostname/ip of your kodi webserver:
;; (setq kodi-host-name "my-htpc:8080")
;; Then open the Remote with the command:
;; 'kodi-remote'
;; Also open the current kodi Video Playlist with the command:
;; 'kodi-remote-playlist'
;; Start play exercise mode:
;; 'kodi-remote-exercise'
;; OPTIONAL: setup settings for deleting files (over tramp)
;; (setq kodi-dangerous-options t)
;; (setq kodi-access-host "my-htpc")
;; if you don't use ssh to access your kodi server / nas:
;; (setq kodi-access-method "smb/ftp/adb...")


;;; Code:

(require 'json)
(require 'request)
(require 'let-alist)
(require 'subr-x)
(require 'cl-lib)
(require 'f)
;; (require 'elnode)

(defcustom kodi-host-name "localhost:8080"
  "Host to access Kodi remote control."
  :type 'string
  :group 'kodi-remote)
(defcustom kodi-dangerous-options nil
  "Option to give access for destructive operations."
  :type 'boolean
  :group 'kodi-remote)
(defcustom kodi-access-host nil
  "Host to access media over tramp."
  :type 'string
  :group 'kodi-remote)
(defcustom kodi-access-method "ssh"
  "Method to access media over tramp."
  :type 'string
  :group 'kodi-remote)
(defvar kodi-show-df nil)
(defvar kodi-active-player -1)
(defvar kodi-active-window nil)
(defvar kodi-fullscreen nil)
(defvar kodi-volume nil)
(defvar kodi-properties nil)
(defvar kodi-request-running nil)
(defvar kodi-watch-filter '((movie . "unseen")
			    (series . "unseen")
			    (music . "all")))
(defvar kodi-selected-show nil)
(defvar-local kodi-remote-refresh-function nil
  "The name of the function used to redraw a buffer.")
(defvar kodi-network-interface nil
  "Network interface connecting to kodi.")
(defvar kodi-elnode-directory nil
  "The temp dir to use for serving streams to kodi.")

(defun kodi-client-ip ()
  "Function to create the local client ip address."
  (format-network-address
   (assoc-default
    kodi-network-interface
    (network-interface-list)) t))

(defun kodi-json-url ()
  "Function to create the full json-url of the kodi-instance."
  (concat "http://" kodi-host-name "/jsonrpc"))

(defun kodi-remote-directory ()
  "Builds remote base path."
  (concat "/" kodi-access-method ":" kodi-access-host ":/"))

(defun kodi-get-watch-filter ()
  "Helper function to get the filter setting for the current media type/buffer."
  (alist-get (kodi-get-filter-type) kodi-watch-filter))

(defun kodi-remote-post (method params)
  "Function to send post requests to the kodi instance.
Argument METHOD kodi json api argument.
Argument PARAMS kodi json api argument."
  (let* ((default-directory "~")
	 (request-data (append `(("id" . 0)
				 ("jsonrpc" . "2.0")
				 ("method" . ,method))
			       (when params
				   `(("params" . ,params))))))
    ;; (print request-data)
    (request
     (kodi-json-url)
     :type "POST"
     :data (json-encode request-data)
     :headers '(("Content-Type" . "application/json"))
     :parser 'json-read)
  (kodi-remote-sit-for-done)))

(defun kodi-remote-get (method params)
  "Function to send get requests to the kodi instance.
Argument METHOD kodi json api argument.
Argument PARAMS kodi json api argument."
  (setq kodi-request-running t)
  (let* ((default-directory "~")
	 (request-data
	  (append `(("id" . 0)
		    ("jsonrpc" . "2.0")
		    ("method" . ,method))
		  (when params
		    `(("params" . ,params))))))
    (request
     (kodi-json-url)
     :data (json-encode request-data)
     :headers '(("Content-Type" . "application/json"))
     :success (cl-function (lambda (&key data &allow-other-keys)
			     (when data
			       (setq kodi-properties
				     (let-alist
					 (json-read-from-string data)
				       .result))
			       (setq kodi-request-running nil))))
     :error (cl-function
	     (lambda (&key error-thrown &allow-other-keys)
	       (message "Got error: %S" error-thrown)))
     :parser 'buffer-string))
  (kodi-remote-sit-for-done)
  kodi-properties)

;;;###autoload
(defun kodi-remote-start-music-party ()
  "Start musik playing in kodi in party mode."
  (interactive)
  (let* ((params '(("item" . (("partymode" . "music"))))))
    (kodi-remote-post "Player.Open" params)))

;;;###autoload
(defun kodi-remote-toggle-extended-info ()
  "Toggle extended media information."
  (interactive)
  (setq kodi-show-df (not kodi-show-df))
  (revert-buffer))

;;;###autoload
(defun kodi-remote-play-pause ()
  "Toggle play/pause of active player."
  (interactive)
  (kodi-remote-get-active-player-id)
  (let* ((params `(("playerid" . ,kodi-active-player))))
    (kodi-remote-post "Player.PlayPause" params)))

;;;###autoload
(defun kodi-remote-stop ()
  "Stopps active player."
  (interactive)
  (kodi-remote-get-active-player-id)
  (let* ((params `(("playerid" . ,kodi-active-player))))
    (kodi-remote-post "Player.Stop" params)))

(defun kodi-remote-player-seek (direction)
  "Seek active player.
Argument DIRECTION which direction and how big of step to seek."
  (kodi-remote-get-active-player-id)
  (let* ((params `(("playerid" . ,kodi-active-player)
		   ("value" . ,direction))))
    (kodi-remote-post "Player.Seek" params)))

(defun kodi-remote-play-database-id (field-name id resume)
  "Play kodi item with the id type in FIELD-NAME and the given ID.
Argument RESUME continue playback where stopped before else start from beginning."
  (let* ((do-resume (when (and resume
			       (< 0 (assoc-default 'position resume)))
		      (y-or-n-p "Do you wanna resume? ")))
	 (params `(("item" . ((,field-name . ,id)))
		   ("options" . (("resume" . ,(if do-resume t -1)))))))
    (kodi-remote-post "Player.Open" params)))

(defun kodi-remote-player-pos ()
  "Update currently active window."
  (kodi-remote-get-active-player-id)
  (let* ((params `(("playerid" . ,kodi-active-player)
		   ("properties" . ("time")))))
    (kodi-remote-get "Player.GetProperties" params)))

(defun kodi-seek-to-time (minutes seconds)
  "Seek active player.
Argument SECONDS to seek to.
Argument MINUTES to seek to."
  (kodi-remote-get-active-player-id)
  (let* ((params `(("playerid" . ,kodi-active-player)
		   ("value" . (("minutes" . ,minutes)
			       ("seconds" . ,seconds))))))
    (kodi-remote-post "Player.Seek" params)))

(defun kodi-time-in-seconds (hours minutes seconds)
  "Convert HOURS MINUTES and SECONDS to total seconds."
  (+ seconds (* 60 (+ (* 60 hours) minutes))))

(defun kodi-remote-play-timings (entries &optional same-file)
  "Seeks and Monitors recursively to playlist ENTRIES start and end timings.
Optional argument SAME-FILE set if it's only a different timeframe but the same file."
  (let* ((entry (car entries))
	 (url (alist-get 'url entry))
	 ;; (start-time-in-sec (alist-get 'start-time-in-sec entry))
	 (end-time-in-sec (alist-get 'end-time-in-sec entry))
	 (start-min (alist-get 'start-min entry))
	 (start-sec (alist-get 'start-sec entry))
	 (rest (cdr entries))
	 (end-reached nil))
    (if same-file
	(kodi-seek-to-time start-min start-sec)
      ;; if play-stream-url doesn't work replace it with play-video-url
      (if (string-prefix-p "http" url)(kodi-remote-play-stream-url url)
	(kodi-remote-play-url url)))
    (while (not end-reached)
	(sleep-for 1)
	(let* ((vid-time (cdar (kodi-remote-player-pos)))
	       (hours (alist-get 'hours vid-time ))
	       (minutes (alist-get 'minutes vid-time ))
	       (seconds (alist-get 'seconds vid-time ))
	       (time-in-sec (kodi-time-in-seconds hours minutes seconds)))
	  (when (> time-in-sec end-time-in-sec)
	    (setq end-reached t))))
    (when rest
      (kodi-remote-play-timings rest (equal url (alist-get 'url (car rest)))))))

(defun kodi-remote-build-exercise-tracks (exercise)
  "Convert a the raw playlist data to the required kodi json format.
Argument EXERCISE TODO."
  (let* ((start (s-split ":" (nth 2 exercise)))
	 (start-min (string-to-number (car start)))
	 (start-sec (string-to-number (cadr start)))
	 (end (s-split ":" (nth 3 exercise)))
	 (end-min (string-to-number (car end)))
	 (end-sec (string-to-number (cadr end))))
    `((url . ,(nth 0 exercise))
      (start-min . ,start-min)
      (start-sec . ,start-sec)
      (end-min . ,end-min)
      (end-sec . ,end-sec)
      (start-time-in-sec . ,(kodi-time-in-seconds 0 start-min start-sec))
      (end-time-in-sec . ,(kodi-time-in-seconds 0 end-min end-sec)))))

(defun kodi-remote-org-read-table (file linenr)
  "Return the table data as list.
Argument FILE name of the file with the org table.
Argument LINENR where the table data starts."
  (let* ((fstring (f-read file))
	 (lines (s-split "\n" fstring)))
    (mapcar (lambda (line)
	      (mapcar 's-trim (s-split "|" line t)))
	    (nthcdr linenr lines))))

;;;###autoload
(defun kodi-remote-exercise (file)
  "Start a special playlist with timecodes of items.
useful for reordering training videos or mashup videos or
whenever you want only a part of a media FILE in your playlist"
  (interactive "F")
  (let* ((exercises-raw
	  (cl-remove-if (lambda (entry)
		       (equal "x" (nth 4 entry)))
		     (kodi-remote-org-read-table file 3)))
	 (exercises (mapcar 'kodi-remote-build-exercise-tracks
			    (nbutlast exercises-raw))))
    (kodi-remote-play-timings exercises)))

(defun kodi-remote-play-continious ()
  "Play all items in the list starting at curser pos."
  (interactive)
  (let* ((start (cl-position (assq (tabulated-list-get-id)
			           tabulated-list-entries)
			     tabulated-list-entries))
	 (ids '(("*kodi-remote-music*" . "songid")
		("*kodi-remote-series-episodes*" . "episodeid"))))
    (kodi-remote-playlist-clear)
    (dolist (button (seq-subseq tabulated-list-entries start))
      (let* ((params `(("playlistid" . 1)
		       ("item" . ((,(assoc-default (buffer-name) ids)
				   . ,(car button)))))))
	(kodi-remote-post "Playlist.Add" params))))
  (kodi-remote-playlist-play))

(defun kodi-remote-play-playlist-item (position)
  "Play series in playlist POSITION with given ID."
  (let* ((params `(("item" . (("playlistid" . 1)
			      ("position" . ,position))))))
    (kodi-remote-post "Player.Open" params)))

;;;###autoload
(defun kodi-remote-toggle-fullscreen ()
  "Toggle Fullscreen."
  (interactive)
  (kodi-remote-get-active-player-id)
  (let* ((params `(("fullscreen" . "toggle"))))
    (kodi-remote-post "Gui.SetFullScreen" params)))

;;;###autoload
(defun kodi-remote-set-volume (offset)
  "Change volume recording to OFFSET."
  (interactive)
  (kodi-remote-get-volume)
  (let* ((vol (+ kodi-volume offset)))
    (let* ((params `(("volume" . ,vol))))
      (kodi-remote-post "Application.SetVolume" params))))

(defun kodi-remote-input (input)
  "Function to send post INPUT json requests."
  (let ((default-directory "~"))
    (request
     (kodi-json-url)
     :type "POST"
     :data (json-encode `(("id" . 1)
			  ("jsonrpc" . "2.0")
			  ("method" . ,input)
			  ))
     :headers '(("Content-Type" . "application/json"))
     :parser 'json-read))
  (kodi-remote-sit-for-done))

(defun kodi-remote-input-execute-action (action)
  "Function to send post ACTION json requests."
  (let* ((params `(("action" . ,action))))
    (kodi-remote-post "Input.ExecuteAction" params)))

(defun kodi-remote-input-direct (seek input)
  "Move horrizontal or SEEK.
Depending on current window move horizontal in menu (INPUT)
 or SEEK big forward/backward."
  (kodi-remote-get-active-window)
  (if (string-equal kodi-active-window "Fullscreen video")
      (kodi-remote-player-seek seek)
    (kodi-remote-input input)))

;; todo: need to compare to other active windows (like musik) for actions.
;;;###autoload
(defun kodi-remote-input-left ()
  "Move left in menu or seek small backward."
  (interactive)
  (kodi-remote-input-direct "smallbackward" "Input.Left"))

;;;###autoload
(defun kodi-remote-input-right ()
  "Move right in menu or seek small forward."
  (interactive)
  (kodi-remote-input-direct "smallforward" "Input.Right"))

;;;###autoload
(defun kodi-remote-input-up ()
  "Move up in menu or seek big forward."
  (interactive)
  (kodi-remote-input-direct "bigforward" "Input.Up"))

;;;###autoload
(defun kodi-remote-input-down ()
  "Move down in menu or seek big backward."
  (interactive)
  (kodi-remote-input-direct "bigbackward" "Input.Down"))

;;;###autoload
(defun kodi-remote-input-back ()
  "Move back menu."
  (interactive)
  (kodi-remote-input "Input.Back"))

;;;###autoload
(defun kodi-remote-input-delete ()
  "Delete selected file."
  (interactive)
  (kodi-remote-input-execute-action "delete"))

;;;###autoload
(defun kodi-remote-input-context-menu ()
  "Activate context menu."
  (interactive)
  (kodi-remote-input "Input.ContextMenu"))

;;;###autoload
(defun kodi-remote-input-home ()
  "Switch to the home screen."
  (interactive)
  (kodi-remote-input "Input.Home"))

;;;###autoload
(defun kodi-remote-input-enter ()
  "Select active item."
  (interactive)
  (kodi-remote-input-execute-action "select"))

;;;###autoload
(defun kodi-remote-playlist-previous ()
  "Previous song in kodi music player."
  (interactive)
  (kodi-remote-playlist-goto "previous"))

;;;###autoload
(defun kodi-remote-playlist-next ()
  "Next song in kodi music player."
  (interactive)
  (kodi-remote-playlist-goto "next"))

(defun kodi-remote-get-volume ()
  "Poll current volume."
  (let* ((params '(("properties" . ("volume")))))
    (kodi-remote-get "Application.GetProperties" params))
  (setq kodi-volume (let-alist kodi-properties .volume)))

(defun kodi-remote-visibility-filter ()
  "Create filter json string for media request."
  (let* ((filter (kodi-get-watch-filter)))
    (unless (equal "all" filter)
      `(("field" . "playcount")
	("operator" .
	 ,(pcase filter
	    ("seen" "greaterthan")
	    ("unseen" "is")))
	("value" . "0" )))))

(defvar kodi-selected-artist)

(defun kodi-remote-filter-band ()
  "Filter by Band name."
  (interactive)
  (kodi-remote-get-artist-list)
  (let* ((name
	  (ido-completing-read
	   "Band: "
	   (mapcar (apply-partially #'assoc-default 'artist)
		   (assoc-default 'artists kodi-properties)))))
    (setq kodi-selected-artist name))
  (kodi-remote-draw-music))

(defun kodi-remote-get-songs (&optional id)
  "Poll list of songs.
Optional argument ID limits to a specific artist."
  (cl-macrolet ((lcons (a b) `(unless (null ,b) (list (cons ,a ,b)))))
    (let* ((filter-watched (kodi-remote-visibility-filter))
	   (artist-filter (when id `(("operator" . "is")
				     ("field" . "artist")
				     ("value" . ,id))))
	   (filters (remove 'nil `(,artist-filter ,filter-watched)))
	   (filter-string (lcons "filter" (lcons "and" filters)))
	   (properties (seq-into (kodi-remote-media-fields 'song) 'vector))
	   (params (cons `("properties" . ,properties) filter-string)))
      (kodi-remote-get "AudioLibrary.GetSongs" params))))

(defun kodi-remote-get-item-size (file)
  "Poll item Size.
Argument FILE the name of the file you want the size."
  (let* ((params `(("file" . ,file)
		   ("properties" . ["size"]))))
  (kodi-remote-get "Files.GetFileDetails" params)))

(defun kodi-remote-get-sources (type)
  "Poll item sources.
Argument TYPE video or audio."
  (let* ((params `(("media" . ,type))))
    (kodi-remote-get "Files.GetSources" params))
  (assoc-default 'sources kodi-properties))


(defun kodi-remote-get-artist-list ()
  "Poll music artists."
  (let* ((params '(("properties" . ["genre"]))))
  (kodi-remote-get "AudioLibrary.GetArtists" params)))

(defun kodi-remote-get-movies ()
  "Poll movies."
  (kodi-remote-get-item 'movie "VideoLibrary.GetMovies" 'movies "video"))

(defun kodi-remote-get-show-list ()
  "Poll show list."
  (kodi-remote-get-item 'tvshow "VideoLibrary.GetTVShows" 'tvshows "video"))

(defun kodi-remote-get-series-episodes (&optional show-id)
  "Poll episodes from show(s).
Optional argument SHOW-ID limits to a specific show."
  (kodi-remote-get-item 'episode "VideoLibrary.GetEpisodes"
			'episodes "video" "tvshowid" show-id))

(defun kodi-remote-get-item (entry-name request-method &optional
					data-field source-type id-name id)
  "Poll unwatches episodes from show.
Optional argument SHOW-ID limits to a specific show.
Argument ENTRY-NAME TODO.
Argument REQUEST-METHOD TODO.
Optional argument DATA-FIELD TODO.
Optional argument SOURCE-TYPE TODO.
Optional argument ID-NAME TODO.
Optional argument ID TODO."
  (let* ((filter (kodi-remote-visibility-filter))
	 (fields (kodi-remote-media-fields entry-name))
	 (sources (kodi-remote-get-sources source-type))
	 (disk-free (seq-contains fields 'diskfree))
	 (params (append (when id (list (append `(,id-name) id)))
			 `(("properties" .
			    ,(seq-into (if disk-free
					   (seq-subseq fields 0 -2) fields)
				       'vector)))
			 (when filter (list (append (list "filter")
						    filter))))))
    (kodi-remote-get request-method params)
    (when (and kodi-show-df disk-free kodi-dangerous-options
	       (boundp 'kodi-access-host))
      (kodi-remote-append-disk-free data-field sources))))

(defun kodi-remote-disk-free (form-string func name dividor)
  "Helper function to get free space string of item.
Argument FORM-STRING the format of the string.
Argument FUNC I don't know.
Argument NAME TODO.
Argument DIVIDOR TODO."
  (format form-string (/ (funcall func (substring name 1))
			 (expt 2 dividor))))

(defvar kodi--sources)
;; FIXME: The GNU convention only uses "path" to refer to a list of directories
;; (as in $PATH and load-path) and not for things like "/a/b/c.pdf" which
;; it calls "filenames".
(defvar kodi-path-df)

(defun kodi-remote-build-disk-strings (element)
  "Create Disk Information of ELEMENT."
  (let* ((default-directory (kodi-remote-directory))
	 (file-name (assoc-default 'file element))
	 (base-path (cdaar (seq-filter
			    (lambda (elt)
			      (file-in-directory-p
			       file-name
			       (assoc-default 'file elt)))
			    kodi--sources)))
	 (size (or (assoc-default base-path kodi-path-df)
		   (elt (split-string
			 (eshell-command-result
		    (format "df \"%s\" -h --output=avail"
			    (substring base-path 1))))
			1)))
	 (diskused (apply 'kodi-remote-disk-free
			  (if (equal (buffer-name) "*kodi-remote-series*")
			      `("%8.1fG" kodi-directory-size ,file-name 30)
			    `("%8.1fM" kodi-file-size ,file-name 20)))))
    ;; (kodi-remote-get-item-size file-name)
    (setq kodi-path-df (append kodi-path-df `((,base-path . ,size))))
    (append element `((diskfree . ,size)) `((diskused . ,diskused)))))

(defun kodi-remote-append-disk-free (data-name sources)
  "Helper Function to get free space of items.
Argument DATA-NAME TODO.
Argument SOURCES TODO."
  (let ((kodi-path-df '())
        (kodi--sources sources))
    (setq kodi-properties
	  `((,data-name
	     . ,(mapcar
		 #'kodi-remote-build-disk-strings
		 (assoc-default data-name kodi-properties)))))))

(defun kodi-file-size (filename)
  "Return size of file FILENAME in bytes.
The size is converted to float for consistency.
    This doesn't recurse directories."
  (float
   (or (file-attribute-size			; might be int or float
	(file-attributes filename))
       0)))

(defun kodi-directory-size (directory)
  "Return size of directory DIRECTORY in bytes.
The size is converted to float for consistency.
    This is includes 1 level of sub directories."
  (apply '+ (mapcar
	     (lambda
	       (entry)
	       (if (file-attribute-type (cdr entry))
		   (kodi-directory-size (concat directory (car entry)))
		 (float
		  (file-attribute-size
		   (cdr entry)))))
	     (cddr (directory-files-and-attributes directory)))))


;;;###autoload
(defun kodi-remote-playlist-add-item ()
  "Add item to playlist."
  (interactive)
  (let* ((ids '(("*kodi-remote-music*" . "songid")
		("*kodi-remote-series-episodes*" . "episodeid")))
	 (params `(("playlistid" . 1)
		   ("item" . ((,(assoc-default (buffer-name) ids)
			       . ,(tabulated-list-get-id)))))))
    (kodi-remote-post "Playlist.Add" params)))

;;;###autoload
(defun kodi-remote-playlist-play ()
  "Play current active playlist."
  (interactive)
  (let* ((params `(("item" . (("playlistid" . 1))))))
    (kodi-remote-post "Player.Open" params)))

(defun kodi-profile-path ()
  "Return the profile path of the kodi instance."
  (with-current-buffer
      (url-retrieve-synchronously
       (concat "http://" kodi-host-name
	       "/vfs/special%3a%2f%2flogpath%2fkodi.log"))
    (re-search-forward "special://home/ is mapped to: ")
    (re-search-forward ".*")
    (match-string 0)))

;;;###autoload
(defun kodi-remote-playlist-save (name)
  "Save playlist as NAME."
  (interactive "sName:")
  (when (and kodi-dangerous-options (boundp 'kodi-access-host))
    (kodi-remote-playlist-get)
    (let* ((default-directory (kodi-remote-directory))
	   (file-name (concat (seq-drop (kodi-profile-path) 0)
			      "/userdata/playlists/video/"
			      name ".m3u"))
	   (items (cdr (assoc 'items kodi-properties)))
	   (entries (mapconcat
		     (lambda (item)
		       (format "#EXTINF:0,%s\n%s"
			       (assoc-default 'label item)
			       (assoc-default 'file item))
		       ) items "\n")))
      (if (file-writable-p file-name)
	  (write-region (concat "#EXTM3U\n" entries) nil file-name)))))


;;;###autoload
(defun kodi-remote-playlists-remove ()
  "Remove playlist."
  (interactive)
  (when (and kodi-dangerous-options (boundp 'kodi-access-host))
    (let* ((default-directory (kodi-remote-directory))
	   (file-name (seq-drop (tabulated-list-get-id) 1)))
      (if (file-writable-p file-name)
	  (delete-file file-name)))))

;;;###autoload
(defun kodi-remote-playlists-rename (name)
  "Rename playlist to new NAME."
  (interactive "sName:")
  (when (and kodi-dangerous-options (boundp 'kodi-access-host))
      (let* ((default-directory (kodi-remote-directory))
	     (file-name (seq-drop (tabulated-list-get-id) 1))
	     (file-name-new (concat (seq-drop (kodi-profile-path) 1)
				    "/userdata/playlists/video/"
				    name ".m3u")))
	(if (file-writable-p file-name)
	    (rename-file file-name file-name-new)))))

;;;###autoload
(defun kodi-remote-playlist-clear ()
  "Clear playlist."
  (interactive)
  (let* ((params `(("playlistid" . 1))))
    (kodi-remote-post "Playlist.Clear" params)))

;; ;; (setq elnode-webserver-docroot "~/webroot")
;; ;; (setq elnode-send-file-program (locate-file "cat" exec-path))
;; (setq elnode-send-file-program "cat")
;; (defconst kodi-elnode-handler
;;    (elnode-webserver-handler-maker "/tmp/webroot/")
;;    )

(defun kodi-remote-playlist-add-url (url)
  "Add item/video to playlist.
Argument URL the file url to the media."
  (interactive "sUrl: ")
  (let* ((params `(("playlistid" . 1)
		   ("item" . (("file" . ,url))))))
    (kodi-remote-post "Playlist.Add" params)))

;;;###autoload
(defun kodi-remote-playlist-remove ()
  "Remove item/video from playlist."
  (interactive)
  (let* ((params `(("playlistid" . 1)
		   ("position" . ,(tabulated-list-get-id)))))
    (kodi-remote-post "Playlist.Remove" params)))

(defun kodi-remote-playlist-get ()
  "Requests playlist items."
  (let* ((params '(("properties" . ["duration" "runtime" "title" "file"])
		   ("playlistid" . 1))))
    (kodi-remote-get "Playlist.GetItems" params)))

(defun kodi-remote-playlist-swap (direction)
  "Move item/video up in the playlist.
Argument DIRECTION can be up or down."
  (if-let ((position1 (tabulated-list-get-id))
	   (difference '(("up" . -1) ("down" . 1)))
	   (position2 (+ position1 (assoc-default direction difference)))
	   (max (length tabulated-list-entries))
	   (positions (list position1 position2))
           ;; FIXME: Use `cl-every'?
	   (eval (cons 'and (mapcar (lambda (x)(<= 0 x max)) positions)))
	   (params `(("playlistid" . 1)
		     ("position1" . ,position1)
		     ("position2" . ,position2))))
      (kodi-remote-post "Playlist.Swap" params)
    ;; (kodi-remote-playlist-draw)
    ))

;;;###autoload
(defun kodi-remote-playlist-move-up ()
  "Move item/video up in the playlist."
  (interactive)
  (kodi-remote-playlist-swap "up"))

;;;###autoload
(defun kodi-remote-playlist-move-down ()
  "Move item/video up in the playlist."
  (interactive)
  (kodi-remote-playlist-swap "down"))

(defun kodi-remote-playlists-get ()
  "Requests playlist items."
  (when (and kodi-dangerous-options
	   (boundp 'kodi-access-host))
      (let* ((params `(("directory" .
			,(concat (kodi-profile-path)
				 "/userdata/playlists/video"))
		       ("properties" . ("title")))))
	(kodi-remote-get "Files.GetDirectory" params))))

(defun kodi-remote-video-scan ()
  "Update availible/new videos."
  (kodi-remote-post "VideoLibrary.Scan" nil))

(defun kodi-remote-audio-scan ()
  "Update availible/new videos."
  (kodi-remote-post "AudioLibrary.Scan" nil))

(defun kodi-remote-get-episode-details (id)
  "Poll details of a episode.
Argument ID kodi series database identifier."
  (let* ((params `(("episodeid" . ,id)
		   ("properties" . ("playcount")))))
    (kodi-remote-get "VideoLibrary.GetEpisodeDetails" params)))

(defun kodi-remote-get-active-window ()
  "Update currently active window."
  (let* ((params '(("properties" . ("currentwindow")))))
    (kodi-remote-get "Gui.GetProperties" params))
  (setq kodi-active-window (let-alist kodi-properties .currentwindow.label)))

(defun kodi-remote-get-active-player-id ()
  "Update currently active player."
  (kodi-remote-get "Player.GetActivePlayers" nil)
  (setq kodi-active-player (let-alist (elt kodi-properties 0) .playerid)))

;;;###autoload
(defun kodi-remote-volume-decrease ()
  "Decrease the volume of kodi."
  (interactive)
  (kodi-remote-set-volume -10))

;;;###autoload
(defun kodi-remote-volume-increase ()
  "Increase the volume of kodi."
  (interactive)
  (kodi-remote-set-volume 10))

;;;###autoload
(defun kodi-remote-is-fullscreen ()
  "Update fullscreen status."
  (let* ((params '(("properties" . ("fullscreen")))))
    (kodi-remote-get "Gui.GetProperties" params))
  (let-alist kodi-properties .fullscreen))

(defun kodi-remote-playlist-goto (pos)
  "Function to set the POS of kodi musik player."
  (request
   (kodi-json-url)
   :type "POST"
   :data (json-encode
	  `(("id" . 1)("jsonrpc" . "2.0")
	    ("method" . "Player.GoTo")
	    ("params" . (("playerid" . 0)
			 ("to" . ,pos)))))
   :headers '(("Content-Type" . "application/json"))
   :parser 'json-read))

;;;###autoload
(defun kodi-remote-play-url (url &optional resume)
  "Plays either direct links to video files or plugin play command URLs.
Optional argument RESUME toggles wether if file should be resumed from last stopped position."
  (interactive "surl: ")
  (kodi-remote-post "Playlist.Clear" '(("playlistid" . 1)))
  (kodi-remote-post "Player.Open"
		    `(("item" . (("file" . ,url)))
		      ("options" . (("resume" .
				     ,(if resume t -1)))))))

;;;###autoload
(defun kodi-remote-play-stream-url (video-url)
  "Convert url to a kodi youtube plugin url and sends that to kodi.
Argument VIDEO-URL A Url from a youtube video."
  (interactive "surl: ")
  (let* ((video-id (nth 1 (split-string video-url "?v=")))
	 (stream-url
	  (concat
	   "plugin://plugin.video.youtube/play/?video_id="
	   video-id)))
    (kodi-remote-play-url stream-url)))

(defun kodi-remote-youtube-operation (video-url func)
  "Wrapper function for youtube-dl.
Extracts url / title from VIDEO-URL and starts FUNC"
  (let* ((response
	  (shell-command-to-string
	   (concat "youtube-dl --no-warnings -f best -g -e "
		   video-url)))
	 (url (nth 1 (split-string response "\n"))))
    (funcall func url)))

;;;###autoload
(defun kodi-remote-append-video-url (video-url)
  "Append urls from videos like youtube to kodi playlists.
Could be used for other sites, too.  whatever youtube-dl
supports.  Argument VIDEO-URL A Url from a youtube video."
  (interactive "surl: ")
  (kodi-remote-youtube-operation video-url
   (lambda (url) (if kodi-network-interface
		  ;; (kodi-remote-playlist-add-url-pls url title)
		  (kodi-remote-playlist-add-url url)
		(kodi-remote-playlist-add-url url)))))

;;;###autoload
(defun kodi-remote-play-video-url (video-url)
  "Sends urls from videos like youtube to kodi.
Could be used for other sites, too.  whatever youtube-dl
supports.  Argument VIDEO-URL A Url from a youtube video."
  (interactive "surl: ")
  (kodi-remote-youtube-operation video-url
   (lambda (url) (kodi-remote-play-url url))))

; elnode seems broken in newer emacs versions

;; (defun kodi-setup-elnode ()
;;   "Start elnode deamon and set up everything if not done already."
;;   ;; (print (elnode-ports))
;;   (when (not (member 8028 (elnode-ports)))
;;     (setq kodi-elnode-directory (make-temp-file "kodi-" t))
;;     (setq elnode-send-file-program "cat")
;;     (defconst kodi-elnode-handler
;;       (elnode-webserver-handler-maker kodi-elnode-directory))
;;     (elnode-start kodi-elnode-handler :port 8038 :host "*")))

;; (defun kodi-remote-playlist-add-url-pls (url &optional label)
;;   "Add item/video to playlist.
;; Argument URL the video url.
;; Optional argument LABEL a custom label for the file."
;;   ;; (interactive "sUrl: ")
;;   (kodi-setup-elnode)
;;   (with-temp-file (expand-file-name
;; 		   (format  "%s.pls" label) kodi-elnode-directory)
;;     (insert (string-join `("[playlist]"
;; 			   ,(concat "File1=" url "")
;; 			   ,(concat "Title1=" label "")
;; 			   "NumberOfEntries=1\n"
;; 			   ) "\n")))
;;   (let* ((stream-url (format "http://%s:8028/%s.pls"
;; 			     (kodi-client-ip) label))
;;   	 (params `(("playlistid" . 1)
;; 		   ("item" . (("file" . ,stream-url))))))
;;     (kodi-remote-post "Playlist.Add" params))
;;   ;; (let* ((url2 (concat "http://" kodi-remote-local-host
;;   ;; 			 ":8028/"))
;;   ;; 	   (params `(("params" . (("directory" . ,url2))))))
;;   ;;   (kodi-remote-post "VideoLibrary.Scan" params))
;;   )


;; (defun kodi-remote-playlist-add-url-strm (url &optional label)
;;   "Add item/video to playlist.
;; Argument URL the url to the media.
;; Optional argument LABEL cutom name of the entry."
;;   ;; (interactive "sUrl: ")
;;   (kodi-setup-elnode)
;;   ;; (print kodi-elnode-directory)
;;   (with-temp-file (expand-file-name
;; 		   (format "%s.strm" label)
;; 		   kodi-elnode-directory)
;;     (insert url))
;;   ;; (with-temp-file (expand-file-name
;;   ;; 		       "youtube-video.nfo" full-dir)
;;   ;; 	(insert (format "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\" ?>\n<movie>\n<title>%s</title>\n</movie>" label)))
;;   (let* ((stream-url (format "http://%s:8028/%s.strm"
;; 			     kodi-remote-local-host label))
;; 	 (params `(("playlistid" . 1)
;; 		   ("item" . (("file" . ,stream-url))))))
;;     (kodi-remote-post "Playlist.Add" params))
;;   ;; (let* ((url2 (concat "http://" kodi-remote-local-host
;;   ;; 			 ":8028/youtube-titel-321/"))
;;   ;; 	   (params `(("params" . (("directory" . ,url2))))))
;;   ;;   (kodi-remote-post "VideoLibrary.Scan" params))
;; )


(defvar kodi-remote-keyboard-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "m") 'kodi-remote-music)
    (define-key map (kbd "SPC") 'kodi-remote-play-pause)
    (define-key map (kbd "<left>") 'kodi-remote-input-left)
    (define-key map (kbd "<right>") 'kodi-remote-input-right)
    (define-key map (kbd "<up>") 'kodi-remote-input-up)
    (define-key map (kbd "<down>") 'kodi-remote-input-down)
    (define-key map (kbd "<backspace>") 'kodi-remote-input-back)
    (define-key map (kbd "<return>") 'kodi-remote-input-enter)
    (define-key map (kbd "x") 'kodi-remote-stop)
    (define-key map (kbd "<delete>") 'kodi-remote-input-delete)
    ;; start dvorak specific keybindings
    (define-key map (kbd "h") 'kodi-remote-input-left)
    (define-key map (kbd "n") 'kodi-remote-input-right)
    (define-key map (kbd "c") 'kodi-remote-input-up)
    (define-key map (kbd "t") 'kodi-remote-input-down)
    ;; end dvorak specific keybindings
    (define-key map (kbd "=") 'kodi-remote-volume-increase)
    (define-key map (kbd "+") 'kodi-remote-volume-increase)
    (define-key map (kbd "-") 'kodi-remote-volume-decrease)
    (define-key map (kbd "<tab>") 'kodi-remote-toggle-fullscreen)
    map)
  "Keymap for `kodi-remote-keyboard-mode'.")

(define-derived-mode kodi-remote-keyboard-mode special-mode "kodi-remote-keyboard"
  "Major mode for remote controlling kodi instance with keyboard commands
Key bindings:
\\{kodi-remote-keyboard-mode-map}"
  (setq cursor-type nil))

;;;###autoload
(defun kodi-remote-keyboard ()
  "Open a `kodi-remote-keyboard-mode' buffer."
  (interactive)
  (let* ((name "*kodi-remote-keyboard*")
         (buffer (get-buffer-create name)))
    (unless (eq buffer (current-buffer))
      (with-current-buffer buffer
        (let ((inhibit-read-only t) )
          (erase-buffer)
          (kodi-remote-keyboard-mode)
          (insert (concat "Kodi Remote:\n"
                          (substitute-command-keys
                           "\\{kodi-remote-keyboard-mode-map}"))))
        (switch-to-buffer-other-window buffer)))))

(defun kodi-get-filter-type ()
  "Return media type for current buffer."
  (let* ((type-map '((music . "*kodi-remote-music*")
		     (series . "*kodi-remote-series-episodes*")
		     (series . "*kodi-remote-series*")
		     (movie . "*kodi-remote-movies*"))))
    (car (rassoc (buffer-name) type-map))))

(defun kodi-switch-watch-filter ()
  "Switch between visability scope of entries."
  (interactive)
  (let* ((filters '("all" "unseen" "seen"))
	 (filter (kodi-get-watch-filter))
	 ;; (watch-filter (assoc-default (kodi-get-filter-type) kodi-watch-filter))
	 (new-filter (or (nth (+ 1 (seq-position filters filter)) filters)
			 (car filters))))
    (setf (alist-get (kodi-get-filter-type) kodi-watch-filter) new-filter)))

(defun kodi-remote-toggle-visibility ()
  "Toggle visability of watched/listened media."
  (interactive)
  (kodi-switch-watch-filter)
  (revert-buffer))

(defun kodi-remote-delete-multiple (ids)
  "Deletes all entries with id in IDS list."
  (mapcar 'kodi-remote-delete-entry ids))

(defun kodi-remote-delete-entry (id)
  "Deletes episode with ID over tramp.
For it to work ‘kodi-dangerous-options’ must be set to t
and ‘kodi-access-host’ must be set to the hostname of your kodi-file host."
  (let* ((default-directory "~"))
    (when (and kodi-dangerous-options (boundp 'kodi-access-host))
      (let* ((params `(("episodeid" . ,id)
		       ("properties" . ("file")))))
	(kodi-remote-get "VideoLibrary.GetEpisodeDetails" params))
      (let* ((default-directory (kodi-remote-directory))
	     (file-name
	      (substring
	       (decode-coding-string
		(let-alist
		    kodi-properties .episodedetails.file)
		'utf-8)
	       1)))
	(if (file-writable-p file-name )
	    (delete-file file-name)))
      (let* ((params `(("episodeid" . ,id ))))
	(kodi-remote-post "VideoLibrary.RemoveEpisode" params)))))

(defun kodi-remote-series-clean ()
  "Cleans video library."
  (interactive)
  (kodi-remote-post "VideoLibrary.Clean" nil))

(defun kodi-remote-playlist-clean ()
  "Cleans video library."
  (interactive)
  (kodi-remote-post "Playlist.Clean" nil))

(defun kodi-remote-series-scan ()
  "Scans kodi for new video content."
  (interactive)
  (kodi-remote-post "VideoLibrary.Scan" nil))

(defun sbit-action (field-name obj)
  "Helper method for start buttons.
Argument FIELD-NAME the name of the id.
Argument OBJ the button obj."
  (kodi-remote-play-database-id
   field-name (button-get obj 'id)
   (button-get obj 'resume)))

(defun sbit-action-playlist (obj)
  "Helper method for playlist start buttons.
Argument OBJ the button obj."
  (kodi-remote-play-playlist-item
   (button-get obj 'id)))

(defun sbit-action-start-modes (obj)
  "Helper method for Main Menu start buttons.
Argument OBJ the button obj."
  (funcall (button-get obj 'args)))

(defun spiderbit-get-name (episode)
  "Return the name of a EPISODE."
  (decode-coding-string (cdr (assoc 'label episode)) 'utf-8) )

(defun kodi-show-get-number-of-unwatched (show)
  "Return number of unwatched episodes from a SHOW."
  (- (cdr (assoc 'episode show))
     (cdr (assoc 'watchedepisodes show))))

(defun kodi-show-get-number-of-episodes (show)
  "Return number of unwatched episodes from a SHOW."
  (pcase (kodi-get-watch-filter)
    ("all" (cdr (assoc 'episode show)))
    ("unseen" (- (cdr (assoc 'episode show))
	       (cdr (assoc 'watchedepisodes show))))
    ("seen" (cdr (assoc 'watchedepisodes show)))))

(defun kodi-remote-sit-for-done ()
  "Sits till the last json request is done."
  (let* ((waiting-time 0))
    (while (and kodi-request-running (< waiting-time 10.0))
      (sit-for 0.1)
      (setq waiting-time (+ 0.1 waiting-time)))))

(defun kodi-remote-series-episodes-wrapper (button)
  "Set the selected show and then displays episodes.
Argument BUTTON contains the show-id"
  (unless (equal button nil)
    (setq kodi-selected-show (button-get button 'id)))
  (kodi-remote-series-episodes))

(defun kodi-remote-songs-wrapper (button)
  "Set the selected artist and then displays songs.
Argument BUTTON contains the artist-id"
  (unless (equal button nil)
    (setq kodi-selected-artist (button-get button 'id)))
  (kodi-remote-songs))

(defun kodi-remote-media-fields (type)
  "Get the interesting fields of each media TYPE."
  (let* ((disk-fields (if kodi-show-df '(diskfree diskused))))
    (pcase type
      ('song '(artist year album track title file playcount duration))
      ('movie (cl-concatenate 'list '(title playcount resume file) disk-fields))
      ('episode (cl-concatenate 'list '(title episode playcount resume file) disk-fields))
      ('tvshow (cl-concatenate 'list '(title watchedepisodes episode file) disk-fields))
      ('file '(title)))))

(defun kodi-generate-entry (action id subitems _hide-ext item)
  "Generate tabulated-list entry for kodi media buffers.
Argument ACTION button action.
Argument ID button/entry id.
Argument SUBITEMS sets entry as category/tag with child entries.
Argument HIDE-EXT if t removes file extension from entry label
Argument ITEM the media data from kodi."
  (let* ((number-of-nodes
	  (when subitems
	      (kodi-show-get-number-of-episodes
	       item)))
	 (filter (kodi-get-watch-filter))
	 (subitemid (assoc-default id item))
	 (resume (assoc-default 'resume item))
	 (keys (append
		(cl-remove-if
		 (lambda (x)
		   (memq x `(playcount type file label
				       episode directory resume
				       title ,id)))
		 (kodi-remote-media-fields
		  (pcase id
		    ('songid 'song)('movieid 'movie)
		    ('episodeid 'episode)('tvshowid 'tvshow)
		    ('file 'file))))
		'(label)))
	 (playcount (assoc-default
		     'playcount item)))
    (when (or (null subitems)
	      (> number-of-nodes 0)
	      (equal filter "all"))
      (let* ((buttons
	      (mapcar
	       (lambda (elem)
		 `(,(kodi-remote-button-name elem item number-of-nodes)
		   action ,action
		   id ,subitemid
		   face ,
		   (if (and playcount
			    (> playcount 0))
		       'font-lock-comment-face
		     'default)
		   resume ,resume))
	       keys)))
	(list subitemid (seq-into buttons 'vector))))))

(defun kodi-remote-button-name (elem item number-of-nodes)
  "Generate Button name for Column ELEM.
Argument ITEM TODO.
Argument NUMBER-OF-NODES TODO."
  (decode-coding-string
   (if (equal
	elem 'watchedepisodes)
       (let ((x number-of-nodes))
	 (if (< 0 x) (number-to-string x) ""))
     (cl-typecase (assoc-default elem item)
       (vector (progn ;; (if (> (length (assoc-default elem item)) 1)
		  ;;     (print (assoc-default elem item)))
		  (elt (assoc-default elem item) 0)))
       (string (assoc-default elem item))
       (number (number-to-string
		 (assoc-default elem item)))))
   'utf-8))

(defun kodi-remote-draw ()
  "Draw the buffer with new contents via `kodi-refresh-function'."
  (with-silent-modifications
    (funcall kodi-remote-refresh-function ;; transmission-torrent-id
)))

(defun kodi-draw-tab-list (action parent id data-name subitems &optional hide-ext)
  "Create and draw a media overview buffer.
Argument ACTION button action.
Argument PARENT sets entry as category/tag with child entries.
Argument ID button/entry id.
Argument DATA-NAME name of the data we want to show.
Argument SUBITEMS sets entry as category/tag with child entries
Optional argument HIDE-EXT if t removes file extension from entry labels."
;; FIXME parent and subitems argument seems to be redundant
  (setq tabulated-list-entries
  	(remove nil (mapcar
		     (apply-partially
		      'kodi-generate-entry
		      (if parent action (apply-partially
					 'sbit-action action))
		      id subitems hide-ext)
		     (assoc-default data-name kodi-properties))))
  (setq tabulated-list-sort-key nil)
  (tabulated-list-init-header)
  (tabulated-list-print))

;;;###autoload
(defun kodi-remote-playlists-draw (&optional _arg _noconfirm)
  "Draw the list of playlists.
Optional argument _ARG revert excepts this param.
Optional argument _NOCONFIRM revert excepts this param."
  (interactive)
  (setq tabulated-list-format
        '[("Playlists" 30 t)])
  (kodi-remote-playlists-get)
  (kodi-draw-tab-list 'file nil 'file 'files nil t))

;;;###autoload
(defun kodi-remote-draw-movies (&optional _arg _noconfirm)
  "Draw a list of movies.
Optional argument _ARG revert excepts this param.
Optional argument _NOCONFIRM revert excepts this param."
  (interactive)
  (kodi-remote-tab-header "Movies" "movies")
  (kodi-remote-video-scan)
  (kodi-remote-get-movies)
  (kodi-draw-tab-list 'movieid nil 'movieid 'movies nil))

;;;###autoload
(defun kodi-remote-draw-shows (&optional _arg _noconfirm)
  "Draw a list of show entries.
Optional argument _ARG revert excepts this param.
Optional argument _NOCONFIRM revert excepts this param."
  (interactive)
  (kodi-remote-tab-header "Series" "series" t)
  (kodi-remote-video-scan)
  (kodi-remote-get-show-list)
  (kodi-draw-tab-list 'kodi-remote-series-episodes-wrapper t
		      'tvshowid 'tvshows t))

;;;###autoload
(defun kodi-remote-draw-episodes (&optional _arg _noconfirm)
  "Draw a list of episodes of all or a specific show.
Optional argument _ARG revert excepts this param.
Optional argument _NOCONFIRM revert excepts this param."
  (interactive)
  (kodi-remote-tab-header "Episode" "series-episodes")
  (kodi-remote-video-scan)
  (kodi-remote-get-series-episodes
   kodi-selected-show)
  (kodi-draw-tab-list 'episodeid nil
		      'episodeid 'episodes nil))

(defun kodi-remote-tab-header (media-column-name mode-tail-name &optional subitems)
  "Generate the header of a kodi media mode.
Argument MEDIA-COLUMN-NAME Entry name.
Argument MODE-TAIL-NAME Name of the media buffer type.
Optional argument SUBITEMS has this mode subitems."
  (setq tabulated-list-format
	(cl-concatenate 'vector
			(if subitems
			    '[("entries" 10 t)])
			(if (and kodi-dangerous-options
				 kodi-show-df)
			    '[("Disk Free" 10 t)
			      ("Disk Used" 10 t)])
			`[(,media-column-name  30 t)]))
  (let* ((filter (kodi-get-watch-filter)))
    (setq mode-name
	  (format "kodi-remote-%s: %s" mode-tail-name filter))))

;;;###autoload
(defun kodi-remote-draw-music (&optional _arg _noconfirm)
  "Draw a list of songs of all or a specific artist.
Optional argument _ARG revert excepts this param.
Optional argument _NOCONFIRM revert excepts this param."
  (interactive)
  (let* ((filter (kodi-get-watch-filter)))
    (setq tabulated-list-format
	  [("Artist" 15 t)("Year" 5 t)("Album" 15 t)
	   ("Track" 5 t)("Duration" 10 t)("Song" 30 t)])
    (setq mode-name
	  (format
	   "kodi-remote-music: %s"
	   (pcase filter
	     ("all" "all")
	     ("unseen" "not listenend")
	     ("seen" "listened")))))
  (kodi-remote-get-artist-list)
  (kodi-remote-get-songs kodi-selected-artist)
  (kodi-draw-tab-list 'songid nil 'songid 'songs nil))

(defun kodi-remote-draw-main (&optional _arg _noconfirm)
  "Draw the main Menu.
Optional argument _ARG revert excepts this param.
Optional argument _NOCONFIRM revert excepts this param."
  (interactive)
  (let* ((menu-entries
	  '(("Movies" . kodi-remote-movies)
	    ("Series" . kodi-remote-series)
	    ("Music" . kodi-remote-music)
	    ("Playlists" . kodi-remote-playlists)
	    ("Keyboard" . kodi-remote-keyboard))))
    (setq tabulated-list-entries
	  (mapcar
	   (lambda (item)
	     (let* ((title (car item))
		    (id (cl-position item menu-entries)))
	       (list `id
		     (vector
		      `(,title
			action sbit-action-start-modes
			args ,(cdr item)
			id ,id)))))
	   menu-entries)))
  (tabulated-list-init-header)
  (tabulated-list-print))

;;;###autoload
(defun kodi-remote-playlist-draw (&optional _arg _noconfirm)
  "Draw the current playlist.
Optional argument _ARG revert excepts this param.
Optional argument _NOCONFIRM revert excepts this param."
  (interactive)
  (kodi-remote-playlist-get)
  (let* ((items (cdr (assoc 'items kodi-properties))))
    (setq tabulated-list-entries
	  (mapcar
	   (lambda (item)
	     (let* ((id (cl-position item items))
		    (title
		     (or ;;(cdr (assoc 'title item))
		      (string-remove-suffix
		       ".pls"
		       (spiderbit-get-name item))
		      "None")))
	       (list `,id
		     (vector
		      `(,title
			action sbit-action-playlist
			id ,id)))))
	   items)))
  ;; (print tabulated-list-entries)
  (tabulated-list-init-header)
  (tabulated-list-print))

(defvar kodi-remote-playlist-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "k") 'kodi-remote-keyboard)
    ;; (define-key map (kbd "n") 'kodi-remote-playlist-next)
    (define-key map (kbd "d") 'kodi-remote-playlist-remove)
    (define-key map (kbd "a") 'kodi-remote-playlist-add-url)
    (define-key map (kbd "p") 'kodi-remote-playlist-play)
    (define-key map (kbd "c") 'kodi-remote-playlist-clear)
    (define-key map (kbd "s") 'kodi-remote-playlist-save)
    map)
  "Keymap for `kodi-remote-playlist-mode'.")

(defvar kodi-remote-playlists-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "k") 'kodi-remote-keyboard)
    (define-key map (kbd "d") 'kodi-remote-playlists-remove)
    (define-key map (kbd "r") 'kodi-remote-playlists-rename)
    map)
  "Keymap for `kodi-remote-playlists-mode'.")

(defvar kodi-remote-series-episodes-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "f") 'kodi-remote-toggle-extended-info)
    (define-key map (kbd "k") 'kodi-remote-keyboard)
    (define-key map (kbd "l") 'kodi-remote-toggle-visibility)
    (define-key map (kbd "d") 'kodi-remote-delete)
    (define-key map (kbd "a") 'kodi-remote-playlist-add-item)
    (define-key map (kbd "x") 'kodi-remote-play-continious)
    map)
  "Keymap for `kodi-remote-playlist-mode'.")

(defvar kodi-remote-series-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "f") 'kodi-remote-toggle-extended-info)
    (define-key map (kbd "k") 'kodi-remote-keyboard)
    (define-key map (kbd "g") 'kodi-remote-draw-shows)
    (define-key map (kbd "c") 'kodi-remote-series-clean)
    (define-key map (kbd "s") 'kodi-remote-series-scan)
    (define-key map (kbd "l") 'kodi-remote-toggle-visibility)
    map)
  "Keymap for `kodi-remote-series-mode'.")

(defvar kodi-remote-music-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "k") 'kodi-remote-keyboard)
    (define-key map (kbd "g") 'kodi-remote-draw-music)
    (define-key map (kbd "a") 'kodi-remote-playlist-add-item)
    (define-key map (kbd "L") 'kodi-remote-toggle-visibility)
    (define-key map (kbd "b") 'kodi-remote-filter-band)
    (define-key map (kbd "x") 'kodi-remote-play-continious)
    map)
  "Keymap for `kodi-remote-music-mode'.")

(defvar kodi-remote-movies-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "k") 'kodi-remote-keyboard)
    (define-key map (kbd "l") 'kodi-remote-toggle-visibility)
    (define-key map (kbd "f") 'kodi-remote-toggle-extended-info)
    ;; (define-key map (kbd "d") 'kodi-remote-delete)
    ;; (define-key map (kbd "a") 'kodi-remote-playlist-add-episode)
    map)
  "Keymap for `kodi-remote-movies-mode'.")

(define-derived-mode kodi-remote-series-mode tabulated-list-mode "kodi-remote-series"
  "Major Mode for kodi series.
Key bindings:
\\{kodi-remote-series-mode-map}"
  ;; (transmission-tabulated-list-format)
  ;; (setq kodi-refresh-function #'kodi-remote-draw-shows)
  ;; (setq kodi-refresh-function nil)
  (setq-local revert-buffer-function #'kodi-remote-draw-shows)
  ;; (add-hook 'post-command-hook #'transmission-timer-check nil t)
  ;; (add-hook 'before-revert-hook #'transmission-tabulated-list-format nil t)
  )

(define-derived-mode kodi-remote-series-episodes-mode tabulated-list-mode "kodi-remote-series-episodes"
  "Major Mode for kodi series.
Key bindings:
\\{kodi-remote-series-episodes-mode-map}"
  (setq-local revert-buffer-function #'kodi-remote-draw-episodes))

;; (define-derived-mode kodi-remote-songs-mode tabulated-list-mode "kodi-remote-songs"
;;   "Major Mode for kodi songs.
;; Key bindings:
;; \\{kodi-remote-songs-mode-map}"
;;   (setq-local revert-buffer-function #'kodi-remote-draw-songs))

(define-derived-mode kodi-remote-music-mode tabulated-list-mode "kodi-remote-music"
  "Major Mode for kodi music.
Key bindings:
\\{kodi-remote-music-mode-map}"
  (setq-local revert-buffer-function #'kodi-remote-draw-music))

(define-derived-mode kodi-remote-mode tabulated-list-mode "kodi-remote"
  "Major Mode for kodi remote.
Key bindings:
\\{kodi-remote-mode-map}"
  (setq tabulated-list-format
        `[("Choices" 30 t)])
  (setq-local revert-buffer-function #'kodi-remote-draw-main))

(define-derived-mode kodi-remote-playlist-mode tabulated-list-mode "kodi-remote-playlist"
  "Major Mode for kodi playlists.
Key bindings:
\\{kodi-remote-playlist-mode-map}"
  (setq tabulated-list-format
        `[("Entry" 30 t)])
  (setq-local revert-buffer-function #'kodi-remote-playlist-draw))

(define-derived-mode kodi-remote-playlists-mode tabulated-list-mode "kodi-remote-playlists"
  "Major Mode for kodi playlists.
Key bindings:
\\{kodi-remote-playlists-mode-map}"
  (setq-local revert-buffer-function #'kodi-remote-playlists-draw))

;;;###autoload
(defun kodi-remote-series-episodes ()
  "Open a `kodi-remote-series-episodes-mode' buffer."
  (interactive)
  (kodi-remote-context #'kodi-remote-series-episodes-mode))

;; ;;;###autoload
;; (defun kodi-remote-songs ()
;;   "Open a `kodi-remote-songs-mode' buffer."
;;   (interactive)
;;   (kodi-remote-context #'kodi-remote-songs-mode))

;;;###autoload
(defun kodi-remote-series ()
  "Open a `kodi-remote-series-mode' buffer."
  (interactive)
  (kodi-remote-context #'kodi-remote-series-mode))

;;;###autoload
(defun kodi-remote-music ()
  "Open a `kodi-remote-music-mode' buffer."
  (interactive)
  (setq kodi-selected-artist nil)
  (kodi-remote-context #'kodi-remote-music-mode))

;;;###autoload
(defun kodi-remote ()
  "Open a `kodi-remote-mode' buffer."
  (interactive)
  (kodi-remote-context #'kodi-remote-mode))

;;;###autoload
(defun kodi-remote-playlist ()
  "Open a `kodi-remote-playlist-mode' buffer."
  (interactive)
  (kodi-remote-context #'kodi-remote-playlist-mode))

(defun kodi-remote-context (mode)
  "Switch to a context buffer of major mode MODE."
  (cl-assert (string-suffix-p "-mode" (symbol-name mode)))
  (let (;; (id (or transmission-torrent-id
        ;;         (cdr (assq 'id (tabulated-list-get-id)))))
        (name (format "*%s*" (string-remove-suffix
			      "-mode" (symbol-name mode)))))
    (if nil (user-error "No media selected")
      (let ((buffer (or (get-buffer name)
                        (generate-new-buffer name))))
        (with-current-buffer buffer
          (unless (derived-mode-p mode)
	    (funcall mode))
	  (if t ;; (and old-id (eq old-id id))
	      (revert-buffer)
	    ;; (setq transmission-torrent-id id)
	    (kodi-remote-draw)
	    ;; (goto-char (point-min))
	    ))
        (pop-to-buffer-same-window buffer)))))

(defun spiderbit-get-movie-id (movie)
  "Return the id of a MOVIE."
  (cdr (assoc 'movieid movie)))

(define-derived-mode kodi-remote-movies-mode tabulated-list-mode "kodi-remote-movies"
  "Major Mode for kodi movies.
Key bindings:
\\{kodi-remote-movies-mode-map}"
  (setq-local revert-buffer-function #'kodi-remote-draw-movies))

;;;###autoload
(defun kodi-remote-movies ()
  "Open a `kodi-remote-movies-mode' buffer."
  (interactive)
  (kodi-remote-context #'kodi-remote-movies-mode))


(defun kodi-files-do (action)
  "Apply ACTION to files in `kodi-media-mode' buffers."
  ;; (cl-assert (memq action kodi-file-symbols))
  (let* ((prop 'tabulated-list-id)
         (region (use-region-p))
         (beg (and region (region-beginning)))
         (end (and region (region-end)))
         (indices
          (if (null region)
	      (list (tabulated-list-get-id))
	    (kodi-text-property-all beg end prop))))
    (if (and indices)
	(if (equal :delete action)
	    (kodi-remote-delete-multiple indices))
      (user-error "No entries selected or at point"))))

(defun kodi-remote-delete ()
  "Deletes entry(s) at point or in region."
  (interactive)
  (kodi-files-do :delete))

(defun kodi-text-property-all (beg end prop)
  "Return a list of non-nil values between BEG and END of a text property PROP.
If none are found, return nil."
  (let (res pos)
    (save-excursion
      (goto-char beg)
      (while (> end (point))
        (push (get-text-property (point) prop) res)
        (setq pos (text-property-not-all (point) end prop (car-safe res)))
        (goto-char (or pos end))))
    (nreverse (delq nil res))))

;;;###autoload
(defun kodi-remote-playlists ()
  "Open a `kodi-remote-playlists-mode' buffer."
  (interactive)
  (kodi-remote-context #'kodi-remote-playlists-mode))



(provide 'kodi-remote)
;;; kodi-remote.el ends here

;; (easy-menu-define kodi-remote-mode-menu kodi-remote-mode-map
;;   "Menu used in `kodi-remote-mode' buffers."
;;   '("Kodi"
;;     ["Series" kodi-remote-series]
;;     ["Add Media" kodi-remote-add
;;      :help "Add Media to the playlist"]
;;     "--"
;;     ;; ["View Series" kodi-remote-series]
;;     ;; ["View playlist" kodi-remote-playlist]
;;     ;; ["View Movies" kodi-remote-movies]
;;     ;; ["View Music" kodi-remote-music]
;;     "--"
;;     ["Refresh" revert-buffer]
;;     ;; ["Quit" kodi-quit]
;;     ))
