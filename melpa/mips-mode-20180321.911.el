;;; mips-mode.el --- Major-mode for MIPS assembly
;;
;; Copyright (C) 2016-2018 Henrik Lissner
;;
;; Author: Henrik Lissner <http://github/hlissner>
;; Maintainer: Henrik Lissner <henrik@lissner.net>
;; Created: September 8, 2016
;; Modified: March 21, 2018
;; Version: 1.1.1
;; Package-Version: 20180321.911
;; Package-Commit: e6c25201a3325b555e64388908d584f3f81d9e32
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

(defcustom mips-tab-width tab-width
  "Width of a tab for `mips-mode'."
  :tag "Tab width"
  :group 'mips
  :type 'integer)

(defcustom mips-interpreter "spim"
  "Path to the mips interpreter executable for running mips code with."
  :tag "MIPS Interpreter"
  :group 'mips
  :type 'string)

(defvar mips-keywords
  '(;; Arithmetic insturctions
    "add"
    "sub"
    "addi"
    "addu"
    "subu"
    "addiu"
    ;; Multiplication/division
    "mult"
    "div"
    "rem"
    "multu"
    "divu"
    "mfhi"
    "mflo"
    "mul"
    "mulu"
    "mulo"
    "mulou"
    ;; Bitwise operations
    "not"
    "and"
    "or"
    "nor"
    "xor"
    "andi"
    "ori"
    "xori"
    ;; Shifts
    "sll"
    "srl"
    "sra"
    "sllv"
    "srlv"
    "srav"
    ;; Comparisons
    "seq"
    "sne"
    "sgt"
    "sgtu"
    "sge"
    "sgeu"
    "slt"
    "sltu"
    "slti"
    "sltiu"
    ;; Jump/branch
    "j"
    "jal"
    "jr"
    "jalr"
    "beq"
    "bne"
    "syscall"
    ;; Load/store
    "lui"
    "lb"
    "lbu"
    "lh"
    "lhu"
    "lw"
    "lwl"
    "lwr"
    "sb"
    "sh"
    "sw"
    "swl"
    "swr"
    ;; Concurrent load/store
    "ll"
    "sc"
    ;; Trap handling
    "break"
    "teq"
    "teqi"
    "tge"
    "tgei"
    "tgeu"
    "tgeiu"
    "tlt"
    "tlti"
    "tltu"
    "tltiu"
    "tne"
    "tnei"
    "rfe"
    ;; Pseudoinstructions
    "b"
    "bal"
    "bge"
    "bgt"
    "ble"
    "blt"
    "bgeu"
    "bleu"
    "bltu"
    "bgtu"
    "bgez"
    "blez"
    "bgtz"
    "bltz"
    "bnez"
    "beqz"
    "bltzal"
    "bgezal"
    "bgtu"
    "la"
    "li"
    "move"
    "movz"
    "movn"
    "nop"
    "clear"
    ;; Deprecated branch-hint pseudoinstructions
    "beql"
    "bnel"
    "bgtzl"
    "bgezl"
    "bltzl"
    "blezl"
    "bltzall"
    "bgezall"
    ;; Floating point instuctions
    ;; Arithmetic
    "add.s"
    "add.d"
    "sub.s"
    "sub.d"
    "mul.s"
    "mul.d"
    "div.s"
    "div.d"
    ;; Comparison
    "c.lt.s"
    "c.lt.d"
    "c.gt.s"
    "c.gt.d"
    "madd.s"
    "madd.d"
    "msub.s"
    "msub.d"
    "movt.s"
    "movt.d"
    "movn.s"
    "movn.d"
    "movz.s"
    "movz.d"
    "trunc.w.d"
    "trunc.w.s"
    ;; Conversion
    "cvt.s.d"
    "cvt.d.s"
    ;; Math
    "abs.s"
    "abs.d"
    "sqrt.s"
    "sqrt.d"
    ;; Load-store
    "l.s"
    "l.d"
    "s.s"
    "s.d"))

(defvar mips-defs
  '(".align"
    ".ascii"
    ".asciiz"
    ".byte"
    ".data"
    ".double"
    ".extern"
    ".float"
    ".globl"
    ".half"
    ".kdata"
    ".ktext"
    ".space"
    ".text"
    ".word"))

(defvar mips-re-label "^[ \t]*[a-zA-Z_0-9]*:")

(defvar mips-re-directive "^[ \\t]?+\\.")

(defvar mips-re-comment "^[ \\t]?+#")

(defvar mips-font-lock-defaults
  `((;; numbers
     ("\\_<-?[0-9]+\\>" . font-lock-constant-face)
     ;; stuff enclosed in "
     ("\"\\.\\*\\?" . font-lock-string-face)
     ;; labels
     ("[a-zA-Z_0-9]*:" . font-lock-function-name-face)
     (,(regexp-opt mips-keywords 'words) . font-lock-keyword-face)
     ;; coprocessor load-store instructions
     ("[sl]wc[1-9]" . font-lock-keyword-face)
     (,(regexp-opt mips-defs) . font-lock-preprocessor-face)
     ;; registers
     ("$\\(f?[0-2][0-9]\\|f?3[01]\\|[ft]?[0-9]\\|[vk][01]\\|a[0-3]\\|s[0-7]\\|[gsf]p\\|ra\\|at\\|zero\\)" . font-lock-type-face)
     ;; ("$\\([a-z0-9]\\{2\\}\\|zero\\)" . font-lock-constant-face)
     ;; special characters
     (":\\|,\\|;\\|{\\|}\\|=>\\|@\\|\\$\\|=" . font-lock-builtin-face))))

;;
(defun mips--interpreter-buffer-name ()
  "Return a buffer name for the preferred mips interpreter"
  (format "*%s*" mips-interpreter))

(defun mips--interpreter-file-arg ()
  "Return the appropriate argument to accept a file for the current mips interpreter"
  (cond ((equal mips-interpreter "spim") "-file")))

(defun mips--last-label-line ()
  "Returns the line of the last label"
  (save-excursion
    (previous-line)
    (end-of-line)
    (re-search-backward mips-re-label)
    (line-number-at-pos)))

(defun mips-indent ()
  "Indent the current line(s)."
  (interactive)
  ;; ensure line when end or empty
  (when (or (eobp) (and (bobp) (eobp)))
    (open-line 1))
  (let ((line (thing-at-point 'line t)))
    (cond ((string-match-p mips-re-comment line)
           (mips-indent-label))
          ((string-match-p mips-re-directive line)
           (mips-indent-directive)
           (when (bolp) (back-to-indentation)))
          ((string-match-p mips-re-label line)
           (mips-indent-label))
          ;; assume that everything else is an instruction
          ((mips-mark-before-indent-column-p)
           (mips-indent-instruction)
           (back-to-indentation))
          (t (save-mark-and-excursion
              (mips-indent-instruction))))))

(defun mips-dedent ()
  "Un-indent the current line."
  (interactive)
  (indent-line-to 0))

(defun mips-indent-instruction ()
  (indent-line-to mips-tab-width))

(defun mips-indent-directive ()
  (when (mips-mark-before-indent-column-p)
    (back-to-indentation))
  (save-mark-and-excursion
   (indent-line-to mips-tab-width)))

(defun mips-indent-label ()
  (save-mark-and-excursion
   (mips-dedent)
   (mips-align-label-line)))

(defun mips-align-label-line ()
  (let ((line-length (length (thing-at-point 'line t))))
    (when (mips-line-label-only-p)
      (if (<= line-length mips-tab-width)
        (move-to-column mips-tab-width t)
        (end-of-line)))))

(defun mips-line-label-only-p ()
  (string-match-p "^[ \t]*[a-zA-Z_0-9]*:[ \t]?*$" (thing-at-point 'line t)))

(defun mips-mark-before-indent-column-p ()
  (string-match-p "^[ \\t]*$" (subseq (thing-at-point 'line t) 0 (current-column))))

(defun mips-run-buffer ()
  "Run the current buffer in a mips interpreter, and display the output in another window"
  (interactive)
  (let ((tmp-file (format "/tmp/mips-%s" (file-name-base))))
    (write-region (point-min) (point-max) tmp-file nil nil nil nil)
    (mips-run-file tmp-file)
    (delete-file tmp-file)))

(defun mips-run-region ()
  "Run the current region in a mips interpreter, and display the output in another window"
  (interactive)
  (let ((tmp-file (format "/tmp/mips-%s" (file-name-base))))
    (write-region (region-beginning) (region-end) tmp-file nil nil nil nil)
    (mips-run-file tmp-file)
    (delete-file tmp-file)))

(defun mips-run-file (&optional filename)
  "Run the file in a mips interpreter, and display the output in another window.
The interpreter will open filename. If filename is nil, it will open the current
buffer's file"
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

(defvar mips-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<backtab>") #'mips-dedent)
    (define-key map (kbd "C-c C-c")   #'mips-run-buffer)
    (define-key map (kbd "C-c C-r")   #'mips-run-region)
    (define-key map (kbd "C-c C-l")   #'mips-goto-label-at-cursor)
    map)
  "Keymap for `mips-mode'.")

;;;###autoload
(define-derived-mode mips-mode prog-mode "MIPS Assembly"
  "Major mode for editing MIPS assembler code."
  (setq font-lock-defaults mips-font-lock-defaults
        comment-start "#"
        comment-end ""
        indent-line-function 'mips-indent)
  (when mips-tab-width
    (setq tab-width mips-tab-width))
  (modify-syntax-entry ?#  "< b" mips-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" mips-mode-syntax-table))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.mips\\'" . mips-mode))

(provide 'mips-mode)
;;; mips-mode.el ends here
