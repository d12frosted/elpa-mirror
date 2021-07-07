;;; helm-emms.el --- Emms for Helm. -*- lexical-binding: t -*-

;; Copyright (C) 2012 ~ 2014 Thierry Volpiatto <thierry.volpiatto@gmail.com>

;; Author: Thierry Volpiatto <thierry.volpiatto@gmail.com>
;; Version: 1.3
;; Package-Version: 20201205.1635
;; Package-Commit: 43d387504a292b36e4e4246abdc9090c1717a561
;; Package-Requires: ((helm "1.5") (emms "6.0") (cl-lib "0.5") (emacs "24.1"))
;; Keywords: multimedia, emms
;; URL: https://github.com/emacs-helm/helm-emms

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

;; This package provides a basic helm interface to emms, the Emacs Multimedia
;; System.  This interface is accessible via the interactive `helm-emms' command
;; and provides direct access to music directories, individual music files, and
;; EMMS streams.  See the `helm-emms' customization group for available
;; customizations, or simply call `helm-emms' to get started.

;;; Code:

(require 'cl-lib)
(require 'helm)
(require 'helm-adaptive)
(require 'emms)

(declare-function emms-play-url "ext:emms-streams")
(declare-function emms-playlist-tracks-in-region "ext:emms" (beg end))
(declare-function emms-playlist-first "ext:emms")
(declare-function emms-playlist-mode-play-smart "ext:emms-playlist-mode")
(declare-function emms-playlist-new "ext:emms" (&optional name))
(declare-function emms-player-simple-regexp "ext:emms-player-simple" (&rest extensions))
(declare-function emms-browser-make-cover "ext:emms-browser")
(declare-function emms-browser-get-cover-from-path "ext:emms-browser")
(declare-function emms-playlist-current-clear "ext:emms")
(declare-function emms-play-directory "ext:emms-source-file")
(declare-function emms-play-file "ext:emms-source-file")
(declare-function emms-add-directory "ext:emms-source-file")
(declare-function emms-add-file "ext:emms-source-file")
(declare-function emms-source-playlist-parse-native "ext:emms-source-playlist")
(defvar emms-player-playing-p)
(defvar emms-browser-default-covers)
(defvar emms-source-file-default-directory)
(defvar emms-track-description-function)
(defvar emms-cache-db)
(defvar emms-playlist-buffer)
(defvar emms-streams-file)
(defvar emms-streams-built-in-list)


(defgroup helm-emms nil
  "Predefined configurations for `helm.el'."
  :group 'helm)

(defface helm-emms-playlist
    '((t (:foreground "Springgreen4" :underline t)))
  "Face used for tracks and directories in current emms playlist."
  :group 'helm-emms)

(defcustom helm-emms-use-track-description-function nil
  "If non-nil, use `emms-track-description-function'.
If you have defined a custom function for track descriptions, you
may want to use it in helm-emms as well."
  :group 'helm-emms
  :type 'boolean)

(defcustom helm-emms-default-sources '(helm-source-emms-dired
                                       helm-source-emms-files
                                       helm-source-emms-streams)
  "The default source for `helm-emms'."
  :group 'helm-emms
  :type 'boolean)

(defcustom helm-emms-music-extensions '("mp3" "ogg" "flac" "wav" "wma")
  "Music files default extensions used by helm to find your music."
  :group 'helm-emms
  :type '(repeat string))

(defcustom helm-emms-directory-files-recursive-fn 'helm-emms-walk-directory
  "The function used to initially parse the user music directory.
It takes one argument DIR. The default function
`helm-emms-walk-directory' use lisp to recursively find all directories
which may be slow on large music directories."
  :group 'helm-emms
  :type '(choice (function :tag "Native" helm-emms-walk-directory)
                 (function :tag "System \"find\" (faster)" helm-emms-walk-directory-with-find)) )

(defcustom helm-emms-find-program "find"
  "The \"find\" program.
This is notably used by `helm-emms-walk-directory-with-find'."
  :group 'helm-emms
  :type 'string)

(defcustom helm-emms-dired-directories (list emms-source-file-default-directory)
  "Directories scanned by `helm-source-emms-dired'."
  :group 'helm-emms
  :type '(repeat string))

(defcustom helm-emms-streams-list nil
  "List of streams for emms streams.
When nil use `emms-streams-built-in-list' entries as default."
  :type '(alist :key-type string :value-type string)
  :group 'helm-emms)

(defun helm-emms--read-streams-from-streams-file ()
  "Read streams from `emms-streams-file' as track list.
Return nil if `emms-streams-file' is nil or not a readable file."
  ;; `emms-streams-file' is a native EMMS playlist of streams, read it as it is.
  (when (and emms-streams-file
             (file-readable-p emms-streams-file))
    (car (read-from-string (with-temp-buffer
                             (insert-file-contents emms-streams-file)
                             (buffer-substring (point-min) (point-max)))))))

(defun helm-emms-stream-setup-default-alist ()
  "Setup default value of `helm-emms-streams-list'.
Source `emms-streams-file' if non-nil to retrieve default
entries, or use `emms-streams-built-in-list'."
  (cl-loop for elm in (or (helm-emms--read-streams-from-streams-file)
                          emms-streams-built-in-list)
           for assoc = (assoc-default 'metadata elm)
           collect (cons (car assoc) (cadr assoc))))

(defvar helm-source-emms-streams
  (helm-build-sync-source "Emms Streams"
    :init (lambda ()
            (require 'emms-streams)
            (unless helm-emms-streams-list
              (setq helm-emms-streams-list
                    (helm-emms-stream-setup-default-alist))))
    :candidates (lambda () helm-emms-streams-list)
    :action '(("Play" . emms-play-url)
              ("Add new stream (C-u play)" . helm-emms-add-new-stream)
              ("Delete stream(s)" . helm-emms-delete-stream))
    :filtered-candidate-transformer 'helm-adaptive-sort
    :group 'helm-emms))

(defun helm-emms-add-new-stream (_candidate)
  "Action to add a new stream to `helm-emms-streams-list'."
  (let ((count 0)
        (prefarg (or helm-current-prefix-arg
                     current-prefix-arg)))
    (cl-labels ((record
                 ()
                 (let ((name (read-string "Stream name: "))
                       (url  (read-string "Stream url: ")))
                   (customize-save-variable 'helm-emms-streams-list
                                            (append (list (cons name url))
                                                    helm-emms-streams-list))
                   (cl-incf count)
                   (when (y-or-n-p "Add a new stream? ")
                     (record))
                   (when prefarg
                     (emms-play-url url)))))
      (record))
    (message "%s new stream(s) added" count)))

(defun helm-emms-delete-stream (_candidate)
  "Delete marked streams."
  (cl-loop for url in (helm-marked-candidates)
           do (customize-save-variable 'helm-emms-streams-list
                    (delete (rassoc url helm-emms-streams-list)
                            helm-emms-streams-list))))

;; Don't forget to set `helm-emms-dired-directories'.
(defvar helm-emms--dired-cache nil)
(defvar helm-emms--directories-added-to-playlist nil)
(defvar helm-source-emms-dired
  (helm-build-sync-source "Music Directories"
    :init (lambda ()
            (cl-assert helm-emms-dired-directories nil
                       "Incorrect EMMS setup please setup `helm-emms-dired-directories' variable")
            ;; User may have a symlinked directory to an external
            ;; drive or whatever (Issue #11).
            (setq helm-emms--dired-cache
                  (cl-loop for dir in (mapcar #'file-truename helm-emms-dired-directories)
                           when (file-exists-p dir)
                           append (funcall helm-emms-directory-files-recursive-fn dir)))
            (add-hook 'emms-playlist-cleared-hook
                      'helm-emms--clear-playlist-directories))
    :candidates 'helm-emms--dired-cache
    :persistent-action 'helm-emms-dired-persistent-action
    :persistent-help "Play or add directory to playlist (C-u clear playlist)"
    :action
    '(("Play Directories"
       . (lambda (directory)
           (emms-stop)
           (emms-playlist-current-clear)
           (cl-loop with mkds = (helm-marked-candidates)
                    with current-prefix-arg = nil
                    with helm-current-prefix-arg = nil
                    for dir in mkds
                    do (helm-emms-add-directory-to-playlist dir))))
      ("Add directories to playlist (C-u clear playlist)"
       . (lambda (directory)
           (let ((mkds (helm-marked-candidates)))
             (cl-loop for dir in mkds
                      do (helm-emms-add-directory-to-playlist dir))))) 
      ("Open dired in file's directory" . (lambda (directory)
                                            (helm-open-dired directory))))
    :filtered-candidate-transformer '(helm-emms-dired-transformer helm-adaptive-sort)
    :group 'helm-emms))

(defun helm-emms-walk-directory (dir)
  "The default function to recursively find directories in music directory."
  (helm-walk-directory dir :directories 'only :path 'full))

(defun helm-emms-walk-directory-with-find (dir)
  "Like `helm-emms-walk-directory' but uses the \"find\" external command.
The path to the command is set in `helm-emms-find-program'.

Warning: This won't work with directories containing a line break."
  (process-lines helm-emms-find-program dir "-mindepth" "1" "-type" "d"))

(defun helm-emms--clear-playlist-directories ()
  (setq helm-emms--directories-added-to-playlist nil))

(defun helm-emms-dired-persistent-action (directory)
  "Play or add DIRECTORY files to emms playlist.

If emms is playing add all files of DIRECTORY to playlist,
otherwise play directory."
  (if emms-player-playing-p
      (progn (emms-add-directory directory)
             (message "All files from `%s' added to playlist"
                      (helm-basename directory)))
    (emms-play-directory directory))
  (push directory helm-emms--directories-added-to-playlist)
  (helm-force-update))

(defun helm-emms-add-directory-to-playlist (directory)
  "Add all files in DIRECTORY to emms playlist."
  (let ((files (helm-emms-directory-files directory t)))
    (helm-emms-add-files-to-playlist files)
    (push directory helm-emms--directories-added-to-playlist)))

(defun helm-emms-add-files-to-playlist (files)
  "Add FILES list to playlist.

If a prefix arg is provided clear previous playlist."
  (with-current-emms-playlist
    (when (or helm-current-prefix-arg current-prefix-arg)
      (emms-stop)
      (emms-playlist-current-clear))
    (dolist (f files) (emms-add-file f))
    (unless emms-player-playing-p
      (helm-emms-play-current-playlist))))

(defun helm-emms-directory-files (directory &optional full nosort)
  "List files in DIRECTORY retaining only music files.

Returns nil when no music files are found."
  (directory-files
   directory full
   (format ".*%s" (apply #'emms-player-simple-regexp
                         helm-emms-music-extensions))
   nosort))

(defun helm-emms-dired-transformer (candidates _source)
  (cl-loop with files
           for d in candidates
           for cover = (pcase (emms-browser-get-cover-from-path d 'small)
                         ((and c (guard (and c (file-exists-p c)))) c)
                         (_ (car emms-browser-default-covers)))
           for inplaylist = (member d helm-emms--directories-added-to-playlist)
           for bn = (helm-basename d)
           when (setq files (helm-emms-directory-files d)) collect
           (cons (let* ((cover-image (and cover (emms-browser-make-cover cover)))
                        (title (if cover bn d))
                        (title-with-face (if inplaylist
                                             (propertize title 'face 'helm-emms-playlist)
                                           title)))
                   (propertize (concat cover-image title-with-face)
                               'help-echo (mapconcat 'identity files "\n")))
                 d)))

(defvar helm-emms-current-playlist nil)

(defun helm-emms-files-modifier (candidates _source)
  (cl-loop for i in candidates
           for curtrack = (emms-playlist-current-selected-track)
           for playing = (or (and helm-emms-use-track-description-function
                                  (funcall emms-track-description-function curtrack))
                             (assoc-default 'info-title curtrack))
           if (member (cdr i) helm-emms-current-playlist)
           collect (cons (pcase (car i)
                           ((and str
                                 (guard (and playing
                                             (string-match-p
                                              (concat (regexp-quote playing) "\\'") str))))
                            (propertize str 'face 'emms-browser-track-face))
                           (str (propertize str 'face 'helm-emms-playlist)))
                         (cdr i))
           into currents
           else collect i into others
           finally return (append
                           (cl-loop for i in helm-emms-current-playlist
                                    when (rassoc i currents)
                                    collect it)
                           others)))

(defun helm-emms-play-current-playlist ()
  "Play current playlist."
  (emms-playlist-first)
  (emms-playlist-mode-play-smart))

(defun helm-emms-set-current-playlist ()
  (when (or (not emms-playlist-buffer)
            (not (buffer-live-p emms-playlist-buffer)))
    (setq emms-playlist-buffer (emms-playlist-new)))
  (setq helm-emms-current-playlist
        (with-current-buffer emms-playlist-buffer
          (save-excursion
            (goto-char (point-min))
            (cl-loop for i in (reverse (emms-playlist-tracks-in-region
                                        (point-min) (point-max)))
                     when (assoc-default 'name i)
                     collect it)))))

(defvar helm-source-emms-files
  (helm-build-sync-source "Emms files"
    :init 'helm-emms-set-current-playlist
    :candidates (lambda ()
                  (cl-loop for v being the hash-values in emms-cache-db
                           for name      = (assoc-default 'name v)
                           for artist    = (or (assoc-default 'info-artist v) "unknown")
                           for genre     = (or (assoc-default 'info-genre v) "unknown")
                           for tracknum  = (or (assoc-default 'info-tracknumber v) "unknown")
                           for song      = (or (assoc-default 'info-title v) "unknown")
                           for info      = (if helm-emms-use-track-description-function
                                               (funcall emms-track-description-function v)
                                             (concat artist " - " genre " - " tracknum ": " song))
                           unless (string-match "^\\(http\\|mms\\):" name)
                           collect (cons info name)))
    :filtered-candidate-transformer 'helm-emms-files-modifier
    :candidate-number-limit 9999
    :persistent-action #'helm-emms-files-persistent-action
    :persistent-help "Play file(s) or add to playlist"
    :action '(("Play file(s)"
               . (lambda (_candidate)
                   (emms-play-file (car (helm-marked-candidates)))
                   (helm-emms-add-files-to-playlist
                    (cdr (helm-marked-candidates)))))
              ("Add to playlist (C-u clear current and play)"
               . (lambda (_candidate)
                   (helm-emms-add-files-to-playlist
                    (helm-marked-candidates))))
              ("Delete tracks from playlist"
               . helm-emms-delete-tracks))
    :group 'helm-emms))

(defun helm-emms-goto-track (candidate)
  (let ((track (emms-track 'file (expand-file-name candidate))))
    (with-current-buffer emms-playlist-buffer
      (goto-char (point-min))
      (when (re-search-forward
             (format "%s"
                     (regexp-quote
                      (helm-basename (assoc-default 'name track) t)))
             nil t)
        (forward-line 0)))))

(defun helm-emms-delete-tracks (_candidate)
  (with-current-buffer emms-playlist-buffer
    (let ((inhibit-read-only t))
      (cl-loop for track in (helm-marked-candidates)
               do
               (when (helm-emms-goto-track track)
                 (emms-playlist-simple-delete-track)))
      (helm-emms-delete-blank-lines))))

(defun helm-emms-delete-blank-lines ()
  (save-excursion
    (goto-char (point-min))
    (while (and (re-search-forward "^$" nil t) (not (eobp)))
      (delete-blank-lines))))

(defun helm-emms-files-persistent-action (candidate)
  (let ((recenter t))
    (if (or emms-player-playing-p
            (not (helm-emms-playlist-empty-p)))
        (with-current-emms-playlist
          (let (track)
            (save-excursion
              (goto-char (point-min))
              (while (and (not (string=
                                candidate
                                (setq track
                                      (assoc-default
                                       'name (emms-playlist-track-at
                                              (point))))))
                          (not (eobp)))
                (forward-line 1))
              (if (string= candidate track)
                  (progn
                    (setq recenter (with-helm-window
                                     (count-lines (window-start) (point))))
                    (emms-playlist-select (point))
                    (when emms-player-playing-p
                      (emms-stop))
                    (emms-start))
                (emms-add-file candidate)))))
      (emms-play-file candidate))
    (helm-force-update nil recenter)))

(defun helm-emms-playlist-empty-p ()
  (with-current-emms-playlist
    (null (emms-playlist-track-at (point)))))

;;;###autoload
(defun helm-emms ()
  "Preconfigured `helm' for emms sources."
  (interactive)
  (helm :sources helm-emms-default-sources
        :buffer "*Helm Emms*"))


(provide 'helm-emms)

;; Local Variables:
;; byte-compile-warnings: (not cl-functions obsolete)
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; helm-emms.el ends here
