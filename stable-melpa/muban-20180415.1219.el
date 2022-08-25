;;; muban.el --- Lightweight template expansion tool

;; Copyright (C) 2018 Jiahao Li

;; Author: Jiahao Li <jiahaowork@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20180415.1219
;; Package-Commit: c134c46e60be1fb3e9a08dba3d07346855e0fcc2
;; Keywords: abbrev, tools
;; Homepage: https://github.com/jiahaowork/muban.el
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

;; This is a simple package for quickly insert template strings.

;; Bind the key you prefer to the command muban-apply:
;; (local-set-key (kbd "somekey") 'muban-apply)

;; A simple example:
;; Save the following content in ~/.emacs.muban:
;; #muban-begin exam#0ple
;; #0<img src=@url@>#0

;; Then you can insert
;; <img src="url">
;; ...other 8 times...
;; <img src="url">
;; simply by typing exam10ple at the insertion point
;; and execute 'muban-apply (better to bind some key).
;; Use TAB to quickly modify the content of "url".

;; For detailed explanations and more examples see the homepage:
;; https://github.com/jiahaowork/muban.el

;;; Code:
(require 'cl-lib)

(defconst muban-file-path "~/.emacs.muban")
(defconst muban-sep "@")
(defconst muban-expand-sep "#")

(defvar muban-formulas '())
(defvar muban-templates '())
(defvar muban-rep-digits '())
(defvar muban-current-markers '())
(make-variable-buffer-local 'muban-current-markers)

(defun muban-parse-formula (formula)
  "Parse FORMULA.
Return the formula regex and repetition digits"
  (let* ((rep-digits '()))
    (while (string-match
	    "#\\([[:digit:]]\\)"
	    formula)
      (setq rep-digits
	    (cons
	     (string-to-number
	      (match-string 1 formula))
	     rep-digits))
      (setq formula
	    (replace-match
	     "\\([[:digit:]]+\\)"
	     t t formula)))
    (list formula (reverse rep-digits))))

(defun muban-parse-file (path)
  "Parse the template file PATH."
  (let* ((string-list
	  (split-string
	   (with-temp-buffer
	     (insert-file-contents path)
	     (buffer-string))
	   "\\([ \f\t\n\r\v]*\\|\\`\\)#muban-begin[ \f\t\n\r\v]+"
	   t)))
    (while string-list
      (let* ((string (pop string-list)))
	(string-match
	 "\\`\\([^\n]+\\)\n\\([[:ascii:][:nonascii:]]+\\)\\'"
	 string)
	(setq muban-templates
	      (cons (match-string 2 string) muban-templates))
	(cl-destructuring-bind
	    (formula rep-digits)
	    (muban-parse-formula
	     (match-string 1 string))
	  (setq muban-formulas (cons formula muban-formulas))
	  (setq muban-rep-digits (cons rep-digits muban-rep-digits)))))))

(defun muban-md5 (path)
  "Get the md5 of PATH."
  (let* ((command
	  (concat
	   (pcase system-type
	     ('gnu/linux "md5sum")
	     ('darwin "md5")) " " path))
	 (output
	  (shell-command-to-string command)))
    (string-match "[[:alnum:]]\\{32\\}" output)
    (match-string 0 output)))

(defun muban-find-parsed-file ()
  "Test if the user defined file has been modified.
If not, return the already parsed file."
  (let ((filepath
	 (concat
	  muban-file-path "."
	  (muban-md5 muban-file-path))))
    (car (cl-remove-if-not
	  (lambda (x) (string= x filepath))
	  (file-expand-wildcards
	   (concat
	    muban-file-path
	    ".*"))))))

(defun muban-init ()
  "Initialize global variables."
  (let ((path (muban-find-parsed-file)))
    (if path
	(cl-destructuring-bind
	    (formulas rep-digits templates)
	    (car
	     (read-from-string
	      (with-temp-buffer
		(insert-file-contents path)
		(buffer-string))))
	  (setq muban-formulas formulas)
	  (setq muban-rep-digits rep-digits)
	  (setq muban-templates templates))
      (mapcar
       'delete-file
       (file-expand-wildcards
	(concat muban-file-path ".*")))
      (muban-parse-file muban-file-path)
      (write-region
       (prin1-to-string
	(list
	 muban-formulas
	 muban-rep-digits
	 muban-templates))
       nil
       (concat
	muban-file-path "."
	(muban-md5 muban-file-path))))))

(defun muban-escape-split (string sep)
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

(defun muban-expand (template reps)
  "Repeat some portions of TEMPLATE according to REPS."
  (let* ((digits (number-sequence 0 9)))
    (while digits
      (let* ((digit (pop digits))
	     (rep (nth digit reps))
	     (sep (concat muban-expand-sep
			  (number-to-string digit)))
	     (splits (muban-escape-split template sep))
	     (new-splits '()))
	(while splits
	  (setq new-splits (cons (pop splits) new-splits))
	  (when splits
	    (setq new-splits
		  (cons
		   (apply 'concat (make-list rep (pop splits)))
		   new-splits))))
	(setq template
	      (apply 'concat (reverse new-splits))))))
  template)

(defun muban-cumsum (x)
  "Compute the cumulative sum of X."
  (let ((res '(0)))
    (while x (setq res (cons (+ (car res) (pop x)) res)))
    (setq res (reverse res))
    (cdr res)))

(defun muban-parse (template)
  "Parse TEMPLATE.
Returns parsed template string and the positions of '@'s."
  (let* ((splits (muban-escape-split template muban-sep))
	 (parsed-template (apply 'concat splits))
	 (offsets (muban-cumsum (mapcar 'length splits))))
    (setq offsets (reverse (cdr (reverse offsets))))
    (list parsed-template offsets)))

(defun muban-match ()
  "Match formulas to the string at point."
  (let* ((current-formula nil)
	 (unprocessed-formulas muban-formulas)
	 (matched-start-pos nil)
	 (current-point (point))
	 (line-string (thing-at-point 'line))
	 (line-begin (line-beginning-position))
	 (index -1)
	 (reps nil))
    (while unprocessed-formulas
      (setq index (1+ index))
      (setq current-formula
	    (pop unprocessed-formulas))
      (setq matched-start-pos
	    (string-match current-formula line-string))
      (if (and
	   matched-start-pos
	   (= (+ line-begin (match-end 0))
	      current-point))
	  (progn
	    (setq matched-start-pos
		  (+ (line-beginning-position)
		     matched-start-pos))
	    (setq unprocessed-formulas nil))
	(setq matched-start-pos nil)))
    (when matched-start-pos
      (list index matched-start-pos))))

(defun muban-get-reps (string index)
  "Get the reptition numbers of STRING after matching the INDEX template."
  (let* ((reps (make-list 10 0))
	 (digits (nth index muban-rep-digits))
	 (count 0))
    (while digits
      (setq count (1+ count))
      (setcar (nthcdr (pop digits) reps)
	      (string-to-number
	       (match-string count string))))
    reps))

(defun muban-make-marker (pos insertion-type)
  "Convenient function for making markers of POS and INSERTION-TYPE."
  (let ((marker (make-marker)))
    (set-marker-insertion-type marker insertion-type)
    (set-marker marker pos)))

(defun muban-get-markers (points)
  "Get markers from POINTS."
  (let ((markers '()))
    (while points
      (let* ((begin (muban-make-marker (pop points) nil))
	     (end (muban-make-marker (pop points) t)))
	(setq markers (cons begin markers))
	(setq markers (cons end markers))))
    (reverse markers)))

(defvar muban-mode-map (make-sparse-keymap))
(define-key muban-mode-map (kbd "TAB") 'muban-next)
(define-minor-mode muban-mode
  "Minor mode when modifying the content of the template string."
  :init-value nil)

;;;###autoload
(defun muban-apply ()
  "The only function for the user."
  (interactive)
  (when muban-current-markers
    (mapcar
     (lambda (x) (set-marker x nil))
     muban-current-markers))
  (let* ((line-string (thing-at-point 'line))
	 (reps nil)
	 (match (muban-match)))
    (if match
	(let* ((index (pop match))
	       (start-pos (pop match))
	       (template-and-offsets
		(muban-parse
		 (muban-expand
		  (nth index muban-templates)
		  (muban-get-reps
		   line-string index))))
	       (template-string
		(pop template-and-offsets)))
	  (delete-region start-pos (point))
	  (insert template-string)
	  (setq muban-current-markers
		(muban-get-markers
		 (mapcar
		  (lambda (x) (+ x start-pos))
		  (append
		   (pop template-and-offsets)
		   (make-list 2 (length template-string))))))
	  (setq muban-mode t)
	  (call-interactively 'muban-next))
      (setq muban-mode nil))))

(defun muban-next ()
  "Jump to the next position where '@' specifies."
  (interactive)
  (when muban-current-markers
    (let* ((begin (pop muban-current-markers))
	   (end (pop muban-current-markers)))
      (delete-region begin end)
      (goto-char begin)
      (set-marker begin nil)
      (set-marker end nil))
    (unless muban-current-markers
      (setq muban-mode nil))))

(muban-init)

(provide 'muban)

;;; muban.el ends here
