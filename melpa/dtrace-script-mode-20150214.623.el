;;; dtrace-script-mode.el --- DTrace code editing commands for Emacs

;;; Commentary:

;; dtrace-script-mode: Mode for editing DTrace D language.
;;
;; You can add the following to your .emacs:
;;
;; (autoload 'dtrace-script-mode "dtrace-script-mode" () t)
;; (add-to-list 'auto-mode-alist '("\\.d\\'" . dtrace-script-mode))
;;
;; When loaded, runs all hooks from dtrace-script-mode-hook
;; You may try
;;
;; (add-hook 'dtrace-script-mode-hook 'imenu-add-menubar-index)
;; (add-hook 'dtrace-script-mode-hook 'font-lock-mode)
;;
;; Alexander Kolbasov <akolb at sun dot com>
;;

;;
;; The dtrace-script-mode inherits from C-mode.
;; It supports imenu and syntax highlighting.
;;

;; $Id: dtrace-script-mode.el,v 1.4 2007/07/17 22:10:23 akolb Exp $

;;; This file is NOT part of GNU Emacs
;;
;; Copyright (c) 2007, Alexander Kolbasov
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above
;;    copyright notice, this list of conditions and the following
;;    disclaimer in the documentation and/or other materials provided
;;    with the distribution.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
;; FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
;; COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
;; INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
;; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
;; STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
;; OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Code:

(require 'cc-mode)

(defvar dtrace-script-mode-map nil "Keymap used in D mode buffers.")

;;
;; Define dtrace-script-mode map unless it was defined already
;;
;; We just use c-mode-map with a few tweaks:
;;
;; M-C-a is bound to dtrace-script-mode-beginning-of-function
;; M-C-e is bound to dtrace-script-mode-end-of-function
;; M-C-h is bound to dtrace-script-mode-mark-function
;;
;; Ideally I would like to just replace whatever keybindings exist in c-mode-map
;; for the above with the new bindings. But up until recently, C-M-a was bound
;; to beginning-of-defun and not to c-beginning-of-defun and the same goes for
;; C-M-e, so we just define the new bindings.
;;
(unless dtrace-script-mode-map
  (setq dtrace-script-mode-map
	(let ((map (c-make-inherited-keymap)))
	  (define-key map "\e\C-a" 'dtrace-script-mode-beginning-of-function)
	  (define-key map "\e\C-e" 'dtrace-script-mode-end-of-function)
	  ;; Separate M-BS from C-M-h.  The former should remain
	  ;; backward-kill-word.
	  (define-key map [(control meta h)] 'dtrace-script-mode-mark-function)
	  map)))

(defvar dtrace-script-mode-syntax-table
  (let ((st (make-syntax-table (standard-syntax-table))))
    (modify-syntax-entry ?/ "$" st)
    (modify-syntax-entry ?` "." st)
    (modify-syntax-entry ?: "." st)
    (modify-syntax-entry ?_ "w" st)
    (modify-syntax-entry ?$ "/" st)
    (modify-syntax-entry ?& "." st)
    (modify-syntax-entry ?* "." st)
    (modify-syntax-entry ?+ "." st)
    (modify-syntax-entry ?- "." st)
    (modify-syntax-entry ?< "." st)
    (modify-syntax-entry ?= "." st)
    (modify-syntax-entry ?> "." st)
    (modify-syntax-entry ?\\ "\\" st)
    (modify-syntax-entry ?/  ". 14" st)
    (modify-syntax-entry ?*  ". 23"   st)
    st)
  "Syntax table in use in `dtrace-script-mode' buffers.")

;;
;; Show probes, pragmas and inlines in imenu
;;
(defvar dtrace-script-mode-imenu-generic-expression
  '(
    (nil "^\\s-*\\(\\sw+:.+\\)" 1 )
    (nil "\\s-*\\(BEGIN\\|END\\)" 1 )
    ("Pramgas" "^#pragma\\s-+D\\s-+\\(.+\\)" 1)
    ("Inlines" "\\s-*inline\\s-+\\(.*\\);" 1)
    )
  "Imenu generic expression for D mode.  See `imenu-generic-expression'.")

(defvar dtrace-script-mode-hook nil
  "Hooks to run when entering D mode.")

;;
;; Definition of various DTrace keywords for font-lock-mode
;;
(defconst dtrace-script-mode-font-lock-keywords
  (eval-when-compile
    (list
     ;;
     ;; Function names.
     ;'("^\\(\\sw+\\):\\(\\sw+\\|:\\)?"
     ;   (1 font-lock-keyword-face) (2 font-lock-function-name-face nil t))
     ;;
     ;; Variable names.
     (cons (regexp-opt
	    '(
	      "egid" "euid" "gid" "pid" "pgid" "ppid" "projid" "sid"
	      "taskid" "uid") 'words)
	   'font-lock-variable-name-face)

     ;;
     ;; DTrace built-in variables
     ;;
     (cons (regexp-opt
	    '(
	      "NULL"
	      "arg0" "arg1" "arg2" "arg3" "arg4" "arg5" "arg6" "arg7"
	      "arg8" "arg9"
	      "args"
	      "caller"
	      "chip"
	      "cpu"
	      "curcpu"
	      "curlwpsinfo"
	      "curpsinfo"
	      "curthread"
	      "cwd"
	      "epid"
	      "errno"
	      "execname"
	      "gid"
	      "id"
	      "ipl"
	      "lgrp"
	      "pid"
	      "ppid"
	      "probefunc"
	      "probemod"
	      "probename"
	      "probeprov"
	      "pset"
	      "pwd"
	      "root"
	      "self"
	      "stackdepth"
	      "target"
	      "this"
	      "tid"
	      "timestamp"
	      "uid"
	      "uregs"
	      "vtimestamp"
	      "walltimestamp"
	      ) 'words)
	   'font-lock-constant-face)
     ;;
     ;; DTrace functions.
     ;;
     (list (regexp-opt
	    '(
	      "alloca"
	      "avg"
	      "basename"
	      "bcopy"
	      "cleanpath"
	      "commit"
	      "copyin"
	      "copyinstr"
	      "copyinto"
	      "copyout"
	      "copyoutstr"
	      "count"
	      "dirname"
	      "discard"
	      "exit"
	      "jstack"
	      "lquantize"
	      "max"
	      "min"
	      "msgdsize"
	      "msgsize"
	      "mutex_owned"
	      "mutex_owner"
	      "mutex_type_adaptive"
	      "mutex_type_spin"
	      "offsetof"
	      "printa"
	      "printf"
	      "progenyof"
	      "quantize"
	      "raise"
	      "rand"
	      "rand"
	      "rw_iswriter"
	      "rw_read_held"
	      "rw_write_held"
	      "speculate"
	      "speculation"
	      "stack"
	      "stop"
	      "stringof"
	      "strjoin"
	      "strlen"
	      "sum"
	      "system"
	      "trace"
	      "tracemem"
	      "trunc"
	      "ustack"
	      ) 'words)
	   1 'font-lock-builtin-face)
     ;;
     ;; Destructive actions
     ;;
     (list (regexp-opt
	    '(
	      "breakpoint"
	      "chill"
	      "panic"
	      ) 'words)
	   1 'font-lock-warning-face)
     ;;
     ;; DTrace providers
     ;;
     (regexp-opt
      '(
	"BEGIN"
	"END"
	"dtrace"
	"dtrace"
	"entry"
	"fasttrap"
	"fbt"
	"fpuinfo"
	"io"
	"lockstat"
	"mib"
	"pid"
	"plockstat"
	"proc"
	"profile"
	"return"
	"sched"
	"sdt"
	"syscall"
	"sysinfo"
	"tick"
	"vm"
	"vminfo"
	"vtrace"
	) 'words)))
  "Default expressions to highlight in D mode.")

(defun dtrace-script-mode-beginning-of-function (&optional arg)
  "Move backward to next beginning-of-function, or as far as possible.
With argument, repeat that many times; negative args move forward.
Returns new value of point in all cases."
  (interactive "p")
  (or arg (setq arg 1))
  (if (< arg 0) (forward-char 1))
  (end-of-line)
  (and (/= arg 0)
       (re-search-backward "^[ \t]*\\([a-z_]+:.*\\|BEGIN\\|END\\)$"
			   nil 'move arg)
       (goto-char (1- (match-end 0))))
  (beginning-of-line))

(defun dtrace-script-mode-end-of-current-function ()
  "Locate the end of current D function"
  (dtrace-script-mode-beginning-of-function 1)
  ;; Now locate opening curly brace
  (search-forward "{")
  (backward-char 1)
  ;; Find closing curly brace
  (forward-list 1))

;; note: this routine is adapted directly from emacs perl-mode.el.
;; no bugs have been removed :-)
(defun dtrace-script-mode-end-of-function (&optional arg)
  "Move forward to next end-of-function.
The end of a function is found by moving forward from the beginning of one.
With argument, repeat that many times; negative args move backward."
  (interactive "p")
  (or arg (setq arg 1))
  (let ((first t))
    (while (and (> arg 0) (< (point) (point-max)))
      (let ((pos (point)) npos)
	(while (progn
		(if (and first
			 (progn
			  (forward-char 1)
			  (dtrace-script-mode-beginning-of-function 1)
			  (not (bobp))))
		    nil
		  (or (bobp) (forward-char -1))
		  (dtrace-script-mode-beginning-of-function -1))
		(setq first nil)
		(dtrace-script-mode-end-of-current-function)
		(skip-chars-forward " \t")
		(if (looking-at "[#\n]")
		    (forward-line 1))
		(<= (point) pos))))
      (setq arg (1- arg)))
    (while (< arg 0)
      (let ((pos (point)))
	(dtrace-script-mode-end-of-function)
	(forward-line 1)
	(if (>= (point) pos)
	    (if (progn (dtrace-script-mode-beginning-of-function 2) (not (bobp)))
		(progn
		  (forward-list 1)
		  (skip-chars-forward " \t")
		  (if (looking-at "[#\n]")
		      (forward-line 1)))
	      (goto-char (point-min)))))
      (setq arg (1+ arg)))))


(defun dtrace-script-mode-mark-function ()
  "Put mark at end of D function, point at beginning."
  (interactive)
  (push-mark (point))
  (dtrace-script-mode-end-of-function)
  (push-mark (point))
  (dtrace-script-mode-beginning-of-function))


;;;###autoload
(define-derived-mode dtrace-script-mode c-mode "DTrace"
  "Major mode for editing DTrace code.
This is much like C mode.  Its keymap inherits from C mode's and it has the same
variables for customizing indentation.  It has its own abbrev table and its own
syntax table.
\\{dtrace-script-mode-map}

Turning on DTrace mode runs `dtrace-script-mode-hook'."
  (setq imenu-generic-expression dtrace-script-mode-imenu-generic-expression)
  (setq font-lock-defaults '(dtrace-script-mode-font-lock-keywords nil nil ((?_ . "w")))))

(provide 'dtrace-script-mode)

;;; dtrace-script-mode.el ends here
