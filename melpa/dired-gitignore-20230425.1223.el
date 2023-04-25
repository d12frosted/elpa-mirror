;;; dired-gitignore.el --- A minor mode to hide gitignored files in a dired buffer -*- lexical-binding: t; -*-

;; Copyright (C) 2021 - 2023 Johannes Mueller

;; Author: Johannes Mueller <github@johannes-mueller.org>
;; URL: https://github.com/johannes-mueller/dired-gitignore.el
;; Package-Version: 20230425.1223
;; Package-Commit: 9e7678533b132f73057f2cb3839a9f00aff97ac3
;; Version: 0.1.0
;; Keywords: dired, convenience, git
;; Package-Requires: ((emacs "27.1"))

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation version 3. <https://www.gnu.org/licenses/>

;; This package is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; This package provides a minor mode which hides files and directories,
;; ignored by git due to an entry in the project's `.gitignore'.

;; When the minor mode is active, the ignored items are hidden.  When it is
;; deactivated, they are shown again.  The recommended use case is to bind the
;; command to toggle the minor mode `(dired-gitignore-mode)' to some
;; convenient key.

;; In order to hide ignored files by default hook it into `dired-mode-hook'
;;
;; (add-hook 'dired-mode-hook 'dired-gitignore-mode)

;; It needs the executables for `git' and `ls' in the `PATH' and a standard UNIX shell
;; behind the `shell-file-name' variable.  The fish shell <3.4.0 does not work.

;;; Code:

(require 'dired)

;;;###autoload
(define-minor-mode dired-gitignore-mode
  "Toggle `dired-gitignore-mode'."
  :init-value nil
  :lighter " !g"
  :group 'dired
  (if dired-gitignore-mode
      (add-hook 'dired-after-readin-hook #'dired-gitignore--hide)
    (remove-hook 'dired-after-readin-hook #'dired-gitignore--hide))
  (revert-buffer))


(defun dired-gitignore--hide ()
  "Determine the lines to be hidden and hide them."
  (save-excursion
    (goto-char (point-min))
    (let ((marked-files (dired-get-marked-files)))
      (dired-gitignore--remove-all-marks)
      (dolist (file (dired-gitignore--files-to-be-ignored))
        (setq marked-files (delete (dired-gitignore--mark-file file) marked-files)))
      (dired-do-kill-lines nil "")
      (dired-gitignore--restore-marks marked-files))))


(defun dired-gitignore--remove-all-marks ()
  "Remove all marks and return the marks removed."
  (save-excursion
    (let ((inhibit-read-only t))
      (goto-char (point-min))
      (while (re-search-forward dired-re-mark nil t)
        (subst-char-in-region (1- (point)) (point) (preceding-char) ?\s)))))


(defun dired-gitignore--files-to-be-ignored ()
  "Determine and return a list of files to be ignored."
  (split-string (shell-command-to-string "git check-ignore $(ls -A1)")))


(defun dired-gitignore--mark-file (file)
  "Mark the file FILE in the Dired buffer."
  (let ((absolute-file (concat (expand-file-name default-directory) file)))
    (when (file-exists-p absolute-file)
      (dired-goto-file absolute-file)
      (dired-mark 1)
      absolute-file)))


(defun dired-gitignore--restore-marks (marked-files)
  "Restore the marks of MARKED-FILES."
  (dolist (file marked-files)
        (dired-goto-file file)
        (dired-mark 1)))


(provide 'dired-gitignore)
;;; dired-gitignore.el ends here
