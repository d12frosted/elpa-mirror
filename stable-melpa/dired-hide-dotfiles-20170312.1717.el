;;; dired-hide-dotfiles.el --- Hde dotfiles in dired -*- lexical-binding: t; -*-

;; Copyright ⓒ 2017 Mattias Bengtsson
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with This program.  If not, see <http://www.gnu.org/licenses/>.
;;
;; Author: Mattias Bengtsson <mattias.jc.bengtsson@gmail.com>

;; Version	    : 0.1
;; Keywords	    : files
;; Package-Requires : ((emacs "25.1"))
;; Package-Version: 20170312.1717
;; Package-Commit: 32cf3b6f90dc56f6ff271c28d827aab303bc6221
;; URL		    : https://github.com/mattiasb/.emacs.d
;; Doc URL	    : TBA

;;; Commentary:

;; Hide dotfiles in dired.
;;
;; To activate this mode add something like this to your init.el:
;;
;;     (defun my-dired-mode-hook ()
;;       "My `dired' mode hook."
;;       ;; To hide dot-files by default
;;       (dired-hide-dotfiles-mode)
;;
;;       ;; To toggle hiding
;;       (define-key dired-mode-map "." #'dired-hide-dotfiles-mode))
;;
;;     (add-hook 'dired-mode-hook #'my-dired-mode-hook)

;;; Note:

;;; Code:

(require 'dired)

;;;###autoload
(define-minor-mode dired-hide-dotfiles-mode
  "Toggle `dired-hide-dotfiles-mode'"
  :init-value nil
  :lighter " !."
  :group 'dired
  (if dired-hide-dotfiles-mode
      (dired-hide-dotfiles--hide)
    (revert-buffer)))

;;;###autoload
(defun dired-hide-dotfiles--hide ()
  "Hide all dot-files in the current `dired' buffer."
  (when dired-hide-dotfiles-mode
    (dired-mark-files-regexp "^\\.")
    (dired-do-kill-lines)))

;;;###autoload
(add-hook 'dired-after-readin-hook 'dired-hide-dotfiles--hide)

(provide 'dired-hide-dotfiles)
;;; dired-hide-dotfiles.el ends here
