;;; typst-mode.el --- A major mode for working with Typst typesetting system -*- lexical-binding: t; -*-

;; Version: 0.1
;; Package-Version: 20230425.337
;; Package-Commit: 5ce6669a28e57ea6f1009c85543d28686212cf32
;; Author: Ziqi Yang
;; Keywords: outlines
;; URL: https://github.com/Ziqi-Yang/typst-mode.el
;; License: GNU General Public License >= 3
;; Package-Requires: ((polymode "0.2.2") (emacs "24.3"))

;; Copyright (C) 2023, Ziqi Yang
;; This file is NOT part of Emacs.
;; This program is free software: you can redistribute it and/or modify
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

;; An Emacs major mode for typst, a markup-based typesetting system
;; https://github.com/Ziqi-Yang/typst-mode.el
;; See https://typst.app/

;;; Code:

(require 'polymode)
(require 'rx)

;;; Groups ==================================================
(defgroup typst nil
  "Typst Writing."
  :prefix "typst-"
  :group 'text
  :group 'languages)

(defgroup typst-mode-faces nil
  "Faces for syntax highlighting."
  :group 'typst
  :group 'faces)

(defgroup typst-mode-markup-faces nil
  "Faces for syntax highlighting."
  :group 'typst-mode-faces
  :group 'faces)

(defgroup typst-mode-code-faces nil
  "Faces for syntax highlighting."
  :group 'typst-mode-faces
  :group 'faces)

(defgroup typst-mode-math-faces nil
  "Faces for syntax highlighting."
  :group 'typst-mode-faces
  :group 'faces)

;;; Variables ===============================================
(defcustom typst-markup-tab-width  4
  "Default tab width for typst markup mode."
  :type 'integer
  :group 'typst)

(defcustom typst-code-tab-width  4
  "Default tab width for typst code mode."
  :type 'integer
  :group 'typst)

(defcustom typst-indent-offset  4
  "Default indentation offset for Typst mode."
  :type 'integer
  :group 'typst)

(defcustom typst-buffer-name  "*typst-mode*"
  "The output buffer name for some compilation and preview command."
  :type 'string
  :group 'typst)

(defcustom typst-executable-location  "typst"
  "The location or name(if in PATH) for typst executable."
  :type 'string
  :group 'typst)

(defcustom typst-pdf-preview-command
  (cond
    ((eq system-type 'darwin) "open %s") ;; mac os
    ((eq system-type 'gnu/linux) "xdg-open %s")
    ((eq system-type 'windows-nt) "start %s"))
  "Command to open/preview pdf.  '%s' stand for the pdf file name."
  :type 'string
  :group 'typst)

(defconst typst--puncts
  '("+" "-" "*" "/" "<"  ">" "=" ;; operator
     "`" "~" "!" "@" "#" "$" "%" "^" "&" "-" "_" "|" "?"
     "{" "}" "(" ")" "[" "]"
     "," "." "\\")
  "All punctuation characters.")

(defun typst--punct-exclude (exclude-list)
  "Exclude all elements from `EXCLUDE-LIST' in `typst--puncts'."
  (let ((punct typst--puncts))
	  (dolist (chr exclude-list)
		  (setq punct (remove chr punct)))
	  punct))

;;; Faces & Corresponding variables =========================
;; @ markup mode
(defface typst-mode-markup-emphasis-face
  '((t :slant italic))
  "Face for emphasis text."
  :group 'typst-mode-markup-faces)
(defvar typst-mode-markup-emphasis-face  'typst-mode-markup-emphasis-face
  "Face name to use for emphasis text.")

(defface typst-mode-markup-strong-face
  '((t :weight bold))
  "Face for strong text."
  :group 'typst-mode-markup-faces)
(defvar typst-mode-markup-strong-face  'typst-mode-markup-strong-face
  "Face name to use for strong text.")

(defface typst-mode-markup-underline-face
  '((t :underline t))
  "Face for underline text."
  :group 'typst-mode-markup-faces)
(defvar typst-mode-markup-underline-face  'typst-mode-markup-underline-face
  "Face name to use for underline text.")

(defface typst-mode-markup-raw-text-face
  '((t :foreground "dim gray"))
  "Face for raw-text."
  :group 'typst-mode-markup-faces)
(defvar typst-mode-markup-raw-text-face  'typst-mode-markup-raw-text-face
  "Face name to use for raw text.")

(defface typst-mode-markup-label-reference-face
  '((t :foreground "blue"))
  "Face for label and reference."
  :group 'typst-mode-markup-faces)
(defvar typst-mode-markup-label-reference-face  'typst-mode-markup-label-reference-face
  "Face name to use for label and reference.")

(defface typst-mode-markup-heading-1-face
  '((t :weight bold :height 150))
  "Face for heading 1."
  :group 'typst-mode-markup-faces)
(defvar typst-mode-markup-heading-1-face  'typst-mode-markup-heading-1-face
  "Face name to use for heading 1.")

(defface typst-mode-markup-heading-2-face
  '((t :inherit typst-mode-markup-heading-1-face :height 140))
  "Face for heading 2."
  :group 'typst-mode-markup-faces)
(defvar typst-mode-markup-heading-2-face  'typst-mode-markup-heading-2-face
  "Face name to use for heading 2.")

(defface typst-mode-markup-heading-3-face
  '((t :inherit typst-mode-markup-heading-1-face :height 130))
  "Face for heading 3."
  :group 'typst-mode-markup-faces)
(defvar typst-mode-markup-heading-3-face  'typst-mode-markup-heading-3-face
  "Face name to use for heading 3.")

(defface typst-mode-markup-heading-4-face
  '((t :inherit typst-mode-markup-heading-1-face :height 120))
  "Face for heading 4."
  :group 'typst-mode-markup-faces)
(defvar typst-mode-markup-heading-4-face  'typst-mode-markup-heading-4-face
  "Face name to use for heading 4.")

(defface typst-mode-markup-heading-5-face
  '((t :inherit typst-mode-markup-heading-1-face :height 110))
  "Face for heading 5."
  :group 'typst-mode-markup-faces)
(defvar typst-mode-markup-heading-5-face  'typst-mode-markup-heading-5-face
  "Face name to use for heading 5.")

(defface typst-mode-markup-term-list-face
  '((t :weight bold))
  "Face for heading 5."
  :group 'typst-mode-markup-faces)
(defvar typst-mode-markup-term-list-face  'typst-mode-markup-term-list-face
  "Face name to use for heading 5.")

(defface typst-mode-markup-slash-face
  '((t :foreground "blue"))
  "Face for slash."
  :group 'typst-mode-markup-faces)
(defvar typst-mode-markup-slash-face  'typst-mode-markup-slash-face
  "Face name to use for slash.")

;;; Regexps & Keywords ======================================

;; @ base
(defconst typst--base-keywords
  '("let" "set" "show" "if" "for" "while" "include" "import")
  "Keywords for typst mode.")

(defconst typst--base-operators
  ;; 'not in' can be composed by "in" and "not"
  ;; same as "==",  "<=", ">=", "+=", "-=", "*=", "/="
  '("+" "-" "*" "/" "<"  ">" "in" "not" "and" "or" "=" "!="))

;; @ code
(defconst typst--code-keywords-regexp
  ;; group 1
  (eval `(rx (or blank bol "{") (group-n 1 (or ,@typst--base-keywords "else")) (or blank eol ":")))
  "Keywords regexp for typst code mode.")

(defconst typst--code-operators-regexp
  (eval `(rx blank (group-n 1 (or ,@typst--base-operators)) blank))
  "Operators regexp for typst code mode.")

(defconst typst--code-constant-regexp
  ;; TODO not graceful
  ;; exclude `.` `%` in rx's character set `punct`
  (let ((puncts (typst--punct-exclude '("." "%"))))
    (eval `(rx (or ,@puncts blank bol)
             (group-n 1
               (or
                 "none"                  ;; none
                 "auto"                  ;; auto
                 "false" "true"          ;; boolean
                 (1+ digit)              ;; integer
                 (1+ (or digit "e" ".")) ;; float
                 (seq (1+ (or digit "e" ".")) (or "pt" "mm" "cm" "in" "em")) ;; length
                 (seq (1+ (or digit "e" ".")) (or "deg" "rad")) ;; angle
                 (seq (1+ (or digit "e" ".")) "%") ;; ratio
                 ;; pass relative length
                 (seq (1+ (or digit "e" ".")) "fr") ;; fraction
                 ;; pass color TODO
                 ;; pass string (already in syntax table)
                 ;; pass array
                 ;; pass dictionary
                 ;; pass arguments
                 ))
             (or ,@puncts blank eol))))
  "Constant regexp for typst code mode.")

(defconst typst--code-symbol-regexp
  (rx (or punct blank) (group-n 1 (1+ (syntax word))) ".")
  "Symbol regexp for typst code mode.")

(defconst typst--code-field-regexp
  (rx (or punct blank) (1+ (syntax word)) "." (group-n 1 (+ (syntax word))))
  "Field regexp for typst code mode.")

(defconst typst--code-function-method-regexp
  (rx (or punct blank "") (group-n 1 (+ (syntax word))) "(")
  "Function/Method regexp for typst code mode.")

;; TODO support function/method call
(defconst typst--code-variable-regexp
  (let ((punct (typst--punct-exclude '(":" "-" "_" "," ")" "]" "}"))))
    (eval `(rx (or blank bol "#") (group-n 1 (+ (syntax word))) (* blank) (or ,@punct blank eol))))
  "Function/Method regexp for typst code mode.")

;; @ markup
(defconst typst--markup-keywords-regexp
  (let ((keywords (mapcar (lambda (keyword) (concat "#" keyword)) typst--base-keywords)))
    (eval `(rx (or blank bol) (group-n 1 (or ,@keywords)) (or blank eol))))
  "Keywords regexp for typst markup mode.")

;; NOTE: this regexp is needed since clause like `#if x == 1 [` won't enter into code mode
(defconst typst--markup-else-keyword-regexp ;; else and else if
  (rx bol (*? not-newline) (syntax close-parenthesis)
    (* blank) (group-n 1 (or "else" (seq "else" (* blank) "if")))(* blank) (syntax open-parenthesis)))

(defconst typst--markup-comment-regexp ;; don't interfer URLs
  (rx (or (and (or bol (1+ whitespace)) "//" (*? anything) eol)
        (and (or bol (1+ whitespace)) "/*" (*? anything) "*/"))))

(defconst typst--markup-strong-regexp ;; don't interfer URLs
  (rx "*" (+ (or (syntax word) blank)) "*"))

(defconst typst--markup-emphasis-regexp
  (rx "_" (+ (or (syntax word) blank)) "_"))

(defconst typst--markup-raw-text-regexp
  (rx "`" (1+ (not blank)) "`"))

(defconst typst--markup-link-regexp
  (rx (or "http://" "https://") (1+ (or alnum ":" "." "/" "-"))))

(defconst typst--markup-label-regexp
  (rx "<" (1+ (not (any punct blank))) ">"))

(defconst typst--markup-reference-regexp
  (rx "@" (1+ (not (any punct blank)))))

(defconst typst--markup-heading-1-regexp
  ;; don't include label
  (rx bol (* blank) "=" (1+ blank) (seq (? (not blank)) (* (not (or "\n" "<"))))))

(defconst typst--markup-heading-2-regexp
  ;; don't include label
  (rx bol (* blank) "==" (1+ blank) (seq (? (not blank)) (* (not (or "\n" "<"))))))

(defconst typst--markup-heading-3-regexp
  ;; don't include label
  (rx bol (* blank) "===" (1+ blank) (seq (? (not blank)) (* (not (or "\n" "<"))))))

(defconst typst--markup-heading-4-regexp
  ;; don't include label
  (rx bol (* blank) "====" (1+ blank) (seq (? (not blank)) (* (not (or "\n" "<"))))))

(defconst typst--markup-heading-5-regexp
  ;; don't include label
  (rx bol (* blank) "=====" (1+ blank) (seq (? (not blank)) (* (not (or "\n" "<"))))))

(defconst typst--markup-term-list-regexp
  (rx bol (* blank) "/" (1+ blank) (group-n 1 (1+ (not ":") )) ":" (* not-newline)))

(defconst typst--markup-term-list-regexp
  (rx bol (* blank) "/" (1+ blank) (group-n 1 (1+ (not ":") )) ":" (* not-newline)))

(defconst typst--markup-slash-regexp ;; for line break and escape character
  (rx "\\" (? (not blank))))

;; @ Keywords table
(defvar typst--markup-font-lock-keywords
  `((,typst--markup-keywords-regexp . font-lock-keyword-face)
     (,typst--markup-else-keyword-regexp 1 font-lock-keyword-face)
     ("#\\w+" . font-lock-function-name-face)
     (,typst--markup-comment-regexp . font-lock-comment-face)
     (,typst--markup-strong-regexp . typst-mode-markup-strong-face) ;; strong
     (,typst--markup-emphasis-regexp . typst-mode-markup-emphasis-face) ;; emphasized
     (,typst--markup-raw-text-regexp . typst-mode-markup-raw-text-face) ;; raw text
     (,typst--markup-link-regexp . typst-mode-markup-underline-face) ;; link
     (,typst--markup-label-regexp . typst-mode-markup-label-reference-face) ;; label
     (,typst--markup-reference-regexp . typst-mode-markup-label-reference-face) ;; reference
     ;; headings
     (,typst--markup-heading-1-regexp . typst-mode-markup-heading-1-face) ;; heading 1
     (,typst--markup-heading-2-regexp . typst-mode-markup-heading-2-face) ;; heading 2
     (,typst--markup-heading-3-regexp . typst-mode-markup-heading-3-face) ;; heading 3
     (,typst--markup-heading-4-regexp . typst-mode-markup-heading-4-face) ;; heading 4
     (,typst--markup-heading-5-regexp . typst-mode-markup-heading-5-face) ;; heading 5
     ;; do nothing with bullet list
     ;; do nothing with Numbered list
     (,typst--markup-term-list-regexp 1 typst-mode-markup-term-list-face) ;; term list
     (,typst--markup-slash-regexp . typst-mode-markup-slash-face) ;; slash(line break and escape character)
     )
  "Minimal highlighting expressions for typst mode.")

(defvar typst--code-font-lock-keywords
  `((,typst--code-keywords-regexp 1 font-lock-keyword-face)
     (,typst--code-operators-regexp . font-lock-builtin-face)
     (,typst--code-constant-regexp 1 font-lock-constant-face)
     (,typst--code-symbol-regexp 1 font-lock-variable-name-face)
     (,typst--code-function-method-regexp 1 font-lock-function-name-face) ;; must be placed before typst--code-field-regexp
     (,typst--code-field-regexp 1 font-lock-string-face)
     ;; (,typst--code-variable-regexp 1 font-lock-variable-name-face) ;; NOTE
     )
  "Minimal highlighting expressions for typst mode.")

(defvar typst--math-font-lock-keywords
  nil
  "Minimal highlighting expressions for typst mode.")

;;; Hooks ===================================================
(defvar typst-mode-hook nil)

;;; Syntax tables ===========================================
(defvar typst--base-syntax-table
  (let ((syntax-table (make-syntax-table)))
    (modify-syntax-entry ?\" "." syntax-table) ;; change the default syntax entry for double quote(string quote character '"')
     (modify-syntax-entry ?\n "> b" syntax-table)
     (modify-syntax-entry ?\( "(" syntax-table)
     (modify-syntax-entry ?\[ "(" syntax-table)
     (modify-syntax-entry ?\{ "(" syntax-table)
     (modify-syntax-entry ?\) ")" syntax-table)
     (modify-syntax-entry ?\] ")" syntax-table)
     (modify-syntax-entry ?\} ")" syntax-table)
     syntax-table)
  "Syntax table for `typst--markup-mode'.")

(defvar typst--markup-syntax-table
  (let ((syntax-table (make-syntax-table typst--base-syntax-table)))
    (modify-syntax-entry ?\\ "\\" syntax-table)
    syntax-table)
  "Syntax table for `typst--markup-mode'.")

(defvar typst--code-syntax-table
  (let ((syntax-table (make-syntax-table typst--base-syntax-table)))
    (modify-syntax-entry ?\" "\"" syntax-table)
    (modify-syntax-entry ?/ ". 124b" syntax-table)
    (modify-syntax-entry ?* ". 23" syntax-table)
    syntax-table)
  "Syntax table for `typst--code-mode'.")

;; (defvar typst--math-syntax-table
;;   (let ((syntax-table (make-syntax-table typst--base-syntax-table)))
;;     (modify-syntax-entry ?\" "\"" syntax-table)
;;     (modify-syntax-entry ?/ ". 124b" syntax-table)
;;     (modify-syntax-entry ?* ". 23" syntax-table)
;;     syntax-table)
;;   "Syntax table for `typst--code-mode'.")

;;; Keymaps =================================================
(defvar typst-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'typst-compile)
    (define-key map (kbd "C-c C-p") 'typst-preview)
    (define-key map (kbd "C-c C-w") 'typst-toggle-watch)
    map))

;;; Indentation =============================================
;; NOTE: this code is from zig-mode: https://github.com/ziglang/zig-mode/blob/master/zig-mode.el
(defun typst-paren-nesting-level ()
  "Get the paren nesting level."
  (nth 0 (syntax-ppss)))

;; NOTE: this code is from zig-mode: https://github.com/ziglang/zig-mode/blob/master/zig-mode.el
(defun typst-mode-indent-line ()
  "Indente line function for typst mode."
  (interactive)
  ;; First, calculate the column that this line should be indented to.
  (let ((indent-col
          (save-excursion
            (back-to-indentation)
            (let* (;; paren-level: How many sets of parens (or other delimiters)
                    ;;   we're within, except that if this line closes the
                    ;;   innermost set(s) (e.g. the line is just "}"), then we
                    ;;   don't count those set(s).
                    (paren-level
                      (save-excursion
                        (while (looking-at "[]})]") (forward-char))
                        (typst-paren-nesting-level)))
                    ;; prev-block-indent-col: If we're within delimiters, this is
                    ;; the column to which the start of that block is indented
                    ;; (if we're not, this is just zero).
                    (prev-block-indent-col
                      (if (<= paren-level 0) 0
                        (save-excursion
                          (while (>= (typst-paren-nesting-level) paren-level)
                            (backward-up-list)
                            (back-to-indentation))
                          (current-column))))
                    ;; base-indent-col: The column to which a complete expression
                    ;;   on this line should be indented.
                    (base-indent-col
                      (if (<= paren-level 0)
                        prev-block-indent-col
                        (or (save-excursion
                              (backward-up-list)
                              (forward-char)
                              (and (not (looking-at " *\\(//[^\n]*\\)?\n"))
                                (current-column)))
                          (+ prev-block-indent-col typst-indent-offset)))))
              ;; (message "%s %s %s %s" paren-level prev-block-indent-col base-indent-col is-expr-continutation)
              base-indent-col))))
    ;; If point is within the indentation whitespace, move it to the end of the
    ;; new indentation whitespace (which is what the indent-line-to function
    ;; always does).  Otherwise, we don't want point to move, so we use a
    ;; save-excursion.
    (if (<= (current-column) (current-indentation))
      ;; (progn
      (indent-line-to indent-col)
      ;; (message "%s %s" (current-column) (current-indentation))
      ;; )
      (save-excursion (indent-line-to indent-col)))))

;;; Functions ===============================================
(defun typst--process-exists-p (process-name)
  "Return non-nil if a process with PROCESS-NAME is currently running."
  (let ((process-list (process-list)))
    (catch 'found
      (dolist (process process-list)
        (when (string= process-name (process-name process))
          (when (eq (process-status process) 'run)
            (throw 'found t)))))))

(defun typst-compile ()
  "Compile the current typst file using typst."
  (interactive)
  (compile compile-command))

(defun typst-preview ()
  "Preview the compiled pdf file."
  (interactive)
  (start-process-shell-command "typst preview" typst-buffer-name
    (format typst-pdf-preview-command
      (concat (file-name-sans-extension (file-name-nondirectory (buffer-file-name))) ".pdf"))))

(defun typst-compile-preview()
  "Compile and then open the compiled pdf file for preview."
  (interactive)
  (compile (concat compile-command " --open")))

(defun typst-watch ()
  "Watch(real time compile & preview) the corresponding pdf file."
  (interactive)
  (let ((file-name (file-name-nondirectory buffer-file-name))
         (watch-process-name "typst watch" ))
    (unless (typst--process-exists-p watch-process-name)
      (start-process-shell-command watch-process-name typst-buffer-name
        (format "%s watch %s %s --open"
          typst-executable-location
          file-name
          (concat (file-name-sans-extension file-name) ".pdf"))))))

(defun typst-stop-watch ()
  "Stop typst watch process."
  (interactive)
  (let ((watch-process-name "typst watch"))
    (delete-process watch-process-name)))

(defun typst-toggle-watch()
  "Toggle tyspt watch."
  (interactive)
  (let ((watch-process-name "typst watch" ))
    (if (typst--process-exists-p watch-process-name)
      (typst-stop-watch)
      (typst-watch))))

;;; Mode definition =========================================
(define-derived-mode typst--base-mode text-mode "Typst"
  "Generic major mode for editing Typst files.

This is a generic major mode intended to be inherited by
concrete implementations.  Currently there are two concrete
implementations: `typst-mode' and `typst-ts-mode'."
  ;; :syntax-table typst-syntax-table
  (setq-local tab-width 4
    indent-line-function 'typst-mode-indent-line
    tab-width typst-code-tab-width
    font-lock-keywords-only t))

(define-derived-mode typst--markup-mode typst--base-mode "Typst"
  "Major mode for editing Typst files.

\\{typst-mode-map}"
  :syntax-table typst--markup-syntax-table
  (setq-local font-lock-multiline nil
    font-lock-defaults '(typst--markup-font-lock-keywords)))

(define-derived-mode typst--code-mode typst--base-mode "Typst"
  "Major mode for editing Typst files.

\\{typst-mode-map}"
  :syntax-table typst--code-syntax-table
  (setq-local font-lock-multiline nil
    font-lock-defaults '(typst--code-font-lock-keywords)))

(define-derived-mode typst--math-mode typst--base-mode "Typst"
  "Major mode for editing Typst files.

\\{typst-mode-map}"
  ;; :syntax-table typst--code-syntax-table
  (setq-local font-lock-multiline nil
    font-lock-defaults '(typst--math-font-lock-keywords)))

(define-hostmode typst--poly-hostmode
  :mode 'typst--markup-mode)

(define-innermode typst--poly-code-oneline-innermode
  :mode 'typst--code-mode
  ;; NOTE: here one line code mode must start with "#" in the line beginning to prevent occurrence in multi-line code block (for instance `[ #hello ]`. In multi-line code block, thanks to indentation, there must be blank before "#")
  ;; only the line begins with #keywords will enter code mode, which means patterns like #module.key won't make sense. That's because #module.key often follows with markup texts. And it is assumed that it is a good style to make keywords occupy one or more whole lines
  :head-matcher `(,(eval `(rx bol (group-n 1 "#") (or ,@typst--base-keywords) (or (seq (*? not-newline) (or "}" ")" "]") (*? (not (or "(" "{" "[" "]" "}" ")")))) (*? (not (or "(" "{" "[" "]" "}" ")")))) (* blank) eol)) . 1)
  :tail-matcher (rx eol)
  :head-mode 'host
  :tail-mode 'host)

;; Parentheses
;; NOTE: user shouldn't escapes a "{" "(" in the end of the line which begins with "#"
(define-innermode typst--poly-code-block-curly-brackets-innermode
  ;; code mode inside multi-line "{ }" block
  :mode 'typst--code-mode
  :head-matcher `(,(eval `(rx bol (group-n 1 "#") (*? (not "\n")) "{" (*? (not (or "{" "(" "[" "}"))) eol)) . 1)
  :tail-matcher `(,(rx (* blank) (group-n 1 "}" ) (* blank) eol) . 1)
  :head-mode 'host
  :tail-mode 'host)

(define-innermode typst--poly-code-block-parentheses-innermode
  ;; code mode inside multi-line "( )" block
  :mode 'typst--code-mode
  :head-matcher `(,(eval `(rx bol (group-n 1 "#") (*? (not "\n" )) "(" (*? (not (or "{" "(" "[" ")"))) eol)) . 1)
  :tail-matcher `(,(rx (* blank) (group-n 1 ")") (* blank) eol) . 1)
  :head-mode 'host
  :tail-mode 'host)


;; (defun typst--find-unmarked-dollar (type &optional backward)
;;   "Search for the next unmarked `$` character.
;; Where the `math-head` and `math-end` text properties are not set.
;; If BACKWARD is non-nil, search backward instead of forward.
;; Argument TYPE "
;;   (let ((search-fn (if backward 're-search-backward 're-search-forward))
;;          (opposite-search-fn (if backward 're-search-forward 're-search-backward))
;;          (search-pattern "\\$")
;;          (next-type-same-p t)
;;          (found nil))
;;     ;; only execute when (type=math-head) or (type=math-tail and backward=nil)
;;     (if (or (eq type 'math-head)
;;           (and (eq type 'math-tail) (eq backward nil)))
;;       (progn
;;         ;; first search backward to know the previous condition and set the count-need variable
;;         (save-excursion
;;           (funcall opposite-search-fn search-pattern nil t)
;;           (setq next-type-same-p
;;             ;; There shouldn't be a character that owns both of the math-head and math-tail property
;;             (let ((math-head (get-text-property (if backward (point) (1- (point) )) 'math-head))
;;                    (math-tail (get-text-property (if backward (point) (1- (point) )) 'math-tail)))
;;               (cond
;;                 ((eq type 'math-head)
;;                   ;; tail: same, head/nil: different
;;                   (if (or math-tail
;;                         (and (not backward) (not math-head) (not math-tail)))
;;                     t))
;;                 ((eq type 'math-tail)
;;                   (if math-head t))))))
;;         (while (and (not found)
;;                  (funcall search-fn search-pattern nil t))
;;           (let ((math-head (get-text-property (if backward (point) (1- (point) )) 'math-head))
;;                  (math-tail (get-text-property (if backward (point) (1- (point) )) 'math-tail)))
;;             (when (and (not math-head) (not math-tail))
;;               (cond
;;                 ((eq type 'math-head)
;;                   (cond
;;                     ((and (not math-head) (not math-tail))
;;                       (if next-type-same-p
;;                         (setq found t)))
;;                     (math-head
;;                       (setq next-type-same-p nil))
;;                     (math-tail
;;                       (setq next-type-same-p t))))
;;                 ((eq type 'math-tail)
;;                   (cond
;;                     ((and (not math-head) (not math-tail))
;;                       (if next-type-same-p
;;                         (setq found t)))
;;                     (math-head
;;                       (setq next-type-same-p t))
;;                     (math-tail
;;                       (setq next-type-same-p nil)))))))
;;           (setq next-type-same-p (not next-type-same-p)))
;;         (if found
;;           (if (> (point) 1)
;;             (progn
;;               (if backward
;;                 (put-text-property (point) (1+ (point)) type t)
;;                 (put-text-property (1- (point)) (point) type t))
;;               (1- (point) ))
;;             (progn
;;               (put-text-property 1 2 type t)
;;               1)))))))
;; ;; (typst--poly-math-find-head 1)
;; ;; (typst--poly-math-find-tail)
;; ;; $ $ $ $ $ $ $
;; ;; (typst--poly-math-find-head -1)

;; (defun typst--poly-math-find-head (ahead)
;;   "See `pm-fun-matcher'."
;;   (let ((backward (if (< ahead 0) t)))
;;     (let ((the_point (typst--find-unmarked-dollar 'math-head backward)))
;;       (if the_point
;;         (progn
;;           (put-text-property the_point (1+ the_point) 'math-head t)
;;           (cons the_point (1+ the_point)))))))

;; (defun typst--poly-math-find-tail (&rest _args)
;;   (message "call find tail")
;;   (let ((the_point (typst--find-unmarked-dollar 'math-tail)))
;;     (if the_point
;;       (progn
;;         (put-text-property the_point (1+ the_point) 'math-tail t)
;;         (cons the_point (1+ the_point))))))

;; (define-innermode typst--poly-math-innermode
;;   :mode 'typst--math-mode
;;   ;; :head-matcher (cons (rx bol (* (not "$")) (group-n 1 "$") (* not-newline)) 1)
;;   ;; :head-matcher "\\$"
;;   ;; :tail-matcher "\\$"
;;   :head-matcher #'typst--poly-math-find-head
;;   :tail-matcher #'typst--poly-math-find-tail
;;   :head-mode 'host
;;   :tail-mode 'host)

;; ;;;###autoload
(define-polymode typst-mode
  :hostmode 'typst--poly-hostmode
  :innermodes '(typst--poly-code-block-parentheses-innermode
                 typst--poly-code-block-curly-brackets-innermode
                 typst--poly-code-oneline-innermode
                 ;; typst--poly-math-innermode ;; FIXME
                 )
  :keymap typst-mode-map
  nil
  "Major mode for editing Typst files.

\\{typst-mode-map}"
  (setq-local comment-start "//")
  (setq-local comment-end "")
  ;; set compile-command
  (let ((file-name (file-name-nondirectory (buffer-file-name))))
    (setq-local compile-command
      (concat typst-executable-location
        " compile " file-name " " (concat (file-name-sans-extension file-name) ".pdf"))))
  (run-hooks 'typst-mode-hook))

;; TODO support treesit
;; (define-polymode typst-mode
;;   :hostmode 'poly-markup-hostmode
;;   :innermodes '())

;; ;;;###autoload
;; (define-derived-mode typst-ts-mode typst-base-mode "Typst"
;;   "Major mode for editing Typst files.

;; \\{typst-ts-mode-map}"
;;   ;; :syntax-table typst-syntax-table
;;   (when (treesit-ready-p 'typst)
;;     (treesit-parser-create 'typst)
;;     ;; (setq-local treesit-font-lock-settings typst--treesit-settings)
;;     (setq-local treesit-font-lock-feature-list
;;       '(( comment definition)
;;          ( keyword string type)
;;          ( assignment builtin constant decorator
;;            escape-sequence number property string-interpolation )
;;          ( bracket delimiter function operator variable)))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.typ\\'" . typst-mode))

(provide 'typst-mode)
;;; typst-mode.el ends here
