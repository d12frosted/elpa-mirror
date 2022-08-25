;;; uxntal-mode.el --- Major mode for Uxntal assembly   -*- lexical-binding: t; -*-

;; Copyright (c) 2022 d_m

;; Author: d_m <d_m@plastic-idolatry.com>
;; Homepage: https://github.com/non/uxntal-mode
;; Version: 0.2
;; Package-Version: 20220502.154
;; Package-Commit: 3fa793964f287d448e3e2b53fd812803c5f5890e
;; Package-Requires: ((emacs "27.1"))
;; SPDX-License-Identifier: Apache-2.0

;;; Commentary:

;; This major mode supports writing the Uxntal assmembly langauge as documented
;; at https://wiki.xxiivv.com/site/uxntal.html.

;;; Code:

;; use rx for regular expressions
(require 'rx)
(require 'seq)

;; open .tal files with this mode
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.tal\\'" . uxntal-mode))

;; macro definitions like %MOD
(defconst uxntal-mode-macro-define-re
  (rx (group bow "%" (1+ (not (in space))) eow)))

;; includes like ~util.tal
(defconst uxntal-mode-include-re
  (rx (group bow "~" (1+ (not (in space))) eow)))

;; labels like @foo
(defconst uxntal-mode-label-define-re
  (rx (group bow "@" (1+ (not (in space))) eow)))

;; subabels like &bar
(defconst uxntal-mode-sublabel-define-re
  (rx (group bow "&" (1+ (not (in space))) eow)))

;; raw characters like 'a or '[
(defconst uxntal-mode-raw-char-re
  (rx (group bow "'" (in "!-~") eow)))

;; raw strings like "foo or "a-b-c-d-e
(defconst uxntal-mode-raw-str-re
  (rx (group bow "\"" (1+ (in "!-~")) eow)))

;; absolute pads like |a0 or |0100
(defconst uxntal-mode-absolute-pad-re
  (rx (group
       bow "|"
       (repeat 2 (in "0-9a-f"))
       (\? (repeat 2 (in "0-9a-f")))
       eow)))

;; pads like $1 $1f $300 $1000
(defconst uxntal-mode-relative-pad-re
  (rx (group bow "$" (repeat 1 4 (in "0-9a-f")) eow)))

;; addresses such as .foo ,bar ;baz :qux
(defconst uxntal-mode-addr-zeropage-re
  (rx (group bow "." (1+ (not (in space))) eow)))
(defconst uxntal-mode-addr-relative-re
  (rx (group bow "," (1+ (not (in space))) eow)))
(defconst uxntal-mode-addr-absolute-re
  (rx (group bow ";" (1+ (not (in space))) eow)))
(defconst uxntal-mode-addr-raw-re
  (rx (group bow ":" (1+ (not (in space))) eow)))

;; literal numbers like #ff or #abcd
(defconst uxntal-mode-number-re
  (rx (group
       bow "#"
       (repeat 2 (in "0-9a-f"))
       (\? (repeat 2 (in "0-9a-f")))
       eow)))

;; raw numbers like ff or abcd
(defconst uxntal-mode-raw-number-re
  (rx (group
       bow
       (repeat 2 (in "0-9a-f"))
       (\? (repeat 2 (in "0-9a-f")))
       eow)))

;; tal instructions like ADD or JMP2r
(defconst uxntal-mode-inst-re
  (rx (group bow
       (or "BRK"
           (group "LIT" (\? "2") (\? "r"))
           (group (or "INC" "POP" "DUP" "NIP" "SWP" "OVR" "ROT"
                      "EQU" "NEQ" "GTH" "LTH"
                      "JMP" "JCN" "JSR" "STH"
                      "LDZ" "STZ" "LDR" "STR" "LDA" "STA"
                      "DEI" "DEO"
                      "ADD" "SUB" "MUL" "DIV"
                      "AND" "ORA" "EOR" "SFT")
                  (\? "2") (\? "k") (\? "r")))
       eow)))

;; all previous rules joined together into a list
(defconst uxntal-font-lock-keywords-1
  (list
   ;; macros (%)
   (list uxntal-mode-macro-define-re 1 font-lock-keyword-face)
   ;; addresses (. , ; :)
   (list uxntal-mode-addr-zeropage-re 1 font-lock-variable-name-face)
   (list uxntal-mode-addr-relative-re 1 font-lock-variable-name-face)
   (list uxntal-mode-addr-absolute-re 1 font-lock-variable-name-face)
   (list uxntal-mode-addr-raw-re 1 font-lock-variable-name-face)
   ;; labels (@ &)
   (list uxntal-mode-label-define-re 1 font-lock-function-name-face)
   (list uxntal-mode-sublabel-define-re 1 font-lock-function-name-face)
   ;; padding (| $)
   (list uxntal-mode-absolute-pad-re 1 font-lock-preprocessor-face)
   (list uxntal-mode-relative-pad-re 1 font-lock-preprocessor-face)
   ;; includes (~)
   (list uxntal-mode-include-re 1 font-lock-preprocessor-face)
   ;; instructions
   (list uxntal-mode-inst-re 1 font-lock-builtin-face)
   ;; constant numbers (#)
   (list uxntal-mode-number-re 1 font-lock-constant-face)
   ;; raw values (' ")
   (list uxntal-mode-raw-number-re 1 font-lock-string-face)
   (list uxntal-mode-raw-char-re 1 font-lock-string-face)
   (list uxntal-mode-raw-str-re 1 font-lock-string-face))
  "Level one font lock.")

;; create the syntax table which powers some highlighting decisions.
;;
;; since it is not possible to exactly encode uxntal's rules for
;; comments, we have to choose between strict and non-strict
;; highlighting.
;;
;; when strict, valid comments such as "( )" or "(<newline>)"
;; will be incorrectly rejected.
;;
;; when non-strict, invalid comments such as "(hi )" or "( bye)"
;; will be incorrectly accepted.
(defun uxntal-create-syntax-table (strict)
  "Create a syntax table. The STRICT parameter determines whether to use strict or lax parsing for comments."
  (let ((table (make-syntax-table))
        (c 0))
    ;; treat characters <= space as whitespace
    (while (< c ?!)
      (modify-syntax-entry c " " table)
      (setq c (1+ c)))
    ;; treat almost all printable characters as word characters
    (while (< c 127)
      (modify-syntax-entry c "w" table)
      (setq c (1+ c)))
    ;; when strict, we require '(' and ')' to have whitespace padding.
    ;; this is typically ok but fails on things like "( )" which
    ;; should be valid comments but would not highlight correctly.
    (if strict
      (progn
        (modify-syntax-entry ?\( "()1nb" table)
        (modify-syntax-entry ?\) ")(4nb" table)
        (modify-syntax-entry ?\s " 123" table)
        (modify-syntax-entry ?\t " 123" table)
        (modify-syntax-entry ?\n " 123" table))
      (progn
        (modify-syntax-entry ?\( "<)nb" table)
        (modify-syntax-entry ?\) ">(nb" table)))
    ;; generic delimiters, ignored by uxnasm
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    ;; return the syntax table
    table))

(defcustom uxntal-mode-strict-comments nil
  "When non-nil, will parse comments strictly, ensuring invalid comments are rejected. Otherwise, comments are parsed permissively, ensuring valid comments are accepted."
  :type 'boolean
  :safe #'booleanp
  :group 'uxntal)

(defcustom uxntal-uxnasm-path "uxnasm"
  "Path to run uxnasm assembler command."
  :type 'string
  :safe #'stringp
  :group 'uxntal)

(defvar uxntal-mode-syntax-table
  (uxntal-create-syntax-table uxntal-mode-strict-comments)
  "Syntax table in use in `uxntal-mode' buffers.")

(defconst uxntal-imenu-generic-expression
  (list (list nil uxntal-mode-label-define-re 1)
        (list nil uxntal-mode-macro-define-re 1))
  "Expressions for navigating Uxntal with imenu.")

(defun uxntal-indent-line ()
  "Indent line by inserting a tab character."
  (interactive)
  (if indent-tabs-mode
      (insert "\t")
    (insert (make-string tab-width ?\s))))

;; set M-x compile to call uxnasm
(defun uxntal-setup-compile-command ()
  "Set the current buffer to compile to a ROM using uxnasm."
  (let* ((in (file-relative-name buffer-file-name))
         (out (concat (file-name-sans-extension in) ".rom")))
    (set (make-local-variable 'compile-command)
         (concat uxntal-uxnasm-path " " in " " out))))

;;;###autoload
(define-derived-mode uxntal-mode prog-mode "Uxntal"
  "Major mode for editing Uxntal files."
  (set-syntax-table (uxntal-create-syntax-table uxntal-mode-strict-comments))
  (uxntal-setup-compile-command)
  (setq font-lock-defaults '(uxntal-font-lock-keywords-1 nil nil)
        comment-start "( "
        comment-end " )"
        comment-quote-nested nil
        indent-line-function #'uxntal-indent-line
        imenu-generic-expression uxntal-imenu-generic-expression))

;; Constructs a table of metadata about every instruction.
;; This table powers uxntal-decode-instruction.
(defconst uxntal-mode-instructions
  (let ((m (make-hash-table :test 'equal :size 32)))
    ;; stack opcodes
    (puthash "BRK" (vector "Break" '(() . ()) nil "halt the program") m)
    (puthash "LIT" (vector "Literal" '(() . ("a")) nil "push the next value onto the stack") m)
    (puthash "INC" (vector "Increment" '(("a") . ("b")) nil "adds one to the top of the stack") m)
    (puthash "POP" (vector "Pop" '(("a") . ()) nil "remove the top of the stack") m)
    (puthash "NIP" (vector "Nip" '(("a" "b") . ("b")) nil "remove the second value (a)") m)
    (puthash "SWP" (vector "Swap" '(("a" "b") . ("b" "a")) nil "swap the top two stack values") m)
    (puthash "ROT" (vector "Rotate" '(("a" "b" "c") . ("b" "c" "a")) nil "rotate the top three values to the left") m)
    (puthash "DUP" (vector "Duplicate" '(("a") . ("a" "a")) nil "duplicate the top of the stack") m)
    (puthash "OVR" (vector "Over" '(("a" "b") . ("a" "b" "a")) nil "duplicate the second value (a) to the top of the stack") m)
    ;; logic opcodes
    (puthash "EQU" (vector "Equal" '(("a" "b") . ("bool^")) nil "push 01 if a == b; push 00 otherwise") m)
    (puthash "NEQ" (vector "Not Equal" '(("a" "b") . ("bool^")) nil "push 01 if a != b; push 00 otherwise") m)
    (puthash "GTH" (vector "Greater Than" '(("a" "b") . ("bool^")) nil "push 01 if a > b; push 00 otherwise") m)
    (puthash "LTH" (vector "Less Than" '(("a" "b") . ("bool^")) nil "push 01 if a < b; push 00 otherwise") m)
    (puthash "JMP" (vector "Jump" '(("addr") . ()) nil "modify the pc using addr") m)
    (puthash "JCN" (vector "Jump Conditional" '(("bool^" "addr") . ()) nil "if bool != 00, modify the pc using addr") m)
    (puthash "JSR" (vector "Jump Stash Return" '(("addr") . ()) '(() . ("pc")) "store pc onto return stack; modify pc using addr") m)
    (puthash "STH" (vector "Stash" '(("a") . ()) '(() . ("a")) "move the top of the stack to the return stack") m)
    ;; memory opcodes
    (puthash "LDZ" (vector "Load Zero-Page" '(("addr^") . ("val")) nil "load value from first 256 bytes of memory onto the stack") m)
    (puthash "STZ" (vector "Store Zero-Page" '(("val" "addr^") . ()) nil "write top of stack into the first 256 bytes of memory") m)
    (puthash "LDR" (vector "Load Relative" '(("addr^") . ("val")) nil "load relative address onto the stack") m)
    (puthash "STR" (vector "Store Relative" '(("val" "addr^") . ()) nil "write top of stack to relative address") m)
    (puthash "LDA" (vector "Load Absolute" '(("addr*") . ("val")) nil "load absolute address onto the stack") m)
    (puthash "STA" (vector "Store Absolute" '(("val" "addr*") . ()) nil "write top of stack to absolute address") m)
    (puthash "DEI" (vector "Device In" '(("addr^") . ("val")) nil "load from the given device onto the stack") m)
    (puthash "DEO" (vector "Device Out" '(("val" "addr^") . ()) nil "write top of stack to the given device") m)
    ;; arithmetic opcodes
    (puthash "ADD" (vector "Add" '(("a" "b") . ("a+b")) nil "addition (a + b)") m)
    (puthash "SUB" (vector "Subtract" '(("a" "b") . ("a-b")) nil "subtraction (a - b)") m)
    (puthash "MUL" (vector "Multiply" '(("a" "b") . ("a*b")) nil "multiplication (a * b)") m)
    (puthash "DIV" (vector "Divide" '(("a" "b") . ("a/b")) nil "division (a / b)") m)
    (puthash "AND" (vector "And" '(("a" "b") . ("a&b")) nil "bitwise-and (a & b)") m)
    (puthash "ORA" (vector "Or" '(("a" "b") . ("a|b")) nil "bitwise-or (a | b)") m)
    (puthash "EOR" (vector "Exclusive Or" '(("a" "b") . ("a^b")) nil "bitwise-xor (a ^ b)") m)
    (puthash "SFT" (vector "Shift" '(("a" "b^") . ("c")) nil "bitshift right (b & 0xf) then left (b >> 4)") m)
    m))

(defun uxntal-format-stack (pair glyph)
  "Format the given stack PAIR as stack effects using GLYPH. Stacks are represented as a pair of lists for input and output parameters respectively. We apply GLYPH to any parameter that doesn't already have a suffix denoting its type ('^' for 8-bit values, '*' for 16-bit values)."
  (let* ((decorate (lambda (name) (if (or (string-suffix-p "^" name)
                                          (string-suffix-p "*" name))
                                      name
                                    (concat name glyph))))
         (ins (mapconcat decorate (car pair) " "))
         (outs (mapconcat decorate (cdr pair) " ")))
    (format "%s -> %s" ins outs)))

(defun uxntal-setup-keep (pair)
  "Translate the given stack PAIR for keep mode. This involves prepending the input parameters (i.e. the first list) to the output parameters (the second list)."
  (let ((in (car pair))
        (out (cdr pair)))
    (cons in (append in out))))

(defun uxntal-decode-instruction (inst)
  "Decode the meaning of the INST instruction. Instructions are always three capital letters followed by a suffix involving '2', 'k', and/or 'r'."
  (let ((m (string-match uxntal-mode-inst-re inst)))
    (if (not m)
        (message "`%s' is not an instruction" inst)
      (let* ((base (substring inst 0 3))
             (inst-info (gethash base uxntal-mode-instructions))
             (name (aref inst-info 0))
             (s0 (aref inst-info 1))
             (s1 (aref inst-info 2))
             (doc (aref inst-info 3))
             ;; set up stacks based on the bitflags given
             ;; 2 -> use 16-bit values (*) instead of 8-bit (^)
             ;; k -> keep inputs on stack
             ;; r -> swap working stack (ws) and return stack (rs)
             (wsx (if (seq-contains-p inst ?r) s1 s0))
             (ws (if (seq-contains-p inst ?k) (uxntal-setup-keep wsx) wsx))
             (rsx (if (seq-contains-p inst ?r) s0 s1))
             (rs (if (seq-contains-p inst ?k) (uxntal-setup-keep rsx) rsx))
             (glyph (if (seq-contains-p inst ?2) "*" "^"))
             (wss (if ws (concat "(" (uxntal-format-stack ws glyph) ") ") ""))
             (rss (if rs (concat "{" (uxntal-format-stack rs glyph) "} ") "")))
        ;; create full string representation of stacks,
        ;; with delimiters and whitespace
        (message "%s %s%s%s: %s" inst wss rss name doc)))))

(defun uxntal-explain-word ()
  "Explain the given word's meaning in Uxntal. Depdending on the word, this may decode an instruction, display a numeric constant, or describe the syntactic category for the given word."
  (interactive)
  (let* ((w (current-word t t))
         (dec (lambda () (string-to-number w 16)))
         (dec1 (lambda () (string-to-number (substring w 1) 16))))
    (cond
     ((not w) (message "No word selected"))
     ((string-match uxntal-mode-macro-define-re w) (message "%s is a macro definition" w))
     ((string-match uxntal-mode-include-re w) (message "%s is an include" w))
     ((string-match uxntal-mode-label-define-re w) (message "%s is a label definition" w))
     ((string-match uxntal-mode-sublabel-define-re w) (message "%s is a sublabel definition" w))
     ((string-match uxntal-mode-raw-char-re w) (message "%s is a raw char" w))
     ((string-match uxntal-mode-raw-str-re w) (message "%s is a raw string" w))
     ((string-match uxntal-mode-absolute-pad-re w) (message "%s is an absolute pad (%d)" w (funcall dec1)))
     ((string-match uxntal-mode-relative-pad-re w) (message "%s is a relative pad (+%d)" w (funcall dec1)))
     ((string-match uxntal-mode-addr-zeropage-re w) (message "%s is a zero-page address" w))
     ((string-match uxntal-mode-addr-relative-re w) (message "%s is a relative address" w))
     ((string-match uxntal-mode-addr-absolute-re w) (message "%s is an absolute address" w))
     ((string-match uxntal-mode-addr-raw-re w) (message "%s is a raw address" w))
     ((string-match uxntal-mode-number-re w) (message "%s is a number (%d)" w (funcall dec1)))
     ((string-match uxntal-mode-raw-number-re w) (message "%s is a raw number (%d)" w (funcall dec)))
     ((string-match uxntal-mode-inst-re w) (uxntal-decode-instruction w))
     (t (message "Unknown word: `%s'" w)))))

(provide 'uxntal-mode)

;;; uxntal-mode.el ends here
