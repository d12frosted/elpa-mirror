;;; vlc.el --- VideoLAN VLC Media Player Control     -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Xu Chunyang

;; Author: Xu Chunyang
;; Homepage: https://github.com/xuchunyang/vlc.el
;; Package-Requires: ((emacs "25.1"))
;; Package-Version: 20200328.1143
;; Package-Commit: 07c4a12904f2700fb8420c4e71395fd59a5e6faa
;; Keywords: tools
;; Version: 0

;; This program is free software; you can redistribute it and/or modify
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

;; This package let you control VLC through VLC HTTP interface

;;; Code:

(require 'auth-source)
(require 'cl-lib)
(require 'dom)
(require 'json)
(require 'subr-x)
(require 'seq)                          ; `seq-find'

(defvar url-http-end-of-headers)
(defvar url-http-response-status)
(defvar url-request-extra-headers)
(defvar url-show-status)

(defgroup vlc nil
  "VideoLAN VLC Media Player Control."
  :group 'applications)

(defcustom vlc-host "127.0.0.1"
  "Host where the HTTP web interface is running."
  :type 'string)

(defcustom vlc-port 8080
  "Port where the HTTP web interface is running.
8080 is the default port unless you launch VLC with command line
option --http-port=PORT."
  :type 'integer)

(defcustom vlc-executable (or (seq-find
                               #'executable-find
                               '("/usr/local/bin/vlc"
                                 "/Applications/VLC.app/Contents/MacOS/VLC"
                                 "\\Program Files\\VideoLAN\\VLC\\vlc.exe"
                                 "C:\\Program Files\\VideoLAN\\VLC\\vlc.exe"))
                              "vlc")
  "The VLC executable used by `vlc-start'."
  :type 'string)

(define-error 'vlc-error "VLC Error" 'error)

;; https://wiki.videolan.org/Documentation:Modules/http_intf/#Access_control
(defvar vlc--password nil
  "Password of the HTTP web interface.")

(defun vlc--password ()
  "Return the HTTP web interface password."
  (unless vlc--password
    (let* ((plist (car (auth-source-search :host "vlc" :user "" :create t :max 1)))
           (save (plist-get plist :save-function))
           (pass (plist-get plist :secret)))
      (when (functionp save)
        (funcall save))
      (setq vlc--password (if (functionp pass)
                              (funcall pass)
                            pass))))
  (unless vlc--password
    (user-error "Can't know your VLC password"))
  vlc--password)

(defun vlc--url-encode-params (params)
  "URL encode PARAMS which must be a plist."
  (mapconcat
   (pcase-lambda ((seq key val))
     (cl-assert (keywordp key))
     (concat (url-hexify-string (substring (symbol-name key) 1))
             "="
             (pcase-exhaustive val
               ((pred symbolp) (url-hexify-string (symbol-name val)))
               ((pred numberp) (number-to-string val))
               ((pred stringp) (url-hexify-string val)))))
   (seq-filter #'cadr (seq-partition params 2))
   "&"))

(defun vlc--json-read ()
  "Wrapper of `json-read' to prevent user modifications."
  (let ((json-object-type 'alist)
        (json-key-type 'symbol)
        (json-array-type 'list)
        (json-false nil)
        (json-null nil))
    (json-read)))

(defun vlc--get (resource &rest params)
  "Make a `GET' request for RESOURCE and return response as JSON.
PARAMS is a plist."
  (unless (string-prefix-p "/" resource)
    (setq resource (concat "/" resource)))
  (let ((url (format "http://%s:%s%s" vlc-host vlc-port resource)))
    (when params
      (setq url (concat url "?" (vlc--url-encode-params params))))
    (with-current-buffer
        (let ((url-request-extra-headers
               `(("Pragma" . "no-cache")
                 ("Authorization" .
                  ,(concat "Basic "
                           (base64-encode-string (concat ":" (vlc--password)))))))
              (url-show-status nil))
          (url-retrieve-synchronously url))
      (pcase url-http-response-status
        (200)
        (code (signal 'vlc-error (list "Wrong HTTP status code" code))))
      (goto-char (1+ url-http-end-of-headers))
      (when (eq (following-char) ?<)    ; HTML
        (signal 'vlc-error
                (let* ((dom (libxml-parse-html-region (point) (point-max)))
                       (body (dom-child-by-tag dom 'body))
                       ;; Error loading /requests/status.json
                       (err (dom-text (dom-child-by-tag body 'h1)))
                       ;; bad argument #1 to &#39;make_uri&#39; (string expected, got nil)
                       (detail (dom-text (dom-child-by-tag body 'pre))))
                  (list err detail (current-buffer)))))
      (set-buffer-multibyte t)
      (prog1 (vlc--json-read)
        (kill-buffer)))))

(defun vlc--uniquify (name existing-names)
  "Uniquify NAME against EXISTING-NAMES.
That is, if NAME is in EXISTING-NAMES, return NAME<2>,
if NAME<2> is also in EXISTING-NAMES, return NAME<3>,
and so on."
  (cond
   ((not (member name existing-names))
    name)
   ((string-match (rx bos (group (1+ nonl)) "<" (group (1+ num)) ">" eos) name)
    (let ((name (match-string 1 name))
          (id (string-to-number (match-string 2 name))))
      (vlc--uniquify (format "%s<%d>" name (1+ id)) existing-names)))
   (t
    (vlc--uniquify (format "%s<%d>" name 2) existing-names))))

(defun vlc--playlist-completing-read (prompt)
  "Pick one item from playlist and return its ID.
PROMPT is a string to prompt with; normally it ends in a colon and a space."
  (let (names names-ids)
    (dolist (x (vlc-playlist))
      (let-alist x
        (let ((name (vlc--uniquify .name names))
              (id (string-to-number .id)))
          (push name names)
          (push (cons
                 ;; Mark the current playing item
                 ;;
                 ;; XXX This might break uniqueness
                 (if .current (concat name "* ") name)
                 id)
                names-ids))))
    (unless names-ids
      (user-error "You playlist is empty, can't pick one from it"))
    (setq names-ids (nreverse names-ids))
    (assoc-default
     (completing-read prompt (mapcar #'car names-ids) nil t)
     names-ids)))

;;; Play, Pause, and Stop

;;;###autoload
(defun vlc-stop ()
  "Stop playing the current stream, if playing or paused."
  (interactive)
  (vlc--get "/requests/status.json" :command 'pl_stop))

;;;###autoload
(defun vlc-play (id)
  "Play playlist item ID.  If ID is omitted, play last active item:."
  (interactive (list (unless current-prefix-arg
                       (vlc--playlist-completing-read "Play: "))))
  (vlc--get "/requests/status.json" :command 'pl_play :id id))

;;;###autoload
(defun vlc-pause ()
  "Toggle the playing pause state."
  (interactive)
  (vlc--get "/requests/status.json" :command 'pl_pause))

(defun vlc-playing-p ()
  "Non-nil if a stream is playing."
  (let-alist (vlc--get "/requests/status.json")
    (equal .state "playing")))

;;; Playlist

(defun vlc-playlist ()
  "Return the playlist."
  (cl-loop for child in (alist-get 'children (vlc--get "/requests/playlist.json"))
           when (equal (alist-get 'name child) "Playlist")
           return (alist-get 'children child)))

;;;###autoload
(defun vlc-empty ()
  "Clear all items from the playlist."
  (interactive)
  (vlc--get "/requests/status.json" :command 'pl_empty))

;;;###autoload
(defun vlc-add (uri &optional noaudio novideo)
  "Add URI to playlist and start playback.
NOAUDIO and NOVIDEO are optional options.
If NOAUDIO is non-nil, disable audio.
If NOVIDEO is non-nil, disable video.
When called interactively, with prefix arg, you can pick one."
  (interactive (cons (concat "file://" (expand-file-name (read-file-name "Add file: ")))
                     (pcase current-prefix-arg
                       ('nil (list nil nil))
                       (_ (pcase (completing-read "Option: " '("noaudio" "novideo") nil t)
                            ("noaudio" (list t nil))
                            ("novideo" (list nil t)))))))
  (vlc--get "/requests/status.json" :command 'in_play
            :input uri
            :option (cond (noaudio "noaudio")
                          (novideo "novideo"))))

;;;###autoload
(defun vlc-enqueue (uri)
  "Add URI to playlist."
  (interactive (list (concat "file://" (expand-file-name (read-file-name "Add file: ")))))
  (vlc--get "/requests/status.json" :command 'in_enqueue :input uri))

;;;###autoload
(defun vlc-next ()
  "Start playing the next item in the playlist."
  (interactive)
  (vlc--get "/requests/status.json" :command 'pl_next))

;;;###autoload
(defun vlc-prev ()
  "Start playing the previous item in the playlist."
  (interactive)
  (vlc--get "/requests/status.json" :command 'pl_previous))

;;;###autoload
(defun vlc-delete (id)
  "Delete an item from playlist by its ID."
  (interactive (list (vlc--playlist-completing-read "Delete: ")))
  (cl-assert id)
  (vlc--get "/requests/status.json" :command 'pl_delete :id id))

;; https://github.com/videolan/vlc/blob/fad0d14618f7be34b04347e517644764d43d8dad/share/lua/README.txt#L358
;;
;; playlist.sort( key ): sort the playlist according to the key.
;;   Key must be one of the followings values: 'id', 'title', 'title nodes first',
;;                                             'artist', 'genre', 'random', 'duration',
;;                                             'title numeric' or 'album'.
(defconst vlc--sort-keys '("id" "title" "title nodes first"
                           "artist" "genre" "random" "duration"
                           "title numeric" "album")
  "All possible sort keys.")

;;;###autoload
(defun vlc-sort (mode &optional reverse)
  "Sort by MODE and return the result.
MODE must be one of `vlc--sort-keys'.
If REVERSE is non-nil, reverse the result."
  (interactive (list (completing-read
                      "Sort by: "
                      vlc--sort-keys
                      nil t)
                     current-prefix-arg))
  (cl-assert (member mode vlc--sort-keys))
  (vlc--get "/requests/status.json" :command 'pl_sort :id (if reverse 1 0) :val mode))

;;; Rate

;;;###autoload
(defun vlc-rate (rate)
  "Set playback speed to RATE.
RATE should within [25%, 400%] according to
VLC->Playback->Playback Speed."
  (cl-assert (> rate 0))
  (vlc--get "/requests/status.json" :command 'rate :val rate))

;;; Random / Repeat / Loop

;;;###autoload
(defun vlc-random (&optional on)
  "Set whether VLC should select streams from the playlist randomly.
rather than in order according to ON.
If ON is 'toggle, toggle random.
If ON is nil, switch to in order.
If ON is non-nil, switch to random."
  (interactive (list 'toggle))
  (when (or (eq on 'toggle)
            (not (eq (and on t)
                     (and (alist-get 'random (vlc--get "/requests/status.json")) t))))
    (vlc--get "/requests/status.json" :command 'pl_random)))

;;;###autoload
(defun vlc-repeat (&optional on)
  "Set whether VLC should repeat playing the current stream continuously.
ON must be one of 'toggle, nil and non-nil."
  (interactive (list 'toggle))
  (when (or (eq on 'toggle)
            (not (eq (and on t)
                     (and (alist-get 'repeat (vlc--get "/requests/status.json")) t))))
    (vlc--get "/requests/status.json" :command 'pl_repeat)))

;;;###autoload
(defun vlc-loop (&optional on)
  "Set whether VLC should repeat playing the playlist continuously.
ON must be one of 'toggle, nil and non-nil."
  (interactive (list 'toggle))
  (when (or (eq on 'toggle)
            (not (eq (and on t)
                     (and (alist-get 'loop (vlc--get "/requests/status.json")) t))))
    (vlc--get "/requests/status.json" :command 'pl_loop)))

;;; Absolute Position

;;;###autoload
(defun vlc-seek (pos)
  "Seek to POS.

Allowed values are of the form:
 [+ or -][<int><H or h>:][<int><M or m or '>:][<int><nothing or S or s or \\\">]
 or [+ or -]<int>%
 (value between [ ] are optional, value between < > are mandatory)
examples:
 1000 -> seek to the 1000th second
 +1H:2M -> seek 1 hour and 2 minutes forward
 -10% -> seek 10% back."
  (interactive "sSeek to: ")
  (vlc--get "/requests/status.json" :command 'seek :val pos))

(defun vlc-get-time ()
  "Return the time position of the current stream, in seconds."
  (alist-get 'time (vlc--get "/requests/status.json")))

(defun vlc-get-length ()
  "Get the length of the current stream, in seconds."
  (alist-get 'length (vlc--get "/requests/status.json")))

;;; Video Options

;;;###autoload
(defun vlc-fullscreen (&optional on)
  "Set whether VLC should repeat playing the playlist continuously.
ON must be one of 'toggle, nil and non-nil."
  (interactive (list 'toggle))
  (when (or (eq on 'toggle)
            (not (eq (and on t)
                     (and (alist-get 'fullscreen
                                     (vlc--get "/requests/status.json"))
                          t))))
    (vlc--get "/requests/status.json" :command 'fullscreen)))

;;; Audio Options

;;;###autoload
(defun vlc-volume (&optional val)
  "Set volume to VAL.
VAL can be absolute integer, percent or +/- relative value, must
of the form: +<int>, -<int>, <int> or <int>%."
  (interactive "sSet volume: ")
  (vlc--get "/requests/status.json" :command 'volume :val val))

;;; Snapshot

;;;###autoload
(defun vlc-snapshot ()
  "Write a snapshot still image of the current video display to a file.
See VLC documentation for command line arguments for controlling
where and how these files are written, such as –snapshot-path."
  (interactive)
  (vlc--get "/requests/status.json" :command 'snapshot))

;;; Keys

(defconst vlc--keys '(toggle-fullscreen
                      leave-fullscreen
                      play-pause
                      pause
                      play
                      faster
                      slower
                      rate-normal
                      rate-faster-fine
                      rate-slower-fine
                      next
                      prev
                      stop
                      position
                      jump-extrashort
                      jump+extrashort
                      jump-short
                      jump+short
                      jump-medium
                      jump+medium
                      jump-long
                      jump+long
                      frame-next
                      nav-activate
                      nav-up
                      nav-down
                      nav-left
                      nav-right
                      disc-menu
                      title-prev
                      title-next
                      chapter-prev
                      chapter-next
                      quit
                      vol-up
                      vol-down
                      vol-mute
                      subdelay-up
                      subdelay-down
                      subsync-markaudio
                      subsync-marksub
                      subsync-apply
                      subsync-reset
                      subpos-up
                      subpos-down
                      audiodelay-up
                      audiodelay-down
                      audio-track
                      audiodevice-cycle
                      subtitle-revtrack
                      subtitle-track
                      subtitle-toggle
                      program-sid-next
                      program-sid-prev
                      aspect-ratio
                      crop
                      toggle-autoscale
                      incr-scalefactor
                      decr-scalefactor
                      deinterlace
                      deinterlace-mode
                      intf-show
                      intf-boss
                      intf-popup-menu
                      snapshot
                      record
                      zoom
                      unzoom
                      wallpaper
                      crop-top
                      uncrop-top
                      crop-left
                      uncrop-left
                      crop-bottom
                      uncrop-bottom
                      crop-right
                      uncrop-right
                      random
                      loop
                      viewpoint-fov-in
                      viewpoint-fov-out
                      viewpoint-roll-clock
                      viewpoint-roll-anticlock
                      zoom-quarter
                      zoom-half
                      zoom-original
                      zoom-double
                      set-bookmark1
                      set-bookmark2
                      set-bookmark3
                      set-bookmark4
                      set-bookmark5
                      set-bookmark6
                      set-bookmark7
                      set-bookmark8
                      set-bookmark9
                      set-bookmark10
                      play-bookmark1
                      play-bookmark2
                      play-bookmark3
                      play-bookmark4
                      play-bookmark5
                      play-bookmark6
                      play-bookmark7
                      play-bookmark8
                      play-bookmark9
                      play-bookmark10
                      clear-playlist
                      subtitle-text-scale-normal
                      subtitle-text-scale-up
                      subtitle-text-scale-down)
  "List of VLC keys.
Extract from URL
`https://docs.racket-lang.org/vlc/#%28part._.Keys%29', which is
extracted from URL
`https://wiki.videolan.org/VLC_HowTo/Use_with_lirc/'")

;;;###autoload
(defun vlc-key (key)
  "Send a key command KEY to VLC.
KEY must be on of `vlc--keys'."
  (interactive (list (pcase (completing-read "Send a key to VLC: "
                                             vlc--keys nil t)
                       ("" nil)
                       (s (intern s)))))
  (cl-assert (memq key vlc--keys))
  (vlc--get "/requests/status.json" :command 'key :val key))

;;; Start

(defvar vlc--process nil "The VLC process.")

;;;###autoload
(defun vlc-start ()
  "Start a VLC process."
  (interactive)
  (unless (executable-find vlc-executable)
    (user-error "Can't find VLC executable"))
  (let* ((password "secret")
         (process-buf (generate-new-buffer " *vlc*"))
         (process (make-process
                   :name "vlc"
                   :buffer process-buf
                   :command (list vlc-executable
                                  "--no-color"
                                  "--extraintf" "http"
                                  "--http-password" password)
                   :connection-type 'pipe)))
    ;; XXX Check if the process is started successfully
    (setq vlc--process process)
    (setq vlc--password password)))

(provide 'vlc)
;;; vlc.el ends here
