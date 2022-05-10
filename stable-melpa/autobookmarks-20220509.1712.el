;;; autobookmarks.el --- Save recently visited files and buffers

;; Copyright (C) 2015 Matúš Goljer <matus.goljer@gmail.com>

;; Author: Matúš Goljer <matus.goljer@gmail.com>
;; Maintainer: Matúš Goljer <matus.goljer@gmail.com>
;; Version: 0.0.1
;; Package-Version: 20220509.1712
;; Package-Commit: 8acd6f182181e23257e01c1b5cf90b872507a74d
;; Created: 28th February 2015
;; Package-requires: ((dash "2.10.0") (cl-lib "0.5"))
;; Keywords: files

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'dash)
(require 'cl-lib)
(require 'bookmark)

(defgroup autobookmarks ()
  "Save recently visited files and buffers."
  :group 'files
  :prefix "abm-")

(defcustom abm-file (locate-user-emacs-file "autobookmarks")
  "File where the bookmark data is persisted."
  :type 'file
  :group 'autobookmarks)

(defcustom abm-old-bookmark-threshold 90
  "Number of days since last visit after which the bookmark is erased."
  :type 'integer
  :group 'autobookmarks)

(defvar abm-visited-buffers nil
  "List of visited buffers.

A buffer is added to this list as soon as it is visited.

In case the session crashes, it is used to recover the recent
buffer list.")

(defun abm-visited-buffers () abm-visited-buffers)

(defvar abm-recent-buffers nil
  "List of recent buffers.

A buffer is added to this list as soon as it is closed.")

(defun abm-recent-buffers () abm-recent-buffers)

(defcustom abm-visited-buffer-hooks '((find-file-hook . abm-handle-visited-buffer)
                                      (write-file-functions . abm-handle-visited-buffer)
                                      (dired-mode-hook . abm-handle-visited-buffer))
  "Hooks used to detect visited buffers."
  :type '(repeat
          (cons
           (symbol :tag "Hook")
           (function :tag "Function")))
  :group 'autobookmarks)

(defcustom abm-ignore-buffers '(
                                "\\.ido\\.last"
                                "\\.git"
                                "\\.svn"
                                "log\\'"
                                "cache"
                                "#\\'"
                                )
  "List of regular expressions to ignore buffers.

If filename matches the expression it is ignored."
  :type '(repeat regexp)
  :group 'autobookmarks)

(defcustom abm-killed-buffer-functions '(
                                         abm-handle-killed-file
                                         abm-handle-killed-dired
                                         abm-handle-killed-info
                                         )
  "Functions used to handle killed buffers.

Function should return non-nil if it handled the buffer."
  :type 'hook
  :group 'autobookmarks)

(defun abm--make-record ()
  "Call `bookmark-make-record' and change some values to more meaningful defaults."
  (let* ((record (--remove (memq (car it) '(
                                            front-context-string
                                            rear-context-string
                                            front-context-region-string
                                            rear-context-region-string
                                            ))
                           (cdr (bookmark-make-record))))
         (record (-concat record (list (cons 'time (current-time))
                                       (cons 'visits 0)))))
    (cons (or (cdr (assoc 'filename record))
              (cdr (assoc 'buffer-name record)))
          record)))

(defun abm--remove-bookmark (bookmark list)
  "Remove BOOKMARK from bookmark list LIST."
  (--remove (equal (car bookmark) (car it)) list))

(defun abm--process-bookmark-p (bookmark)
  "Test if we should process this BOOKMARK.

List of ignored buffers is customizable via `abm-ignore-buffers'."
  (let ((filename (cdr (assoc 'filename bookmark))))
    (and filename (--none? (string-match-p it filename) abm-ignore-buffers))))

(defun abm--add-bookmark-to-visited (bookmark)
  (when (abm--process-bookmark-p bookmark)
    (let ((bookmark (or (--first (equal (car bookmark) (car it)) abm-recent-buffers) bookmark)))
      (unless (assoc (car bookmark) abm-visited-buffers)
        (push bookmark abm-visited-buffers))
      (setq abm-recent-buffers (abm--remove-bookmark bookmark abm-recent-buffers)))))

(defun abm--add-bookmark-to-recent (bookmark)
  (when (abm--process-bookmark-p bookmark)
    (let ((bookmark (or (--first (equal (car bookmark) (car it)) abm-visited-buffers) bookmark)))
      (unless (assoc (car bookmark) abm-recent-buffers)
        ;; remove all bookmarks which point to a parent of new bookmark
        (setq abm-recent-buffers
              (--remove (string-prefix-p (car it) (car bookmark)) abm-recent-buffers))
        (push bookmark abm-recent-buffers))
      (setq abm-visited-buffers (abm--remove-bookmark bookmark abm-visited-buffers)))))

(defun abm-remove-recent (regexp)
  "Remove matching bookmarks from `abm-recent-buffers'."
  (interactive "sRegexp to match and remove: ")
  (when (equal regexp "")
    (user-error "The regexp to match against is empty"))
  (setq abm-recent-buffers (--remove (string-match-p regexp (car it)) abm-recent-buffers)))

(defun abm-remove-nonexistant (check-remote-files-p)
  "Remove all bookmarks which point to non-existing files.

This *will* also check remote files accessed with TRAMP unless
invoked with prefix argument \\[universal-argument]."
  (interactive "P")
  (setq abm-recent-buffers
        (--filter (let ((file (cdr (assoc 'filename (cdr it)))))
                    (if check-remote-files-p
                        (file-exists-p file)
                      (or (file-remote-p file)
                          (file-exists-p file))))
                  abm-recent-buffers)))

(defun abm-save-to-file ()
  "Save visited and recent buffers to file.

Additionally, before saving the data, it filters the
`abm-recent-buffers' list and removes bookmarks older than
`abm-old-bookmark-threshold'."
  (interactive)
  ;; in case this is called before init finished we might overwrite
  ;; the saved data, so load that first
  (unless abm-recent-buffers
    (abm-load-from-file))
  ;; remove too old bookmarks
  (setq abm-recent-buffers (--remove
                            (time-less-p
                             ;; old threshold in days
                             (days-to-time abm-old-bookmark-threshold)
                             ;; minus "current - bookmark last used timestamp" (= number of days since last use)
                             (time-subtract (current-time) (or (cdr (assoc 'time it)) (current-time))))
                            abm-recent-buffers))
  (let ((print-level nil)
        (print-length nil))
    (make-directory (file-name-directory abm-file) t)
    (with-temp-file abm-file
      (insert ";; This file is created automatically by autobookmarks.el\n\n")
      (insert (format "(setq abm-visited-buffers '%S)\n" abm-visited-buffers))
      (insert (format "(setq abm-recent-buffers '%S)" abm-recent-buffers)))))

(defun abm-load-from-file ()
  "Load saved bookmarks."
  (interactive)
  (when (file-exists-p abm-file)
    (load-file abm-file)
    (setq abm-recent-buffers (-concat abm-visited-buffers abm-recent-buffers))
    (setq abm-visited-buffers nil)))

(if after-init-time
    (abm-load-from-file)
  (add-hook 'after-init-hook 'abm-load-from-file))

;; handlers

(defun abm-handle-visited-buffer ()
  "Handle opened buffer."
  (let ((record (abm--make-record)))
    (abm--add-bookmark-to-visited record))
  (abm-save-to-file))

;; TODO: take care of the repetition here?  Will we ever do something
;; else than make record and push it?
(defun abm-handle-killed-file ()
  "Handle killed file buffer."
  (when (buffer-file-name)
    (let ((record (abm--make-record)))
      (abm--add-bookmark-to-recent record))))

(defun abm-handle-killed-dired ()
  "Handle killed dired buffer."
  (when (eq major-mode 'dired-mode)
    (let ((record (abm--make-record)))
      (abm--add-bookmark-to-recent record))))

(defun abm-handle-killed-info ()
  "Handle killed info buffer."
  (when (eq major-mode 'Info-mode)
    (let ((record (abm--make-record)))
      (abm--add-bookmark-to-recent record))))

(defun abm-handle-killed-buffer ()
  "Run \"killed-buffer\" handlers.

The list is customizable via `abm-killed-buffer-functions'."
  (unless (equal " " (substring (buffer-name) 0 1))
    (run-hook-with-args-until-success 'abm-killed-buffer-functions)
    (abm-save-to-file)))

;; visit the stored bookmark
(defun abm-restore-killed-buffer (bookmark)
  "Restore killed buffer BOOKMARK."
  (-when-let (visits (assq 'visits (cdr bookmark)))
    (cl-incf (cdr visits)))
  (-when-let (time (assq 'time (cdr bookmark)))
    (setf (cdr time) (current-time)))
  (bookmark-jump bookmark))

;; minor mode

;;;###autoload
(define-minor-mode autobookmarks-mode
  "Autobookmarks."
  :group 'autobookmarks
  :global t
  (if autobookmarks-mode
      (progn
        (add-hook 'kill-emacs-hook 'abm-save-to-file)
        (--each abm-visited-buffer-hooks
          (add-hook (car it) (cdr it) :append))
        (add-hook 'kill-buffer-hook 'abm-handle-killed-buffer))
    (remove-hook 'kill-emacs-hook 'abm-save-to-file)
    (--each abm-visited-buffer-hooks
      (remove-hook (car it) (cdr it)))
    (remove-hook 'kill-buffer-hook 'abm-handle-killed-buffer)))

(provide 'autobookmarks)
;;; autobookmarks.el ends here
