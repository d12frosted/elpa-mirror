;;; caseformat.el --- Format based letter case converter  -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Hiroki YAMAKAWA

;; Author: Hiroki YAMAKAWA <s06139@gmail.com>
;; URL: https://github.com/HKey/caseformat
;; Package-Version: 20160102.1230
;; Package-Commit: 72707c9f0f0819b4e2aa45876432a293aa07f814
;; Version: 0.1.0
;; Package-Requires: ((emacs "24") (cl-lib "0.5") (dash "2.12.1") (s "1.10.0"))
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

;; This tool helps you to insert uppercase alphabetical characters without
;; shift keys.

;; Please see https://github.com/HKey/caseformat/blob/master/README.md for
;; more details.

;;; Code:

(require 'cl-lib)
(require 'dash)
(require 's)


(defgroup caseformat nil
  "Format based letter case converter"
  :group 'convenience
  :prefix "caseformat-")

(defcustom caseformat-converter-table
  '(("-" capitalize)
    (":" upcase))
  "A list which indicates how to convert alphabetical strings.
Each element is a list like (<prefix> <converter>).
<prefix> is a string which indicates the start of conversion.
<converter> is a function used to convert an alphabetical string.  It should
have a parameter and return a converted string like `capitalize'.

         -------------- prefixes
         |    |
         v    v
    camel-case-string
    ~~~~~ ~~~~~ ~~~~
      ^     ^     ^
      |     |     |
      |     ----------- target strings
      |                 (to be converted by `capitalize' by default)
 not converted"
  :type '(list (list string function)))

(defvar caseformat-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "M-l") #'caseformat-backward)
    map)
  "A keymap for `caseformat-mode'.")


(defun caseformat--split (string table)
  "Split STRING into a list based on TABLE.
STRING is a target string.
TABLE is a list like `caseformat-converter-table'.
Each element of the returned list is a cons cell like (<prefix> . <body>).
<prefix> is a prefix string of TABLE.
<body> is a string to be converted.

Example:
  (caseformat--split \"foo-bar:baz\" caseformat-converter-table)
  ;; => ((nil . \"foo\") (\"-\" . \"bar\") (\":\" . \"baz\"))"
  (let ((prefixes (-map #'car table)))
    (-if-let ((_ no-prefix prefix body other)
              (s-match
               (format "\\`\\(.*?\\)\\(%s\\)\\([A-Za-z]+\\)\\(.*\\)\\'"
                       (regexp-opt prefixes))
               string))
        (append
         (-non-nil
          (list (and (s-present? no-prefix) (cons nil no-prefix))
                (cons prefix body)))
         (caseformat--split other table))
      (list (cons nil string)))))

(defun caseformat--convert (string prefix table)
  "Convert STRING with PREFIX based on TABLE.
Return a converted string."
  (-if-let ((_ converter) (cl-assoc prefix table :test #'equal))
      (funcall converter string)
    string))

;;;###autoload
(cl-defun caseformat-convert (string
                              &optional (table caseformat-converter-table))
  "Convert STRING based on TABLE.
TABLE is a list like `caseformat-converter-table'.

Example:
  (caseformat-convert \"-foo:bar\")
  ;; => \"FooBAR\""
  (->> (caseformat--split string table)
       (--map (-let (((prefix . body) it))
                (caseformat--convert body prefix table)))
       (apply #'concat)))


(defun caseformat--do-convert (n)
  "Convert N chunks of non-whitespace characters from point.
When N is negative, convert characters backward."
  (let ((searcher (if (cl-plusp n)
                      (lambda ()
                        (re-search-forward "[ \n\t]*\\([^ \n\t]+\\)" nil t))
                    (lambda ()
                      (re-search-backward "\\(?:[ \n\t]\\|\\`\\)\\([^ \n\t]+\\)" nil t))))
        (count (abs n))
        (point (point-marker)))
    (save-excursion
      (save-match-data
        (while (and (<= 0 (cl-decf count)) (funcall searcher))
          (save-excursion
            (goto-char point)        ; to remember the cursor position
            (replace-match (caseformat-convert (match-string 1)) t nil nil 1)))))))

;;;###autoload
(defun caseformat-forward (&optional arg)
  "Convert non-whitespace characters from point.
If ARG is a number, this converts ARG chunks of characters.
This command does not move the cursor position."
  (interactive "p")
  (caseformat--do-convert (or arg 1)))

;;;###autoload
(defun caseformat-backward (&optional arg)
  "Convert non-whitespace characters backward from point.
If ARG is a number, this converts ARG chunks of characters.
This command does not move the cursor position."
  (interactive "p")
  (caseformat--do-convert (- (or arg 1))))


;;;###autoload
(define-minor-mode caseformat-mode
  "A minor-mode to manage caseformat commands."
  :group 'caseformat
  :keymap caseformat-mode-map)

;;;###autoload
(define-globalized-minor-mode global-caseformat-mode
  caseformat-mode
  (lambda () (caseformat-mode 1)))

(provide 'caseformat)
;;; caseformat.el ends here
