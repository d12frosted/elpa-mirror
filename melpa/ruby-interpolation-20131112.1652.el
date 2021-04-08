;;; ruby-interpolation.el --- Ruby string interpolation helpers

;; Copyright (C) 2012 Arthur Leonard Andersen

;; Author: Arthur Leonard Andersen <leoc.git@gmail.com>
;; URL: http://github.com/leoc/ruby-interpolation.el
;; Package-Version: 20131112.1652
;; Package-Commit: 1978e337601222cedf00e117bf4b5cac15d1f203
;; Version: 0.1.0

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
;;
;;    A little minor mode providing electric keys for #{} interpolation
;;  in ruby
;;
;;; Installation:
;;
;;    Drop into your `vendor` directory and `(require 'ruby-interpolation)`
;;
;;; Code

(defvar ruby-interpolation-key "#"
  "The key to invoke ruby string interpolation via #{}")

(defvar ruby-interpolation-mode-map
  (let ((map (make-sparse-keymap))
        (key (read-kbd-macro ruby-interpolation-key)))
    (define-key map key 'ruby-interpolation-insert)
    map)
  "Keymap for `ruby-interpolation-mode`.")

(defun ruby-interpolation-string-at-point-p()
  (cond ((and ruby-interpolation-mode
	      (consp (memq 'font-lock-string-face (text-properties-at (point)))))
	 (save-excursion
	   (search-backward-regexp "\"\\|'" nil t)
	   (string= "\"" (string (char-after (point))))
	   ))))

(defun ruby-interpolation-insert ()
  "Called when interpolation key is pressed"
  (interactive)
  (if (ruby-interpolation-string-at-point-p)
      (progn (save-excursion (insert "#{}"))
             (forward-char 2))
    (insert "#")))

;;;###autoload
(define-minor-mode ruby-interpolation-mode
  "Automatic insertion of ruby string interpolation."
  :init-value nil
  :lighter " #{}"
  :keymap ruby-interpolation-mode-map)

(add-hook 'ruby-mode-hook 'ruby-interpolation-mode)

(provide 'ruby-interpolation)

;;; ruby-interpolation.el ends here
