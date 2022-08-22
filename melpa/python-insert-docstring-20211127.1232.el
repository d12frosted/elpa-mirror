;;; python-insert-docstring.el --- Python Google docstring inserter -*- lexical-binding: t; -*-

;; Copyright (c) 2021 Marco Vocialta

;; Author: Marco Vocialta <macurovc@tutanota.com>
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/macurovc/insert-docstring
;; Version: 1.1

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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package can automatically generate function docstrings in Python
;; according to the Google style guide available at this URL:

;; https://google.github.io/styleguide/pyguide.html#383-functions-and-methods

;; The text gets automatically indented and split on multiple lines.

;; In order to use this package, you can set a custom keybinding in your
;; ~/.emacs file such as:

;; (defun set-python-keybindings ()
;;   (local-set-key (kbd "C-c i") 'python-insert-docstring-with-google-style-at-point)
;;   )
;; (add-hook 'python-mode-hook 'set-python-keybindings)

;; Now, in a python file, place the cursor on a function, type `C-c i` and
;; follow the instructions.

;;; Code:

(require 'cl-lib)

(defgroup python-insert-docstring nil "Insert Docstring custom variables"
  :group 'convenience)

(defcustom python-insert-docstring-tab-width (if (boundp 'python-tab-width)
                                                 python-tab-width
                                               4)
  "Tabulation width in Python files."
  :group 'python-insert-docstring
  :type 'integer)

(defcustom python-insert-docstring-default-indentation (make-string python-insert-docstring-tab-width
                                                                    ?\s)
  "Python indentation string."
  :group 'python-insert-docstring
  :type 'string)

(defcustom python-insert-docstring-function-indentation-regex (rx line-start
                                                                  (group (* blank))
                                                                  "def"
                                                                  (or blank "\n"))
  "Regex to find the indentation of a function."
  :group 'python-insert-docstring
  :type 'string)

(defcustom python-insert-docstring-function-name-regex (rx "def"
                                                           (+ (or blank "\n"))
                                                           (group (+ (not whitespace)))
                                                           (* (or blank "\n"))
                                                           "(")
  "Regex to find the name of a function."
  :group 'python-insert-docstring
  :type 'string)

(defcustom python-insert-docstring-function-arguments-regex (rx "("
                                                                (group (* (not (any "(" ")"))))
                                                                ")")
  "Regex to find the string of arguments of a function."
  :group 'python-insert-docstring
  :type 'string)

(defcustom python-insert-docstring-function-end-regex (rx ")"
                                                          (* (not (any ":")))
                                                          ":")
  "Regex to find the end of a function."
  :group 'python-insert-docstring
  :type 'string)

(defcustom python-insert-docstring-blank-or-newline-regex (rx (+ (or blank "\n")))
  "Regex to find blanks and newlines (used for trimming)."
  :group 'python-insert-docstring
  :type 'string)


(cl-defstruct python-insert-docstring--argument-data
  "Data associated to a function argument."
  name description)

(cl-defstruct python-insert-docstring--function-data
  "Data associated to a function." indentation-string
  short-description long-description arguments
  return)


;;;###autoload
(defun python-insert-docstring-with-google-style-at-point ()
  "Insert a Google docstring for the Python function at point."
  (interactive)
  (let* ((function-data (python-insert-docstring--function-data-at-point))
         (google-docstring (python-insert-docstring--google-docstring
                            function-data)))
    (python-insert-docstring--insert-docstring-with-indentation
     google-docstring)))


(defun python-insert-docstring--function-data-at-point ()
  "Return a function-data struct with the data of the function at point."
  (let ((indentation-string (python-insert-docstring--match-string-for-function-at-point
                             python-insert-docstring-function-indentation-regex))
        (function-name (python-insert-docstring--match-string-for-function-at-point
                        python-insert-docstring-function-name-regex))
        (arguments-string (python-insert-docstring--match-string-for-function-at-point
                           python-insert-docstring-function-arguments-regex)))
    (python-insert-docstring--make-function-data indentation-string
                                                 function-name
                                                 (python-insert-docstring--get-arguments-names-from-string
                                                  arguments-string))))


(defun python-insert-docstring--match-string-for-function-at-point (regex)
  "Match REGEX for the python function at point and return its first group."
  (save-excursion
    (end-of-line)
    (re-search-backward python-insert-docstring-function-indentation-regex)
    (re-search-forward regex)
    (match-string 1)))


(defun python-insert-docstring--get-arguments-names-from-string (arguments-string)
  "Parse the argument names and return them in a list.
Argument ARGUMENTS-STRING string containing the arguments."
  (if (string-equal "" arguments-string)
      nil
    (let ((arguments (mapcar (lambda (string)
                               "Remove default value if any and trim"
                               (car (split-string string "=" t python-insert-docstring-blank-or-newline-regex)))
                             (cl-remove-if (lambda (string)
                                             "Match type data leftovers"
                                             (string-match-p (rx (or "[" "]"))
                                                             string))
                                           (mapcar (lambda (single-argument-string)
                                                     "Drop type data"
                                                     (car (split-string single-argument-string ":")))
                                                   (split-string arguments-string ","))))))
      (if (member (car arguments) '("self" "cls"))
          (cdr arguments)
        arguments))))


(defun python-insert-docstring--make-function-data (indentation-string function-name argument-names)
  "Create a function-data struct.
Argument INDENTATION-STRING indentation of the function.
Argument FUNCTION-NAME name of the function.
Argument ARGUMENT-NAMES names of the function arguments."
  (make-python-insert-docstring--function-data :indentation-string indentation-string
                                               :short-description (python-insert-docstring--get-short-description-from-user
                                                                   function-name):long-description
                                               (python-insert-docstring--get-long-description-from-user
                                                function-name)
                                               :arguments (python-insert-docstring--make-arguments-data
                                                           argument-names):return
                                               (python-insert-docstring--get-return-description-from-user)))


(defun python-insert-docstring--make-argument-data (argument-name)
  "Generate an arguments-data struct.
The user is asked to input the argument description.
Argument ARGUMENT-NAME name of the argument."
  (make-python-insert-docstring--argument-data :name argument-name
                                               :description (read-string (format "Enter the description for argument '%s': "
                                                                                 argument-name))))

(defun python-insert-docstring--make-arguments-data (argument-names)
  "Generate an arguments-data struct for each argument in ARGUMENT-NAMES.
The user is asked for the description of each argument."
  (mapcar #'python-insert-docstring--make-argument-data
          argument-names))


(defun python-insert-docstring--get-short-description-from-user (function-name)
  "Ask the user for the short description of the function.
Argument FUNCTION-NAME name of the function."
  (read-string (format "Enter the short description for the function '%s': "
                       function-name)))


(defun python-insert-docstring--get-long-description-from-user (function-name)
  "Ask the user for the long description of the function.
Argument FUNCTION-NAME name of the function."
  (let ((description (read-string (format "Enter the long description for the function '%s' (leave empty to omit it): "
                                          function-name))))
    (if (string-equal description "")
        nil
      description)))


(defun python-insert-docstring--get-return-description-from-user ()
  "Ask the user of the description of the returned data."
  (let ((description (read-string "Enter the return description (leave empty to omit it): ")))
    (if (string-equal description "")
        nil
      description)))


(defun python-insert-docstring--prefix-lines (lines prefix)
  "Prepend each string in the LINES list with the PREFIX string.
The result is a list of strings.
If a string is empty, PREFIX doesn't get prepended."
  (mapcar (lambda (line)
            (if (string-equal "" line)
                line
              (concat prefix line)))
          lines))


(defun python-insert-docstring--insert-docstring-with-indentation (docstring-lines)
  "Insert the DOCSTRING-LINES in the buffer."
  (save-excursion
    (end-of-line)
    (re-search-backward python-insert-docstring-function-indentation-regex)
    (re-search-forward python-insert-docstring-function-end-regex)
    (insert "\n")
    (insert (mapconcat #'identity docstring-lines "\n"))))


(defun python-insert-docstring--google-docstring (function-data)
  "Return the Google docstring lines corresponding to FUNCTION-DATA."
  (let ((docstring-indentation (concat (python-insert-docstring--function-data-indentation-string
                                        function-data)
                                       python-insert-docstring-default-indentation))
        (short-description (python-insert-docstring--function-data-short-description
                            function-data))
        (long-description (python-insert-docstring--function-data-long-description
                           function-data))
        (arguments (python-insert-docstring--function-data-arguments
                    function-data))
        (return (python-insert-docstring--function-data-return
                 function-data)))
    (nconc (python-insert-docstring--line-to-indented-paragraph (format "\"\"\"%s" short-description)
                                                                docstring-indentation)
           (python-insert-docstring--google-docstring-long-description
            long-description docstring-indentation)
           (python-insert-docstring--google-docstring-arguments
            arguments docstring-indentation)
           (python-insert-docstring--google-docstring-returns
            return docstring-indentation)
           (python-insert-docstring--prefix-lines '("\"\"\"")
                                                  docstring-indentation))))


(defun python-insert-docstring--google-docstring-long-description (long-description docstring-indentation)
  "Return the LONG-DESCRIPTION with the given DOCSTRING-INDENTATION."
  (if long-description
      (nconc (list "")
             (python-insert-docstring--line-to-indented-paragraph
              long-description docstring-indentation))))


(defun python-insert-docstring--google-docstring-arguments (arguments docstring-indentation)
  "Return the Args docstring lines.
Argument ARGUMENTS list of arguments.
Argument DOCSTRING-INDENTATION indentation string."
  (let ((argument-indentation (concat docstring-indentation python-insert-docstring-default-indentation)))
    (nconc (if arguments
               (nconc (list "")
                      (python-insert-docstring--prefix-lines '("Args:")
                                                             docstring-indentation)))
           (python-insert-docstring--google-docstring-arguments-list
            arguments argument-indentation))))


(defun python-insert-docstring--google-docstring-argument-description (argument-data arguments-docstring-indentation)
  "Generate a docstring paragraph with the description of an argument.
Argument ARGUMENT-DATA struct with the argument data.
Argument ARGUMENTS-DOCSTRING-INDENTATION intentation of the argument paragraph."
  (let ((name (python-insert-docstring--argument-data-name
               argument-data))
        (description (python-insert-docstring--argument-data-description
                      argument-data)))
    (python-insert-docstring--line-to-indented-paragraph (format "%s: %s" name description)
                                                         arguments-docstring-indentation
                                                         python-insert-docstring-default-indentation)))


(defun python-insert-docstring--google-docstring-arguments-list (arguments arguments-docstring-indentation)
  "Return the lines where every argument is described.
Argument ARGUMENTS list of arguments.
Argument ARGUMENTS-DOCSTRING-INDENTATION indentation for the arguments lines."
  (cl-reduce #'nconc
             (mapcar (lambda (argument)
                       (python-insert-docstring--google-docstring-argument-description
                        argument arguments-docstring-indentation))
                     arguments)))


(defun python-insert-docstring--google-docstring-returns (return-description docstring-indentation)
  "Return the RETURN-DESCRIPTION with the given DOCSTRING-INDENTATION."
  (if return-description
      (nconc (list "")
             (python-insert-docstring--prefix-lines '("Returns:")
                                                    docstring-indentation)
             (python-insert-docstring--line-to-indented-paragraph return-description
                                                                  (concat python-insert-docstring-default-indentation
                                                                          docstring-indentation)))))


(defun python-insert-docstring--line-to-indented-paragraph (line indentation &optional new-line-prefix
                                                                 column-width)
  "Split a LINE into multiple ones to form a paragraph column.
Argument INDENTATION indentation prefixed to each paragraph row.
Optional argument NEW-LINE-PREFIX prefix string for new lines.
Optional argument COLUMN-WIDTH maximum lenght of a line."
  (let ((max-length (- (or column-width
                           (python-insert-docstring--get-fill-column))
                       (python-insert-docstring--indentation-length
                        indentation))))
    (python-insert-docstring--prefix-lines (python-insert-docstring--append-words-to-paragraph ()
                                                                                               max-length
                                                                                               (split-string line)
                                                                                               new-line-prefix)
                                           indentation)))


(defun python-insert-docstring--get-fill-column ()
  "Return the fill column value."
  (if (boundp 'python-insert-docstring--fill-column)
      python-insert-docstring--fill-column
    (if (boundp 'python-fill-column)
        python-fill-column
      fill-column)))


(defun python-insert-docstring--indentation-length (indentation-string &optional num-tab-chars)
  "Compute the number of character in INDENTATION-STRING.
Tabs count according to their width.
Optional argument NUM-TAB-CHARS spaces in a tabulation (default: `tab-width')."
  (cl-reduce #'+
             (mapcar (lambda (char)
                       (if (char-equal char ?\t)
                           (or num-tab-chars tab-width)
                         1))
                     indentation-string)))


(defun python-insert-docstring--append-words-to-paragraph (lines max-line-width words &optional new-line-prefix)
  "Append the WORDS to the strings in LINES.
A new line is appended whenever MAX-LINE-WIDTH is reached. New lines can be
optionally prefixed with NEW-LINE-PREFIX."
  (if words
      (python-insert-docstring--append-words-to-paragraph (let ((next-word (car words))
                                                                (next-line (car (last lines))))
                                                            (if next-line
                                                                (if (<= (+ (length next-line)
                                                                           (length next-word)
                                                                           1) max-line-width)
                                                                    (nconc (nbutlast lines)
                                                                           (list (concat next-line " " next-word)))
                                                                  (nconc lines
                                                                         (list (concat new-line-prefix next-word))))
                                                              (list next-word)))
                                                          max-line-width
                                                          (cdr words)
                                                          new-line-prefix)
    lines))

;; End:

(provide 'python-insert-docstring)

;;; python-insert-docstring.el ends here
