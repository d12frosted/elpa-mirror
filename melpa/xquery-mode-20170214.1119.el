;;; xquery-mode.el --- A simple mode for editing xquery programs

;; Copyright (C) 2005 Suraj Acharya
;; Copyright (C) 2006-2012 Michael Blakeley

;; Authors:
;;   Suraj Acharya <sacharya@cs.indiana.edu>
;;   Michael Blakeley <mike@blakeley.com>
;;   Artem Malyshev <proofit404@gmail.com>
;; URL: https://github.com/xquery-mode/xquery-mode
;; Version: 0.1.0
;; Package-Requires: ((cl-lib "0.5"))

;; This file is not part of GNU Emacs.

;; xquery-mode.el is free software; you can redistribute it
;; and/or modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.

;; This software is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;; Code:

;; TODO: 'if()' is highlighted as a function
;; TODO: requiring nxml-mode excludes XEmacs - just for colors?
;; TODO: test using featurep 'xemacs
;; TODO use nxml for element completion?

(require 'cl-lib)
(require 'thingatpt)
(require 'font-lock)
(require 'nxml-mode)

(defgroup xquery-mode nil
  "Major mode for XQuery files editing."
  :group 'languages)

(defun turn-on-xquery-tab-to-tab-indent ()
  "Turn on tab-to-tab XQuery-mode indentation."
  (define-key xquery-mode-map (kbd "TAB") 'tab-to-tab-stop)
  (kill-local-variable 'indent-line-function)
  (kill-local-variable 'indent-region-function))

(defun turn-on-xquery-native-indent ()
  "Turn on native XQuery-mode indentation."
  (define-key xquery-mode-map (kbd "TAB") 'indent-for-tab-command)
  (set (make-local-variable 'indent-line-function) 'xquery-mode-indent-line)
  (set (make-local-variable 'indent-region-function) 'xquery-mode-indent-region))

(defun toggle-xquery-mode-indent-style ()
  "Switch to the next indentation style."
  (interactive)
  (if (eq xquery-mode-indent-style 'tab-to-tab)
      (setq xquery-mode-indent-style 'native)
    (setq xquery-mode-indent-style 'tab-to-tab))
  (xquery-mode-activate-indent-style))

(defun xquery-mode-activate-indent-style ()
  "Activate current indentation style."
  (cond ((eq xquery-mode-indent-style 'tab-to-tab)
         (turn-on-xquery-tab-to-tab-indent))
        ((eq xquery-mode-indent-style 'native)
         (turn-on-xquery-native-indent))))

(defcustom xquery-mode-hook nil
  "Hook run after entering XQuery mode."
  :type 'hook
  :options '(turn-on-font-lock))

(defvar xquery-toplevel-bovine-table nil
  "Top level bovinator table.")

(defvar xquery-mode-syntax-table ()
  "Syntax table for xquery-mode.")

(setq xquery-mode-syntax-table
      (let ((xquery-mode-syntax-table (make-syntax-table)))
        ;; single-quotes are equivalent to double-quotes
        (modify-syntax-entry ?' "\"" xquery-mode-syntax-table)
        ;; treat underscores as punctuation
        (modify-syntax-entry ?\_ "." xquery-mode-syntax-table)
        ;; treat hypens as punctuation
        (modify-syntax-entry ?\- "." xquery-mode-syntax-table)
        ;; colons are both punctuation and comments
        ;; the space after '.' indicates an unused matching character slot
        (modify-syntax-entry ?\: ". 23" xquery-mode-syntax-table)
        ;; XPath step separator / is punctuation
        (modify-syntax-entry ?/ "." xquery-mode-syntax-table)
        ;; xquery doesn't use backslash-escaping, so \ is punctuation
        (modify-syntax-entry ?\\ "." xquery-mode-syntax-table)
        ;; set-up the syntax table correctly for all the different braces
        (modify-syntax-entry ?\{ "(}" xquery-mode-syntax-table)
        (modify-syntax-entry ?\} "){" xquery-mode-syntax-table)
        (modify-syntax-entry ?\[ "(]" xquery-mode-syntax-table)
        (modify-syntax-entry ?\] ")]" xquery-mode-syntax-table)
        ;; parens may indicate a comment, or may be a sequence
        (modify-syntax-entry ?\( "()1n" xquery-mode-syntax-table)
        (modify-syntax-entry ?\) ")(4n" xquery-mode-syntax-table)
        xquery-mode-syntax-table))

(defvar xquery-mode-keywords ()
  "Keywords for xquery-mode.")

;;;###autoload
(define-derived-mode xquery-mode fundamental-mode "XQuery"
  "A major mode for W3C XQuery 1.0"
  ;; indentation
  (setq nxml-prolog-end (point-min))
  (setq nxml-scan-end (copy-marker (point-min) nil))
  (make-local-variable 'forward-sexp-function)
  (setq forward-sexp-function 'xquery-forward-sexp)
  (local-set-key "/" 'nxml-electric-slash)
  (setq tab-width xquery-mode-indent-width)
  (xquery-mode-activate-indent-style)
  ;; apparently it's important to set at least an empty list up-front
  (set (make-local-variable 'font-lock-defaults) '((nil)))
  (set (make-local-variable 'comment-start) "(:")
  (set (make-local-variable 'comment-end) ":)")
  (set (make-local-variable 'comment-style) 'extra-line))

;; TODO: move it upper.
(defcustom xquery-mode-indent-style 'tab-to-tab
  "Indentation behavior.
`tab-to-tab' to use `tab-to-tab-stop' indent function
`native' to use own indentation engine"
  :group 'xquery-mode
  :type '(choice (const :tag "Tab to tab" tab-to-tab)
                 (const :tag "Native" native))
  :set (lambda (var key)
         (set var key)
         (xquery-mode-activate-indent-style)))

(defcustom xquery-mode-indent-width 2
  "Indent width for `xquery-mode'."
  :group 'xquery-mode
  :type 'integer)

;; XQuery doesn't have keywords, but these usually work...
;; TODO: remove as many as possible, in favor of parsing
(setq xquery-mode-keywords
      (list
       ;; FLWOR
       ;;"let" "for"
       "at" "in"
       "where"
       "stable order by" "order by"
       "ascending" "descending" "empty" "greatest" "least" "collation"
       "return"
       ;; XPath axes
       "self" "child" "descendant" "descendant-or-self"
       "parent" "ancestor" "ancestor-or-self"
       "following" "following-sibling"
       "preceding" "preceding-sibling"
       ;; conditionals
       "if" "then" "else"
       "typeswitch" ;"case" "default"
       ;; quantified expressions
       "some" "every" "construction" "satisfies"
       ;; schema
       "schema-element" "schema-attribute" "validate"
       ;; operators
       "intersect" "union" "except" "to"
       "is" "eq" "ne" "gt" "ge" "lt" "le"
       "or" "and"
       "div" "idiv" "mod"))

(defvar xquery-mode-keywords-regex
  (concat "\\b\\("
          (mapconcat
           (function
            (lambda (r)
              (if (string-match "[ \t]+" r)
                  (replace-match "[ \t]+" nil t r)
                r)))
           xquery-mode-keywords
           "\\|")
          "\\)\\b")
  "Keywords regex for xquery mode.")

;; XQuery syntax - TODO build a real parser
(defvar xquery-mode-ncname "\\(\\sw[-_\\.[:word:]]*\\)"
  "NCName regex, in 1 group.")

;; highlighting needs a group, even if it's "" - so use (...?) not (...)?
;; note that this technique treats the local-name as optional,
;; when the prefix should be the optional part.
(defvar xquery-mode-qname
  (concat
   xquery-mode-ncname
   "\\(:?\\)"
   "\\("
   xquery-mode-ncname
   "?\\)")
  "QName regex, in 3 groups.")

(font-lock-add-keywords
 'xquery-mode
 `(
   ;; prolog version decl
   ("\\(xquery\\s-+version\\)\\s-+"
    (1 font-lock-keyword-face))
   ;; namespace default decl for 0.9 or 1.0
   (,(concat
      "\\(\\(declare\\)?"
      "\\(\\s-+default\\s-+\\(function\\|element\\)\\)"
      "\\s-+namespace\\)\\s-+")
    (1 font-lock-keyword-face))
   ;; namespace decl
   (,(concat
      "\\(declare\\s-+namespace\\)\\s-+")
    (1 font-lock-keyword-face))
   ;; option decl
   (,(concat "\\(declare\\s-+option\\s-+" xquery-mode-qname "\\)")
    (1 font-lock-keyword-face))
   ;; import module decl - must precede library module decl
   ("\\(import\\s-+module\\)\\s-+\\(namespace\\)?\\s-+"
    (1 font-lock-keyword-face)
    (2 font-lock-keyword-face))
   ;; library module decl, for 1.0 or 0.9-ml
   ("\\(module\\)\\s-+\\(namespace\\)?\\s-*"
    (1 font-lock-keyword-face)
    (2 font-lock-keyword-face))
   ;; import schema decl
   ("\\(import\\s-+schema\\)\\s-+\\(namespace\\)?\\s-+"
    (1 font-lock-keyword-face)
    (2 font-lock-keyword-face))
   ;; variable decl
   ("\\(for\\|let\\|declare\\s-+variable\\|define\\s-+variable\\)\\s-+\\$"
    (1 font-lock-keyword-face))
   ;; variable name
   (,(concat "\\($" xquery-mode-qname "\\)")
    (1 font-lock-variable-name-face))
   ;; function decl
   (,(concat
      "\\(declare\\s-+function\\"
      "|declare\\s-+private\\s-+function\\"
      "|define\\s-+function\\)\\s-+\\("
      xquery-mode-qname "\\)(")
    (1 font-lock-keyword-face)
    (2 font-lock-function-name-face))
   ;; schema test or type decl
   (,(concat
      "\\("
      "case"
      "\\|instance\\s-+of\\|castable\\s-+as\\|treat\\s-+as\\|cast\\s-+as"
      ;; "as" must be last in the list
      "\\|as"
      "\\)"
      "\\s-+\\(" xquery-mode-qname "\\)"
      ;; type may be followed by element() or element(x:foo)
      "(?\\s-*\\(" xquery-mode-qname "\\)?\\s-*)?")
    (1 font-lock-keyword-face)
    (2 font-lock-type-face)
    ;; TODO: the second qname never matches
    (3 font-lock-type-face))
   ;; function call
   (,(concat "\\(" xquery-mode-qname "\\)(")
    (1 font-lock-function-name-face))
   ;; named node constructor
   (,(concat "\\(attribute\\|element\\)\\s-+\\(" xquery-mode-qname "\\)\\s-*{")
    (1 font-lock-keyword-face)
    (2 font-lock-constant-face))
   ;; anonymous node constructor
   ("\\(binary\\|comment\\|document\\|text\\)\\s-*{"
    (1 font-lock-keyword-face))
   ;; typeswitch default
   ("\\(default\\s-+return\\)\\s-+"
    (1 font-lock-keyword-face)
    (2 font-lock-keyword-face))
   ;; xml start element start
   (,(concat "<" xquery-mode-qname)
    (1 'nxml-element-prefix)
    (2 'nxml-element-colon)
    (3 'nxml-element-prefix))
   ;; xml start element end
   ("\\(/?\\)>"
    (1 'nxml-tag-slash))
   ;; xml end element
   (,(concat "<\\(/\\)" xquery-mode-qname ">")
    (1 'nxml-tag-slash)
    (2 'nxml-element-prefix)
    (3 'nxml-element-colon)
    (4 'nxml-element-local-name))
   ;; TODO: xml attribute or xmlns decl
   ;; xml comments
   ("\\(<!--\\)\\([^-]*\\)\\(-->\\)"
    (1 'nxml-comment-delimiter)
    (2 'nxml-comment-content)
    (3 'nxml-comment-delimiter))
   ;; highlighting XPath expressions, including *:foo
   ;;
   ;; TODO: this doesn't match expressions unless they start with
   ;; slash
   ;;
   ;; TODO: but matching without a leading slash overrides all the
   ;; keywords
   (,(concat "\\(//?\\)\\(*\\|\\sw*\\)\\(:?\\)" xquery-mode-ncname)
    (1 font-lock-constant-face)
    (2 font-lock-constant-face)
    (3 font-lock-constant-face)
    (4 font-lock-constant-face))
   ;; highlighting pseudo-keywords - must be late, for problems like
   ;; 'if ()'
   (,xquery-mode-keywords-regex
    (1 font-lock-keyword-face))))

;;;###autoload
(add-to-list 'auto-mode-alist '(".xq[erxy]\\'" . xquery-mode))

(defun xquery-forward-sexp (&optional arg)
  "XQuery forward s-expresssion.
This function is not very smart.  It tries to use
`nxml-forward-balanced-item' if it sees '>' or '<' characters in
the current line (ARG), and uses the regular `forward-sexp'
otherwise."
  (if (> arg 0)
      (progn
        (if (looking-at "\\s-*<")
            (nxml-forward-balanced-item arg)
          (let ((forward-sexp-function nil)) (forward-sexp arg))))
    (if (looking-back ">\\s-*")
        (nxml-forward-balanced-item arg)
      (let ((forward-sexp-function nil)) (forward-sexp arg)))))

(defun xquery-mode-indent-line ()
  "Indent current line as xquery code."
  (xquery-mode-indent-region
   (line-beginning-position)
   (line-end-position))
  (when (< (current-column) (current-indentation))
    (back-to-indentation)))

(defun xquery-mode-indent-region (start end)
  "Indent given region.
START and END are region boundaries."
  (interactive "r")
  (save-excursion
    (let* ((literals '(("\\(?:\\<declare\\>\\|\\<define\\>\\)\\(?:\\s-+\\<private\\>\\)?\\s-+\\<function\\>.*?(" . function-name-stmt)
                       ("\\<declare\\>\\s-+\\<variable\\>" . declare-variable-stmt)
                       ("\\(?:\\<module\\>\\|\\<declare\\>\\s-+\\<default\\>\\s-+\\<function\\>\\)\\s-+\\<namespace\\>" . namespace-stmt)
                       ("\\<import\\>\\s-+\\<module\\>" . import-stmt)
                       ("(:" . comment-start-stmt)
                       (":)" . comment-end-stmt)
                       ("=>" . arrow-operator-stmt)
                       ("<!\\[CDATA\\[" . cdata-start-stmt)
                       ("\\]\\]>" . cdata-end-stmt)
                       ("<!--" . xml-comment-start-stmt)
                       ("-->" . xml-comment-end-stmt)
                       ("{{" . escaped-open-curly-bracket-stmt)
                       ("}}" . escaped-close-curly-bracket-stmt)
                       ("{" . open-curly-bracket-stmt)
                       ("}" . close-curly-bracket-stmt)
                       ("\\[" . open-square-bracket-stmt)
                       ("\\]" . close-square-bracket-stmt)
                       ("(" . open-round-bracket-stmt)
                       (")" . close-round-bracket-stmt)
                       ("<\\(?:\\?\\)?[^>/ ]+\\>" . open-xml-tag-start-stmt)
                       ("\\(?:/\\|\\?\\)>" . self-closing-xml-tag-end-stmt)
                       (">" . open-xml-tag-end-stmt)
                       ("</[^>]+>" . close-xml-tag-stmt)
                       ("\"" . double-quote-stmt)
                       ("'" . quote-stmt)
                       ("\"" . close-double-quote-stmt) ;; Don't ask...
                       ("'" . close-quote-stmt)
                       ("\\<for\\>" . for-stmt)
                       ("\\<let\\>" . let-stmt)
                       ("\\<order\\>\\s-+\\<by\\>" . order-by-stmt)
                       (":=" . assign-stmt)
                       (";" . semicolon-stmt)
                       (":" . colon-stmt)
                       ("," . comma-stmt)
                       ("*" . glob-stmt)
                       ("\\<if\\>" . if-stmt)
                       ("\\<then\\>" . then-stmt)
                       ("\\<else\\>\\s-+\\<if\\>" . else-if-stmt)
                       ("\\<else\\>" . else-stmt)
                       ("\\<where\\>" . where-stmt)
                       ("\\<return\\>" . return-stmt)
                       ("\\<typeswitch\\>" . typeswitch-stmt)
                       ("\\<switch\\>" . switch-stmt)
                       ("\\<case\\>" . case-stmt)
                       ("\\<default\\>" . default-stmt)
                       ("\\<try\\>" . try-stmt)
                       ("\\<catch\\>" . catch-stmt)
                       ("\\<element\\>" . element-stmt)
                       ("\\$[[:alnum:]-_.:/@]*[[:alnum:]]" . var-stmt)
                       ("[[:alnum:]-_.:/@]*[[:alnum:]]" . word-stmt)
                       ("[^[:space:]]" . non-blank-stmt)))
           (search-number 0)
           (expression-lookup-fn (lambda (stream found-literal offset)
                                   (when (memq (caar stream)
                                               '(open-square-bracket-stmt
                                                 assign-stmt where-stmt if-stmt else-stmt
                                                 default-stmt open-xml-tag-start-stmt
                                                 return-stmt))
                                     (list 'expression-start-stmt nil offset))))
           (curly-expression-lookup-fn (lambda (stream found-literal offset)
                                         (when (and (eq (caar stream) 'open-curly-bracket-stmt)
                                                    (eq (1+ (cl-fourth (car stream))) search-number))
                                           (list 'curly-expression-start-stmt nil offset))))
           (for-expression-lookup-fn (lambda (stream found-literal offset)
                                       (when (eq (caar stream) 'for-stmt)
                                         (list 'for-expression-start-stmt nil offset))))
           (element-arg-lookup-fn (lambda (stream found-literal offset)
                                    (when (eq (caar stream) 'element-stmt)
                                      (list 'element-arg-stmt nil offset))))
           (substitutions (list (list 'var-stmt
                                      expression-lookup-fn curly-expression-lookup-fn for-expression-lookup-fn 'var-stmt)
                                (list 'word-stmt
                                      expression-lookup-fn curly-expression-lookup-fn 'word-stmt 'element-end-stmt)
                                (list 'non-blank-stmt
                                      (lambda (stream found-literal offset)
                                        (when (memq (caar stream)
                                                    '(xml-comment-start-stmt open-xml-tag-stmt))
                                          (list 'expression-start-stmt nil offset)))
                                      'non-blank-stmt)
                                (list 'open-curly-bracket-stmt
                                      element-arg-lookup-fn 'open-curly-bracket-stmt)
                                '(catch-stmt
                                  catch-stmt catch-exception-stmt)
                                '(function-name-stmt
                                  expression-end-stmt function-name-stmt)
                                '(declare-variable-stmt
                                  expression-end-stmt declare-variable-stmt)
                                '(for-stmt
                                  for-expression-end-stmt expression-end-stmt for-stmt)
                                '(where-stmt
                                  for-expression-end-stmt expression-end-stmt where-stmt)
                                '(order-by-stmt
                                  for-expression-end-stmt expression-end-stmt order-by-stmt)
                                '(return-stmt
                                  for-expression-end-stmt expression-end-stmt return-stmt)
                                '(close-curly-bracket-stmt
                                  expression-end-stmt curly-expression-end-stmt close-curly-bracket-stmt)
                                '(close-square-bracket-stmt
                                  expression-end-stmt close-square-bracket-stmt)
                                '(close-round-bracket-stmt
                                  expression-end-stmt close-round-bracket-stmt element-end-stmt)
                                '(else-stmt
                                  expression-end-stmt else-stmt)
                                '(else-if-stmt
                                  expression-end-stmt else-if-stmt)
                                '(case-stmt
                                  expression-end-stmt case-stmt)
                                (list 'default-stmt
                                      (lambda (stream found-literal offset)
                                        ;; TODO: Calculate item from opposite and found-literal.
                                        (when (cl-find '(typeswitch-stmt switch-stmt)
                                                       stream
                                                       :key #'car
                                                       :test (lambda (item s) (memq s item)))
                                          (list 'expression-end-stmt nil offset)))
                                      (lambda (stream found-literal offset)
                                        ;; TODO: Calculate item from opposite and found-literal.
                                        (when (cl-find '(typeswitch-stmt switch-stmt)
                                                       stream
                                                       :key #'car
                                                       :test (lambda (item s) (memq s item)))
                                          (list 'default-stmt nil offset))))
                                (list 'let-stmt
                                      curly-expression-lookup-fn 'for-expression-end-stmt 'expression-end-stmt 'let-stmt)
                                '(semicolon-stmt
                                  expression-end-stmt semicolon-stmt)
                                (list 'comment-start-stmt
                                      curly-expression-lookup-fn 'comment-start-stmt)
                                (list 'xml-comment-start-stmt
                                      curly-expression-lookup-fn 'xml-comment-start-stmt)
                                '(xml-comment-end-stmt
                                  expression-end-stmt xml-comment-end-stmt)
                                '(self-closing-xml-tag-end-stmt
                                  expression-end-stmt self-closing-xml-tag-end-stmt)
                                '(open-xml-tag-end-stmt
                                  expression-end-stmt open-xml-tag-end-stmt)
                                '(close-xml-tag-stmt
                                  expression-end-stmt close-xml-tag-stmt)
                                '(cdata-start-stmt
                                  expression-end-stmt cdata-start-stmt)
                                '(comma-stmt
                                  expression-end-stmt comma-stmt)
                                '(self-closing-xml-tag-stmt
                                  self-closing-xml-tag-stmt expression-stmt)
                                (list 'double-quote-stmt
                                      curly-expression-lookup-fn 'double-quote-stmt)
                                (list 'quote-stmt
                                      curly-expression-lookup-fn 'quote-stmt)))
           (on-close '((expression-start-stmt . expression-stmt)
                       (curly-expression-start-stmt . expression-stmt)
                       (element-stmt . expression-stmt)
                       (element-arg-stmt . element-arg-offset-stmt)
                       (element-arg-offset-stmt . expression-stmt)
                       (open-curly-bracket-stmt . expression-stmt)
                       (open-round-bracket-stmt . expression-stmt)
                       ((open-xml-tag-start-stmt open-xml-tag-end-stmt) . open-xml-tag-stmt)
                       ((open-xml-tag-start-stmt self-closing-xml-tag-end-stmt) . self-closing-xml-tag-stmt)
                       (open-xml-tag-stmt . expression-stmt)
                       (else-stmt . expression-stmt)
                       (default-stmt . expression-stmt)
                       (double-quote-stmt . expression-stmt)
                       (quote-stmt . expression-stmt)
                       ;; TODO: surround expr-start for return expr-end
                       ;; TODO: surround expr-start if then else expr-end
                       (return-stmt . expression-stmt)
                       (catch-stmt . expression-stmt)))
           ;; TODO: assign-stmt should be closed by strings and numbers.
           (opposite '((close-curly-bracket-stmt open-curly-bracket-stmt)
                       (close-square-bracket-stmt open-square-bracket-stmt)
                       (close-round-bracket-stmt open-round-bracket-stmt function-name-stmt)
                       (self-closing-xml-tag-end-stmt open-xml-tag-start-stmt)
                       (open-xml-tag-end-stmt open-xml-tag-start-stmt)
                       (close-xml-tag-stmt open-xml-tag-stmt)
                       (close-double-quote-stmt double-quote-stmt)
                       (close-quote-stmt quote-stmt)
                       (assign-stmt let-stmt declare-variable-stmt)
                       (return-stmt where-stmt order-by-stmt for-stmt)
                       (for-stmt for-stmt)
                       (where-stmt for-stmt)
                       (order-by-stmt where-stmt for-stmt)
                       (else-stmt if-stmt)
                       (if-stmt else-stmt)
                       (default-stmt typeswitch-stmt switch-stmt)
                       (catch-stmt try-stmt)
                       (semicolon-stmt namespace-stmt import-stmt assign-stmt declare-variable-stmt)
                       (comment-end-stmt comment-start-stmt)
                       (xml-comment-end-stmt xml-comment-start-stmt)
                       (cdata-end-stmt cdata-start-stmt)
                       (glob-stmt catch-exception-stmt)
                       (expression-stmt
                        return-stmt else-stmt assign-stmt catch-stmt catch-exception-stmt
                        element-stmt element-arg-stmt element-arg-offset-stmt default-stmt)
                       (element-end-stmt element-stmt)
                       (expression-end-stmt expression-start-stmt)
                       (curly-expression-end-stmt curly-expression-start-stmt expression-start-stmt)
                       (for-expression-end-stmt for-expression-start-stmt)
                       (var-stmt assign-stmt return-stmt)))
           (implicit-statements '(expression-end-stmt curly-expression-end-stmt expression-stmt for-expression-end-stmt))
           ;; TODO: No seriously, I should start to use ` and , lisp features.
           (next-re-table (list '(comment-start-stmt . inside-comment)
                                '(comment-end-stmt . generic)
                                '(xml-comment-start-stmt . inside-xml-comment)
                                (cons 'xml-comment-end-stmt (lambda (stream found-literal offset)
                                                              (cond
                                                               ((eq (caar stream) 'open-xml-tag-stmt)
                                                                'inside-xml-tag)
                                                               ((and (> (length stream) 1)
                                                                     (equal (mapcar #'car (cl-subseq stream 0 2))
                                                                            '(expression-start-stmt open-xml-tag-stmt)))
                                                                'inside-xml-tag)
                                                               (t 'generic))))
                                '(cdata-start-stmt . inside-cdata)
                                '(cdata-end-stmt . generic)
                                '(double-quote-stmt . inside-double-quoted-string)
                                (cons 'close-double-quote-stmt (lambda (stream found-literal offset)
                                                                 (cond
                                                                  ((eq (caar stream) 'open-xml-tag-start-stmt)
                                                                   'inside-open-xml-tag)
                                                                  ((and (> (length stream) 1)
                                                                        (equal (mapcar #'car (cl-subseq stream 0 2))
                                                                               '(expression-start-stmt open-xml-tag-start-stmt)))
                                                                   'inside-open-xml-tag)
                                                                  (t 'generic))))
                                '(quote-stmt . inside-string)
                                (cons 'close-quote-stmt (lambda (stream found-literal offset)
                                                          (cond
                                                           ((eq (caar stream) 'open-xml-tag-start-stmt)
                                                            'inside-open-xml-tag)
                                                           ((and (> (length stream) 1)
                                                                 (equal (mapcar #'car (cl-subseq stream 0 2))
                                                                        '(expression-start-stmt open-xml-tag-start-stmt)))
                                                            'inside-open-xml-tag)
                                                           (t 'generic))))
                                '(open-xml-tag-start-stmt . inside-open-xml-tag)
                                '(open-xml-tag-stmt . inside-xml-tag)
                                (cons 'close-xml-tag-stmt (lambda (stream found-literal offset)
                                                            (cond
                                                             ((eq (caar stream) 'open-xml-tag-stmt)
                                                              'inside-xml-tag)
                                                             ((and (> (length stream) 1)
                                                                   (equal (mapcar #'car (cl-subseq stream 0 2))
                                                                          '(expression-start-stmt open-xml-tag-stmt)))
                                                              'inside-xml-tag)
                                                             (t 'generic))))
                                (cons 'self-closing-xml-tag-stmt (lambda (stream found-literal offset)
                                                                   (cond
                                                                    ((eq (caar stream) 'open-xml-tag-stmt)
                                                                     'inside-xml-tag)
                                                                    ((and (> (length stream) 1)
                                                                          (equal (mapcar #'car (cl-subseq stream 0 2))
                                                                                 '(expression-start-stmt open-xml-tag-stmt)))
                                                                     'inside-xml-tag)
                                                                    (t 'generic))))
                                '(open-curly-bracket-stmt . generic)
                                (cons 'close-curly-bracket-stmt (lambda (stream found-literal offset)
                                                                  (cond
                                                                   ((eq (caar stream) 'open-xml-tag-stmt)
                                                                    'inside-xml-tag)
                                                                   ((and (> (length stream) 1)
                                                                         (equal (mapcar #'car (cl-subseq stream 0 2))
                                                                                '(expression-start-stmt open-xml-tag-stmt)))
                                                                    'inside-xml-tag)
                                                                   ((eq (caar stream) 'double-quote-stmt)
                                                                    'inside-double-quoted-string)
                                                                   (t 'generic))))))
           (grid (list (cons 'generic
                             (cl-remove-if (lambda (x) (memq x '(escaped-open-curly-bracket-stmt
                                                                 escaped-close-curly-bracket-stmt
                                                                 close-quote-stmt
                                                                 close-double-quote-stmt
                                                                 self-closing-xml-tag-end-stmt
                                                                 open-xml-tag-end-stmt
                                                                 non-blank-stmt)))
                                           (mapcar #'cdr literals)))
                       '(inside-comment
                         comment-end-stmt colon-stmt non-blank-stmt)
                       '(inside-xml-comment
                         xml-comment-end-stmt non-blank-stmt)
                       '(inside-cdata
                         cdata-end-stmt)
                       '(inside-double-quoted-string
                         open-curly-bracket-stmt close-double-quote-stmt word-stmt)
                       '(inside-string
                         close-quote-stmt word-stmt)
                       '(inside-open-xml-tag
                         self-closing-xml-tag-end-stmt open-xml-tag-end-stmt
                         double-quote-stmt quote-stmt colon-stmt word-stmt)
                       '(inside-xml-tag
                         cdata-start-stmt xml-comment-start-stmt
                         escaped-open-curly-bracket-stmt escaped-close-curly-bracket-stmt
                         open-curly-bracket-stmt open-xml-tag-start-stmt close-xml-tag-stmt
                         non-blank-stmt)))
           ;; TODO: don't calculate indent pairs.  Write it declarative way.
           ;; TODO: make variable below calculated only.
           (non-pairs '(cdata-end-stmt
                        comment-end-stmt xml-comment-end-stmt
                        close-double-quote-stmt close-quote-stmt
                        var-stmt word-stmt assign-stmt))
           ;; TODO: This duplication makes me sad very often.
           (pairs '((close-curly-bracket-stmt open-curly-bracket-stmt)
                    (close-round-bracket-stmt function-name-stmt)))
           ;; TODO: that's not good at all.
           (aligned-pairs (append (cl-remove-if (lambda (x) (member x (append non-pairs (mapcar #'car pairs))))
                                                opposite
                                                :key #'car)
                                  '((close-round-bracket-stmt open-round-bracket-stmt)
                                    (then-stmt if-stmt)
                                    (else-if-stmt if-stmt)
                                    (let-stmt for-stmt)
                                    (case-stmt typeswitch-stmt switch-stmt))))
           (opening (apply #'append (mapcar #'cdr opposite)))
           (closing (mapcar #'car opposite))
           (re-table (mapcar (lambda (g)
                               (let* ((name (car g))
                                      (grid-literals (cdr g))
                                      (group-lookup (cl-loop for x in grid-literals
                                                             for y from 1
                                                             collect (cons y x)))
                                      (groups (mapcar #'car group-lookup))
                                      (re (mapconcat (lambda (x) (concat "\\(" (car x) "\\)"))
                                                     (cl-remove-if-not
                                                      (lambda (x) (memq (cdr x) grid-literals))
                                                      literals)
                                                     "\\|")))
                                 (list name re groups group-lookup)))
                             grid))
           (read-table 'generic)
           (re (cadr (assoc read-table re-table)))
           (groups (cl-caddr (assoc read-table re-table)))
           (group-lookup (cl-cadddr (assoc read-table re-table)))
           (current-indent 0)
           (at-front t)
           stream
           exit)
      (goto-char (point-min))
      (push (list 'buffer-beginning 0 0 0) stream)
      (while (not exit)
        (if (re-search-forward re (min (line-end-position) end) t)
            (progn
              (cl-incf search-number)
              (let* ((matched-group (cl-find-if #'match-string-no-properties groups))
                     (found-literal (cdr (assoc matched-group group-lookup)))
                     (offset (- (current-column)
                                (current-indentation)
                                (length (match-string-no-properties 0))))
                     (buf (or (delq nil
                                    (mapcar (lambda (s)
                                              (if (symbolp s)
                                                  (list s nil offset)
                                                (apply s stream found-literal offset nil)))
                                            (cdr (assoc found-literal substitutions))))
                              (list (list found-literal nil offset)))))
                (while (memq (caar buf) implicit-statements)
                  (let ((token (car (pop buf))))
                    (when (and (memq token closing)
                               (memq (caar stream)
                                     (cdr (assoc token opposite))))
                      (let* ((closed (car (pop stream)))
                             (trigger (cdr (cl-assoc
                                            (list closed token)
                                            on-close
                                            :test (lambda (item s) (if (consp s) (equal item s) (eq (car item) s)))))))
                        (when trigger
                          (push (list trigger nil nil) buf))))))
                (when at-front
                  (cl-destructuring-bind (previous-token previous-indent previous-offset previous-search-number)
                      (car stream)
                    (cond
                     ((< (point) start)
                      (setq current-indent (current-indentation)))
                     ;; TODO: Rewrite as nested expression start block.
                     ((and (eq previous-token 'comment-start-stmt)
                           (memq (caar buf) '(colon-stmt comment-end-stmt)))
                      (setq current-indent (+ previous-indent previous-offset 1)))
                     ((eq previous-token 'comment-start-stmt)
                      (setq current-indent (+ previous-indent previous-offset 3)))
                     ((cl-loop for pair in pairs
                               thereis (and (eq (caar buf) (car pair))
                                            (memq previous-token (cdr pair))))
                      (setq current-indent previous-indent))
                     ((cl-loop for pair in aligned-pairs
                               thereis (and (eq (caar buf) (car pair))
                                            (memq previous-token (cdr pair))))
                      (setq current-indent (+ previous-indent previous-offset)))
                     ((eq previous-token 'open-round-bracket-stmt)
                      (setq current-indent (+ previous-indent previous-offset 1)))
                     ((memq previous-token '(open-curly-bracket-stmt assign-stmt))
                      (setq current-indent (+ previous-indent xquery-mode-indent-width)))
                     ((memq previous-token '(open-xml-tag-stmt
                                             return-stmt if-stmt else-stmt where-stmt let-stmt
                                             namespace-stmt import-stmt
                                             function-name-stmt declare-variable-stmt
                                             typeswitch-stmt switch-stmt default-stmt
                                             try-stmt catch-stmt))
                      (setq current-indent (+ previous-indent previous-offset xquery-mode-indent-width)))
                     ((memq previous-token '(expression-start-stmt
                                             curly-expression-start-stmt for-expression-start-stmt
                                             element-arg-offset-stmt))
                      (setq current-indent (+ previous-indent previous-offset)))
                     ((memq previous-token '(cdata-start-stmt double-quote-stmt quote-stmt))
                      (setq current-indent (current-indentation)))
                     ((eq previous-token 'buffer-beginning)
                      (setq current-indent previous-indent)))))
                (setq at-front nil)
                (while buf
                  (cl-destructuring-bind (buf-token buf-indent buf-offset)
                      (pop buf)
                    (when (and (memq buf-token closing)
                               (memq (caar stream)
                                     (cdr (assoc buf-token opposite))))
                      (cl-destructuring-bind (closed-token closed-indent closed-offset closed-search-number)
                          (pop stream)
                        (let ((trigger (cdr (cl-assoc
                                             (list closed-token buf-token)
                                             on-close
                                             :test (lambda (item s) (if (consp s) (equal item s) (eq (car item) s)))))))
                          (when trigger
                            (let ((trigger-buf (or (delq nil
                                                         (mapcar (lambda (s)
                                                                   (if (symbolp s)
                                                                       (list s closed-indent closed-offset)
                                                                     (apply s stream trigger closed-offset nil)))
                                                                 (cdr (assoc trigger substitutions))))
                                                   (list (list trigger closed-indent closed-offset)))))
                              (setq buf (append trigger-buf buf)))))))
                    (when (memq buf-token opening)
                      (push (list buf-token (or buf-indent current-indent) buf-offset search-number) stream))
                    (let ((next-re-key (cdr (assoc buf-token next-re-table))))
                      (when next-re-key
                        (when (functionp next-re-key)
                          (setq next-re-key (apply next-re-key stream found-literal offset nil)))
                        (cl-destructuring-bind (next-re-re next-re-groups next-re-lookups)
                            (cdr (assoc next-re-key re-table))
                          (setq read-table next-re-key
                                re next-re-re
                                groups next-re-groups
                                group-lookup next-re-lookups))))))))
          (unless at-front
            (setq end (+ end (- current-indent (current-indentation))))
            (indent-line-to current-indent))
          (if (>= (line-end-position) end)
              (setq exit t)
            (setq at-front t)
            (forward-line)
            (beginning-of-line)))))))

(provide 'xquery-mode)

;;; xquery-mode.el ends here
)
            (beginning-of-line)))))))

(provide 'xquery-mode)

;;; xquery-mode.el ends here
