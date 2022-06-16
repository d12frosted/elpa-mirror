;;; stylefmt.el --- Stylefmt interface
;; copyright (C) 2015 κeen All rights reserved.
;; Author: κeen
;; Version: 0.0.2
;; Package-Version: 20161025.824
;; Package-Commit: 7a38f26bf8ff947215f34f0a064c7ca80575ccbc
;; Keywords: style code formatter
;; URL: https://github.com/KeenS/stylefmt.el
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
;;
;;; Commentary:
;; This is a thin wrapper of [stylefmt](https://github.com/morishitter/stylefmt)
;;
;;; Installation:
;; 1. install stylefmt. If you have installed npm, just type `npm install -g stylefmt`
;; 2 Add your init.el
;;   (load "path/to/stylefmt.el)
;;   ;optional    
;;   (add-hook 'css-mode-hook 'stylefmt-enable-on-save)
;;; Code:

(defgroup stylefmt nil
  "'stylefmt' interface."
  :group 'style)

(defcustom stylefmt-command "stylefmt"
  "The 'stylefmt' command."
  :type 'string
  :group 'stylefmt)

(defcustom stylefmt-popup-errors nil
  "Display error buffer when stylefmt fails."
  :type 'boolean)

(defun stylefmt--call (buf)
  "Format BUF using stylefmt."
  (with-current-buffer (get-buffer-create "*stylefmt*")
    (erase-buffer)
    (insert-buffer-substring buf)
    (if (zerop (call-process-region (point-min) (point-max) stylefmt-command t t nil))
        (progn (copy-to-buffer buf (point-min) (point-max))
               (kill-buffer))
      (when stylefmt-popup-errors
        (display-buffer (current-buffer)))
      (error "stylefmt failed, see *stylefmt* buffer for details"))))

;;;###autoload
(defun stylefmt-format-buffer ()
  "Format the current buffer according to the stylefmt tool."
  (interactive)
  (unless (executable-find stylefmt-command)
    (error "Could not locate executable \"%s\"" stylefmt-command))

  (let ((cur-point (point))
        (cur-win-start (window-start)))
    (stylefmt--call (current-buffer))
    (goto-char cur-point)
    (set-window-start (selected-window) cur-win-start))
  (message "Formatted buffer with stylefmt."))

;;;###autoload
(defun stylefmt-enable-on-save ()
  "Add this to .emacs to run stylefmt on the current buffer when saving:
 (add-hook 'after-save-hook 'stylefmt-after-save).

Note that this will cause style-mode to get loaded the first time
you save any file, kind of defeating the point of autoloading."

  (interactive)
  (add-hook 'before-save-hook 'stylefmt-format-buffer nil t))

;;;###autoload
(defun stylefmt-disable-on-save ()
  "disable the on-save hook"
  (interactive)
  (remove-hook 'before-save-hook 'stylefmt-format-buffer t))

(provide 'stylefmt)
;;; stylefmt.el ends here
