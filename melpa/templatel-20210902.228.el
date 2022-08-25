;;; templatel.el --- Templating language; -*- lexical-binding: t -*-
;;
;; Author: Lincoln Clarete <lincoln@clarete.li>
;; URL: https://clarete.li/templatel
;; Package-Version: 20210902.228
;; Package-Commit: e1ccb88cdc4b482b078276960f810b82ba3b7847
;; Version: 0.1.6
;; Package-Requires: ((emacs "25.1"))
;;
;; Copyright (C) 2020-2021  Lincoln Clarete
;;
;; This program is free software: you can redistribute it and/or modify
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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; This language compiles templates into Emacs Lisp functions that can
;; be called with different sets of variables.  This work is inspired
;; by Jinja and among its main features, it supports if statements,
;; for loops, and a good amount of expressions that make it simpler to
;; manipulate data within the template.
;;
;; (require 'templatel)
;;
;; (templatel-render-string
;;  "<h1>{{ title }}</h1>
;; <ul>
;;   {% for user in users %}
;;     <li><a href=\"{{ user.url }}\">{{ user.name }}</a></li>
;;   {% endfor %}
;; </ul>"
;;  '(("title" . "A nice web page")
;;    ("users" . ((("url" . "http://clarete.li")
;;                 ("name" . "link"))
;;                (("url" . "http://gnu.org")
;;                 ("name" . "Gnu!!"))))))
;;
;; This library also provides template in heritance and automatic HTML
;; entity escaping among other things.  Take a look at the
;; documentation website for all the features:
;; https://clarete.li/templatel/doc.
;;
;;; Code:

(require 'seq)
(require 'subr-x)

(define-error 'templatel-syntax-error "Syntax Error" 'templatel-error)

(define-error 'templatel-runtime-error "Runtime Error" 'templatel-error)

(define-error 'templatel-backtracking "Backtracking" 'templatel-internal)

;; --- String utilities ---

(defun templatel--decoded (&rest bytes)
  "Decode BYTES as a utf-8 string."
  (decode-coding-string (apply #'unibyte-string bytes) 'utf-8))

(defun templatel--string (rune)
  "Convert RUNE numeric value into a UTF-8 string."
  (cond
   ((<= rune (- (ash 1 7) 1))
    (byte-to-string rune))
   ((<= rune (- (ash 1 11) 1))
    (templatel--decoded
     (logior #xC0 (ash rune -6))
     (logior #x80 (logand rune #x3F))))
   ((<= rune (- (ash 1 16) 1))
    (templatel--decoded
     (logior #xE0 (ash rune -12))
     (logior #x80 (logand (ash rune -6) #x3F))
     (logior #x80 (logand rune #x3F))))
   (t
    (templatel--decoded
     (logior #xF0 (ash rune -18))
     (logior #x80 (logand (ash rune -12) #x3F))
     (logior #x80 (logand (ash rune -6) #x3F))
     (logior #x80 (logand rune #x3F))))))

(defun templatel--join-chars (chars)
  "Join all the CHARS forming a string."
  (string-join (mapcar #'templatel--string chars) ""))

;; --- Scanner ---

(defun templatel--scanner-new (input file-name)
  "Create scanner state for INPUT named FILE-NAME."
  (list input 0 0 0 file-name))

(defun templatel--scanner-input (scanner)
  "Input that SCANNER is operating on."
  (car scanner))

(defun templatel--scanner-cursor (scanner)
  "Cursor position of SCANNER."
  (cadr scanner))

(defun templatel--scanner-cursor-set (scanner value)
  "Set SCANNER's cursor to VALUE."
  (setf (cadr scanner) value))

(defun templatel--scanner-cursor-incr (scanner)
  "Increment SCANNER's cursor."
  (templatel--scanner-cursor-set scanner (+ 1 (templatel--scanner-cursor scanner))))

(defun templatel--scanner-file (scanner)
  "Line the SCANNER's cursor is in."
  (elt scanner 4))

(defun templatel--scanner-line (scanner)
  "Line the SCANNER's cursor is in."
  (caddr scanner))

(defun templatel--scanner-line-set (scanner value)
  "Set SCANNER's line to VALUE."
  (setf (caddr scanner) value))

(defun templatel--scanner-line-incr (scanner)
  "Increment SCANNER's line and reset col."
  (templatel--scanner-col-set scanner 0)
  (templatel--scanner-line-set scanner (+ 1 (templatel--scanner-line scanner))))

(defun templatel--scanner-col (scanner)
  "Column the SCANNER's cursor is in."
  (cadddr scanner))

(defun templatel--scanner-col-set (scanner value)
  "Set column of the SCANNER as VALUE."
  (setf (cadddr scanner) value))

(defun templatel--scanner-col-incr (scanner)
  "Increment SCANNER's col."
  (templatel--scanner-col-set scanner (+ 1 (templatel--scanner-col scanner))))

(defun templatel--scanner-state (scanner)
  "Return a copy o SCANNER's state."
  (copy-sequence (cdr scanner)))

(defun templatel--scanner-state-set (scanner state)
  "Set SCANNER's state with STATE."
  (templatel--scanner-cursor-set scanner (car state))
  (templatel--scanner-line-set scanner (cadr state))
  (templatel--scanner-col-set scanner (caddr state)))

(defun templatel--scanner-current (scanner)
  "Peak the nth cursor of SCANNER's input."
  (if (templatel--scanner-eos scanner)
      (templatel--scanner-error scanner "EOF")
    (elt (templatel--scanner-input scanner)
         (templatel--scanner-cursor scanner))))

(defun templatel--scanner-error (_scanner msg)
  "Generate error in SCANNER and document with MSG."
  (signal 'templatel-backtracking msg))

(defun templatel--scanner-eos (scanner)
  "Return t if cursor is at the end of SCANNER's input."
  (eq (templatel--scanner-cursor scanner)
      (length (templatel--scanner-input scanner))))

(defun templatel--scanner-next (scanner)
  "Push SCANNER's cursor one character."
  (if (templatel--scanner-eos scanner)
      (templatel--scanner-error scanner "EOF")
    (progn
      (templatel--scanner-col-incr scanner)
      (templatel--scanner-cursor-incr scanner))))

(defun templatel--scanner-any (scanner)
  "Match any character on SCANNER's input minus EOF."
  (let ((current (templatel--scanner-current scanner)))
    (templatel--scanner-next scanner)
    current))

(defun templatel--scanner-match (scanner c)
  "Match current character under SCANNER's to C."
  (if (eq c (templatel--scanner-current scanner))
      (progn (templatel--scanner-next scanner) c)
    (templatel--scanner-error scanner
                              (format
                               "Expected %s, got %s" c (templatel--scanner-current scanner)))))

(defun templatel--scanner-matchs (scanner s)
  "Match SCANNER's input to string S."
  (mapcar (lambda (i) (templatel--scanner-match scanner i)) s))

(defun templatel--scanner-range (scanner a b)
  "Succeed if SCANNER's current entry is between A and B."
  (let ((c (templatel--scanner-current scanner)))
    (if (and (>= c a) (<= c b))
        (templatel--scanner-any scanner)
      (templatel--scanner-error scanner (format "Expected %s-%s, got %s" a b c)))))

(defun templatel--scanner-or (scanner options)
  "Read the first one of OPTIONS that works SCANNER."
  (if (null options)
      (templatel--scanner-error scanner "No valid options")
    (let ((state (templatel--scanner-state scanner)))
      (condition-case nil
          (funcall (car options))
        (templatel-internal
         (progn (templatel--scanner-state-set scanner state)
                (templatel--scanner-or scanner (cdr options))))))))

(defun templatel--scanner-optional (scanner expr)
  "Read EXPR from SCANNER returning nil if it fails."
  (let ((state (templatel--scanner-state scanner)))
    (condition-case nil
        (funcall expr)
      (templatel-internal
       (templatel--scanner-state-set scanner state)
       nil))))

(defun templatel--scanner-not (scanner expr)
  "Fail if EXPR succeed, succeed when EXPR fail using SCANNER."
  (let ((cursor (templatel--scanner-cursor scanner))
        (succeeded (condition-case nil
                       (funcall expr)
                     (templatel-internal
                      nil))))
    (templatel--scanner-cursor-set scanner cursor)
    (if succeeded
        (templatel--scanner-error scanner "Not meant to succeed")
      t)))

(defun templatel--scanner-zero-or-more (scanner expr)
  "Read EXPR zero or more time from SCANNER."
  (let (output
        (running t))
    (while running
      (let ((state (templatel--scanner-state scanner)))
        (condition-case nil
            (setq output (cons (funcall expr) output))
          (templatel-internal
           (progn
             (templatel--scanner-state-set scanner state)
             (setq running nil))))))
    (reverse output)))

(defun templatel--scanner-one-or-more (scanner expr)
  "Read EXPR one or more time from SCANNER."
  (cons (funcall expr)
        (templatel--scanner-zero-or-more scanner expr)))

(defun templatel--token-expr-op (scanner)
  "Read '{{' off SCANNER's input."
  (templatel--scanner-matchs scanner "{{"))

(defun templatel--token-stm-op- (scanner)
  "Read '{%' off SCANNER's input."
  (templatel--scanner-matchs scanner "{%"))

(defun templatel--token-stm-op (scanner)
  "Read '{%' off SCANNER's input, with optional spaces afterwards."
  (templatel--token-stm-op- scanner)
  (templatel--parser-_ scanner))

(defun templatel--token-comment-op (scanner)
  "Read '{#' off SCANNER's input."
  (templatel--scanner-matchs scanner "{#")
  (templatel--parser-_ scanner))

;; Notice these two tokens don't consume white spaces right after the
;; closing tag. That gets us a little closer to preserving entirely
;; the input provided to the parser.
(defun templatel--token-expr-cl (scanner)
  "Read '}}' off SCANNER's input."
  (templatel--scanner-matchs scanner "}}"))

(defun templatel--token-stm-cl (scanner)
  "Read '%}' off SCANNER's input."
  (templatel--scanner-matchs scanner "%}"))

(defun templatel--token-comment-cl (scanner)
  "Read '#}' off SCANNER's input."
  (templatel--scanner-matchs scanner "#}"))

(defun templatel--token-dot (scanner)
  "Read '.' off SCANNER's input."
  (templatel--scanner-matchs scanner ".")
  (templatel--parser-_ scanner))

(defun templatel--token-comma (scanner)
  "Read ',' off SCANNER's input."
  (templatel--scanner-matchs scanner ",")
  (templatel--parser-_ scanner))

(defun templatel--token-if (scanner)
  "Read 'if' off SCANNER's input."
  (templatel--scanner-matchs scanner "if")
  (templatel--parser-_ scanner))

(defun templatel--token-elif (scanner)
  "Read 'elif' off SCANNER's input."
  (templatel--scanner-matchs scanner "elif")
  (templatel--parser-_ scanner))

(defun templatel--token-else (scanner)
  "Read 'else' off SCANNER's input."
  (templatel--scanner-matchs scanner "else")
  (templatel--parser-_ scanner))

(defun templatel--token-endif (scanner)
  "Read 'endif' off SCANNER's input."
  (templatel--scanner-matchs scanner "endif")
  (templatel--parser-_ scanner))

(defun templatel--token-for (scanner)
  "Read 'for' off SCANNER's input."
  (templatel--scanner-matchs scanner "for")
  (templatel--parser-_ scanner))

(defun templatel--token-endfor (scanner)
  "Read 'endfor' off SCANNER's input."
  (templatel--scanner-matchs scanner "endfor")
  (templatel--parser-_ scanner))

(defun templatel--token-block (scanner)
  "Read 'block' off SCANNER's input."
  (templatel--scanner-matchs scanner "block")
  (templatel--parser-_ scanner))

(defun templatel--token-endblock (scanner)
  "Read 'endblock' off SCANNER's input."
  (templatel--scanner-matchs scanner "endblock")
  (templatel--parser-_ scanner))

(defun templatel--token-extends (scanner)
  "Read 'extends' off SCANNER's input."
  (templatel--scanner-matchs scanner "extends")
  (templatel--parser-_ scanner))

(defun templatel--token-include (scanner)
  "Read 'include' off SCANNER's input."
  (templatel--scanner-matchs scanner "include")
  (templatel--parser-_ scanner))

(defun templatel--token-in (scanner)
  "Read 'in' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "in")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-is (scanner)
  "Read 'is' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "is")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-and (scanner)
  "Read 'and' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "and")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-not (scanner)
  "Read 'not' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "not")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-or (scanner)
  "Read 'or' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "or")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-paren-op (scanner)
  "Read '(' off SCANNER's input."
  (templatel--scanner-matchs scanner "(")
  (templatel--parser-_ scanner))

(defun templatel--token-paren-cl (scanner)
  "Read ')' off SCANNER's input."
  (templatel--scanner-matchs scanner ")")
  (templatel--parser-_ scanner))

(defun templatel--token-| (scanner)
  "Read '|' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "|")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-+ (scanner)
  "Read '+' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "+")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-- (scanner)
  "Read '-' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "-")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-* (scanner)
  "Read '*' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "*")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-** (scanner)
  "Read '**' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "**")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-slash (scanner)
  "Read '/' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "/")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-dslash (scanner)
  "Read '//' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "//")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-= (scanner)
  "Read '=' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "=")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-== (scanner)
  "Read '==' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "==")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-!= (scanner)
  "Read '!=' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "!=")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-> (scanner)
  "Read '>' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner ">")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-< (scanner)
  "Read '<' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "<")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token->= (scanner)
  "Read '>=' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner ">=")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-<= (scanner)
  "Read '<=' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "<=")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-% (scanner)
  "Read '%' off SCANNER's input."
  ;; This is needed or allowing a cutting point to be introduced right
  ;; after the operator of a binary expression.
  (templatel--scanner-not scanner (lambda() (templatel--token-stm-cl scanner)))
  (let ((m (templatel--scanner-matchs scanner "%")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))

(defun templatel--token-^ (scanner)
  "Read '^' off SCANNER's input."
  (let ((m (templatel--scanner-matchs scanner "^")))
    (templatel--parser-_ scanner)
    (templatel--join-chars m)))



;; --- Parser ---

(defun templatel--parser-rstrip-comment (scanner thing)
  "Parse THING then try to consume spaces from SCANNER."
  (let ((value (funcall thing scanner)))
    (templatel--scanner-zero-or-more
     scanner
     (lambda() (templatel--parser-comment scanner)))
    value))

;; GR: Template            <- Comment* (Text Comment* / Statement Comment* / Expression Comment*)+
(defun templatel--parser-template (scanner)
  "Parse Template entry from SCANNER's input."
  (templatel--scanner-zero-or-more
   scanner
   (lambda() (templatel--parser-comment scanner)))
  (cons
   "Template"
   (templatel--scanner-one-or-more
    scanner
    (lambda() (templatel--scanner-or
               scanner
               (list (lambda() (templatel--parser-rstrip-comment scanner #'templatel--parser-text))
                     (lambda() (templatel--parser-rstrip-comment scanner #'templatel--parser-statement))
                     (lambda() (templatel--parser-rstrip-comment scanner #'templatel--parser-expression))))))))

;; GR: Text                <- (!(_EXPR_OPEN / _STM_OPEN / _COMMENT_OPEN) .)+
(defun templatel--parser-text (scanner)
  "Parse Text entries from SCANNER's input."
  (cons
   "Text"
   (templatel--join-chars
    (templatel--scanner-one-or-more
     scanner
     (lambda()
       (templatel--scanner-not
        scanner
        (lambda()
          (templatel--scanner-or
           scanner
           (list
            (lambda() (templatel--token-expr-op scanner))
            (lambda() (templatel--token-stm-op- scanner))
            (lambda() (templatel--token-comment-op scanner))))))
       (let ((chr (templatel--scanner-any scanner)))
         (if (eq chr ?\n)
             (templatel--scanner-line-incr scanner))
         chr))))))

;; GR: Statement           <- IfStatement
;; GR:                       / ForStatement
;; GR:                       / BlockStatement
;; GR:                       / ExtendsStatement
;; GR:                       / IncludeStatement
(defun templatel--parser-statement (scanner)
  "Parse a statement from SCANNER."
  (templatel--scanner-or
   scanner
   (list
    (lambda() (templatel--parser-if-stm scanner))
    (lambda() (templatel--parser-for-stm scanner))
    (lambda() (templatel--parser-block-stm scanner))
    (lambda() (templatel--parser-extends-stm scanner))
    (lambda() (templatel--parser-include-stm scanner)))))


;; GR: IfStatement         <- _Elif / _Else / _If Expr _STM_CLOSE Template _EndIf
(defun templatel--parser-if-stm (scanner)
  "SCANNER."
  (templatel--scanner-or
   scanner
   (list (lambda() (templatel--parser-if-stm-elif scanner))
         (lambda() (templatel--parser-if-stm-else scanner))
         (lambda() (templatel--parser-if-stm-endif scanner)))))

(defun templatel--parser-stm-cl (scanner)
  "Read stm-cl off SCANNER or error out if it's not there."
  (templatel--parser-cut
   scanner
   (lambda() (templatel--token-stm-cl scanner))
   "Statement not closed with \"%}\""))

;; GR: _Elif               <- _If Expr _STM_CLOSE Template Elif+ Else?
(defun templatel--parser-if-stm-elif (scanner)
  "Parse elif from SCANNER."
  (templatel--parser-if scanner)
  (let* ((expr (templatel--parser-expr scanner))
         (_ (templatel--parser-stm-cl scanner))
         (tmpl (templatel--parser-template scanner))
         (elif (templatel--scanner-one-or-more scanner (lambda() (templatel--parser-elif scanner))))
         (else (templatel--scanner-optional scanner (lambda() (templatel--parser-else scanner)))))
    (if else
        (cons "IfElif" (list expr tmpl elif else))
      (progn
        (templatel--parser-endif scanner)
        (cons "IfElif" (list expr tmpl elif))))))

;; GR: _Else               <- _If Expr _STM_CLOSE Template Else
(defun templatel--parser-if-stm-else (scanner)
  "Parse else from SCANNER."
  (templatel--parser-if scanner)
  (let* ((expr (templatel--parser-expr scanner))
         (_ (templatel--parser-stm-cl scanner))
         (tmpl (templatel--parser-template scanner))
         (else (templatel--parser-else scanner)))
    (cons "IfElse" (list expr tmpl else))))

;; _If Expr _STM_CLOSE Template _EndIf  -- No grammar annotation because it's repeated
(defun templatel--parser-if-stm-endif (scanner)
  "Parse endif from SCANNER."
  (templatel--parser-if scanner)
  (let* ((expr (templatel--parser-expr scanner))
         (_    (templatel--parser-stm-cl scanner))
         (tmpl (templatel--parser-template scanner))
         (_    (templatel--parser-endif scanner)))
    (cons "IfStatement" (list expr tmpl))))

;; GR: Elif                <- _STM_OPEN _elif Expr _STM_CLOSE Template
(defun templatel--parser-elif (scanner)
  "Parse elif expression off SCANNER."
  (templatel--token-stm-op scanner)
  (templatel--token-elif scanner)
  (let ((expr (templatel--parser-expr scanner))
        (_    (templatel--parser-stm-cl scanner))
        (tmpl (templatel--parser-template scanner)))
    (cons "Elif" (list expr tmpl))))

;; GR: _If                 <- _STM_OPEN _if
(defun templatel--parser-if (scanner)
  "Parse if condition off SCANNER."
  (templatel--token-stm-op scanner)
  (templatel--token-if scanner))

;; GR: Else                <- _STM_OPEN _else _STM_CLOSE Template _EndIf
(defun templatel--parser-else (scanner)
  "Parse else expression off SCANNER."
  (templatel--token-stm-op scanner)
  (templatel--token-else scanner)
  (templatel--parser-stm-cl scanner)
  (let ((tmpl (templatel--parser-template scanner)))
    (templatel--parser-endif scanner)
    (cons "Else" (list tmpl))))

;; GR: _EndIf              <- _STM_OPEN _endif _STM_CLOSE
(defun templatel--parser-endif (scanner)
  "Parse endif tag off SCANNER."
  (templatel--parser-cut
   scanner
   (lambda()
     (templatel--token-stm-op scanner)
     (templatel--token-endif scanner)
     (templatel--parser-stm-cl scanner))
   "Missing endif statement"))

;; GR: ForStatement        <- _For Expr _in Expr _STM_CLOSE Template _EndFor
;; GR: _For                <- _STM_OPEN _for
(defun templatel--parser-for-stm (scanner)
  "Parse for statement from SCANNER."
  (templatel--token-stm-op scanner)
  (templatel--token-for scanner)
  (let ((iter (templatel--parser-identifier scanner))
        (_ (templatel--token-in scanner))
        (iterable (templatel--parser-expr scanner))
        (_ (templatel--parser-stm-cl scanner))
        (tmpl (templatel--parser-template scanner))
        (_ (templatel--parser-endfor scanner)))
    (cons "ForStatement" (list iter iterable tmpl))))

;; GR: _EndFor             <- _STM_OPEN _endfor _STM_CLOSE
(defun templatel--parser-endfor (scanner)
  "Parse {% endfor %} statement from SCANNER."
  (templatel--parser-cut
   scanner
   (lambda()
     (templatel--token-stm-op scanner)
     (templatel--token-endfor scanner)
     (templatel--parser-stm-cl scanner))
   "Missing endfor statement"))

;; GR: BlockStatement      <- _Block String _STM_CLOSE Template? _EndBlock
(defun templatel--parser-block-stm (scanner)
  "Parse block statement from SCANNER."
  (templatel--token-stm-op scanner)
  (templatel--token-block scanner)
  (let ((name (templatel--parser-cut
               scanner
               (lambda() (templatel--parser-identifier scanner))
               "Missing block name"))
        (_ (templatel--parser-_ scanner))
        (_ (templatel--parser-stm-cl scanner))
        (tmpl (templatel--scanner-optional
               scanner
               (lambda() (templatel--parser-template scanner)))))
    (templatel--parser-endblock scanner)
    (cons "BlockStatement" (list name tmpl))))

;; GR: _EndBlock           <- _STM_OPEN _endblock _STM_CLOSE
(defun templatel--parser-endblock (scanner)
  "Parse {% endblock %} statement from SCANNER."
  (templatel--parser-cut
   scanner
   (lambda()
     (templatel--token-stm-op scanner)
     (templatel--token-endblock scanner)
     (templatel--parser-stm-cl scanner))
   "Missing endblock statement"))

;; GR: ExtendsStatement    <- _STM_OPEN _extends String _STM_CLOSE
(defun templatel--parser-extends-stm (scanner)
  "Parse extends statement from SCANNER."
  (templatel--token-stm-op scanner)
  (templatel--token-extends scanner)
  (let ((name (templatel--parser-cut
               scanner
               (lambda() (templatel--parser-string scanner))
               "Missing template name in extends statement")))
    (templatel--parser-_ scanner)
    (templatel--parser-stm-cl scanner)
    (cons "ExtendsStatement" (list name))))

;; GR: IncludeStatement    <- _STM_OPEN _include String _STM_CLOSE
(defun templatel--parser-include-stm (scanner)
  "Parse extends statement from SCANNER."
  (templatel--token-stm-op scanner)
  (templatel--token-include scanner)
  (let ((name (templatel--parser-cut
               scanner
               (lambda() (templatel--parser-string scanner))
               "Missing template name in include statement")))
    (templatel--parser-_ scanner)
    (templatel--parser-stm-cl scanner)
    (cons "IncludeStatement" (list name))))

;; GR: Expression          <- _EXPR_OPEN Expr _EXPR_CLOSE
(defun templatel--parser-expression (scanner)
  "SCANNER."
  (templatel--token-expr-op scanner)
  (templatel--parser-_ scanner)
  (let ((expr (templatel--parser-expr scanner)))
    (templatel--parser-cut
     scanner
     (lambda() (templatel--token-expr-cl scanner))
     "Unclosed bracket")
    (cons "Expression" (list expr))))

;; GR: Expr                <- Logical
(defun templatel--parser-expr (scanner)
  "Read an expression from SCANNER."
  (cons
   "Expr"
   (list (templatel--parser-logical scanner))))

(defun templatel--parser-cut (scanner fn msg)
  "Try to parse FN off SCANNER or error with MSG.

There are two types of errors emitted by this parser:
 1. Backtracking (internal), which is caught by most scanner
    functions, like templatel--scanner-or and templatel--scanner-zero-or-more.
 2. Syntax Error (public), which signals an unrecoverable parsing
    error.

This function catches backtracking errors and transform them in
syntax errors.  It must be carefully explicitly on places where
backtracking should be interrupted earlier."
  (condition-case nil
      (funcall fn)
    (templatel-internal
     (signal 'templatel-syntax-error
             (format "%s at %s,%s: %s"
                     (or (templatel--scanner-file scanner) "<string>")
                     (1+ (templatel--scanner-line scanner))
                     (1+ (templatel--scanner-col scanner))
                     msg)))))

(defun templatel--parser-item-or-named-collection (name first rest)
  "NAME FIRST REST."
  (if (null rest)
      first
    (cons name (cons first rest))))

(defun templatel--parser-binary (scanner name randfn ratorfn)
  "Parse binary operator NAME from SCANNER.

A binary operator needs two functions: one for reading the
operands (RANDFN) and another one to read the
operator (RATORFN)."
  (templatel--parser-item-or-named-collection
   (if (null name) "BinOp" name)
   (funcall randfn scanner)
   (templatel--scanner-zero-or-more
    scanner
    (lambda()
      (cons
       (funcall ratorfn scanner)
       (templatel--parser-cut
        scanner
        (lambda() (funcall randfn scanner))
        "Missing operand after binary operator"))))))

;; GR: Logical             <- Comparison ((AND / OR) Comparison)*
(defun templatel--parser-logical (scanner)
  "Read Logical from SCANNER."
  (templatel--parser-binary
   scanner
   nil ; "Logical"
   #'templatel--parser-comparison
   (lambda(s)
     (templatel--scanner-or
      s
      (list
       (lambda() (templatel--token-and s))
       (lambda() (templatel--token-or s)))))))

;; GR: Comparison          <- Term ((EQ / NEQ / LTE / GTE / LT / GT / IN) Term)*
(defun templatel--parser-comparison (scanner)
  "Read a Comparison from SCANNER."
  (templatel--parser-binary
   scanner
   nil ; "Comparison"
   #'templatel--parser-term
   (lambda(s)
     (templatel--scanner-or
      s
      (list
       (lambda() (templatel--token-== s))
       (lambda() (templatel--token-!= s))
       (lambda() (templatel--token-<= s))
       (lambda() (templatel--token->= s))
       (lambda() (templatel--token-< s))
       (lambda() (templatel--token-> s))
       (lambda() (templatel--token-in s)))))))

;; GR: Term                <- Factor ((PLUS / MINUS) Factor)*
(defun templatel--parser-term (scanner)
  "Read Term from SCANNER."
  (templatel--parser-binary
   scanner
   nil ; "Term"
   #'templatel--parser-factor
   (lambda(s)
     (templatel--scanner-or
      s
      (list
       (lambda() (templatel--token-+ s))
       (lambda() (templatel--token-- s)))))))

;; GR: Factor              <- Power ((STAR / DSLASH / SLASH) Power)*
(defun templatel--parser-factor (scanner)
  "Read Factor from SCANNER."
  (templatel--parser-binary
   scanner
   nil ; "Factor"
   #'templatel--parser-power
   (lambda(s)
     (templatel--scanner-or
      s
      (list
       (lambda() (templatel--token-* s))
       (lambda() (templatel--token-slash s))
       (lambda() (templatel--token-dslash s)))))))

;; GR: Power               <- Test ((POWER / MOD) Test)*
(defun templatel--parser-power (scanner)
  "Read Power from SCANNER."
  (templatel--parser-binary
   scanner
   nil ; "Power"
   #'templatel--parser-test
   (lambda(s)
     (templatel--scanner-or
      s
      (list
       (lambda() (templatel--token-** s))
       (lambda() (templatel--token-% s)))))))

;; GR: Test              <- Filter (_IS Filter)*
(defun templatel--parser-test (scanner)
  "Read Test from SCANNER."
  (templatel--parser-binary
   scanner
   "Test"
   #'templatel--parser-filter #'templatel--token-is))

;; GR: Filter              <- Unary (_PIPE Unary)*
(defun templatel--parser-filter (scanner)
  "Read Filter from SCANNER."
  (templatel--parser-binary
   scanner
   "Filter"
   #'templatel--parser-unary #'templatel--token-|))

;; GR: UnaryOp             <- PLUS / MINUS / NOT / BNOT
(defun templatel--parser-unary-op (scanner)
  "Read an Unary operator from SCANNER."
  (templatel--scanner-or
   scanner
   (list
    (lambda() (templatel--token-+ scanner))
    (lambda() (templatel--token-- scanner))
    (lambda() (templatel--token-not scanner)))))

;; GR: Unary               <- UnaryOp Unary / UnaryOp Primary / Primary
(defun templatel--parser-unary (scanner)
  "Read Unary from SCANNER."
  (templatel--scanner-or
   scanner
   (list
    (lambda()
      (cons
       "Unary"
       (list
        (templatel--parser-unary-op scanner)
        (templatel--parser-unary scanner))))
    (lambda()
      (cons
       "Unary"
       (list
        (templatel--parser-unary-op scanner)
        (templatel--parser-cut
         scanner
         (lambda() (templatel--parser-primary scanner))
         "Missing operand after unary operator"))))
    (lambda() (templatel--parser-primary scanner)))))

;; GR: Primary             <- _PAREN_OPEN Expr _PAREN_CLOSE
;; GR:                      / Element
(defun templatel--parser-primary (scanner)
  "Read Primary from SCANNER."
  (templatel--scanner-or
   scanner
   (list
    (lambda()
      (templatel--token-paren-op scanner)
      (let ((expr (templatel--parser-expr scanner)))
        (templatel--token-paren-cl scanner)
        expr))
    (lambda() (templatel--parser-element scanner)))))

;; GR: Attribute           <- Identifier (_dot Identifier)+
(defun templatel--parser-attribute (scanner)
  "Read an Attribute from SCANNER."
  (cons
   "Attribute"
   (cons
    (templatel--parser-identifier scanner)
    (templatel--scanner-one-or-more
     scanner
     (lambda()
       (templatel--token-dot scanner)
       (templatel--parser-identifier scanner))))))

;; GR: Element             <- Value / Attribute / FnCall / Identifier
(defun templatel--parser-element (scanner)
  "Read Element off SCANNER."
  (cons
   "Element"
   (list
    (templatel--scanner-or
     scanner
     (list
      (lambda() (templatel--parser-value scanner))
      (lambda() (templatel--parser-attribute scanner))
      (lambda() (templatel--parser-fncall scanner))
      (lambda() (templatel--parser-identifier scanner)))))))

(defun templatel--parser-paren-cl (scanner)
  "Read a closed parentheses with a cutting point from SCANNER."
  (templatel--parser-cut
   scanner
   (lambda() (templatel--token-paren-cl scanner))
   "Unclosed parentheses"))

;; GR: FnCall              <- Identifier ParamList
(defun templatel--parser-fncall (scanner)
  "Read FnCall off SCANNER."
  (cons
   "FnCall"
   (cons
    (templatel--parser-identifier scanner)
    (templatel--parser-paramlist scanner))))

;; GR: ParamList           <- _ParamListOnlyNamed
;; GR:                      / _ParamListPosNamed
;; GR:                      / _ParamListOnlyPos
;; GR:                      / _PAREN_OPEN _PAREN_CLOSE
(defun templatel--parser-paramlist (scanner)
  "Read parameter list off SCANNER."
  (templatel--scanner-or
   scanner
   (list
    (lambda() (templatel--parser--paramlist-only-named scanner))
    (lambda() (templatel--parser--paramlist-pos-named scanner))
    (lambda() (templatel--parser--paramlist-only-pos scanner))
    (lambda()
      (templatel--token-paren-op scanner)
      (templatel--parser-paren-cl scanner)
      nil))))

;; GR: _ParamListOnlyNamed <- _PAREN_OPEN NamedParams _PAREN_CLOSE
(defun templatel--parser--paramlist-only-named (scanner)
  "Read exclusively named params from SCANNER."
  (templatel--token-paren-op scanner)
  (let ((params (templatel--parser-namedparams scanner)))
    (templatel--parser-paren-cl scanner)
    params))

;; GR: _ParamListPosNamed  <- _PAREN_OPEN Params NamedParams _PAREN_CLOSE
(defun templatel--parser--paramlist-pos-named (scanner)
  "Read positionnal and named parameters from SCANNER."
  (templatel--token-paren-op scanner)
  (let* ((positional (templatel--parser-params scanner))
         (_ (templatel--token-comma scanner))
         (named (templatel--parser-namedparams scanner)))
    (templatel--parser-paren-cl scanner)
    (append named positional)))

;; GR: _ParamListOnlyPos   <- _PAREN_OPEN Params _PAREN_CLOSE
(defun templatel--parser--paramlist-only-pos (scanner)
  "Read parameter list from SCANNER."
  (templatel--token-paren-op scanner)
  (let ((params (templatel--parser-params scanner)))
    (templatel--parser-paren-cl scanner)
    params))

;; GR: Params              <- Expr (_COMMA Expr !_EQ)*
(defun templatel--parser-params (scanner)
  "Read a list of parameters off SCANNER."
  (let ((first (templatel--parser-expr scanner))
        (rest (templatel--scanner-zero-or-more
               scanner
               (lambda()
                 (templatel--token-comma scanner)
                 (let ((expr (templatel--parser-expr scanner)))
                   ;; Only named params have this extra sign
                   (templatel--scanner-not
                    scanner
                    (lambda() (templatel--token-= scanner)))
                   expr)))))
    (cons first rest)))

;; GR: NamedParams         <- NamedParam (_COMMA NamedParam)*
(defun templatel--parser-namedparams (scanner)
  "Read a list of named parameters off SCANNER."
  (let ((first (templatel--parser-namedparam scanner))
        (rest (templatel--scanner-zero-or-more
               scanner
               (lambda()
                 (templatel--token-comma scanner)
                 (templatel--parser-namedparam scanner)))))
    (list (cons "NamedParams" (cons first rest)))))

;; GR: NamedParam          <- Identifier _EQ Expr
(defun templatel--parser-namedparam (scanner)
  "Read one named parameter off SCANNER."
  (let ((id (templatel--parser-identifier scanner)))
    (templatel--token-= scanner)
    (list id (templatel--parser-expr scanner))))

;; GR: Value               <- Number / BOOL / NIL / String
(defun templatel--parser-value (scanner)
  "Read Value from SCANNER."
  (let ((value (templatel--scanner-or
                scanner
                (list
                 (lambda() (templatel--parser-number scanner))
                 (lambda() (templatel--parser-bool scanner))
                 (lambda() (templatel--parser-nil scanner))
                 (lambda() (templatel--parser-string scanner))))))
    (templatel--parser-_ scanner)
    value))

;; GR: Number              <- BIN / HEX / FLOAT / INT
(defun templatel--parser-number (scanner)
  "Read Number off SCANNER."
  (cons
   "Number"
   (templatel--scanner-or
    scanner
    (list
     (lambda() (templatel--parser-bin scanner))
     (lambda() (templatel--parser-hex scanner))
     (lambda() (templatel--parser-float scanner))
     (lambda() (templatel--parser-int scanner))))))

;; GR: INT                 <- [0-9]+                  _
(defun templatel--parser-int (scanner)
  "Read integer off SCANNER."
  (string-to-number
   (templatel--join-chars
    (templatel--scanner-one-or-more
     scanner
     (lambda() (templatel--scanner-range scanner ?0 ?9))))
   10))

;; GR: FLOAT               <- [0-9]* '.' [0-9]+       _
(defun templatel--parser-float (scanner)
  "Read float from SCANNER."
  (string-to-number
   (templatel--join-chars
    (append
     (templatel--scanner-zero-or-more
      scanner (lambda() (templatel--scanner-range scanner ?0 ?9)))
     (templatel--scanner-matchs
      scanner ".")
     (templatel--scanner-one-or-more
      scanner (lambda() (templatel--scanner-range scanner ?0 ?9)))))))

;; GR: BIN                 <- '0b' [0-1]+             _
(defun templatel--parser-bin (scanner)
  "Read binary number from SCANNER."
  (templatel--scanner-matchs scanner "0b")
  (string-to-number
   (templatel--join-chars
    (append
     (templatel--scanner-one-or-more
      scanner
      (lambda() (templatel--scanner-range scanner ?0 ?1)))))
   2))

;; GR: HEX                 <- '0x' [0-9a-fA-F]+       _
(defun templatel--parser-hex (scanner)
  "Read hex number from SCANNER."
  (templatel--scanner-matchs scanner "0x")
  (string-to-number
   (templatel--join-chars
    (append
     (templatel--scanner-one-or-more
      scanner
      (lambda()
        (templatel--scanner-or
         scanner
         (list (lambda() (templatel--scanner-range scanner ?0 ?9))
               (lambda() (templatel--scanner-range scanner ?a ?f))
               (lambda() (templatel--scanner-range scanner ?A ?F))))))))
   16))

;; GR: BOOL                <- ('true' / 'false')         _
(defun templatel--parser-bool (scanner)
  "Read boolean value from SCANNER."
  (cons
   "Bool"
   (templatel--scanner-or
    scanner
    (list (lambda() (templatel--scanner-matchs scanner "true") t)
          (lambda() (templatel--scanner-matchs scanner "false") nil)))))

;; GR: NIL                 <- 'nil'                      _
(defun templatel--parser-nil (scanner)
  "Read nil constant from SCANNER."
  (templatel--scanner-matchs scanner "nil")
  (cons "Nil" nil))

;; GR: String              <- _QUOTE (!_QUOTE .)* _QUOTE _
(defun templatel--parser-string (scanner)
  "Read a double quoted string from SCANNER."
  (templatel--scanner-match scanner ?\")
  (let ((str (templatel--scanner-zero-or-more
              scanner
              (lambda()
                (templatel--scanner-not
                 scanner
                 (lambda() (templatel--scanner-match scanner ?\")))
                (templatel--scanner-any scanner)))))
    (templatel--scanner-match scanner ?\")
    (cons "String" (templatel--join-chars str))))

;; GR: IdentStart          <- [a-zA-Z_]
(defun templatel--parser-identstart (scanner)
  "Read the first character of an identifier from SCANNER."
  (templatel--scanner-or
   scanner
   (list (lambda() (templatel--scanner-range scanner ?a ?z))
         (lambda() (templatel--scanner-range scanner ?A ?Z))
         (lambda() (templatel--scanner-match scanner ?_)))))

;; GR: IdentCont           <- [a-zA-Z0-9_]*  _
(defun templatel--parser-identcont (scanner)
  "Read the rest of an identifier from SCANNER."
  (templatel--scanner-zero-or-more
   scanner
   (lambda()
     (templatel--scanner-or
      scanner
      (list (lambda() (templatel--scanner-range scanner ?a ?z))
            (lambda() (templatel--scanner-range scanner ?A ?Z))
            (lambda() (templatel--scanner-range scanner ?0 ?9))
            (lambda() (templatel--scanner-match scanner ?_)))))))

;; GR: Identifier          <- IdentStart IdentCont
(defun templatel--parser-identifier (scanner)
  "Read Identifier entry from SCANNER."
  (cons
   "Identifier"
   (let ((identifier (templatel--join-chars
                      (cons (templatel--parser-identstart scanner)
                            (templatel--parser-identcont scanner)))))
     (templatel--parser-_ scanner)
     identifier)))

;; GR: _                   <- (Space / Comment)*
(defun templatel--parser-_ (scanner)
  "Read whitespaces from SCANNER."
  (templatel--scanner-zero-or-more
   scanner
   (lambda()
     (templatel--scanner-or
      scanner
      (list
       (lambda() (templatel--parser-space scanner))
       (lambda() (templatel--parser-comment scanner)))))))

;; GR: Space               <- ' ' / '\t' / _EOL
(defun templatel--parser-space (scanner)
  "Consume spaces off SCANNER."
  (templatel--scanner-or
   scanner
   (list
    (lambda() (templatel--scanner-matchs scanner " "))
    (lambda() (templatel--scanner-matchs scanner "\t"))
    (lambda() (templatel--parser-eol scanner)))))

;; GR: _EOL                <- '\r\n' / '\n' / '\r'
(defun templatel--parser-eol (scanner)
  "Read end of line from SCANNER."
  (let ((eol (templatel--scanner-or
              scanner
              (list
               (lambda() (templatel--scanner-matchs scanner "\r\n"))
               (lambda() (templatel--scanner-matchs scanner "\n"))
               (lambda() (templatel--scanner-matchs scanner "\r"))))))
    (templatel--scanner-line-incr scanner)
    eol))

;; GR: Comment             <- "{#" (!"#}" .)* "#}"
(defun templatel--parser-comment (scanner)
  "Read comment from SCANNER."
  (templatel--token-comment-op scanner)
  (let ((str (templatel--scanner-zero-or-more
              scanner
              (lambda()
                (templatel--scanner-not
                 scanner
                 (lambda() (templatel--token-comment-cl scanner)))
                (templatel--scanner-any scanner)))))
    (templatel--token-comment-cl scanner)
    (cons "Comment" (templatel--join-chars str))))



;; --- Compiler/Runtime ---

(defun templatel--runtime (tree state code)
  "Boilerplate for runtime that can execute templates or blocks.

TREE takes the code that has already been compiled and needs a
runtime to be executed.

STATE is an alist with variables for extending the internal state
of the runtime.  They're mostly needed to give flexibility for
storing state that allows different runtimes to coordinate with
`templatel--compiler-block'.

And CODE is what gets executed right after the rendering is
finished."
  `(lambda(&rest runtime)
     (defun rt/get(key)
       (car (alist-get key (seq-partition runtime 2))))
     (let* (,@state
            (rt/blocks (make-hash-table :test 'equal))
            (rt/parent nil)
            (rt/parent-template nil)
            (rt/parent-blocks nil)
            (rt/varstk (list (rt/get :vars)))
            (rt/valstk (list))
            (rt/filters '(("abs"         . templatel-filters-abs)
                          ("attr"        . templatel-filters-attr)
                          ("capitalize"  . templatel-filters-capitalize)
                          ("default"     . templatel-filters-default)
                          ("escape"      . templatel-filters-escape)
                          ("e"           . templatel-filters-escape)
                          ("first"       . templatel-filters-first)
                          ("float"       . templatel-filters-float)
                          ("int"         . templatel-filters-int)
                          ("join"        . templatel-filters-join)
                          ("last"        . templatel-filters-last)
                          ("length"      . templatel-filters-length)
                          ("lower"       . templatel-filters-lower)
                          ("max"         . templatel-filters-max)
                          ("min"         . templatel-filters-min)
                          ("round"       . templatel-filters-round)
                          ("safe"        . templatel-filters-safe)
                          ("sort"        . templatel-filters-sort)
                          ("sum"         . templatel-filters-sum)
                          ("take"        . templatel-filters-take)
                          ("title"       . templatel-filters-title)
                          ("upper"       . templatel-filters-upper)
                          ;; Exclusive to templatel
                          ("plus1"       . templatel-filters-plus1)
                          ;; deprecated in favor of `attr` filter.
                          ("getattr"     . templatel-filters-attr)))

            (rt/tests '(("defined"       . templatel-tests-defined)
                        ("divisible"     . templatel-tests-divisible)))

            (rt/lookup-var
             (lambda(name)
               (catch '-brk
                 (dolist (ivars (reverse rt/varstk))
                   (let ((value (assoc name ivars)))
                     (unless (null value)
                       (throw '-brk (cdr value)))))
                 'undefined)))
            (rt/lookup-block
             (lambda(name)
               (catch '-brk
                 (dolist (iblocks (reverse (append (list rt/blocks) (rt/get :blocks))))
                   (let ((value (and iblocks (gethash name iblocks))))
                     (unless (null value)
                       (throw '-brk value)))))))
            (rt/lookup-parent-block
             (lambda(name)
               (catch '-brk
                 (dolist (iblocks rt/parent-blocks)
                   (let ((value (and iblocks (gethash name iblocks))))
                     (unless (null value)
                       (throw '-brk value)))))))

            ;; The rendering of the template; here the blocks of the
            ;; current template are going to be executed and put into
            ;; the rt/blocks hash table.
            (rt/data
             (with-temp-buffer
               ,@tree
               (buffer-string))))
       ,code)))

(defun templatel--compiler-code (tree template-name)
  "Compile TEMPLATE-NAME into a function with TREE as body.

This generates code for templates, either with or without a
parent template."
  (templatel--runtime
   tree
   `((rt/template-name ,template-name)
     (rt/compiling-super nil))
   ;; return the rendered data if the root template has been
   ;; reached; otherwise, keep recursing to the parent template.
   `(if (null rt/parent)
        rt/data
      (funcall (templatel--compiler-code rt/parent rt/parent-template)
               :env (rt/get :env)
               :vars (rt/get :vars)
               :blocks (append
                        (list rt/blocks)
                        (rt/get :blocks))))))

(defun templatel--compiler-block-code (tree template-name)
  "Compile a block into a function with TREE as body.

TEMPLATE-NAME is the name of the template the block belongs to.
This exists mostly for adding this information to error
messages."
  (templatel--runtime
   tree
   `((rt/template-name ,template-name)
     (rt/compiling-super t))
   `(if (rt/get :get-data)
        rt/data
      (cons rt/blocks rt/parent-blocks))))

(defun templatel--compiler-block (tree)
  "Compile a block statement from TREE.

This function is deceivingly simple.  So deceiving that it's
actually a little complex.  It generates code that runs mutually
recursively with code generated by `templatel--compiler-code'.

The compilation of blocks is tricker than most things in the
language because of inheritance.  The blocks are collected from
leaves to the root, but the surrounding content around blocks and
blocks not overridden come from the root template.

The code generated by this function won't actually `insert' any
text in the output buffer until it is at the root template.  It
will collect the blocks of the current template within
`rt/blocks'."
  (let ((name (cdar tree))
        (body (templatel--compiler-run (cadr tree))))
    `(if rt/compiling-super
         (progn
           ,(templatel--compiler-block-with-super name body))
       ,(templatel--compiler-template-block name body))))

(defun templatel--compiler-template-block (name body)
  "Emit code for wrapping the BODY of block named NAME.

It emits the code that will apply the following rules:

 - if it is not the root template, then defer execution to code
   generated by `templatel--compiler-block-with-super';

 - if it is the root template, first try to use a block with the
   same name received recursively from the leaf template, if such
   block doesn't exist, use code received from BODY."
  `(progn
     (if (null rt/parent)
         (progn
           (let ((block (funcall rt/lookup-block ,name)))
             (if block (insert block)
               ,@body)))
       ,(templatel--compiler-block-with-super name body))))

(defun templatel--compiler-block-with-super (name body)
  "Emit code for wrapping BODY of block named NAME.

This is different from `templatel--compiler-template-block'
because this function temporarily provides the filter `super` for
the function that renders the block to have access to its parents
blocks, stored in `rt/parent-blocks'."
  `(let ((parent-block (funcall rt/lookup-parent-block ,name))
         (env (rt/get :env)))
     (templatel-env-add-filter
      env "super"
      (lambda()
        (if (templatel-env-get-autoescape env)
            (templatel-mark-safe parent-block)
          parent-block)))
     (if (rt/get :get-data)
         (progn ,@body)
       (puthash ,name
                (funcall (templatel--compiler-block-code ',body rt/template-name)
                         :env (rt/get :env)
                         :vars (rt/get :vars)
                         :get-data t)
                rt/blocks))
     (templatel-env-remove-filter env "super")))

(defun templatel--compiler-extends (tree)
  "Compile an extends statement from TREE.

The name of the template will be saved in `rt/parent-template',
the unwrapped code retrieved via `templatel--env-run-importfn'
will be saved in `rt/parent' and the blocks of the parent
template in `rt/parent-blocks'.

This function calls out to `templatel--compiler-block-code' for
recursivelly building a set of all the parents blocks that will
be inspected by `rt/lookup-parent-block'."
  `(progn
     (setq rt/parent-template ,(cdar tree))
     (setq rt/parent
           (templatel--env-run-importfn (rt/get :env) rt/parent-template))
     (setq rt/parent-blocks
           (apply (templatel--compiler-block-code rt/parent rt/parent-template) runtime))))

(defun templatel--compiler-include (tree)
  "Compile an include statement from TREE.

The include statement takes a name of a template that is imported
via ~:importfn~ (see
[[anchor:symbol-templatel-env-new][templatel-env-new]]).

The imported template is then rendered and its output is inserted
into the output buffer."
  `(progn
     (templatel--env-run-importfn (rt/get :env) ,(cdar tree))
     (insert (templatel-env-render (rt/get :env) ,(cdar tree) (rt/get :vars)))))

(defun templatel--compiler-element (tree)
  "Compile an element from TREE."
  `(let ((value ,@(templatel--compiler-run tree)))
     (push value rt/valstk)
     value))

(defun templatel--compiler-expr (tree)
  "Compile an expr from TREE."
  `(progn
     ,@(mapcar #'templatel--compiler-run tree)))

(defun templatel--compiler--attr (tree)
  "Walk through attributes on TREE."
  (if (null (cdr tree))
      (templatel--compiler-identifier (cdar tree))
    `(let ((el (assoc ,(cdar tree) ,(templatel--compiler--attr (cdr tree)))))
       (if el
           (cdr el)
         'undefined))))

(defun templatel--compiler-attribute (tree)
  "Compile attribute access from TREE."
  (templatel--compiler--attr (reverse tree)))

(defun templatel--compiler-get-filter (name)
  "Produce accessor for filter NAME."
  `(or (assoc ,name rt/filters)
       (templatel--env-filter (rt/get :env) ,name)))

(defun templatel--compiler-filter-fncall-standalone (item)
  "Compiler standalone filter with params from ITEM.

Example:

  {{ fn(val) }}

Will be converted into the following:

  (fn val)

Notice the parameter list is compiled before being passed to the
function call."
  (let ((fname (cdar item))
        (params (cdr item)))
    `(let ((entry ,(templatel--compiler-get-filter fname)))
       (if (null entry)
           (signal
            'templatel-runtime-error
            (format "Filter `%s' doesn't exist" ,fname))
         (car
          (progn
            ,@(templatel--compiler-run params)
            (push (apply
                   (cdr entry)
                   (mapcar (lambda(_) (pop rt/valstk)) ',params))
                  rt/valstk)))))))

(defun templatel--compiler-filter-identifier (item)
  "Compile a filter without params from ITEM.

This filter takes a single parameter: the value being piped into
it.  The code generated must first ensure that such filter is
registered in the local `filters' variable, failing if it isn't.
If the filter exists, it must then call its associated handler."
  (let ((fname (cdar (cdr item))))
    `(let ((entry ,(templatel--compiler-get-filter fname)))
       (if (null entry)
           (signal
            'templatel-runtime-error
            (format "Filter `%s' doesn't exist" ,fname))
         (push (funcall (cdr entry) (pop rt/valstk)) rt/valstk)))))

(defun templatel--compiler-filter-fncall (item)
  "Compiler filter with params from ITEM.

A filter can have multiple parameters.  In that case, the value
piped into the filter becomes the first parameter and the other
parameters are shifted to accommodate this change.  E.g.:

  {{ number | int(16) }}

Will be converted into the following:

  (int number 16)

Notice the parameter list is compiled before being passed to the
function call."
  (let ((fname (cdr (cadr (cadr item))))
        (params (cddr (cadr item))))
    `(let ((entry ,(templatel--compiler-get-filter fname)))
       (if (null entry)
           (signal
            'templatel-runtime-error
            (format "Filter `%s' doesn't exist" ,fname))
         (push (apply
                (cdr entry)
                (cons (pop rt/valstk)
                      (list ,@(templatel--compiler-run params))))
               rt/valstk)))))

(defun templatel--compiler-filter-item (item)
  "Handle compilation of single filter described by ITEM.

This function routes the item to be compiled to the appropriate
function.  A filter could be either just an identifier or a
function call."
  (if (string= (caar (cddr item)) "Identifier")
      (templatel--compiler-filter-identifier (cdr item))
    (templatel--compiler-filter-fncall (cdr item))))

(defun templatel--compiler-filter-list (tree)
  "Compile filters from TREE.

TREE contains a list of filters that can be either Identifiers or
FnCalls.  This functions job is to iterate over the this list and
call `templatel--compiler-filter-item' on each entry."
  `(progn
     ,(templatel--compiler-run (car tree))
     ,@(mapcar #'templatel--compiler-filter-item (cdr tree))))

(defun templatel--compiler-get-test (name)
  "Produce accessor for test NAME."
  `(or (assoc ,name rt/tests)
       (templatel--env-test (rt/get :env) ,name)))

(defun templatel--compiler-test-identifier (item)
  "Compile a test without params from ITEM.

This test takes a single parameter: the value being piped into
it.  The code generated must first ensure that such test is
registered in the local `tests' variable, failing if it isn't.
If the test exists, it must then call its associated handler."
  (let ((fname (cdar (cdr item))))
    `(let ((entry ,(templatel--compiler-get-test fname)))
       (if (null entry)
           (signal
            'templatel-runtime-error
            (format "Test `%s' doesn't exist" ,fname))
         (push (funcall (cdr entry) (pop rt/valstk)) rt/valstk)))))

(defun templatel--compiler-test-fncall (item)
  "Compiler test with params from ITEM.

A test can have multiple parameters.  In that case, the value
piped into the test becomes the first parameter and the other
parameters are shifted to accommodate this change.  E.g.:

  {{ number | int(16) }}

Will be converted into the following:

  (int number 16)

Notice the parameter list is compiled before being passed to the
function call."
  (let ((fname (cdr (cadr (cadr item))))
        (params (cddr (cadr item))))
    `(let ((entry ,(templatel--compiler-get-test fname)))
       (if (null entry)
           (signal
            'templatel-runtime-error
            (format "Test `%s' doesn't exist" ,fname))
         (push (apply
                (cdr entry)
                (cons (pop rt/valstk)
                      (list ,@(templatel--compiler-run params))))
               rt/valstk)))))

(defun templatel--compiler-test-item (item)
  "Handle compilation of single test described by ITEM.

This function routes the item to be compiled to the appropriate
function.  A test could be either just an identifier or a
function call."
  (if (string= (caar (cddr item)) "Identifier")
      (templatel--compiler-test-identifier (cdr item))
    (templatel--compiler-test-fncall (cdr item))))

(defun templatel--compiler-test-list (tree)
  "Compile a test from TREE."
  `(progn
     ,(templatel--compiler-run (car tree))
     ,@(mapcar #'templatel--compiler-test-item (cdr tree))))

(defun templatel--compiler-named-param (tree)
  "Compile named param from TREE."
  `(progn
     ;; pushes the value of the evaluated expression to the stack then
     ;; assemble the named return value
     ,@(templatel--compiler-run (cdr tree))
     (cons ,(cdar tree) (pop rt/valstk))))

(defun templatel--compiler-named-params (tree)
  "Compile a list of named params from TREE."
  `(push (list ,@(mapcar #'templatel--compiler-named-param tree)) rt/valstk))

(defun templatel--compiler-expression (tree)
  "Compile an expression from TREE."
  `(progn
     ,@(templatel--compiler-run tree)
     (insert (templatel--runtime-value
              (rt/get :env)
              (or (pop rt/valstk) "")))))

(defun templatel--runtime-value (env value)
  "Compile VALUE within ENV.

This mostly handles autoescaping of values.  If the string is a
safe string.  e.g.: `(safe . x)' then it is just printed out.
Otherwise its HTML entities are escaped."
  (let ((fn (if (templatel-env-get-autoescape env)
                #'templatel-escape-string
              #'identity)))
    (pcase value
      (`(safe . ,x) x)
      (x (funcall fn (format "%s" x))))))

(defun templatel--compiler-text (tree)
  "Compile text from TREE."
  `(insert ,tree))

(defun templatel--compiler-identifier (tree)
  "Compile identifier from TREE."
  `(funcall rt/lookup-var ,tree))

(defun templatel--compiler-if-elif-cond (tree)
  "Compile cond from elif statements in TREE."
  (let ((expr (cadr tree))
        (tmpl (caddr tree)))
    `((progn ,(templatel--compiler-run expr)
             (templatel--truthy (pop rt/valstk)))
      ,@(templatel--compiler-run tmpl))))

(defun templatel--compiler-if-elif (tree)
  "Compile if/elif/else statement off TREE."
  (let ((expr (car tree))
        (body (cadr tree))
        (elif (caddr tree))
        (else (cadr (cadddr tree))))
    `(cond ((progn ,(templatel--compiler-run expr)
                   (templatel--truthy (pop rt/valstk)))
            ,@(templatel--compiler-run body))
           ,@(mapcar #'templatel--compiler-if-elif-cond elif)
           (t ,@(templatel--compiler-run else)))))

(defun templatel--compiler-if-else (tree)
  "Compile if/else statement off TREE."
  (let ((expr (car tree))
        (body (cadr tree))
        (else (cadr (caddr tree))))
    `(if (progn ,(templatel--compiler-run expr)
                (templatel--truthy (pop rt/valstk)))
         (progn ,@(templatel--compiler-run body))
       ,@(templatel--compiler-run else))))

(defun templatel--compiler-if (tree)
  "Compile if statement off TREE."
  (let ((expr (car tree))
        (body (cadr tree)))
    `(if (progn ,(templatel--compiler-run expr)
                (templatel--truthy (pop rt/valstk)))
         (progn ,@(templatel--compiler-run body)))))

(defun templatel--truthy (v)
  "Define if V should be evaluated to true or false."
  (if (eq 'undefined v)
      nil
    v))

(defun templatel--compiler-for (tree)
  "Compile for statement off TREE."
  (let ((id (cdar tree)))
    `(let ((subenv '((,id . nil)))
           (iterable (progn
                       ,(templatel--compiler-run (cadr tree))
                       (pop rt/valstk))))
       (push subenv rt/varstk)
       (mapc
        (lambda(id)
          (setf (alist-get ,id subenv) id)
          ,@(templatel--compiler-run (caddr tree)))
        iterable)
       (pop rt/varstk))))

(defun templatel--compiler-binop-item (tree)
  "Compile item from list of binary operator/operand in TREE."
  (if (not (null tree))
      (let* ((tag (caar tree))
             (val (templatel--compiler-run (cdr (car tree))))
             (op (cadr (assoc tag '(;; Arithmetic
                                    ("*" *)
                                    ("/" /)
                                    ("+" +)
                                    ("-" -)
                                    ("%" %)
                                    ("**" expt)
                                    ;; Logic
                                    ("and" and)
                                    ("or" or)
                                    ;; Comparison
                                    ("<" <)
                                    (">" >)
                                    ("!=" (lambda(a b) (not (equal a b))))
                                    ("==" equal)
                                    (">=" >=)
                                    ("<=" <=)
                                    ("in" (lambda(a b) (not (null (member a b))))))))))
        (if (not (null val))
            `(progn
               ,val
               ,(templatel--compiler-binop-item (cdr tree))
               (let ((b (pop rt/valstk))
                     (a (pop rt/valstk)))
                 (push (,op a b) rt/valstk)))))))

(defun templatel--compiler-binop (tree)
  "Compile a binary operator from the TREE."
  `(progn
     ,(templatel--compiler-run (car tree))
     ,(templatel--compiler-binop-item (cdr tree))))

(defun templatel--compiler-unary (tree)
  "Compile a unary operator from the TREE."
  (let* ((tag (car tree))
         (val (cadr tree))
         (op (cadr (assoc tag '(("+" (lambda(x) (if (< x 0) (- x) x)))
                                ("-" -)
                                ("~" lognot)
                                ("not" not))))))
    `(progn
       ,(templatel--compiler-run val)
       (push (,op (pop rt/valstk)) rt/valstk))))

(defun templatel--compiler-run (tree)
  "Compile TREE into bytecode."
  (pcase tree
    (`() nil)
    (`("Template"          . ,a) (templatel--compiler-run a))
    (`("Text"              . ,a) (templatel--compiler-text a))
    (`("Identifier"        . ,a) (templatel--compiler-identifier a))
    (`("Attribute"         . ,a) (templatel--compiler-attribute a))
    (`("Filter"            . ,a) (templatel--compiler-filter-list a))
    (`("FnCall"            . ,a) (templatel--compiler-filter-fncall-standalone a))
    (`("Test"              . ,a) (templatel--compiler-test-list a))
    (`("NamedParams"       . ,a) (templatel--compiler-named-params a))
    (`("Expr"              . ,a) (templatel--compiler-expr a))
    (`("Expression"        . ,a) (templatel--compiler-expression a))
    (`("Element"           . ,a) (templatel--compiler-element a))
    (`("IfElse"            . ,a) (templatel--compiler-if-else a))
    (`("IfElif"            . ,a) (templatel--compiler-if-elif a))
    (`("IfStatement"       . ,a) (templatel--compiler-if a))
    (`("ForStatement"      . ,a) (templatel--compiler-for a))
    (`("BlockStatement"    . ,a) (templatel--compiler-block a))
    (`("ExtendsStatement"  . ,a) (templatel--compiler-extends a))
    (`("IncludeStatement"  . ,a) (templatel--compiler-include a))
    (`("BinOp"             . ,a) (templatel--compiler-binop a))
    (`("Unary"             . ,a) (templatel--compiler-unary a))
    (`("Number"            . ,a) a)
    (`("String"            . ,a) a)
    (`("Bool"              . ,a) a)
    (`("Nil"               . ,a) a)
    ((pred listp)             (mapcar #'templatel--compiler-run tree))
    (_ (message "NOENTIENDO: `%s`" tree))))



(defun templatel--string-apply (s fn)
  "Apply FN to S taking safe strings into account."
  (pcase s
    (`(safe . ,x) (cons 'safe (funcall fn x)))
    (x (funcall fn x))))


;; Filters

(defun templatel-filters-abs (n)
  "Absolute value of number N."
  (abs n))

(defun templatel-filters-attr (s n)
  "Get element N of assoc S."
  (let ((element (assoc n s)))
    (if element (cdr element))))

(defun templatel-filters-capitalize (s)
  "Upper-case the first character of S."
  (format "%c%s"
   (upcase (elt s 0))
   (seq-drop s 1)))

(defun templatel-filters-default (value default)
  "Return DEFAULT if VALUE is nil or return VALUE."
  (if (templatel--truthy value)
      value
    default))

(defun templatel-filters-escape (s)
  "Convert special chars in S to their respective HTML entities."
  (templatel-escape-string s))

(defun templatel-filters-first (s)
  "First element of sequence S."
  (elt s 0))

(defun templatel-filters-float (s)
  "Parse S as float."
  (cond
   ((stringp s) (float (string-to-number s)))
   ((numberp s) (float s))
   (t (signal
       'templatel-runtime-error
       (format "Can't convert type %s to float" (type-of s))))))

(defun templatel-filters-int (s &optional base)
  "Convert S into integer of base BASE."
  (cond
   ((stringp s)
    (truncate (string-to-number (replace-regexp-in-string "^0[xXbB]" "" s)
                                (or base 10))))
   ((numberp s)
    (truncate s))
   (t (signal
       'templatel-runtime-error
       (format "Can't convert type %s to int" (type-of s))))))

(defun templatel-filters-join (seq &optional sep)
  "Join al elements of SEQ with SEP."
  ;; calling format ensure i of any type becomes a string
  (mapconcat (lambda(i) (format "%s" i)) seq (or sep "")))

(defun templatel-filters-last (s)
  "Last element of sequence S."
  (elt s (- (length s) 1)))

(defun templatel-filters-length (seq)
  "Return how many elements in a SEQ."
  (length seq))

(defun templatel-filters-lower (s)
  "Lower case all chars of S."
  (templatel--string-apply s #'downcase))

(defun templatel-filters-max (seq)
  "Find maximum value within SEQ."
  (apply #'max seq))

(defun templatel-filters-min (seq)
  "Find minimum value within SEQ."
  (apply #'min seq))

(defun templatel-filters-round (n)
  "Round N."
  (round n))

(defun templatel-filters-sum (s)
  "Sum all entries in S."
  (apply #'+ s))

(defun templatel-filters-take (s n)
  "Take N elements of sequence S."
  (seq-take s n))

(defun templatel-filters-title (s)
  "Upper first char of each word in S."
  (capitalize s))

(defun templatel-filters-upper (s)
  "Upper case all chars of S."
  (templatel--string-apply s #'upcase))

(defun templatel-filters-plus1 (s)
  "Add one to S."
  (1+ s))

(defun templatel-filters-safe (s)
  "Mark string S as safe.

That is useful if one wants to allow variables to contain HTML
code.  e.g.:

#+BEGIN_SRC emacs-lisp
\(templatel-render-string
 \"Hi {{ name|safe }}!\" '((\"name\" . \"<b>you</b>\"))
 :autoescape t)
#+END_SRC

The above snippet would output the HTML entities untouched even
though the flag for auto escaping is true:

#+BEGIN_SRC text
Hi <b>you</b>!
#+END_SRC"
  (templatel-mark-safe s))

(defun templatel-filters-sort (s)
  "Return S sorted."
  (sort s #'<))



;; Tests

(defun templatel-tests-defined (v)
  "Return t if V is defined."
  (not (eq v 'undefined)))

(defun templatel-tests-divisible (value d)
  "Return t if VALUE is divisible by D."
  (eq 0 (% value d)))



(defun templatel--get (lst sym default)
  "Pick SYM from LST or return DEFAULT."
  (let ((val (assoc sym lst)))
    (if val
        (cadr val)
      default)))

(defun templatel-mark-safe (s)
  "Mark string S as safe."
  (pcase s
    (`(safe . ,_) s)
    (x (cons 'safe x))))

(defun templatel-escape-string (s)
  "Escape string S."
  (let ((output s))
    (dolist (replacement '((?& . "&amp;")
                           (?> . "&gt;")
                           (?< . "&lt;")
                           (?\' . "&#39;")
                           (?\" . "&#34;")))
      (setq output (replace-regexp-in-string
                    (regexp-quote (format "%c" (car replacement)))
                    (cdr replacement)
                    output nil 'literal)))
    output))

;; --- Public Environment API ---

(defun templatel-env-new (&rest options)
  "Create new template environment configured via OPTIONS.

Both
[[anchor:symbol-templatel-render-string][templatel-render-string]]
and
[[anchor:symbol-templatel-render-string][templatel-render-file]]
provide a one-call interface to render a template from a string
or from a file respectively.  Although convenient, neither or
these two functions can be used to render templates that use ~{%
extends %}~.

This decision was made to keep /templatel/ extensible allowing
users to define how new templates should be found.  It also keeps
the library simpler as a good side-effect.

To get template inheritance to work, a user defined import
function must be attached to a template environment.  The user
defined function is responsible for finding and adding templates
to the environment.  The following snippet demonstrates how to
create the simplest import function and provide it to an
environment via ~:importfn~ parameter.

#+BEGIN_SRC emacs-lisp
\(templatel-env-new
 :importfn (lambda(environment name)
             (templatel-env-add-template
              environment name
              (templatel-new-from-file
               (expand-file-name name \"/home/user/templates\")))))
#+END_SRC"
  (let* ((opt (seq-partition options 2)))
    `[;; 0. Where we keep the templates
      ,(make-hash-table :test 'equal)
      ;; 1. Function used by extends
      ,(templatel--get opt :importfn
                       (lambda(_e _n) (error "Import function not defined")))
      ;; 2. Where we keep the filter functions
      ,(make-hash-table :test 'equal)
      ;; 3. Where we keep the test functions
      ,(make-hash-table :test 'equal)
      ;; 4. Autoescape flag that defaults to true
      nil]))

(defun templatel-env-add-template (env name template)
  "Add TEMPLATE to ENV under key NAME."
  (puthash name template (elt env 0)))

(defun templatel-env-remove-template (env name)
  "Remove template NAME from ENV.

This function reverts the effect of a previous call to
[[anchor:symbol-templatel-env-add-template][templatel-env-add-template]]."
  (remhash name (elt env 0)))

(defun templatel-env-add-filter (env name filter)
  "Add FILTER to ENV under key NAME.

This is how /templatel/ supports user-defined filters.  Let's say
there's a template environment that needs to provide a new filter
called *addspam* that adds the word \"spam\" right after text.:

#+begin_src emacs-lisp
\(let ((env (templatel-env-new)))
  (templatel-env-add-filter env \"spam\" (lambda(stuff) (format \"%s spam\" stuff)))
  (templatel-env-add-template env \"page.html\" (templatel-new \"{{ spam(\\\"hi\\\") }}\"))
  (templatel-env-render env \"page.html\" '()))
#+end_src

The above code would render something like ~hi spam~.

Use
[[anchor:symbol-templatel-env-remove-filter][templatel-env-remove-filter]]
to remove filters added with this function."
  (puthash name filter (elt env 2)))

(defun templatel-env-remove-filter (env name)
  "Remove filter from ENV under key NAME.

This function reverts the effect of a previous call to
[[anchor:symbol-templatel-env-add-filter][templatel-env-add-filter]]."
  (remhash name (elt env 2)))

(defun templatel-env-add-test (env name test)
  "Add TEST to ENV under key NAME."
  (puthash name test (elt env 3)))

(defun templatel-env-remove-test (env name)
  "Remove test from ENV under key NAME.

This function reverts the effect of a previous call to
[[anchor:symbol-templatel-env-add-test][templatel-env-add-test]]."
  (remhash name (elt env 2)))

(defun templatel--env-source (env name)
  "Get source code of template NAME within ENV."
  (gethash name (elt env 0)))

(defun templatel--env-filter (env name)
  "Get filter NAME within ENV."
  (let ((entry (gethash name (elt env 2))))
    (or (and entry (cons name entry)))))

(defun templatel--env-test (env name)
  "Get test NAME within ENV."
  (let ((entry (gethash name (elt env 3))))
    (or (and entry (cons name entry)))))

(defun templatel--env-run-importfn (env name)
  "Run import with NAME within ENV."
  (let ((importfn (elt env 1)))
    (if importfn
        (funcall importfn env name))))

(defun templatel-env-get-autoescape (env)
  "Get autoescape flag of ENV."
  (elt env 4))

(defun templatel-env-set-autoescape (env autoescape)
  "Set AUTOESCAPE flag of ENV to either true or false."
  (aset env 4 autoescape))

(defun templatel-env-render (env name vars)
  "Render template NAME within ENV with VARS as parameters."
  (funcall (templatel--compiler-code (templatel--env-source env name) name)
           :env env
           :vars vars))

(defun templatel-new (source)
  "Create a template off SOURCE."
  (templatel--compiler-run
   (templatel--parser-template
    (templatel--scanner-new source "<string>"))))

(defun templatel-new-from-file (path)
  "Create a template from file at PATH."
  (with-temp-buffer
    (insert-file-contents path)
    (let* ((scanner (templatel--scanner-new (buffer-string) path))
           (tree (templatel--parser-template scanner))
           (code (templatel--compiler-run tree)))
      code)))

;; ------ Public API without Environment

(defun templatel-render-string (template variables &rest options)
  "Render TEMPLATE string with VARIABLES.

This is the simplest way to use *templatel*, since it only takes
a function call.  However, notice that it won't allow you to
extend other templates because no ~:importfn~ can be passed to
the implicit envoronment created within this function.  Please
refer to the next section
[[anchor:section-template-environments][Template Environments]]
to learn how to use the API that enables template inheritance.

The argument OPTIONS can have the following entries:

- *AUTOESCAPE*: enables automatic HTML entity escaping.  Defaults
   to ~nil~.

#+BEGIN_SRC emacs-lisp
\(templatel-render-string \"Hello, {{ name }}!\" '((\"name\" . \"GNU!\")))
#+END_SRC"
  (let ((env (templatel-env-new))
        (opt (seq-partition options 2)))
    (templatel-env-set-autoescape env (templatel--get opt :autoescape nil))
    (templatel-env-add-template env "<string>" (templatel-new template))
    (templatel-env-render env "<string>" variables)))

(defun templatel-render-file (path variables &rest opt)
  "Render template file at PATH with VARIABLES.

Just like with
[[anchor:symbol-templatel-render-string][templatel-render-string]],
templates rendered with this function also can't use ~{% extends %}~
statements.  Please refer to the section
[[anchor:section-template-environments][Template Environments]]
to learn how to use the API that enables template inheritance.

Given the HTML template ~file.html~:
#+BEGIN_SRC jinja2
Hi, {{ name }}!
#+END_SRC

And the following Lisp code:
#+BEGIN_SRC emacs-lisp
\(templatel-render-file \"out.html\" '((\"name\" . \"test\")))
#+END_SRC

When, executed the above code would generate the file `out.html`
with the variable interpolated into the content.  e.g.:

#+BEGIN_SRC text
Hi, test!
#+END_SRC

The argument OPT can have the following entries:

- *AUTOESCAPE-EXT*: list contains which file extensions enable
automatic enabled HTML escaping.  In the example above, HTML
entities present in `name` will be escaped.  Notice that the
comparison is case sensitive.  Defaults to ~'(\"html\" \"xml\")~."
  (let ((env (templatel-env-new)))
    (templatel-env-set-autoescape
     env (member (file-name-extension path)
                 (templatel-env-set-autoescape
                  env (templatel--get opt :autoescape-ext '("html" "xml")))))
    (templatel-env-add-template env path (templatel-new-from-file path))
    (templatel-env-render env path variables)))

(provide 'templatel)
;;; templatel.el ends here
