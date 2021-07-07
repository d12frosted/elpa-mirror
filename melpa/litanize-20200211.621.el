;;; litanize.el --- Generate "Latour Litanies" -*- lexical-binding: t; -*-

;; Copyright 2019 FoAM oü
;;
;; AUTHOR: nik gaffney <nik@fo.am>
;; Created: 2019-01-19
;; Version: 0.2
;; Package-Version: 20200211.621
;; Package-Commit: ba73259e35b4649884ba56542d3a55f43bd3b80b
;; Package-Requires: ((emacs "24.1") (enlive "0.0.1") (s "1.12.0"))
;; Keywords: tools, Latour Litany, alien phenomenology, ontography, metaphorism, carpentry
;; URL: https://github.com/zzkt/litanizer

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; A simple version of Ian Bogost's method of generating "Latour Litanies"
;; from random wikipedia titles as an exercise in ontography, metaphorism,
;; and carpentry
;;
;; Currently uses wikipedia titles as elements. Might be extended to use
;; other lists in other futures.
;; 
;; 'M-x litanize' will generate a litany in a new buffer
;;
;; 'M-x litanize-at-point' will generate a litany at the point
;;
;; further -> http://bogost.com/writing/blog/latour_litanizer/


;;; Code:

(defgroup litanize nil
  "Generating 'Latour Litanies' as an exercise in ontography, metaphorism, and carpentry"
  :group 'stochastism)

(require 's)
(require 'enlive)

(defun litanize-wp-title ()
  "Return a random wikipedia title."
  (s-chop-suffix
   " - Wikipedia"
   (nth 2 (enlive-query
	   (enlive-fetch "https://en.wikipedia.org/wiki/Special:Random")
	   [title]))))


;;;###autoload
(defun litanize-litany (length)
  "Create an arbitary (or random) LENGTH litany in its own buffer."
    (interactive "nHow long a litany? ")
  (with-current-buffer (get-buffer-create "*Latour litany*")
    (erase-buffer)
    (when (<= length 3) (setq length 3))
    (dotimes (i length)
      (insert (litanize-wp-title))
      (cond ((<= i (- length 3)) (insert ", "))
	    ((=  i (- length 2)) (insert " & "))
	    ((=  i (- length 1)) (insert "."))))))

;;;###autoload
(defun litanize ()
  "Create a Latour Litany in its own buffer."
  (interactive)
  (litanize-litany 5))

;;;###autoload
(defun litanize-at-point ()
  "Create a Latour Litany at the current point."
  (interactive)
    (dotimes (i 5)
      (insert (litanize-wp-title))
      (cond ((<= i 2) (insert ", "))
	    ((=  i 3) (insert " & "))
	    ((=  i 4) (insert ".")))))


(provide 'litanize)

;;; litanize.el ends here
