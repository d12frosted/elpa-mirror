;;; cuda-mode.el --- NVIDIA CUDA Major Mode

;; Copyright (C) 2014  Jack Morrison

;; Author: Jack Morrison <jackmorrison1@gmail.com>
;; Keywords: c, languages
;; Package-Version: 20201013.2230
;; Package-Commit: 7f593518fd135fc6af994024bcb47986dfa502d2

;; This program is free software; you can redistribute it and/or modify
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

;; Originally found on EmacsWiki @ http://www.emacswiki.org/emacs/CudaMode

;;; Code:

(require 'cc-mode)
(require 'cl)

;; These are only required at compile time to get the sources for the
;; language constants.  (The cc-fonts require and the font-lock
;; related constants could additionally be put inside an
;; (eval-after-load "font-lock" ...) but then some trickery is
;; necessary to get them compiled.)
(eval-when-compile
  (require 'cc-langs)
  (require 'cc-fonts))


(eval-and-compile
  ;; Make our mode known to the language constant system.  Use C
  ;; mode as the fallback for the constants we don't change here.
  ;; This needs to be done also at compile time since the language
  ;; constants are evaluated then.
  (c-add-language 'cuda-mode 'c++-mode))

;; cuda has no boolean but a string and a vector type.
(c-lang-defconst c-primitive-type-kwds
  "Primitive type keywords.  As opposed to the other keyword lists, the
keywords listed here are fontified with the type face instead of the
keyword face.

If any of these also are on `c-type-list-kwds', `c-ref-list-kwds',
`c-colon-type-list-kwds', `c-paren-nontype-kwds', `c-paren-type-kwds',
`c-<>-type-kwds', or `c-<>-arglist-kwds' then the associated clauses
will be handled.

Do not try to modify this list for end user customizations; the
`*-font-lock-extra-types' variable, where `*' is the mode prefix, is
the appropriate place for that."
  cuda
  (append
   '("dim3"
     "char1" "uchar1" "char2" "uchar2" "char3" "uchar3" "char4" "uchar4"
     "short1" "ushort1" "short2" "ushort2" "short3" "ushort3" "short4" "ushort4"
     "int1" "uint1" "int2" "uint2" "int3" "uint3" "int4" "uint4"
     "long1" "ulong1" "long2" "ulong2" "long3" "ulong3" "long4" "ulong4"
     "float1" "float2"  "float3" "float4"
     "double1" "double2" )
   ;; Use append to not be destructive on the
   ;; return value below.
   (append
    (c-lang-const c-primitive-type-kwds)
    nil)))

(c-lang-defconst c-modifier-kwds
  cuda (append
	(c-lang-const c-modifier-kwds)
	'("__device__" "__global__" "__shared__" "__host__" "__constant__")))

(c-lang-defconst c-other-op-syntax-tokens
  "List of the tokens made up of characters in the punctuation or
parenthesis syntax classes that have uses other than as expression
operators."
  cuda
  (append '("#" "##"	; Used by cpp.
	    "::" "..." "<<<" ">>>")
	  (c-lang-const c-other-op-syntax-tokens)))

(c-lang-defconst c-primary-expr-kwds
  "Keywords besides constants and operators that start primary expressions."
  cuda  '("gridDim" "blockIdx" "blockDim" "threadIdx" "warpSize"))

(c-lang-defconst c-paren-nontype-kwds
  "Keywords that may be followed by a parenthesis expression that doesn't
contain type identifiers."
  cuda       nil
  (c c++) '(;; GCC extension.
	    "__attribute__"
	    ;; MSVC extension.
	    "__declspec"))

(defconst cuda-builtins
  '(;; atom
    "atomicAdd"
    "atomicAnd"
    "atomicCAS"
    "atomicDec"
    "atomicExch"
    "atomicInc"
    "atomicMax"
    "atomicMin"
    "atomicOr"
    "atomicSub"
    "atomicXor"
    ;; dev
    "tex1D"
    "tex1Dfetch"
    "tex2D"
    "__float_as_int"
    "__int_as_float"
    "__float2int_rn"
    "__float2int_rz"
    "__float2int_ru"
    "__float2int_rd"
    "__float2uint_rn"
    "__float2uint_rz"
    "__float2uint_ru"
    "__float2uint_rd"
    "__int2float_rn"
    "__int2float_rz"
    "__int2float_ru"
    "__int2float_rd"
    "__uint2float_rn"
    "__uint2float_rz"
    "__uint2float_ru"
    "__uint2float_rd"
    "__fadd_rz"
    "__fmul_rz"
    "__fdividef"
    "__mul24"
    "__umul24"
    "__mulhi"
    "__umulhi"
    "__mul64hi"
    "__umul64hi"
    "min"
    "umin"
    "fminf"
    "fmin"
    "max"
    "umax"
    "fmaxf"
    "fmax"
    "abs"
    "fabsf"
    "fabs"
    "sqrtf"
    "sqrt"
    "sinf"
    "__sinf"
    "sin"
    "cosf"
    "__cosf"
    "cos"
    "sincosf"
    "__sincosf"
    "expf"
    "__expf"
    "exp"
    "logf"
    "__logf"
    "log"
    ;; runtime
    "cudaBindTexture"
    "cudaBindTextureToArray"
    "cudaChooseDevice"
    "cudaConfigureCall"
    "cudaCreateChannelDesc"
    "cudaD3D10GetDevice"
    "cudaD3D10MapResources"
    "cudaD3D10RegisterResource"
    "cudaD3D10ResourceGetMappedArray"
    "cudaD3D10ResourceGetMappedPitch"
    "cudaD3D10ResourceGetMappedPointer"
    "cudaD3D10ResourceGetMappedSize"
    "cudaD3D10ResourceGetSurfaceDimensions"
    "cudaD3D10ResourceSetMapFlags"
    "cudaD3D10SetDirect3DDevice"
    "cudaD3D10UnmapResources"
    "cudaD3D10UnregisterResource"
    "cudaD3D9GetDevice"
    "cudaD3D9GetDirect3DDevice"
    "cudaD3D9MapResources"
    "cudaD3D9RegisterResource"
    "cudaD3D9ResourceGetMappedArray"
    "cudaD3D9ResourceGetMappedPitch"
    "cudaD3D9ResourceGetMappedPointer"
    "cudaD3D9ResourceGetMappedSize"
    "cudaD3D9ResourceGetSurfaceDimensions"
    "cudaD3D9ResourceSetMapFlags"
    "cudaD3D9SetDirect3DDevice"
    "cudaD3D9UnmapResources"
    "cudaD3D9UnregisterResource"
    "cudaEventCreate"
    "cudaEventDestroy"
    "cudaEventElapsedTime"
    "cudaEventQuery"
    "cudaEventRecord"
    "cudaEventSynchronize"
    "cudaFree"
    "cudaFreeArray"
    "cudaFreeHost "
    "cudaGetChannelDesc"
    "cudaGetDevice"
    "cudaGetDeviceCount"
    "cudaGetDeviceProperties"
    "cudaGetErrorString"
    "cudaGetLastError"
    "cudaGetSymbolAddress"
    "cudaGetSymbolSize"
    "cudaGetTextureAlignmentOffset"
    "cudaGetTextureReference"
    "cudaGLMapBufferObject"
    "cudaGLRegisterBufferObject"
    "cudaGLSetGLDevice"
    "cudaGLUnmapBufferObject"
    "cudaGLUnregisterBufferObject"
    "cudaLaunch"
    "cudaMalloc"
    "cudaMalloc3D"
    "cudaMalloc3DArray"
    "cudaMallocArray"
    "cudaMallocHost"
    "cudaMallocPitch"
    "cudaMemcpy"
    "cudaMemcpy2D"
    "cudaMemcpy2DArrayToArray"
    "cudaMemcpy2DFromArray"
    "cudaMemcpy2DToArray"
    "cudaMemcpy3D"
    "cudaMemcpyArrayToArray"
    "cudaMemcpyFromArray"
    "cudaMemcpyFromSymbol"
    "cudaMemcpyToArray"
    "cudaMemcpyToSymbol"
    "cudaMemset"
    "cudaMemset2D"
    "cudaMemset3D"
    "cudaSetDevice"
    "cudaSetupArgument"
    "cudaStreamCreate"
    "cudaStreamDestroy"
    "cudaStreamQuery"
    "cudaStreamSynchronize"
    "cudaThreadExit"
    "cudaThreadSynchronize"
    "cudaUnbindTexture"
    ;; other
    "__syncthreads")
  "Names of built-in cuda functions.")

(defcustom cuda-font-lock-extra-types nil
  "*List of extra types to recognize in Cuda mode.
Each list item should be a regexp matching a single identifier."
  :group 'cuda-mode)

(defconst cuda-font-lock-keywords-1
  (c-lang-const c-matchers-1 cuda)
  "Minimal highlighting for CUDA mode.")

(defconst cuda-font-lock-keywords-2
  (c-lang-const c-matchers-2 cuda)
  "Fast normal highlighting for CUDA mode.")

(defconst cuda-font-lock-keywords-3
  (c-lang-const c-matchers-3 cuda)
  "Accurate normal highlighting for CUDA mode.")

;;; Not used yet. Still figuring out cc-mode.
(setq cuda-builtins-regexp (regexp-opt cuda-builtins 'symbols))
(setq cuda-builtins-regexp nil)

(defvar cuda-font-lock-keywords cuda-font-lock-keywords-3
  "Default expressions to highlight in CUDA mode.")

(defvar cuda-mode-syntax-table nil
  "Syntax table used in cuda-mode buffers.")
(or cuda-mode-syntax-table
    (setq cuda-mode-syntax-table
	  (funcall (c-lang-const c-make-mode-syntax-table cuda))))

(defvar cuda-mode-abbrev-table nil
  "Abbreviation table used in cuda-mode buffers.")

(c-define-abbrev-table 'cuda-mode-abbrev-table
  ;; Keywords that if they occur first on a line might alter the
  ;; syntactic context, and which therefore should trig reindentation
  ;; when they are completed.
  '(("else" "else" c-electric-continued-statement 0)
    ("while" "while" c-electric-continued-statement 0)))

(defvar cuda-mode-map (let ((map (c-make-inherited-keymap)))
			;; Add bindings which are only useful for CUDA
			map)
  "Keymap used in cuda-mode buffers.")

(easy-menu-define cuda-menu cuda-mode-map "CUDA Mode Commands"
  ;; Can use `cuda' as the language for `c-mode-menu'
  ;; since its definition covers any language.  In
  ;; this case the language is used to adapt to the
  ;; nonexistence of a cpp pass and thus removing some
  ;; irrelevant menu alternatives.
  (cons "CUDA" (c-lang-const c-mode-menu cuda)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.cu\\'" . cuda-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.cuh\\'" . cuda-mode))

;;;###autoload
(defun cuda-mode ()
  "Major mode for editing CUDA.
Cuda is a C like language extension for mixed native/GPU coding
created by NVIDIA

The hook `c-mode-common-hook' is run with no args at mode
initialization, then `cuda-mode-hook'.

Key bindings:
\\{cuda-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (c-initialize-cc-mode t)
  (set-syntax-table cuda-mode-syntax-table)
  (setq major-mode 'cuda-mode
        mode-name "Cuda"
        local-abbrev-table cuda-mode-abbrev-table
        abbrev-mode t)
  (use-local-map c-mode-map)
  ;; `c-init-language-vars' is a macro that is expanded at compile
  ;; time to a large `setq' with all the language variables and their
  ;; customized values for our language.
  (c-init-language-vars cuda-mode)
  ;; `c-common-init' initializes most of the components of a CC Mode
  ;; buffer, including setup of the mode menu, font-lock, etc.
  ;; There's also a lower level routine `c-basic-common-init' that
  ;; only makes the necessary initialization to get the syntactic
  ;; analysis and similar things working.
  (c-common-init 'cuda-mode)
  (easy-menu-add cuda-menu)
  (run-hooks 'c-mode-common-hook)
  (run-hooks 'cuda-mode-hook)
  (setq font-lock-keywords-case-fold-search t)
  (c-update-modeline))

(provide 'cuda-mode)
;;; cuda-mode.el ends here
