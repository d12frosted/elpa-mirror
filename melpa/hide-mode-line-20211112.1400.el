;;; hide-mode-line.el --- minor mode that hides/masks your modeline -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2018-2021 Henrik Lissner
;;
;; Author: Henrik Lissner <http://github/hlissner>
;; Maintainer: Henrik Lissner <git@henrik.io>
;; Created: March 01, 2018
;; Modified: November 12, 2021
;; Version: 1.0.3
;; Package-Version: 20211112.1400
;; Package-Commit: bc5d293576c5e08c29e694078b96a5ed85631942
;; Keywords: frames mode-line
;; URL: https://github.com/hlissner/emacs-hide-mode-line
;; Package-Requires: ((emacs "24.4"))
;;
;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;; Provides `hide-mode-line-mode`.  A minor mode that hides (or masks) the
;; mode-line in your current buffer.  It can be used to toggle an alternative
;; mode-line, toggle its visibility, or simply disable the mode-line in buffers
;; where it isn't very useful otherwise.
;;
;;; Code:

(defvar hide-mode-line-format nil
  "The modeline format to use when `hide-mode-line-mode' is active.")

(defvar hide-mode-line-excluded-modes '(fundamental-mode)
  "List of major modes where `global-hide-mode-line-mode' won't affect.")

(defvar-local hide-mode-line--old-format nil
  "Storage for the old `mode-line-format', so it can be restored when
`hide-mode-line-mode' is disabled.")

;;;###autoload
(define-minor-mode hide-mode-line-mode
  "Minor mode to hide the mode-line in the current buffer."
  :init-value nil
  :global nil
  (if hide-mode-line-mode
      (progn
        (add-hook 'after-change-major-mode-hook #'hide-mode-line-mode nil t)
        (unless hide-mode-line--old-format
          (setq hide-mode-line--old-format mode-line-format))
        (setq mode-line-format hide-mode-line-format))
    (remove-hook 'after-change-major-mode-hook #'hide-mode-line-mode t)
    (setq mode-line-format hide-mode-line--old-format
          hide-mode-line--old-format nil))
  (when (called-interactively-p 'any)
    (redraw-display)))

;; Ensure major-mode or theme changes don't overwrite these variables
(put 'hide-mode-line--old-format 'permanent-local t)
(put 'hide-mode-line-mode 'permanent-local-hook t)

;;;###autoload
(define-globalized-minor-mode global-hide-mode-line-mode
  hide-mode-line-mode turn-on-hide-mode-line-mode
  (redraw-display))

;;;###autoload
(defun turn-on-hide-mode-line-mode ()
  "Turn on `hide-mode-line-mode'.
Unless in `fundamental-mode' or `hide-mode-line-excluded-modes'."
  (unless (memq major-mode hide-mode-line-excluded-modes)
    (hide-mode-line-mode +1)))

;;;###autoload
(defun turn-off-hide-mode-line-mode ()
  "Turn off `hide-mode-line-mode'."
  (hide-mode-line-mode -1))

(provide 'hide-mode-line)
;;; hide-mode-line.el ends here
