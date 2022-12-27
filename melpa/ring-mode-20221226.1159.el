;;; ring-mode.el --- A major mode for the Ring programming language -*- lexical-binding: t -*-

;; Version: 0.0.1
;; Package-Version: 20221226.1159
;; Package-Commit: 4e38dd5ca374d7d40fd1eeed1e83ef935efd387a
;; Author: XXIV
;; Keywords: files, ring
;; Package-Requires: ((emacs "24.3"))
;; Homepage: https://github.com/thechampagne/ring-mode

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode for the Ring programming language.

;;;; Installation

;; You can use built-in package manager (package.el) or do everything by your hands.

;;;;; Using package manager

;; Add the following to your Emacs config file

;; (require 'package)
;; (add-to-list 'package-archives
;;              '("melpa" . "https://melpa.org/packages/") t)
;; (package-initialize)

;; Then use `M-x package-install RET ring-mode RET` to install the mode.
;; Use `M-x ring-mode` to change your current mode.

;;;;; Manual

;; Download the mode to your local directory.  You can do it through `git clone` command:

;; git clone git://github.com/thechampagne/ring-mode.git

;; Then add path to ring-mode to load-path list — add the following to your Emacs config file

;; (add-to-list 'load-path
;; 	     "/path/to/ring-mode/")
;; (require 'ring-mode)

;; Use `M-x ring-mode` to change your current mode.

;;; Code:

(defconst ring-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    table))


(defconst ring-builtins
  '("acos" "add" "addattribute" "adddays" "addmethod" "addsublistsbyfastcopy" "addsublistsbymove"
    "ascii" "asin" "assert" "atan" "atan2" "attributes" "binarysearch" "bytes2double"
    "bytes2float" "bytes2int" "callgarbagecollector" "callgc" "ceil" "cfunctions" "char" "chdir"
    "checkoverflow" "classes" "classname" "clearerr" "clock" "clockspersecond" "closelib" "copy"
    "cos" "cosh" "currentdir" "date" "dec" "decimals" "del" "diffdays" "dir" "direxists" "double2bytes"
    "eval" "exefilename" "exefolder" "exp" "fabs" "fclose" "feof" "ferror" "fexists" "fflush" "fgetc"
    "fgetpos" "fgets" "filename" "find" "float2bytes" "floor" "fopen" "fputc" "fputs"
    "fread" "freopen" "fseek" "fsetpos" "ftell" "functions" "fwrite" "getarch" "getattribute"
    "getchar" "getfilesize" "getnumber" "getpathtype" "getpointer" "getptr" "getstring"
    "globals" "hex" "hex2str" "input" "insert" "int2bytes" "intvalue" "isalnum" "isalpha"
    "isandroid" "isattribute" "iscfunction" "isclass" "iscntrl" "isdigit" "isfreebsd"
    "isfunction" "isglobal" "isgraph" "islinux" "islist" "islocal" "islower" "ismacosx"
    "ismethod" "ismsdos" "isnull" "isnumber" "isobject" "ispackage" "ispackageclass"
    "ispointer" "isprint" "isprivateattribute" "isprivatemethod" "ispunct" "isspace"
    "isstring" "isunix" "isupper" "iswindows" "iswindows64" "isxdigit" "left" "len"
    "lines" "list" "list2str" "loadlib" "locals" "log" "log10" "lower" "max"
    "memcpy" "memorycopy" "mergemethods" "methods" "min" "murmur3hash" "newlist"
    "nofprocessors" "nullpointer" "nullptr" "number" "obj2ptr" "object2pointer"
    "objectid" "packageclasses" "packagename" "packages" "perror" "pointer2object"
    "pointer2string" "pointercompare" "pow" "prevfilename" "print" "print2str" "ptr2obj"
    "ptr2str" "ptrcmp" "puts" "raise" "random" "randomize" "read" "remove" "rename" "reverse"
    "rewind" "right" "ring_give" "ring_see" "ring_state_delete" "ring_state_filetokens"
    "ring_state_findvar" "ring_state_init" "ring_state_main" "ring_state_mainfile"
    "ring_state_new" "ring_state_newvar" "ring_state_runcode" "ring_state_runfile"
    "ring_state_runobjectfile" "ring_state_scannererror" "ring_state_setvar"
    "ring_state_stringtokens" "ringvm_callfunc" "ringvm_calllist"
    "ringvm_cfunctionslist" "ringvm_classeslist" "ringvm_codelist" "ringvm_evalinscope"
    "ringvm_fileslist" "ringvm_functionslist" "ringvm_genarray" "ringvm_give" "ringvm_hideerrormsg"
    "ringvm_info" "ringvm_memorylist" "ringvm_packageslist" "ringvm_passerror" "ringvm_scopescount"
    "ringvm_see" "ringvm_settrace" "ringvm_tracedata" "ringvm_traceevent" "ringvm_tracefunc"
    "setattribute" "setpointer" "setptr" "shutdown" "sin" "sinh" "sort" "sort" "space" "sqrt" "srandom"
    "str2hex" "str2hexcstyle" "str2list" "strcmp" "string" "substr" "swap" "sysget" "sysset" "system"
    "sysunset" "tan" "tanh" "tempfile" "tempname" "time" "timelist" "trim" "type" "ungetc" "unsigned"
    "upper" "uptime" "variablepointer" "varptr" "version" "windowsnl" "write"))


(defconst ring-operators
  '(
    ;; Arithmetic operators
    "+" "-" "*" "/" "%" "++" "--"

    ;; Relational operators
    "=" "!=" ">" "<" ">=" "<="

    ;; Logical operators
    "and" "or" "not" "&&" "||" "!"
    "&" "|" "^" "~" "<<" ">>"

    ;; Bitwise operators
    "+=" "-=" "*=" "/=" "%=" "<<="
    ">>=" "&=" "|=" "^="

    ;; Other operators
    ":" "." "?"))


(defun ring-keywords (limit)
  "Match case-insensitive ring keywords up to limit."
  (let ((case-fold-search t))
    (re-search-forward
     (rx word-boundary (or "again" "and" "but" "bye" "call" "case" "catch" "changeringkeyword"
			   "changeringoperator" "class" "def" "do" "done" "else" "elseif" "end"
			   "exit" "for" "from" "func" "get" "give" "if" "import" "in" "load"
			   "loadsyntax" "loop" "new" "next" "not" "off" "ok" "on" "or" "other"
			   "package" "private" "put" "return" "see" "step" "switch" "to" "try"
			   "while" "endfunc" "endclass" "endpackage" "endif" "endfor" "endwhile"
			   "endswitch" "endtry" "function" "endfunction" "break" "continue")
	 word-boundary)
     limit 'no-error)))


(defun ring-constants (limit)
  "Match case-insensitive ring constants up to limit."
  (let ((case-fold-search t))
    (re-search-forward
     (rx word-boundary (or "true" "false") word-boundary)
     limit 'no-error)))


(defconst ring-font-lock-keywords
  (list
   `("\\(#.*\\)" . font-lock-comment-face)
   `(ring-constants . font-lock-constant-face)
   `(ring-keywords  . font-lock-keyword-face)
   `(,(concat (regexp-opt ring-builtins 'symbols)  "[[:space:]]*(") . (1 font-lock-builtin-face ))
   `(,(regexp-opt ring-operators) . font-lock-builtin-face)))

;;;###autoload
(define-derived-mode ring-mode prog-mode "Ring"
  "A major mode for the Ring programming language."
  :syntax-table ring-mode-syntax-table
  (setq-local font-lock-defaults '(ring-font-lock-keywords))
  (setq-local comment-start "# ")
  (setq-local comment-end ""))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ring\\'" . ring-mode))

(provide 'ring-mode)

;;; ring-mode.el ends here
