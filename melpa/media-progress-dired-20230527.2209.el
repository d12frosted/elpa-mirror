;;; media-progress-dired.el --- Display position where media player stopped in dired buffer -*- lexical-binding:t -*-

;; Copyright (C) 2023 Dmitriy Pshonko
;; Copyright (C) 2018-2019  Free Software Foundation, Inc.

;; Author: Dmitriy Pshonko <http://github.com/jumper047>
;; Author: Arthur Miller <arthur.miller@live.com>
;; Author: Clemens Radermacher <clemera@posteo.net>
;; Version: 0.1.0
;; Package-Version: 20230527.2209
;; Package-Commit: 438a37019383eef35e45875b3e4df3fca4eaf39f
;; Keywords: files, convenience
;; Homepage: https://github.com/jumper047/media-progress
;; Package-Requires: ((emacs "28.1") (media-progress "0.1.0"))

;; This file is NOT part of GNU Emacs.

;;; License:

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

;; Minor mode to display viewing progress of the media file in DIRED buffer.
;; Just activate `media-progress-dired-mode' while in DIRED buffer!

;;; Code:

(require 'dired)
(require 'dired-x)
(require 'dired-aux)
(require 'media-progress)

(defgroup media-progress-dired nil
  "Show media progress info in Dired."
  :group 'media-progress
  :prefix "media-progress-dired-")

(defface media-progress-dired-mpv-info-face
  '((t (:inherit font-lock-comment-face)))
  "Face for commit message.")

(defcustom media-progress-dired-auto-hide-details-p t
  "If details should get hidden automatically.

Uses function `dired-hide-details-mode' to hide details when showing mpv
info."
  :type 'boolean)

(defvar-local media-progress-dired--restore-no-details nil
  "If no details view has to be restored.")

(defun media-progress-dired--files ()
  "Return list of file names in Dired buffer."
  (save-excursion
    (let (files)
      (goto-char 1)
      (while (not (eobp))
        (when (dired-file-name-at-point)
          (push (expand-file-name (dired-file-name-at-point)) files))
        (dired-next-line 1))
      (nreverse files))))

(defun media-progress-dired--insert-info ()
  "Insert git log messages into current buffer."
  (let* ((files (media-progress-dired--files))
         (longest (media-progress-dired--longest-line files))
         mpv-info)
    (save-excursion
      (with-silent-modifications
        (dolist (file files)
          (dired-goto-file file)
          (when (dired-file-name-at-point)
            (dired-move-to-end-of-filename t)
            (setq mpv-info (media-progress-info-string file))
            (if mpv-info (insert (make-string (1+ (- longest (length file))) ?\s) mpv-info))))
        (media-progress-dired--fontify-info (point-max))))))


(defun media-progress-dired--longest-line (lines)
  "Find longest line length in a list of LINES."
  (let ((longest 0) length)
    (dolist (l lines)
      (setq length (length l))
      (if (> length longest) (setq longest length)))
    longest))

(defun media-progress-dired--remove-info ()
  "Renove inserted progress messages."
  (save-excursion
    (with-silent-modifications
      (goto-char 1)
      (while (not (eobp))
        (when (dired-file-name-at-point)
          (dired-move-to-end-of-filename)
          (delete-region (point) (line-end-position)))
        (dired-next-line 1)))))

(defun media-progress-dired--after-readin ()
  "Hook called after a Dired buffer is modified."
  (media-progress-dired--insert-info))

(defun media-progress-dired--before-readin ()
  "Hook called before a Dired buffer is modified."
  (when (bound-and-true-p media-progress-dired-mode)
    (media-progress-dired--remove-info)))

(defun media-progress-dired--revert-buffer (&rest _r)
  "Recalculate media progress info after buffer is reverted."
  (when (bound-and-true-p media-progress-dired-mode)
    (media-progress-dired--remove-info)
    (media-progress-dired--insert-info)))

(defun media-progress-dired--fontify-info (limit)
  "Fonitfy inserted media progress info in Dired buffer.

LIMIT as required by font-lock hook."
  (save-excursion
    (goto-char (point-min))
    (while (< (point) limit)
      (when (dired-file-name-at-point)
        (dired-move-to-end-of-filename)
        (when (not (eolp))
          (add-text-properties
           (1+ (point)) (line-end-position)
           (list 'font-lock-fontified t
                 'face 'media-progress-dired-commit-message-face))))
      (dired-next-line 1))))

(defun media-progress-dired--after-mode ()
  "Enable automatic details hiding.
Intended to use in the `after-change-major-mode-hook'"
  (when media-progress-dired-auto-hide-details-p
    (unless (bound-and-true-p dired-hide-details-mode)
      (setq media-progress-dired--restore-no-details t)
      (dired-hide-details-mode))))

(defun media-progress-dired--on-first-change ()
  "Fontify inserted media progress info in whole Dired buffer.
Intended to use in `first-change-hook'"
  (media-progress-dired--fontify-info (point-max)))

(defun media-progress-dired--cleanup ()
  "Remove media progress messages."
  (media-progress-dired--remove-info)
  (when media-progress-dired--restore-no-details
    (setq media-progress-dired--restore-no-details nil)
    (dired-hide-details-mode -1))
  (advice-remove 'dired-revert #'media-progress-dired--revert-buffer)
  (remove-hook 'dired-before-readin-hook #'media-progress-dired--before-readin t)
  (remove-hook 'dired-after-readin-hook #'media-progress-dired--after-readin t)
  (remove-hook 'after-change-major-mode-hook #'media-progress-dired--after-mode t)
  (remove-hook 'first-change-hook #'media-progress-dired--on-first-change t)
  (setq font-lock-keywords
        (remove '(media-progress-dired--fontify-info) font-lock-keywords)))

;;;###autoload
(define-minor-mode media-progress-dired-mode
  "Toggle media progress info in current Dired buffer."
  :lighter " mprd"
  (unless (derived-mode-p 'dired-mode)
    (user-error "Not in a Dired buffer"))
  (cond
   ((not media-progress-dired-mode)
    (media-progress-dired--cleanup))
   (t
    (font-lock-add-keywords nil '(media-progress-dired--fontify-info))
    (advice-add 'dired-revert :after #'media-progress-dired--revert-buffer)
    (add-hook 'dired-before-readin-hook #'media-progress-dired--before-readin nil t)
    (add-hook 'dired-after-readin-hook #'media-progress-dired--after-readin nil t)
    (add-hook 'after-change-major-mode-hook #'media-progress-dired--after-mode nil t)
    (add-hook 'first-change-hook #'media-progress-dired--on-first-change nil t)
    (media-progress-dired--insert-info))))

(provide 'media-progress-dired)
;;; media-progress-dired.el ends here
