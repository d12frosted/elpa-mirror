;;; dired-hide-dotfiles.el --- Hide dotfiles in dired -*- lexical-binding: t; -*-

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
;; Package-Version: 20210222.1919
;; Package-Commit: 6a379f23f64045f5950d229254ce6f32dbbf5364
;; URL		    : https://github.com/mattiasb/dired-hide-dotfiles
;; Doc URL	    : TBA

;;; Commentary:

;; Hide dotfiles in dired.
;;
;; To activate this mode add something like this to your init.el:
;;
;;     (defun my-dired-mode-hook ()
;;       "My `dired' mode hook."
;;       ;; To hide dot-files by default
;;       (dired-hide-dotfiles-mode))
;;
;;     ;; To toggle hiding
;;     (define-key dired-mode-map "." #'dired-hide-dotfiles-mode)
;;     (add-hook 'dired-mode-hook #'my-dired-mode-hook)

;;; Note:

;;; Code:

(require 'dired)

(defgroup dired-hide-dotfiles nil
  "Dired hide dotfiles."
  :group 'dired)

(defcustom dired-hide-dotfiles-verbose t
  "When non-nil, show how many dotfiles were hidden."
  :version "0.2"
  :type 'boolean
  :group 'dired-hide-dotfiles)

;;;###autoload
(define-minor-mode dired-hide-dotfiles-mode
  "Toggle `dired-hide-dotfiles-mode'"
  :init-value nil
  :lighter " !."
  :group 'dired
  (if dired-hide-dotfiles-mode
      (progn
        (add-hook 'dired-after-readin-hook 'dired-hide-dotfiles--hide)
        (dired-hide-dotfiles--hide))
    (remove-hook 'dired-after-readin-hook 'dired-hide-dotfiles--hide)
    (revert-buffer)))

(defun dired-hide-dotfiles--hide ()
  "Hide all dot-files in the current `dired' buffer."
  (let ((inhibit-message t))
    (dired-mark-files-regexp "^\\."))
  (dired-do-kill-lines nil (if dired-hide-dotfiles-verbose
                               "Hid %d dotfile%s."
                             "")))

(provide 'dired-hide-dotfiles)
;;; dired-hide-dotfiles.el ends here
