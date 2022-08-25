;;; lines-at-once.el --- Insert and edit multiple lines at once

;; Copyright (C) 2018 Jiahao Li

;; Author: Jiahao Li <jiahaowork@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20180422.247
;; Package-Commit: a018ba90549384d52ec58c2685fd14a0f65252be
;; Keywords: abbrev, tools
;; Homepage: https://github.com/jiahaowork/lines-at-once.el
;; Package-Requires: ((emacs "25"))

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

;; This package allows you to quickly insert and edit multiple lines.

;; Bind the key you prefer to the command lines-at-once-insert

;; For detailed explanations and more examples see the homepage:
;; https://github.com/jiahaowork/lines-at-once.el

;;; Code:
(require 'cl-lib)

(defconst lines-at-once-sep "@")

(defvar lines-at-once-current-markers '())
(make-variable-buffer-local 'lines-at-once-current-markers)

(defun lines-at-once-escape-split (string sep)
  "Split STRING while allowing using '\' to escape SEP."
  (let* ((raw-splits (split-string string sep))
	 (fragments '())
	 (escaped-splits '()))
    (while raw-splits
      (let* ((next (pop raw-splits)))
	(if (string-suffix-p "\\" next)
	    (progn
	      (setq next
		    (concat
		     (substring next 0 (1- (length next)))
		     sep))
	      (setq fragments (cons next fragments)))
	  (setq fragments (cons next fragments))
	  (setq escaped-splits
		(cons
		 (apply 'concat (reverse fragments))
		 escaped-splits))
	  (setq fragments '()))))
    (reverse escaped-splits)))

(defun lines-at-once-cumsum (x)
  "Compute the cumulative sum of X."
  (let ((res '(0)))
    (while x (setq res (cons (+ (car res) (pop x)) res)))
    (setq res (reverse res))
    (cdr res)))

(defun lines-at-once-parse (line)
  "Parse LINE.
Returns the parsed line string('\n' at the end included)
and the positions of '@'s.
If the format of LINE is invalid, return nil."
  (when (string-match "\\`\\(.+?\\)[ \f\t\n\r\v]+\\([[:digit:]]+\\)[ \f\t\n\r\v]*\\'" line)
    (let* ((repetition (string-to-number (match-string 2 line)))
	   (line (concat (match-string 1 line) "\n"))
	   (splits (lines-at-once-escape-split line lines-at-once-sep))
	   (parsed-line (apply 'concat splits))
	   (offsets (nbutlast
		     (lines-at-once-cumsum (mapcar 'length splits))
		     1)))
      (list parsed-line offsets repetition))))

(defun lines-at-once-make-markers (points)
  "Convenient function for making markers from POINTS."
  (mapcar (lambda (x) (set-marker (make-marker) x)) points))

(defvar lines-at-once-mode-map (make-sparse-keymap))
(define-key lines-at-once-mode-map (kbd "TAB") 'lines-at-once-next)
(define-minor-mode lines-at-once-mode
  "Minor mode when modifying the content of the template string."
  :init-value t)

;;;###autoload
(defun lines-at-once-insert ()
  "Expand the line at point to multiple lines."
  (interactive)
  (when lines-at-once-current-markers
    (mapcar
     (lambda (x) (set-marker x nil))
     lines-at-once-current-markers))
  (setq lines-at-once-mode t)
  (let ((matched (lines-at-once-parse (thing-at-point 'line))))
    (when matched
      (cl-destructuring-bind (line offsets repetition) matched
	(let* ((line-length (length line))
	       (begin-point (line-beginning-position)))
	  (setq lines (apply 'concat (make-list repetition line)))
	  (delete-region (line-beginning-position) (line-end-position))
	  (goto-char begin-point)
	  (insert lines)
	  (setq lines-at-once-current-markers
		(lines-at-once-make-markers
		 (mapcar
		  (apply-partially '+ begin-point)
		  (append
		   (apply
		    (apply-partially 'cl-concatenate 'list)
		    (mapcar
		     (lambda (x)
		       (mapcar
			(lambda (y)
			  (+ y (* x line-length)))
			offsets))
		     (number-sequence 0 (1- repetition))))
		   (list (length lines))))))
	  (lines-at-once-next))))))

(defun lines-at-once-next ()
  "Jump to the next position where '@' specifies."
  (interactive)
  (when lines-at-once-current-markers
    (let* ((marker (pop lines-at-once-current-markers)))
      (goto-char marker)
      (set-marker marker nil))
    (unless lines-at-once-current-markers
      (setq lines-at-once-mode nil))))

(provide 'lines-at-once)

;;; lines-at-once.el ends here
