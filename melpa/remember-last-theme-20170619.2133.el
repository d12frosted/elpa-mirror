;;; remember-last-theme.el --- Remember the last used theme between sessions. -*- lexical-binding: t-*-
;;
;; Author: Anler Hernández Peral <inbox+emacs@anler.me>
;; Maintainer: Anler Hernández Peral <inbox+emacs@anler.me>
;; Created: 26 Feb 2017
;; Version: 1.1.0
;; Package-Version: 20170619.2133
;; Package-Commit: 57e8e2a475ea89316dbb5c4d2ea047f56a2cbcdf
;; Keywords: convenience faces
;; URL: https://github.com/anler/remember-last-theme
;; Package-Requires: ((emacs "24.4"))
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Remember the last used theme between Emacs sessions. When you quit
;; Emacs, the current theme settings will be stored as if they had
;; been set using `customize-themes'.
;;
;; Usage:
;;  (require 'remember-last-theme) ; if installed manually
;;  (remember-last-theme-enable)
;;
;;; Code:
(require 'cus-edit)

(defun remember-last-theme-save ()
  "Save the current theme(s) for next sessions."
  (interactive)
  (customize-save-variable 'custom-enabled-themes custom-enabled-themes))

(defun remember-last-theme-with-file-save (filename)
  "Save the current theme(s) for next sessions."
  (defun perform-save ()
    (interactive)
    (with-temp-buffer
      (print custom-enabled-themes (current-buffer))
      (if (file-writable-p filename)
          (write-file filename)
        (message (format "Cannot save themes because %s is not writable" filename))))))

(defun remember-last-theme-with-file-load (filename)
  "Load the current theme(s) for current session."
  (defun perform-load ()
    (interactive)
    (if (file-readable-p filename)
        (mapc
         'load-theme
         (read (with-temp-buffer
                 (insert-file-contents filename)
                 (buffer-string))))
      (message (format "Cannot load saved themes because %s is not readable" filename)))))

;;;###autoload
(defun remember-last-theme-enable ()
  "Ensure that the current theme(s) will be saved when Emacs exits."
  (interactive)
  (add-hook 'kill-emacs-hook 'remember-last-theme-save))

;;;###autoload
(defun remember-last-theme-with-file-enable (filename)
  "Ensure that the current theme(s) will be saved when Emacs exits."
  (interactive "F")
  (message filename)
  (add-hook 'kill-emacs-hook (remember-last-theme-with-file-save filename))
  (add-hook 'after-init-hook (remember-last-theme-with-file-load filename))
  )

(provide 'remember-last-theme)
;;; remember-last-theme.el ends here
