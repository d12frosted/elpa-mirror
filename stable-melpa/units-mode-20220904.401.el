;;; units-mode.el --- Mode for conversion between different units -*- lexical-binding: t -*-

;; Copyright (C) 2022

;; Author: Gaurav Atreya <allmanpride@gmail.com>
;; Maintainer:
;; URL: https://github.com/Atreyagaurav/units-mode
;; Package-Version: 20220904.401
;; Package-Commit: 22cfd1a9e4264eb4b95b0ef58aaa08cae862e924
;; Version: 0.1
;; Package-Requires: ((emacs "24.4"))
;; Homepage: https://github.com/Atreyagaurav/units-mode
;; Keywords: units,unit-conversion,convenience


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
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

;; This is Emacs interface to gnu units program <https://www.gnu.org/software/units/units.html>.

;; For detailed help visit github page:
;; https://github.com/Atreyagaurav/units-mode

;;; Code:
(require 'cl-lib)

(defcustom units-binary-path "units"
  "Path to the units binary." :group 'units :type 'string)

(defvar units-default-args "-t"
  "Default args to add to units command.")

(defcustom units-user-args ""
  "Extra args for user to add to units command."
  :group 'units :type 'string)

(defvar units-insert-separator " = "
  "Separator to insert before inserting the `units' outputs.")

(defun units-command (args)
  "Run the units command with ARGS and return the output."
  (string-trim-right
   (shell-command-to-string
    (format "%s %s %s %s"
	    units-binary-path
	    units-default-args
	    units-user-args
	    args))))


(defun units-convert (value to-unit)
  "Convert VALUE to TO-UNIT unit."
  (let ((out-lines (split-string
		     (units-command
		      (format "\"%s\" \"%s\""
			      value to-unit)) "\n")))
    (if (and (= (length out-lines) 1)
	     (string-match-p "^[0-9.e;]+$"
			     (car out-lines)))
	(car out-lines)
      (user-error "%s" (string-join out-lines "\n")))))

(defun units-convert-single (value from-unit to-unit)
  "Convert a single VALUE from FROM-UNIT to TO-UNIT."
  (units-convert (format "%s %s" value from-unit) to-unit))

(defun units-convert-simple (value from-unit to-unit)
  "Convert a single VALUE from FROM-UNIT to TO-UNIT."
  (read
   (units-convert
    (format "%s %s" value from-unit) to-unit)))

(defun units-convert-formatted (value to-unit)
  "Convert VALUE to TO-UNIT and format the output."
  (let ((converted (units-convert value to-unit)))
    (if (cl-search ";" to-unit)
	(let ((values (split-string converted ";"))
	      (units (split-string to-unit ";")))
	  (string-join
	   (cl-loop for val in values
		    for unt in units
		    if (> (string-to-number val) 0)
		    collect (format "%s %s" val unt)) " + "))
      (format "%s %s" converted to-unit))))


(defun units-conformable-list (value)
  "Conformable units list related to VALUE."
  (let ((output (units-command (format "--conformable \"%s\""
				       value))))
    (if (not (string-match-p "Unknown unit" output))
	      (split-string output
	       "\n")
      (user-error output))))


(defun units-get-interactive-args ()
  "Get Args for interactive input of REGION-TEXT and TO-UNITS."
  (let ((region-text
	  (buffer-substring-no-properties
	   (region-beginning) (region-end))))
      (list region-text
	    (completing-read
	     "Convert to: "
	     (units-conformable-list region-text)))))

(defun units-convert-region (region-text to-unit)
  "Convert the marked REGION-TEXT to TO-UNIT."
  (interactive (units-get-interactive-args))
  (message "%s" (units-convert-formatted region-text to-unit)))

(defun units-reduce (value)
  "Reduce the VALUE to standard units."
  (interactive "r")
  (message "%s" (units-command
		 (format "\"%s\"" value))))

(defun units-reduce-region (beg end)
  "Reduce the region (BEG to END) to standard units."
  (interactive "r")
  (message "%s" (units-reduce
		 (buffer-substring-no-properties beg end))))

(defun units-reduce-region-and-insert (beg end)
  "Reduce the region (BEG to END) to standard units and insert the results."
  (interactive "r")
  (goto-char end)
  (insert units-insert-separator
	  (units-reduce-region beg end)))

(defun units-convert-region-and-insert (region-text to-unit)
  "Convert REGION-TEXT to TO-UNIT and insert the results."
  (interactive (units-get-interactive-args))
  (goto-char (region-end))
  (insert units-insert-separator
	   (units-convert-region region-text to-unit)))

(defun units-read (value &optional convert-to)
  "Read the numeric value from VALUE optionally convert it to CONVERT-TO unit."
  (if convert-to
      (read (units-convert value convert-to))
    (if (string-match "\\([0-9.]+\\)" value)
	(read (match-string 1 value))
      (error "No values to read"))))

(defmacro units-ignore (value unit)
  "Read the numeric value from VALUE and ignore UNIT."
  (ignore unit)
  value)

(define-minor-mode units-mode
  "Minor mode for Calculations related to units.")

(provide 'units-mode)

;;; units-mode.el ends here
