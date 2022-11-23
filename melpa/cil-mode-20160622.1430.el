;;; cil-mode.el --- Common Intermediate Language mode

;; Copyright (C) 2015-2016 Friedrich von Never

;; Author: Friedrich von Never <friedrich@fornever.me>
;; URL: https://github.com/ForNeVeR/cil-mode
;; Version: 0.4
;; Keywords: languages

;;; Commentary:

;; cil-mode is a major emacs mode for editing of Common Intermediate
;; Language. It helps emacs to highlight CIL keywords and sets up the
;; proper indentation for such files.

;;; Code:

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.il\\'" . cil-mode))

(defconst cil-keywords (list
                    "abstract"
                    "ansi"
                    "as"
                    "assembly"
                    "at"
                    "auto"
                    "autochar"
                    "beforefieldinit"
                    "bool"
                    "bytearray"
                    "catch"
                    "cdecl"
                    "char"
                    "cil"
                    "class"
                    "const"
                    "default"
                    "enum"
                    "explicit"
                    "extends"
                    "false"
                    "famandassem"
                    "family"
                    "famorassem"
                    "fastcall"
                    "fastcall"
                    "fault"
                    "field"
                    "filter"
                    "final"
                    "finally"
                    "float"
                    "float32"
                    "float64"
                    "forwardref"
                    "handler"
                    "hidebysig"
                    "il"
                    "implements"
                    "import"
                    "initonly"
                    "instance"
                    "int"
                    "int16"
                    "int32"
                    "int64"
                    "int8"
                    "interface"
                    "internalcall"
                    "lasterr"
                    "literal"
                    "managed"
                    "method"
                    "modopt"
                    "modreq"
                    "native"
                    "nested"
                    "newslot"
                    "noinlining"
                    "nomangle"
                    "not_in_gc_heap"
                    "notremotable"
                    "notserialized"
                    "object"
                    "optil"
                    "pinned"
                    "pinvokeimpl"
                    "preservesig"
                    "private"
                    "privatescope"
                    "public"
                    "refany"
                    "reqsecobj"
                    "rtspecialname"
                    "runtime"
                    "sealed"
                    "sequential"
                    "serializable"
                    "special"
                    "specialname"
                    "static"
                    "stdcall"
                    "stdcall"
                    "strict"
                    "string"
                    "synchronized"
                    "thiscall"
                    "thiscall"
                    "tls"
                    "to"
                    "true"
                    "typedref"
                    "unicode"
                    "unmanaged"
                    "unmanagedexp"
                    "unsigned"
                    "value"
                    "valuetype"
                    "vararg"
                    "virtual"
                    "void"
                    "wchar"
                    "winapi"
                    "wrapper"))

(defconst cil-instructions (list
                            "add"
                            "add.ovf"
                            "add.ovf.un"
                            "and"
                            "arglist"
                            "beq"
                            "beq.s"
                            "bge"
                            "bge.s"
                            "bge.un"
                            "bge.un.s"
                            "bgt"
                            "bgt.s"
                            "bgt.un"
                            "bgt.un.s"
                            "ble"
                            "ble.s"
                            "ble.un"
                            "ble.un.s"
                            "blt"
                            "blt.s"
                            "blt.un"
                            "blt.un.s"
                            "bne.un"
                            "bne.un.s"
                            "box"
                            "br"
                            "br.s"
                            "break"
                            "brfalse"
                            "brfalse.s"
                            "brinst"
                            "brinst.s"
                            "brnull"
                            "brnull.s"
                            "brtrue"
                            "brtrue.s"
                            "brzero"
                            "brzero.s"
                            "call"
                            "calli"
                            "callvirt"
                            "castclass"
                            "ceq"
                            "cgt"
                            "cgt.un"
                            "ckfinite"
                            "clt"
                            "clt.un"
                            "conv.i"
                            "conv.i1"
                            "conv.i2"
                            "conv.i4"
                            "conv.i8"
                            "conv.ovf.i"
                            "conv.ovf.i.un"
                            "conv.ovf.i1"
                            "conv.ovf.i1.un"
                            "conv.ovf.i2"
                            "conv.ovf.i2.un"
                            "conv.ovf.i4"
                            "conv.ovf.i4.un"
                            "conv.ovf.i8"
                            "conv.ovf.i8.un"
                            "conv.ovf.u"
                            "conv.ovf.u.un"
                            "conv.ovf.u1"
                            "conv.ovf.u1.un"
                            "conv.ovf.u2"
                            "conv.ovf.u2.un"
                            "conv.ovf.u4"
                            "conv.ovf.u4.un"
                            "conv.ovf.u8"
                            "conv.ovf.u8.un"
                            "conv.r.un"
                            "conv.r4"
                            "conv.r8"
                            "conv.u"
                            "conv.u1"
                            "conv.u2"
                            "conv.u4"
                            "conv.u8"
                            "cpblk"
                            "cpobj"
                            "div"
                            "div.un"
                            "dup"
                            "endfault"
                            "endfilter"
                            "endfinally"
                            "endmac"
                            "illegal"
                            "initblk"
                            "initobj"
                            "isinst"
                            "jmp"
                            "ldarg"
                            "ldarg.0"
                            "ldarg.1"
                            "ldarg.2"
                            "ldarg.3"
                            "ldarg.s"
                            "ldarga"
                            "ldarga.s"
                            "ldc.i4"
                            "ldc.i4.0"
                            "ldc.i4.1"
                            "ldc.i4.2"
                            "ldc.i4.3"
                            "ldc.i4.4"
                            "ldc.i4.5"
                            "ldc.i4.6"
                            "ldc.i4.7"
                            "ldc.i4.8"
                            "ldc.i4.M1"
                            "ldc.i4.m1"
                            "ldc.i4.s"
                            "ldc.i8"
                            "ldc.r4"
                            "ldc.r8"
                            "ldelem.i"
                            "ldelem.i1"
                            "ldelem.i2"
                            "ldelem.i4"
                            "ldelem.i8"
                            "ldelem.r4"
                            "ldelem.r8"
                            "ldelem.ref"
                            "ldelem.u1"
                            "ldelem.u2"
                            "ldelem.u4"
                            "ldelem.u8"
                            "ldelema"
                            "ldfld"
                            "ldflda"
                            "ldftn"
                            "ldind.i"
                            "ldind.i1"
                            "ldind.i2"
                            "ldind.i4"
                            "ldind.i8"
                            "ldind.r4"
                            "ldind.r8"
                            "ldind.ref"
                            "ldind.u1"
                            "ldind.u2"
                            "ldind.u4"
                            "ldind.u8"
                            "ldlen"
                            "ldloc"
                            "ldloc.0"
                            "ldloc.1"
                            "ldloc.2"
                            "ldloc.3"
                            "ldloc.s"
                            "ldloca"
                            "ldloca.s"
                            "ldnull"
                            "ldobj"
                            "ldsfld"
                            "ldsflda"
                            "ldstr"
                            "ldtoken"
                            "ldvirtftn"
                            "leave"
                            "leave.s"
                            "localloc"
                            "mkrefany"
                            "mul"
                            "mul.ovf"
                            "mul.ovf.un"
                            "neg"
                            "newarr"
                            "newobj"
                            "nop"
                            "not"
                            "or"
                            "pop"
                            "prefix1"
                            "prefix2"
                            "prefix3"
                            "prefix4"
                            "prefix5"
                            "prefix6"
                            "prefix7"
                            "prefixref"
                            "refanytype"
                            "refanyval"
                            "rem"
                            "rem.un"
                            "ret"
                            "rethrow"
                            "shl"
                            "shr"
                            "shr.un"
                            "sizeof"
                            "starg"
                            "starg.s"
                            "stelem.i"
                            "stelem.i1"
                            "stelem.i2"
                            "stelem.i4"
                            "stelem.i8"
                            "stelem.r4"
                            "stelem.r8"
                            "stelem.ref"
                            "stfld"
                            "stind.i"
                            "stind.i1"
                            "stind.i2"
                            "stind.i4"
                            "stind.i8"
                            "stind.r4"
                            "stind.r8"
                            "stind.ref"
                            "stloc"
                            "stloc.0"
                            "stloc.1"
                            "stloc.2"
                            "stloc.3"
                            "stloc.s"
                            "stobj"
                            "stsfld"
                            "sub"
                            "sub.ovf"
                            "sub.ovf.un"
                            "switch"
                            "tail."
                            "throw"
                            "unaligned."
                            "unbox"
                            "volatile."
                            "xor"))

(defconst cil-font-lock-keywords-1
  (let ((label-face font-lock-preprocessor-face)
        (metadata-face font-lock-builtin-face)
        (keyword-face font-lock-keyword-face)
        (instruction-face font-lock-function-name-face)
        (preprocessor-face font-lock-preprocessor-face)

        (keyword-regexp (concat "\\_<" (regexp-opt cil-keywords) "\\_>"))
        (instruction-regexp (concat "\\_<" (regexp-opt cil-instructions) "\\_>")))
    (list
     (list "^\\s-*#.*" 0 preprocessor-face t)
     (cons instruction-regexp instruction-face)
     (cons "^\\s-*\\<\\(\\w\\|\\s_\\)+:" label-face)
     (cons "^\\s-*\\.\\w+\\>" metadata-face)
     (cons keyword-regexp keyword-face))))

(defvar cil-font-lock-keywords nil
  "Default highlighing expressions for CIL mode")
(setq cil-font-lock-keywords cil-font-lock-keywords-1)

(defvar cil-mode-indentation-size 4
  "Base indentation size for CIL mode.")

(defun cil-mode--is-label ()
  (char-equal ?: (char-before (line-end-position))))

(defun cil-mode--is-closing-brace ()
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward "[:blank:]")
    (let* ((current-point (point))
           (char-after-point (char-after current-point)))
      (when char-after-point
        (char-equal ?} char-after-point)))))

(defun cil-indent-line ()
  "Indent current line as CIL code"
  (interactive)
  (beginning-of-line)
  (cond ((bobp)
         (indent-line-to 0))
        ((or (cil-mode--is-label)
             (cil-mode--is-closing-brace))
         (indent-line-to (- (* cil-mode-indentation-size (car (syntax-ppss))) cil-mode-indentation-size)))
        (t
         (indent-line-to (* cil-mode-indentation-size (car (syntax-ppss)))))))

(defvar cil-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" st)
    (modify-syntax-entry ?* ". 23" st)
    (modify-syntax-entry ?\n "> b" st)
    st)
  "Syntax table for cil-mode")

(defalias 'cil-parent-mode
  (if (fboundp 'prog-mode) 'prog-mode 'fundamental-mode))

;;;###autoload
(define-derived-mode cil-mode cil-parent-mode "CIL"
  "Major mode for editing Common Intermediate Language files"
  (setq font-lock-defaults '(cil-font-lock-keywords))
  (set (make-local-variable 'indent-line-function) 'cil-indent-line)
  ;; Comments
  (make-local-variable 'comment-start)
  (setq comment-start "// ")
  (make-local-variable 'comment-end)
  (setq comment-end "")
  (make-local-variable 'comment-start-skip)
  (setq comment-start-skip "//[ \t]*")
  (make-local-variable 'comment-column)
  (setq comment-column 0))


(provide 'cil-mode)

;;; cil-mode.el ends here.
