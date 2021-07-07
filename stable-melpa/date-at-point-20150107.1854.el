;;; date-at-point.el --- Add `date' to `thing-at-point' function

;; Copyright © 2014-2015 Alex Kost

;; Author: Alex Kost <alezost@gmail.com>
;; Created: 31 Dec 2014
;; Version: 0.1
;; Package-Version: 20150107.1854
;; Package-Commit: 662f8350a83311503dc0aae47a28752f9f1270c9
;; URL: https://gitorious.org/alezost-emacs/date-at-point
;; URL: https://github.com/alezost/date-at-point.el
;; Keywords: convenience

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

;; This file provides an additional `date' thing for `thing-at-point'
;; function.

;; Using:
;;
;; 1. Add (require 'date-at-point) to your elisp code.
;; 2. Use (thing-at-point 'date).

;; By default, a date in "2013-03-09"-like format is matched.  This can
;; be changed with `date-at-point-regexp' variable.

;;; Code:

(defvar date-at-point-regexp
  "[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}"
  "Regular expression matching a date.")

(declare-function thing-at-point-looking-at "thingatpt"
                  (regexp &optional distance))

(defun date-at-point-bounds ()
  "Return the bounds of the date at point."
  (save-excursion
    (when (thing-at-point-looking-at date-at-point-regexp)
      (cons (match-beginning 0) (match-end 0)))))

(put 'date 'bounds-of-thing-at-point 'date-at-point-bounds)

;;;###autoload
(defun date-at-point ()
  "Return the date at point, or nil if none is found."
  (thing-at-point 'date))

(provide 'date-at-point)

;;; date-at-point.el ends here
