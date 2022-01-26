;;; jsonnet-mode.el --- Major mode for editing jsonnet files -*- lexical-binding: t -*-

;; Copyright (C) 2017 Nick Lanham

;; Author: Nick Lanham
;; URL: https://github.com/mgyucht/jsonnet-mode
;; Package-Commit: 7c9961b084b1ea352555317076bc27a512dd341f
;; Package-Version: 20220121.2109
;; Package-X-Original-Version: 0.0.1
;; Keywords: languages
;; Package-Requires: ((emacs "24") (dash "2.17.0"))

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

;; This package provides syntax highlighting, indenting, formatting, and utility
;; methods for jsonnet files. To use it, place it somewhere in your load-path,
;; and then add the following to your init.el:
;; (load "jsonnet-mode")
;;
;; This mode creates the following keybindings:
;;   'C-c C-c' evaluates the current buffer in Jsonnet and put the output in an
;;             output buffer
;;   'C-c C-f' jumps to the definition of the identifier at point
;;   'C-c C-r' reformats the entire buffer using Jsonnet's fmt utility

;;; Code:

(require 'subr-x)
(require 'smie)
(require 'cl-extra)
(require 'dash)

(defgroup jsonnet '()
  "Major mode for editing Jsonnet files."
  :group 'languages)

(defcustom jsonnet-command
  "jsonnet"
  "Jsonnet command to run in ‘jsonnet-eval-buffer’.

See also: `jsonnet-command-options'."
  :type '(string)
  :group 'jsonnet)

(defcustom jsonnet-command-options
  '()
  "A list of options and values to pass to `jsonnet-command'.

For example:
  '(\"--ext-str\" \"foo=bar\")"
  :group 'jsonnet
  :type '(repeat string))

(defcustom jsonnet-fmt-command
  "jsonnetfmt"
  "Jsonnet format command."
  :type '(string)
  :group 'jsonnet)

(defcustom jsonnet-library-search-directories
  nil
  "Sequence of Jsonnet library search directories, with later entries shadowing earlier entries."
  :type '(repeat directory)
  :group 'jsonnet)

(defcustom jsonnet-enable-debug-print
  nil
  "If non-nil, enables debug printing in ‘jsonnet-mode’ functions."
  :type '(boolean)
  :group 'jsonnet)

(defcustom jsonnet-indent-level
  2
  "Number of spaces to indent with."
  :type '(number)
  :group 'jsonnet)

(defcustom jsonnet-use-smie
  t
  "Use experimental SMIE indentation."
  :type '(boolean)
  :group 'jsonnet)

(defconst jsonnet--identifier-regexp
  "[a-zA-Z_][a-zA-Z0-9_]*"
  "Regular expression matching a Jsonnet identifier.")

(defconst jsonnet--function-name-regexp
  (concat "local \\(" jsonnet--identifier-regexp "\\)"
          "\\(([a-zA-Z0-9_, ]*)\s*=\\|\s*=\s*function\\)"))

(defconst jsonnet-font-lock-keywords-1
  (let ((builtin-regex (regexp-opt '("assert" "else" "error" "for" "function" "if" "import" "importstr" "in" "local" "self" "super" "then") 'symbols))
        (constant-regex (regexp-opt '("false" "null" "true") 'symbols))
        (function-name-regex jsonnet--function-name-regexp)
        ;; Any other local bindings are variables
        (variable-name-regex (concat "local \\(" jsonnet--identifier-regexp "\\)\s+="))
        ;; All standard library functions (see https://jsonnet.org/docs/stdlib.html)
        (standard-functions-regex (regexp-opt (mapcar (lambda (func-name) (concat "std." func-name))
                                                '("abs" "acos" "asciiLower" "asciiUpper" "asin" "assertEqual" "atan" "base64" "base64Decode" "base64DecodeBytes" "ceil" "char" "clamp" "codepoint" "cos" "count" "decodeUTF8" "deepJoin" "encodeUTF8" "endsWith" "equals" "escapeStringBash" "escapeStringDollars" "escapeStringJson" "escapeStringPython" "exp" "exponent" "extVar" "filter" "filterMap" "find" "findSubstr" "flatMap" "flattenArrays" "floor" "foldl" "foldr" "format" "isArray" "isBoolean" "isFunction" "isNumber" "isObject" "isString" "join" "length" "lines" "log" "lstripChars" "makeArray" "manifestIni" "manifestJson" "manifestJsonEx" "manifestPython" "manifestPythonVars" "manifestXmlJsonml" "manifestYamlDoc" "manifestYamlStream" "mantissa" "map" "mapWithIndex" "mapWithKey" "max" "md5" "member" "mergePatch" "min" "mod" "modulo" "native" "objectFields" "objectFieldsAll" "objectFieldsEx" "objectHas" "objectHasAll" "objectHasEx" "parseHex" "parseInt" "parseJson" "parseOctal" "pow" "primitiveEquals" "prune" "range" "repeat" "resolvePath" "reverse" "rstripChars" "set" "setDiff" "setInter" "setMember" "setUnion" "sign" "sin" "slice" "sort" "split" "splitLimit" "sqrt" "startsWith" "strReplace" "stringChars" "stripChars" "substr" "tan" "thisFile" "toString" "trace" "type" "uniq")))))
    (list
     `(,builtin-regex . font-lock-builtin-face)
     `(,constant-regex . font-lock-constant-face)
     `(,function-name-regex . (1 font-lock-function-name-face))
     `(,variable-name-regex . (1 font-lock-variable-name-face))
     '("[[:space:]].+:" . font-lock-keyword-face)
     '("\\([[:digit:]]+\\(?:\\.[[:digit:]]+\\)?\\)" . font-lock-constant-face)
     `(,standard-functions-regex . font-lock-function-name-face)
     ))
  "Minimal highlighting for ‘jsonnet-mode’.")

(defconst jsonnet-smie-grammar
  (smie-prec2->grammar
   (smie-merge-prec2s
    (smie-bnf->prec2
     '((id)
       (insts (inst) (insts ";" insts))
       (inst (exp))
       (multiline-string ("open-|||" "multiline-string" "close-|||"))
       (exp ("{" objinside "}")
            ("[" arrinside "]")
            ("[" exp "forspec-close" "]")
            ("{" exp "forspec-close" "}")
            (multiline-string)
            (exp "." id)
            ("thing-index-open" "indexinside" "]")
            ("exp-open-paren" args ")")
            (id)
            ("bind-begin" bind "bind-end")
            (ifthen)
            ("exp-open-curly" objinside "}")
            ("function" exp))
       (ifthen ("if" exp "then" exp)
               (ifthen "else" exp))
       (arrinside (exp "," exp))
       (objinside (member)
                  (objlocal)
                  (objinside "," objinside))
       (member (objlocal)
               (field)
               (member "," member))
       (field (fieldname ":" exp)
              (fieldname "::" exp)
              (fieldname ":::" exp)
              (fieldname "+" ":" exp)
              (fieldname "+" "::" exp)
              (fieldname "+" ":::" exp)
              ("fieldname-open-paren" params "fieldname-close-paren" exp))
       (fieldname (id)
                  ("[" exp "]"))
       (objlocal ("local" bind))
       (bind (id "=" exp)
             (bind "," bind))
       (args (exp)
             (id "=" exp)
             (args "," args))
       (params (param)
               (param "," param))
       (param (id)
              (id "=" exp)))
     '((assoc ";") (left "then") (left "else") (left ".") (left "local") (right "function") (assoc ","))
     '((right "=")))
    (smie-precs->prec2
     '((right "=")
       (right "<=" ">=" "==" "!=")
       (left "^" "&" "|")
       (left "<<" ">>")
       (left "&&" "||")
       (left "*" "/" "%")
       (left "+" "-"))))))

(defvar jsonnet-font-lock-keywords jsonnet-font-lock-keywords-1
  "Default highlighting expressions for jsonnet mode.")

(defconst jsonnet-multiline-string-syntax (string-to-syntax "\""))

(defconst jsonnet-multiline-string-beg-regexp "[[:space:]]*\\(|||\\)\n")

(defconst jsonnet-multiline-string-end-regexp "[[:space:]]*\\(|||\\)[[:space:]]*%?[^\n,]*")

(defun jsonnet-smie-rules (kind token)
  "SMIE rules for KIND and TOKEN."
  ;; FIXME: Needs more documentation.
  (pcase (cons kind token)
    (`(:elem . args) jsonnet-indent-level)
    (`(:after . ,(or `"{" `"[" `"("))
     (unless (smie-rule-hanging-p) jsonnet-indent-level))
    (`(:before . ,(or `"{" `"[" `"("))
     (when (smie-rule-hanging-p)
       (back-to-indentation)
       (cons 'column (current-column))))
    (`(:before . ,(or "}" "]"))
     (smie-rule-parent))
    (`(:after . ",")
     (when-let ((open-curly (jsonnet-smie--find-enclosing-delim "{")))
       (save-excursion
         (goto-char open-curly)
         (back-to-indentation)
         (cons 'column (+ (current-column) jsonnet-indent-level)))))
    (`(:after . ,(or `":" `"::" `":::"))
     (if (and (save-excursion
                (re-search-backward (rx "|||") nil t))
              (save-excursion
                (jsonnet-smie--forward-token)
                (looking-at "|||")))
         ;; FIXME: Indentation is incorrect if ||| exists anywhere
         ;; before point while indenting a multiline string.
         nil
       jsonnet-indent-level))
    (`(:after . ";")
     (when-let ((open-curly (jsonnet-smie--find-enclosing-delim "{")))
       (if (smie-rule-parent-p "{")
           jsonnet-indent-level)))
    (`(:before . "then")
     (cond
      ((save-excursion
         (and
          (re-search-backward (rx word-boundary "if" word-boundary) nil t)
          (equal (jsonnet-smie--backward-token) "else")))
       (back-to-indentation)
       (cons 'column (current-column)))
      ((re-search-backward (rx word-boundary "if" word-boundary) nil t)
       (cons 'column (current-column)))))
    (`(:after . "then")
     (cond
      ;; Return nil to handle "else if" in a `(:before . then)' rule.
      ((and (re-search-backward (rx word-boundary "if" word-boundary) nil t)
            (equal (jsonnet-smie--backward-token) "else"))
       nil)
      (t jsonnet-indent-level)))
    (`(:before . "multiline-string")
     (save-excursion
       (re-search-backward (rx "|||") nil t)
       (back-to-indentation)
       (cons 'column (+ jsonnet-indent-level (current-column)))))
    (`(:before . "close-|||")
     (save-excursion
       (re-search-backward (rx "|||") nil t)
       (back-to-indentation)
       (cons 'column (current-column))))
    (`(:after . "=")
     (cond
      ((and (smie-rule-next-p "{" "[")
            (not (smie-rule-hanging-p)))
       (save-excursion
         (beginning-of-line-text)
         (when (looking-at "local")
           (cons 'column (current-column)))))
      ((smie-rule-hanging-p)
       (save-excursion
         (beginning-of-line-text)
         (cons 'column (+ (current-column) jsonnet-indent-level))))))
    (`(:after . "else") (if (smie-rule-parent-p "then") jsonnet-indent-level))
    (`(:before . "else") (if (smie-rule-parent-p "then") (smie-rule-parent)))
    (`(:before . "function")
     (save-excursion
       (cond
        ;; function() as an argument
        ((when-let ((open-paren (jsonnet-smie--find-enclosing-delim "(")))
           (goto-char open-paren)
           (back-to-indentation)
           (cons 'column (+ (current-column) jsonnet-indent-level))))
        (t
         (back-to-indentation)
         (cons 'column (current-column))))))
    (`(:before . "(")
     (cond
      ;; Hanging open paren.
      ((and (not (smie-rule-bolp))
            (smie-rule-hanging-p))
       (beginning-of-line-text)
       (cons 'column (current-column)))
      ;; Parenthesized function argument.
      ((and (smie-rule-bolp)
            (smie-rule-prev-p "("))
       (smie-indent-backward-token)
       (beginning-of-line-text)
       (cons 'column (+ (current-column) jsonnet-indent-level)))))
    (`(:before . ")")
     (when-let ((open-paren (jsonnet-smie--find-enclosing-delim "(")))
       (goto-char open-paren)
       (back-to-indentation)
       (cons 'column (current-column))))))

(defun jsonnet-smie--forward-token ()
  "SMIE function for lexing tokens after point."
  (skip-chars-forward " \t")
  (cond
   (t
    (let ((tok (smie-default-forward-token)))
      (cond
       ((when-let ((open-bracket (jsonnet-smie--find-enclosing-delim "{" "["))
                   (looking-at-for-p (equal tok "for")))
          (search-forward-regexp (rx word-boundary "in" word-boundary) nil t)
          "forspec-close"))
       ((cond
         ;; `smie-default-forward-token' seems to return an empty
         ;; string when point is before "|||".
         ((save-excursion (and (looking-at (rx "|||"))
                               (re-search-backward (rx "|||") nil t)
                               (progn
                                 (goto-char (+ 3 (point)))
                                 (equal (syntax-ppss-context (syntax-ppss))
                                        'string))))
          (re-search-forward (rx "|||") nil t)
          "close-|||")
         ((save-excursion (and (equal tok "|||")
                               (re-search-backward (rx "|||") nil t 2)
                               (progn
                                 (goto-char (+ 3 (point)))
                                 (equal (syntax-ppss-context (syntax-ppss))
                                        'string))))
          "close-|||")))
       ((when (and (equal (syntax-ppss-context (syntax-ppss))
                          'string)
                   (save-excursion (re-search-backward (rx "|||") nil t))
                   (save-excursion (re-search-forward (rx "|||") nil t)))
          (end-of-line)
          "multiline-string"))
       (t tok))))))

(defun jsonnet-smie--backward-token ()
  "SMIE function for lexing tokens before point."
  (forward-comment (- (point)))
  (cond
   (t
    (let ((tok (smie-default-backward-token)))
      (cond
       ((when (and (looking-back (rx "|||") (- (point) 3))
                   (save-excursion (re-search-forward (rx "|||") nil t)))
          (re-search-backward "|||" nil t)
          "open-|||"))
       ((when (and (equal (syntax-ppss-context (syntax-ppss))
                          'string)
                   (save-excursion (re-search-backward (rx "|||") nil t))
                   (save-excursion (re-search-forward (rx "|||") nil t)))
          (back-to-indentation)
          "multiline-string"))
       ((when (and (looking-back ")" (1- (point)))
                   (save-excursion
                     (forward-char -1)
                     (goto-char (jsonnet-smie--find-enclosing-delim "("))
                     (skip-syntax-backward "-")
                     (skip-syntax-backward "w")
                     (looking-at "function")))
          (re-search-backward "function" nil t)
          "function"))
       (t tok))))))



(defun jsonnet-smie--indent-inside-multiline-string ()
  "Calculate indentation when point is inside a multiline string."
  (when (and (nth 3 (syntax-ppss))
             (jsonnet--find-current-multiline-string))
    (unless (looking-at "|||")
      (save-excursion
        (let* ((col (current-column))
               (multiline-string-indent (progn
                                          (search-forward-regexp "|||")
                                          (back-to-indentation)
                                          (+ (current-column) jsonnet-indent-level))))
          (if (> col multiline-string-indent)
              col
            multiline-string-indent))))))

(defun jsonnet--find-multiline-string-prefix (start)
  "Find prefix for multiline |||...||| string starting at START.
Moves point to first non-prefix character."
  (goto-char start)
  (end-of-line)
  (while (and (eolp) (not (eobp))) ; skip blank lines
    (goto-char (1+ (point)))
    (re-search-forward "^[[:space:]]*" nil 'move))
  (let ((prefix (match-string 0)))
    (if (looking-at "|\\{3\\}")
        ;; Found end delimiter already (multline string that only
        ;; contains blank lines).  Make up a prefix that won't exclude
        ;; end delimiter.
        (concat prefix " ")
      prefix)))

(defun jsonnet--font-lock-open-multiline-string (start)
  "Set syntax of jsonnet multiline |||...||| opening delimiter.
START is the position of |||.
Moves point to the first character following open delimiter."
  (let* ((ppss (save-excursion (syntax-ppss start)))
         (in-string (nth 3 ppss))
         (in-comment (nth 4 ppss)))
    (unless (or in-string in-comment)
      (let ((prefix (jsonnet--find-multiline-string-prefix start))
            (line (save-excursion
                    (next-logical-line)
                    (beginning-of-line)
                    (re-search-forward ".*$" nil t)
                    (match-string 0))))
        (while (or (string-match-p "^$" line) (string-prefix-p prefix line))
          (next-logical-line)
          (beginning-of-line)
          (save-excursion
            (re-search-forward "[[:space:]]*[^\n]*$" nil t)
            (setq line (match-string 0))))
        (when-let ((end (and (looking-at "[[:space:]]*|||")
                             (progn
                               (re-search-forward jsonnet-multiline-string-end-regexp nil t)
                               (match-end 1)))))
          (put-text-property start end
                             'font-lock-multiline t)
          ;; tell jit-lock to refontify if this block is modified
          (put-text-property start (point) 'syntax-multiline t)
          (goto-char (- end 4)))
        jsonnet-multiline-string-syntax))))

(defun jsonnet--syntax-propertize-function (start end)
  (goto-char start)
  (funcall
   (syntax-propertize-rules
    ("[[:space:]]*\\(|\\{3\\}\\)\n"
     (1 (jsonnet--font-lock-open-multiline-string (match-beginning 1))))
    ("|||" (0 jsonnet-multiline-string-syntax)))
   (point) end))

;; Syntax table
(defconst jsonnet-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; Comments. Jsonnet supports /* */ and // as comment delimiters
    (modify-syntax-entry ?/ ". 124" table)
    (modify-syntax-entry ?* ". 23b" table)
    ;; Additionally, Jsonnet supports # as a comment delimiter
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    ;; ", ', and ||| are quotations in Jsonnet.
    ;; ||| is handled by jsonnet--syntax-propertize-function
    (modify-syntax-entry ?' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    ;; Our parenthesis, braces and brackets
    (modify-syntax-entry ?\( "()" table)
    (modify-syntax-entry ?\) ")(" table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    table)
  "Syntax table for `jsonnet-mode'.")

;; Indent rules
(defun jsonnet--debug-print (str)
  "Print out STR if ‘jsonnet-enable-debug-print’ is non-nil."
  (when jsonnet-enable-debug-print
    (message str)))

(defun jsonnet--find-current-block-comment ()
  "Return the position of the comment start if inside a block comment. Otherwise, return nil."
  (let* ((previous-comment-start (save-excursion (re-search-backward "\\/\\*" nil t)))
         (previous-comment-end (save-excursion (re-search-backward "\\*\\/" nil t)))
         (is-in-block-comment (and (integerp previous-comment-start)
                                   (or (not (integerp previous-comment-end))
                                       (> previous-comment-start previous-comment-end)))))
    (when is-in-block-comment previous-comment-start)))

(defun jsonnet--find-current-multiline-string ()
  "Return the position of the beginning of the current multiline string.

If not inside of a multiline string, return nil."
  (let* ((ppss (syntax-ppss))
         (in-string (nth 3 ppss))
         (start (nth 8 ppss)))
    (when in-string
      start)))

(defun jsonnet--find-dot-after-close-paren ()
  "Return the position of dot after a closing parentheses."
  (let* ((ppss (syntax-ppss))
         (in-string (nth 3 ppss))
         (last-nonspace-char (if (and (looking-at (rx (not space)))
                                      (eq (following-char) ?\)))
                                 (point)
                               (save-excursion
                                 (re-search-backward (rx (not space)) nil t)
                                 (if (eolp)
                                     (1- (point))
                                   (point)))))
         (next-nonspace-char (save-excursion
                               (1- (re-search-forward (rx (not space)) nil t))))
         (last-char (save-excursion
                      (goto-char last-nonspace-char)
                      (following-char)))
         (next-char (save-excursion
                      (goto-char next-nonspace-char)
                      (following-char))))
    (when (and (not in-string)
               (eq last-char ?\))
               (eq next-char ?\.))
      t)))

(defun jsonnet--line-matches-regex-p (regex)
  "Return t if the current line matches REGEX."
  (save-excursion
    (beginning-of-line)
    (integerp (re-search-forward regex (line-beginning-position 2) t))))

;; Experimental algorithm
(defun jsonnet--indent-in-parens ()
  "Compute the indent of the current line, given it is inside parentheses."
  (if (jsonnet--line-matches-regex-p "^\s*)") 0 2))

(defun jsonnet--indent-in-braces ()
  "Compute the indent of the current line, given it is inside braces."
  (cond
   ((jsonnet--line-matches-regex-p "^\s*}") 0)
   ((save-excursion
      (forward-line -1)
      (jsonnet--line-matches-regex-p ":\s*$")) 4)
   (t 2)))

(defun jsonnet--indent-in-brackets ()
  "Compute the indent of the current line, given it is inside braces."
  (if (jsonnet--line-matches-regex-p "^\s*]") 0 2))

(defun jsonnet--indent-toplevel ()
  "Compute the indent of the current line, given it is not inside any delimiter."
  0)

(defun jsonnet-calculate-indent ()
  "Compute the indent of the current line."
  (interactive)
  (save-excursion
    (beginning-of-line)
    (cond
     ;; At the beginning of the buffer, the indent should be 0.
     ((bobp) 0)
     ;; NOTE: In all of these examples, the 'o' indicates the location of point after
     ;; indenting on that line. If the indent of the line depends on the contents of the line
     ;; itself, a '^' is used to indicate the proper indentation for the last line.
     ;;
     ;; If we are in a block comment, the indent should match the * at the beginning of the
     ;; comment.
     ;; e.g.
     ;; |/*
     ;; | o
     ((jsonnet--find-current-block-comment)
      (goto-char (jsonnet--find-current-block-comment))
      (+ 1 (current-column)))
     ;; If we are inside of a multiline string, the indent should be 2 greater than the beginning
     ;; of the multiline string. However, if the current line ends a multiline string, then the
     ;; indent should match the beginning of the multiline string.
     ((jsonnet--find-current-multiline-string)
      (let ((multiline-string-ends (jsonnet--line-matches-regex-p "^\s*|||")))
        (goto-char (jsonnet--find-current-multiline-string))
        (+ (current-indentation) (if multiline-string-ends 0 2))))
     ;; Otherwise, indent according to the kind of delimiter we are nested in.
     (t
      (let ((state (syntax-ppss)))
        (if (not (eq 0 (car state)))
            (let* ((delimiter-pos (cadr state))
                   (delimiter (when (not (eq 0 (car state)))
                                (char-after delimiter-pos)))
                   (current-indent (save-excursion
                                     (goto-char (cadr state))
                                     (current-indentation)))
                   (additional-indent (pcase delimiter
                                        (`?\( (jsonnet--indent-in-parens))
                                        (`?\{ (jsonnet--indent-in-braces))
                                        (`?\[ (jsonnet--indent-in-brackets))
                                        (_    (error (format "Unrecognized delimiter: %s" delimiter)))))
                   (new-indent (+ current-indent additional-indent)))
              (jsonnet--debug-print (format "Current delimiter: %s, position: %d" delimiter delimiter-pos))
              new-indent)
          (jsonnet--indent-toplevel)))))))

(defun jsonnet-smie--find-enclosing-delim (&rest type)
  "Return TYPE's position if inside a paren-like expression, else nil.
TYPE is an opening paren-like character."
  (let* ((ppss (syntax-ppss)))
    (and (< 0 (nth 0 ppss))
         (save-excursion
           (goto-char (nth 1 ppss))
           (if (-some-p (lambda (x)
                          (looking-at (rx-to-string x)))
                        type)
               (nth 1 ppss))))))

(defun jsonnet-indent-line ()
  "Indent current line according to Jsonnet syntax."
  (interactive)
  (let ((calculated-indent (jsonnet-calculate-indent)))
    (when (not (eq calculated-indent (current-indentation)))
      (beginning-of-line)
      (delete-char (current-indentation))
      (indent-to calculated-indent))))

;;;###autoload
(define-derived-mode jsonnet-mode prog-mode "Jsonnet"
  "jsonnet-mode is a major mode for editing .jsonnet files."
  :syntax-table jsonnet-mode-syntax-table
  (setq-local font-lock-defaults '(jsonnet-font-lock-keywords ;; keywords
                                   nil  ;; keywords-only
                                   nil  ;; case-fold
                                   nil  ;; syntax-alist
                                   nil  ;; syntax-begin
                                   ))
  (if jsonnet-use-smie
      (progn
        (smie-setup jsonnet-smie-grammar #'jsonnet-smie-rules
                    :forward-token  #'jsonnet-smie--forward-token
                    :backward-token #'jsonnet-smie--backward-token)
        (setq-local smie-indent-basic jsonnet-indent-level)
        (setq-local smie-indent-functions '(jsonnet-smie--indent-inside-multiline-string
                                            smie-indent-fixindent
                                            smie-indent-bob
                                            smie-indent-close
                                            smie-indent-comment
                                            smie-indent-comment-continue
                                            smie-indent-comment-close
                                            smie-indent-comment-inside
                                            smie-indent-keyword
                                            smie-indent-after-keyword
                                            smie-indent-empty-line)))
    (setq-local indent-line-function #'jsonnet-indent-line))
  (setq-local syntax-propertize-function #'jsonnet--syntax-propertize-function)
  (setq-local comment-start "// ")
  (setq-local comment-start-skip "//+[\t ]*")
  (setq-local comment-end "")
  (add-hook 'syntax-propertize-extend-region-functions
            #'syntax-propertize-multiline 'append 'local))

;;;###autoload
(add-to-list 'auto-mode-alist (cons "\\.jsonnet\\'" 'jsonnet-mode))
;;;###autoload
(add-to-list 'auto-mode-alist (cons "\\.libsonnet\\'" 'jsonnet-mode))

;; Utilities for evaluating and jumping around Jsonnet code.
;;;###autoload
(defun jsonnet-eval-buffer ()
  "Run jsonnet with the path of the current file."
  (interactive)
  (let ((file-to-eval (file-truename (buffer-file-name)))
        (search-dirs jsonnet-library-search-directories)
        (output-buffer-name "*jsonnet output*"))
    (save-some-buffers (not compilation-ask-about-save)
                       (let ((directories (cons (file-name-directory file-to-eval)
                                                search-dirs)))
                         (lambda ()
                           (member (file-name-directory (file-truename (buffer-file-name)))
                                   directories))))
    (let ((cmd jsonnet-command)
          (args (append jsonnet-command-options
                        (cl-loop for dir in search-dirs
                                 collect "-J"
                                 collect dir)
                        (list file-to-eval))))
      (with-current-buffer (get-buffer-create output-buffer-name)
        (setq buffer-read-only nil)
        (erase-buffer)
        (if (zerop (apply #'call-process cmd nil t nil args))
            (progn
              (when (fboundp 'json-mode)
                (json-mode))
              (view-mode))
          (compilation-mode nil))
        (goto-char (point-min))
        (display-buffer (current-buffer) '(nil (inhibit-same-window . t)))))))

(define-key jsonnet-mode-map (kbd "C-c C-c") 'jsonnet-eval-buffer)

;;;###autoload
(defun jsonnet-jump-to-definition (identifier)
  "Jump to the definition of the jsonnet function IDENTIFIER."
  (interactive "sFind definition with name: ")
  (let* ((local-def (concat "local\s+" identifier "[^[:alnum:]_]"))
         (inner-def (concat identifier "\\:+"))
         (full-regex (concat "\\(" local-def "\\|" inner-def "\\)"))
         (identifier-def (save-excursion
                           (goto-char (point-max))
                           (re-search-backward full-regex nil t))))
    (if identifier-def
        (progn
          (push-mark)
          (goto-char identifier-def))
      (message (concat "Unable to find definition for " identifier ".")))))

(defun jsonnet--get-identifier-at-location (&optional location)
  "Return the identifier at LOCATION if over a Jsonnet identifier.
If not provided, current point is used."
  (save-excursion
    (when location
      (goto-char location))
    (let ((curr-point (point))
          (curr-char (char-after)))
      (when (or (eq ?_ curr-char)
                (<= ?a curr-char ?z)
                (<= ?A curr-char ?Z)
                (<= ?0 curr-char ?9))
        (let ((start (save-excursion
                       (skip-chars-backward "[:alnum:]_")
                       (skip-chars-forward "[:digit:]")
                       (point)))
              (end   (save-excursion
                       (skip-chars-forward "[:alnum:]_")
                       (point))))
          (when (<= start curr-point end)
            (buffer-substring start end)))))))

;;;###autoload
(defun jsonnet-jump (_)
  "Jumps to the definition of the Jsonnet expression at POINT."
  (interactive "d")
  (let ((current-identifier (jsonnet--get-identifier-at-location)))
    (if (not current-identifier)
        (message "Point is not over a valid Jsonnet identifier.")
      (jsonnet-jump-to-definition current-identifier))))

(define-key jsonnet-mode-map (kbd "C-c C-f") 'jsonnet-jump)

;;;###autoload
(defun jsonnet-reformat-buffer ()
  "Reformat entire buffer using the Jsonnet format utility."
  (interactive)
  (let ((point (point))
        (file-name (buffer-file-name))
        (stdout-buffer (get-buffer-create "*jsonnetfmt stdout*"))
        (stderr-buffer-name "*jsonnetfmt stderr*")
        (stderr-file (make-temp-file "jsonnetfmt")))
    (when-let ((stderr-window (get-buffer-window stderr-buffer-name t)))
      (quit-window nil stderr-window))
    (unwind-protect
        (let* ((only-test buffer-read-only)
               (exit-code (apply #'call-process-region nil nil jsonnet-fmt-command
                                 nil (list stdout-buffer stderr-file) nil
                                 (append (when only-test '("--test"))
                                         '("-")))))
          (cond ((zerop exit-code)
                 (progn
                   (if (or only-test
                           (zerop (compare-buffer-substrings nil nil nil stdout-buffer nil nil)))
                       (message "No format change necessary.")
                     (erase-buffer)
                     (insert-buffer-substring stdout-buffer)
                     (goto-char point))
                   (kill-buffer stdout-buffer)))
                ((and only-test (= exit-code 2))
                 (message "Format change is necessary, but buffer is read-only."))
                (t (with-current-buffer (get-buffer-create stderr-buffer-name)
                     (setq buffer-read-only nil)
                     (insert-file-contents stderr-file t nil nil t)
                     (goto-char (point-min))
                     (when file-name
                       (while (search-forward "<stdin>" nil t)
                         (replace-match file-name)))
                     (set-buffer-modified-p nil)
                     (compilation-mode nil)
                     (display-buffer (current-buffer)
                                     '((display-buffer-reuse-window
                                        display-buffer-at-bottom
                                        display-buffer-pop-up-frame)
                                       .
                                       ((window-height . fit-window-to-buffer))))))))
      (delete-file stderr-file))))

(when (and (boundp 'compilation-error-regexp-alist)
           (boundp 'compilation-error-regexp-alist-alist))
  (add-to-list 'compilation-error-regexp-alist 'jsonnet-eval-line)
  (add-to-list 'compilation-error-regexp-alist-alist
               '(jsonnet-eval-line .
                                   ("^\\(?:[^:]+:\\)?\\s-+\\([^:\n]+\\):\\([0-9]+\\):\\([0-9]+\\)\\(?:-\\([0-9]+\\)\\)?:?\\s-.*$"
                                    1 2 (3 . 4) nil 1)) t)
  (add-to-list 'compilation-error-regexp-alist 'jsonnet-eval-lines)
  (add-to-list 'compilation-error-regexp-alist-alist
               '(jsonnet-eval-lines .
                                    ("^\\(?:[^:]+:\\)?\\s-+\\([^:\n]+\\):(\\([0-9]+\\):\\([0-9]+\\))-(\\([0-9]+\\):\\([0-9]+\\))\\s-.*$"
                                     1 (2 . 4) (3 . 5) nil 1)) t))

(define-key jsonnet-mode-map (kbd "C-c C-r") 'jsonnet-reformat-buffer)

(provide 'jsonnet-mode)
;;; jsonnet-mode.el ends here
