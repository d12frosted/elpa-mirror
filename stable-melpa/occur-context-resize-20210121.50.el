;;; occur-context-resize.el --- dynamically resize context around matches in occur-mode

;; Copyright (C) 2014-2021 Charles L.G. Comstock

;; Author: Charles L.G. Comstock <dgtized@gmail.com>
;; Created: 19 Aug 2014
;; Version: 0.1
;; Package-Version: 20210121.50
;; Package-Commit: 9d62a5b5c39ab7921dfc12dd0ab139b38dd16582
;; URL: https://github.com/dgtized/occur-context-resize.el
;; Keywords: matching

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

;; Makes +,-, and 0 resize the context displayed around occur matches in
;; `occur-mode'.
;;
;; `occur-context-resize-default' will revert to whatever size context is
;; specified in `list-matching-lines-default-context-lines'.

;;; Usage:

;; Enable the package in `occur-mode' with the following:
;;
;;   (add-hook 'occur-mode-hook 'occur-context-resize-mode)

;;; Code:

(defun occur-context-resize-larger ()
  "Show more context around occur matches."
  (interactive)
  (setf (cadr occur-revert-arguments)
        (1+ (or (cadr occur-revert-arguments) 0)))
  (revert-buffer))

(defun occur-context-resize-smaller ()
  "Show less context around occur matches."
  (interactive)
  (setf (cadr occur-revert-arguments)
        (max (1- (or (cadr occur-revert-arguments) 0)) 0))
  (revert-buffer))

(defun occur-context-resize-default ()
  "Revert to show default context around occur-matches."
  (interactive)
  (setf (cadr occur-revert-arguments) nil)
  (revert-buffer))

;;;###autoload
(define-minor-mode occur-context-resize-mode
  "Dynamically resize context around matches in occur-mode.

\\{occur-context-resize-mode-map}"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "+") 'occur-context-resize-larger)
            (define-key map (kbd "-") 'occur-context-resize-smaller)
            (define-key map (kbd "0") 'occur-context-resize-default)
            map))

(provide 'occur-context-resize)
;;; occur-context-resize.el ends here
