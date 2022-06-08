;;; mips-mode.el --- Major-mode for MIPS assembly -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2016-2022 Henrik Lissner
;;
;; Author: Henrik Lissner <http://github/hlissner>
;; Maintainer: Henrik Lissner <contact@henrik.io>
;; Created: September 8, 2016
;; Modified: June 8, 2022
;; Version: 1.2.0
;; Package-Version: 20220608.1204
;; Package-Commit: 98795cdc81979821ac35d9f94ce354cd99780c67
;; Keywords: languages mips assembly
;; Homepage: https://github.com/hlissner/emacs-mips-mode
;; Package-Requires: ((emacs "25.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; A major mode for MIPS Assembly, loosely based off haxor-mode. Written for the
;; MIPS Assembly track on exercism.io. A MIPS interpreter such as spim must be
;; installed for the code evaluation features.
;;
;;; Code:

(defgroup mips nil
  "Major mode for editing MIPS assembly."
  :prefix "mips-"
  :group 'languages
  :link '(url-link :tag "Github" "https://github.com/hlissner/emacs-mips-mode")
  :link '(emacs-commentary-link :tag "Commentary" "ng2-mode"))


;;
;;; Settings

(defcustom mips-interpreter "spim"
  "Path to the mips interpreter executable."
  :tag "MIPS Interpreter"
  :group 'mips
  :type 'string)

(defcustom mips-tab-width tab-width
  "Width of a tab for `mips-mode'."
  :tag "Tab width"
  :group 'mips
  :type 'integer)

(defcustom mips-baseline-column 0
  "Label definitions are aligned to this column."
  :tag "Indentation baseline."
  :group 'mips
  :type 'integer)

(defcustom mips-operator-column tab-width
  "Operators and directives are indented to this column."
  :tag "Operator column."
  :group 'mips
  :type 'integer)

(defcustom mips-operands-column tab-width
  "Indent operands (like registers and label references) to this column."
  :tag "Operands column."
  :group 'mips
  :initialize (lambda (s _v) (set-default s (+ 4 (* 2 mips-operator-column))))
  :type 'integer)

(defcustom mips-comments-column 30
  "Comments are indented to this column."
  :tag "Comment column."
  :group 'mips
  :initialize (lambda (s _v) (set-default s (+ 20 mips-operands-column)))
  :type 'integer)

(defcustom mips-after-indent-hook #'mips-cycle-point
  "Function to call after indenting."
  :tag "Indent callback."
  :group 'mips
  :type 'symbol)

(defcustom mips-indent-character 32
  "Indent character."
  :tag "Indent character."
  :group 'mips
  :type '(choice (const :tag "Space" 32)
                 (const :tag "Tab (flaky, don't use!)" 11)))

(defcustom mips-auto-indent nil
  "If non-nil, columns are aligned automatically during typing."
  :tag "Indent automatically."
  :group 'mips
  :type 'boolean)


;;
;;; Helpers

(defun mips--interpreter-buffer-name ()
  "Return a buffer name for the preferred mips interpreter."
  (format "*%s*" mips-interpreter))

(defun mips--interpreter-file-args (file)
  "Return the appropriate arguments to accept a FILE argument.

Depends on the value of `mips-interpreter'."
  (delq
   nil (list (if (member (downcase (file-name-base mips-interpreter))
                         '("spim" "qtspim"))
                 "-file")
             file)))

(defun mips--last-label-line ()
  "Return the line of the last label."
  (save-excursion
    (forward-line -1)
    (end-of-line)
    (re-search-backward "^[a-zA-Z0-9_]*:")
    (line-number-at-pos)))

(defun mips-sanitize-buffer ()
  "Untabify and re-indent the buffer."
  ;; Tab-indenting is way too flaky for use, so until that's fixed,
  ;; this is a kinda-sorta cleanup thing (leading tab characters
  ;; trigger it), It's only called by `mips-mode', and can be removed
  ;; as soon as tabs work properly.
  (save-excursion
    (when (and (re-search-forward "^\t" nil t)
               (y-or-n-p "Sanitize (untabify/re-indent) buffer? "))
      (mips-indent-region (point-min) (point-max)))))

(defun mips-line ()
  "Return line at point as a string."
  (thing-at-point 'line t))

(defun mips-comment-line-p ()
  "Return non-nil if line at point is comment-only."
  (string-match-p mips-comment-line-re (mips-line)))


;;
;;; Execution commands

(defun mips-run-buffer ()
  "Run current buffer through `mips-interpreter' and display output in a popup."
  (interactive)
  (let ((tmp-file (make-temp-file "mips-" nil (format "-%d-%s" (emacs-pid) (file-name-base (buffer-file-name))))))
    (write-region (point-min) (point-max) tmp-file nil nil nil nil)
    (unwind-protect
        (mips-run-file tmp-file)
      (delete-file tmp-file))))

(defun mips-run-region (beg end)
  "Run selection through `mips-interpreter' and display output in popup.

BEG and END are buffer positions."
  (interactive "r")
  (let ((tmp-file (make-temp-file "mips-" nil (format "-%d-%s" (emacs-pid) (file-name-base (buffer-file-name))))))
    (write-region (region-beginning) (region-end) tmp-file nil nil nil nil)
    (unwind-protect
        (mips-run-file tmp-file)
      (delete-file tmp-file))))

(defun mips-run-file (&optional file)
  "Run FILE in a mips interpreter and display output in another window.

The interpreter will open FILE. If FILE is nil, it will open the current
buffer's file"
  (interactive (list (buffer-file-name)))
  (when (buffer-live-p (get-buffer (mips--interpreter-buffer-name)))
    (kill-buffer (mips--interpreter-buffer-name)))
  (apply #'start-process mips-interpreter
         (mips--interpreter-buffer-name)
         mips-interpreter (mips--interpreter-file-args file))
  (with-current-buffer (pop-to-buffer (mips--interpreter-buffer-name))
    (read-only-mode t)
    (help-mode)))


;;
;;; Navigation commands

(defun mips-goto-label (label)
  "Jump to the label entitled LABEL."
  (interactive "sGo to Label: ")
  (let ((orig-pt (point)))
    (goto-char (point-min))
    (unless (re-search-forward (format "[ \t]*%s:" label))
      (goto-char orig-pt))))

(defun mips-next-label ()
  "Jump to next label after point."
  (interactive)
  (let ((orig-pt (point)))
    (condition-case _
        (save-match-data
          (goto-char (point-at-eol))
          (re-search-forward "^[ \t]*[a-zA-Z0-9_.]+:")
          (goto-char (match-beginning 0)))
      (error
       (goto-char orig-pt)
       (user-error "No next label")))))

(defun mips-previous-label ()
  "Jump to previous label before point."
  (interactive)
  (let ((orig-pt (point)))
    (condition-case _
        (save-match-data
          (goto-char (point-at-bol))
          (re-search-backward "^[ \t]*[a-zA-Z0-9_]+:")
          (goto-char (match-beginning 0)))
      (error
       (goto-char orig-pt)
       (user-error "No previous label")))))

(defun mips-goto-label-at-cursor ()
  "Jump to the label that matches the symbol at point."
  (interactive)
  (mips-goto-label (symbol-at-point)))


;;
;;; Indentation

(defvar mips-line-re
  (concat
   "\\(?:[ \t]*\\)?\\([a-zA-Z0-9_]*:\\)?"      ;; label definition
   "\\(?:[ \t]*\\)?\\([\.a-zA-Z0-9_]*\\)?"     ;; opcode/operator
   "\\(?:[ \t]*\\)?\\(\".*\"\\|[^#\n^]+?\\)?"  ;; operands/registers
   "\\(?:[ \t]*\\)?\\(#[^\n]*\\)?$")           ;; comments
  "An (excessive) regexp to match MIPS assembly statements.")

(defvar mips-comment-line-re "^[ t]*#[^\n]*"
  "Regexp to match comment-only lines.")

(defvar mips-wp-char '(11 32)
  "A list of integers for whitespace.")

(defun mips-auto-indent ()
  "Automatically indent the current line, if necessary."
  (when (and mips-auto-indent
             (eq major-mode 'mips-mode)
             (and (stringp (mips-line))
                  (not (mips-comment-line-p))))
    (mips-align-all-columns)))

(defun mips--pad-rxg (column group)
  "Match a MIPS assembly statement using `mips-line-re'.

Will trim, pad, or backward-delete string segment in matching group GROUP until
COLUMN."
  (save-match-data
    (string-match mips-line-re (mips-line))
    (when (wholenump (match-beginning group))
      (move-to-column (match-beginning group))
      (let ((col (current-column)))
        (when (< col (match-end group))
          (while (/= col column)
            (if (< col column)
                (insert mips-indent-character)
              (if (member (preceding-char) mips-wp-char)
                  (delete-char -1)
                (message "Bumped into a wall at column %s!" col)
                (insert mips-indent-character) ;; pad one whitespace
                (move-to-column column t)      ;; and bail out forward.
                (while (memq (char-after) mips-wp-char)
                  (delete-char 1))))))))))

(defun mips-align-all-columns ()
  "Align each column of a MIPS statement line."
  (save-mark-and-excursion
   (mips--pad-rxg mips-baseline-column 1)
   (mips--pad-rxg mips-operator-column 2)
   (mips--pad-rxg mips-operands-column 3)
   (mips--pad-rxg mips-comments-column 4)))

(defun mips-indent-line (&optional suppress-hook)
  "Indent MIPS assembly line at point and run hook.

If SUPPRESS-HOOK, don't trigger `mips-after-indent-hook'."
  (interactive)
  (when (eobp) (open-line 1))
  (let ((line-before-indent (mips-line)))
    (if (mips-comment-line-p)
      (unless suppress-hook
        (mips-cycle-indent))
      (mips-align-all-columns)
      (unless suppress-hook
        (when (and mips-after-indent-hook (string= line-before-indent (mips-line)))
          (funcall mips-after-indent-hook))))))

(defun mips-indent-region (start end)
  "Indent MIPS statements between START and END."
  (interactive)
  (deactivate-mark)
  (let ((first-line (line-number-at-pos start))
        (last-line  (line-number-at-pos end)))
    (untabify (line-beginning-position first-line)
              (line-end-position last-line))
    (save-mark-and-excursion
      (goto-char start)
      (while (and (<= (line-number-at-pos (point)) last-line)
                  (not (eobp)))
        (funcall indent-line-function t)
        (forward-line)))
    (delete-trailing-whitespace start end)))

(defun mips-dedent ()
  "Dedent line to the baseline."
  (interactive)
  (deactivate-mark)
  (indent-line-to mips-baseline-column))

(defun mips-newline ()
  "`newline' for MIPS assembly." ;; to handle comment lines
  (interactive)
  (cond ((mips-comment-line-p)
         (open-line 1)
         (forward-line))
        ((mips-indent-line t)
         (newline)
         (mips-indent-line)
         (back-to-indentation))))

(defun mips--cycle (func &rest args)
  "Cycle between indent markers on the current line."
  (cond ((or (bolp) (< (current-column) mips-operator-column))
         (apply func mips-operator-column args))
        ((< (current-column) mips-operands-column)
         (apply func mips-operands-column args))
        ((< (current-column) mips-comments-column)
         (apply func mips-comments-column args))
        ((apply func mips-baseline-column args))))

(defun mips-cycle-indent ()
  "Move indentation to the next \"significant\" column."
  (mips--cycle #'indent-line-to))

(defun mips-cycle-point ()
  "Move point to the next \"significant\" column."
  (mips--cycle #'move-to-column t))


;;
;;; Font-lock

(defvar mips-font-lock-keywords
  '( ;; Arithmetic insturctions
    "add" "sub" "subu" "addi" "subi" "addu" "addiu"
    ;; Multiplication/division
    "mul" "mult" "multu" "mulu" "madd" "maddu" "msub" "msubu" "div" "divu"
    ;; Bitwise operations
    "and" "or" "nor" "xor" "andi" "ori" "xori" "clo" "clz"
    ;; Shifts
    "sll" "srl" "sllv" "srlv" "sra" "srav"
    ;; Comparisons
    "slt" "sltu" "slti" "sltiu"
    ;; Move data
    "mfhi" "mthi" "mflo" "mtlo" "movn" "movz" "movf" "movt"
    ;; Jump
    "j" "jal" "jalr" "jr"
    ;; branch
    "bc1f" "bc1t" "beq" "bgez" "bgezal" "bgtz" "blez" "bltzal" "bltz" "bne"
    ;; Load
    "lui" "lb" "lbu" "lh" "lhu" "lw" "lwcl" "lwl" "lwr"
    ;; Store
    "sb" "sh" "sw" "swl" "swr" ; coproc: swc1 sdc1
    ;; Concurrent load/store
    "ll" "sc"
    ;; Trap handling
    "teq" "teqi" "tne" "tneqi" "tge" "tgeu" "tgei" "tgeiu" "tlt" "tltu" "tlti"
    "tltiu"
    ;; Exception / Interrupt
    "eret" "break" "bop" "syscall"
    ;;--- Floats -----------------------------------------------------
    ;; Arithmetic
    "add.s" "add.d" "sub.s" "sub.d" "mul.s" "mul.d" "div.s" "div.d" "neg.d"
    "neg.s"
    ;; Comparison
    "c.e.d" "c.e.s" "c.le.d" "c.le.s" "c.lt.s" "c.lt.d" ; "c.gt.s" "c.gt.d"
    "madd.s" "madd.d" "msub.s" "msub.d"
    ;; Move Floats
    "mov.d" "move.s" "movf.d" "movf.s" "movt.d" "movt.s" "movn.d" "movn.s"
    "movnzd" "movz.s" "movz.d"
    ;; Conversion
    "cvt.d.s" "cvt.d.w" "cvt.s.d" "cvt.s.w" "cvt.w.d" "cvt.w.s" "trunc.w.d"
    "trunc.w.s"
    ;; Math
    "abs.s" "abs.d" "sqrt.s" "sqrt.d" "ceil.w.d" "ceil.w.s" "floor.w.d"
    "floor.w.s" "round.w.d" "round.w.s"))

(defvar mips-font-lock-pseudoinstructions
  '(;; Arithmetic & logical
    "rem" "remu" "mulo" "mulou" "abs" "neg" "negu" "not" "rol" "ror"
    ;; branches
    "b" "beqz" "bge" "bgeu" "bgt" "bgtu" "ble" "bleu" "blt" "bltu" "bnez"
    ;; loads
    "la" "li" "ld" "ulh" "ulhu" "ulw"
    ;; Store
    "sd" "ush" "usw"
    ;; move
    "move" ; coproc: "mfc1.d"
    ;; comparisons
    "sgt" "sgtu" "sge" "sgeu" "sle" "sleu" "sne" "seq"
    ;;--- Floats -----------------------------------------------------
    ;; load-store
    "l.d" "l.s" "s.d" "s.s"))

(defvar mips-font-lock-deprecated
  '("beql" "bnel" "bgtzl" "bgezl" "bltzl" "blezl" "bltzall" "bgezall"))

(defvar mips-font-lock-directives
  '(".align" ".ascii" ".asciiz" ".byte" ".data" ".double" ".extern" ".float"
    ".globl" ".half" ".kdata" ".ktext" ".space" ".text" ".word"))

(defvar mips-font-lock-defaults
  `((;; numbers
     ("\\_<-?[0-9]+\\>" . font-lock-constant-face)
     ;; stuff enclosed in "
     ("\"\\.\\*\\?" . font-lock-string-face)
     ;; labels
     ("[a-zA-Z_0-9]*:" . font-lock-function-name-face)
     (,(regexp-opt mips-font-lock-keywords 'words) . font-lock-keyword-face)
     (,(regexp-opt mips-font-lock-pseudoinstructions 'words) . font-lock-variable-name-face)
     (,(regexp-opt mips-font-lock-deprecated 'words) . font-lock-warning-face)
     ;; coprocessor load-store / move from-to instructions
     ("[slm][ftwd]c[0-9]\\(?:[.]d\\)?" . font-lock-keyword-face)  ; "mfc0" "mfc1" "mtc0" "mtc1"
     (,(regexp-opt mips-font-lock-directives) . font-lock-preprocessor-face)
     ;; registers
     ("$\\(f?[0-2][0-9]\\|f?3[01]\\|[ft]?[0-9]\\|[vk][01]\\|a[0-3]\\|s[0-7]\\|[gsf]p\\|ra\\|at\\|zero\\)" . font-lock-type-face)
     ;; ("$\\([a-z0-9]\\{2\\}\\|zero\\)" . font-lock-constant-face)
     ;; special characters
     (":\\|,\\|;\\|{\\|}\\|=>\\|@\\|\\$\\|=" . font-lock-builtin-face))))


;;
;;; Major mode

(defvar mips-imenu-expression
  '(("Label"     "^\\s-*\\([a-zA-Z0-9_]+\\):" 1)
    ("Directive" "\\s-+[.]\\([a-z]+\\)"       1))
  "List of definition matchers for creating an Imenu index in `mips-mode'.

See `imenu-generic-expression' for details.")

(defvar mips-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap newline-and-indent] #'mips-newline)
    (define-key map (kbd "<backtab>") #'mips-dedent)
    (define-key map (kbd "C-c C-c")   #'mips-run-buffer)
    (define-key map (kbd "C-c C-r")   #'mips-run-region)
    (define-key map (kbd "C-c C-l")   #'mips-goto-label-at-cursor)
    (define-key map (kbd "M-n")       #'mips-next-label)
    (define-key map (kbd "M-p")       #'mips-previous-label)
    map)
  "Keymap for `mips-mode'.")

;;;###autoload
(define-derived-mode mips-mode prog-mode "MIPS Assembly"
  "Major mode for editing MIPS assembler code."
  (setq-local font-lock-defaults mips-font-lock-defaults)
  (setq-local comment-start "#")
  (setq-local comment-end "")
  (setq-local indent-line-function #'mips-indent-line)
  (setq-local indent-region-function #'mips-indent-region)
  (setq-local indent-tabs-mode nil)
  (when mips-tab-width
    (setq-local tab-width mips-tab-width))
  (mips-sanitize-buffer)
  (modify-syntax-entry ?#  "< b" mips-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" mips-mode-syntax-table)
  (setq imenu-generic-expression #'mips-imenu-expression)
  (add-hook 'post-command-hook #'mips-auto-indent nil t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.mips\\'" . mips-mode))

(provide 'mips-mode)
;;; mips-mode.el ends here
