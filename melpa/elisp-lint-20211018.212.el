;;; elisp-lint.el --- Basic linting for Emacs Lisp  -*- lexical-binding:t -*-
;;
;; Copyright (C) 2013-2015 Nikolaj Schumacher
;; Copyright (C) 2018-2020 Neil Okamoto
;;
;; Author: Nikolaj Schumacher <bugs * nschum de>,
;; Maintainer: Neil Okamoto <neil.okamoto+melpa@gmail.com>
;; Version: 0.5.0-SNAPSHOT
;; Package-Version: 20211018.212
;; Package-Commit: a5ae046c35a898a88eff05137fe9e5159ae610d8
;; Keywords: lisp, maint, tools
;; Package-Requires: ((emacs "24.4") (dash "2.15.0") (package-lint "0.11"))
;; URL: http://github.com/gonewest818/elisp-lint/
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; This is a tool for finding certain problems in Emacs Lisp files.  Use it on
;; the command line like this:
;;
;; $(EMACS) -Q --batch -l elisp-lint.el -f elisp-lint-files-batch *.el
;;
;; You can disable individual checks by passing flags on the command line:
;;
;; $(EMACS) -Q --batch -l elisp-lint.el -f elisp-lint-files-batch \
;;          --no-indent *.el
;;
;; Alternatively, you can disable checks using file variables or the following
;; .dir-locals.el file:
;;
;; ((emacs-lisp-mode . ((elisp-lint-ignored-validators . ("fill-column")))))
;;
;; For a full list of validators, see 'elisp-lint-file-validators' and
;; 'elisp-lint-buffer-validators'.
;;
;;; Change Log:
;;
;; * Version 0.5-SNAPSHOT (MELPA)
;;    - suppress "Package X is not installable" errors when running in
;;      a context where 'package-initialize' hasn't occurred
;; * Version 0.4 (MELPA Stable, March 2020)
;;    - Provide a summary report of all tests [#20]
;;    - Integrate 'package-lint' [#19]
;;    - Remove 'package-format', as 'package-lint' covers the same territory
;;    - Make byte-compile errors and warnings more robust
;;    - Make 'fill-column' checker ignore the package summary line [#25]
;;    - Make 'fill-column' checker ignore the package requires header
;;    - Add dependency on 'dash.el'
;;    - Colorized output
;; * Version 0.3 (December 2019)
;;    - Emacs 23 support is deprecated [#13]
;;    - Adopt CircleCI and drop Travis CI [#9] [#14]
;;    - Add 'check-declare' validator [#16]
;;    - Generate autoloads before byte-compile [#8]
;; * Version 0.2 (Feb 2018)
;;    - Project transferred to new maintainer
;;    - Whitespace check permits page-delimiter (^L)
;;    - Indentation check prints the diff to console
;;    - User can specify indent specs to tell the checker about macros
;;    - Added 'checkdoc' (available only Emacs 25 and newer)
;;    - Cleared up the console output for easier reading in CI
;;    - Expand Travis CI test matrix to include Emacs 25 and 26
;; * Version 0.1 (2015)
;;    - Basic linting functionality implemented
;;
;;; Code:

(require 'bytecomp)
(require 'check-declare)
(require 'checkdoc nil t)
(require 'package)
(require 'package-lint)
(require 'subr-x)
(require 'dash)

(defconst elisp-lint-file-validators
  '("byte-compile"
    "check-declare"))

(defconst elisp-lint-buffer-validators
  (append (when (fboundp 'checkdoc-current-buffer)
            '("checkdoc"))
          '("package-lint"
            "indent"
            "indent-character"
            "fill-column"
            "trailing-whitespace")))

(defvar elisp-lint-ignored-validators nil
  "List of validators that should not be run.")
(put 'elisp-lint-ignored-validators 'safe-local-variable 'listp)

(defvar elisp-lint-batch-files nil
  "List of files to be processed in batch execution.")

(defvar elisp-lint-indent-specs nil
  "Alist of symbols and their indent specifiers.
The property 'lisp-indent-function will be set accordingly on
each of the provided symbols prior to running the indentation
check.  Caller can set this variable as needed on the command
line or in \".dir-locals.el\".  The alist should take the form
`((symbol1 . spec1) (symbol2 . spec2) ...)' where the specs are
identical to the `indent' declarations in defmacro.")
(put 'elisp-lint-indent-specs 'safe-local-variable 'listp)

(defvar elisp-lint--debug nil
  "Toggle when debugging interactively for extra warnings, etc.")

(defmacro elisp-lint--protect (&rest body)
  "Handle errors raised in BODY."
  (declare (indent 0) (debug t))
  `(condition-case err
       (progn ,@body)
     (error (message "%s" (error-message-string err)) nil)))

(defmacro elisp-lint--run (validator &rest args)
  "Run the VALIDATOR with ARGS."
  `(unless (member ,validator elisp-lint-ignored-validators)
     (let ((v (elisp-lint--protect
                (funcall (intern (concat "elisp-lint--" ,validator)) ,@args))))
       (copy-tree v)))) ;; TODO: is deep copy necessary?

(defun elisp-lint--handle-argv ()
  "Parse command line and find flags to disable specific validators.
Push results to `elisp-lint-ignored-validators' and `elisp-lint-batch-files'."
  (dolist (option command-line-args-left)
    (cond ((string-match "^--no-\\([a-z-]*\\)" option)
           (add-to-list 'elisp-lint-ignored-validators
                        (substring-no-properties option 5)))
          (t (add-to-list 'elisp-lint-batch-files option))))
  (setq command-line-args-left nil))    ; empty this.  we've handled all.

;;; Validators

(defvar elisp-lint--autoloads-filename nil
  "The autoloads file for this package.")

(defun elisp-lint--generate-autoloads ()
  "Generate autoloads and set `elisp-lint--autoloads-filename'.
Assume `default-directory' name is also the package name,
e.g. for this package it will be \"elisp-lint-autoloads.el\"."
  (let* ((dir (directory-file-name default-directory))
         (prefix (file-name-nondirectory dir))
         (pkg (intern prefix))
         (load-prefer-newer t)
         (inhibit-message t))
    (package-generate-autoloads pkg dir)
    (setq elisp-lint--autoloads-filename (format "%s-autoloads.el" prefix))))

(defun elisp-lint--byte-compile (path-to-file)
  "Byte-compile PATH-TO-FILE with warnings enabled.
Return a list of errors, or nil if none found."
  (let ((comp-log "*Compile-Log*")
        (lines nil)
        (byte-compile-warnings t)
        (file (file-name-nondirectory path-to-file)))
    (unless elisp-lint--autoloads-filename
      (elisp-lint--generate-autoloads))
    (let ((inhibit-message t))
      (load-file elisp-lint--autoloads-filename))
    (when (get-buffer comp-log) (kill-buffer comp-log))
    (byte-compile-file path-to-file)
    ;; Using `get-buffer-create' to avoid a message if compilation hasn't
    ;; produced any warnings and thus created the buffer.
    (with-current-buffer (get-buffer-create comp-log)
      (goto-char (point-min))
      (while (not (eobp))
        (if (looking-at file)
            (let* ((end-pos (save-excursion ; continuation on next line?
                              (beginning-of-line 2)
                              (if (looking-at "    ") 2 1)))
                   (item (split-string
                          (buffer-substring-no-properties
                           (line-beginning-position)
                           (line-end-position end-pos))
                          ":")))
              (push (list (string-to-number (nth 1 item)) ; LINE
                          (string-to-number (nth 2 item)) ; COL
                          'byte-compile                   ; TYPE
                          (string-trim                    ; MSG
                           (mapconcat #'identity (cdddr item) ":")))
                    lines)))
        (beginning-of-line 2)))
    lines))

(defun elisp-lint--check-declare (file)
  "Validate `declare-function' statements in FILE."
  (let ((errlist (check-declare-file file)))
    (mapcar
     (lambda (item)
       ;; check-declare-file returns a list of items containing, from
       ;; left to right, the name of the library where 'declare-function'
       ;; said to find the definition, followed by a list of the filename
       ;; we are currently linting, the function name being looked up,
       ;; and the error returned by 'check-declare-file':
       ;;
       ;; ((".../path/to/library1.el.gz" ("foo.el" "func1" "err message"))
       ;;  (".../path/to/library2.el.gz" ("foo.el" "func2" "err message"))
       ;;  ...
       ;;  (".../path/to/libraryN.el.gz" ("foo.el" "funcN" "err message")))
       ;;
       ;; For now we don't get line numbers for warnings, but the
       ;; 'declare-function' lines are easy for the user to find.
       (list 0 0 'check-declare
             (format "(declare-function) %s: \"%s\" in file \"%s\""
                     (car (cddadr item))
                     (cadadr item)
                     (car item))))
     errlist)))

;; Checkdoc is available only Emacs 25 or newer
(when (fboundp 'checkdoc-current-buffer)
  (defun elisp-lint--checkdoc ()
    "Run checkdoc on the current buffer.
Parse warnings and return in a list, or nil if no errors found."
    (let ((style-buf "*Style Warnings*")
          (lines nil))
      (when (get-buffer style-buf) (kill-buffer style-buf))
      (checkdoc-current-buffer t)
      (with-current-buffer style-buf
        (goto-char (point-min))
        (beginning-of-line 5) ; skip empty lines and ^L
        (while (not (eobp))
          (let ((item (split-string
                       (buffer-substring-no-properties
                        (line-beginning-position) (line-end-position))
                       ":")))
            (push (list (string-to-number (nth 1 item))           ; LINE
                        0                                         ; COLUMN
                        'checkdoc                                 ; TYPE
                        (string-trim
                         (mapconcat #'identity (cddr item) ":"))) ; MSG
                  lines)
            (beginning-of-line 2))))
      lines)))

(defun elisp-lint--package-lint ()
  "Run package-lint on buffer and return results.
Result is a list of one item per line having an error, and each
entry contains: (LINE COLUMN TYPE MESSAGE)

Because package-lint uses the package library to validate when
dependencies can be installed, this function checks for when the
package library has NOT been initialized, and suppresses the
inevitable \"not installable\" errors in that case."
  (let ((err (-map
              (lambda (item)
                (-update-at 2
                            (lambda (s)
                              (make-symbol (concat "package-lint:"
                                                   (symbol-name s))))
                            item))
              (package-lint-buffer))))
    (if package-archive-contents        ; if package.el is initialized?
        err                             ; return the errors
      (-remove                          ; else remove "not installable"
       (lambda (item)
         (string-match "^Package [^ ]+ is not installable." (nth 3 item)))
       err))))

(defun elisp-lint--next-diff ()
  "Search via regexp for the next diff in the current buffer.
We expect this buffer to contain the output of \"diff -C 0\" and
that the point is advancing through the buffer as it is parsed.
Here we know each diff entry will be formatted like this if the
indentation problem occurs in an isolated line:

    ***************
    *** 195 ****
    !        (let ((tick (buffer-modified-tick)))
    --- 195 ----
    !   (let ((tick (buffer-modified-tick)))

or formatted like this if there is a series of lines:

    ***************
    *** 195,196 ****
    !        (let ((tick (buffer-modified-tick)))
    !  (indent-region (point-min) (point-max))
    --- 195,196 ----
    !   (let ((tick (buffer-modified-tick)))
    !     (indent-region (point-min) (point-max))

So we will search for the asterisks and line numbers.  Return a
list containing the range of line numbers for this next
diff.  Return nil if no more diffs found in the buffer."
  (when (re-search-forward
         "^\\*\\*\\* \\([0-9]+\\),*\\([0-9]*\\) \\*\\*\\*\\*$" nil t)
    (let* ((r1 (string-to-number (match-string-no-properties 1)))
           (r2 (match-string-no-properties 2))
           (r2 (if (equal r2 "") r1 (string-to-number r2))))
      (beginning-of-line 2)   ; leave point at start of next line
      (number-sequence r1 r2))))

(defun elisp-lint--indent ()
  "Confirm buffer indentation is consistent with `emacs-lisp-mode'.
Use `indent-region' to format the entire buffer, and compare the
results to the filesystem.  Return a list of diffs if there are
any discrepancies.  Prior to indenting the buffer, apply the
settings provided in `elisp-lint-indent-specs' to configure
specific symbols (typically macros) that require special
handling.  Result is a list of one item per line having an error,
and each entry contains: (LINE COLUMN TYPE MESSAGE)"
  (dolist (s elisp-lint-indent-specs)
    (put (car s) 'lisp-indent-function (cdr s)))
  (let ((tick (buffer-modified-tick))
        (errlist nil))
    (let ((inhibit-message t))
      (indent-region (point-min) (point-max)))
    (unless (equal tick (buffer-modified-tick))
      (let ((diff-switches "-C 0")) (diff-buffer-with-file))
      (revert-buffer t t)               ; revert indent changes
      (with-current-buffer "*Diff*"
        (goto-char (point-min))
        (while (not (eobp))
          (let ((line-range (elisp-lint--next-diff)))
            (if line-range
                (mapc (lambda (linenum) ; loop over the range and report
                        (push (list linenum 0 'indent
                                    (buffer-substring-no-properties
                                     (line-beginning-position)
                                     (line-end-position))) errlist)
                        (beginning-of-line 2)) ; next line
                      line-range)
              (goto-char (point-max)))))
        (kill-buffer)))
    errlist))

(defun elisp-lint--indent-character ()
  "Verify buffer indentation is consistent with `indent-tabs-mode'.
Use a file variable or \".dir-locals.el\" to override the default value."
  (let ((lines nil)
        (re (if indent-tabs-mode
                (elisp-lint--not-tab-regular-expression)
              "^\t"))
        (msg (if indent-tabs-mode
                 "spaces instead of tabs"
               "tabs instead of spaces")))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward re nil t)
        (push (list (count-lines (point-min) (point))
                    0 'indent-character msg) lines)))
    lines))

(defun elisp-lint--not-tab-regular-expression ()
  "Regex to match a string of spaces with a length of `tab-width'."
  (concat "^" (make-string tab-width ? )))

(defvar elisp-lint--package-summary-regexp
  "^;;; \\([^ ]*\\)\\.el ---[ \t]*\\(.*?\\)[ \t]*\\(-\\*-.*-\\*-[ \t]*\\)?$"
  "This regexp must match the definition in package.el.")

(defvar elisp-lint--package-requires-regexp
  "^;;[ \t]+Package-Requires:"
  "This regexp must match the definition in package.el.")

(defun elisp-lint--fill-column ()
  "Confirm buffer has no lines exceeding `fill-column' in length.
Use a file variable or \".dir-locals.el\" to override the default
value.

Certain lines in the file are excluded from this check, and can
have unlimited length:

* The package summary comment line, which by definition must
  include the package name, a summary description (up to 60
  characters), and an optional \"-*- lexical-binding:t -*-\"
  declaration.

* The \"Package-Requires\" header, whose length is determined by
  the number of dependencies specified."
  (save-excursion
    (let ((line-number 1)
          (too-long-lines nil))
      (goto-char (point-min))
      (while (not (eobp))
        (let ((text (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position))))
          (when
              (and (not (string-match elisp-lint--package-summary-regexp text))
                   (not (string-match elisp-lint--package-requires-regexp text))
                   (> (length text) fill-column))
            (push (list line-number 0 'fill-column
                        (format "line length %s exceeded" fill-column))
                  too-long-lines)))
        (setq line-number (1+ line-number))
        (forward-line 1))
      too-long-lines)))

(defun elisp-lint--trailing-whitespace ()
  "Confirm buffer has no line with trailing whitespace.
Allow `page-delimiter' if it is alone on a line."
  (save-excursion
    (let ((lines nil))
      (goto-char (point-min))
      (while (re-search-forward "[[:space:]]+$" nil t)
        (unless (string-match-p
                 (concat page-delimiter "$") ; allow a solo page-delimiter
                 (buffer-substring-no-properties (line-beginning-position)
                                                 (line-end-position)))
          (push (list (count-lines (point-min) (point)) 0
                      'whitespace "trailing whitespace found")
                lines)))
      lines)))

;;; Colorized output

;; Derived from similar functionality in buttercup.el
;; whose implementation is also licensed under the GPL:
;; https://github.com/jorgenschaefer/emacs-buttercup/

(defconst elisp-lint--ansi-colors
  '((black   . 30)
    (red     . 31)
    (green   . 32)
    (yellow  . 33)
    (blue    . 34)
    (magenta . 35)
    (cyan    . 36)
    (white   . 37))
  "ANSI color escape codes.")

(defconst elisp-lint--no-color
  (let ((term (getenv-internal "TERM"))
        (no-color (getenv-internal "NO_COLOR")))
    (or (and (stringp term) (string= term "dumb"))
        (and (stringp no-color) (> (length no-color) 0))))
  "Disable colored text via the environment: NO_COLOR non-empty OR TERM=dumb.")

(defun elisp-lint--print (color fmt &rest args)
  "Print output text in COLOR, formatted according to FMT and ARGS."
  (if elisp-lint--no-color
      (progn
        (princ (apply #'format fmt args))
        (terpri))
    (let ((ansi-val (cdr (assoc color elisp-lint--ansi-colors)))
          (cfmt (concat "\u001b[%sm" fmt  "\u001b[0m")))
      (princ (apply #'format cfmt ansi-val args))
      (terpri))))

;;; Linting

(defun elisp-lint-file (file)
  "Run validators on FILE."
  (with-temp-buffer
    (find-file file)
    (let ((warnings (-concat (-mapcat (lambda (validator)
                                        (elisp-lint--run validator file))
                                      elisp-lint-file-validators)
                             (-mapcat (lambda (validator)
                                        (elisp-lint--run validator))
                                      elisp-lint-buffer-validators))))
      (mapc (lambda (w)
              ;; TODO: with two passes we could exactly calculate the number of
              ;; spaces to indent after the filenames and line numbers.
              (elisp-lint--print 'cyan "%-32s %s"
                                 (format "%s:%d:%d (%s)"
                                         file (nth 0 w) (nth 1 w) (nth 2 w))
                                 (nth 3 w)))
            (sort warnings (lambda (x y) (< (car x) (car y)))))
      (not warnings))))

(defun elisp-lint-files-batch ()
  "Run validators on all files specified on the command line."
  (elisp-lint--handle-argv)
  (when elisp-lint--debug
    (elisp-lint--print 'cyan "files: %s"
                       elisp-lint-batch-files)
    (elisp-lint--print 'cyan "ignored: %s"
                       elisp-lint-ignored-validators)
    (elisp-lint--print 'cyan "file validators: %s"
                       elisp-lint-file-validators)
    (elisp-lint--print 'cyan "buffer validators: %s"
                       elisp-lint-buffer-validators))
  (let ((success t))
    (dolist (file elisp-lint-batch-files)
      (if (elisp-lint-file file)
          (elisp-lint--print 'green "%s OK" file)
        (elisp-lint--print 'red "%s FAIL" file)
        (setq success nil)))
    (unless elisp-lint--debug (kill-emacs (if success 0 1)))))

;; ELISP>
;; (let ((command-line-args-left '("--no-byte-compile"
;;                                 "--no-package-format"
;;                                 "--no-checkdoc"
;;                                 "--no-check-declare"
;;                                 "example.el")))
;;   (setq elisp-lint-ignored-validators nil
;;         elisp-lint-file-validators nil
;;         elisp-lint-buffer-validators nil
;;         elisp-lint-batch-files nil)
;;   (elisp-lint-files-batch))

(provide 'elisp-lint)

;;; elisp-lint.el ends here
