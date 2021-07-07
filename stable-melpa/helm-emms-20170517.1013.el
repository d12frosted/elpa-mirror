;;; helm-emms.el --- Emms for Helm. -*- lexical-binding: t -*-

;; Copyright (C) 2012 ~ 2014 Thierry Volpiatto <thierry.volpiatto@gmail.com>

;; Version: 1.3
;; Package-Version: 20170517.1013
;; Package-Commit: d7da090af0f63b92c5d735197992c732adbeef3d
;; Package-Requires: ((helm "1.5") (emms "0.0") (cl-lib "0.5") (emacs "24.1"))

;; X-URL: https://github.com/emacs-helm/helm-emms

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

;;; Code:

(require 'cl-lib)
(require 'helm)
(require 'emms)

(declare-function emms-streams "ext:emms-streams")
(declare-function emms-stream-init "ext:emms-streams")
(declare-function emms-stream-delete-bookmark "ext:emms-streams")
(declare-function emms-stream-add-bookmark "ext:emms-streams" (name url fd type))
(declare-function emms-stream-save-bookmarks-file "ext:emms-streams")
(declare-function emms-stream-quit "ext:emms-streams")
(declare-function emms-playlist-tracks-in-region "ext:emms" (beg end))
(declare-function emms-playlist-first "ext:emms")
(declare-function emms-playlist-mode-play-smart "ext:emms-playlist-mode")
(declare-function emms-playlist-new "ext:emms" (&optional name))
(declare-function emms-player-simple-regexp "ext:emms-player-simple" (&rest extensions))
(declare-function emms-browser-make-cover "ext:emms-browser")
(declare-function emms-playlist-current-clear "ext:emms")
(declare-function emms-play-directory "ext:emms-source-file")
(declare-function emms-play-file "ext:emms-source-file")
(declare-function emms-add-playlist-file "ext:emms-source-playlist")
(declare-function emms-add-directory "ext:emms-source-file")
(defvar emms-player-playing-p)
(defvar emms-browser-default-covers)
(defvar emms-source-file-default-directory)
(defvar emms-track-description-function)
(defvar emms-cache-db)
(defvar emms-playlist-buffer)
(defvar emms-stream-list)


(defgroup helm-emms nil
  "Predefined configurations for `helm.el'."
  :group 'helm)

(defface helm-emms-playlist
    '((t (:foreground "Springgreen4" :underline t)))
  "Face used for tracks in current emms playlist."
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

(defcustom helm-emms-music-extensions '("mp3" "ogg" "flac" "wav")
  "Music files default extensions used by helm to find your music."
  :group 'helm-emms
  :type '(repeat string))

(defun helm-emms-stream-edit-bookmark (elm)
  "Change the information of current emms-stream bookmark from helm."
  (let* ((cur-buf helm-current-buffer)
         (bookmark (assoc elm emms-stream-list))
         (name     (read-from-minibuffer "Description: "
                                         (nth 0 bookmark)))
         (url      (read-from-minibuffer "URL: "
                                         (nth 1 bookmark)))
         (fd       (read-from-minibuffer "Feed Descriptor: "
                                         (int-to-string (nth 2 bookmark))))
         (type     (read-from-minibuffer "Type (url, streamlist, or lastfm): "
                                         (format "%s" (car (last bookmark))))))
    (save-window-excursion
      (emms-streams)
      (when (re-search-forward (concat "^" name) nil t)
        (forward-line 0)
        (emms-stream-delete-bookmark)
        (emms-stream-add-bookmark name url (string-to-number fd) type)
        (emms-stream-save-bookmarks-file)
        (emms-stream-quit)
        (switch-to-buffer cur-buf)))))

(defun helm-emms-stream-delete-bookmark (_candidate)
  "Delete emms-streams bookmarks from helm."
  (let* ((cands   (helm-marked-candidates))
         (bmks    (cl-loop for bm in cands collect
                        (car (assoc bm emms-stream-list))))
         (bmk-reg (mapconcat 'regexp-quote bmks "\\|^")))
    (when (y-or-n-p (format "Really delete radios\n -%s: ? "
                            (mapconcat 'identity bmks "\n -")))
      (save-window-excursion
        (emms-streams)
        (goto-char (point-min))
        (cl-loop while (re-search-forward bmk-reg nil t)
              do (progn (forward-line 0)
                        (emms-stream-delete-bookmark))
              finally do (progn
                           (emms-stream-save-bookmarks-file)
                           (emms-stream-quit)))))))

(defvar helm-source-emms-streams
  (helm-build-sync-source "Emms Streams"
    :init (lambda ()
            (require 'emms-streams)
            (emms-stream-init))
    :candidates (lambda ()
                  (mapcar 'car emms-stream-list))
    :action '(("Play" . (lambda (elm)
                          (let* ((stream (assoc elm emms-stream-list))
                                 (fn (intern (concat "emms-play-" (symbol-name (car (last stream))))))
                                 (url (cl-second stream)))
                            (funcall fn url))))
              ("Delete" . helm-emms-stream-delete-bookmark)
              ("Edit" . helm-emms-stream-edit-bookmark))
    :filtered-candidate-transformer 'helm-adaptive-sort))

;; Don't forget to set `emms-source-file-default-directory'
(defvar helm-emms--dired-cache nil)
(defvar helm-emms--directories-added-to-playlist nil)
(defvar helm-source-emms-dired
  (helm-build-sync-source "Music Directory"
    :init (lambda ()
            (setq helm-emms--dired-cache
                  (helm-walk-directory
                   emms-source-file-default-directory
                   :directories 'only
                   :path 'full))
            (add-hook 'emms-playlist-cleared-hook
                      'helm-emms--clear-playlist-directories))
    :candidates 'helm-emms--dired-cache
    :persistent-action 'helm-emms-dired-persistent-action
    :persistent-help "Play or add directory to playlist (C-u clear playlist)"
    :action
    '(("Play Directory" . (lambda (directory)
                            (emms-play-directory directory)
                            (push directory helm-emms--directories-added-to-playlist)))
      ("Add directory to playlist (C-u clear playlist)"
       . helm-emms-add-directory-to-playlist)
      ("Open dired in file's directory" . (lambda (directory)
                                            (helm-open-dired directory))))
    :candidate-transformer 'helm-emms-dired-transformer
    :filtered-candidate-transformer 'helm-adaptive-sort))

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
    (dolist (f files) (emms-add-playlist-file f))
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

(defun helm-emms-dired-transformer (candidates)
  (cl-loop with files
           for d in candidates
           for cover = (pcase (expand-file-name "cover_small.jpg" d)
                         ((and c (pred file-exists-p)) c)
                         (_ (car emms-browser-default-covers)))
           for inplaylist = (member d helm-emms--directories-added-to-playlist)
           for bn = (helm-basename d)
           when (setq files (helm-emms-directory-files d)) collect
           (if cover
               (cons (propertize
                      (concat (emms-browser-make-cover cover)
                              (if inplaylist
                                  (propertize bn 'face 'helm-emms-playlist)
                                bn))
                      'help-echo (mapconcat 'identity files "\n"))
                     d)
             d)))

(defvar helm-emms-current-playlist nil)

(defun helm-emms-files-modifier (candidates _source)
  (cl-loop for i in candidates
           for playing = (assoc-default 'info-title
                          (emms-playlist-current-selected-track))
           if (member (cdr i) helm-emms-current-playlist)
           collect (cons (pcase (car i)
                           ((and str (guard (and playing
                                                 (string-match-p playing str))))
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
    :persistent-help "Play file or add it to playlist"
    :action '(("Play file" . emms-play-file)
              ("Add to Playlist and play (C-u clear current)"
               . (lambda (_candidate)
                   (helm-emms-add-files-to-playlist
                    (helm-marked-candidates)))))))

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
                (emms-add-playlist-file candidate)))))
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

;;; helm-emms ends here

;;; helm-emms.el ends here
