;;; ac-math.el --- Auto-complete sources for input of mathematical symbols and latex tags
;;
;; Copyright (C) 2011-2013, Vitalie Spinu
;; Author: Vitalie Spinu
;; URL: https://github.com/vitoshka/ac-math
;; Package-Version: 20141116.2127
;; Package-Commit: c012a8f620a48cb18db7d78995035d65eae28f11
;; Keywords: latex, auto-complete, Unicode, symbols
;; Version: 1.1
;; Package-Requires: ((auto-complete "1.4") (math-symbol-lists "1.0"))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This file is *NOT* part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;; Features that might be required by this library:
;;
;;   auto-complete http://cx4a.org/software/auto-complete/
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;
;; This add-on defines three ac-sources for the
;; *[auto-complete](https://github.com/auto-complete)* package:
;; 
;; * ac-source-latex-commands	- input latex commands 
;; * ac-source-math-latex       - input math latex tags  (by default, active only in math environments in latex modes)
;; * ac-source-math-unicode     - input of unicode symbols (by default, active everywhere except math environments)
;; 
;; Start math completion by typing the prefix "\" key. Select the completion
;; type RET (`ac-complete`). Completion on TAB (`ac-expand`) is not that great
;; as you will see dummy characters, but it's usable.
;; 
;; (See https://github.com/vitoshka/ac-math#readme for more)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'math-symbol-lists)
(require 'auto-complete)

(defgroup ac-math nil
  "Auto completion."
  :group 'auto-complete
  :prefix "ac-math")

(defcustom ac-math-unicode-in-math-p nil
  "Set this to t if unicode in math latex environments is needed."
  :group 'ac-math)

(defcustom ac-math-prefix-regexp "\\\\\\(.*\\)"
  "Regexp matching the prefix of the ac-math symbol."
  :group 'ac-math)

(defvar ac-math--dummy " ")

(defun ac-math--make-candidates (alist &optional unicode)
  "Build a list of math symbols ready to be used in ac source.
Each element is a cons cell (SYMB . VALUE) where SYMB is the
string to be displayed during the completion and the VALUE is the
actually value inserted on RET completion.  If UNICODE is non-nil
the value of VALUE is the unicode character else it's the latex
command."
  (delq nil
        (mapcar
         #'(lambda (el)
	     (let* ((symb (substring (nth 1 el) 1))
		    ;; (sep (propertize ac-math--dummy 'display ""))
		    (sep ac-math--dummy)
		    (ch (and (nth 2 el) (decode-char 'ucs (nth 2 el))))
		    (uni-symb (and ch (char-to-string ch)))
		    (uni-string (concat sep uni-symb)))
	       (unless (and unicode (null uni-symb))
		 (cons (concat symb uni-string)
		       (if unicode
			   uni-symb
			 symb)))))
         alist)))

(defconst ac-math-symbols-latex
  (delete-dups
   (append (ac-math--make-candidates math-symbol-list-basic)
           (ac-math--make-candidates math-symbol-list-extended)))
  "List of math completion candidates.")

(defconst ac-math-symbols-unicode
  (delete-dups
   (append (ac-math--make-candidates math-symbol-list-basic t)
           (ac-math--make-candidates math-symbol-list-extended t)))
  "List of math completion candidates.")

(defun ac-math-action-latex (&optional del-backward)
  "Function to be used in ac action property.
Deletes the unicode symbol from the end of the completed
string. If DEL-BACKWARD is non-nil, delete the name of the symbol
instead."
  (let ((pos (point))
	(start-dummy (save-excursion
		       (re-search-backward ac-math--dummy (point-at-bol) 'no-error)))
	(end-dummy (match-end 0))
	(inhibit-point-motion-hooks t))
    (when start-dummy
      (if del-backward
	  (when end-dummy
	    (goto-char start-dummy)
	    (when (re-search-backward ac-math-prefix-regexp)
	      (delete-region (match-beginning 0) end-dummy))
	    (forward-word 1))
	(delete-region start-dummy (point))))))

(defun ac-math-action-unicode ()
  (ac-math-action-latex 'backward))

(defun ac-math-latex-math-face-p ()
  (let ((face (get-text-property (point) 'face)))
    (if (consp face)
        (eq  (car face) 'font-latex-math-face)
      (eq face 'font-latex-math-face))))

(defun ac-math-candidates-latex ()
  (when (ac-math-latex-math-face-p)
    ac-math-symbols-latex))

(defun ac-math-candidates-unicode ()
  (when (or ac-math-unicode-in-math-p
	    (not (ac-math-latex-math-face-p)))
    ac-math-symbols-unicode))

(defun ac-math-prefix ()
  "Return the location of the start of the current symbol.
Uses `ac-math-prefix-regexp'."
  (when (re-search-backward ac-math-prefix-regexp (point-at-bol) 'no-error)
    (match-beginning 1)))

;;;###autoload
(defvar ac-source-latex-commands
  '((candidates . math-symbol-list-latex-commands)
    (symbol . "c")
    (prefix . ac-math-prefix)))

;;;###autoload
(defvar ac-source-math-latex
  '((candidates . ac-math-candidates-latex)
    (symbol . "l")
    (prefix . ac-math-prefix)
    (action . ac-math-action-latex)))

;;;###autoload
(defvar ac-source-math-unicode
  '((candidates . ac-math-candidates-unicode)
    (symbol . "u")
    (prefix . ac-math-prefix)
    (action . ac-math-action-unicode)))

(provide 'ac-math)

;;; ac-math.el ends here
