;;; magit-filenotify.el --- Refresh status buffer when git tree changes -*- lexical-binding: t -*-

;; Copyright (C) 2013-2015 Rüdiger Sonderfeld

;; Author: Rüdiger Sonderfeld <ruediger@c-plusplus.de>
;; Created: 17 Jul 2013
;; Keywords: tools
;; Package-Version: 20151116.2340
;; Package-Commit: c0865b3c41af20b6cd89de23d3b0beb54c8401a4
;; Package-Requires: ((magit "1.3.0") (emacs "24.4"))

;; This file is NOT part of GNU Emacs.

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

;; This module comes with a minor mode `magit-filenotify' which tracks
;; changes in the source tree using `file-notify' and refreshes the magit
;; status buffer.  Emacs 24.4 with `file-notify-support' is required for
;; it to work.

;; Also see https://github.com/magit/magit-filenotify for more information.

;;; Code:

(require 'magit)
(require 'cl-lib)
(require 'filenotify)

(defgroup magit-filenotify nil
  "Refresh status buffer if source tree changes"
  :prefix "magit-filenotify"
  :group 'magit-extensions)

(defcustom magit-filenotify-ignored '("\\`\\.#" "\\`flycheck_")
  "A list of regexp for filenames that will be ignored by the callback."
  :group 'magit-filenotify
  :type '(repeat regexp))

(defun magit-filenotify--directories ()
  "List all directories containing files watched by git."
  (cons
   default-directory
   (cl-remove-duplicates
    (cl-loop for file in (magit-git-lines "ls-files")
             for dir = (file-name-directory (magit-decode-git-path file))
             when dir
             collect (expand-file-name dir))
    :test #'string=)))

;; Use #'equal as test because watch-descriptors aren't always integers.  With
;; inotify, descriptors can be lists like (17).  This is properly documented in
;; (info "(elisp)File Notifications") which states "It [the descriptor] should
;; be used for comparison by `equal' only".
(defvar magit-filenotify-data (make-hash-table :test #'equal)
  "A hash table to map watch-descriptors to a list (DIRECTORY STATUS-BUFFER).")

(defvar magit-filenotify--idle-timer nil
  "Timer which will refresh buffers when Emacs becomes idle.")

(defcustom magit-filenotify-idle-delay 1.57
  "Number of seconds to wait before refreshing out-of-date buffers."
  :group 'magit-filenotify
  :type 'number)

(defcustom magit-filenotify-instant-refresh-time 1.73
  "Minimum number of seconds for an instant refresh.
When an file-notify event occurs for some repository and the
previous event is more distant than this value, the corresponding
magit status buffer will be refreshed immediately instead of
delaying the refresh according to `magit-filenotify-idle-delay'.

Note that setting this option to a too low value will cause very
frequent refreshes which might seem to make Emacs hang in case
frequent changes occur to files, e.g., during the compilation of
a large project."
  :group 'magit-filenotify
  :type 'number)

(defvar magit-filenotify--buffers nil
  "List of magit status buffers to be refreshed.
Those will be refreshed after `magit-filenotify-idle-delay' seconds.")

(defun magit-filenotify--refresh-buffer (buffer)
  "Refresh the given magit status BUFFER."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      ;; `magit-refresh' runs the functions in `magit-pre-refresh-hook' which
      ;; contains `magit-maybe-save-repository-buffers'.  This function
      ;; queries the user to save repository buffers.  That's nice for
      ;; interactive use but it's bad here because when you edit, save, and
      ;; start editing again, you'll get that query after
      ;; `magit-filenotify-idle-delay'.
      ;;
      ;; Workaround Emacs bug#21311.  As the bug states, this is actually not
      ;; an Emacs bug but a bug in Magit.  All hooks should be declared using
      ;; `defvar' nowadays.  This has been fixed already in Magit (see
      ;; https://github.com/magit/magit/issues/2198) but let's keep that here
      ;; for compatibility with older Magit versions.
      (defvar magit-pre-refresh-hook)
      (let ((magit-pre-refresh-hook nil))
        (magit-refresh))))
  (setq magit-filenotify--buffers (delq buffer magit-filenotify--buffers)))

(defun magit-filenotify--refresh-all ()
  "Refresh all magit status buffers in `magit-filenotify--buffers'.
Those are all status buffers for which file change notifications
have been received since the last refresh."
  (mapc #'magit-filenotify--refresh-buffer magit-filenotify--buffers))

(defun magit-filenotify--register-buffer (buffer)
  "Register BUFFER as being out-of-date.
BUFFER is some magit status buffer where some file-notify change
event has been received for some of the repository's
directories.

All out-of-date magit status buffers are collected in
`magit-filenotify--buffers' and will be refreshed automatically
when Emacs has been idle for `magit-filenotify-idle-delay'
seconds."
  (cl-pushnew buffer magit-filenotify--buffers)
  (if magit-filenotify--idle-timer
      (progn
        (cancel-timer magit-filenotify--idle-timer)
        (timer-activate-when-idle magit-filenotify--idle-timer t))
    (setq magit-filenotify--idle-timer
          (run-with-idle-timer magit-filenotify-idle-delay
                               nil #'magit-filenotify--refresh-all))))

(defvar magit-filenotify--last-event-times (make-hash-table)
  "A hash-table from status buffers to the last event for the buffers.")

(defun magit-filenotify--rm-watch (desc)
  "Remove the directory watch DESC."
  ;; At least when using inotify as `file-notify--library' there will be an
  ;; error when calling `file-notify-rm-watch' on a descriptor of a directory
  ;; which has been deleted (as per git rm -rf some/dir/).
  ;;
  ;; Actually, it would be even better to handle deletions and creations of
  ;; directories directly in `magit-filenotify--callback', i.e., if a watched
  ;; dir is deleted, remove its entry (and all subdir entries) from
  ;; `magit-filenotify-data'.  If some new directory is created as a
  ;; subdirectory of a watched directory, start watching it.  However, one
  ;; problem is that renamings can be either reported as one `renamed' events
  ;; or a sequence of `created' and `deleted' events in any order depending on
  ;; `file-notify--library' (and maybe also `system-type').
  (condition-case var
      (file-notify-rm-watch desc)
    (file-notify-error (message "File notify error: %S" (cdr var)))))

(defun magit-filenotify--callback (ev)
  "Handle file-notify callbacks.
Argument EV contains the watch data."
  (unless
      (let ((file (nth 2 ev)) res)
        (dolist (rx magit-filenotify-ignored res)
          (when (string-match rx (file-name-nondirectory file))
            (setq res t))))
    (let* ((wd (car ev))
           (data (gethash wd magit-filenotify-data))
           (buffer (cadr data))
           (now (current-time)))
      (if (buffer-live-p buffer)
          (let ((last-event-time (gethash buffer magit-filenotify--last-event-times)))
            (puthash buffer now magit-filenotify--last-event-times)
            (if (and last-event-time
                     (> (time-to-seconds (time-subtract now last-event-time))
                        magit-filenotify-instant-refresh-time))
                ;; Fast path: The last event concerning this status buffer is
                ;; quite some time back in the past, so refresh immediately.
                ;; This should basically catch all cases where a user manually
                ;; modifies a file, e.g. by saving a buffer.
                (magit-filenotify--refresh-buffer buffer)
              ;; Delayed path: We're receiving bursts of events which probably
              ;; means that some kind of compilation is ongoing.  So defer the
              ;; refreshes into the future in order not to lock up emacs.
              (magit-filenotify--register-buffer buffer)))
        (magit-filenotify--rm-watch wd)
        (remhash wd magit-filenotify-data)
        (remhash buffer magit-filenotify--last-event-times)))))

(defun magit-filenotify-start ()
  "Start watching for changes to the source tree using filenotify.
This can only be called from a magit status buffer."
  (unless (derived-mode-p 'magit-status-mode)
    (error "Only works in magit status buffer"))
  (dolist (dir (magit-filenotify--directories))
    (when (file-exists-p dir)
      (puthash (file-notify-add-watch dir
                                      '(change attribute-change)
                                      #'magit-filenotify--callback)
               (list dir (current-buffer))
               magit-filenotify-data))))

(defun magit-filenotify-stop ()
  "Stop watching for changes to the source tree using filenotify.
This can only be called from a magit status buffer."
  (unless (derived-mode-p 'magit-status-mode)
    (error "Only works in magit status buffer"))
  (maphash
   (lambda (k v)
     (when (or (equal (cadr v) (current-buffer)) ; or use buffer?
               ;; Also remove watches for source trees where the magit status
               ;; buffer has been killed.
               (not (buffer-live-p (cadr v))))
       (magit-filenotify--rm-watch k)
       (remhash k magit-filenotify-data)
       (remhash (cadr v) magit-filenotify--last-event-times)))
   magit-filenotify-data))

(defun magit-filenotify-watching-p ()
  "Return non-nil if current source tree is watched."
  (unless (derived-mode-p 'magit-status-mode)
    (error "Only works in magit status buffer"))
  (let (ret)
    (maphash (lambda (_k v)
               (when (and (not ret)
                          (equal (cadr v) (current-buffer)))
                 (setq ret t)))
             magit-filenotify-data)
    ret))

(defcustom magit-filenotify-lighter " MagitFilenotify"
  "String to display in mode line when `magit-filenotify-mode' is active."
  :group 'magit-filenotify
  :type 'string)

;;;###autoload
(define-minor-mode magit-filenotify-mode
  "Refresh status buffer if source tree changes."
  :lighter magit-filenotify-lighter
  :group 'magit-filenotify
  (if magit-filenotify-mode
      (progn
        (magit-filenotify-start)
        (add-hook 'kill-buffer-hook #'magit-filenotify-stop nil t))
    (magit-filenotify-stop)))

(defun magit-filenotify-stop-all ()
  "Stop watching for changes in all git trees."
  (interactive)
  (maphash
   (lambda (k _v) (magit-filenotify--rm-watch k))
   magit-filenotify-data)
  (clrhash magit-filenotify-data))

;;; Loading
(easy-menu-add-item magit-mode-menu nil
                    ["Auto Refresh" magit-filenotify-mode
                     :style toggle
                     :visible (derived-mode-p 'magit-status-mode)
                     :selected (magit-filenotify-watching-p)
                     :help "Refresh magit status buffer when source tree updates"]
                    "Refresh")

(custom-add-option 'magit-status-mode-hook #'magit-filenotify-mode)

(defun magit-filenotify-unload-function ()
  "Cleanup when module is unloaded."
  (magit-filenotify-stop-all)
  (easy-menu-remove-item magit-mode-menu nil "Auto Refresh"))

(provide 'magit-filenotify)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; magit-filenotify.el ends here
