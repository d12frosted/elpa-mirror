;;; focus-autosave-mode.el --- Automatically save files in focus-out-hook.  -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Wojciech Siewierski

;; Author: Wojciech Siewierski <wojciech.siewierski@onet.pl>
;; Keywords: convenience, files, frames, mouse
;; Package-Version: 20160519.2116
;; Package-Commit: e89ed22aa4dfc76e1b844b202aedd468ad58814a
;; Package-Requires: ((emacs "24.4"))

;; This file is not part of GNU Emacs.

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

;; `focus-autosave-mode' is a global minor mode saving every modified
;; file when the Emacs frame loses its focus.

;; `focus-autosave-local-mode' is a buffer-local version of this mode.

;; Currently there is no way to exclude some buffers from the global version.

;;; Code:

(require 'cl-lib)

(defvar focus-autosave-buffer-list nil
  "A list of buffers to be saved on focus-out.")

(defcustom focus-autosave-local-action nil
  "A shell command or Elisp function to run after saving the
buffer. Do nothing if `nil'"
  :risky t)
(make-local-variable 'focus-autosave-local-action)

;;;###autoload
(define-minor-mode focus-autosave-mode
  "Automatically save all the modified files when the frame loses its focus."
  :lighter " focus-save"
  :global t
  (let ((hook 'focus-out-hook)
        (hook-function #'focus-autosave-save-all))
    (if focus-autosave-mode
        (add-hook hook hook-function)
      (remove-hook hook hook-function))))

;;;###autoload
(define-minor-mode focus-autosave-local-mode
  "Automatically save this buffer when the frame loses its focus."
  :lighter " local-focus-save"
  :global nil
  (if focus-autosave-local-mode
      (progn
        (add-to-list 'focus-autosave-buffer-list (current-buffer))
        (add-hook 'focus-out-hook #'focus-autosave-save-marked))
    (progn
      (setq focus-autosave-buffer-list
            (delete (current-buffer)
                    focus-autosave-buffer-list))
      (focus-autosave-cleanup-hook))))

(defun focus-autosave-cleanup-hook ()
  "Remove the `focus-out-hook' if the autosaved buffer list is empty."
  (unless focus-autosave-buffer-list
    (remove-hook 'focus-out-hook #'focus-autosave-save-marked)))

(defun focus-autosave-save-all ()
  "Save all buffers."
  (mapc #'focus-autosave-buffer
        (buffer-list)))

(defun focus-autosave-should-save-p (buffer)
  (and (buffer-live-p buffer)
       (buffer-modified-p buffer)
       (buffer-file-name buffer)))

(defun focus-autosave-buffer (buffer)
  "Save a buffer and run its autosave command if present."
  (when (focus-autosave-should-save-p buffer)
    (with-current-buffer buffer
      (save-buffer)
      (cond
       ((functionp focus-autosave-local-action)
        (funcall focus-autosave-local-action))
       ((stringp focus-autosave-local-action)
        (async-shell-command focus-autosave-local-action))))))

(defun focus-autosave-save-marked ()
  "Save the marked buffers and remove the killed ones from the list."
  (setq focus-autosave-buffer-list
        (cl-delete-if-not #'buffer-live-p
                          focus-autosave-buffer-list))
  (mapc #'focus-autosave-buffer
        focus-autosave-buffer-list)
  (focus-autosave-cleanup-hook))

(provide 'focus-autosave-mode)
;;; focus-autosave-mode.el ends here
