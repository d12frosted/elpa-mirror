;;; smart-cursor-color.el --- Change cursor color dynamically
;;
;; Filename: smart-cursor-color.el
;; Description: Change cursor color dynamically at cursor or pointer.
;; Author: 7696122
;; Maintainer: 7696122
;; Created: Thu Oct 31 21:33:34 2013 (+0900)
;; Version: 0.0.6
;; Package-Version: 20201207.2228
;; Package-Commit: d532f0b27e37cbd3bfc0be09d0b54aa38f1648f1
;; Package-Requires: ()
;; Last-Updated: Tue Apr 29 22:35:48 2014 (+0900)
;;           By: 7696122
;;     Update #: 403
;; URL: https://github.com/7696122/smart-cursor-color/
;; Doc URL: http://7696122.github.io/smart-cursor-color/
;; Keywords: cursor, color, face
;; Compatibility: GNU Emacs: 24.x
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; Quickstart
;;
;; To make the mode enabled every time Emacs starts, add the following
;; to Emacs initialisation file (~/.emacs or ~/.emacs.d/init.el):
;;
;; If installed from melpa.
;;       (smart-cursor-color-mode 1)
;;
;; If installed manually,
;;       (add-to-list 'load-path "path-to-installed-directory")
;;       (require 'smart-cursor-color)
;;       (smart-cursor-color-mode 1)
;;
;; When hl-line-mode is on,
;; smart-cursor-color-mode is not work.
;; So must turn off hl-line-mode.
;;       (hl-line-mode -1)
;;
;; But when global-hl-line-mode is on,
;; smart-cursor-color-mode is work.
;;       (global-hl-line-mode 1)
;;       (smart-cursor-color-mode 1)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change Log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(defvar scc--last-cursor-color nil
  "Current cursor color for smart-cursor-color-mode.")

(defvar scc--default-cursor-color nil
  "Default cursor color.  When picked foreground color is nil, use this.")

(defvar scc--saved-cursor-color nil
  "Saved cursor color.  When turn off smart-cursor-color-mode, restore origin cursor color.")

(defgroup smart-cursor-color nil
  ""
  :group 'cursor)

(defcustom scc--ignore-modes '(org-agenda-mode)
  ""
  :group 'smart-cursor-color)

(defun scc--set-cursor-color ()
  "Change cursor color dynamically."
  (unless (member major-mode scc--ignore-modes)
    (let ((picked-color (foreground-color-at-point)))
      (if picked-color
          (unless (eq picked-color scc--last-cursor-color)
            (setq scc--last-cursor-color picked-color)
            (set-cursor-color scc--last-cursor-color))
        (unless (eq scc--default-cursor-color scc--last-cursor-color)
          (setq scc--last-cursor-color scc--default-cursor-color)
          (set-cursor-color scc--default-cursor-color))))))

(defun scc--fix-global-hl-line-mode ()
  "for global-hl-line-mode."
  (if (and global-hl-line-mode
           smart-cursor-color-mode)
      (progn
        (smart-cursor-color-mode -1)
        (smart-cursor-color-mode +1))))

;; (defun scc--reset-cursor-color ()
;;   ""
;;   (set-cursor-color scc--default-cursor-color))

(add-hook 'global-hl-line-mode-hook 'scc--fix-global-hl-line-mode)

;;;###autoload
(define-minor-mode smart-cursor-color-mode
  "Dynamically changed cursor color at point's color."
  :lighter " scc" :global t :group 'smart-cursor-color :require 'smart-cursor-color
  (if smart-cursor-color-mode
      (progn
        (setq scc--default-cursor-color (frame-parameter nil 'foreground-color))
        (setq scc--saved-cursor-color (frame-parameter nil 'cursor-color))
        (add-hook 'post-command-hook 'scc--set-cursor-color)
        ;; (add-hook 'buffer-list-update-hook 'scc--reset-cursor-color)
        )
    (remove-hook 'post-command-hook 'scc--set-cursor-color)
    ;; (remove-hook 'buffer-list-update-hook 'scc--reset-cursor-color)
    (unless (equal (frame-parameter nil 'cursor-color) scc--saved-cursor-color)
      (set-cursor-color scc--saved-cursor-color))))

;;;###autoload
(defun turn-on-smart-cursor-color ()
  "Unconditionally turn on `smart-cursor-color-mode'."
  (interactive)
  (smart-cursor-color-mode +1))

;;;###autoload
(defun turn-off-smart-cursor-color ()
  "Unconditionally turn off `smart-cursor-color-mode'."
  (interactive)
  (smart-cursor-color-mode -1))

(provide 'smart-cursor-color)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; smart-cursor-color.el ends here
