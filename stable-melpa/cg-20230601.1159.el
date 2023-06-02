;;; cg.el --- Major mode for editing Constraint Grammar files  -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2010-2022 Kevin Brubeck Unhammer

;; Author: Kevin Brubeck Unhammer <unhammer@fsfe.org>
;; Version: 0.4.0
;; Package-Version: 20230601.1159
;; Package-Commit: 4c92ab6454b03b1bd3829bf79e22cb862fed11b5
;; Package-Requires: ((emacs "26.1"))
;; Url: https://visl.sdu.dk/constraint_grammar.html
;; Keywords: languages

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a major mode for editing Constraint Grammar
;; source files, including syntax highlighting and interactive grammar
;; development from within Emacs.  Use `C-c C-i' to edit the text you
;; want to edit, then just `C-c C-c' whenever you want to run the
;; grammar over that text.  Clicking on a line number in the trace
;; output will take you to the definition of that rule.

;; Usage:
;;
;; (autoload 'cg-mode "/path/to/cg.el"
;;  "cg-mode is a major mode for editing Constraint Grammar files."  t)
;; (add-to-list 'auto-mode-alist '("\\.cg3\\'" . cg-mode))
;; ; Or if you use a non-standard file suffix, e.g. .rlx:
;; (add-to-list 'auto-mode-alist '("\\.rlx\\'" . cg-mode))

;; I recommend using `company-mode' for tab-completion, and
;; `smartparens-mode' if you're used to it (`paredit-mode' does not
;; work well if you have set names with the # character in them).
;; Both are available from MELPA (see http://melpa.milkbox.net/).
;;
;; You can lazy-load company-mode for cg-mode like this:
;;
;; (eval-after-load 'company-autoloads
;;     '(add-hook 'cg-mode-hook #'company-mode))


;; TODO:
;; - investigate bug in `show-smartparens-mode' causing slowness
;; - different syntax highlighting for sets and tags (difficult)
;; - use something like prolog-clause-start to define M-a/e etc.
;; - indentation function (based on prolog again?)
;; - the rest of the keywords
;; - https://visl.sdu.dk/cg3/single/#regex-icase
;; - keyword tab-completion
;; - `font-lock-syntactic-keywords' is obsolete since 24.1
;; - show definition of set/list-at-point in modeline
;; - show section name/number in modeline

;;; Code:

(defconst cg-version "0.4.0" "Version of cg-mode.")

(eval-when-compile (require 'cl-lib))
(require 'xref)
(require 'tool-bar)

;;;============================================================================
;;;
;;; Define the formal stuff for a major mode named cg.
;;;

(defvar cg-mode-map (make-sparse-keymap)
  "Keymap for CG mode.")

(defgroup cg nil
  "Major mode for editing VISL CG-3 Constraint Grammar files."
  :tag "CG"
  :group 'languages)

;;;###autoload
(defcustom cg-command "vislcg3"
  "The vislcg3 command, e.g. \"/usr/local/bin/vislcg3\".

Buffer-local, so use `setq-default' if you want to change the
global default value.

See also `cg-extra-args' and `cg-pre-pipe'."
  :type 'string)
(make-variable-buffer-local 'cg-extra-args)

;;;###autoload
(defcustom cg-extra-args "--trace"
  "Extra arguments sent to vislcg3 when running `cg-check'.

Buffer-local, so use `setq-default' if you want to change the
global default value.

See also `cg-command'."
  :type 'string)
(make-variable-buffer-local 'cg-extra-args)
(setq-default cg-extra-args "--trace")

;;;###autoload
(defcustom cg-pre-pipe "cg-conv"
  "Pipeline to run before vislcg3 when testing a file with `cg-check'.

Buffer-local, so use `setq-default' if you want to change the
global default value.  If you want to set it on a per-file basis,
put a line like

# -*- cg-pre-pipe: \"lt-proc foo.bin | cg-conv\"; othervar: value; -*-

in your .cg3/.rlx file.

See also `cg-command' and `cg-post-pipe'."
  :type 'string)
(make-variable-buffer-local 'cg-pre-pipe)

;;;###autoload
(defcustom cg-post-pipe ""
  "Pipeline to run after vislcg3 when testing a file with `cg-check'.

Buffer-local, so use `setq-default' if you want to change the
global default value.  If you want to set it on a per-file basis,
put a line like

# -*- cg-post-pipe: \"cg-conv --out-apertium | lt-proc -b foo.bin\"; -*-

in your .cg3/.rlx file.

See also `cg-command' and `cg-pre-pipe'."
  :type 'string)
(make-variable-buffer-local 'cg-post-pipe)

(defconst cg-kw-set-list
  '("LIST" "SET" "TEMPLATE"
    ;; These are not sets (and don't have names after the kw) but we
    ;; have them here to make beginning-of-defun work:
    "MAPPING-PREFIX" "SOFT-DELIMITERS" "DELIMITERS")
  "List-like keywords used for indentation, highlighting etc.
Don't change without re-evaluating `cg-kw-re' (or all of cg.el).")
(defconst cg-kw-set-re (regexp-opt cg-kw-set-list)
  "Regexp version of `cg-kw-set-list'.")

(defconst cg-kw-rule-list
  '("SUBSTITUTE"
    "PROTECT"
    "UNPROTECT"
    "IFF"
    "ADDCOHORT" "REMCOHORT"
    "COPY"
    "MOVE" "SWITCH"
    "EXTERNAL" "DELIMIT"
    "MAP"    "ADD"
    "UNMAP"
    "SELECT" "REMOVE"
    "SETPARENT"    "SETCHILD"
    "ADDRELATION"  "REMRELATION"  "SETRELATION"
    "ADDRELATIONS" "REMRELATIONS" "SETRELATIONS"
    "SETVARIABLE"  "REMVARIABLE"
    "APPEND")
  "Rule-starter keywords for indentation, highlighting etc.
Don't change without re-evaluating `cg-kw-re' (or all of cg.el)." )
(defconst cg-kw-rule-re (regexp-opt cg-kw-rule-list)
  "Regexp version of `cg-kw-rule-list'.")
(defconst cg-kw-trace-rule-re (regexp-opt (append '("ADDCOHORT-AFTER" "ADDCOHORT-BEFORE")
                                                  cg-kw-rule-list))
  "Regexp version of `cg-kw-rule-list' with extra keywords used only in tracing.")
(defconst cg-kw-re (regexp-opt (append cg-kw-set-list cg-kw-rule-list))
  "Regexp combination of `cg-kw-rule-list' and `cg-kw-set-list'.")

(defconst cg-kw-rule-flags '("NEAREST"
			     "ALLOWLOOP"
			     "DELAYED"
			     "IMMEDIATE"
			     "LOOKDELETED"
			     "LOOKDELAYED"
			     "UNSAFE" ;
			     "SAFE"
			     "REMEMBERX"
			     "RESETX"
			     "KEEPORDER"
			     "VARYORDER"
			     "ENCL_INNER"
			     "ENCL_OUTER"
			     "ENCL_FINAL"
			     "ENCL_ANY"
			     "ALLOWCROSS"
			     "WITHCHILD"
			     "NOCHILD"
			     "ITERATE"
			     "NOITERATE"
			     "UNMAPLAST"
			     "REVERSE"
			     "SUB"
			     "OUTPUT")
  "Rule flags used for highlighting.
from https://visl.sdu.dk/svn/visl/tools/vislcg3/trunk/src/Strings.cpp
Don't change without re-evaluating the file.")
(defconst cg-kw-context-flags '("NOT"
				"NEGATE"
				"NONE"
				"LINK"
				"BARRIER"
				"CBARRIER"
				"OR"
				"TARGET"
				"IF"
				"AFTER"
				"BEFORE"
				"WITH"
				"FROM"
				"TO")
  "Context flags used for highlighting.
Don't change without re-evaluating the file.")
(defconst cg-kw-flags-re (regexp-opt (append cg-kw-rule-flags cg-kw-context-flags)))


;;;###autoload
(defcustom cg-indentation 8
  "The width for indentation in Constraint Grammar mode."
  :type 'integer)
(put 'cg-indentation 'safe-local-variable 'integerp)

(defconst cg-font-lock-keywords-1
  (let ((<word>? "\\(?:\"<[^>]+>\"[irv]*\\)?"))
    `((,(format "^[ \t]*\\(%s\\)[ \t]+\\(\\(\\sw\\|\\s_\\)+\\)" cg-kw-set-re)
       (1 font-lock-keyword-face)
       (2 font-lock-variable-name-face))
      ("^[ \t]*\\(MAPPING-PREFIX\\|DELIMITERS\\|SOFT-DELIMITERS\\)"
       1 font-lock-keyword-face)
      ("^[ \t]*\\(SECTION\\|AFTER-SECTIONS\\|BEFORE-SECTIONS\\|MAPPINGS\\|CONSTRAINTS\\|CORRECTIONS\\)"
       1 font-lock-warning-face)
      (,(format "^[ \t]*%s[ \t]*\\(%s\\)\\(\\(:\\(\\s_\\|\\sw\\)+\\)?\\)" <word>? cg-kw-rule-re)
       (1 font-lock-keyword-face)
       (2 font-lock-variable-name-face))
      ("[ \t\n]\\([+-]\\)[ \t\n]"
       1 font-lock-function-name-face)))
  "Subdued level highlighting for CG mode.")

(defconst cg-font-lock-keywords-2
  (append cg-font-lock-keywords-1
          `(("\\<\\(&&\\(\\s_\\|\\sw\\)+\\)\\>"
             (1 font-lock-variable-name-face))
            ("\\<\\(\\$\\$\\(\\s_\\|\\sw\\)+\\)\\>"
             (1 font-lock-variable-name-face))
            (,(format "\\<\\(%s\\|[psc][lroOxX]*\\)\\>" cg-kw-flags-re)
             1 font-lock-function-name-face)
            ("\\B\\(\\^\\)"		; fail-fast
             1 font-lock-function-name-face)))
  "Gaudy level highlighting for CG modes.")

(defvar cg-font-lock-keywords cg-font-lock-keywords-1
  "Default expressions to highlight in CG modes.")

(defvar cg-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">#" table)
    ;; todo: better/possible to conflate \\s_ and \\sw into one class?
    (modify-syntax-entry ?@ "_" table)
    ;; using syntactic keywords for "
    (modify-syntax-entry ?\" "." table)
    (modify-syntax-entry ?» "." table)
    (modify-syntax-entry ?« "." table)
    table)
  "Syntax table for CG mode.")



;;; Tool-bar -----------------------------------------------------------------

(defvar cg-mode-tool-bar-map
  (when (keymapp tool-bar-map)
    (let ((map (copy-keymap tool-bar-map)))
      (define-key-after map [separator-cg] menu-bar-separator)
      (tool-bar-local-item
       "show" 'cg-edit-input 'cg-edit-input map
       :help "Edit input examples")
      (tool-bar-local-item
       "spell" 'cg-check 'cg-check map
       :help "Check input with grammar")
      (define-key-after map [separator-cg-2] menu-bar-separator)
      (tool-bar-local-item
       "sort-criteria" 'cg-output-set-unhide 'cg-output-set-unhide map
       :help "Show only matching analyses in output")
      (tool-bar-local-item
       "describe" 'cg-output-toggle-analyses 'cg-output-toggle-analyses map
       :help "Toggle analyses in output")
      map)))

(defvar cg-input-mode-tool-bar-map
  (when (keymapp tool-bar-map)
    (let ((map (copy-keymap tool-bar-map)))
      (define-key-after map [separator-cg] menu-bar-separator)
      (tool-bar-local-item
       "show" 'cg-back-to-file 'cg-back-to-file map
       :help "Back to grammar rules file")
      (tool-bar-local-item
       "spell" 'cg-back-to-file-and-check 'cg-back-to-file-and-check map
       :help "Check input with grammar")
      map)))

(defvar cg-output-mode-tool-bar-map
  (when (keymapp tool-bar-map)
    (let ((map (copy-keymap tool-bar-map)))
      (define-key-after map [separator-cg] menu-bar-separator)
      (tool-bar-local-item
       "show" 'cg-back-to-file-and-edit-input 'cg-back-to-file-and-edit-input map
       :help "Back to grammar rules file")
      (tool-bar-local-item
       "spell" 'cg-back-to-file-and-check 'cg-back-to-file-and-check map
       :help "Check input examples with grammar")
      (define-key-after map [separator-cg-2] menu-bar-separator)
      (tool-bar-local-item
       "sort-criteria" 'cg-output-set-unhide 'cg-output-set-unhide map
       :help "Show only matching analyses in output")
      (tool-bar-local-item
       "describe" 'cg-output-toggle-analyses 'cg-output-toggle-analyses map
       :help "Toggle analyses in output")
      map)))




;;; Navigation/comments ------------------------------------------------------

(defun cg-beginning-of-defun ()
  "Go to beginning of a rule."
  (re-search-backward defun-prompt-regexp nil 'noerror)
  (while (nth 4 (syntax-ppss))
    (re-search-backward defun-prompt-regexp nil 'noerror))
  (re-search-backward "\"<[^\"]>\"" (line-beginning-position) 'noerror))

(defun cg-end-of-defun ()
  "Go to end of a rule."
  (and (search-forward ";")
       (re-search-forward defun-prompt-regexp nil 'noerror)
       (goto-char (match-beginning 0)))
  (while (nth 4 (syntax-ppss))
    (and (search-forward ";")
         (re-search-forward defun-prompt-regexp nil 'noerror)
         (goto-char (match-beginning 0))))
  (re-search-backward "\"<[^\"]>\"" (line-beginning-position) 'noerror))

(defun cg--line-commented-p ()
  "Check if this line is commented or not."
  (save-excursion
    (back-to-indentation)
    (looking-at "#")))

(defun cg--region-commented-p (beg end)
  "Check if the region BEG .. END is *completely* commented or not."
  (catch 'ret
    (save-excursion
      (goto-char beg)
      (while (and (< (point) end)
                  (< (point) (point-max)))
        (if (cg--line-commented-p)
            (forward-line)
          (throw 'ret nil)))
      (throw 'ret t))))

(defun cg--comment-uncomment-rule (comment &optional n)
  "Toggle whether rule-at-point is commented out or not.
If COMMENT, always comment out.  If N is a number, do that many rules."
  (let ((i 0)
        (n (if (numberp n) n 1))
        (initial-point (point-marker)))
    (while (< i n)
      (cl-incf i)
      (let* ((r (save-excursion
                  (if (search-forward ";" nil 'noerror)
                      (1+ (point-marker))
                    (point-max))))
             (l (save-excursion
                  (goto-char r)
                  (if (re-search-backward defun-prompt-regexp nil 'noerror)
                      (goto-char (line-beginning-position))
                    (point-min)))))
        ;; Only uncomment rules if they're completely commented (but
        ;; always uncomment the first one)
        (when (or comment
                  (= i 1)
                  (cg--region-commented-p l r))
          (goto-char r)
          (skip-chars-forward "\r\n[:blank:]")
          (if comment
              (comment-region l r)
            (uncomment-region l r))
          (skip-chars-forward "\r\n[:blank:]")))
      (when (= n 1)
        (goto-char initial-point)))))

(defun cg-comment-rule (&optional n)
  "Comment a rule around point.
With a prefix argument N, comment that many rules."
  (interactive "p")
  (cg--comment-uncomment-rule 'comment n))

(defun cg-uncomment-rule (&optional n)
  "Uncomment a rule around point.
With a prefix argument N, uncomment that many rules."
  (interactive "p")
  (cg--comment-uncomment-rule nil n))

(defun cg-comment-or-uncomment-rule (&optional n)
  "Comment the rule at point.
If already inside (or before) a comment, uncomment instead.
With a prefix argument N, (un)comment that many rules."
  (interactive "p")
  (if (or (elt (syntax-ppss) 4)
          (< (save-excursion
               (skip-chars-forward "\r\n[:blank:]")
               (point))
             (save-excursion
               (comment-forward 1)
               (point))))
      (cg-uncomment-rule n)
    (cg-comment-rule n)))



;;;###autoload
(define-derived-mode cg-mode prog-mode "CG"
  "Major mode for editing Constraint Grammar files.

CG-mode provides the following specific keyboard key bindings:

\\{cg-mode-map}"
  :group 'cg
  ;; Font lock
  (set (make-local-variable 'font-lock-defaults)
       `((cg-font-lock-keywords cg-font-lock-keywords-1 cg-font-lock-keywords-2)
         nil				; KEYWORDS-ONLY
         'case-fold ; some keywords (e.g. x vs X) are case-sensitive,
                                        ; but that doesn't matter for highlighting
         ((?/ . "w") (?~ . "w") (?. . "w") (?- . "w") (?_ . "w") (?& . "w"))
         nil ;	  beginning-of-line		; SYNTAX-BEGIN
         (font-lock-syntactic-keywords . cg-font-lock-syntactic-keywords)
         (font-lock-syntactic-face-function . cg-font-lock-syntactic-face-function)))
  (setq-local tool-bar-map cg-mode-tool-bar-map)
  ;; Indentation
  (set (make-local-variable 'indent-line-function) #'cg-indent-line)
  ;; Comments and blocks
  (set (make-local-variable 'comment-start) "#")
  (set (make-local-variable 'comment-start-skip) "#+[\t ]*")
  (set (make-local-variable 'comment-use-syntax) t)
  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  (set (make-local-variable 'parse-sexp-lookup-properties) t)
  (set (make-local-variable 'defun-prompt-regexp) (concat cg-kw-re "\\(?::[^\n\t ]+\\)[\t ]"))
  (set (make-local-variable 'beginning-of-defun-function) #'cg-beginning-of-defun)
  (set (make-local-variable 'end-of-defun-function) #'cg-end-of-defun)
  ;; Completion:
  (add-to-list 'completion-at-point-functions 'cg-complete-list-set)
  ;; Syntax highlighting:
  (when font-lock-mode
    (setq font-lock-set-defaults nil)
    (font-lock-set-defaults)
    (font-lock-ensure))
  (add-hook 'after-change-functions #'cg-after-change nil 'buffer-local)
  (let* ((buf (current-buffer))
         (hl-timer (run-with-idle-timer 1 'repeat 'cg-output-hl buf)))
    (add-hook 'kill-buffer-hook
              (lambda () (cancel-timer hl-timer))
              nil
              'local)))


(defconst cg-font-lock-syntactic-keywords
  ;; We can have ("words"with"quotes"inside"")! Quote rule: is it a ",
  ;; if yes then jump to next unescaped ". Then regardless, jump to
  ;; next whitespace, but don't cross an unescaped )
  '(("\\(\"\\)[^\"\n]*\\(?:\"\\(?:\\\\)\\|[^) \n\t]\\)*\\)?\\(\"\\)[irv]\\{0,3\\}[); \n\t]"
     (1 "\"")
     (2 "\""))
    ;; A `#' begins a comment when it is unquoted and at the beginning
    ;; of a word; otherwise it is a symbol.
    ;; For this to work, we also add # into the syntax-table as a
    ;; comment, with \n to turn it off, and also need
    ;; (set (make-local-variable 'parse-sexp-lookup-properties) t)
    ;; to avoid parser problems.
    ("[^|&;<>()`\\\"' \t\n]\\(#+\\)" 1 "_")
    ;; fail-fast, at the beginning of a word:
    ("[( \t\n]\\(\\^\\)" 1 "'")))

(defun cg-font-lock-syntactic-face-function (state)
  "Determine which face to use when fontifying syntactically.

Argument STATE is assumed to be from `parse-partial-sexp' at the
beginning of the region to highlight; see
`font-lock-syntactic-face-function'."
  ;; TODO: something like
  ;; 	((= 0 (nth 0 state)) font-lock-variable-name-face)
  ;; would be great to differentiate SETs from their members, but it
  ;; seems this function only runs on comments and strings...
  (cond ((nth 3 state)
         (if
             (save-excursion
               (goto-char (nth 8 state))
               (re-search-forward "\"[^\"\n]*\\(\"\\(\\\\)\\|[^) \n\t]\\)*\\)?\"[irv]\\{0,3\\}[); \n\t]")
               (and (match-string 1)
                    (not (equal ?\\ (char-before (match-beginning 1))))
                    ;; TODO: make next-error hit these too
                    ))
             'cg-string-warning-face
           font-lock-string-face))
        (t font-lock-comment-face)))

(defface cg-string-warning-face
  '((((class grayscale) (background light)) :foreground "DimGray" :slant italic :underline "orange")
    (((class grayscale) (background dark))  :foreground "LightGray" :slant italic :underline "orange")
    (((class color) (min-colors 88) (background light)) :foreground "VioletRed4" :underline "orange")
    (((class color) (min-colors 88) (background dark))  :foreground "LightSalmon" :underline "orange")
    (((class color) (min-colors 16) (background light)) :foreground "RosyBrown" :underline "orange")
    (((class color) (min-colors 16) (background dark))  :foreground "LightSalmon" :underline "orange")
    (((class color) (min-colors 8)) :foreground "green" :underline "orange")
    (t :slant italic))
  "CG mode face used to highlight troublesome strings with unescaped quotes in them.")




;;; Indentation

(defun cg-calculate-indent ()
  "Return the indentation for the current line."
;;; idea from sh-mode, use font face?
  ;; (or (and (boundp 'font-lock-string-face) (not (bobp))
  ;; 		 (eq (get-text-property (1- (point)) 'face)
  ;; 		     font-lock-string-face))
  ;; 	    (eq (get-text-property (point) 'face) sh-heredoc-face))
  (let ((origin (point))
        (old-case-fold-search case-fold-search))
    (setq case-fold-search nil)		; for re-search-backward
    (prog1
        (save-excursion
          (let ((kw-pos (progn
                          (goto-char (1- (or (search-forward ";" (line-end-position) t)
                                             (line-end-position))))
                          (re-search-backward (concat ";\\|" cg-kw-re) nil 'noerror))))
            (when kw-pos
              (let* ((kw (match-string-no-properties 0)))
                (if (and (not (equal kw ";"))
                         (> origin (line-end-position)))
                    cg-indentation
                  0)))))
      (setq case-fold-search old-case-fold-search))))

(defun cg-indent-line ()
  "Indent the current line.

Very simple indentation: lines with keywords from `cg-kw-list'
get zero indentation, others get one indentation."
  (interactive)
  (let ((indent (cg-calculate-indent))
        (pos (- (point-max) (point))))
    (when indent
      (beginning-of-line)
      (skip-chars-forward " \t")
      (indent-line-to indent)
      ;; If initial point was within line's indentation,
      ;; position after the indentation.  Else stay at same point in text.
      (if (> (- (point-max) pos) (point))
          (goto-char (- (point-max) pos))))))


;;; Interactive functions:

(defvar cg--occur-history nil)
(defvar cg--occur-prefix-history nil)
(defvar cg--goto-history nil)

(defun cg-permute (input)
  "Permute INPUT list.

From http://www.emacswiki.org/emacs/StringPermutations"
  (if (null input)
      (list input)
    (cl-mapcan (lambda (elt)
                 (cl-mapcan (lambda (p)
                              (list (cons elt p)))
                            (cg-permute (cl-remove elt input :count 1))))
               input)))

(defun cg-read-arg (prompt history &optional default)
  "Ensure DEFAULT is in HISTORY and call `read-from-minibuffer' with PROMPT."
  (let* ((default (or default (car history)))
         (input
          (read-from-minibuffer
           (concat prompt
                   (if default
                       (format " (default: %s): " (query-replace-descr default))
                     ": "))
           nil
           nil
           nil
           (quote history)
           default)))
    (if (equal input "")
        default
      input)))

(defun cg-occur-list (&optional prefix words)
  "Do an occur-check for the left-side of a LIST/SET assignment.

WORDS is a space-separated list of words which *all* must occur
between LIST/SET and =.  Optional prefix argument PREFIX lets you
specify a prefix to the name of LIST/SET.

This is useful if you have a whole bunch of this stuff:
LIST subst-mask/fem = (n m) (np m) (n f) (np f) ;
LIST subst-mask/fem-eint = (n m sg) (np m sg) (n f sg) (np f sg) ;
etc."
  (interactive (list (when current-prefix-arg
                       (cg-read-arg
                        "Word to occur between LIST/SET and disjunction"
                        cg--occur-prefix-history))
                     (cg-read-arg
                      "Words to occur between LIST/SET and ="
                      cg--occur-history)))
  (let* ((words-perm (cg-permute (split-string words " " 'omitnulls)))
         ;; can't use regex-opt because we need .* between the words
         (perm-disj (mapconcat (lambda (word)
                                 (mapconcat 'identity word ".*"))
                               words-perm
                               "\\|")))
    (setq cg--occur-history (cons words cg--occur-history))
    (setq cg--occur-prefix-history (cons prefix cg--occur-prefix-history))
    (let ((tmp regexp-history))
      (occur (concat "\\(LIST\\|SET\\) +" prefix ".*\\(" perm-disj "\\).*="))
      (setq regexp-history tmp))))

(defun cg-goto-rule (&optional input)
  "Go to the line number of the rule described by INPUT.

INPUT is the rule info from vislcg3 --trace; e.g. if INPUT is
\"SELECT:1022:rulename\", go to the rule on line number 1022.
Interactively, use a prefix argument to paste INPUT manually,
otherwise this function uses the most recently copied line in the
X clipboard.

This makes switching between the terminal and the file slightly
faster (since double-clicking the rule info in most terminals will
select the whole string \"SELECT:1022:rulename\")."
  (interactive (list (when current-prefix-arg
                       (cg-read-arg "Paste rule info from --trace here: "
                                    cg--goto-history))))
  (let ((errmsg (if input (concat "Unrecognised rule/trace format: " input)
                  "X clipboard does not seem to contain vislcg3 --trace rule info"))
        (rule (or input (with-temp-buffer
                          (yank)
                          (buffer-substring-no-properties (point-min)(point-max))))))
    (if (string-match
         "\\(\\(select\\|iff\\|remove\\|map\\|addcohort\\|remcohort\\|switch\\|copy\\|add\\|substitute\\):\\)?\\([0-9]+\\)"
         rule)
        (progn (goto-char (point-min))
	       (forward-line (1- (string-to-number (match-string 3 rule))))
               (setq cg--goto-history (cons rule cg--goto-history)))
      (message errmsg))))



;;; Flymake ----------------------------------------------------------------

(defvar-local cg--flymake-proc nil)

(defvar cg--flymake-ignore-unused-sets
  (list "_MARK_" "_PAREN_" "_ENCL_" "_TARGET_" "_ATTACHTO_" "_SAME_BASIC_"))

(defvar cg--flymake-warnings-pattern
  (rx
   (or
    ;; apertium-nob.nob.rlx: Error: Garbage data encountered on line 7922 near `REMUVE`!
    (seq ": " (group-n 1 (or "Error" "Warning")) ": "
         (group-n 2 (* not-newline))
         " on line " (group-n 3 (+ digit)))
    ;; Unused sets:
    ;; Line 0 set _TARGET_
    ;; Line 103 set %én%
    (seq bol "Line " (group-n 4 (+ digit))
         " set " (group-n 5 (* not-newline)))
    ;; apertium-nob.nob.rlx: Warning: LIST <noen> was defined twice with the same contents: Lines 375 and 33650.
    (seq ": Warning: "
         (group-n 6 (* not-newline))
         ": Lines "
         (group-n 7 (+ digit))
         " and "
         (group-n 8 (+ digit))))))

(defun cg-flymake (report-fn &rest _args)
  "Flymake backend for Constraint Grammar.
REPORT-FN as in other flymake backends."
  (unless (executable-find "vislcg3")
    (error "Cannot find the `vislcg3' executable"))
  (when (process-live-p cg--flymake-proc)
    (kill-process cg--flymake-proc))
  (save-restriction
    (widen)
    (let ((source (current-buffer))
          (tempfile (with-temp-message ""
                      (make-temp-file "cg-flymake" nil ".cg3" (buffer-string)))))
      (setq
       cg--flymake-proc
       (make-process
        :name "cg-flymake"
        :noquery t
        :connection-type 'pipe
        :stderr nil           ; 2>&1
        :buffer (generate-new-buffer " *cg-flymake*")
        :command (list "vislcg3" "--grammar-only" "--show-unused-sets" "--grammar" tempfile)
        :sentinel
        (lambda (proc _event)
          (when (eq 'exit (process-status proc))
            (unwind-protect
                (if (with-current-buffer source (eq proc cg--flymake-proc)) ; proc is not obsolete
                    (with-current-buffer (process-buffer proc)
                      (goto-char (point-min))
                      (cl-loop
                       while (search-forward-regexp
                              cg--flymake-warnings-pattern ; either match groups (1 2 3) or (4 5) or (6 7 8)
                              nil
                              'noerror)
                       unless (member (match-string 5) cg--flymake-ignore-unused-sets)
                       for msg = (or (match-string 2)
                                     (and (match-string 5)
                                          (concat "Unused set " (match-string 5)))
                                     (and (match-string 6)
                                          (concat (match-string 6) " line " (match-string 8))))
                       for (beg . end) = (flymake-diag-region
                                          source
                                          (string-to-number (or (match-string 3)
                                                                (match-string 4)
                                                                (match-string 7))))
                       for type = (if (equal (match-string 1) "Error")
                                      :error
                                    :warning)
                       collect (flymake-make-diagnostic source
                                                        beg
                                                        end
                                                        type
                                                        msg)
                       into diags
                       finally (funcall report-fn diags)))
                  (flymake-log :warning "Canceling obsolete check %s"
                               proc))
              (kill-buffer (process-buffer proc))
              (delete-file tempfile)))))))))

(defun cg-flymake-setup-backend ()
  "Enable flymake checking for Constraint Grammar buffers."
  (add-hook 'flymake-diagnostic-functions 'cg-flymake nil t)
  (flymake-mode 1))

(add-hook 'cg-mode-hook 'cg-flymake-setup-backend)



;;; Running examples ----------------------------------------------------------------
(require 'compile)

(defvar cg--file nil
  "Which CG file the `cg-output-mode' (and `cg--check-cache-buffer')
buffer corresponds to.")
(make-variable-buffer-local 'cg--file)
(defvar cg--input-buffer nil
  "Which CG input buffer the `cg-mode' buffer corresponds to.")
(make-variable-buffer-local 'cg--input-buffer)
(defvar cg--tmp nil     ; TODO: could use cg--file iff buffer-modified-p
  "Which temporary file was sent in lieu of `cg--file' to compilation.
In case the buffer of `cg--file' was not saved.")
(make-variable-buffer-local 'cg--tmp)
(defvar cg--cache-in nil
  "Which input buffer the `cg--check-cache-buffer' corresponds to.")
(make-variable-buffer-local 'cg--cache-in)
(defvar cg--cache-pre-pipe nil
  "Which pre-pipe the output of `cg--check-cache-buffer' had.")
(make-variable-buffer-local 'cg--cache-pre-pipe)

(defun cg-edit-input (&optional pick-buffer)
  "Open a buffer to edit the input sent when running `cg-check'.
With prefix argument PICK-BUFFER, prompt for a buffer (e.g. a
text file you've already opened) to use as CG input buffer."
  (interactive "P")
  (when pick-buffer
    (setq-local cg--input-buffer (get-buffer
                                  (read-buffer-to-switch "Use as input buffer: "))))
  (pop-to-buffer
   (cg--get-input-buffer (buffer-file-name))))

;;;###autoload
(defcustom cg-check-do-cache t
  "If non-nil, `cg-check' caches the output of `cg-pre-pipe'.
The cache is emptied whenever you make a change in the input buffer,
or call `cg-check' from another CG file."
  :group 'cg
  :type 'bool)

(defvar cg--check-cache-buffer nil "See `cg-check-do-cache'.")

(defun cg-input-mode-bork-cache (_from _to _len)
  "Purge the `cg-check' cache.
Since `cg-check' will not reuse a cache unless `cg--file' and
`cg--cache-in' match."
  (when cg--check-cache-buffer
    (with-current-buffer cg--check-cache-buffer
      (setq cg--file nil
            cg--cache-pre-pipe nil
            cg--cache-in nil))))

(defun cg-pristine-cache-buffer (file in pre-pipe)
  "Make a new cache-buffer bound to this cg FILE, PRE-PIPE and input buffer IN."
  (with-current-buffer (setq cg--check-cache-buffer
                             (get-buffer-create "*cg-pre-cache*"))
    (widen)
    (delete-region (point-min) (point-max))
    (set (make-local-variable 'cg--file) file)
    (set (make-local-variable 'cg--cache-in) in)
    (set (make-local-variable 'cg--cache-pre-pipe) pre-pipe)
    (current-buffer)))

(defvar cg-input-mode-map (make-sparse-keymap)
  "Keymap for CG input mode.")

(define-derived-mode cg-input-mode fundamental-mode "CG-in"
  "Input for `cg-mode' buffers."
  (use-local-map cg-input-mode-map)
  (setq-local tool-bar-map cg-input-mode-tool-bar-map)
  (add-hook 'after-change-functions #'cg-input-mode-bork-cache nil t))


;;;###autoload
(defcustom cg-per-buffer-input 'pipe
  "Make input buffers specific to their source CG's.

If it is 'pipe (the default), input buffers will be shared by all
CG's that have the same value for `cg-pre-pipe'.

If this is 'buffer or t, the input buffer created by
`cg-edit-input' will be specific to the CG buffer it was called
from.

If it is nil, all CG buffers share one input buffer."
  :type 'symbol)

(defun cg--input-buffer-name (file)
  "Create a name for the input buffer for FILE."
  (format "*CG input%s*"
          (pcase cg-per-buffer-input
            ('nil "")
            ('pipe (concat " for " cg-pre-pipe))
            (_ (concat " for " (file-name-base file))))))

(defun cg--get-input-buffer (file)
  "Return a (possibly new) input buffer.
If `cg-per-buffer-input' is t, the buffer will have be named
after FILE; if it is 'pipe, the buffer will be named after the
`cg-pre-pipe'."
  (let ((buf (if (buffer-live-p cg--input-buffer)
                 cg--input-buffer
               (get-buffer-create (cg--input-buffer-name file)))))
    (setq-local cg--input-buffer buf)
    (with-current-buffer buf
      (cg-input-mode)
      (setq cg--file file))
    buf))

(defun cg-get-file ()
  "Get the name of the CG rule file for the output buffer."
  (list cg--file))

(defconst cg-output-regexp-alist
  `((,(format "%s:\\([^ \n\t:]+\\)\\(?::[^ \n\t]+\\)?" cg-kw-trace-rule-re)
     ,#'cg-get-file 1 nil 1)
    ("^\\([^:]*: \\)?Warning: .*?line \\([0-9]+\\).*"
     ,#'cg-get-file 2 nil 1)
    ("^\\([^:]*: \\)?Warning: .*"
     ,#'cg-get-file nil nil 1)
    ("^\\([^:]*: \\)?Error: .*?line \\([0-9]+\\).*"
     ,#'cg-get-file 2 nil 2)
    ("^\\([^:]*: \\)?Error: .*"
     ,#'cg-get-file nil nil 2)
    (".*?line \\([0-9]+\\).*"		; some error messages span several lines
     ,#'cg-get-file 1 nil 2))
  "Regexp used to match vislcg3 --trace hits.
See `compilation-error-regexp-alist'.")
;; TODO: highlight strings and @'s and #1->0's in cg-output-mode ?

;;;###autoload
(defcustom cg-output-setup-hook nil
  "List of hook functions run by `cg-output-process-setup'.
See `run-hooks'."
  :type 'hook)

(defun cg-output-process-setup ()
  "Run `cg-output-setup-hook' for `cg-check'.

That hook is useful for doing things like
 (setenv \"PATH\" (concat \"~/local/stuff\" (getenv \"PATH\")))"
  (run-hooks 'cg-output-setup-hook))

(defvar cg-output-comment-face  font-lock-comment-face	;compilation-info-face
  "Face name to use for comments in cg-output.")

(defvar cg-output-form-face	'compilation-error
  "Face name to use for forms in cg-output.")

(defvar cg-output-lemma-face	font-lock-string-face
  "Face name to use for lemmas in cg-output.")

(defvar cg-output-mapping-face 'bold
  "Face name to use for mapping tags in cg-output.")

(defvar cg-output-highlight-face 'font-lock-variable-name-face
  "Face name to use for highlighting symbol at point in grammar in cg-output.")

(defvar cg-output-mode-font-lock-keywords
  '(("^;\\(?:[^:]* \\)"
     ;; hack alert! a colon in a tag will mess this up
     ;; (hardly matters much though)
     0 cg-output-comment-face)
    ("\"<[^>\n]+>\""
     0 cg-output-form-face)
    ("\t\\(\".*\"\\) "
     ;; easier to match "foo"bar" etc. here since it's always the first tag
     1 cg-output-lemma-face)
    ("\\_<@[^ \n]+"
     0 cg-output-mapping-face))
  "Additional things to highlight in CG output.
This gets tacked on the end of the generated expressions.")

(defvar cg--output-display-table (make-display-table)
  "Used to turn ellipses into spaces when hiding analyses.")

(defvar cg-sent-tag "\\bsent\\b"
  "Any cohort matching this regex gets a newline tacked on after the wordform.
For `cg-output-hide-analyses'.")

(defvar cg-output-unhide-regex nil
  "Regular expression exempt from hiding when doing `cg-output-hide-analyses'.")

(defvar cg--output-hiding-analyses nil
  "If non-nil, re-hide analyses after `cg-check'.
Saves you from having to re-enter the buffer and press `h' if you
you want to keep analyses hidden most of the time.")

(defvar cg--output-unhide-history nil)



(define-compilation-mode cg-output-mode "CG-out"
  "Major mode for output of Constraint Grammar compilations and runs."
  (setq-local tool-bar-map cg-output-mode-tool-bar-map)
  ;; cg-output-mode-font-lock-keywords applied automagically
  (set (make-local-variable 'compilation-skip-threshold)
       1)
  (set (make-local-variable 'compilation-error-regexp-alist)
       cg-output-regexp-alist)
  (set (make-local-variable 'cg--file)
       nil)
  (set (make-local-variable 'cg--tmp)
       nil)
  (set (make-local-variable 'compilation-disable-input)
       nil)
  ;; compilation-directory-matcher can't be nil, so we set it to a regexp that
  ;; can never match.
  (set (make-local-variable 'compilation-directory-matcher)
       '("\\`a\\`"))
  (set (make-local-variable 'compilation-process-setup-function)
       #'cg-output-process-setup)
  ;; (add-hook 'compilation-filter-hook 'cg-output-filter nil t) ; TODO: nab grep code mogrifying bash colours
  ;; We send text to stdin:
  (set (make-local-variable 'compilation-disable-input)
       nil)
  (set (make-local-variable 'compilation-finish-functions)
       (list #'cg-check-finish-function))
  (modify-syntax-entry ?§ "_")
  (modify-syntax-entry ?@ "_")
  ;; For cg-output-hide-analyses:
  (add-to-invisibility-spec '(cg-output . t))
  ;; snatched from `org-mode':
  (when (and (fboundp 'set-display-table-slot) (boundp 'buffer-display-table)
	     (fboundp 'make-glyph-code))
    (set-display-table-slot cg--output-display-table
			    4
			    (vconcat (make-glyph-code " ")))
    (setq buffer-display-table cg--output-display-table)))



(defun cg-output-remove-overlay (overlay)
  "Remove the invisible cg-output OVERLAY."
  (remove-overlays (overlay-start overlay) (overlay-end overlay) 'invisible 'cg-output))

(defun cg-output-hide-region (from to)
  "Hide the region FROM .. TO using invisible overlays."
  (remove-overlays from to 'invisible 'cg-output)
  (let ((o (make-overlay from to nil)))
    (overlay-put o 'evaporate t)
    (overlay-put o 'invisible 'cg-output)
    (overlay-put o 'isearch-open-invisible 'cg-output-remove-overlay)))

(defun cg-output-show-all ()
  "Undo the effect of `cg-output-hide-analyses'."
  (interactive)
  (with-current-buffer (cg-output-buffer)
    (setq cg--output-hiding-analyses nil)
    (remove-overlays (point-min) (point-max) 'invisible 'cg-output)))

(defun cg-output-hide-analyses ()
  "Hide all analyses.

This turns the CG format back into input text (more or less).
You can still isearch through the text for tags, REMOVE/SELECT
keywords etc.

Call `cg-output-set-unhide' to set a regex which will be exempt
from hiding.  Call `cg-output-show-all' to turn off all hiding."
  (interactive)
  (with-current-buffer (cg-output-buffer)
    (setq cg--output-hiding-analyses t)
    (let (prev)
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward "^\"<.*>\"" nil 'noerror)
          (let ((line-beg (match-beginning 0))
                (line-end (match-end 0)))
            (cg-output-hide-region line-beg (+ line-beg 2)) ; "<
            (cg-output-hide-region (- line-end 2) line-end) ; >"
            (when prev
              (if (save-excursion (re-search-backward cg-sent-tag prev 'noerror))
                  (cg-output-hide-region prev (- line-beg 1))	; show newline
                (cg-output-hide-region prev line-beg))) ; hide newline too
            (setq prev line-end)))
        (goto-char prev)
        (when (re-search-forward "^[^\t\"]" nil 'noerror)
          (cg-output-hide-region prev (match-beginning 0)))))

    (when cg-output-unhide-regex
      (cg-output-unhide-some cg-output-unhide-regex))))

(defun cg-output-unhide-some (needle)
  "Remove invisible-overlays matching NEEDLE."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward needle nil 'noerror)
      (mapc (lambda (o)
	      (when (eq 'cg-output (overlay-get o 'invisible))
		(remove-overlays (overlay-start o) (overlay-end o)
				 'invisible 'cg-output)))
	    (overlays-at (match-beginning 0))))))

(defun cg-output-set-unhide (needle)
  "Make an exception to `cg-output-hide-analyses'.

If NEEDLE is the empty string, hide all analyses.
This is saved and reused whenever `cg-output-hide-analyses' is
called."
  (interactive (list (cg-read-arg
		      "Regex to unhide, or empty to hide all"
		      cg--output-unhide-history
		      "")))
  (if (equal needle "")
      (setq cg-output-unhide-regex nil)
    (setq cg-output-unhide-regex needle)
    (setq cg--output-unhide-history (cons needle cg--output-unhide-history)))
  (cg-output-hide-analyses))

(defun cg-output-toggle-analyses ()
  "Hide or show analyses from output.
See `cg-output-hide-analyses'."
  (interactive)
  (with-current-buffer (cg-output-buffer)
    (if cg--output-hiding-analyses
        (cg-output-show-all)
      (cg-output-hide-analyses))))



;;;###autoload
(defcustom cg-check-after-change nil
  "If non-nil, run `cg-check' on grammar after each change to the buffer."
  :group 'cg
  :type 'bool)

;;;###autoload
(defcustom cg-check-after-change-secs 1
  "Minimum seconds between each `cg-check' after a change to a CG buffer.
Use 0 to check immediately after each change."
  :type 'integer)

(defvar cg--after-change-timer nil)
(defun cg-after-change (_from _to _len)
  "For use in `after-change-functions'."
  (when (and cg-check-after-change
             (not (member cg--after-change-timer timer-list)))
    (setq
     cg--after-change-timer
     (run-at-time
      cg-check-after-change-secs
      nil
      (lambda ()
        (unless (cg-output-running)
	  (with-demoted-errors "cg-after-change: %S" (cg-check))))))))

(defcustom cg-output-always-highlight nil
  "Regexp patterns of tags to always highlight in output, with a face to use."
  :local t
  :safe (lambda (_) t)
  :type '(repeat (cons regexp face)))

(defun cg-output-hl-always-patterns ()
  "Highlight the `cg-output-always-highlight' patterns in output.
That variable is buffer-local, but the value is copied from cg
buffer to cg-output-buffer on check."
  (with-current-buffer (cg-output-buffer)
    (dolist (pat.face cg-output-always-highlight)
      (cg-hl-pat (car pat.face) (cdr pat.face)))))

(defun cg-output-hl (cg-buffer)
  "Highlight the symbol at point of CG-BUFFER in the output buffer."
  (when (eq (current-buffer) cg-buffer)
    (let* ((sym (symbol-at-point))
	   (sym-re (regexp-quote (symbol-name sym))))
      ;; TODO: make regexp-opts of the LIST definitions and search
      ;; those as well?
      (with-current-buffer (cg-output-buffer)
        (when (and sym-re
	           (get-buffer-window)
	           (not (cg-output-running)))
          (remove-overlays (point-min) (point-max) 'face cg-output-highlight-face)
          (cg-hl-pat sym-re cg-output-highlight-face))))))

(defun cg-hl-pat (pat face)
  "Highlight tag matching regex PAT with FACE in current buffer."
  (let ((pat-delimited (concat "\\(?:^\\|[ \"(:]\\)\\("
			       pat
                               "\\)\\(?:[:)\" ]\\|$\\)")))
    (goto-char (point-min))
    (while (re-search-forward pat-delimited nil 'noerror)
      (overlay-put (make-overlay (match-beginning 1) (match-end 1))
		   'face face))))

(defun cg-output-running ()
  "Check if we're already running a vislcg3 process."
  (let ((proc (get-buffer-process (cg-output-buffer))))
    (and proc (eq (process-status proc) 'run))))

(defun cg-output-buffer-name (mode)
  "Construct a name for the output buffer if we're in the right MODE."
  (if (equal mode "cg-output")
      (concat "*CG output for " (file-name-base cg--file) "*")
    (error "Unexpected mode %S" mode)))

(defun cg-output-buffer ()
  "Get or make the output buffer for this grammar file."
  (let ((cg--file (if (eq major-mode 'cg-mode)
		      (buffer-file-name)
		    cg--file)))
    (get-buffer-create (compilation-buffer-name
			"cg-output"
			'cg-output-mode
			'cg-output-buffer-name))))

(defun cg-end-process (proc &optional string)
  "End PROC, optionally first sending in STRING."
  (when string
    (process-send-string proc string))
  (process-send-string proc "\n")
  (process-send-eof proc))

(defun cg-check ()
  "Run vislcg3 --trace on the buffer with your example inputs.

A temporary file is created in case you haven't saved yet.

If you've set `cg-pre-pipe', input will first be sent through
that.  Set your test input sentence(s) with `cg-edit-input'.
If you want to send a whole file instead, just set `cg-pre-pipe' to
something like
\"zcat corpus.gz | lt-proc analyser.bin | cg-conv\".

Similarly, `cg-post-pipe' is run on output."
  (interactive)
  (let*
      ((file (buffer-file-name))
       (tmp (make-temp-file "cg."))
       ;; Run in a separate process buffer from cmd and post-pipe:
       (pre-pipe (if (and cg-pre-pipe (not (equal "" cg-pre-pipe)))
                     cg-pre-pipe
                   "cat"))
       ;; Tacked on to cmd, thus the |:
       (post-pipe (if (and cg-post-pipe (not (equal "" cg-post-pipe)))
                      (concat " | " cg-post-pipe)
                    ""))
       ;; cg-proc doesn't expect the --grammar argument (a bit hacky,
       ;; better would be to make cg-extra-args a function taking
       ;; grammar path as string):
       (grammar-arg (if (string-match-p ".*cg-proc$" cg-command)
                        ""
                      "--grammar"))
       (cmd (concat
             cg-command " " cg-extra-args " " grammar-arg " " tmp " "
             post-pipe))
       (in (cg--get-input-buffer file))
       (out (progn (write-region (point-min) (point-max) tmp)
                   (compilation-start
                    cmd
                    'cg-output-mode
                    'cg-output-buffer-name)))
       ; copy of the buffer-local variable
       (patterns cg-output-always-highlight))

    (with-current-buffer out
      (setq-local cg-output-always-highlight patterns)
      (setq cg--tmp tmp)
      (setq cg--file file))

    (if (and cg-check-do-cache
             (buffer-live-p cg--check-cache-buffer)
             (with-current-buffer cg--check-cache-buffer
               ;; Check that the cache is for this grammar and input:
               (and (equal cg--cache-pre-pipe pre-pipe)
                    (equal cg--file file)
                    (equal cg--cache-in in))))

        (with-current-buffer cg--check-cache-buffer
          (cg-end-process (get-buffer-process out) (buffer-string)))

      (let ((cg-proc (get-buffer-process out))
            (pre-proc (start-process "cg-pre-pipe" "*cg-pre-pipe-output*"
                                     "/bin/bash" "-c" pre-pipe))
            (cache-buffer (cg-pristine-cache-buffer file in pre-pipe)))
        (set-process-filter pre-proc (lambda (_pre-proc string)
                                       (with-current-buffer cache-buffer
                                         (insert string))
                                       (when (eq (process-status cg-proc) 'run)
                                         (process-send-string cg-proc string))))
        (set-process-sentinel pre-proc (lambda (_pre-proc _string)
                                         (when (eq (process-status cg-proc) 'run)
                                           (cg-end-process cg-proc))))
        (with-current-buffer in
          (cg-end-process pre-proc (buffer-string)))))

    (display-buffer out)))

(defun cg-check-finish-function (buffer _change)
  "BUFFER as in `compilation-finish-functions'."
  ;; Note: this makes `recompile' not work, which is why `g' is
  ;; rebound in `cg-output-mode'
  (let ((w (get-buffer-window buffer)))
    (when w
      (with-selected-window (get-buffer-window buffer)
        (scroll-up-line 4))))
  (with-current-buffer buffer
    (delete-file cg--tmp))
  (cg-output-hl-always-patterns)
  (when cg--output-hiding-analyses
    (cg-output-hide-analyses)))

(defun cg-back-to-file-and-edit-input ()
  "Open buffer with example inputs."
  (interactive)
  (cg-back-to-file)
  (cg-edit-input))

(defun cg-back-to-file ()
  "Open buffer of grammar rules file."
  (interactive)
  (let ((cg-buffer (find-buffer-visiting cg--file)))
    (if (cdr (window-list))
        (delete-window)
      (bury-buffer))
    (let ((cg-window (get-buffer-window cg-buffer)))
      (if cg-window
	  (select-window cg-window)
	(pop-to-buffer cg-buffer)))))


(defun cg-back-to-file-and-check ()
  "Open buffer of grammar rules file and check examples."
  (interactive)
  (cg-back-to-file)
  (cg-check))


(defun cg-toggle-check-after-change ()
  "Toggle whether we should run examples on each change to rules."
  (interactive)
  (setq cg-check-after-change (not cg-check-after-change))
  (message "%s after each change" (if cg-check-after-change
                                      (format "Checking CG %s seconds" cg-check-after-change-secs)
                                    "Not checking CG")))




;;; xref support --------------------------------------------------------------

(declare-function xref-make-bogus-location "xref" (message))
(declare-function xref-make "xref" (summary location))
(declare-function xref-collect-references "xref" (symbol dir))

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql cg)))
  "Return identifier at point for CG syntax."
  (format "%s" (symbol-at-point)))

(defvar cg--set-definition-re "^ *\\(?:[Ll][Ii][Ss]\\|[Ss][Ee]\\)t\\s +\\(%s\\)\\(?:\\s \\|=\\)")

(cl-defmethod xref-backend-identifier-completion-table ((_backend (eql cg)))
  "Return the completion table for CG identifiers."
  (completion-table-dynamic
   (lambda (prefix)
     (let* ((prefix-re (concat (replace-quote prefix)
                               "\\S *"))
            (def-re (format cg--set-definition-re prefix-re))
            matches)
       (save-excursion
         (save-restriction
           (widen)
           (goto-char (point-min))
           (while (re-search-forward def-re nil 'noerror)
             (push (match-string-no-properties 1) matches))))
       matches))
   'switch-buffer))

(defun cg-complete-list-set ()
  "Simple dabbrev-like completion for `completion-at-point-functions'."
  (let ((bounds (or (bounds-of-thing-at-point 'symbol)
                    (cons (point) (point)))))
    (list (car bounds)
          (cdr bounds)
          (xref-backend-identifier-completion-table 'cg))))

(cl-defmethod xref-backend-definitions ((_backend (eql cg)) symbol)
  "Find definitions of SYMBOL.
Only lists/sets for now."
  (let* ((loc
          (save-excursion
            (save-restriction
              (widen)
              (goto-char (point-min))
              (and
               (re-search-forward (format cg--set-definition-re symbol) nil 'noerror)
               (xref-make-file-location (buffer-file-name)
                                        (line-number-at-pos) ; TODO: this is slow!
                                        (current-column)))))))
    (when loc
      (list (xref-make (format "%s" symbol) loc)))))

(cl-defmethod xref-backend-references ((_backend (eql cg)) symbol)
  "Find references of SYMBOL – not yet implemented."
  (message "Not yet implemented")
  nil)

(defun cg--xref-backend ()
  "Use this in `xref-backend-functions' to get CG references."
  'cg)

(defun cg-setup-xref ()
  "Use this in `cg-mode-hook' to get CG cross-references."
  (define-key cg-mode-map (kbd "M-.") 'xref-find-definitions)
  (add-hook 'xref-backend-functions #'cg--xref-backend nil t))

(add-hook 'cg-mode-hook #'cg-setup-xref)

;;; Keybindings ---------------------------------------------------------------
(define-key cg-mode-map (kbd "C-c C-o") #'cg-occur-list)
(define-key cg-mode-map (kbd "C-c C-r") #'cg-goto-rule)
(define-key cg-mode-map (kbd "C-c C-c") #'cg-check)
(define-key cg-mode-map (kbd "C-c C-i") #'cg-edit-input)
(define-key cg-mode-map (kbd "C-c M-c") #'cg-toggle-check-after-change)
(define-key cg-mode-map (kbd "C-;") #'cg-comment-or-uncomment-rule)
(define-key cg-mode-map (kbd "M-#") #'cg-comment-or-uncomment-rule)
(define-key cg-mode-map (kbd "C-c C-u") #'cg-output-set-unhide)
(define-key cg-mode-map (kbd "C-c C-v") #'cg-output-toggle-analyses)

(define-key cg-output-mode-map (kbd "C-c C-i") #'cg-back-to-file-and-edit-input)
(define-key cg-output-mode-map (kbd "i") #'cg-back-to-file-and-edit-input)
(define-key cg-output-mode-map (kbd "g") #'cg-back-to-file-and-check)
(define-key cg-output-mode-map (kbd "h") #'cg-output-toggle-analyses)
(define-key cg-output-mode-map (kbd "u") #'cg-output-set-unhide)
;;; TODO: C-c C-h for toggling hiding from grammar buffer? That'll
;;; shadow the old C-c C-h binding though ("help for C-c prefix")

(define-key cg-input-mode-map (kbd "C-c C-c") #'cg-back-to-file-and-check)
(define-key cg-output-mode-map (kbd "C-c C-c") #'cg-back-to-file)

(define-key cg-output-mode-map (kbd "n") 'next-error-no-select)
(define-key cg-output-mode-map (kbd "p") 'previous-error-no-select)

(define-key cg-mode-map (kbd "C-c C-n") 'next-error)
(define-key cg-mode-map (kbd "C-c C-p") 'previous-error)

;;; Turn on for .cg3 and .rlx files -------------------------------------------
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.rlx\\'" . cg-mode))
(add-to-list 'auto-mode-alist '("\\.cg3\\'" . cg-mode))
;; Tino Didriksen recommends this file suffix.

;;; Run hooks -----------------------------------------------------------------
(run-hooks 'cg-load-hook)

(provide 'cg)

;;;============================================================================

;;; cg.el ends here
