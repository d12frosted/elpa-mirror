;;; caseformat.el --- Format based letter case converter  -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Hiroki YAMAKAWA

;; Author: Hiroki YAMAKAWA <s06139@gmail.com>
;; URL: https://github.com/HKey/caseformat
;; Package-Version: 20160115.1615
;; Package-Commit: 75ddb9c64eeb78b46d9e1db99bef8d0fb1e46b99
;; Version: 0.2.0
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
    (":" upcase)
    (t downcase))
  "A list which indicates how to convert alphabetical strings.
Each element is a list like (<prefix> <converter>).
<prefix> is a string which indicates the start of conversion.  <prefix> can
also be t (symbol).  It indicates that there is no prefix string in an
argument string of `caseformat-convert' and the corresponding function is
used to convert the argument string, not a separated alphabetical string.
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
  :type '(list (list (choice string (const t)) function))
  :group 'caseformat
  :package-version '(caseformat . "0.2.0"))

(defcustom caseformat-global-mode-selector nil
  "A function which selects whether `caseformat-mode' is enabled or not.
This is useful to disable `caseformat-mode' in specified buffers when
using `global-caseformat-mode'.
This function is called by `global-caseformat-mode' for each buffer and
run in the target buffer.
If the function returns non-nil or this variable is not a function,
`caseformat-mode' is enabled by `global-caseformat-mode'.

For example, if you want to disable `caseformat-mode' in the minibuffer,
please set this variable to:

  (lambda () (not (minibufferp)))"
  :type '(choice (function :tag "Selector function")
                 (const :tag "Enable always" nil))
  :group 'caseformat
  :package-version '(caseformat . "0.2.0"))

(defcustom caseformat-enable-repetition t
  "When this is non-nil, enable sequential-command like repetition.
When this value is non-nil and a same command of caseformat is called
repeatedly, the command does its action as sequential-command
like repetition.

Example (\"|\" is the cursor position):
  -foo-bar :hoge_:huga -baz|  ;; before calling of `caseformat-backward'
  -foo-bar :hoge_:huga Baz|   ;; after first calling of `caseformat-backward'
  -foo-bar HOGE_HUGA Baz|     ;; after second calling
  FooBar HOGE_HUGA Baz|       ;; after third calling"
  :type 'boolean
  :group 'caseformat
  :package-version '(caseformat . "0.2.0"))

(defvar caseformat-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "M-l") #'caseformat-backward)
    map)
  "A keymap for `caseformat-mode'.")

(defvar caseformat--resumption-marker nil
  "Resumption marker for sequential-command like repetition.")


(defun caseformat--split-1 (string table)
  "Split STRING into a list based on TABLE.
A utility function of `caseformat--split'."
  (-if-let* ((prefixes (-filter #'stringp (-map #'car table)))
             ((_ no-prefix prefix body other)
              (s-match
               (format "\\`\\(.*?\\)\\(%s\\)\\([A-Za-z]+\\)\\(.*\\)\\'"
                       (regexp-opt prefixes))
               string)))
      (append
       (-non-nil
        (list (and (s-present? no-prefix) (cons nil no-prefix))
              (cons prefix body)))
       (caseformat--split-1 other table))
    (list (cons nil string))))

(defun caseformat--split (string table)
  "Split STRING into a list based on TABLE.
STRING is a target string.
TABLE is a list like `caseformat-converter-table'.
Each element of the returned list is a cons cell like (<prefix> . <body>).
<prefix> is a prefix string of TABLE.
<body> is a string to be converted.

Example:
  (caseformat--split \"foo-bar:baz\" caseformat-converter-table)
  ;; => ((nil . \"foo\") (\"-\" . \"bar\") (\":\" . \"baz\"))

  (caseformat--split \"foobar\" caseformat-converter-table)
  ;; => ((t . \"foobar\"))"
  (let* ((result (caseformat--split-1 string table))
         (first (cl-first result)))
    (if (and (= (length result) 1)
             (null (car first)))
        ;; STRING has no prefix string
        `((t . ,(cdr first)))
      result)))

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


(defun caseformat--get-resumption-marker ()
  "Get the marker for command repetition."
  (setq caseformat--resumption-marker
        (or caseformat--resumption-marker
            (make-marker))))

(defun caseformat--set-resumption-marker (point)
  "Set the marker for command repetition to POINT."
  (set-marker (caseformat--get-resumption-marker) point))

(defun caseformat--repeat? ()
  "Return a marker to resume if current command can repeat."
  (let ((marker (caseformat--get-resumption-marker)))
    (and caseformat-enable-repetition
         (eq this-command last-command)
         (eq (current-buffer) (marker-buffer marker))
         marker)))

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
      ;; sequential-command like repetition
      (-when-let (marker (caseformat--repeat?))
        (goto-char marker))
      (save-match-data
        (while (and (<= 0 (cl-decf count)) (funcall searcher))
          (save-excursion
            (caseformat--set-resumption-marker (point))
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

(defun caseformat--turn-on-caseformat-mode ()
  "Turn on `caseformat-mode' if needed.
See also: `caseformat-global-mode-selector'"
  (when (or (not (functionp caseformat-global-mode-selector))
            (funcall caseformat-global-mode-selector))
    (caseformat-mode 1)))

;;;###autoload
(define-globalized-minor-mode global-caseformat-mode
  caseformat-mode
  caseformat--turn-on-caseformat-mode)

(provide 'caseformat)
;;; caseformat.el ends here
