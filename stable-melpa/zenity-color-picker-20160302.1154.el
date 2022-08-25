;;; zenity-color-picker.el --- Insert and adjust colors using Zenity  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Samuel Laurén

;; Author: Samuel Laurén <samuel.lauren@iki.fi>
;; Keywords: colors
;; Package-Version: 20160302.1154
;; Package-Commit: bdece51052ef7037e0a3481fc1f487939f57777e
;; Version: 0.1.0
;; URL: https://bitbucket.org/Soft/zenity-color-picker.el
;; Package-Requires: ((emacs "24.4"))

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

;; Insert and adjust colors using Zenity. Zenity
;; (https://help.gnome.org/users/zenity/stable/) is obviously required.

;;; KNOWN ISSUES

;; - Color presentation can change between adjustments
;; - No support for three-letter hex colors


;;; Code:

(require 'cl-lib)
(require 'thingatpt)

(defvar zenity-cp-zenity-bin "zenity")

(defun zenity-cp-to-color (str)
  (cond ((zenity-cp-hex-color-p str) (zenity-cp-hex-to-color str))
        ((zenity-cp-rgb-color-p str) (zenity-cp-rgb-to-color str))
        (t nil)))

(defconst zenity-cp-hex-color-regexp
  "#\\([a-f0-9]\\{2\\}\\)\\([a-f0-9]\\{2\\}\\)\\([a-f0-9]\\{2\\}\\)")

(defconst zenity-cp-rgb-color-regexp
  "rgb(\\([0-9]\\{1,3\\}\\),\\([0-9]\\{1,3\\}\\),\\([0-9]\\{1,3\\}\\))")

(defun zenity-cp-hex-color-p (str)
  "Check if STR is a valid hex formatted color string"
  (and (string-match-p zenity-cp-hex-color-regexp (downcase str)) t))

(defun zenity-cp-hex-to-color (str)
  (save-match-data
    (string-match zenity-cp-hex-color-regexp str)
    (mapcar
     (lambda (index)
       (string-to-number (match-string index str) 16))
     '(1 2 3))))

(defun zenity-cp-rgb-color-p (str)
  "Check if STR is a valid rgb formatted color string"
  (and (string-match-p zenity-cp-rgb-color-regexp str) t))

(defun zenity-cp-rgb-to-color (str)
  (save-match-data
    (string-match zenity-cp-rgb-color-regexp str)
    (mapcar
     (lambda (index)
       (string-to-number (match-string index str)))
     '(1 2 3))))

(defun zenity-cp--short-p (n)
  (= (lsh n -4) (logand n #xf)))

(defun zenity-cp-color-to-hex (color &optional short)
  "Convert (R G B) list to hex string. If SHORT is not NIL, try
to use CSS-style shorthand notation."
  (cl-destructuring-bind (r g b) color
    (if (and short (zenity-cp--short-p r) (zenity-cp--short-p g) (zenity-cp--short-p b))
        (format "#%x%x%x"
                (logand r #xf)
                (logand g #xf)
                (logand b #xf))
      (format "#%02x%02x%02x" r g b))))

(defun zenity-cp-color-picker (&optional initial)
  "Execute zenity color picker.

Returns the selected color as a list of form (RED GREEN BLUE) or
NIL if selection was cancelled."
  (if (executable-find zenity-cp-zenity-bin)
      (with-temp-buffer
        (pcase (apply 'call-process
                      (append `(,zenity-cp-zenity-bin nil (,(current-buffer) nil) nil "--color-selection")
                              (when initial
                                (list (format "--color=%s" (zenity-cp-color-to-hex initial)))))) 
          (`0 (zenity-cp-to-color (buffer-string)))))
    (error "Could not find %s" zenity-cp-zenity-bin)))

(defun zenity-cp-bounds-of-color-at-point ()
  (save-excursion
    (skip-chars-backward "#a-fA-F0-9")
    (when (looking-at zenity-cp-hex-color-regexp)
      (cons (point) (match-end 0)))))

(put 'color 'bounds-of-thing-at-point
     'zenity-cp-bounds-of-color-at-point)

(defun zenity-cp-color-at-point ()
  (let ((color (thing-at-point 'color t)))
    (when color
      (zenity-cp-to-color color))))

(defun zenity-cp-transform-color-at-point (transform)
  (let ((bounds (zenity-cp-bounds-of-color-at-point))
        (old (zenity-cp-color-at-point)))
    (when old
      (let ((new (funcall transform old)))
        (when new
          (save-excursion
            (goto-char (car bounds))
            (delete-region (car bounds) (cdr bounds))
            (insert (zenity-cp-color-to-hex new))))))))

;;;###autoload
(defun zenity-cp-adjust-color-at-point ()
  "Adjust color at point"
  (interactive)
  (zenity-cp-transform-color-at-point #'zenity-cp-color-picker))

;;;###autoload
(defun zenity-cp-insert-color-at-point ()
  "Insert color at point"
  (interactive)
  (let ((color (zenity-cp-color-picker)))
    (insert (zenity-cp-color-to-hex color))))

;;;###autoload
(defun zenity-cp-color-at-point-dwim ()
  "Adjust or insert color at point"
  (interactive)
  (if (zenity-cp-color-at-point)
      (zenity-cp-adjust-color-at-point)
    (zenity-cp-insert-color-at-point)))

(provide 'zenity-color-picker)
;;; zenity-color-picker.el ends here
