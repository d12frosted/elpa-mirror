;;; pdf-view-pagemark.el --- Add indicator in pdfview mode to show the page remaining

;; Copyright (c) 2023 Kimi Ma <kimi.im@outlook.com>

;; Author:  Kimi Ma <kimi.im@outlook.com>
;; URL: https://github.com/kimim/pdf-view-pagemark
;; Package-Version: 20230516.252
;; Package-Commit: fa0ae8c8225b7489b6356e8521b91727681aa441
;; Keywords: multimedia convenience
;; Version: 0.1
;; Package-Requires: ((pdf-tools "0.90") (posframe "1.4.2") (emacs "26.0"))

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
;; Because Emacs cannot show continuous pages at the same time, it is
;; difficult to keep track of the remaining text in current page, this
;; minor mode add a posframe indicator to tell you the line from
;; scroll up.
;;
;; To enable, add the following:
;;   (add-hook 'pdf-view-mode-hook 'pdf-view-pagemark-mode)

;;; Code:

(require 'pdf-view)
(require 'posframe)

(defcustom pdf-view-pagemark-buffer "*pdf-view-pagemark*"
  "Buffer name to show pagemark."
  :group 'pdf-view
  :type 'string)

(defcustom pdf-view-pagemark-timeout 3
  "Timeout to show pagemark."
  :group 'pdf-view
  :type 'integer)

(defcustom pdf-view-pagemark-alpha 40
  "Trasparency level of pagemark posframe."
  :group 'pdf-view
  :type 'integer)

(defface pdf-view-pagemark-color
  nil
  "Background color of pagemark posframe."
  :group 'pdf-view)

;;;###autoload
(define-minor-mode pdf-view-pagemark-mode
  "Automatically show pagemark indicator."
  :global nil
  (if (not pdf-view-pagemark-mode)
      (advice-remove 'image-scroll-up 'pdf-view-pagemark-indicate)
    (pdf-view-pagemark)))

(defun pdf-view-pagemark ()
  "Enable pagemark."
  (when (derived-mode-p 'pdf-view-mode)
    ;; This buffer is in pdf-view-mode
    (advice-add 'image-scroll-up :before 'pdf-view-pagemark-indicate)))

(defun pdf-view-pagemark-image-height ()
  "Get pdf height."
  (let ((image (image-get-display-property)))
    (ceiling (cdr (image-display-size image t)))))

(defun pdf-view-pagemark-image-width ()
  "Get pdf width."
  (let ((image (image-get-display-property)))
    (ceiling (car (image-display-size image t)))))

(defun pdf-view-pagemark-win-height ()
  "Get window height."
  (let ((edges (window-edges nil t t)))
    (- (nth 3 edges) (nth 1 edges))))

(defun pdf-view-pagemark-win-width ()
  "Get window width."
  (let ((edges (window-edges nil t t)))
    (- (nth 2 edges) (nth 0 edges))))

(defun pdf-view-pagemark-rem-height ()
  "Calculate remaining height of pdf page."
  (- (pdf-view-pagemark-image-height) (window-vscroll nil t)
     (pdf-view-pagemark-win-height)))

(defun pdf-view-pagemark-position ()
  "Calculate indicator position."
  (- (pdf-view-pagemark-win-height)
     (pdf-view-pagemark-rem-height)
     10))

(defun pdf-view-pagemark-indicate (&optional n)
  "Show indicator for remaining pdf page, `N' is not used."
  (let* ((left-indent (/ (- (pdf-view-pagemark-win-width)
                            (pdf-view-pagemark-image-width))
                         2))
         (rem-height (pdf-view-pagemark-rem-height))
         (len (/ (pdf-view-pagemark-image-width) (frame-char-width)))
         (bg (or (face-background 'pdf-view-pagemark-color)
                 (face-background 'highlight))))
    (if (and (< 0 rem-height)
             (< rem-height (pdf-view-pagemark-win-height)))
        (set-frame-parameter
         (posframe-show pdf-view-pagemark-buffer
                        :string (make-string len ?-)
                        :foreground-color bg
                        :background-color bg
                        :position `(,left-indent . ,(pdf-view-pagemark-position))
                        :timeout pdf-view-pagemark-timeout)
         'alpha pdf-view-pagemark-alpha)
      (posframe-delete pdf-view-pagemark-buffer))))

(provide 'pdf-view-pagemark)
;;; pdf-view-pagemark.el ends here
