;;; mips-mode.el --- Major-mode for MIPS assembly
;;
;; Copyright (C) 2016-2018 Henrik Lissner
;;
;; Author: Henrik Lissner <http://github/hlissner>
;; Maintainer: Henrik Lissner <henrik@lissner.net>
;; Created: September 8, 2016
;; Modified: May 2, 2018
;; Version: 1.1.2
;; Package-Version: 20180502.1457
;; Package-Commit: 75152fc78baa762af4f83602f6cb3c8b9bcebca3
;; Keywords: languages mips assembly
;; Homepage: https://github.com/hlissner/emacs-mips-mode
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
  "Operands such as registers and label references are indented
to this column."
  :tag "Operands column."
  :group 'mips
  :initialize (lambda (s v) (set-default s (+ 4 (* 2 mips-operator-column))))
  :type 'integer)

(defcustom mips-comments-column 30
  "Comments are indented to this column."
  :tag "Comment column."
  :group 'mips
  :initialize (lambda (s v) (set-default s (+ 20 mips-operands-column)))
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
  :set (lambda (s v)
         (set-default s v)
         (if v (add-hook 'post-command-hook #'mips-auto-indent)
             (remove-hook 'post-command--hook #'mips-auto-indent)))
  :type 'boolean)

(defun mips--interpreter-buffer-name ()
  "Return a buffer name for the preferred mips interpreter"
  (format "*%s*" mips-interpreter))

(defun mips--interpreter-file-arg ()
  "Return the appropriate argument to accept a file for the
current mips interpreter"
  (cond ((equal mips-interpreter "spim") "-file")))

(defun mips--last-label-line ()
  "Returns the line of the last label"
  (save-excursion
    (previous-line)
    (end-of-line)
    (re-search-backward "^[a-zA-Z0-9_]*:")
    (line-number-at-pos)))

(defun mips-run-buffer ()
  "Run the current buffer in a mips interpreter, and display the
output in another window"
  (interactive)
  (let ((tmp-file (format "/tmp/mips-%s" (file-name-base))))
    (write-region (point-min) (point-max) tmp-file nil nil nil nil)
    (mips-run-file tmp-file)
    (delete-file tmp-file)))

(defun mips-run-region ()
  "Run the current region in a mips interpreter, and display the
output in another window"
  (interactive)
  (let ((tmp-file (format "/tmp/mips-%s" (file-name-base))))
    (write-region (region-beginning) (region-end) tmp-file nil nil nil nil)
    (mips-run-file tmp-file)
    (delete-file tmp-file)))

(defun mips-run-file (&optional filename)
  "Run the file in a mips interpreter, and display the output in another window.
The interpreter will open filename. If filename is nil, it will
open the current buffer's file"
  (interactive)
  (let ((file (or filename (buffer-file-name))))
    (when (buffer-live-p (get-buffer (mips--interpreter-buffer-name)))
      (kill-buffer (mips--interpreter-buffer-name)))
    (start-process mips-interpreter
                   (mips--interpreter-buffer-name)
                   mips-interpreter (mips--interpreter-file-arg) file))
  (pop-to-buffer (mips--interpreter-buffer-name))
  (read-only-mode t)
  (help-mode))

(defun mips-goto-label (label)
  "Jump to the label entitled LABEL."
  (interactive "sGo to Label: ")
  (let ((orig-pt (point)))
    (beginning-of-buffer)
    (unless (re-search-forward (format "[ \t]*%s:" label))
      (goto-char orig-pt))))

(defun mips-goto-label-at-cursor ()
  "Jump to the label that matches the symbol at point."
  (interactive)
  (mips-goto-label (symbol-at-point)))

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

;;;;;;;;;;;;;;;;;
;; INDENTATION ;;
;;;;;;;;;;;;;;;;;
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

(defun mips-line ()
  "Return line at point as a string."
  (thing-at-point 'line t))

(defun mips-comment-line-p ()
  "Return true if line at point is comment-only."
  (string-match-p mips-comment-line-re (mips-line)))

(defun mips-pad-rxg (column group)
  "Match a MIPS assembly statement using `mips-line-re' and trim,
pad or backward-delete string segment in matching group GROUP
until COLUMN."
  (string-match mips-line-re (mips-line))
  (when (wholenump (match-beginning group))
    (move-to-column (match-beginning group))
    (when (< (current-column) (match-end group))
      (while (/= (current-column) column)
        (if (< (current-column) column)
          (insert mips-indent-character)
          (if (member (preceding-char) mips-wp-char)
            (delete-backward-char 1)
            (progn (message "Bumped into a wall at column %s!" (current-column))
                   (insert mips-indent-character) ;; pad one whitespace
                   (move-to-column column t)      ;; and bail out forward.
                   (while (member (char-after) mips-wp-char)
                     (delete-forward-char 1)))))))))

(defun mips-indent-line (&optional suppress-hook)
  "Indent MIPS assembly line at point and run hook."
  (interactive)
  (when (eobp) (open-line 1))
  (let ((line-before-indent (mips-line)))
    (if (mips-comment-line-p)
      (unless suppress-hook
        (mips-cycle-indent))
      (mips-align-all-columns)
      (unless suppress-hook
        (when (and mips-after-indent-hook (string-equal line-before-indent (mips-line)))
          (funcall mips-after-indent-hook))))))

(defun mips-align-all-columns ()
  "Align each column of a MIPS statement line."
  (save-mark-and-excursion
   (mips-pad-rxg mips-baseline-column 1)
   (mips-pad-rxg mips-operator-column 2)
   (mips-pad-rxg mips-operands-column 3)
   (mips-pad-rxg mips-comments-column 4)))

(defun mips-indent-region (start end)
  "Indent a region consisting of MIPS assembly statements."
  (interactive)
  (deactivate-mark)
  (let ((first-line (line-number-at-pos start))
        (last-line  (line-number-at-pos end)))
    (untabify (line-beginning-position first-line)
              (line-end-position last-line))
    (save-mark-and-excursion
     (goto-line first-line)
     (while (and (<= (line-number-at-pos (point)) last-line)
                 (not (eobp)))
       (funcall indent-line-function t)
       (forward-line)))
    (delete-trailing-whitespace start end)))

(defun mips-auto-indent ()
  (when (and mips-auto-indent
             (eq major-mode 'mips-mode)
             (and (stringp (mips-line))
                  (not (mips-comment-line-p))))
    (mips-align-all-columns)))

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
        (t (mips-indent-line t)
           (newline)
           (mips-indent-line)
           (back-to-indentation))))

(defun mips-cycle (func &rest args)
  (cond ((or (bolp) (< (current-column) mips-operator-column))
         (apply func mips-operator-column args))
        ((< (current-column) mips-operands-column)
         (apply func mips-operands-column args))
        ((< (current-column) mips-comments-column)
         (apply func mips-comments-column args))
        (t (apply func mips-baseline-column args))))

(defun mips-cycle-indent ()
  "Move indentation to the next \"significant\" column."
  (mips-cycle #'indent-line-to))

(defun mips-cycle-point ()
  "Move point to the next \"significant\" column."
  (mips-cycle #'move-to-column t))

;;;;;;;;;;;;;
;; FONTIFY ;;
;;;;;;;;;;;;;

(defvar mips-font-lock-keywords
  '( ;; Arithmetic insturctions
    "add" "sub" "addi" "subi" "addu" "addiu"
    ;; Multiplication/division
    "mult" "div" "rem" "multu" "divu" "mfhi" "mflo" "mul" "mulu" "mulo" "mulou"
    ;; Bitwise operations
    "not" "and" "or" "nor" "xor" "andi" "ori" "xori"
    ;; Shifts
    "sll" "srl" "sra" "sllv" "srlv" "srav"
    ;; Comparisons
    "seq" "sne" "sgt" "sgtu" "sge" "sgeu" "slt" "sltu" "slti" "sltiu"
    ;; Jump/branch
    "j" "jal" "jr" "jalr" "beq" "bne" "syscall"
    ;; Load/store
    "lui" "lb" "lbu" "lh" "lhu" "lw" "lwl" "lwr" "sb" "sh" "sw" "swl" "swr"
    ;; Concurrent load/store
    "ll" "sc"
    ;; Trap handling
    "break" "teq" "teqi" "tge" "tgei" "tgeu" "tgeiu" "tlt" "tlti" "tltu" "tltiu" "tne" "tnei" "rfe"
    ;; Pseudoinstructions
    "b" "bal" "bge" "bgt" "ble" "blt" "bgeu" "bleu" "bltu" "bgtu" "bgez" "blez" "bgtz"
    "bltz" "bnez" "beqz" "bltzal" "bgezal" "bgtu" "la" "li" "move" "movz" "movn" "nop" "clear"
    ;; Deprecated branch-hint pseudoinstructions
    "beql" "bnel" "bgtzl" "bgezl" "bltzl" "blezl" "bltzall" "bgezall"
    ;; Floating point instuctions
    ;; Arithmetic
    "add.s" "add.d" "sub.s" "sub.d" "mul.s" "mul.d" "div.s" "div.d"
    ;; Comparison
    "c.lt.s" "c.lt.d" "c.gt.s" "c.gt.d" "madd.s" "madd.d" "msub.s" "msub.d" "movt.s"
    "movt.d" "movn.s" "movn.d" "movz.s" "movz.d" "trunc.w.d" "trunc.w.s"
    ;; Conversion
    "cvt.s.d" "cvt.d.s"
    ;; Math
    "abs.s" "abs.d" "sqrt.s" "sqrt.d"
    ;; Load-store
    "l.s" "l.d" "s.s" "s.d"))

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
     ;; coprocessor load-store instructions
     ("[sl]wc[1-9]" . font-lock-keyword-face)
     (,(regexp-opt mips-font-lock-directives) . font-lock-preprocessor-face)
     ;; registers
     ("$\\(f?[0-2][0-9]\\|f?3[01]\\|[ft]?[0-9]\\|[vk][01]\\|a[0-3]\\|s[0-7]\\|[gsf]p\\|ra\\|at\\|zero\\)" . font-lock-type-face)
     ;; ("$\\([a-z0-9]\\{2\\}\\|zero\\)" . font-lock-constant-face)
     ;; special characters
     (":\\|,\\|;\\|{\\|}\\|=>\\|@\\|\\$\\|=" . font-lock-builtin-face))))

;;;;;;;;;;
;; MODE ;;
;;;;;;;;;;

(defvar mips-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap newline-and-indent] #'mips-newline)
    (define-key map (kbd "<backtab>") #'mips-dedent)
    (define-key map (kbd "C-c C-c")   #'mips-run-buffer)
    (define-key map (kbd "C-c C-r")   #'mips-run-region)
    (define-key map (kbd "C-c C-l")   #'mips-goto-label-at-cursor)
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
  (setq-local tab-width (or mips-tab-width tab-width))
  (mips-sanitize-buffer)
  (modify-syntax-entry ?#  "< b" mips-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" mips-mode-syntax-table))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.mips\\'" . mips-mode))

(provide 'mips-mode)
;;; mips-mode.el ends here
