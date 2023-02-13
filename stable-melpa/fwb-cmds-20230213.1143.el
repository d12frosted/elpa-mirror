;;; fwb-cmds.el --- misc frame, window and buffer commands  -*- lexical-binding:t -*-

;; Copyright (C) 2008-2023 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/fwb-cmds
;; Keywords: convenience
;; Package-Version: 20230213.1143
;; Package-Commit: 1b375c6890de61eaccc97c92f2b46de6f9205417

;; Package-Requires: ((emacs "25.1") (compat "29.1.3.4"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Commands defined here operate on frames, windows and buffers and
;; make it easier and faster to access certain functionality that
;; is already available using the builtin commands.

;;; Code:

(require 'cl-lib)
(require 'compat)
(require 'find-func)

;;;###autoload
(defun fwb-delete-window (&optional window)
  "Remove WINDOW from the display.  Default is `selected-window'.
If WINDOW is the only one in its frame, then `delete-frame' too."
  (interactive)
  (save-current-buffer
    (when window
      (select-window window))
    (if (one-window-p t)
        (delete-frame)
      (delete-window (selected-window)))))

(defun fwb--delete-window-or-frame (fn &optional window)
  "If WINDOW is the only one in its frame, then `delete-frame' too.
This is an around advice for `delete-window'."
  (interactive)
  (save-current-buffer
    (when window
      (select-window window))
    (if (one-window-p t)
        (delete-frame)
      (funcall fn (selected-window)))))

;;;###autoload
(defun fwb-kill-this-buffer-and-its-window ()
  "Kill the current buffer and delete its window.
When called in the minibuffer, get out of the minibuffer
using `abort-recursive-edit'."
  (interactive)
  (if (menu-bar-non-minibuffer-window-p)
      (let ((buffer (current-buffer)))
        (fwb-delete-window (selected-window))
        (kill-buffer buffer))
    (abort-recursive-edit)))

;;;###autoload
(defun fwb-kill-other-buffers-and-their-window ()
  "Kill non-current buffers in the selected frame and delete their window.
Only buffers are considered that have a window in the current frame."
  (interactive)
  (dolist (window (window-list nil :exclude-minibuffer))
    (unless (equal window (selected-window))
      (kill-buffer (window-buffer window))
      (with-no-warnings
        (delete-window window)))))

;;;###autoload
(defun fwb-replace-current-window-with-frame ()
  "Delete window but show buffer in a newly created frame."
  (interactive)
  (let ((window (selected-window)))
    (switch-to-buffer-other-frame (current-buffer))
    (with-no-warnings
      (delete-window window))))

;;;###autoload
(defun fwb-replace-some-window-with-frame ()
  "Delete some window but show buffer in a newly created frame.
Replace the first window that never displayed another buffer than
the one it is currently displaying.  If all windows displayed
another buffer before, then replace the selected window."
  (interactive)
  (if-let ((window (cl-find-if-not #'window-prev-buffers (window-list))))
      (with-selected-window window
        (fwb-replace-current-window-with-frame))
    (fwb-replace-current-window-with-frame)))

;;;###autoload
(defun fwb-switch-to-current-buffer-other-frame ()
  "Create new frame with the current buffer."
  (interactive)
  (switch-to-buffer-other-frame (current-buffer)))

;;;###autoload
(defun fwb-toggle-window-split ()
  "Toggle between vertical and horizontal split."
  ;; Source: https://www.emacswiki.org/emacs/ToggleWindowSplit.
  ;; Author: Jeff Dwork
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
             (next-win-buffer (window-buffer (next-window)))
             (this-win-edges (window-edges (selected-window)))
             (next-win-edges (window-edges (next-window)))
             (this-win-2nd (not (and (<= (car this-win-edges)
                                         (car next-win-edges))
                                     (<= (cadr this-win-edges)
                                         (cadr next-win-edges)))))
             (splitter
              (if (= (car this-win-edges)
                     (car (window-edges (next-window))))
                  #'split-window-horizontally
                #'split-window-vertically)))
        (delete-other-windows)
        (let ((first-win (selected-window)))
          (funcall splitter)
          (if this-win-2nd (other-window 1))
          (set-window-buffer (selected-window) this-win-buffer)
          (set-window-buffer (next-window) next-win-buffer)
          (select-window first-win)
          (if this-win-2nd (other-window 1))))))

;;;###autoload
(defun fwb-sudo-find-file (&optional arg)
  "Edit the visited file as \"root\".
If the current buffer does not visit a file, the visited file is
writable or with a prefix argument, then read a file to visit."
  (interactive "P")
  (require 'tramp)
  (if (or arg
          (not buffer-file-name)
          (file-writable-p buffer-file-name))
      (let ((default-directory
             (concat "/sudo:root@localhost:" default-directory)))
        (apply #'find-file
               (find-file-read-args
                "Find file: "
                (confirm-nonexistent-file-or-buffer))))
    (find-alternate-file (concat "/sudo:root@localhost:" buffer-file-name))))

;;; _
(provide 'fwb-cmds)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; fwb-cmds.el ends here
