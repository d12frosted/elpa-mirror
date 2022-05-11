;;; pcmpl-args.el --- Enhanced shell command completion    -*- lexical-binding: t -*-

;; Copyright (C) 2012  Jonathan Waltman

;; Author: Jonathan Waltman <jonathan.waltman@gmail.com>
;; URL: https://github.com/JonWaltman/pcmpl-args.el
;; Package-Version: 20220510.2056
;; Package-Commit: 43229e1096f89c277190f09a3d794781f8fa0015
;; Keywords: abbrev completion convenience processes terminals unix
;; Created: 25 Jul 2012
;; Version: 0.1.3
;; Package-Requires: ((emacs "25.1"))

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package extends option and argument completion of shell
;; commands read by Emacs.  It is intended to make shell completion in
;; Emacs comparable to the rather excellent completion provided by
;; both Bash and Zsh.
;;
;; This package uses `pcomplete' to define completion handlers which
;; are used whenever shell completion is performed.  This includes
;; when commands are read in the minibuffer via `shell-command' (M-!)
;; or in `shell-mode'.
;;
;; Completion support is provided for many different commands
;; including:
;;
;;   - GNU core utilities (ls, rm, mv, date, sort, cut, printf, ...)
;;
;;   - Built-in shell commands (if, test, time, ...)
;;
;;   - Various GNU/Linux commands (find, xargs, grep, man, tar, ...)
;;
;;   - Version control systems (bzr, git, hg, ...)
;;

;; Installation:
;;
;; To use this package, save `pcmpl-args.el' to your `load-path' and
;; add the following to your `init.el':
;;
;;     (require 'pcmpl-args)
;;
;; Note: This package uses `lexical-binding' so it probably will not
;; work with older versions of Emacs (prior to 24.1).
;;
;; Note: This package redefines the following functions:
;;
;;   `pcomplete/bzip2'
;;   `pcomplete/chgrp'
;;   `pcomplete/chown'
;;   `pcomplete/gdb'
;;   `pcomplete/gzip'
;;   `pcomplete/make'
;;   `pcomplete/rm'
;;   `pcomplete/rmdir'
;;   `pcomplete/tar'
;;   `pcomplete/time'
;;   `pcomplete/which'
;;   `pcomplete/xargs'
;;

;; Defining new completion commands:
;;
;; This package contains a number of utilities for defining new
;; pcomplete completion commands:
;;
;; `pcmpl-args-pcomplete'
;;      Can be used to define completion for commands that have
;;      complex option and argument parsing.
;;
;; `pcmpl-args-pcomplete-on-help'
;;      Completion via parsing the output of `COMMAND --help'.
;;
;; `pcmpl-args-pcomplete-on-man'
;;      Completion via parsing the output of `man COMMAND'.
;;

;;; Code:

(eval-when-compile (require 'subr-x))
(require 'cl-lib)
(require 'pcomplete)
(require 'pcmpl-unix)
(require 'pcmpl-linux)

(defgroup pcmpl-args nil
  "Refined argument completion for use with pcomplete."
  :group 'pcomplete)

(defcustom pcmpl-args-debug nil
  "Non-nil means to print debugging info to *pcmpl-args-debug*.
See also `pcmpl-args-debug-parse-help'."
  :type 'boolean)

(defcustom pcmpl-args-debug-parse-help nil
  "Non-nil to highlight matches when parsing help buffers.
See `pcmpl-args-parse-help-buffer'."
  :type 'boolean)

(defcustom pcmpl-args-cache-default-duration 10.0
  "Default number of seconds to cache completions.
Does not apply to some completions that are cached for longer
periods of time.  See `pcmpl-args-cache-max-duration'."
  :type 'float)

(defcustom pcmpl-args-cache-max-duration 100.0
  "Maximum number of seconds to cache completions."
  :type 'float)

(defcustom pcmpl-args-annotation-style 'long
  "Control how completions are annotated.

nil
    No annotations.

`long'
    Full descriptions (if available).

`short'
    Limited descriptions (if available)."
  :type '(choice (const nil)
                 (const long)
                 (const short)))



;;; Utility functions

(defun pcmpl-args-debug (format &rest args)
  "Log debugging info to *pcmpl-args-debug* buffer.
FORMAT and ARGS are the same as for `message'.  Logging is only
performed if variable `pcmpl-args-debug' is non-nil."
  (when pcmpl-args-debug
    (with-current-buffer (get-buffer-create "*pcmpl-args-debug*")
      (goto-char (point-max))
      (insert (apply #'format (cons format args))
              "\n"))))

(defun pcmpl-args-strip (string)
  "Strip STRING of any leading or following whitespace."
  (save-match-data
    (replace-regexp-in-string "\\`[ \t\n\r\v]+\\|[ \t\n\r\v]+\\'"
                              "" string)))

(defun pcmpl-args-pad-or-truncate-string (string width)
  "Pad STRING with spaces to make it WIDTH characters long."
  (cond ((= (length string) width)
         string)
        ((< (length string) width)
         (concat string (make-string (- width (length string)) ?\s)))
        (t
         (substring string 0 width))))

(defun pcmpl-args-partition-string (regexp string)
  "Split a STRING on the first occurrence of REGEXP.
Returns a list containing the substring before the match, the
matching substring, and substring after the match."
  (when (string-match regexp string)
    (list (substring string 0 (match-beginning 0))
          (substring string (match-beginning 0) (match-end 0))
          (substring string (match-end 0)))))

(defun pcmpl-args-process-file (program &rest args)
  "Call PROGRAM with ARGS using `process-file' and insert the output.
If the exit status is non-zero, an error is signaled."
  (pcmpl-args-debug "!pcmpl-args-process-file: %S" (cons program args))
  (let* ((retcode (apply #'process-file program nil t nil args)))
    (when (not (equal 0 retcode))
      (let ((pcmpl-args-debug t))
        (pcmpl-args-debug
         "Error: %s"
         (if (equal (pcmpl-args-strip (buffer-string)) "")
             (format "Shell command failed with code %S" retcode)
           (pcmpl-args-strip (buffer-string))))))
    retcode))

(defun pcmpl-args-process-lines (program &rest args)
  "PROGRAM and ARGS are the same as `process-lines'.
Logging is enabled if variable `pcmpl-args-debug' is NON NIL."
  (pcmpl-args-debug "!process-lines: %S %S" program args)
  (apply #'process-lines program args))

(defun pcmpl-args-unbackspace-string (string)
  "Remove ^H characters from STRING."
  (replace-regexp-in-string ".\b" "" string))

(defun pcmpl-args-unbackspace-argspecs (argspecs)
  "Remove ^H characters from ARGSPECS."
  (mapcar
   (lambda (option)
     (dolist (key '(:help option) option)
       (let ((string (plist-get option key)))
         (when string
           (let ((new-string (pcmpl-args-unbackspace-string string)))
             (setq option (plist-put option key new-string)))))))
   argspecs))


;;; Option extraction from help text

(defvar pcmpl-args-guess-completions-hints
  '((".*=\\(file\\|FILE\\|f\\|F\\)\\'" (:eval (pcomplete-entries)))
    (".*=\\(dir\\|DIR\\|directory\\|DIRECTORY\\)\\'" (:eval (pcomplete-dirs)))
    (".*=\\(user\\|USER\\|username\\|USERNAME\\|uname\\|UNAME\\)\\'"
     (:eval (pcmpl-unix-user-names)))
    (".*=\\(group\\|groupname\\|gname\\|GROUP\\|GROUPNAME\\|GNAME\\)\\'"
     (:eval (pcmpl-unix-group-names)))
    ("" (:eval (pcomplete-entries))))
  "List of elements used by `pcmpl-args-guess-completions'.")

(defun pcmpl-args-guess-completions (optname optarg)
  "Infer a completion-table to use based on OPTNAME and OPTARG.
OPTNAME is the name of the option or argument and OPTARG is a
string describing the type of the option or argument.

If OPTARG is one of the following forms:

    {STRING-1|STRING-2|STRING-3...}
    {STRING-1,STRING-2,STRING-3...}

It returns a list of strings split on `,' or `|'.

Otherwise it searches `pcmpl-args-guess-completions-hints' and
uses the completion-table specified by the first matching
element.  Each element of this list is of the form:

`(STRING FORM)'
    STRING is a regexp to match against a string created
    by concatenating OPTNAME, \"=\", and a copy of OPTARG
    stripped of any surrounding brackets.
    During the match, `case-fold-search' is temporarily bound to
    nil.  If it is successful, FORM is returned.

`FUNCTION'
    FUNCTION is a function to call with two arguments, OPTNAME
    and OPTARG.  If it returns a non-nil value, this value is
    returned."
  (cond ((null optarg) nil)
        ((not (atom optarg))
         (error (not 'here)))
        ((string-match "\\`[ \t]*{\\(.+\\)}" optarg)
         (or (split-string (match-string 1 optarg) "[ \t|,]" t)
             '("BAD-BRACE")))
        (t
         (when (string-match "\\`[[< ]*\\(.*?\\)[]> ]*\\'" optarg)
           (setq optarg (match-string 1 optarg)))
         (let ((opt=arg (format "%s=%s" optname optarg)))
           (cl-dolist (hint pcmpl-args-guess-completions-hints)
             (cond ((stringp (car-safe hint))
                    (when (let (case-fold-search)
                            (string-match (car hint) opt=arg))
                      (cl-return (cadr hint))))
                   ((functionp hint)
                    (let ((result (funcall hint optname optarg)))
                      (when result
                        (cl-return result))))
                   (t
                    (error
                     "Invalid value in `pcmpl-args-guess-completions-hints': %S" hint))))))))

(defun pcmpl-args-make-argspecs (specs &rest keyword-args)
  "Create a list of \"argspecs\" that specify how to complete arguments.

SPECS should be a list of the form:

    ((TYPE NAME [[ACTIONS] [PROPERTIES ...]]) ...)

TYPE is a symbol and should be either `argument' or `option'.

If the TYPE is `argument' then NAME is either an integer
specifying the nth positional argument or the symbol `*' which
specifies any number of arguments.

If the TYPE is `option' then NAME is a string or a list of
strings specifying the name, style, and possibly the
sub-arguments of the option.  The following forms are supported:

    \"--option\"            - Option with no arguments.
    \"--option ARG\"        - Option one argument.
    \"--option ARG ARG\"    - Option with two arguments.
    \"--option[ARG]\"       - Option with one optional argument.
    \"--option<ARG>\"       - Option with one required argument.
    \"--option=ARG\"        - Option with one argument that is either
                              seperate or inline delimited by \"=\".
    \"--option[=ARG]\"      - Option with one optional argument that
                              is either seperate or inline delimited
                              by \"=\".

These forms work for both long-named options (those beginning
with \"--\") and single-letter options.

Multiple options can be specified in the same NAME by delimiting
them with commas.  For example:

    \"-o, --option\"        - Two options that both have no arguments.
    \"-o, --option ARG\"    - Two options that both have one argument.
                              same as \"-o ARG, -option ARG\"
    \"-o, --option[=ARG]\"  - Two options with one optional argument;
                              same as \"-o[ARG], -option[=ARG]\"
    \"-o, --option=ARG\"    - Two options with one argument;
                              same as \"-o ARG, -option=ARG\"

A description can also be specified in NAME by delimiting it with
multiple spaces or a tab character.  For example:

    \"--option  This option does ...\"


ACTIONS specify arguments and completions. It should be a list of
the form:

      ((METAVAR COMPLETIONS [SUFFIX]) ...)

  METAVAR is a string indicating the argument's type.

  COMPLETIONS is either a completion-table or one of the
  following forms:

  `(:eval FORM)'
      FORM is evaluated to produce a completion-table when
      completion is performed.  The variable `pcomplete-stub'
      will contain the string being completed.

  `(:lambda FUNCTION)'
      FUNCTION is called when completion is performed and it
      should return a completion-table.  The function is called
      with one argument, an alist of the options and arguments.

  t
      The symbol t means to use the completion-table returned
      by `pcmpl-args-guess-completions'.

  `none'
      The symbol `none' means that no completions can be
      generated and prevents the fallback behaviour of completing
      file names.

  SUFFIX is optional and it specifies a string to insert after
  completion is performed.

PROPERTIES are optional and consists of keywords followed by a
value.  The following are recognized:

:help
    String describing the option.

:excludes
    List of option and argument names that will not be completed
    after this point.  Also, the symbol `-' excludes options and
    `:' excludes positional arguments.

:repeat
    Non-nil value specifies that this option or argument can occur
    multiple times.

:style
    Controls how inline arguments are handled.
        `seperate' - no inline arguments
        `inline' - arguments must be inline
        `seperate-or-inline' - arguments can be inline or not

:delim
    String specifying the delimiter used for options with inline
    arguments.

:suffix
    String to insert after completion is performed.

:subparser
    Function to call when the argument or option is parsed. See the
    source for details.


The following KEYWORD-ARGS are supported:

:hints
    List of elements to temporarily add to
    `pcmpl-args-guess-completions-hints'.

:no-shared-args
    Options specified in the same string do not necessarily share
    the same arguments.

The value returned can be passed to `pcmpl-args-pcomplete'."

  (let ((kwargs keyword-args))
    (while kwargs
      (unless (keywordp (car kwargs))
        (error "Invalid keyword argument: %S" (car kwargs)))
      (pop kwargs) (pop kwargs)))

  (let ((pcmpl-args-guess-completions-hints
         (append (plist-get keyword-args :hints)
                 pcmpl-args-guess-completions-hints))
        accum)
    (dolist (spec (remove nil specs))
      (if (member :name spec)
          ;; It's an expanded argspec; pass it along
          (push spec accum)
        (let ((type (elt spec 0))
              (names (elt spec 1))
              (props (nthcdr 2 spec)))
          (unless (and (symbolp type)
                       (member type '(option argument)))
            (error "Invalid argspec type: %S" type))
          (when (and props (not (keywordp (car props))))
            (push :actions props))
          (let ((lst props))
            (while lst
              (cl-assert (keywordp (car lst)) t)
              (pop lst)
              (pop lst)))
          (dolist (el
                   (cond ((eq type 'argument)
                          (pcmpl-args--make-argspec-argument names props))
                         ((eq type 'option)
                          (pcmpl-args--make-argspec-option
                           names props (plist-get keyword-args :no-shared-args)))
                         (t
                          (error "Unrecognized argspec type: %S" type))))
            (push el accum)))))
    (setq accum (nreverse accum))
    (let (rv)
      (dolist (spec accum)
        ;; Guess and replace appropriate actions.
        (when (plist-get spec :actions)
          (setq spec (plist-put
                      ;; (copy-sequence spec)
                      spec
                      :actions
                      (mapcar (lambda (action)
                                (if (not (eq (elt action 1) t))
                                    action
                                  (append (list (elt action 0)
                                                (pcmpl-args-guess-completions
                                                 (plist-get spec :name)
                                                 (elt action 0)))
                                          (nthcdr 2 action))))
                              (plist-get spec :actions)))))
        ;; For prettier output, remove keys with nil values.
        (let (lst k v)
          (while spec
            (setq k (pop spec)
                  v (pop spec))
            (when v
              (push k lst)
              (push v lst)))
          (setq spec (nreverse lst)))
        (push spec rv))
      (setq rv (nreverse rv))
      (when pcmpl-args-debug
        (pcmpl-args-debug "= argspecs =")
        (dolist (spec rv)
          (pcmpl-args-debug "%S" spec))
        (pcmpl-args-debug "\n%s\n" (pcmpl-args-format-argspecs rv)))
      rv)))

(defun pcmpl-args--make-argspec-argument (name &optional props)
  (cl-assert (or (numberp name) (memq name '(*))) t)
  (list (apply #'list :name name :type 'argument (copy-sequence props))))

(defun pcmpl-args--make-argspec-option (options-list &optional plist no-share-args)
  (when (atom options-list) (setq options-list (list options-list)))
  (mapc (lambda (o) (cl-assert (stringp o) t)) options-list)
  (setq plist (copy-sequence plist))
  (let (option-strings argspecs)
    ;; Flatten options-list to single options.
    (dolist (opt-str options-list)
      ;; Extract inline help delimited by multiple spaces.
      (when (string-match "  +\\|\t[\t ]*" opt-str)
        (unless (plist-get plist :help)
          (setq plist (plist-put
                       plist :help
                       (substring opt-str (match-end 0)))))
        (setq opt-str (substring opt-str 0 (match-beginning 0))))
      ;; Split into multiple options.
      (setq opt-str (replace-regexp-in-string
                     "\\([, ]+\\)-" "\x0" opt-str nil nil 1))
      (dolist (s (split-string opt-str "\x0" t))
        (push s option-strings)))
    (setq option-strings (nreverse option-strings))
    (dolist (opt-str option-strings)
      (let ((optname opt-str)
            (argstring nil))
        (when (string-match " " optname)
          (setq argstring (substring optname (match-beginning 0))
                optname (substring optname 0 (match-beginning 0))))
        (when (string-match "=" optname)
          (setq argstring (concat (substring optname (match-beginning 0)) argstring)
                optname (substring optname 0 (match-beginning 0))))
        (when (string-match "\\`.*?\\((\\|{\\|<\\|\\[\\)" optname)
          (setq argstring (concat (substring optname (match-beginning 1)) argstring)
                optname (substring optname 0 (match-beginning 1))))
        (when (string-match "\\`-*\\'" optname)
          (pcmpl-args-debug (propertize "Bad option: %S" 'face 'error) opt-str)
          (setq optname opt-str
                argstring nil))
        (cl-assert (= (length (concat optname argstring))
                      (length opt-str))
                   t)
        (if (null argstring)
            (push (list :name optname
                        :type 'option
                        :help nil
                        :style nil
                        :delim nil
                        :suffix nil
                        :aliases nil
                        :actions nil) argspecs)
          (push (list :name optname
                      :type 'option
                      :help nil
                      :style (cond ((string-prefix-p "=" argstring)
                                    'seperate-or-inline)
                                   ((string-prefix-p " " argstring)
                                    'seperate)
                                   (t 'inline))
                      :delim (cond ((string-prefix-p "=" argstring) "=")
                                   ((string-prefix-p " " argstring) nil)
                                   ((string-prefix-p "[=" argstring) "=")
                                   (t ""))
                      :suffix (when (string-prefix-p "[=" argstring)
                                "=")
                      :aliases nil
                      :actions (mapcar (lambda (s)
                                         (list s t))
                                       (split-string
                                        (replace-regexp-in-string
                                         "\\`\\(\\[=\\(.*?\\)\\]\\)" "\\2"
                                         (replace-regexp-in-string
                                          "\\`[ =]" "" argstring)
                                         nil nil 1)
                                        " " t)))
                argspecs))))
    (setq argspecs (nreverse argspecs))
    (let (rv)
      (let ((names (mapcar (lambda (s) (plist-get s :name)) argspecs))
            (spec-with-actions
             (car (delq nil (mapcar (lambda (s) (and (plist-get s :actions) s))
                                    argspecs)))))
        (dolist (spec argspecs)
          (setq spec (plist-put spec :aliases
                                (remove (plist-get spec :name) names)))
          ;; Handle multiple options that use the same arg, eg: `-o, --opt=ARG'
          (when (and (not no-share-args)
                     (not (plist-get spec :actions))
                     spec-with-actions)
            (if (or (and (string-prefix-p "--" (plist-get spec :name))
                         (string-prefix-p "--" (plist-get spec-with-actions :name)))
                    (and (not (string-prefix-p "--" (plist-get spec :name)))
                         (not (string-prefix-p "--" (plist-get spec-with-actions :name)))))
                ;; Both are long or short options; just copy the properties.
                (setq spec (plist-put spec :actions (plist-get spec-with-actions :actions))
                      spec (plist-put spec :style (plist-get spec-with-actions :style))
                      spec (plist-put spec :delim (plist-get spec-with-actions :delim))
                      spec (plist-put spec :suffix (plist-get spec-with-actions :suffix)))
              (let ((delim (plist-get spec-with-actions :delim))
                    (suffix (plist-get spec-with-actions :suffix))
                    (long-p (string-prefix-p "--" (plist-get spec :name))))
                (pcase (plist-get spec-with-actions :style)
                  (`seperate
                   (setq delim nil
                         suffix nil))
                  (`seperate-or-inline
                   (setq delim (if long-p "=" "")
                         suffix (if long-p nil nil)))
                  (`inline
                    (setq delim (if long-p "=" "")
                          suffix (if long-p "=" "")))
                  (x (error "Invalid option style: %S" x)))
                (setq spec (plist-put spec :actions (plist-get spec-with-actions :actions))
                      spec (plist-put spec :style (plist-get spec-with-actions :style))
                      spec (plist-put spec :delim delim)
                      spec (plist-put spec :suffix suffix)))))
          (let ((tmp plist))
            (while tmp
              (setq spec (plist-put spec (pop tmp) (pop tmp)))))
          (push spec rv)))
      rv)))

(defun pcmpl-args-parse-help-buffer (&rest keyword-args)
  "Return a list of options found in the current buffer.
The current buffer should contain text describing option usage,
such as the output of command called with the `--help' option.

Due to the variations in formatting, this function tries to
recognize and handle many different styles.  The best handled
style is the GNU long-option style.

The following KEYWORD-ARGS are recognized:

:filters
    Function or a list of functions to call before parsing.
    May be used to modify the buffer contents.

:start-regexp
    Regular expression indicating where to start parsing.

:end-regexp
    Regular expression indicating where to stop parsing.

If the variable `pcmpl-args-debug-parse-help' is non-nil, the
matched options will be highlighted.

Returns a list of cons cells of the form:

    \(OPTION . DESCRIPTION)"
  (when pcmpl-args-debug-parse-help
    (dolist (ov (append (car (overlay-lists))
                        (cdr (overlay-lists))))
      (delete-overlay ov)))
  (goto-char (point-min))
  (when (plist-get keyword-args :filters)
    (dolist (f (or (and (functionp (plist-get keyword-args :filters))
                        (list (plist-get keyword-args :filters)))
                   (plist-get keyword-args :filters)))
      (goto-char (point-min))
      (funcall f)))
  (goto-char (point-min))
  (save-restriction
    (when (or (plist-get keyword-args :start-regexp)
              (plist-get keyword-args :end-regexp))
      (when (plist-get keyword-args :start-regexp)
        (re-search-forward (plist-get keyword-args :start-regexp) nil t))
      (narrow-to-region
       (point)
       (or (save-excursion
             (and (plist-get keyword-args :end-regexp)
                  (re-search-forward (plist-get keyword-args :end-regexp) nil t)
                  (match-beginning 0)))
           (point-max))))
    (let* ((start-time (float-time))
           (rgx (concat "^[ ]\\{1,60\\}"
                        "\\("
                        (concat "\\(?:\\(?:\\(?:"
                                "-+[^- \n][^ \n]*"         ;option
                                "\\(?: [^- \n][^ \n]*\\)?" ;optarg
                                "\\)\\)"                   ;
                                "\\(?:[ ]\\{,60\\},\\|[ ]\\{1,60\\}or \\)[ ]\\{0,60\\}" ;delimiter
                                "\\)*")
                        "\\(?:"
                        "\\(?:[ ]\\{,60\\}-+[^- \n][^ \n]*\\)+" ;option
                        ;; "\\>"
                        (concat "\\("
                                ;; optarg followed by description or newline
                                "\\(?: [^- \n][^ \n]*\\($\\|[ ][ ]+\\)\\)"
                                "\\|"
                                "\\(?: <[^ \n]*>\\)+" ;<optarg>...
                                "\\|"
                                "\\(?: \\[[^ \n]*\\]\\)+" ;[optarg]...
                                "\\|"
                                "\\(?: [A-Z][-:_@A-Z0-9]+\\)" ;OPTARG
                                "\\|"
                                "\\(?: [a-zA-Z]=[^ \n]*\\)" ;optarg=value
                                "\\)")
                        "?"
                        "\\)+\\)"))
           opts
           opt doc
           opt-beg-pos opt-end-pos
           doc-beg-pos doc-end-pos
           doc-column)
      (while (let (case-fold-search)
               (re-search-forward rgx nil t))
        (skip-chars-forward " ")
        (setq opt-beg-pos (match-beginning 1)
              opt-end-pos (match-end 0)
              doc-beg-pos (point)
              doc-end-pos (line-end-position)
              doc-column (save-excursion
                           (goto-char doc-beg-pos)
                           (current-column))
              opt (replace-regexp-in-string
                   " or " ", "
                   (replace-regexp-in-string
                    "[ \t\f\v\r\n]+" " "
                    (buffer-substring-no-properties
                     opt-beg-pos opt-end-pos)))
              doc nil)
        ;; Look for a description which may span multiple lines.
        (if (eolp)
            ;; Description may start on the next line.
            (save-excursion
              (forward-line)
              (skip-chars-forward " ")
              (when (or (eolp) (bolp))
                (forward-line)
                (skip-chars-forward " "))
              (if (or (eolp) (bolp)
                      (<= (current-column)
                          (save-excursion
                            (goto-char opt-beg-pos)
                            (current-column))))
                  (setq doc-column nil)
                (setq doc-beg-pos (point)
                      doc-column (current-column))))
          ;; The description starts on the same line so be more discerning
          ;; about parsing the next line if it looks like an option.
          (save-excursion
            (forward-line)
            (skip-chars-forward " ")
            (if (or (eolp)
                    (bolp)
                    (and (looking-at "-")
                         (< (current-column) doc-column)))
                (setq doc-column nil)
              (setq doc-column (min doc-column (current-column))))))
        (goto-char doc-beg-pos)
        ;; Parse indented text.
        (while (and doc-column
                    (not (eobp)))
          (setq doc-end-pos (line-end-position))
          (forward-line)
          (skip-chars-forward " ")
          (when (or (eolp)
                    (< (current-column) doc-column))
            (setq doc-column nil)))
        (goto-char doc-end-pos)
        ;; (save-excursion
        ;;   (goto-char doc-beg-pos)
        ;;   (setq doc-end-pos
        ;;         (min (+ (point) 300)
        ;;              (or (and (re-search-forward
        ;;                        "\\=\\(.\\|\n\\)+?\\.\\([ ][ ]\\|[ ]*$\\)"
        ;;                        doc-end-pos t)
        ;;                       (match-beginning 2))
        ;;                  doc-end-pos))))
        (setq doc (replace-regexp-in-string
                   " *\n *" " "
                   (pcmpl-args-strip
                    (buffer-substring-no-properties doc-beg-pos doc-end-pos))))
        (when pcmpl-args-debug-parse-help
          (pcmpl-args-debug "Found option: %S  %S" opt doc)
          (let ((ov (make-overlay opt-beg-pos opt-end-pos)))
            (overlay-put ov 'face '(:background "light green")))
          (let ((ov (make-overlay doc-beg-pos doc-end-pos)))
            (overlay-put ov 'face '(:background "pink"))))
        (push (cons opt doc) opts))
      (setq opts (nreverse opts))
      ;; We assume that options without descriptions are probably aliases
      ;; so we assign them the subsequent option's description.
      (let ((lst opts) el)
        (while lst
          (setq el (pop lst))
          (when (and lst (string= "" (cdr el)))
            (setcdr el (cl-dolist (p lst)
                         (when (not (string= "" (cdr p)))
                           (cl-return (cdr p))))))))
      (when pcmpl-args-debug
        (pcmpl-args-debug "Found %s options in %f seconds"
                          (length opts) (- (float-time) start-time)))
      opts)))

(defun pcmpl-args-extract-argspecs-from-buffer (&rest args)
  "Return a list of argspecs by parsing the current buffer.
ARGS are passed to `pcmpl-args-parse-help-buffer'."
  (save-excursion
    (goto-char (point-min))
    (let ((opt-doc-alist (apply #'pcmpl-args-parse-help-buffer args))
          accum)
      (dolist (opt opt-doc-alist)
        (push (list 'option
                    (car opt)
                    :help (cdr opt))
              accum))
      (nreverse accum))))

(defun pcmpl-args-extract-argspecs-from-shell-command (shell-command &rest args)
  "Return a list of argspecs by parsing the output of SHELL-COMMAND.
ARGS are passed to `pcmpl-args-parse-help-buffer'."
  (ignore-errors (kill-buffer " *pcmpl-args-output*"))
  (with-current-buffer (get-buffer-create " *pcmpl-args-output*")
    (erase-buffer)
    (pcmpl-args-process-file
     shell-file-name shell-command-switch shell-command)
    (apply #'pcmpl-args-extract-argspecs-from-buffer args)))

(defvar pcmpl-args-man-function 'pcmpl-args-default-man-function
  "Function called to generate the manual for a command.
It should take one argument, the name of the manual and it should
insert its content into the current buffer.")

(defun pcmpl-args-default-man-function (name)
  (let ((process-environment process-environment))
    ;; Setting MANWIDTH to a high number makes most paragraphs fit on a single
    ;; line, reducing the number of false positives that result from lines
    ;; starting with `-' that aren't really options.
    (push "MANWIDTH=10000" process-environment)
    (pcmpl-args-process-file "man" name)))

(defun pcmpl-args-extract-argspecs-from-manpage (name &rest args)
  "Return a list of argspecs by parsing the manpage identified by NAME.
ARGS are passed to `pcmpl-args-parse-help-buffer'."
  (ignore-errors (kill-buffer " *pcmpl-args-output*"))
  (with-current-buffer (get-buffer-create " *pcmpl-args-output*")
    (erase-buffer)
    (funcall pcmpl-args-man-function name)
    (goto-char (point-min))
    (pcmpl-args-unbackspace-argspecs
     (apply #'pcmpl-args-extract-argspecs-from-buffer args))))

(defun pcmpl-args-format-argspec (spec &optional short)
  "Return a string for displaying SPEC.
If SHORT is NON NIL, return a string without :help."
  (let* ((metavars (mapcar #'car (plist-get spec :actions)))
         (type (plist-get spec :type))
         name)
    (cond ((member type '(argument))
           (setq name (format "%S=" (plist-get spec :name))))
          ((member type '(option))
           (setq name (format "%s" (plist-get spec :name))))
          (t
           (error "Unknown argspec type: %S" spec)))
    (setq name (propertize name 'face 'font-lock-keyword-face))
    (when metavars
      (let ((s ""))
        (setq s (concat s (or
                           (cond ((eq (plist-get spec :style) 'inline)
                                  (plist-get spec :delim))
                                 ((eq (plist-get spec :style) 'seperate-or-inline)
                                  (if (and (stringp (plist-get spec :name))
                                           (string-prefix-p "--" (plist-get spec :name)))
                                      (plist-get spec :delim)
                                    (plist-get spec :suffix)))
                                 (t
                                  (plist-get spec :suffix)))
                           " ")))
        (let ((actions (plist-get spec :actions))
              action)
          (while actions
            (setq action (pop actions)
                  s (concat s
                            (elt action 0)
                            (and actions (or (elt action 2)
                                             " "))))))
        (when (and (eq (plist-get spec :style) 'inline)
                   (not (string-match-p "\\[" s)))
          (setq s (concat "[" s "]")))
        (setq name (concat name (propertize (upcase s) 'face font-lock-type-face)))))
    (when (not short)
      (setq name (format "%-22s  %s" name
                         (propertize (or (plist-get spec :help) "")
                                     'face font-lock-doc-face))))
    name))

(defun pcmpl-args-format-argspecs (specs)
  "Return a string for displaying SPECS."
  (mapconcat #'pcmpl-args-format-argspec specs "\n"))

(defun pcmpl-args-parse-arguments (arguments argspecs)
  "Parse the words in ARGUMENTS as specified by ARGSPECS.
Returns a list containing the following:

- List containing any unprocessed arguments.
- List of argspecs that have not been excluded.
- List of property lists containing info of previous parsing states."
  (pcmpl-args-debug "Parsing arguments: %S" arguments)
  (pcmpl-args--sanity-check arguments argspecs nil)
  (let* (seen)
    (while arguments
      (let* ((option-specs
              (delq nil (mapcar
                         (lambda (s) (if (eq (plist-get s :type) 'option) s))
                         argspecs)))
             (option-specs-no-prefix
              (delq nil (mapcar
                         (lambda (s)
                           (when (and (eq (plist-get s :type) 'option)
                                      (not (string-prefix-p "-" (plist-get s :name))))
                             s))
                         argspecs)))
             (argument-specs
              (delq nil (mapcar
                         (lambda (s) (if (eq (plist-get s :type) 'argument) s))
                         argspecs)))
             parsed)
        (cond
         ;; Parse a long or short option.
         ((and option-specs
               (or option-specs-no-prefix
                   (null argument-specs)
                   (string-match "\\`-" (car arguments)))
               (setq parsed
                     (progn
                       (pcmpl-args--parse-option arguments argspecs seen))))
          (when (equal (plist-get (car (elt parsed 2)) :context) 'unknown-option)
            (let ((ambigous-matches (pcmpl-args--find-ambiguous-options (car arguments)
                                                                        argspecs)))
              ;; Don't try to parse as short option if ambigous
              (if ambigous-matches
                  (pcmpl-args-debug "Option is ambigous" (car arguments))
                (pcmpl-args-debug "Try to parse as short option")
                (setq parsed (pcmpl-args--parse-short-option arguments argspecs seen)))))
          (setq arguments (elt parsed 0)
                argspecs (elt parsed 1)
                seen (elt parsed 2)))
         ;; Parse a positional argument.
         ((setq parsed
                (progn
                  (pcmpl-args--parse-argument arguments argspecs seen)))
          (setq arguments (elt parsed 0)
                argspecs (elt parsed 1)
                seen (elt parsed 2)))
         (t
          (error "Failed to parse arguments: %S" arguments)))
        (pcmpl-args-debug "Remaining arguments: %S" arguments)))
    (pcmpl-args-debug "Parsing done\n")
    (pcmpl-args--sanity-check arguments argspecs seen)))

(defun pcmpl-args--sanity-check (arguments argspecs seen)
  (when pcmpl-args-debug
    (dolist (arg arguments)
      (cl-assert (stringp arg) t))
    (dolist (spec argspecs)
      (cl-assert (and spec (listp spec)) t)
      (let ((tmp spec))
        (while tmp
          (cl-assert (keywordp (car tmp)) t)
          (pop tmp)
          (cl-assert (not (keywordp (car tmp))) t)
          (pop tmp)))
      (cl-assert (plist-get spec :name) t)
      (cl-assert (plist-get spec :type) t)
      (dolist (action (plist-get spec :action))
        (cl-assert (and action (listp action)) t)
        (cl-assert (stringp (car action)) t)
        (cl-assert (and action (or (= 3 (length action))
                                   (= 2 (length action)))))))
    (dolist (state seen)
      (cl-assert (and state (listp state)) t)
      (let ((tmp state))
        (while tmp
          (cl-assert (keywordp (car tmp)) t)
          (pop tmp)
          (cl-assert (not (keywordp (car tmp))) t)
          (pop tmp)))
      (cl-assert (stringp (plist-get state :stub)) t)
      (cl-assert (member :name state) t)
      (cl-assert (member :action state) t)
      (when (plist-get state :action)
        (cl-assert (stringp (car (plist-get state :action))) t)
        (cl-assert (and (plist-get state :action)
                        (or (= 3 (length (plist-get state :action)))
                            (= 2 (length (plist-get state :action)))) t)))))
  (list arguments argspecs seen))

(defun pcmpl-args-filter-argspecs (spec argspecs)
  "Filter ARGSPECS excluded by SPEC."
  (let ((excludes (plist-get spec :excludes)))
    (unless (or (equal (plist-get spec :name) '*)
                (plist-get spec :repeat))
      (push (plist-get spec :name) excludes)
      (setq excludes (append excludes (plist-get spec :aliases))))
    (dolist (pattern excludes)
      (unless (or (null pattern)
                  (numberp pattern)
                  (stringp pattern)
                  (memq pattern '(- * : options arguments positionals)))
        (error "Invalid exclude pattern: %S" pattern))
      (setq argspecs
            (mapcar (lambda (sp)
                      (let ((type (plist-get sp :type))
                            (name (plist-get sp :name)))
                        (cond ((equal name pattern)
                               nil)
                              ((and (eq type 'option)
                                    (memq pattern '(- options)))
                               nil)
                              ((and (eq type 'argument)
                                    (memq pattern '(* arguments)))
                               nil)
                              ((and (eq type 'argument)
                                    (memq pattern '(: positional))
                                    (not (equal name '*)))
                               nil)
                              (t
                               sp))))
                    argspecs)))
    (remove nil argspecs)))

(defun pcmpl-args--parse-argument (arguments argspecs seen)
  (pcmpl-args-debug "Parsing argument: %S" (car arguments))
  (let* ((argument-specs
          (sort
           (delq nil (mapcar (lambda (s)
                               (and (eq 'argument (plist-get s :type)) s))
                             argspecs))
           (lambda (a b)
             (< (if (eq (plist-get a :name) '*) 1000000 (plist-get a :name))
                (if (eq (plist-get b :name) '*) 1000000 (plist-get b :name))))))
         spec nargs vals action)
    (while (and argument-specs
                (equal (plist-get (car argument-specs) :name)
                       (plist-get (cadr argument-specs) :name)))
      (pop argument-specs))
    (setq spec (car argument-specs)
          argspecs (pcmpl-args-filter-argspecs spec argspecs)
          nargs (if (eq (plist-get spec :name) '*) 10000 1))
    (pcmpl-args-debug "Parsed argument: %S --> %S" (car arguments) spec)
    (if (plist-get spec :subparser)
        (progn
          (pcmpl-args-debug "Calling subparser for argument %S\narguments:\n%s\nstates:\n%s\n"
                            (plist-get spec :name)
                            (pp-to-string arguments)
                            (pp-to-string seen))
          (apply #'pcmpl-args--sanity-check
                 (funcall (plist-get spec :subparser)
                          arguments argspecs seen)))
      (let ((i 0)
            (actions (plist-get spec :actions)))
        (while (and arguments (< i nargs))
          (pcmpl-args-debug "Parsed argument: %S[%S] = %S --> %S"
                            (plist-get spec :name)
                            i (car arguments) (elt actions (min i (1- (length actions)))))
          (push (pop arguments) vals)
          (setq action (elt actions (min i (1- (length actions)))))
          (cl-incf i)))
      (setq vals (nreverse vals))
      (push (list :context (if argument-specs 'argument 'unknown-argument)
                  :name (or (plist-get spec :dest)
                            (plist-get spec :name))
                  :argspec spec
                  :action action
                  :values vals
                  :stub (car (last vals)))
            seen)
      (list arguments argspecs seen))))

(defun pcmpl-args--parse-option (arguments argspecs seen)
  (pcmpl-args-debug "Parsing option: %S" arguments)
  (let* ((argspec (pcmpl-args--find-option (car arguments) argspecs))
         context action values stub)
    (setq argspecs (pcmpl-args-filter-argspecs argspec argspecs))
    (cond ((null argspec)
           (pcmpl-args-debug "Unknown option: %S" (car arguments))
           (setq context 'unknown-option
                 stub (pop arguments)
                 values nil
                 action (pcmpl-args--make-action-for-options
                         stub argspec argspecs
                         ;; (remove nil (cons argspec argspecs))
                         )))
          ((or (null (plist-get argspec :actions))
               (plist-get argspec :subparser))
           (pcmpl-args-debug "Parsed option: %S --> %S" (car arguments) argspec)
           (setq context 'option
                 stub (pop arguments)
                 values nil
                 action (pcmpl-args--make-action-for-options
                         stub argspec argspecs
                         ;; (remove nil ;; (cons argspec argspecs)
                         ;;         argspecs
                         ;;         )
                         )))
          (t
           (pcmpl-args-debug "Parsed option: %S --> %S" (car arguments) argspec)
           (setq stub (pop arguments)
                 action nil)
           (let (args
                 (nargs (length (plist-get argspec :actions)))
                 (name-delim (concat (plist-get argspec :name)
                                     (plist-get argspec :delim))))
             (cond ((null (plist-get argspec :actions))
                    nil)
                   ((and (eq 'inline (plist-get argspec :style))
                         (not (string-prefix-p name-delim stub)))
                    (cl-decf nargs))
                   ((and (eq 'seperate-or-inline (plist-get argspec :style))
                         (not (string-prefix-p name-delim stub)))
                    nil)
                   ((and (memq (plist-get argspec :style) '(seperate-or-inline))
                         (equal (plist-get argspec :delim) "")
                         arguments)
                    nil)
                   ((memq (plist-get argspec :style) '(seperate-or-inline inline))
                    (cl-assert (string-prefix-p name-delim stub) t)
                    (push (substring stub (length name-delim)) arguments)
                    (setq stub (substring stub 0 (length (plist-get argspec :name))))
                    (cl-assert (equal stub (plist-get argspec :name)) t)))
             (dotimes (i nargs)
               (when arguments
                 (pcmpl-args-debug "Parsed optarg: %S --> %S"
                                   (car arguments)
                                   (elt (plist-get argspec :actions) i))
                 (push (setq stub (pop arguments)) args)))
             (setq args (nreverse args))
             (setq context 'option
                   values args
                   action (if values
                              (elt (plist-get argspec :actions)
                                   (1- (length values)))
                            (pcmpl-args--make-action-for-options
                             stub argspec argspecs
                             ;; (remove nil ;; (cons argspec argspecs)
                             ;;         argspecs
                             ;;         )
                             ))))))
    (let ((saw (list :context context
                     :name (or (plist-get argspec :dest)
                               (plist-get argspec :name))
                     :stub stub
                     :argspec argspec
                     :action action
                     :values values)))
      (push saw seen))
    (if (plist-get argspec :subparser)
        (progn
          (pcmpl-args-debug "Calling subparser for argument %S\narguments:\n%s\nstates:\n%s\n"
                            (plist-get argspec :name)
                            (pp-to-string arguments)
                            (pp-to-string seen))
          (apply #'pcmpl-args--sanity-check
                 (funcall (plist-get argspec :subparser)
                          arguments argspecs seen)))
      (list arguments argspecs seen))))

(defun pcmpl-args--parse-short-option (arguments argspecs seen)
  (pcmpl-args-debug "Parsing short option: %S" arguments)
  (if (null arguments)
      (list arguments argspecs seen)
    (let ((matched-spec (pcmpl-args--find-option (car arguments) argspecs)))
      (cond (matched-spec
             (pcmpl-args--parse-option arguments argspecs seen))
            ((string-match "\\`-[a-zA-Z0-9]" (car arguments))
             (let* ((arg (car arguments))
                    (a (pcmpl-args--parse-option (list (substring arg 0 2))
                                                 argspecs seen))
                    (new-arg (substring arg 2)))
               (pop arguments)
               (setq argspecs (elt a 1)
                     seen (elt a 2))
               (if (equal new-arg "")
                   (list arguments argspecs seen)
                 (pcmpl-args--parse-short-option
                  (cons (concat "-" new-arg) arguments)
                  argspecs seen))))
            (t
             (pcmpl-args--parse-option arguments argspecs seen))))))

(defun pcmpl-args--find-option (optname argspecs)
  (cl-assert (stringp optname) t)
  (or (let (found)
        (dolist (spec argspecs)
          (when (and (eq (plist-get spec :type) 'option)
                     (equal (plist-get spec :name) optname))
            (setq found spec)))
        found)
      (let (accum)
        (dolist (spec argspecs)
          (when (and (eq (plist-get spec :type) 'option)
                     (plist-get spec :actions)
                     (memq (plist-get spec :style) '(seperate-or-inline inline))
                     (string-prefix-p (concat (plist-get spec :name)
                                              (plist-get spec :delim))
                                      optname))
            (push spec accum)))
        (setq accum
              (sort accum
                    (lambda (a b) (> (length (plist-get a :name))
                                     (length (plist-get b :name))))))
        (car accum))))

(defun pcmpl-args--find-ambiguous-options (optname argspecs)
  (cl-assert (stringp optname) t)
  (let (accum)
    (dolist (spec argspecs)
      (when (and (eq (plist-get spec :type) 'option)
                 (string-prefix-p optname (plist-get spec :name)))
        (push spec accum)))
    (nreverse accum)))

(defun pcmpl-args--find-prefix-options (optname argspecs)
  (cl-assert (stringp optname) t)
  (let (accum)
    (dolist (spec argspecs)
      (when (and (eq (plist-get spec :type) 'option)
                 (string-prefix-p (plist-get spec :name) optname))
        (push spec accum)))
    (nreverse accum)))

(defun pcmpl-args--make-action-for-options (stub spec argspecs)
  (let* ((ambigous (pcmpl-args--find-ambiguous-options
                    stub (cons spec argspecs)))
         (suffix (or (and spec (plist-get spec :suffix))
                     (plist-get (car ambigous) :suffix)
                     " "))
         (tbl (make-hash-table :test 'equal)))
    (if (or (null spec)
            (plist-get spec :actions)
            (not (string-match "\\`-[a-zA-Z0-9]\\'" (plist-get spec :name)))
            (> (length ambigous) 1))
        (progn
          (dolist (spec (cons spec argspecs))
            (when (eq (plist-get spec :type) 'option)
              (puthash (propertize (plist-get spec :name)
                                   'help-echo (plist-get spec :help))
                       (when pcmpl-args-annotation-style
                         (substring-no-properties
                          (pcmpl-args-format-argspec
                           spec (equal pcmpl-args-annotation-style 'short))
                          (length (plist-get spec :name))))
                       tbl)))
          (setq argspecs nil
                ambigous nil
                spec nil
                stub nil)
          (list "OPTION"
                (lambda (s p a)
                  (cond ((eq a 'metadata)
                         `(metadata
                           (category . option)
                           (annotation-function
                            . ,(pcmpl-args-make-completion-annotator
                                tbl))))
                        (t
                         (complete-with-action a tbl s p))))
                suffix))

      (dolist (spec argspecs)
        (when (and (eq (plist-get spec :type) 'option)
                   (string-match "\\`-[a-zA-Z0-9]\\'" (plist-get spec :name)))
          (puthash (propertize (substring (plist-get spec :name) 1)
                               'help-echo (plist-get spec :help))
                   (when pcmpl-args-annotation-style
                     (substring-no-properties
                      (pcmpl-args-format-argspec
                       spec (equal pcmpl-args-annotation-style 'short))
                      (length (plist-get spec :name))))
                   tbl)))
      (setq argspecs nil
            ambigous nil
            spec nil
            stub nil)
      (list "SHORT-OPTION"
            (list :lambda (lambda (_alist)
                            (setq pcomplete-stub "")
                            (lambda (s p a)
                              (cond ((eq a 'metadata)
                                     `(metadata
                                       (category . option)
                                       (annotation-function
                                        . ,(pcmpl-args-make-completion-annotator
                                            tbl))))
                                    (t
                                     (complete-with-action
                                      a tbl s p))))))))))


;;; Caching support

(defvar pcmpl-args-cache (make-hash-table :test 'equal))

(defmacro pcmpl-args-cached (key duration &rest body)
  "Look up KEY in cache or eval and cache BODY for a DURATION of seconds."
  (declare (indent 2))
  (let ((k (make-symbol "k")))
    `(let ((,k ,key))
       (or (pcmpl-args-cache-get ,k)
           (pcmpl-args-cache-put ,k (progn ,@body)
                                 ,duration)))))

(defun pcmpl-args-cache-flush (&optional all)
  "Check and delete expired elements in cache.
When called interactively or ALL is NON NIL, all elements are
deleted."
  (interactive "p")
  (if all
      (setq pcmpl-args-cache
            (clrhash pcmpl-args-cache))
    (maphash (lambda (k _v)
               (pcmpl-args--cache-get k))
             (copy-hash-table pcmpl-args-cache))))

(defun pcmpl-args-cache-put (key value &optional duration)
  "Associate KEY with VALUE in cache for a DURATION of seconds.
After the DURATION has expired, the cached VALUE will be deleted.
If DURATION is t, `pcmpl-args-cache-default-duration' will be
used."
  (when (eq duration t)
    (setq duration (or pcmpl-args-cache-default-duration 0.0)))
  (setq duration (min duration pcmpl-args-cache-max-duration))
  (pcmpl-args-debug "pcmpl-args-cache-put: [%S] caching %S for %S"
                    (hash-table-count pcmpl-args-cache)
                    key (or duration pcmpl-args-cache-default-duration))
  (cl-assert (numberp duration) t)
  (when (> duration 0.0)
    (let ((time (+ duration (float-time))))
      (cl-assert (< 0.0 time) t)
      (puthash key (list '--pcmpl-args-cache--
                         time
                         value)
               pcmpl-args-cache)))
  value)

(defun pcmpl-args-cache-get (key)
  "Look up KEY in cache and return its value.
If the KEY's cache duration has expired, the value will be nil."
  (prog1 (pcmpl-args--cache-get key)
    ;; Checks the entire cache on every access; it might be better
    ;; to do this via a timer or a hook or something.
    (pcmpl-args-cache-flush)))

(defun pcmpl-args--cache-get (key)
  (let ((found (gethash key pcmpl-args-cache)))
    (if (and found (not (eq (car found) '--pcmpl-args-cache--)))
        (cl-assert nil nil "Invalid cache entry: %S" found)
      (let ((_ (elt found 0))
            (expires (elt found 1))
            (retval  (elt found 2)))
        (cond
         ((null found)
          (pcmpl-args-debug
           (propertize "pcmpl-args-cache-get: [%S] %S [missing]"
                       'face 'warning)
           (hash-table-count pcmpl-args-cache) key)
          nil)
         ((numberp expires)
          (if (>= (- (float-time) expires) 0)
              (progn
                (pcmpl-args-debug
                 (propertize "pcmpl-args-cache-get: [%S] %S [cache expired]"
                             'face 'warning)
                 (hash-table-count pcmpl-args-cache) key)
                ;; (puthash key nil pcmpl-args-cache)
                (remhash key pcmpl-args-cache)
                (setq retval nil))
            (pcmpl-args-debug
             (propertize "pcmpl-args-cache-get: [%S] %S [cached]"
                         'face 'success)
             (hash-table-count pcmpl-args-cache) key))
          retval)
         (t
          (cl-assert nil nil "Invalid cache expiration time stored: %S" found)))))))


;;; Completion utilities

(defun pcmpl-args-completions-with-context (args)
  "Return the completions that pcomplete would generate from ARGS."
  (pcmpl-args-debug "pcmpl-args-completions-with-context: %S" args)
  (setq pcomplete-args args
        pcomplete-last (1- (length pcomplete-args))
        pcomplete-index 0
        pcomplete-stub (car args))
  (if (= pcomplete-index pcomplete-last)
      (funcall pcomplete-command-completion-function)
    (let ((sym (or (pcomplete-find-completion-function
                    (funcall pcomplete-command-name-function))
                   pcomplete-default-completion-function)))
      (ignore
       (pcomplete-next-arg)
       (funcall sym)))))

(defun pcmpl-args-completion-table-with-metadata (metadata table)
  "Return a new completion-table.
It completes like TABLE, but returns METADATA when requested."
  (cl-assert (eq (car metadata) 'metadata) t)
  (lambda (string pred action)
    (cond
     ((eq action 'metadata) metadata)
     (t
      (complete-with-action action table string pred)))))

(defun pcmpl-args-guess-display-width ()
  (save-excursion
    (save-window-excursion
      (let ((config (current-window-configuration)))
        (unwind-protect
            (let ((buff (get-buffer "*Completions*")))
              (prog1 (1- (window-width
                          (display-buffer (get-buffer-create "*Completions*"))))
                (unless buff
                  (kill-buffer "*Completions*"))))
          (set-window-configuration config))))))

(defun pcmpl-args-make-completion-annotator (table-or-function)
  (let ((width (pcmpl-args-guess-display-width)))
    (lambda (string)
      (when pcmpl-args-annotation-style
        (let ((retval
               (cond ((functionp table-or-function)
                      (funcall table-or-function string))
                     ((hash-table-p table-or-function)
                      (gethash string table-or-function))
                     (t
                      (let ((cell (assoc string table-or-function)))
                        (if (atom (cdr cell))
                            (cdr cell)
                          (cadr cell)))))))
          (when retval
            (pcmpl-args-pad-or-truncate-string
             retval (- width (length string)))))))))

(defun pcmpl-args-completion-table-with-annotations (alist-or-hash
                                                     &optional metadata)
  "Create a new completion-table.
It completes like ALIST-OR-HASH and will return METADATA plus an
`annotation-function'.

ALIST-OR-HASH should be either an association list or a hash table
mapping completions to their descriptions."
  (cl-assert (not (functionp alist-or-hash)) t)
  (cl-assert (or (hash-table-p alist-or-hash)
                 (and alist-or-hash (listp alist-or-hash)))
             t)
  (let ((table (make-hash-table :test 'equal))
        (maxwidth 0)
        (min-maxwidth 6)
        (max-maxwidth 22))
    (if (not (hash-table-p alist-or-hash))
        (progn
          (setq maxwidth
                (apply #'max (mapcar (lambda (cell)
                                       (length (car cell)))
                                     alist-or-hash))
                maxwidth (max min-maxwidth (min max-maxwidth maxwidth)))
          (dolist (cell alist-or-hash)
            (let ((k (car cell))
                  (v (if (atom (cdr cell))
                         (cdr cell)
                       (cadr cell))))
              (puthash (propertize k 'help-echo v)
                       (and (eq pcmpl-args-annotation-style 'long)
                            (concat (and (wholenump (- maxwidth (length k)))
                                         (make-string (- maxwidth (length k)) ?\s))
                                    "  " v))
                       table))))
      (maphash (lambda (k _v)
                 (setq maxwidth (max maxwidth (length k))))
               alist-or-hash)
      (setq maxwidth (max min-maxwidth (min max-maxwidth maxwidth)))
      (maphash (lambda (k v)
                 (puthash (propertize k 'help-echo v)
                          (and (eq pcmpl-args-annotation-style 'long)
                               (concat (and (wholenump (- maxwidth (length k)))
                                            (make-string (- maxwidth (length k)) ?\s))
                                       "  " v))
                          table))
               alist-or-hash))
    (setq alist-or-hash nil)
    (pcmpl-args-completion-table-with-metadata
     (append (or metadata '(metadata))
             (list (cons 'annotation-function
                         (pcmpl-args-make-completion-annotator
                          (lambda (s)
                            (or (gethash s table)
                                (let* ((us (pcomplete-unquote-argument s))
                                       (d (gethash us table)))
                                  (cl-assert (> (length s) (length us)) t)
                                  (and d (substring d (- (length s) (length us)))))))))))
     table)))

(defun pcmpl-args-pare-completion-table (new-table old-table)
  "Return a new completion-table.
It completes like NEW-TABLE, but its output from
`all-completions' will be trimmed of any elements contained in
OLD-TABLE."
  (lambda (string pred action)
    (cond ((eq action t)
           (let ((old-comps (all-completions string old-table pred))
                 (new-comps (all-completions string new-table pred)))
             (pcomplete-pare-list (copy-sequence new-comps) old-comps)))
          (t
           (complete-with-action action new-table string pred)))))

(defun pcmpl-args-join-completion-tables (delim table-1 table-2)
  "Return a new completion-table.
It will complete like TABLE-1 unless it completes a string
containing DELIM when it will complete like TABLE-2 called the
substring following the DELIM."
  (lambda (string pred action)
    (let ((parts (and string
                      (pcmpl-args-partition-string delim string))))
      (cond ((null parts)
             (complete-with-action action table-1 string pred))

            ((eq (car-safe action) 'boundaries)
             (let* ((b0 (length (concat (elt parts 0) (elt parts 1))))
                    (b1 (length (cdr action)))
                    (subboundaries
                     (complete-with-action action table-2
                                           (elt parts 2) pred)))
               (if (eq (car-safe subboundaries) 'boundaries)
                   (cl-list* 'boundaries
                             (+ b0 (cadr subboundaries))
                             b1)
                 (cl-list* 'boundaries b0 b1))))
            ((eq action nil)
             (let ((result (complete-with-action action table-2
                                                 (elt parts 2) pred)))
               (when (stringp result)
                 (setq result (concat (elt parts 0) (elt parts 1)
                                      result)))
               result))
            (t
             (complete-with-action action table-2 (elt parts 2) pred))))))

(defun pcmpl-args-completion-table-dynamic (fun)
  "FUN is like in `completion-table-dynamic'.
It doesn't ignore metadata."
  (lambda (string pred action)
    (complete-with-action action (funcall fun string) string pred)))

(defun pcmpl-args-completion-table-inline (table delim pare)
  "Return a completion table that can complete multiple words inline.
The string is split via DELIM and the last part of the string is
completed using TABLE.  If PARE is non-nil, the completions are pared
of the previous parts."
  (let ((splitter (if (functionp delim)
                      delim
                    (lambda (s)
                      (split-string s delim)))))
    (lambda (string pred action)
      (let* ((parts (funcall splitter string))
             (s1 (substring string 0 (- (length string)
                                        (length (car (last parts))))))
             (s2 (car (last parts))))
        (complete-with-action
         action
         (if pare
             (pcmpl-args-pare-completion-table
              (apply-partially 'completion-table-with-context s1 table)
              parts)
           (apply-partially 'completion-table-with-context s1 table))
         s2 pred)))))

(defun pcmpl-args-symbolic-permissions-completion-table (string pred action)
  "Complete symbolic-permission STRING, like those used by `chmod'."
  ;; [ugoa]*([-+=]([rwxXst]*|[ugo]))+
  (let ((pare-string string)
        tbl)
    (if (string-match "\\`.*[-+=]" string)
        (setq pare-string (substring string (match-end 0))
              tbl
              '(("r" "read")
                ("w" "write")
                ("x" "execute (or search for directories)")
                ("X" "execute/search only if the file is a directory")
                ("s" "set user or group ID on execution")
                ("t" "restricted deletion flag or sticky bit")
                ("u" "user's current permissions")
                ("g" "group's current permissions")
                ("o" "other's current permissions")))
      (setq pare-string string
            tbl
            '(("u" "user who owns it")
              ("g" "users in group")
              ("o" "other users")
              ("a" "all users")
              ("+" "add file mode bits")
              ("-" "remove file mode bits")
              ("=" "set file mode bits"))))
    (setq tbl (pcmpl-args-completion-table-inline
               (pcmpl-args-pare-completion-table
                (pcmpl-args-completion-table-with-annotations tbl)
                (split-string pare-string "" t))
               "" nil))
    (complete-with-action action tbl string pred)))

(declare-function shell--command-completion-data "shell")

(defun pcmpl-args-shell-command-completions ()
  "Return a completion-table that completes the name of shell commands."
  (elt (shell--command-completion-data) 2))

(defun pcmpl-args-environment-variable-completions ()
  "Return a completion-table that completes the name of environment variables."
  (delq nil (mapcar (lambda (s)
                      (substring s 0 (string-match "=" s)))
                    process-environment)))

(defun pcmpl-args-printf-sequence-completions (sequences)
  "Return a completion-table that completes printf style SEQUENCES."
  (lambda (string pred action)
    (complete-with-action
     action (apply-partially
             'completion-table-with-context string
             (pcmpl-args-completion-table-with-annotations
              (if (or (string-match "\\`[^%]*\\'" string)
                      (string-match "\\`.*%[^a-zA-Z]*[a-zA-Z][^%]*\\'" string))
                  sequences
                (mapcar (lambda (cell)
                          (list (substring (car cell) 1)
                                (cadr cell)))
                        sequences))))
     "" pred)))

(defun pcmpl-args-size-suffix-completions (&optional suffixes)
  "Return a completion-table that completes size SUFFIXES."
  (setq suffixes (or suffixes
                     '(("c" "1")
                       ("w" "2")
                       ("b" "512")
                       ("K" "1024")
                       ("M" "1024^2")
                       ("G" "1024^3")
                       ("T" "1024^4")
                       ("P" "1024^5")
                       ("E" "1024^6")
                       ("Z" "1024^7")
                       ("Y" "1024^8")
                       ("kB" "1000")
                       ("MB" "1000*1000")
                       ("GB" "1000*1000*1000"))))
  (lambda (string pred action)
    (let* ((prefix (and (string-match "\\`[0-9]*" string)
                        (match-string 0 string)))
           (suffix (substring string (length prefix))))
      (complete-with-action
       action (apply-partially
               'completion-table-with-context prefix
               (pcmpl-args-completion-table-with-annotations
                suffixes))
       suffix pred))))


(defvar pcmpl-args-word-function
  (lambda (w)
    (when (not (equal w ""))
      (delq nil
            (mapcar (lambda (l)
                      (and (string-match ".*\t\\(.*\\)\\'" l)
                           (match-string 1 l)))
                    (pcmpl-args-process-lines "dict" "-f" "-m" "-s" "prefix" "--" w)))))
  "Function called to generate a list of words.
Function is called with one argument, the word to complete.")

(defun pcmpl-args-word-completions (w)
  (funcall pcmpl-args-word-function w))


;;; Pcomplete completion functions

(defun pcmpl-args-pcomplete (argspecs)
  "Complete the current pcomplete arguments according to ARGSPECS.
Does not return.  Throws the tag `pcomplete-completions' with the
value of the completion-table found by calling
`pcmpl-args-parse-arguments' with the current value of
`pcomplete-args' and ARGSPECS.

ARGSPECS should be value a created with
`pcmpl-args-make-argspecs'."
  (noreturn
   (progn
     (pcmpl-args-debug "\n\n================================")
     (cl-assert (= pcomplete-last (1- (length pcomplete-args))) t)
     (let* ((result (pcmpl-args-parse-arguments (cdr pcomplete-args) argspecs))
            (seen (elt result 2))
            (stub (plist-get (car seen) :stub))
            (action (plist-get (car seen) :action))
            (metavar (elt action 0))
            (suffix (or (elt action 2) " "))
            (form (elt action 1))
            alist)
       (cl-assert (memq :stub (car seen)) t)
       (dolist (s seen)
         (dolist (name (cons (plist-get s :name)
                             (plist-get (plist-get s :argspec) :aliases)))
           (let* ((cell (or (assoc name alist)
                            (assoc name (push (list name)
                                              alist))))
                  (vals (plist-get s :values)))
             (setcdr cell (append (list vals) (cdr cell))))))

       (let ((state (append (list :alist alist) (car seen))))
         (pcmpl-args-debug "== State ==")
         (let ((tmp state))
           (while tmp
             (if (eq (car tmp) :action)
                 (let ((print-length 10))
                   (pcmpl-args-debug "%S %S" (pop tmp) (pop tmp)))
               (pcmpl-args-debug "%S %S" (pop tmp) (pop tmp))))
           (pcmpl-args-debug ""))

         (while (< pcomplete-index (1- (length pcomplete-args)))
           (pcomplete-next-arg))

         (setq pcomplete-stub stub)
         (set (make-local-variable 'pcomplete-termination-string)
              (or suffix " "))
         (when (eq form t)
           (setq form (pcmpl-args-guess-completions
                       (plist-get (car seen) :name) metavar)))
         (throw 'pcomplete-completions
                (pcase form
                  (`none
                   (setq pcomplete-termination-string "")
                   (lambda (_s _p a)
                     (cond ((or (eq a 'lambda)
                                (eq a nil))
                            t)
                           (t
                            nil))))
                  (`(:eval . ,rest)
                   (when (cdr rest)
                     (error "Extra forms in action: %S" form))
                   (eval (car rest) t))
                  (`(:lambda . ,rest)
                   (funcall (car rest) alist))
                  (table table))))))))

(defun pcmpl-args-pcomplete-on-help ()
  "Perform completion on the help output of the current command.
The current command is called with one option `--help' and its
output is processed via `pcmpl-args-parse-help-buffer'.

This function can be used to define option completion for
different commands.  For example:

    \(defalias 'pcomplete/my-command 'pcmpl-args-pcomplete-on-help)

will create a completion handler for `my-command' using the
options found in its help output (assuming that `my-command'
recognizes the `--help' option)."
  (let ((shell-command (concat (car pcomplete-args) " --help")))
    (pcmpl-args-pcomplete
     (pcmpl-args-cached shell-command t
                        (pcmpl-args-make-argspecs
                         (append
                          (pcmpl-args-extract-argspecs-from-shell-command shell-command)
                          `((argument * (("FILE" t))))))))))

(defun pcmpl-args-pcomplete-on-man ()
  "Perform pcomplete completion based on the current command's man page.
The manual of current command is generated by calling
`pcmpl-args-man-function' and is processed via
`pcmpl-args-parse-help-buffer'.

This function can be used to define option completion for
different commands.  For example:

    \(defalias 'pcomplete/my-command 'pcmpl-args-pcomplete-on-man)

will create a completion handler for `my-command' using the
options found in its man page."
  (pcmpl-args-pcomplete
   (pcmpl-args-cached (car pcomplete-args) t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage (car pcomplete-args))
                        `((argument * (("FILE" t)))))))))


(defun pcmpl-args-command-subparser (args specs seen)
  "Argument subparser to handle commands that invoke other commands."
  (pcmpl-args-debug "Command subparser called with args: %S" args)
  (cl-assert (and args) t)
  (let (xargs)
    (while args
      (push (pop args) xargs))
    (setq xargs (nreverse xargs))
    (push (list :name (plist-get (car seen) :stub)
                :argspec (plist-get (car seen) :argspec)
                :stub (car (last xargs))
                :action `("COMMAND"
                          (:lambda
                           ,(lambda (_alist)
                              (if (> (length xargs) 1)
                                  (or (pcmpl-args-completions-with-context xargs)
                                      (throw 'pcomplete-completions nil))
                                (throw 'pcomplete-completions
                                       (pcmpl-args-shell-command-completions))))))
                :values xargs)
          seen)
    (list args specs seen)))


;; Completion for coreutils
;; basename cat chgrp chmod chown chroot cksum comm cp csplit cut
;; date dd df dir dircolors dirname du echo env expand expr factor
;; false fmt fold groups head hostid id install join link ln logname
;; ls md5sum mkdir mkfifo mknod mktemp mv nice nl nohup od paste
;; pathchk pinky pr printenv printf ptx pwd readlink rm rmdir
;; sha1sum seq shred sleep sort split stat stty sum sync tac tail
;; tee test touch tr true tsort tty uname unexpand uniq unlink users
;; vdir wc who whoami yes

;; Redefines version in `pcmpl-unix.el'.
(defun pcomplete/chgrp ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (pcmpl-args-extract-argspecs-from-manpage "chgrp")
     `((argument 0 (("GROUP" t)))
       (argument * (("FILE" t))))))))

(defun pcomplete/chmod ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    `((argument 0 (("MODE" pcmpl-args-symbolic-permissions-completion-table)))
      (argument * (("FILE" t)))))))

;; Redefines version in `pcmpl-unix.el'.
(defun pcomplete/chown ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (pcmpl-args-extract-argspecs-from-manpage "chown")
     `((argument 0 (("OWNER:GROUP" t)))
       (argument * (("FILE" t)))))
    :hints
    `(("\\`\\(0\\|--from\\)="
       (:eval (pcmpl-args-join-completion-tables
               ":" (pcmpl-unix-user-names) (pcmpl-unix-group-names))))))))

(defun pcomplete/chroot ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (pcmpl-args-extract-argspecs-from-manpage "chroot")
     `((argument 0 (("COMMAND" nil))
                 :subparser pcmpl-args-command-subparser))))))

(defalias 'pcomplete/cp #'pcomplete/mv)

(defvar pcmpl-args-date-format-sequences
  '(("%%" "a literal %")
    ("%a" "locale's abbreviated weekday name (e.g., Sun)")
    ("%A" "locale's full weekday name (e.g., Sunday)")
    ("%b" "locale's abbreviated month name (e.g., Jan)")
    ("%B" "locale's full month name (e.g., January)")
    ("%c" "locale's date and time (e.g., Thu Mar  3 23:05:25 2005)")
    ("%C" "century       ; like %Y, except omit last two digits (e.g., 20)") ;
    ("%d" "day of month (e.g, 01)")
    ("%D" "date; same as %m/%d/%y")
    ("%e" "day of month, space padded; same as %_d")
    ("%F" "full date; same as %Y-%m-%d")
    ("%g" "last two digits of year of ISO week number (see %G)")
    ("%G" "year of ISO week number (see %V); normally useful only with %V")
    ("%h" "same as %b")
    ("%H" "hour (00..23)")
    ("%I" "hour (01..12)")
    ("%j" "day of year (001..366)")
    ("%k" "hour ( 0..23)")
    ("%l" "hour ( 1..12)")
    ("%m" "month (01..12)")
    ("%M" "minute (00..59)")
    ("%n" "a newline")
    ("%N" "nanoseconds (000000000..999999999)")
    ("%p" "locale's equivalent of either AM or PM; blank if not known")
    ("%P" "like %p, but lower case")
    ("%r" "locale's 12-hour clock time (e.g., 11:11:04 PM)")
    ("%R" "24-hour hour and minute; same as %H:%M")
    ("%s" "seconds since 1970-01-01 00:00:00 UTC")
    ("%S" "second (00..60)")
    ("%t" "a tab")
    ("%T" "time; same as %H:%M:%S")
    ("%u" "day of week (1..7); 1 is Monday")
    ("%U" "week number of year, with Sunday as first day of week (00..53)")
    ("%V" "ISO week number, with Monday as first day of week (01..53)")
    ("%w" "day of week (0..6); 0 is Sunday")
    ("%W" "week number of year, with Monday as first day of week (00..53)")
    ("%x" "locale's date representation (e.g., 12/31/99)")
    ("%X" "locale's time representation (e.g., 23:13:48)")
    ("%y" "last two digits of year (00..99)")
    ("%Y" "year")
    ("%z" "+hhmm numeric timezone (e.g., -0400)")
    ("%:z" "+hh:mm numeric timezone (e.g., -04:00)")
    ("%::z" "+hh:mm:ss numeric time zone (e.g., -04:00:00)")
    ("%:::z" "numeric time zone with : to necessary precision (e.g., -04, +05:30)")
    ("%Z" "alphabetic time zone abbreviation (e.g., EDT)")))

(defun pcomplete/date ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'date t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage "date")
                        `((argument * (("FORMAT"
                                        (:eval
                                         (pcmpl-args-printf-sequence-completions
                                          pcmpl-args-date-format-sequences))))
                                    :excludes (-))))))))

(defun pcomplete/dd ()
  (while t
    (let ((rh (pcomplete-arg))
          lh)
      (if (not (string-match "\\`\\(.*\\)=\\(.*\\)\\'" rh))
          (progn
            (set (make-local-variable 'pcomplete-termination-string) "")
            (pcomplete-here*
             (pcmpl-args-completion-table-with-annotations
              '(("bs=" "BYTES - read and write BYTES bytes at a time")
                ("cbs=" "BYTES - convert BYTES bytes at a time")
                ("conv=" "CONVS - convert the file as per the comma separated symbol list")
                ("count=" "BLOCKS - copy only BLOCKS input blocks")
                ("ibs=" "BYTES - read BYTES bytes at a time (default: 512)")
                ("if=" "FILE - read from FILE instead of stdin")
                ("iflag=" "FLAGS - read as per the comma separated symbol list")
                ("obs=" "BYTES - write BYTES bytes at a time (default: 512)")
                ("of=" "FILE - write to FILE instead of stdout")
                ("oflag=" "FLAGS - write as per the comma separated symbol list")
                ("seek=" "BLOCKS - skip BLOCKS obs-sized blocks at start of output")
                ("skip=" "BLOCKS - skip BLOCKS ibs-sized blocks at start of input")
                ("status=noxfer" "suppress transfer statistics")))
             nil t))
        (setq lh (match-string 2 rh)
              rh (match-string 1 rh))
        (cond ((string-match "\\`\\(if\\|of\\)\\'" rh)
               (pcomplete-here* (pcomplete-entries) lh t))
              ((string-match "\\`\\(iflag\\|oflag\\)\\'" rh)
               (pcomplete-here*
                (pcmpl-args-completion-table-with-annotations
                 '(("append" "append mode (makes sense only for output; conv=notrunc suggested)")
                   ("direct" "use direct I/O for data")
                   ("directory" "fail unless a directory")
                   ("dsync" "use synchronized I/O for data")
                   ("sync" "likewise, but also for metadata")
                   ("fullblock" "accumulate full blocks of input (iflag only)")
                   ("nonblock" "use non-blocking I/O")
                   ("noatime" "do not update access time")
                   ("noctty" "do not assign controlling terminal from file")
                   ("nofollow" "do not follow symlinks")))
                lh t))
              ((string-match "\\`\\(conv\\)\\'" rh)
               (pcomplete-here*
                (pcmpl-args-completion-table-with-annotations
                 '(("ascii" "from EBCDIC to ASCII")
                   ("ebcdic" "from ASCII to EBCDIC")
                   ("ibm" "from ASCII to alternate EBCDIC")
                   ("block" "pad newline-terminated records with spaces to cbs-size")
                   ("unblock" "replace trailing spaces in cbs-size records with newline")
                   ("lcase" "change upper case to lower case")
                   ("nocreat" "do not create the output file")
                   ("excl" "fail if the output file already exists")
                   ("notrunc" "do not truncate the output file")
                   ("ucase" "change lower case to upper case")
                   ("swab" "swap every pair of input bytes")
                   ("noerror" "continue after read errors")
                   ("sync" "pad every input block with NULs to ibs-size")
                   ("fdatasync" "physically write output file data before finishing")
                   ("fsync" "likewise, but also write metadata")))
                lh t))
              (t
               (string-match "\\`[0-9]*\\([^0-9]*\\)\\'" lh)
               (setq lh (match-string 1 lh))
               (pcomplete-here*
                (pcmpl-args-size-suffix-completions)
                lh t)))))))

(defalias 'pcomplete/dir #'pcomplete/ls)

(defun pcomplete/echo ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    `((option "-n    do not output the trailing newline")
      (option "-e    enable interpretation of backslash escapes")
      (option "-E    disable interpretation of backslash escapes (default)")
      (argument * (("STRING" t)))))))

(defun pcomplete/env ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (pcmpl-args-extract-argspecs-from-manpage "env")
     `((argument 0 (("COMMAND" nil))
                 :subparser pcmpl-args-command-subparser))))))

(defalias 'pcomplete/false #'pcomplete/true)

(defun pcomplete/groups ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (pcmpl-args-extract-argspecs-from-manpage "groups")
     `((argument * (("USERNAME" (:eval (pcmpl-unix-user-names))))))))))

(defalias 'pcomplete/id #'pcomplete/groups)

(defalias 'pcomplete/ln #'pcomplete/mv)

(defun pcomplete/ls ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'ls t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage "ls")
                        `((argument * (("FILE" t)))))
                       :hints
                       '(("\\`--colou?r=" ("yes" "no" "always" "never" "auto"))
                         ("\\`--format=" ("across" "commas" "horizontal" "long"
                                          "single-column" "verbose" "vertical"))
                         ("\\`--indicator-style=" ("none" "slash" "file-type" "classify"))
                         ("\\`--quoting-style=" ("literal" "locale" "shell"
                                                 "shell-always" "c" "escape"))
                         ("\\`--sort=" ("none" "extension" "size" "time" "version"))
                         ("\\`--time=" ("atime" "access" "use" "ctime" "status"))
                         ("\\`--time-style=" ("full-iso" "long-iso" "iso" "locale"
                                              "posix-full-iso" "posix-long-iso"
                                              "posix-iso" "posix-locale"))
                         ("=\\(COLS\\|cols\\)\\'" none))))))

(defun pcomplete/mv ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'mv t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage "mv")
                        `((argument * (("FILE" t)))))
                       :hints
                       `(("\\`--backup=" ("none" "off" "numbered" "t"
                                          "existing" "nil" "simple" "never")))))))

(defun pcomplete/nice ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (pcmpl-args-extract-argspecs-from-manpage "nice")
     `((argument 0 (("COMMAND" nil))
                 :subparser pcmpl-args-command-subparser))))))

(defun pcomplete/nohup ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    `((argument 0 (("COMMAND" nil))
                :subparser pcmpl-args-command-subparser)))))

(defun pcomplete/printenv ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    `((argument
       * (("VARIABLE"
           (:eval (pcmpl-args-environment-variable-completions)))))))))

(defvar pcmpl-args-printf-sequences
  '(("% " "leave one space in front of positive number")
    ("%-" "left adjust result")
    ("%." "precision")
    ("%*" "field width in next argument")
    ("%#" "alternate form")
    ("%%" "a percent sign")
    ("%+" "always place sign before a number from signed conversion")
    ("%0" "zeropad to length n")
    ("%b" "as %s but interpret escape sequences in argument")
    ("%c" "print the first character of the argument")
    ("%E" "double number in scientific notation")
    ("%e" "double number in scientific notation")
    ("%f" "double number")
    ("%G" "double number as %f or %e depending on size")
    ("%g" "double number as %f or %e depending on size")
    ("%i" "signed decimal number")
    ("%d" "signed decimal number")
    ("%n" "store number of printed bytes in parameter specified by argument")
    ("%o" "unsigned octal number")
    ("%q" "as %s but shell quote result")
    ("%s" "print the argument as a string")
    ("%u" "unsigned decimal number")
    ("%X" "unsigned uppercase hexadecimal number")
    ("%x" "unsigned lowercase hexadecimal number")))

(defun pcomplete/printf ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    `((argument
       0 (("FORMAT" (:eval
                     (pcmpl-args-printf-sequence-completions
                      pcmpl-args-printf-sequences)))))
      (argument * (("FILE" t)))))))

;; Redefines version in `pcmpl-unix.el'.
(defalias 'pcomplete/rm #'pcmpl-args-pcomplete-on-man)

;; Redefines version in `pcmpl-unix.el'.
(defun pcomplete/rmdir ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (pcmpl-args-extract-argspecs-from-manpage "rmdir")
     `((argument * (("DIRECTORY" t))))))))

(defun pcomplete/sort ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (pcmpl-args-extract-argspecs-from-manpage "sort")
     `((argument * (("FILE" t)))))
    :hints
    `(("\\`--sort=" ("general-numeric" "month" "numeric"
                     "random" "version"))))))

(defun pcomplete/stat ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (pcmpl-args-extract-argspecs-from-manpage "stat")
     `((argument * (("FILE" t)))))
    :hints
    `(("=FORMAT"
       (:lambda
        (lambda (alist)
          (pcmpl-args-printf-sequence-completions
           (if (or (assoc "-f" alist)
                   (assoc "--file-system" alist))
               '(("%a" "Free blocks available to non-superuser")
                 ("%b" "Total data blocks in file system")
                 ("%c" "Total file nodes in file system")
                 ("%d" "Free file nodes in file system")
                 ("%f" "Free blocks in file system")
                 ("%C" "SELinux security context string")
                 ("%i" "File System ID in hex")
                 ("%l" "Maximum length of filenames")
                 ("%n" "File name")
                 ("%s" "Block size (for faster transfers)")
                 ("%S" "Fundamental block size (for block counts)")
                 ("%t" "Type in hex")
                 ("%T" "Type in human readable form"))
             '(("%a" "Access rights in octal")
               ("%A" "Access rights in human readable form")
               ("%b" "Number of blocks allocated (see %B)")
               ("%B" "The size in bytes of each block reported by %b")
               ("%C" "SELinux security context string")
               ("%d" "Device number in decimal")
               ("%D" "Device number in hex")
               ("%f" "Raw mode in hex")
               ("%F" "File type")
               ("%g" "Group ID of owner")
               ("%G" "Group name of owner")
               ("%h" "Number of hard links")
               ("%i" "Inode number")
               ("%n" "File name")
               ("%N" "Quoted file name with dereference if symbolic link")
               ("%o" "I/O block size")
               ("%s" "Total size, in bytes")
               ("%t" "Major device type in hex")
               ("%T" "Minor device type in hex")
               ("%u" "User ID of owner")
               ("%U" "User name of owner")
               ("%x" "Time of last access")
               ("%X" "Time of last access as seconds since Epoch")
               ("%y" "Time of last modification")
               ("%Y" "Time of last modification as seconds since Epoch")
               ("%z" "Time of last change")
               ("%Z" "Time of last change as seconds since Epoch")))))))))))

(defun pcomplete/test ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (with-temp-buffer
       (insert "
    -a FILE      existing file
    -b FILE      block special file
    -c FILE      character special file
    -d FILE      directory
    -e FILE      existing file
    -f FILE      regular file
    -g FILE      setgid bit
    -G FILE      group owned file
    -k FILE      sticky bit
    -h FILE      symbolic link
    -L FILE      symbolic link
    -n FILE      non empty string
    -N FILE      unread file
    -o OPTION      option
    -O FILE      own file
    -p FILE      named pipe
    -r FILE      readable file
    -s FILE      non empty file
    -S FILE      socket
    -t FILE      terminal file descriptor
    -u FILE      setuid bit
    -w FILE      writable file
    -x FILE      executable file
    -z FILE      empty string

    -ef FILE     same file
    -eq FILE     numerically equal
    -ge FILE     numerically greater than or equal
    -gt FILE     numerically greater than
    -le FILE     numerically less than or equal
    -lt FILE     numerically less than
    -ne FILE     numerically not equal
    -nt FILE     newer than
    -ot FILE     older than")
       (pcmpl-args-extract-argspecs-from-buffer))
     `((argument * (("FILE" t))))))))

(defun pcomplete/true ())

(defalias 'pcomplete/vdir #'pcomplete/ls)

(defalias 'pcomplete/basename #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/cat #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/cksum #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/comm #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/csplit #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/cut #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/df #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/dircolors #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/dirname #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/du #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/expand #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/expr #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/factor #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/fmt #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/fold #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/head #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/hostid #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/install #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/join #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/link #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/logname #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/md5sum #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/mkdir #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/mkfifo #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/mknod #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/mktemp #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/nl #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/od #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/paste #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/pathchk #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/pinky #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/pr #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/ptx #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/pwd #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/readlink #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/seq #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/sha1sum #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/shred #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/sleep #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/split #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/stty #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/sum #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/sync #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/tac #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/tail #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/tee #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/touch #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/tr #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/tsort #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/tty #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/uname #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/unexpand #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/uniq #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/unlink #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/users #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/wc #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/whoami #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/who #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/yes #'pcmpl-args-pcomplete-on-man)


;; Man page completion

(defun pcmpl-args-man-completion-table (string pred action)
  (cond
   ((eq action 'metadata)
    `(metadata (category . manual)
               (annotation-function
                . ,(pcmpl-args-make-completion-annotator
                    (lambda (s)
                      (get-text-property (1- (length s)) 'help-echo s))))))
   (t
    (complete-with-action
     action
     (mapcar (lambda (cell)
               (propertize (car cell) 'help-echo (cdr cell)))
             (pcmpl-args--man-get-data))
     string pred))))

(defun pcmpl-args--man-get-data ()
  (pcmpl-args-cached 'man-data 60
                     (let (table)
                       (dolist (l (let ((process-environment process-environment))
                                    (push "MANWIDTH=1000" process-environment)
                                    (pcmpl-args-process-lines "man" "-k" ".")))
                         (or (string-match
                              "\\`\\([^ ]+\\)\\(.*\\)\\'" l)
                             (error "Bad apropos"))
                         (let* ((page (match-string 1 l))
                                (desc (match-string 2 l)))
                           (push (cons page (if (equal pcmpl-args-annotation-style 'long)
                                                desc
                                              (when (string-match "\\`\\([ ]+(.*?)\\)" desc)
                                                (match-string 1 desc))))
                                 table)))
                       (dolist (section
                                '(("1" "Executable programs or shell commands")
                                  ("2" "System calls (functions provided by the kernel)")
                                  ("3" "Library calls (functions within program libraries)")
                                  ("4" "Special files (usually found in /dev)")
                                  ("5" "File formats and conventions eg /etc/passwd")
                                  ("6" "Games")
                                  ("7" "Miscellaneous")
                                  ("8" "System administration commands (usually only for root)")
                                  ("9" "Kernel routines [Non standard]")))
                         (push (cons (car section)
                                     (when (equal pcmpl-args-annotation-style 'long)
                                       (concat "                    - " (cadr section))))
                               table))
                       table)))

(defun pcomplete/man ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'man t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage "man")
                        `((argument
                           * (("MAN-PAGE-OR-SECTION" pcmpl-args-man-completion-table)
                              ("MAN-PAGE"
                               (:lambda
                                ,(lambda (alist)
                                   (let ((section (car (last (cadr (assoc '* alist)) 2))))
                                     (if (not (string-match "\\`[0-9]" section))
                                         'pcmpl-args-man-completion-table
                                       (apply-partially
                                        'completion-table-with-predicate
                                        'pcmpl-args-man-completion-table
                                        (lambda (c)
                                          (string-match (concat "(" (regexp-quote section) ")")
                                                        (or (get-text-property (1- (length c)) 'help-echo c)
                                                            "(7) xxxxxxxxxxxxx")))
                                        t)))))))
                           :excludes (-))))))))


;; Info node completion

(declare-function info-initialize "info")
(declare-function Info-insert-dir "info")

(defun pcmpl-args-info-node-completions ()
  "Create a unique alist from all index entries."
  (require 'info)
  (pcmpl-args-cached 'info-node-completions t
                     (info-initialize)
                     (let ((tbl (make-hash-table :test 'equal)))
                       (with-temp-buffer
                         (with-temp-message ""
                           (Info-insert-dir))
                         (goto-char (point-min))
                         (while (re-search-forward
                                 (concat "^\\* \\(.*?\\): \\((.*?)\\(.*?\\)[.]\\)[ \t]*"
                                         "\\(\n[^*\n][ \t]*\\(?9:.*\\)\\|\\(?9:.*\\)\\)")
                                 nil t)
                           (puthash (match-string 1)
                                    (match-string 9)
                                    tbl)))
                       (pcmpl-args-completion-table-with-annotations
                        tbl `(metadata (category . info-node))))))

(defun pcomplete/info ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'info t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage "info")
                        `((argument
                           * (("NODE" (:eval (pcmpl-args-info-node-completions)))))))))))


;; find completion

(defun pcmpl-args-find-command-subparser (args specs seen)
  (if (null args)
      (list args specs seen)
    (let (xargs)
      (while (and args
                  (not (or (equal (car args) "+")
                           (equal (car args) ";"))))
        (push (pop args) xargs))
      (setq xargs (nreverse xargs))
      (let ((result (pcmpl-args-command-subparser xargs specs seen)))
        (list args (cadr result) (caddr result))))))

(defvar pcmpl-args-find-printf-sequences
  '(("%%" "A literal percent sign.")
    ("%a" "File's last access time.")
    ("%Ak" "File's last access time (format specified by k).")
    ("%b" "The amount of disk space used in 512-byte blocks.")
    ("%c" "File's last status change time.")
    ("%Ck" "File's last status change time (format specified by k).")
    ("%d" "File's depth in the directory tree.")
    ("%D" "The device number on which the file exists.")
    ("%f" "File's name with any leading directories removed.")
    ("%F" "Type of the filesystem the file is on.")
    ("%g" "File's group name.")
    ("%G" "File's numeric group ID.")
    ("%h" "Leading directories of file's name.")
    ("%H" "Command line argument under which file was found.")
    ("%i" "File's inode number (in decimal).")
    ("%k" "The amount of disk space used in 1K blocks.")
    ("%l" "Object of symbolic link (empty if not symbolic link).")
    ("%m" "File's permission bits (in octal).")
    ("%M" "File's permissions (in symbolic form).")
    ("%n" "Number of hard links to file.")
    ("%p" "File's name.")
    ("%P" "File's name with the name of the argument removed.")
    ("%s" "File's size in bytes.")
    ("%S" "File's sparseness.  (BLOCKSIZE*st_blocks / st_size).")
    ("%t" "File's last modification time.")
    ("%Tk" "File's last modification time (format specified by k).")
    ("%u" "File's user name.")
    ("%U" "File's numeric user ID.")
    ("%y" "File's type (like in ls -l).")
    ("%Y" "File's type (like %y), plus follow symlinks.")))

(defun pcomplete/find ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (mapcar
     (lambda (spec) (append spec '(:repeat t)))
     `((option "-P    Never follow symbolic links.")
       (option "-L    Follow symbolic links.")
       (option "-H    Do not follow symbolic links, except for arguments.")
       (option "-D DEBUGOPTIONS    Print diagnostic information.")
       (option "-O[LEVEL]    Enables query optimisation.")
       (option "-d    A synonym for -depth.")
       (option "-daystart    Measure times from the beginning of today.")
       (option "-depth    Process directory's contents before the directory.")
       (option "-follow    Follow symbolic links.")
       (option "-help    Print usage and exit.")
       (option "-ignore_readdir_race    No error if stat fails on found files.")
       (option "-maxdepth N    Descend at most N levels of directories.")
       (option "-mindepth N    Ignore files less than N levels of directories.")
       (option "-mount    Don't descend directories on other filesystems.")
       (option "-noignore_readdir_race    Turns off the effect of -ignore_readdir_race.")
       (option "-noleaf    Do not optimize subdirectories based on hard link count.")
       (option "-regextype TYPE    Changes the regular expression syntax.")
       (option "-version    Print the find version number and exit.")
       (option "-warn    Turn warning messages on.")
       (option "-nowarn    Turn warning messages off.")
       (option "-xdev    Don't descend directories on other filesystems.")
       (option "-amin N    File accessed N minutes ago.")
       (option "-anewer FILE    File accessed after FILE was modified.")
       (option "-atime N    File accessed N*24 hours ago.")
       (option "-cmin N    File's status changed N minutes ago.")
       (option "-cnewer FILE    File's status changed after FILE was modified.")
       (option "-ctime N    File's status changed N*24 hours ago.")
       (option "-empty    Regular file or directory is empty.")
       (option "-executable    File is executable or a directory.")
       (option "-false    Always false.")
       (option "-fstype TYPE    File is on a filesystem of type TYPE.")
       (option "-gid N    File's numeric group ID is N.")
       (option "-group GNAME    File belongs to group GNAME.")
       (option "-ilname PATTERN    Like -lname, but case insensitive.")
       (option "-iname PATTERN    Like -name, but case insensitive.")
       (option "-inum N    File has inode number N.")
       (option "-ipath PATTERN    Same way as -iwholename.")
       (option "-iregex PATTERN    Like -regex, but case insensitive.")
       (option "-iwholename PATTERN    Like -wholename, but case insensitive.")
       (option "-links N    File has N links.")
       (option "-lname PATTERN    Symbolic link whose contents match shell PATTERN.")
       (option "-mmin N    File's data was last modified N minutes ago.")
       (option "-mtime N    File's data was last modified N*24 hours ago.")
       (option "-name PATTERN    Base of file name matches PATTERN.")
       (option "-newer FILE    File was modified more recently than FILE.")
       (option "-newerXY REFERENCE    Compares timestamp of file with REFERENCE.")
       (option "-nogroup    No group corresponds to file's numeric group ID.")
       (option "-nouser    No user corresponds to file's numeric user ID.")
       (option "-path PATTERN    File name matches shell PATTERN.")
       (option "-perm MODE    File's permission bits are exactly MODE.")
       (option "-readable    Matches files which are readable.")
       (option "-regex PATTERN    File name matches regular expression PATTERN.")
       (option "-samefile NAME    File refers to the same inode as NAME.")
       (option "-size N    File uses N units of space.")
       (option "-true    Always true.")
       (option "-type C    File is of type C.")
       (option "-uid N    File's numeric user ID is N.")
       (option "-used N    File accessed N days after status changed.")
       (option "-user UNAME    File is owned by user UNAME.")
       (option "-wholename PATTERN    Same as -path.")
       (option "-writable    Matches files which are writable.")
       (option "-xtype C    Same as -type unless file is a symbolic link.")
       (option "-delete    Delete files.")
       (option "-fls FILE    Like -ls but write to FILE like -fprint.")
       (option "-fprint FILE    Print the full file name into FILE.")
       (option "-fprint0 FILE    Like -print0 but write to FILE.")
       (option "-fprintf FILE FORMAT    Like -printf but write to FILE.")
       (option "-ls    List current file in ls -dils format.")
       (option "-print    Print the full file name.")
       (option "-print0    Print the full file name followed by a null character.")
       (option "-printf FORMAT    Print format, interpreting % directives.")
       (option "-prune    Do not descend into found directories.")
       (option "-quit    Exit immediately.")
       (option "-exec" (("COMMAND {} ;" nil))
               :subparser pcmpl-args-find-command-subparser
               :help "Execute COMMAND replacing {} with the file.")
       (option "-execdir" (("COMMAND {} ;" nil))
               :subparser pcmpl-args-find-command-subparser
               :help "Like -exec, but is run in the file's directory.")
       (option "-ok" (("COMMAND ;" nil))
               :subparser pcmpl-args-find-command-subparser
               :help "Like -exec but ask the user first.")
       (option "-okdir" (("COMMAND ;" nil))
               :subparser pcmpl-args-find-command-subparser
               :help "Like -execdir but ask the user first.")))
    :hints
    `(("=FORMAT\\'" (:eval
                     (if (let (case-fold-search)
                           (string-match "\\`\\(.*%[ACT]\\)\\'" pcomplete-stub))
                         (progn (setq pcomplete-stub "")
                                (pcmpl-args-completion-table-with-annotations
                                 (mapcar (lambda (cell)
                                           (cons (substring-no-properties (car cell) 1)
                                                 (cdr cell)))
                                         pcmpl-args-date-format-sequences)))
                       (pcmpl-args-printf-sequence-completions
                        pcmpl-args-find-printf-sequences))))
      ("=UNAME\\'" (:eval (pcmpl-unix-user-names)))
      ("=GNAME\\'" (:eval (pcmpl-unix-group-names)))
      ("=DEBUGOPTIONS\\'" ("help" "tree" "stat" "opt" "rates"))
      ("\\`-regextype=" ("findutils-default" "awk" "egrep" "ed" "emacs"
                         "gnu-awk" "grep" "posix-awk" "posix-basic"
                         "posix-egrep" "posix-extended" "posix-minimal-basic"
                         "sed"))
      ("\\`-size=" (:eval (pcmpl-args-size-suffix-completions)))
      ("\\`-fstype=" (:eval (pcmpl-linux-fs-types)))
      ("\\`-perm=" pcmpl-args-symbolic-permissions-completion-table)
      ("\\`-x?type="
       (:eval (pcmpl-args-completion-table-with-annotations
               '(("b" "block (buffered) special")
                 ("c" "character (unbuffered) special")
                 ("d" "directory")
                 ("p" "named pipe (FIFO)")
                 ("f" "regular file")
                 ("l" "symbolic link")
                 ("s" "socket")
                 ("D" "door (Solaris)")))))))))


;; Shell commands that exec other commands
(defun pcomplete/command ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    `((argument 0 (("COMMAND" nil))
                :subparser pcmpl-args-command-subparser)))))

;; Redefines version in `pcmpl-unix.el'.
(defalias 'pcomplete/time #'pcomplete/command)

;; Redefines version in `pcmpl-unix.el'.
(defalias 'pcomplete/which #'pcomplete/command)

(defalias 'pcomplete/coproc #'pcomplete/command)
(defalias 'pcomplete/do #'pcomplete/command)
(defalias 'pcomplete/elif #'pcomplete/command)
(defalias 'pcomplete/else #'pcomplete/command)
(defalias 'pcomplete/exec #'pcomplete/command)
(defalias 'pcomplete/if #'pcomplete/command)
(defalias 'pcomplete/then #'pcomplete/command)
(defalias 'pcomplete/until #'pcomplete/command)
(defalias 'pcomplete/whatis #'pcomplete/command)
(defalias 'pcomplete/whence #'pcomplete/command)
(defalias 'pcomplete/where #'pcomplete/command)
(defalias 'pcomplete/whereis #'pcomplete/command)
(defalias 'pcomplete/while #'pcomplete/command)


;; Compression tools

(defun pcmpl-args--gzip-pcomplete (suffixes)
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (pcmpl-args-extract-argspecs-from-manpage (car pcomplete-args))
     `((argument * (("FILE"
                     (:lambda
                      (lambda (alist)
                        (if (or (assoc "-d" alist)
                                (assoc "--decompress" alist)
                                (assoc "-t" alist)
                                (assoc "--test" alist)
                                (assoc "-l" alist)
                                (assoc "--list" alist))
                            (pcomplete-entries (concat (regexp-opt
                                                        (split-string ,suffixes) t)
                                                       "\\'"))
                          (pcomplete-entries))))))))))))

;; Redefines version in `pcmpl-gnu.el'.
(defun pcomplete/gzip ()
  (pcmpl-args--gzip-pcomplete ".gz -gz .z -z _z .Z .tgz .taz"))

;; Redefines version in `pcmpl-gnu.el'.
(defun pcomplete/bzip2 ()
  (pcmpl-args--gzip-pcomplete ".bz2 .bz .tbz2 .tbz"))

(defun pcomplete/xz ()
  (pcmpl-args--gzip-pcomplete ".xz .lzma .txz .tlz"))


;; Tar completion

(defun pcmpl-args-tar-complete-files-in-archive (archive)
  (if (or (null archive)
          (not (file-regular-p archive))
          (not (file-readable-p archive)))
      (pcomplete-entries)
    (pcmpl-args-process-lines "tar" "tf" (expand-file-name archive))))

;; Redefines version in `pcmpl-gnu.el'.
(defun pcomplete/tar ()
  (if (pcomplete-match "\\`-" 0)
      (pcmpl-args-pcomplete
       (pcmpl-args-make-argspecs
        (append
         (pcmpl-args-extract-argspecs-from-manpage "tar")
         `((argument
            * (("FILE"
                (:lambda
                 ,(lambda (alist)
                    (let ((file (caadr (or (assoc "-f" alist)
                                           (assoc "--file" alist)))))
                      (if (or (assoc "-x" alist)
                              (assoc "--extract" alist)
                              (assoc "--get" alist)
                              (assoc "-t" alist)
                              (assoc "--list" alist))
                          (pcmpl-args-tar-complete-files-in-archive file)
                        (pcomplete-entries))))))))))))
    (pcmpl-args-pcomplete
     (pcmpl-args-make-argspecs
      `((argument
         0 (("OPTIONS"
             (:eval
              (pcmpl-args-completion-table-dynamic
               (lambda (s)
                 (let* ((tar-main-opts
                         '(("A" "append tar files to an archive")
                           ("c" "create a new archive")
                           ("d" "find differences between archive and file system")
                           ("r" "append files to the end of an archive")
                           ("t" "list the contents of an archive")
                           ("u" "only append files newer than copy in archive")
                           ("x" "extract files from an archive")))
                        (tar-non-main-opts
                         '(("g" "handle new GNU-format incremental backup")
                           ("G" "handle old GNU-format incremental backup")
                           ("n" "archive is seekable")
                           ("S" "handle sparse files efficiently")
                           ("k" "don't replace existing files when extracting")
                           ("U" "remove each file prior to extracting over it")
                           ("W" "attempt to verify the archive after writing it")
                           ("O" "extract files to standard output")
                           ("m" "don't extract file modified time")
                           ("p" "extract information about file permissions")
                           ("s" "sort names to extract to match archive")
                           ("f" "use archive file or device ARCHIVE")
                           ("F" "run script at end of each tape (implies -M)")
                           ("L" "change tape after writing NUMBER x 1024 bytes")
                           ("M" "create/list/extract multi-volume archive")
                           ("b" "BLOCKS x 512 bytes per record")
                           ("B" "reblock as we read (for 4.2BSD pipes)")
                           ("i" "ignore zeroed blocks in archive (means EOF)")
                           ("H" "create archive of the given format")
                           ("V" "create archive with volume name TEXT; at")
                           ("a" "use archive suffix to determine the compression")
                           ("I" "filter through PROG (must accept -d)")
                           ("j" "filter the archive through bzip2")
                           ("z" "filter the archive through gzip")
                           ("Z" "filter the archive through compress")
                           ("J" "filter the archive through xz")
                           ("C" "change to directory DIR")
                           ("h" "follow symlinks; archive and dump the files they")
                           ("K" "begin at member MEMBER-NAME in the archive")
                           ("N" "only store files newer than DATE-OR-FILE")
                           ("P" "don't strip leading `/'s from file names")
                           ("T" "get names to extract or create from FILE")
                           ("X" "exclude patterns listed in FILE")
                           ("l" "print a message if not all links are dumped")
                           ("R" "show block number within archive with each")
                           ("v" "verbosely list files processed")
                           ("w" "ask for confirmation for every action")
                           ("o" "when creating, same as --old-archive; when")
                           ("?" "give this help list")))
                        (lst (or (split-string s "" t) '("")))
                        tbl)
                   (cond ((dolist (main-opt tar-main-opts)
                            (when (member (car main-opt) lst)
                              (return t)))
                          (setq tbl tar-non-main-opts))
                         (t
                          (setq tbl (append tar-main-opts
                                            tar-non-main-opts))))
                   (pcmpl-args-completion-table-inline
                    (pcmpl-args-completion-table-with-annotations tbl)
                    "" t))))))))
        (argument 1 (("ARCHIVE" (:eval (pcomplete-entries)))))
        (argument
         * (("FILE" (:lambda
                     ,(lambda (alist)
                        (let* ((options (caadr (assoc 0 alist)))
                               (files (cadr (assoc 1 alist))))
                          (if (string-match-p "[xt]" options)
                              (pcmpl-args-tar-complete-files-in-archive (car files))
                            (pcomplete-entries)))))))))))))


;; Perl argument and module completion

(declare-function perldoc-modules-alist "perldoc" (&optional re-cache))

(defvar pcmpl-args-perl-debugging-flags
  '(("p" "Tokenizing and parsing (with v, displays parse stack)")
    ("s" "Stack snapshots (with v, displays all stacks)")
    ("l" "Context (loop) stack processing")
    ("t" "Trace execution")
    ("o" "Method and overloading resolution")
    ("c" "String/numeric conversions")
    ("P" "Print profiling info, preprocessor command -P, source file input state")
    ("m" "Memory and SV allocation")
    ("f" "Format processing")
    ("r" "Regular expression parsing and execution")
    ("x" "Syntax tree dump")
    ("u" "Tainting checks")
    ("U" "Unofficial, User hacking (reserved for private, unreleased use)")
    ("H" "Hash dump -- usurps values()")
    ("X" "Scratchpad allocation")
    ("D" "Cleaning up")
    ("S" "Thread synchronization")
    ("T" "Tokenising")
    ("R" "Include reference counts of dumped variables (eg when using -Ds)")
    ("J" "Do not s,t,P-debug (Jump over) opcodes within package DB")
    ("v" "Verbose: use in conjunction with other flags")
    ("C" "Copy On Write")
    ("A" "Consistency checks on internal structures")
    ("q" "quiet - currently only suppresses the \"EXECUTING\" message")))

(defvar pcmpl-args-perl-unicode-features
  '(("I" "STDIN is assumed to be in UTF-8")
    ("O" "STDOUT will be in UTF-8")
    ("E" "STDERR will be in UTF-8")
    ("S" "I + O + E")
    ("i" "UTF-8 is the default PerlIO layer for input streams")
    ("o" "UTF-8 is the default PerlIO layer for output streams")
    ("D" "i + o")
    ("A" "the @ARGV elements are expected to be strings encoded in UTF-8")
    ("L" "Make \"IOEioA\" conditional on the locale environment variables.")
    ("a" "Set ${^UTF8CACHE} to -1, to run the UTF-8 caching code in debugging mode.")))

(defun pcmpl-args-perl-modules ()
  (pcmpl-args-cached 'perl-modules 60.0
                     ;; Copied from `perldoc.el'.
                     (with-temp-buffer
                       (let ((case-fold-search nil)
                             (perldoc-inc nil)
                             (modules nil))
                         (let ((default-directory "/"))
                           (shell-command "perl -e 'print \"@INC\"'" t))
                         (goto-char (point-min))
                         (while (re-search-forward "\\(/[^ ]*\\)" nil t)
                           (let ((libdir (match-string 1)))
                             (when (not (member libdir perldoc-inc))
                               (push libdir perldoc-inc))))
                         (dolist (dir perldoc-inc)
                           (when (file-readable-p dir)
                             (erase-buffer)
                             (let ((default-directory "/"))
                               (shell-command (concat "find -L " (shell-quote-argument dir)
                                                      " -name '[A-Z]*.pm' -o -name '*.pod'") t))
                             (goto-char (point-min))
                             (while (re-search-forward
                                     (concat "^" (regexp-quote dir) "/\\(.*\\).\\(pm\\|pod\\)$") nil t)
                               (push (replace-regexp-in-string
                                      "/" "::"
                                      (replace-regexp-in-string "^pod/" "" (match-string 1)))
                                     modules))))
                         (delete-dups modules)))))

(defun pcmpl-args-perl-debugging-modules ()
  (delq nil (mapcar (lambda (mod)
                      (and (string-match "\\`Devel::\\(.+\\)\\'" mod)
                           (concat "" (match-string 1 mod))))
                    (pcmpl-args-perl-modules))))

(defun pcomplete/perl ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    `((option "-0[octal/hex]    specify record separator (\\0, if no argument)"
              (("octal/hex"
                (:eval
                 (pcmpl-args-completion-table-with-annotations
                  '(("0" "slurp files in paragraph mode")
                    ("777" "slurp files whole")))))))
      (option "-a    autosplit mode with -n or -p (splits $_ into @F)")
      (option "-C[number/list]    enables the listed Unicode features"
              (("number/list"
                (:eval (pcmpl-args-completion-table-inline
                        (pcmpl-args-completion-table-with-annotations
                         pcmpl-args-perl-unicode-features)
                        "" t)))))
      (option "-c    check syntax only (runs BEGIN and CHECK blocks)")
      (option "-d    run program under debugger")
      (option "-dt   run program with threads under debugger")
      (option "-d:[debugger]    run program under Devel::module"
              (("debugger" (:eval (pcmpl-args-perl-debugging-modules)))))
      (option "-dt:[debugger]    run program using threads under Devel::module"
              (("debugger" (:eval (pcmpl-args-perl-debugging-modules)))))
      (option "-D[number/list]    set debugging flags (argument is a bit mask or alphabets)"
              (("number/list"
                (:eval (pcmpl-args-completion-table-inline
                        (pcmpl-args-completion-table-with-annotations
                         pcmpl-args-perl-debugging-flags)
                        "" t)))))
      (option "-e, -E    one line of program (several -e's allowed, omit programfile)"
              (("code" none)) :repeat t :excludes (:))
      (option "-f    don't do $sitelib/sitecustomize.pl at startup")
      (option "-F[pattern]    split() pattern for -a switch (//'s are optional)")
      (option "-i[extension]  edit <> files in place (makes backup if extension supplied)")
      (option "-I[directory]  specify @INC/#include directory (several -I's allowed)")
      (option "-l[octnum]     enable line ending processing, specifies line terminator")
      (option "-m[module]    execute \"use module ();\" before executing program"
              (("module" (:eval (pcmpl-args-perl-modules)))))
      (option "-m-[module]    execute \"no module ();\" before executing program"
              (("module" (:eval (pcmpl-args-perl-modules)))))
      (option "-M[module]    execute \"use module ;\" before executing program"
              (("module" (:eval (pcmpl-args-perl-modules)))))
      (option "-M-[module]    execute \"no module ;\" before executing program"
              (("module" (:eval (pcmpl-args-perl-modules)))))
      (option "-n    assume \"while (<>) { ... }\" loop around program")
      (option "-p    assume loop like -n but print line also, like sed")
      (option "-P    run program through C preprocessor before compilation")
      (option "-s    enable rudimentary parsing for switches after programfile")
      (option "-S    look for programfile using PATH environment variable")
      (option "-t    enable tainting warnings")
      (option "-T    enable tainting checks")
      (option "-u    dump core after parsing program")
      (option "-U    allow unsafe operations")
      (option "-v    print version, subversion (includes VERY IMPORTANT perl info)")
      (option "-V    print configuration summary")
      (option "-V:[variable]    print a single Config.pm variable"
              (("variable" (:eval (pcmpl-args-process-lines
                                   "perl" "-MConfig" "-e"
                                   "print join('\n', keys %Config);")))))
      (option "-w    enable many useful warnings (RECOMMENDED)")
      (option "-W    enable all warnings")
      (option "-x[directory]    strip off text before #!perl line and perhaps cd to directory")
      (option "-X    disable all warnings")
      (argument 0 (("PROGRAM"
                    (:eval (pcomplete-dirs-or-entries
                            ".*\\.\\([pP]\\([Llm]\\|erl\\|od\\)\\|al\\)\\'")))))
      (argument * (("FILE" t)))))))


;; Python completion
(defun pcomplete/python ()
  ;; usage: python [option] ... [-c cmd | -m mod | file | -] [arg] ...
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    `((option "-B    don't write .py[co] files on import; also PYTHONDONTWRITEBYTECODE=x")
      (option "-c cmd    program passed in as string (terminates option list)"
              :excludes (- : *))
      (option "-d    debug output from parser; also PYTHONDEBUG=x")
      (option "-E    ignore PYTHON* environment variables (such as PYTHONPATH)")
      (option "-h    print this help message and exit (also --help)")
      (option "-i    inspect interactively after running script")
      (option "-m mod    run library module as a script (terminates option list)"
              :excludes (- : *)
              :subparser pcmpl-args-command-subparser)
      (option "-O    optimize generated bytecode slightly; also PYTHONOPTIMIZE=x")
      (option "-OO    remove doc-strings in addition to the -O optimizations")
      (option "-Q arg    division options: -Qold (default), -Qwarn, -Qwarnall, -Qnew")
      (option "-s    don't add user site directory to sys.path; also PYTHONNOUSERSITE")
      (option "-S    don't imply 'import site' on initialization")
      (option "-t    issue warnings about inconsistent tab usage (-tt: issue errors)")
      (option "-u    unbuffered binary stdout and stderr; also PYTHONUNBUFFERED=x")
      (option "-v    verbose (trace import statements); also PYTHONVERBOSE=x")
      (option "-V    print the Python version number and exit (also --version)")
      (option "-W arg    warning control; arg is action:message:category:module:lineno")
      (option "-x    skip first line of source, allowing use of non-Unix forms of #!cmd")
      (option "-3    warn about Python 3.x incompatibilities that 2to3 cannot trivially fix")
      (argument 0 (("file" (:eval (pcomplete-dirs-or-entries "\\.py.?\\'"))))
                :help "program read from script file; '-' read from stdin"
                :excludes (-))
      (argument * (("arg" nil))
                :help "arguments passed to program in sys.argv[1:]"
                :subparser pcmpl-args-command-subparser)))))


;; Bazaar completion

(defun pcmpl-args-bzr-commands (&optional topics)
  (pcmpl-args-cached (cons 'bzr-command topics) t
                     (let ((tbl (make-hash-table :test 'equal)))
                       (dolist (l (nconc (pcmpl-args-process-lines "bzr" "help" "commands")
                                         (and topics
                                              (pcmpl-args-process-lines "bzr" "help" "topics"))))
                         (when (string-match "^\\([^ \t]+?\\)[ \t]+\\(.*\\)$" l)
                           (puthash (match-string 1 l)
                                    (match-string 2 l) tbl)))
                       ;; (dolist (cmd-and-aliases
                       ;;          '(("update" "up")
                       ;;            ("status" "st" "stat")
                       ;;            ("serve" "server")
                       ;;            ("resolve" "resolved")
                       ;;            ("remove-branch" "rmbranch")
                       ;;            ("remove" "rm" "del")
                       ;;            ("mv" "move" "rename")
                       ;;            ("lp-propose-merge" "lp-submit" "lp-propose")
                       ;;            ("launchpad-open" "lp-open")
                       ;;            ("launchpad-mirror" "lp-mirror")
                       ;;            ("launchpad-login" "lp-login")
                       ;;            ("init-repository" "init-repo")
                       ;;            ("help" "?" "--help" "-?" "-h")
                       ;;            ("diff" "di" "dif")
                       ;;            ("commit" "ci" "checkin")
                       ;;            ("checkout" "co")
                       ;;            ("branch" "get" "clone")
                       ;;            ("annotate" "ann" "blame" "praise")))
                       ;;   (dolist (alias (cdr cmd-and-aliases))
                       ;;     (puthash alias (gethash (car cmd-and-aliases) tbl) tbl)))
                       (pcmpl-args-completion-table-with-annotations
                        tbl `(metadata (category . bzr-command))))))

(defun pcomplete/bzr ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    `((argument
       0 (("BZR-COMMAND" nil))
       :subparser
       (lambda (arguments argspecs seen)
         (let ((stub (pop arguments)))
           (push (list :name 0
                       :stub stub
                       :action `("BZR-CMD"
                                 (:eval (pcmpl-args-bzr-commands))))
                 seen)
           (if (null arguments)
               (list arguments argspecs seen)
             (setq argspecs
                   (when (string-match "\\`[-_[:alnum:]]+\\'" stub)
                     (ignore-errors
                       (pcmpl-args-extract-argspecs-from-shell-command
                        (concat "bzr " (shell-quote-argument stub) " --usage")))))
             (setq argspecs
                   (append
                    argspecs
                    (cond ((equal stub "help")
                           `((argument
                              * (("BZR-COMMAND"
                                  (:eval (pcmpl-args-bzr-commands t)))))))
                          (t
                           `((argument * (("FILE" t))))))))
             (list arguments (pcmpl-args-make-argspecs argspecs) seen)))))))))


;; Mercurial (hg) completion

(defun pcmpl-args-hg-commands (&optional help-topics)
  (pcmpl-args-cached (cons 'hg-command help-topics) t
                     (let ((tbl (make-hash-table :test 'equal)))
                       (with-temp-buffer
                         (pcmpl-args-process-file "hg" "help")
                         (goto-char (point-min))
                         (when (re-search-forward "commands.*" nil t)
                           (skip-chars-forward " \t\n")
                           (while (re-search-forward "^ +\\([_a-zA-Z]+\\)  +\\(.*\\)$"
                                                     (save-excursion
                                                       (re-search-forward "^[ ]*$" nil t)) t)
                             (puthash (match-string 1)
                                      (match-string 2) tbl))
                           (when help-topics
                             (while (re-search-forward "^ +\\([_a-zA-Z]+\\)  +\\(.*\\)$"
                                                       nil t)
                               (puthash (match-string 1)
                                        (match-string 2) tbl)))))
                       (pcmpl-args-completion-table-with-annotations
                        tbl `(metadata (category . hg-command))))))

(defun pcomplete/hg ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'hg t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-shell-command "hg -v help")
                        `((argument
                           0 (("HG-COMMAND" nil))
                           :subparser
                           (lambda (arguments argspecs seen)
                             (let ((stub (pop arguments)))
                               (push (list :name 0
                                           :stub stub
                                           :values (plist-get (car seen) :values)
                                           :action `("HG-CMD" (:eval (pcmpl-args-hg-commands))))
                                     seen)
                               (if (null arguments)
                                   (list arguments argspecs seen)
                                 (setq argspecs
                                       (when (string-match "\\`[-_[:alnum:]]+\\'" stub)
                                         (ignore-errors
                                           (pcmpl-args-extract-argspecs-from-shell-command
                                            (concat "hg help " (shell-quote-argument stub))))))
                                 (setq argspecs
                                       (append
                                        argspecs
                                        (cond ((equal stub "help")
                                               `((argument * (("HG-COMMAND"
                                                               (:eval (pcmpl-args-hg-commands t)))))))
                                              (t `((argument * (("FILE" t))))))))
                                 (list arguments (pcmpl-args-make-argspecs argspecs) seen)))))))))))


;; Git completion

(defvar pcmpl-args-git-commands
  '(("add" "Add file contents to the index.")
    ("am" "Apply a series of patches from a mailbox.")
    ("annotate" "Annotate file lines with commit information.")
    ("apply" "Apply a patch to files and/or to the index.")
    ("archimport" "Import an Arch repository into git.")
    ("archive" "Create an archive of files from a named tree.")
    ("bisect" "Find by binary search the change that introduced a bug.")
    ("blame" "Show what revision and author last modified each line of a file.")
    ("branch" "List, create, or delete branches.")
    ("bundle" "Move objects and refs by archive.")
    ("cat-file" "Provide content or type and size information for repository objects.")
    ("check-attr" "Display gitattributes information.")
    ("check-ref-format" "Ensures that a reference name is well formed.")
    ("checkout" "Checkout a branch or paths to the working tree.")
    ("checkout-index" "Copy files from the index to the working tree.")
    ("cherry" "Find commits not merged upstream.")
    ("cherry-pick" "Apply the change introduced by an existing commit.")
    ("citool" "Graphical alternative to git-commit.")
    ("clean" "Remove untracked files from the working tree.")
    ("clone" "Clone a repository into a new directory.")
    ("commit" "Record changes to the repository.")
    ("commit-tree" "Create a new commit object.")
    ("config" "Get and set repository or global options.")
    ("count-objects" "Count unpacked number of objects and their disk consumption.")
    ("cvsexportcommit" "Export a single commit to a CVS checkout.")
    ("cvsimport" "Salvage your data out of another SCM people love to hate.")
    ("cvsserver" "A CVS server emulator for git.")
    ("daemon" "A really simple server for git repositories.")
    ("describe" "Show the most recent tag that is reachable from a commit.")
    ("diff" "Show changes between commits, commit and working tree, etc.")
    ("diff-files" "Compares files in the working tree and the index.")
    ("diff-index" "Compares content and mode of blobs between the index and repository.")
    ("diff-tree" "Compares the content and mode of blobs found via two tree objects.")
    ("difftool" "Show changes using common diff tools.")
    ("fast-export" "Git data exporter.")
    ("fast-import" "Backend for fast Git data importers.")
    ("fetch" "Download objects and refs from another repository.")
    ("fetch-pack" "Receive missing objects from another repository.")
    ("filter-branch" "Rewrite branches.")
    ("fmt-merge-msg" "Produce a merge commit message.")
    ("for-each-ref" "Output information on each ref.")
    ("format-patch" "Prepare patches for e-mail submission.")
    ("fsck" "Verifies the connectivity and validity of the objects in the database.")
    ("gc" "Cleanup unnecessary files and optimize the local repository.")
    ("get-tar-commit-id" "Extract commit ID from an archive created using git-archive.")
    ("grep" "Print lines matching a pattern.")
    ("gui" "A portable graphical interface to Git.")
    ("hash-object" "Compute object ID and optionally creates a blob from a file.")
    ("help" "display help information about git.")
    ("http-backend" "Server side implementation of Git over HTTP.")
    ("http-fetch" "Download from a remote git repository via HTTP.")
    ("http-push" "Push objects over HTTP/DAV to another repository.")
    ("imap-send" "Send a collection of patches from stdin to an IMAP folder.")
    ("index-pack" "Build pack index file for an existing packed archive.")
    ("init" "Create an empty git repository or reinitialize an existing one.")
    ("instaweb" "Instantly browse your working repository in gitweb.")
    ("log" "Show commit logs.")
    ("lost-found" "(deprecated) Recover lost refs that luckily have not yet been pruned.")
    ("ls-files" "Show information about files in the index and the working tree.")
    ("ls-remote" "List references in a remote repository.")
    ("ls-tree" "List the contents of a tree object.")
    ("mailinfo" "Extracts patch and authorship from a single e-mail message.")
    ("mailsplit" "Simple UNIX mbox splitter program.")
    ("merge" "Join two or more development histories together.")
    ("merge-base" "Find as good common ancestors as possible for a merge.")
    ("merge-file" "Run a three-way file merge.")
    ("merge-index" "Run a merge for files needing merging.")
    ("merge-one-file" "The standard helper program to use with git-merge-index.")
    ("merge-tree" "Show three-way merge without touching index.")
    ("mergetool" "Run merge conflict resolution tools to resolve merge conflicts.")
    ("mktag" "Creates a tag object.")
    ("mktree" "Build a tree-object from ls-tree formatted text.")
    ("mv" "Move or rename a file, a directory, or a symlink.")
    ("name-rev" "Find symbolic names for given revs.")
    ("notes" "Add/inspect commit notes.")
    ("pack-objects" "Create a packed archive of objects.")
    ("pack-redundant" "Find redundant pack files.")
    ("pack-refs" "Pack heads and tags for efficient repository access.")
    ("parse-remote" "Routines to help parsing remote repository access parameters.")
    ("patch-id" "Compute unique ID for a patch.")
    ("peek-remote" "(deprecated) List the references in a remote repository.")
    ("prune" "Prune all unreachable objects from the object database.")
    ("prune-packed" "Remove extra objects that are already in pack files.")
    ("pull" "Fetch from and merge with another repository or a local branch.")
    ("push" "Update remote refs along with associated objects.")
    ("quiltimport" "Applies a quilt patchset onto the current branch.")
    ("read-tree" "Reads tree information into the index.")
    ("rebase" "Forward-port local commits to the updated upstream head.")
    ("receive-pack" "Receive what is pushed into the repository.")
    ("reflog" "Manage reflog information.")
    ("relink" "Hardlink common objects in local repositories.")
    ("remote" "manage set of tracked repositories.")
    ("repack" "Pack unpacked objects in a repository.")
    ("replace" "Create, list, delete refs to replace objects.")
    ("repo-config" "(deprecated) Get and set repository or global options.")
    ("request-pull" "Generates a summary of pending changes.")
    ("rerere" "Reuse recorded resolution of conflicted merges.")
    ("reset" "Reset current HEAD to the specified state.")
    ("rev-list" "Lists commit objects in reverse chronological order.")
    ("rev-parse" "Pick out and massage parameters.")
    ("revert" "Revert an existing commit.")
    ("rm" "Remove files from the working tree and from the index.")
    ("send-email" "Send a collection of patches as emails.")
    ("send-pack" "Push objects over git protocol to another repository.")
    ("sh-setup" "Common git shell script setup code.")
    ("shell" "Restricted login shell for GIT-only SSH access.")
    ("shortlog" "Summarize 'git log' output.")
    ("show" "Show various types of objects.")
    ("show-branch" "Show branches and their commits.")
    ("show-index" "Show packed archive index.")
    ("show-ref" "List references in a local repository.")
    ("stash" "Stash the changes in a dirty working directory away.")
    ("status" "Show the working tree status.")
    ("stripspace" "Filter out empty lines.")
    ("submodule" "Initialize, update or inspect submodules.")
    ("svn" "Bidirectional operation between a Subversion repository and git.")
    ("symbolic-ref" "Read and modify symbolic refs.")
    ("tag" "Create, list, delete or verify a tag object signed with GPG.")
    ("tar-tree" "(deprecated) Create a tar archive of the files in the named tree object.")
    ("unpack-file" "Creates a temporary file with a blob's contents.")
    ("unpack-objects" "Unpack objects from a packed archive.")
    ("update-index" "Register file contents in the working tree to the index.")
    ("update-ref" "Update the object name stored in a ref safely.")
    ("update-server-info" "Update auxiliary info file to help dumb servers.")
    ("upload-archive" "Send archive back to git-archive.")
    ("upload-pack" "Send objects packed back to git-fetch-pack.")
    ("var" "Show a git logical variable.")
    ("verify-pack" "Validate packed git archive files.")
    ("verify-tag" "Check the GPG signature of tags.")
    ("whatchanged" "Show logs with difference each commit introduces.")
    ("write-tree" "Create a tree object from the current index.")))

(defun pcmpl-args-git-commands ()
  (pcmpl-args-cached 'git-commands t
                     (with-temp-buffer
                       (pcmpl-args-process-file "git" "help" "-a")
                       (goto-char (point-min))
                       (let ((cmds (copy-sequence pcmpl-args-git-commands)))
                         (while (re-search-forward
                                 "^[\t\s]+\\([^[:space:]]+\\)[\t\s]*\\([^[:space:]]*\\)$"
                                 nil t)
                           (let ((cmd (match-string 1))
                                 (help (match-string 2)))
                             (when (member help '(nil ""))
                               (setq help "..."))
                             (unless (assoc cmd cmds)
                               (push (list cmd help) cmds))))
                         (setq cmds
                               (sort cmds (lambda (a b) (string-lessp (car a) (car b)))))
                         (pcmpl-args-completion-table-with-annotations
                          cmds `(metadata (category . git-command)))))))

(defun pcmpl-args-git-extract-argspecs-from-help (cmd)
  (pcmpl-args-cached (cons 'git-commands cmd) t
                     (ignore-errors (kill-buffer " *pcmpl-args-output*"))
                     (with-current-buffer (get-buffer-create " *pcmpl-args-output*")
                       (erase-buffer)
                       (let ((process-environment process-environment))
                         (push "MANWIDTH=10000" process-environment)
                         (pcmpl-args-process-file "git" "help" "--man" "--" cmd)
                         (goto-char (point-min))
                         (pcmpl-args-unbackspace-argspecs
                          (pcmpl-args-extract-argspecs-from-buffer))))))

(defun pcmpl-args-git-refs ()
  (pcmpl-args-process-lines "git" "rev-parse" "--abbrev-ref" "--all"))

(defun pcomplete/git ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (pcmpl-args-git-extract-argspecs-from-help "")
     `((argument 0 (("GIT-COMMAND" nil))
                 :subparser
                 (lambda (arguments argspecs seen)
                   (let ((stub (pop arguments)))
                     (push (list :name 0
                                 :stub stub
                                 :values (plist-get (car seen) :values)
                                 :action `("GIT-COMMAND" (:eval (pcmpl-args-git-commands))))
                           seen)
                     (if (null arguments)
                         (list arguments argspecs seen)
                       (setq argspecs
                             (ignore-errors
                               (pcmpl-args-git-extract-argspecs-from-help stub)))
                       (setq argspecs
                             (append
                              argspecs
                              (cond ((equal stub "help")
                                     `((argument * (("GIT-COMMAND"
                                                     (:eval (pcmpl-args-git-commands)))))))
                                    (t `((argument * (("FILE" t))))))))
                       (list arguments (pcmpl-args-make-argspecs argspecs) seen))))))))))


;; Miscellaneous commands

(defalias 'pcomplete/etags #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/ctags #'pcomplete/etags)
(defalias 'pcomplete/ctags-exuberant #'pcomplete/etags)

(defun pcomplete/cmp ()
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    (append
     (with-temp-buffer
       (insert "\n
       -b, --print-bytes
              Print differing bytes.
       -i SKIP, --ignore-initial=SKIP
              Skip the first SKIP bytes of input.
       -l, --verbose
              Output byte numbers and values of all differing bytes.
       -n LIMIT, --bytes=LIMIT
              Compare at most LIMIT bytes.
       -s, --quiet, --silent
              Output nothing; yield exit status only.
       -v, --version
              Output version info.
       --help
              Output this help.")
       (goto-char (point-min))
       (pcmpl-args-extract-argspecs-from-buffer))
     `((argument * (("FILE" t)))))
    :hints
    `(("=\\(SKIP\\|LIMIT\\)"
       (:eval (pcmpl-args-size-suffix-completions)))))))

(defun pcomplete/curl ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'curl t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage
                         "curl"
                         :filters (list
                                   (lambda ()
                                     ;; Replace options like `-o/--opt' with `-o, --opt'.
                                     (while (re-search-forward "^[ ]*-[^-]\\(/\\)--" nil t)
                                       (replace-match ", " nil nil nil 1)))))
                        `((argument * (("FILE" t)))))))))

(defun pcomplete/dict ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'dict t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage "dict")
                        `((argument
                           * (("WORD"
                               (:lambda
                                (lambda (alist)
                                  (let ((w (car (last (cadr (assoc '* alist))))))
                                    (pcmpl-args-word-completions w)))))))))))))

(defun pcomplete/enscript ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'enscript t
                      (pcmpl-args-make-argspecs
                       (append (pcmpl-args-extract-argspecs-from-manpage "enscript")
                               `((argument * (("FILE" t)))))
                       :no-shared-args t))))

(defun pcomplete/gcc ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'gcc 60.0
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage "gcc")
                        `((argument * (("FILE" t)))))))))

;; Redefines version in `pcmpl-gnu.el'.
(defun pcomplete/gdb ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'gdb t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage "gdb")
                        `((argument 0 (("EXECUTABLE-FILE" (:eval (pcomplete-executables)))))
                          (argument * (("FILE" t)))))))))

(defun pcomplete/gprof ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'gprof t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage
                         "gprof"
                         :filters (list
                                   (lambda ()
                                     ;; Remove double quotes around options
                                     (while (re-search-forward "^\\([ ]*\\)\"\\(-.*\\)\"" nil t)
                                       (replace-match "\\1\\2")))))
                        `((argument * (("FILE" t)))))))))

(defun pcomplete/grep ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'grep t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage "grep")
                        `((option ("-e" "--regexp=") (("PATTERN" none))
                                  :aliases (0)
                                  :help "use PATTERN for matching")
                          (argument 0 (("PATTERN" none)) :excludes ("-e" "--regexp="))
                          (argument * (("FILE" t)))))
                       :hints
                       `(("\\`\\(-d\\|--directories\\)=" ("read" "recurse" "skip"))
                         ("\\`--binary-files=" ("binary" "text" "without-match"))
                         ("\\`\\(-D\\|--devices\\)=" ("read" "skip"))
                         ("\\`--colou?r=" ("yes" "no" "always" "never" "auto")))))))

(defalias 'pcomplete/egrep #'pcomplete/grep)
(defalias 'pcomplete/fgrep #'pcomplete/grep)
(defalias 'pcomplete/rgrep #'pcomplete/grep)

;; Redefines version in `pcmpl-gnu.el'.
(defun pcomplete/make ()
  "Completion for GNU `make'."
  (let ((pcomplete-help "(make)Top"))
    (pcmpl-args-pcomplete
     (pcmpl-args-cached 'make t
                        (pcmpl-args-make-argspecs
                         (append
                          (pcmpl-args-extract-argspecs-from-manpage "make")
                          `((argument * (("TARGET" (:eval (completion-table-in-turn
                                                           (pcmpl-gnu-make-rule-names)
                                                           (pcomplete-entries)))))))))))))

(defun pcomplete/rsync ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'rsync t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-shell-command "rsync --help")
                        `((argument * (("FILE" t)))))))))

(defun pcomplete/sudo ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'sudo t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage "sudo")
                        `((argument 0 (("COMMAND" nil))
                                    :subparser pcmpl-args-command-subparser)))))))

(defun pcomplete/vlc ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'vlc t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-shell-command "vlc -H")
                        `((argument * (("FILE" t)))))))))


;; Redefines version in `pcmpl-unix.el'.
(defun pcomplete/xargs ()
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'xargs t
                      (pcmpl-args-make-argspecs
                       (append
                        (pcmpl-args-extract-argspecs-from-manpage "xargs")
                        `((argument 0 (("COMMAND" nil))
                                    :subparser pcmpl-args-command-subparser)))))))

(defalias 'pcomplete/configure #'pcmpl-args-pcomplete-on-help)
(defalias 'pcomplete/nosetests #'pcmpl-args-pcomplete-on-help)

(defalias 'pcomplete/a2ps #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/ack-grep #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/agrep #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/automake #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/awk #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/bash #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/bc #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/bison #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/cal #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/dc #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/diff #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/emacs #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/gawk #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/gperf #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/indent #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/locate #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/ld #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/ldd #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/m4 #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/ncal #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/netstat #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/nm #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/objcopy #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/objdump #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/patch #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/pgrep #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/ps #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/readelf #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/sed #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/shar #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/strip #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/texindex #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/traceroute #'pcmpl-args-pcomplete-on-man)
(defalias 'pcomplete/wget #'pcmpl-args-pcomplete-on-man)


;; Pass completion

(defalias 'pcmpl-args-pass-subcommands
  (pcmpl-args-completion-table-with-annotations
   '(("cp" "Copy password or directory")
     ("edit" "Insert a new password or edit an existing password")
     ("find" "List names of passwords inside the tree that match patterns")
     ("generate" "Generate new password")
     ("git" "Execute git commands")
     ("grep" "Searches inside each decrypted password file")
     ("help" "Show usage message")
     ("init" "Initialize new password storage")
     ("insert" "Insert a new password into the password store")
     ("ls" "List names of passwords")
     ("mv" "Move password or directory")
     ("rm" "Remove password or directory")
     ("show" "Decrypt and print a password")
     ("version" "Show version information"))))

(defun pcmpl-args-pass-prefix ()
  "Return password-store directory.
It is suffixed with a slash."
  (let ((directory (or (getenv "PASSWORD_STORE_DIR")
                       (expand-file-name "~/.password-store"))))
    (concat directory "/")))

(defun pcmpl-args-pass-find (&optional type)
  "Return a list of password-store entries.
By default, return all directories and files in password-store.
These can be limited by TYPE.

If TYPE is :files, return only files.  If TYPE is :directories,
return only directories."
  (let ((dir (pcmpl-args-pass-prefix)))

    (cl-labels
        ((no-git (dir) (not (string-suffix-p "/.git" dir)))
         (chop-dir (entry) (string-remove-prefix dir entry))
         (chop-ext (entry) (string-remove-suffix ".gpg" entry))
         (chop (entry) (chop-dir (chop-ext entry)))
         (dotp (file) (string-prefix-p "." (file-name-base file)))
         (gpgp (file) (string-suffix-p ".gpg" file))
         (dot-or-gpg-p (file) (or (dotp file) (gpgp file))))

      (cl-case type
        (:files
         (thread-last (directory-files-recursively dir "\\.gpg\\'" nil #'no-git t)
           (mapcar #'chop)))
        (:directories
         (thread-last (directory-files-recursively dir ".*" t #'no-git t)
           (cl-delete-if #'dot-or-gpg-p)
           (mapcar #'chop-dir)))
        (t
         (thread-last (directory-files-recursively dir ".*" t #'no-git t)
           (cl-delete-if #'dotp)
           (mapcar #'chop)))))))

(defvar epa-protocol)
(defun pcmpl-args-pass-keys (args)
  "Return a list of gpg secret keys.
This list is filtered based on `ARGS', which is an alist with
inserted command line argument.  If some gpg key was already
entered, it will be removed from returned list."
  ;; Dirty hack
  (unless (boundp 'epa-protocol)
    (require 'epa))
  (declare-function epg-list-keys "epg" (context &optional name mode))
  (declare-function epg-key-user-id-list "epg" (x))
  (declare-function epg-key-sub-key-list "epg" (x))
  (declare-function epg-sub-key-fingerprint "epg" (x))
  (declare-function epg-user-id-string "epg" (x))

  (let* ((context (epg-make-context epa-protocol))
         (keys (epg-list-keys context nil 'secret))
         (extract-fingerprints
          (lambda (key)
            (append
             (mapcar #'epg-user-id-string (epg-key-user-id-list key))
             (mapcar #'epg-sub-key-fingerprint (epg-key-sub-key-list key))))))
    (cl-set-difference (mapcan extract-fingerprints keys)
                       (cadr (assq '* args))
                       :test #'string=)))

(defun pcmpl-args-pass-subcommand-specs (subcommand)
  "Return specs for pass `SUBCOMMAND'."
  (pcase subcommand
    ("edit"
     '((argument 0 (("PASSNAME" (:eval (pcmpl-args-pass-find :files)))))))

    ("find"
     '((argument * (("PATTERN" none)))))

    ("generate"
     '((option "-n, --no-symbols" :help "Use only alphanumeric characters")
       (option "-c, --clip" :help "Copy the password to the clipboard")
       (option "-i, --in-place" :help "Only replace the first line of the password file")
       (option "-f, --force" :help "Don't prompt before overwriting an existing password")
       (argument 0 (("PASSNAME" (:eval (pcmpl-args-pass-find)))))
       (argument 1 (("PASSLENGTH" none)))))

    ((or "git" "grep")
     '((argument 0 (("CMDOPTS" none))
                 :subparser
                 (lambda (args specs seen)
                   (push (plist-get (pop seen) :stub) args)
                   (pcmpl-args-command-subparser args specs seen)))))

    ("init"
     '((option "-p, --path=SUBFOLDER" (("SUBFOLDER" (:eval (pcmpl-args-pass-find :directories))))
               :help "GPGIDs are assigned for that specific SUBFOLDER of the store")
       (argument * (("GPGID" (:lambda pcmpl-args-pass-keys))))))

    ("insert"
     '((option "-e, --echo" :help "Enable keyboard echo and don't confirm the password")
       (option "-m, --multiline" :help "Read lines until EOF or Ctrl+D is reached")
       (option "-f, --force" :help "Don't prompt before overwriting an existing password")
       (argument 0 (("PASSNAME" (:eval (pcmpl-args-pass-find)))))))

    ("ls"
     '((argument 0 (("SUBFOLDER" (:eval (pcmpl-args-pass-find :directories)))))))

    ("rm"
     '((option "-r, --recursive" :help "Delete PASSNAME recursively if it is a directory")
       (option "-f, --force" :help "Do not interactively prompt before removal")
       (argument 0 (("PASSNAME" (:eval (pcmpl-args-pass-find)))))))

    ("show"
     '((option "-c[LINENUMBER], --clip[=LINENUMBER]" (("LINENUMBER" none))
               :help "Copy the first (or specified) line to the clipboard")
       (option "-q[LINENUMBER], --qrcode[=LINENUMBER]" (("LINENUMBER" none))
               :help "Display a QR code of the first (or specified) line")
       (argument 0 (("PASSNAME" (:eval (pcmpl-args-pass-find :files)))))))

    ((or "cp" "mv")
     '((option "-f, --force" :help "Silently overwrite NEWPATH if it exists")
       (argument 0 (("OLDPATH" (:eval (pcmpl-args-pass-find)))))
       (argument 1 (("NEWPATH" (:eval (pcmpl-args-pass-find)))))))))

(defun pcomplete/pass ()
  "Pass completion."
  (pcmpl-args-pcomplete
   (pcmpl-args-make-argspecs
    '((argument 0 (("OPTIONS" nil))
                :subparser
                (lambda (arguments argspecs seen)
                  (let ((command (pop arguments)))
                    (push (list :name 0
                                :stub command
                                :values (list command)
                                :action '("COMMAND" pcmpl-args-pass-subcommands))
                          seen)
                    (when arguments
                      (let ((specs (pcmpl-args-pass-subcommand-specs command)))
                        (setq argspecs (pcmpl-args-make-argspecs specs)))))
                  (list arguments argspecs seen)))))))

(defun pcomplete/pwgen ()
  "Pwgen completion."
  (pcmpl-args-pcomplete
   (pcmpl-args-cached 'pwgen pcmpl-args-cache-max-duration
     (pcmpl-args-make-argspecs
      (append (pcmpl-args-extract-argspecs-from-manpage "pwgen")
              `((argument 0 (("pw_length" none)))
                (argument 1 (("num_pw" none)))))))))


;;; Testing

(defun pcmpl-args--debug-parse-help-buffer ()
  "Parse help in the current buffer and highlight any matches."
  (interactive)
  (let ((pcmpl-args-debug-parse-help t)
        (pcmpl-args-debug t))
    (pcmpl-args-parse-help-buffer)))

(declare-function shell-completion-vars "shell")

(defun pcmpl-args--debug-completion-at-point-data (line)
  "Return the completion data that pcomplete would generate for LINE."
  (with-temp-buffer
    (require 'shell)
    (shell-completion-vars)
    (insert line)
    (comint-completion-at-point)))

(defun pcmpl-args--debug-all-completions (line)
  "Return the completions that pcomplete would generate for LINE."
  (interactive "sDebug completions for line: ")
  (let* ((result (pcmpl-args--debug-completion-at-point-data line))
         (beg (elt result 0))
         (end (elt result 1))
         (table (elt result 2))
         (_props (nthcdr 3 result)))
    (let ((comps
           (and result
                (all-completions (substring line (1- beg) (1- end)) table))))
      (if (called-interactively-p 'interactive)
          (with-output-to-temp-buffer "*pcmpl-args-completions*"
            (display-completion-list comps))
        comps))))

(defun pcmpl-args--debug-standalone ()
  "Print completions of the current command line arguments.
To be used when running Emacs in batch mode.

Example:

    $ emacs --batch -l pcmpl-args.el -f pcmpl-args--debug-standalone 'ls -'

will print completions for `ls -'."
  (if (/= 1 (length command-line-args-left))
      (error "Expected one argument")
    (message "# Completions for %S" (car command-line-args-left)))
  (let* ((str (pop command-line-args-left))
         (result (or (pcmpl-args--debug-completion-at-point-data str)
                     (error "No completions")))
         (word (substring str (1- (elt result 0)) (1- (elt result 1))))
         (comps (all-completions word (elt result 2) nil))
         (afun (or (cdr (assoc 'annotation-function
                               (cdr (completion-metadata word (elt result 2) nil))))
                   (lambda (_) nil))))
    (dolist (c comps)
      (princ (substring-no-properties c))
      (princ "\t")
      (princ (replace-regexp-in-string "[ \t\r\f\n]*\\'"
                                       "" (or (funcall afun c) "")))
      (terpri))))

(defun pcmpl-args--debug-pcomplete-commands (&optional regexp verbose)
  "Collect statistics for pcomplete/ commands."
  (interactive (list (read-regexp "Debug pcomplete/ commands matching regexp")
                     current-prefix-arg))
  (let* ((pcmpl-args-debug t)
         (regexp (or regexp ""))
         (cmds
          (let (accum)
            ;; ;; Collect pcomplete/ commands from the current buffer.
            ;; (save-excursion
            ;;   (goto-char (point-min))
            ;;   (while (re-search-forward "\\_<pcomplete/\\(.+?\\)\\_>" nil t)
            ;;     (let ((s (match-string 0)))
            ;;       (when (fboundp (intern-soft s))
            ;;         (when (string-match-p regexp (match-string 1))
            ;;           (push (match-string-no-properties 1) accum))))))

            ;; Collect all pcomplete/ commands.
            (mapatoms
             (lambda (s)
               (when (and (fboundp s)
                          (string-match "\\`pcomplete/\\([^/]+\\)\\'"
                                        (symbol-name s))
                          (string-match-p regexp
                                          (match-string 1 (symbol-name s))))
                 (push (match-string 1 (symbol-name s)) accum))))
            (sort (delete-dups (nreverse accum)) #'string-lessp)))
         (n-cmds (length cmds))
         (start-time (float-time))
         failed-cmds)
    (pcmpl-args-cache-flush t)
    (with-current-buffer (get-buffer-create "*pcmpl-args-stats*")
      (goto-char (point-max))
      (unless (bolp) (insert "\n"))
      (insert "\n;; COMMAND   L-OPTS  S-OPTS  ARGS    SECONDS\n")
      (while cmds
        (let ((start (float-time)))
          (goto-char (point-max))
          (let* ((cmd (car cmds))
                 opt-cap-data opt-comps
                 arg-cap-data arg-comps)
            (pcmpl-args-cache-flush t)
            (condition-case err
                (setq opt-cap-data (pcmpl-args--debug-completion-at-point-data (concat cmd " -"))
                      opt-comps (all-completions "-" (elt opt-cap-data 2))
                      arg-cap-data (pcmpl-args--debug-completion-at-point-data (concat cmd " "))
                      arg-comps (all-completions "" (elt arg-cap-data 2)))
              (error
               (push (list (car cmds) opt-cap-data err) failed-cmds)))
            (let ((long 0)
                  (short 0))
              (dolist (c opt-comps)
                (if (string-prefix-p "--" c)
                    (cl-incf long)
                  (cl-incf short)))
              (insert (format "%-8s\t%S\t%S\t%S\t%f\n"
                              (car cmds)
                              long short
                              (length arg-comps)
                              (- (float-time) start)))

              (let* ((metadata (completion-metadata "-" (elt opt-cap-data 2) nil))
                     (afun (cdr (assoc 'annotation-function (cdr metadata))))
                     new-raw-argspecs
                     new-argspecs)
                (dolist (c opt-comps)
                  (push (list 'option
                              (substring-no-properties
                               (concat c (funcall (or afun (lambda (_s)
                                                             "    <no description>"))
                                                  c)))) new-raw-argspecs))
                (setq new-raw-argspecs (nreverse new-raw-argspecs)
                      new-argspecs (pcmpl-args-make-argspecs new-raw-argspecs))
                (when verbose
                  (insert
                   (pcmpl-args-format-argspecs new-argspecs)
                   "\n\n"))
                (let ((new-long 0)
                      (new-short 0))
                  (dolist (spec new-argspecs)
                    (cl-assert (and (eq 'option (plist-get spec :type))
                                    spec)
                               t)
                    (if (string-prefix-p "--" (plist-get spec :name))
                        (cl-incf new-long)
                      (cl-incf new-short)))
                  (when new-argspecs
                    (cl-assert (and (eq long new-long) new-argspecs) t))
                  (when new-argspecs
                    (cl-assert (and (eq short new-short) new-argspecs) t))))

              (pop-to-buffer "*pcmpl-args-stats*")
              (goto-char (point-max))
              (recenter -1)
              (redisplay))))
        (pop cmds))

      (when failed-cmds
        (insert "\n;; Failed commands:\n")
        (dolist (fcmd failed-cmds)
          (insert (format "%s %S\n" (elt fcmd 0) (elt fcmd 2)))))

      (insert (format "\n;; Tried %S commands in %f seconds\n"
                      n-cmds (- (float-time) start-time)))
      (pcmpl-args-cache-flush t)
      nil)))

(defun pcmpl-args--print-readme ()
  "Print the commentary in a form suitable for a README file."
  (save-excursion
    (let (header meta copyright commentary)
      (goto-char (point-min))
      (setq header
            (buffer-substring
             (progn (re-search-forward ";+ ")
                    (point))
             (progn (re-search-forward " +-\\*-")
                    (match-beginning 0))))
      (forward-line 3)
      (setq meta
            (buffer-substring (point)
                              (progn (forward-paragraph)
                                     (point)))
            copyright
            (buffer-substring (point)
                              (progn (re-search-forward "^;+ Commentary:")
                                     (forward-line -1)
                                     (point))))
      (forward-line 3)
      (setq commentary
            (buffer-substring (point)
                              (progn (re-search-forward "^;+ Code:")
                                     (forward-line -1)
                                     (point))))
      (princ (replace-regexp-in-string
              "^;;;?\\( \\| *$\\)" ""
              (concat header "\n"
                      (make-string (length header) ?=) "\n\n"
                      commentary "\n"
                      (make-string 72 ?-) "\n"
                      copyright "\n"
                      (make-string 72 ?-) "\n"
                      meta))))))

;; (ert-deftest pcmpl-args-test-make-argspecs  ()
;;   (let ((opts
;;          '((("-o") ((option "-o")))
;;            (("--output") ((option "--output")))
;;            (("-o" "--output") ((option "-o, --output")))
;;            (("-o" "--output") ((option "-o --output")))
;;            (("-o" "--output") ((option "-o , --output")))
;;            (("-o" "--output") ((option "-o,--output")))
;;            (("-o" "--output") ((option "-o , --output")))
;;            (("-o") ((option "-o ARG")))
;;            (("--output") ((option "--output ARG")))
;;            (("-o" "--output") ((option "-o ARG, --output")))
;;            (("-o" "--output") ((option "-o, --output ARG")))
;;            (("-o" "--output") ((option "-o, --output=ARG")))
;;            (("-o" "--output") ((option "-o, --output[=ARG]")))
;;            (("-o" "--output") ((option "-o, --output<ARG>")))
;;            (("-o" "--output") ((option "-o, --output[ARG]")))
;;            )))
;;     (dolist (el opts)
;;       (let* ((names (car el))
;;              (specs (cadr el))
;;              (argspecs (pcmpl-args-make-argspecs specs)))
;;         (should argspecs)
;;         (dolist (name names)
;;           (should (member name (mapcar (lambda (spec)
;;                                          (plist-get spec :name))
;;                                        argspecs))))))))
;;
;; (ert-deftest pcmpl-args-test-ls  ()
;;   (should (member "--format" (pcmpl-args--debug-all-completions "ls -")))
;;   (should (member "across" (pcmpl-args--debug-all-completions "ls --format ")))
;;   (should-not (member "--help" (pcmpl-args--debug-all-completions "ls --format --")))
;;   (should (member "yes" (pcmpl-args--debug-all-completions "ls --color=")))
;;   (unless (file-exists-p "yes")
;;     (should-not (member "yes" (pcmpl-args--debug-all-completions "ls --color ")))))
;;
;; (ert-deftest pcmpl-args-test-find  ()
;;   (should (member "-type" (pcmpl-args--debug-all-completions "find -")))
;;   (should (member "f" (pcmpl-args--debug-all-completions "find -type ")))
;;   (should-not (pcmpl-args--debug-all-completions "find -type -"))
;;   (should (member "ls" (pcmpl-args--debug-all-completions "find -exec ls")))
;;   (should (member "--format" (pcmpl-args--debug-all-completions "find -exec ls -")))
;;   (should (member "across" (pcmpl-args--debug-all-completions "find -exec ls --format ")))
;;   (should (member "-type" (pcmpl-args--debug-all-completions "find -exec ls --format + -"))))
;;
;; (ert-deftest pcmpl-args-test-xargs  ()
;;   (should (member "-0" (pcmpl-args--debug-all-completions "xargs -")))
;;   (should (member "ls" (pcmpl-args--debug-all-completions "xargs -d '\\n' ls")))
;;   (should (member "--format" (pcmpl-args--debug-all-completions "xargs -d '\\n' ls -")))
;;   (should (member "across" (pcmpl-args--debug-all-completions "xargs -d '\\n' ls --format "))))
;;
;; (ert-deftest pcmpl-args-test-bzr  ()
;;   (should (member "help" (pcmpl-args--debug-all-completions "bzr ")))
;;   (should (member "diff" (pcmpl-args--debug-all-completions "bzr help "))))
;;

;; (progn
;;   (elp-restore-all)
;;   (elp-instrument-package "pcmpl-")
;;   (elp-instrument-package "pcomplete-")
;;   t)


;;; Autoload

;; ;; Eval to generate autoloads.
;; (let (accum)
;;   (save-excursion
;;     (goto-char (point-min))
;;     (while (re-search-forward "^ *(\\(defun\\|defalias\\) +'?\\(pcomplete/.+?\\) " nil t)
;;       (cl-assert (fboundp (intern-soft (match-string-no-properties 2))) t)
;;       (push (match-string-no-properties 2) accum))
;;     (setq accum (nreverse accum))
;;     (cl-assert (= (length accum) (length (delete-dups (copy-sequence accum)))) t))
;;   (insert (format "\n\n;;;###autoload (dolist (func '(%s)) (autoload func \"pcmpl-args\"))\n"
;;                   (mapconcat 'identity accum " "))))

;;;###autoload (dolist (func '(pcomplete/chgrp pcomplete/chmod pcomplete/chown pcomplete/chroot pcomplete/cp pcomplete/date pcomplete/dd pcomplete/dir pcomplete/echo pcomplete/env pcomplete/false pcomplete/groups pcomplete/id pcomplete/ln pcomplete/ls pcomplete/mv pcomplete/nice pcomplete/nohup pcomplete/printenv pcomplete/printf pcomplete/rm pcomplete/rmdir pcomplete/sort pcomplete/stat pcomplete/test pcomplete/true pcomplete/vdir pcomplete/basename pcomplete/cat pcomplete/cksum pcomplete/comm pcomplete/csplit pcomplete/cut pcomplete/df pcomplete/dircolors pcomplete/dirname pcomplete/du pcomplete/expand pcomplete/expr pcomplete/factor pcomplete/fmt pcomplete/fold pcomplete/head pcomplete/hostid pcomplete/install pcomplete/join pcomplete/link pcomplete/logname pcomplete/md5sum pcomplete/mkdir pcomplete/mkfifo pcomplete/mknod pcomplete/mktemp pcomplete/nl pcomplete/od pcomplete/paste pcomplete/pathchk pcomplete/pinky pcomplete/pr pcomplete/ptx pcomplete/pwd pcomplete/readlink pcomplete/seq pcomplete/sha1sum pcomplete/shred pcomplete/sleep pcomplete/split pcomplete/stty pcomplete/sum pcomplete/sync pcomplete/tac pcomplete/tail pcomplete/tee pcomplete/touch pcomplete/tr pcomplete/tsort pcomplete/tty pcomplete/uname pcomplete/unexpand pcomplete/uniq pcomplete/unlink pcomplete/users pcomplete/wc pcomplete/whoami pcomplete/who pcomplete/yes pcomplete/man pcomplete/info pcomplete/find pcomplete/command pcomplete/time pcomplete/which pcomplete/coproc pcomplete/do pcomplete/elif pcomplete/else pcomplete/exec pcomplete/if pcomplete/then pcomplete/until pcomplete/whatis pcomplete/whence pcomplete/where pcomplete/whereis pcomplete/while pcomplete/gzip pcomplete/bzip2 pcomplete/xz pcomplete/tar pcomplete/perl pcomplete/python pcomplete/bzr pcomplete/hg pcomplete/git pcomplete/etags pcomplete/ctags pcomplete/ctags-exuberant pcomplete/cmp pcomplete/curl pcomplete/dict pcomplete/enscript pcomplete/gcc pcomplete/gdb pcomplete/gprof pcomplete/grep pcomplete/egrep pcomplete/fgrep pcomplete/rgrep pcomplete/make pcomplete/rsync pcomplete/sudo pcomplete/vlc pcomplete/xargs pcomplete/configure pcomplete/nosetests pcomplete/a2ps pcomplete/ack-grep pcomplete/agrep pcomplete/automake pcomplete/awk pcomplete/bash pcomplete/bc pcomplete/bison pcomplete/cal pcomplete/dc pcomplete/diff pcomplete/emacs pcomplete/gawk pcomplete/gperf pcomplete/indent pcomplete/locate pcomplete/ld pcomplete/ldd pcomplete/m4 pcomplete/ncal pcomplete/netstat pcomplete/nm pcomplete/objcopy pcomplete/objdump pcomplete/patch pcomplete/pgrep pcomplete/ps pcomplete/readelf pcomplete/sed pcomplete/shar pcomplete/strip pcomplete/texindex pcomplete/traceroute pcomplete/wget pcomplete/pass pcomplete/pwgen)) (autoload func "pcmpl-args"))

(provide 'pcmpl-args)
;;; pcmpl-args.el ends here
