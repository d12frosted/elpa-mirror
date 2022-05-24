;;; masm-mode.el --- MASM x86 and x64 assembly major mode -*- lexical-binding: t; -*-

;; This is free and unencumbered software released into the public domain.

;; Author: YiGeeker <zyfchinese@yeah.net>
;; Version: 1.0.0
;; Package-Version: 20200308.1450
;; Package-Commit: 626b9255c2bb967a53d1d50be0b98a1bcae3250c
;; Package-Requires: ((emacs "25.1"))
;; Keywords: languages
;; URL: https://github.com/YiGeeker/masm-mode

;; This file is NOT part of GNU Emacs.
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of GNU General Public License.

;;; Commentary:

;; A major mode for editing MASM x86 and x64 assembly code. It
;; includes syntax highlighting, automatic comment indentation and
;; various build commands.
;; Notice: masm-mode will clobber Emacs's built-in asm-mode.

;;; Code:

(defgroup masm nil
  "Options for `masm-mode'."
  :link '(custom-group-link :tag "Font Lock Faces group" font-lock-faces)
  :group 'languages)

(defcustom masm-program-win64 t
  "Syntax for `masm-mode', t for Win64 and nil for Win32."
  :type '(choice (const :tag "Win64" t)
                 (const :tag "Win32" nil))
  :group 'masm-mode)

(defcustom masm-win32-compile-args '("/c" "/coff")
  "Default arguments for the ml.exe in `masm-mode'."
  :type '(repeat string)
  :group 'masm-mode)

(defcustom masm-win32-link-args '("/subsystem:windows")
  "Default arguments for the Win32 link.exe in `masm-mode'."
  :type '(repeat string)
  :group 'masm-mode)

(defcustom masm-win32-executable-path ""
  "Path for ml.exe."
  :type 'directory
  :group 'masm-mode)

(defcustom masm-win32-include-path ()
  "Path for Win32 inc files in `masm-mode'."
  :type '(repeat directory)
  :group 'masm-mode)

(defcustom masm-win32-library-path ()
  "Path for Win32 lib files in `masm-mode'."
  :type '(repeat directory)
  :group 'masm-mode)

(defcustom masm-win64-compile-args '("/c")
  "Default arguments for the ml64.exe in `masm-mode'."
  :type '(repeat string)
  :group 'masm-mode)

(defcustom masm-win64-link-args '("/subsystem:windows" "/machine:x64" "/entry:main")
  "Default arguments for the Win64 link.exe in `masm-mode'."
  :type '(repeat string)
  :group 'masm-mode)

(defcustom masm-win64-executable-path ""
  "Path for ml64.exe."
  :type 'directory
  :group 'masm-mode)

(defcustom masm-win64-include-path ()
  "Path for Win64 inc files in `masm-mode'."
  :type '(repeat directory)
  :group 'masm-mode)

(defcustom masm-win64-library-path ()
  "Path for Win64 lib files in `masm-mode'."
  :type '(repeat directory)
  :group 'masm-mode)

(defcustom masm-build-executable "nmake"
  "Default executable for building the assembly project in `masm-mode'."
  :type 'string
  :group 'masm-mode)

(defcustom masm-build-args ()
  "Default arguments for the build command in `masm-mode'."
  :type '(repeat string)
  :group 'masm-mode)

(defvar-local masm--program-win64
  masm-program-win64
  "Decided by customizable value.")

(defvar-local masm--compile-command-used nil
  "Save changed compile command.")

(defvar-local masm--link-command-used nil
  "Save changed link command.")

(defvar-local masm--build-command-used nil
  "Save changed build command.")

(defgroup masm-mode-faces ()
  "Faces used by `masm-mode'."
  :group 'masm-mode)

(defvar masm-mode-abbrev-table nil
  "Abbrev table used while in `masm-mode'.")
(define-abbrev-table 'masm-mode-abbrev-table ())

(defface masm-registers
  '((t :inherit (font-lock-variable-name-face)))
  "Face for registers."
  :group 'masm-mode-faces)

(defface masm-prefix
  '((t :inherit (font-lock-builtin-face)))
  "Face for prefix."
  :group 'masm-mode-faces)

(defface masm-types
  '((t :inherit (font-lock-type-face)))
  "Face for types."
  :group 'masm-mode-faces)

(defface masm-instructions
  '((t :inherit (font-lock-builtin-face)))
  "Face for instructions."
  :group 'masm-mode-faces)

(defface masm-directives
  '((t :inherit (font-lock-keyword-face)))
  "Face for directives."
  :group 'masm-mode-faces)

(defface masm-labels
  '((t :inherit (font-lock-function-name-face)))
  "Face for labels."
  :group 'masm-mode-faces)

(defface masm-subprogram
  '((t :inherit (font-lock-function-name-face)))
  "Face for subprogram."
  :group 'masm-mode-faces)

(defface masm-macro
  '((t :inherit (font-lock-function-name-face)))
  "Face for macro."
  :group 'masm-mode-faces)

(defface masm-section-name
  '((t :inherit (font-lock-type-face)))
  "Face for section name."
  :group 'masm-mode-faces)

(defface masm-constant
  '((t :inherit (font-lock-constant-face)))
  "Face for constant."
  :group 'masm-mode-faces)

(defface masm-struct
  '((t :inherit (font-lock-type-face)))
  "Face for struct."
  :group 'masm-mode-faces)

(defface masm-union
  '((t :inherit (font-lock-type-face)))
  "Face for union."
  :group 'masm-mode-faces)

(eval-and-compile
  (defconst masm-registers-common
    '("ah" "al" "ax" "bh" "bl" "bp" "bx" "ch" "cl" "cr0" "cr2" "cr3"
      "cs" "cx" "dh" "di" "dl" "dr0" "dr1" "dr2" "dr3" "dr6" "dr7"
      "ds" "dx" "eax" "ebp" "ebx" "ecx" "edi" "edx" "eip" "es" "esi"
      "esp" "fpr0" "fpr1" "fpr2" "fpr3" "fpr4" "fpr5" "fpr6" "fpr7"
      "fs" "gs" "ip" "mmx0" "mmx1" "mmx2" "mmx3" "mmx4" "mmx5" "mmx6"
      "mmx7" "si" "sp" "ss" "st" "tr3" "tr4" "tr5" "tr6" "tr7" )
    "MASM registers for `masm-mode'."))


(eval-and-compile
  (defconst masm-registers-win64-only
    '( "r10" "r10b" "r10d" "r10w" "r11" "r11b" "r11d" "r11w" "r12"
       "r12b" "r12d" "r12w" "r13" "r13b" "r13d" "r13w" "r14" "r14b"
       "r14d" "r14w" "r15" "r15b" "r15d" "r15w" "r8" "r8b" "r8d" "r8w"
       "r9" "r9b" "r9d" "r9w" "rax" "rbp" "rbx" "rcx" "rdi" "rdx" "rip"
       "rsi" "rsp" "xmm0" "xmm1" "xmm10" "xmm11" "xmm12" "xmm13"
       "xmm14" "xmm15" "xmm2" "xmm3" "xmm4" "xmm5" "xmm6" "xmm7" "xmm8"
       "xmm9")
    "MASM win64 registers for `masm-mode'."))

(eval-and-compile
  (defconst masm-instructions-common
    '("aaa" "aad" "aam" "aas" "adc" "adcx" "add" "addpd" "addps"
      "addsd" "addss" "addsubpd" "addsubps" "adox" "aesdec"
      "aesdeclast" "aesenc" "aesenclast" "aesimc" "aeskeygenassist"
      "and" "andn" "andnpd" "andnps" "andpd" "andps" "arpl" "bound"
      "bsf" "bsr" "bswap" "bt" "btc" "btr" "bts" "call" "clc" "cld"
      "cli" "clts" "cmp" "cmps" "cmpsb" "cmpsw" "cmpxchg" "cwd" "daa"
      "das" "dec" "div" "enter" "esc" "f2xm1" "fabs" "fadd" "faddp"
      "fbld" "fbstp" "fchs" "fclex" "fcom" "fcomp" "fcompp" "fcos"
      "fdecstp" "fdisi" "fdiv" "fdivp" "fdivr" "fdivrp" "feni" "ffree"
      "fiadd" "ficom" "ficomp" "fidiv" "fidivr" "fild" "fimul"
      "fincstp" "finit" "fist" "fistp" "fisub" "fisubr" "fld" "fld1"
      "fldcw" "fldenv" "fldenvd" "fldenvw" "fldl2e" "fldl2t" "fldlg2"
      "fldln2" "fldpi" "fldz" "fmul" "fmulp" "fnclex" "fndisi" "fneni"
      "fninit" "fnop" "fnsave" "fnsaved" "fnsavew" "fnstcw" "fnstenv"
      "fnstenvd" "fnstenvw" "fnstsw" "fpatan" "fprem" "fprem1" "fptan"
      "frndint" "frstor" "frstord" "frstorw" "fsave" "fsaved" "fsavew"
      "fscale" "fsetpm" "fsin" "fincos" "fsqrt" "fst" "fstcw" "fstenv"
      "fstenvd" "fstenvw" "fstp" "fstsw" "fsub" "fsubp" "fsubr"
      "fsubrp" "ftst" "fucom" "fucomp" "fucompp" "fwait" "fxam" "fxch"
      "fxtract" "fyl2x" "fyl2xp1" "hlt" "idiv" "imul" "in" "inc" "ins"
      "insb" "insd" "insw" "int" "into" "invd" "invlpg" "iret" "iretd"
      "iretdf" "iretf" "ja" "jae" "jb" "jbe" "jc" "jcxz" "je" "jecxz"
      "jg" "jge" "jl" "jle" "jmp" "jna" "jnae" "jnb" "jnbe" "jnc"
      "jne" "jng" "jnge" "jnl" "jnle" "jno" "jnp" "jns" "jnz" "jo"
      "jp" "jpe" "jpo" "js" "jz" "lahf" "lar" "lds" "lea" "leave"
      "les" "lfs" "lgdt" "lgs" "lidt" "lldt" "lmsw" "lods" "lodsb"
      "lodsd" "lodsw" "loop" "loopd" "loope" "looped" "loopew"
      "loopne" "loopned" "loopnz" "loopnzd" "loopnzw" "loopw" "loopz"
      "loopzd" "loopzw" "lsl" "lss" "ltr" "mov" "movapd" "movaps"
      "movbe" "movd" "movddup" "movdq2q" "movdqa" "movdqu" "movhlps"
      "movhpd" "movhps" "movlhps" "movlpd" "movlps" "movmskpd"
      "movmskps" "movntdq" "movntdqa" "movnti" "movntpd" "movntps"
      "movntq" "movntsd" "movntss" "movq" "movq2dq" "movs" "movsb"
      "movsd" "movsx" "movsw" "movzx" "mul" "nop" "not" "or" "out"
      "outs" "outsb" "outsd" "outsw" "pabsb" "pabsd" "pabsw"
      "packssdw" "packsswb" "packusdw" "packuswb" "paddb" "paddd"
      "paddq" "paddsb" "paddsiw" "paddsw" "paddusb" "paddusw" "paddw"
      "palignr" "pand" "pandn" "pause" "paveb" "pavgb" "pavgusb"
      "pavgw" "pblendvb" "pblendw" "pclmulhqhqdq" "pclmulhqlqdq"
      "pclmullqhqdq" "pclmullqlqdq" "pclmulqdq" "pcmpeqb" "pcmpeqd"
      "pcmpeqq" "pcmpeqw" "pcmpestri" "pcmpestrm" "pcmpgtb" "pcmpgtd"
      "pcmpgtq" "pcmpgtw" "pcmpistri" "pcmpistrm" "pdep" "pdistib"
      "pext" "pextrb" "pextrd" "pextrq" "pextrw" "pf2id" "pf2iw"
      "pfacc" "pfadd" "pfcmpeq" "pfcmpge" "pfcmpgt" "pfmax" "pfmin"
      "pfmul" "pfnacc" "pfpnacc" "pfrcp" "pfrcpit1" "pfrcpit2"
      "pfrcpv" "pfrsqit1" "pfrsqrt" "pfrsqrtv" "pfsub" "pfsubr"
      "phaddd" "phaddsw" "phaddw" "phminposuw" "phsubd" "phsubsw"
      "phsubw" "pi2fd" "pi2fw" "pinsrb" "pinsrd" "pinsrq" "pinsrw"
      "pmachriw" "pmaddubsw" "pmaddwd" "pmagw" "pmaxsb" "pmaxsd"
      "pmaxsw" "pmaxub" "pmaxud" "pmaxuw" "pminsb" "pminsd" "pminsw"
      "pminub" "pminud" "pminuw" "pmovmskb" "pmovsxbd" "pmovsxbq"
      "pmovsxbw" "pmovsxdq" "pmovsxwd" "pmovsxwq" "pmovzxbd"
      "pmovzxbq" "pmovzxbw" "pmovzxdq" "pmovzxwd" "pmovzxwq" "pmuldq"
      "pmulhriw" "pmulhrsw" "pmulhrwa" "pmulhrwc" "pmulhuw" "pmulhw"
      "pmulld" "pmullw" "pmuludq" "pmvgezb" "pmvlzb" "pmvnzb" "pmvzb"
      "pop" "popa" "popf" "popfd" "push" "pusha" "pushd" "pushf"
      "pushfd" "pushw" "rcl" "rcr" "ret" "retf" "retn" "rol" "ror"
      "sahf" "sal" "sar" "sbb" "scas" "scasb" "scasd" "scasw" "seta"
      "setae" "setb" "setbe" "setc" "sete" "setg" "setge" "setl"
      "setle" "setna" "setnae" "setnb" "setnbe" "setnc" "setne"
      "setng" "setnge" "setnl" "setnle" "setno" "setnp" "setns"
      "setnz" "seto" "setp" "setpe" "setpo" "sets" "setz" "shld" "shl"
      "shld" "shr" "shrd" "sidt" "sldt" "smsw" "stc" "std" "sti" "str"
      "stos" "stosb" "stosd" "stosw" "sub" "test" "verr" "verw"
      "wbinvd" "xadd" "xchg" "xlat" "xlatb" "xor")
    "MASM instructions for `masm-mode'."))

(eval-and-compile
  (defconst masm-instructions-win32-only
    '("pushad" "popad")
    "MASM Win32 instructions for `masm-mode'."))

(eval-and-compile
  (defconst masm-section-name
    '(".code" ".const" ".data" ".data?" ".stack")
    "MASM section names for `masm-mode'."))

(eval-and-compile
  (defconst masm-types
    '("byte" "dword" "fword" "qword" "Real4" "Real8" "Real10" "sbyte"
      "sdword" "sword" "tbyte" "word")
    "MASM types for `masm-mode'."))

(eval-and-compile
  (defconst masm-prefix
    '("lock" "rep" "repe" "repne" "repnz" "repz")
    "MASM prefixes for `masm-mode'."))

(eval-and-compile
  (defconst masm-directives-win32-only
    '(".186" ".286" ".286c" ".286p" ".287" ".386" ".386c" ".386p"
      ".387" ".486" ".486p" ".8086" ".8087" ".alpha" ".break"
      ".continue" ".cref" ".dosseg" ".else" ".elseif" ".endif" ".endw"
      ".err" ".err1" ".err2" ".errb" ".errdef" ".errdif" ".errdifi"
      ".erre" ".erridn" ".erridni" ".errnb" ".errndef" ".errnz"
      ".exit" ".fardata" ".fardata?" ".if" ".lall" ".lfcond" ".list"
      ".listall" ".listif" ".listmacro" ".listmacroall" ".mmx"
      ".model" ".msfloat" ".no87" ".nocref" ".nolist" ".nolistif"
      ".nolistmacro" ".radix"".repeat" ".sall" ".seq" ".sfcond"
      ".startup" ".tfcond" ".type" ".until" ".untilcxz" ".while"
      ".xall" ".xcref" ".xlist" "%out" "carry?" "invoke" "overflow?"
      "parity?" "sign?" "zero?")
    "MASM win32 directives for `masm-mode'."))

(eval-and-compile
  (defconst masm-directives-common
    '("alias" "align" "assume" "catstr" "comm" "comment" "db" "dd"
      "df" "dosseg" "dq" "dt" "dup" "dw" "echo" "else" "elseif"
      "elseif1" "elseif2" "elseifb" "elseifdef" "elseifdif"
      "elseifdifi" "elseife" "elseifidn" "elseifidni" "elseifnb"
      "elseifndef" "end" "endif" "endm" "endp" "ends" "eq" "equ"
      "even" "exitm" "extern" "externdef" "extrn" "for" "forc""ge"
      "goto" "group" "gt" "high" "highword" "if" "if1" "if2" "ifb"
      "ifdef" "ifdif" "ifdifi" "ife" "ifidn" "ifidni" "ifnb" "ifndef"
      "include" "includelib" "instr" "irp" "irpc" "label" "le"
      "length" "lengthof" "local" "low" "lowword" "lroffset" "lt"
      "macro" "mask" "mod" "name" "ne" "offset" "opattr" "option"
      "org" "page" "popcontext" "proc" "proto" "ptr" "public" "purge"
      "pushcontext" "record" "repeat" "rept" "seg" "segment" "short"
      "size" "sizeof" "sizestr" "struc" "struct" "substr" "subtitle"
      "subttl" "textequ" "this" "title" "type" "typedef" "union" "uses"
      "while")
    "MASM directives for `masm-mode'."))

(defconst masm-label-regexp
  "\\(\\_<[a-zA-Z_@][a-zA-Z0-9_@?]*\\_>\\):\\s-*"
  "Regexp for `masm-mode' for matching labels.")

(defconst masm-subprogram-regexp
  "\\(\\_<[a-zA-Z_@]+\\_>\\)[ \t]+\\(proc\\|endp\\)\\s-*"
  "Regexp for `masm-mode' for matching subprogram.")

(defconst masm-constant-regexp
  "\\<[-+]?\\([0-9]+[Dd]?\\|[01]+[Bb]\\|[0-7]+[Qq]\\|[0-9A-Fa-f]+[Hh]\\)\\([-+]\\([0-9]+[Dd]?\\|[01]+[Bb]\\|[0-7]+[Qq]\\|[0-9A-Fa-f]+[Hh]\\)\\)*\\>"
  "Regexp for `masm-mode' for matching numeric constants.")

(defconst masm-struct-regexp
  "\\(\\_<[a-zA-Z_@]+\\_>\\)[ \t]+\\(struct\\|ends\\)\\s-*"
  "Regexp for `masm-mode' for matching struct.")

(defconst masm-union-regexp
  "\\(\\_<[a-zA-Z_@]+\\_>\\)[ \t]+\\(union\\|ends\\)\\s-*"
  "Regexp for `masm-mode' for matching struct.")

(defconst masm-macro-regexp
  "\\(\\_<[a-zA-Z_@]+\\_>\\)[ \t]+macro\\s-*"
  "Regexp for `masm-mode' for matching macro.")

(defmacro masm--opt (keywords)
  "Prepare KEYWORDS for `looking-at'."
  `(eval-when-compile
     (regexp-opt ,keywords 'words)))

(defconst masm-imenu-generic-expression
  `((nil ,(concat "^\\s-*" masm-label-regexp) 1)
    (nil ,(concat "\\(\\_<[a-zA-Z_@]+\\_>\\)[ \t]+"
                  (masm--opt '("proc" "macro")))
         1))
  "Expressions for `imenu-generic-expression'.")

(defconst masm-win32-font-lock-keywords
  `((,(masm--opt masm-section-name) . 'masm-section-name)
    (,(masm--opt masm-registers-common) . 'masm-registers)
    (,(masm--opt masm-types) . 'masm-types)
    (,(masm--opt masm-instructions-common) . 'masm-instructions)
    (,(masm--opt masm-instructions-win32-only) . 'masm-instructions)
    (,(masm--opt masm-prefix) . 'masm-prefix)
    (,masm-label-regexp (1 'masm-labels))
    (,masm-subprogram-regexp (1 'masm-subprogram))
    (,masm-constant-regexp . 'masm-constant)
    (,masm-struct-regexp (1 'masm-struct))
    (,masm-union-regexp (1 'masm-union))
    (,masm-macro-regexp (1 'masm-macro))
    (,(masm--opt masm-directives-common) . 'masm-directives)
    (,(masm--opt masm-directives-win32-only) . 'masm-directives))
  "Win32 keywords for `masm-mode'.")

(defconst masm-win64-font-lock-keywords
  `((,(masm--opt masm-section-name) . 'masm-section-name)
    (,(masm--opt masm-registers-common) . 'masm-registers)
    (,(masm--opt masm-registers-win64-only) . 'masm-registers)
    (,(masm--opt masm-types) . 'masm-types)
    (,(masm--opt masm-instructions-common) . 'masm-instructions)
    (,(masm--opt masm-prefix) . 'masm-prefix)
    (,masm-label-regexp (1 'masm-labels))
    (,masm-subprogram-regexp (1 'masm-subprogram))
    (,masm-constant-regexp . 'masm-constant)
    (,masm-struct-regexp (1 'masm-struct))
    (,masm-union-regexp (1 'masm-union))
    (,masm-macro-regexp (1 'masm-macro))
    (,(masm--opt masm-directives-common) . 'masm-directives))
  "Win64 keywords for `masm-mode'.")

(defconst masm-mode-syntax-table
  (with-syntax-table (copy-syntax-table)
    (modify-syntax-entry ?_  "w")
    (modify-syntax-entry ?@  "w")
    (modify-syntax-entry ?\? "w")
    (modify-syntax-entry ?\. "w")
    (modify-syntax-entry ?\; "<")
    (modify-syntax-entry ?\n ">")
    (modify-syntax-entry ?\" "\"")
    (modify-syntax-entry ?\' "\"")
    (syntax-table))
  "Syntax table for `masm-mode'.")

(defvar masm-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Note that the comment character isn't set up until masm-mode is called.
    (define-key map ":"        #'masm-colon)
    (define-key map "\C-c;"    #'comment-region)
    (define-key map ";"        #'masm-comment)
    (define-key map "\C-j"     #'masm-newline-and-indent)
    (define-key map "\C-m"     #'masm-newline-and-indent)
    (define-key map "\C-c\C-c" #'masm-build)
    (define-key map "\C-c\C-b" #'masm-compile)
    (define-key map "\C-c\C-l" #'masm-link)
    (define-key map "\C-c\C-s" #'masm-change-program-type)
    (define-key map [menu-bar masm-mode] (cons "Masm" (make-sparse-keymap)))

    (define-key map [menu-bar masm-mode newline-and-indent]
      '(menu-item "Insert Newline and Indent" masm-newline-and-indent
                  :help "Insert a newline, then indent according to major mode"))
    (define-key map [menu-bar masm-mode masm-colon]
      '(menu-item "Insert Colon" masm-colon
                  :help "Insert a colon; if it follows a label, delete the label's indentation"))
    (define-key map [menu-bar masm-mode masm-change-program-type]
      '(menu-item "Switch program type" masm-change-program-type
                  :help "Switch between Win32 and Win64"))
    (define-key map [menu-bar masm-mode masm-link]
      '(menu-item "Link the obj file" masm-link
                  :help "Use link to link the obj file"))
    (define-key map [menu-bar masm-mode masm-compile]
      '(menu-item "Compile the file" masm-compile
                  :help "Use ml64 to compile the file"))
    (define-key map [menu-bar masm-mode masm-build]
      '(menu-item "Build the project" masm-build
                  :help "Use nmake to build the project"))
    (define-key map [menu-bar masm-mode comment-region]
      '(menu-item "Comment Region" comment-region
                  :help "Comment or uncomment each line in the region"))
    map)
  "Keymap for masm mode.")

(defun masm-colon ()
  "Insert a colon and convert the current line into a label."
  (interactive)
  (call-interactively #'self-insert-command)
  (save-excursion
    (back-to-indentation)
    (delete-horizontal-space)))

(defun masm-newline-and-indent ()
  "Auto-indent the new line."
  (interactive)
  (let ((indent
         (save-excursion
           (back-to-indentation)
           (current-column)))
        (col (current-column)))
    (newline-and-indent)
    (if (eql indent col)
        (indent-line-to indent))))

(defun masm--current-line ()
  "Return the current line as a string."
  (save-excursion
    (let ((start (line-beginning-position))
          (end (line-end-position)))
      (buffer-substring-no-properties start end))))

(defun masm--empty-line-p ()
  "Return non-nil if current line has non-whitespace."
  (not (string-match-p "\\S-" (masm--current-line))))

(defun masm--line-has-comment-p ()
  "Return non-nil if current line contain a comment."
  (save-excursion
    (end-of-line)
    (nth 4 (syntax-ppss))))

(defun masm--line-has-non-comment-p ()
  "Return non-nil of the current line has code."
  (let* ((line (masm--current-line))
         (match (string-match-p "\\S-" line)))
    (when match
      (not (eql ?\; (aref line match))))))

(defun masm--inside-indentation-p ()
  "Return non-nil if point is within the indentation."
  (save-excursion
    (let ((point (point))
          (start (line-beginning-position))
          (end (save-excursion (back-to-indentation) (point))))
      (and (<= start point) (<= point end)))))

(defun masm-insert-comment ()
  "Insert a comment if the current line doesn’t contain one."
  (let ((comment-insert-comment-function nil))
    (if (or (masm--empty-line-p) (nth 3 (syntax-ppss)))
        (progn
          (indent-line-to 0)
          (insert ";"))
      (comment-indent))))

(defun masm-comment (&optional arg)
  "Begin or edit a comment with context-sensitive placement.

The right-hand comment gutter is far away from the code, so this
command uses the mark ring to help move back and forth between
code and the comment gutter.

* If no comment gutter exists yet, mark the current position and
  jump to it.
* If already within the gutter, pop the top mark and return to
  the code.
* If on a line with no code, just insert a comment character.
* If within the indentation, just insert a comment character.
  This is intended prevent interference when the intention is to
  comment out the line.

With a prefix ARG, kill the comment on the current line with
`comment-kill'."
  (interactive "p")
  (if (not (eql arg 1))
      (comment-kill nil)
    (cond
     ;; Empty line, or inside a string? Insert.
     ((or (masm--empty-line-p) (nth 3 (syntax-ppss)))
      (indent-line-to 0)
      (insert ";"))
     ;; Inside the indentation? Comment out the line.
     ((masm--inside-indentation-p)
      (insert ";"))
     ;; Currently in a right-side comment? Return.
     ((and (masm--line-has-comment-p)
           (masm--line-has-non-comment-p)
           (nth 4 (syntax-ppss)))
      (setf (point) (mark))
      (pop-mark))
     ;; Line has code? Mark and jump to right-side comment.
     ((masm--line-has-non-comment-p)
      (push-mark)
      (comment-indent))
     ;; Otherwise insert.
     ((insert ";")))))

(defun masm-compile (_savep command)
  "Compile COMMAND in `masm-mode'."
  (interactive
   (list (if (buffer-modified-p)
             (let ((savep (y-or-n-p (format "Buffer %s modified; Save it before compile? " (current-buffer)))))
               (if savep
                   (save-buffer))))
         (if masm--compile-command-used
             (read-shell-command "Compile command: " masm--compile-command-used)
           (let ((command (if masm--program-win64
                              (concat
                               "ml64 "
                               (mapconcat (lambda (str) str) masm-win64-compile-args " ")
                               " "
                               (file-name-nondirectory buffer-file-name))
                            (concat
                             "ml "
                             (mapconcat (lambda (str) str) masm-win32-compile-args " ")
                             " "
                             (file-name-nondirectory buffer-file-name)))))
             (read-shell-command "Compile command: " command)))))
  (setq masm--compile-command-used command)
  (if masm--program-win64
      (let ((process-environment
             (append
              (list
               (concat "PATH=" masm-win64-executable-path ";"
                       (getenv "path"))
               (concat "INCLUDE=" (mapconcat #'file-name-as-directory masm-win64-include-path ";")
                       (getenv "include"))
               (concat "LIB=" (mapconcat #'file-name-as-directory masm-win64-library-path ";")
                       (getenv "lib")))
              process-environment)))
        (compilation-start
         command nil (lambda (_maj-mode)
                       "*masm x64 compile*")))
    (let ((process-environment
           (append
            (list
             (concat "PATH=" masm-win32-executable-path ";"
                     (getenv "path"))
             (concat "INCLUDE=" (mapconcat #'file-name-as-directory masm-win32-include-path ";")
                     (getenv "include"))
             (concat "LIB=" (mapconcat #'file-name-as-directory masm-win32-library-path ";")
                     (getenv "lib")))
            process-environment)))
      (compilation-start
       command nil (lambda (_maj-mode)
                     "*masm x86 compile*")))))


(defun masm-link (command)
  "Compile COMMAND in `masm-mode'."
  (interactive
   (list (if masm--link-command-used
             (read-shell-command "Link command: " masm--link-command-used)
           (let ((command (concat
                           "link "
                           (mapconcat (lambda (str) str) (if masm--program-win64 masm-win64-link-args masm-win32-link-args) " ")
                           " "
                           (file-name-base buffer-file-name)
                           ".obj")))
             (read-shell-command "Link command: " command)))))
  (setq masm--link-command-used command)
  (if masm--program-win64
      (let ((process-environment
             (append
              (list
               (concat "PATH=" masm-win64-executable-path ";"
                       (getenv "path"))
               (concat "INCLUDE=" (mapconcat #'file-name-as-directory masm-win64-include-path ";")
                       (getenv "include"))
               (concat "LIB=" (mapconcat #'file-name-as-directory masm-win64-library-path ";")
                       (getenv "lib")))
              process-environment)))
        (compilation-start
         command nil (lambda (_maj-mode)
                       "*masm x64 link*")))
    (let ((process-environment
           (append
            (list
             (concat "PATH=" masm-win32-executable-path ";"
                     (getenv "path"))
             (concat "INCLUDE=" (mapconcat #'file-name-as-directory masm-win32-include-path ";")
                     (getenv "include"))
             (concat "LIB=" (mapconcat #'file-name-as-directory masm-win32-library-path ";")
                     (getenv "lib")))
            process-environment)))
      (compilation-start
       command nil (lambda (_maj-mode)
                     "*masm x86 link*")))))

(defun masm-build (_savep command)
  "Build COMMAND in `masm-mode'."
  (interactive
   (list (if (buffer-modified-p)
             (let ((savep (y-or-n-p (format "Buffer %s modified; Save it before build? " (current-buffer)))))
               (if savep
                   (save-buffer))))
         (if masm--build-command-used
             (read-shell-command "Build command: " masm--build-command-used)
           (let ((command (concat
                           masm-build-executable " "
                           (mapconcat (lambda (str) str) masm-build-args " "))))
             (read-shell-command "Build command: " command)))))
  (setq masm--build-command-used command)
  (if masm--program-win64
      (let ((process-environment
             (append
              (list
               (concat "PATH=" masm-win64-executable-path ";"
                       (getenv "path"))
               (concat "INCLUDE=" (mapconcat #'file-name-as-directory masm-win64-include-path ";")
                       (getenv "include"))
               (concat "LIB=" (mapconcat #'file-name-as-directory masm-win64-library-path ";")
                       (getenv "lib")))
              process-environment)))
        (compilation-start
         command nil (lambda (_maj-mode)
                       "*masm x64 build*")))
    (let ((process-environment
           (append
            (list
             (concat "PATH=" masm-win32-executable-path ";"
                     (getenv "path"))
             (concat "INCLUDE=" (mapconcat #'file-name-as-directory masm-win32-include-path ";")
                     (getenv "include"))
             (concat "LIB=" (mapconcat #'file-name-as-directory masm-win32-library-path ";")
                     (getenv "lib")))
            process-environment)))
      (compilation-start
       command nil (lambda (_maj-mode)
                     "*masm x86 build*")))))

(defun masm-win32 ()
  "Change to Win32 highlighting."
  (interactive)
  (setq-local masm--program-win64 nil)
  (setq-local font-lock-keywords masm-win32-font-lock-keywords)
  (font-lock-flush))

(defun masm-win64 ()
  "Change to Win64 highlighting."
  (interactive)
  (setq-local masm--program-win64 t)
  (setq-local font-lock-keywords masm-win64-font-lock-keywords)
  (font-lock-flush))

(defun masm-change-program-type ()
  "Switch program highlighting."
  (interactive)
  (if masm--program-win64
      (call-interactively #'masm-win32)
    (call-interactively #'masm-win64)))

(defun masm-mode-before ()
  "Delay this to a hook instead of running it immediately, due the order in which file local variables are processed."
  (unless (eql masm--program-win64 masm-program-win64)
    (setq masm--program-win64 masm-program-win64)
    (if masm-program-win64
        (setq-local font-lock-keywords masm-win64-font-lock-keywords)
      (setq-local font-lock-keywords masm-win32-font-lock-keywords))))

;;;###autoload
(define-derived-mode masm-mode prog-mode "MASM"
  "Major mode for editing MASM assembly programs."
  :group 'masm-mode
  (setq local-abbrev-table masm-mode-abbrev-table)
  (if masm--program-win64
      (setq-local font-lock-defaults '(masm-win64-font-lock-keywords nil :case-fold))
    (setq-local font-lock-defaults '(masm-win32-font-lock-keywords nil :case-fold)))
  (setq-local comment-start ";")
  (setq-local comment-insert-comment-function #'masm-insert-comment)
  (setq-local imenu-generic-expression masm-imenu-generic-expression)
    
  (add-hook 'after-change-major-mode-hook #'masm-mode-before t t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.asm\\'" . masm-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.inc\\'" . masm-mode))

(provide 'masm-mode)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; masm-mode.el ends here
