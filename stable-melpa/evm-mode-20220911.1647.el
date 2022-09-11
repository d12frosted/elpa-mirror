;;; evm-mode.el --- Major mode for editing Ethereum EVM bytecode

;; Copyright © 2022, by Ta Quang Trung

;; Author: Ta Quang Trung
;; Version: 0.0.1
;; Package-Version: 20220911.1647
;; Package-Commit: 422b65cfd04854072bf6b9238c49e3d40577ef98
;; Created: 29 April 2022
;; Keywords: languages
;; Homepage: https://github.com/taquangtrung/emacs-evm-mode

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

;; Emacs major mode for editing Ethereum EVM bytecode.

;; Features:
;; - Syntax highlight for EVM bytecode.
;; - Code outline (labels and blocks) via Imenu.

;; Installation:
;; - Automatic package installation from Melpa.
;; - Manual installation by putting the `evm-mode.el' file in Emacs' load path.

;;; Code:

(require 'rx)
(require 'imenu)

(defconst evm-opcodes
  '("add"
    "addmod"
    "address"
    "and"
    "balance"
    "basefee"
    "blockhash"
    "byte"
    "call"
    "callcode"
    "calldatacopy"
    "calldataload"
    "calldatasize"
    "caller"
    "callvalue"
    "chainid"
    "codecopy"
    "codesize"
    "coinbase"
    "create"
    "create2"
    "delegatecall"
    "difficulty"
    "div"
    "dup1"
    "dup10"
    "dup11"
    "dup12"
    "dup13"
    "dup14"
    "dup15"
    "dup16"
    "dup2"
    "dup3"
    "dup4"
    "dup5"
    "dup6"
    "dup7"
    "dup8"
    "dup9"
    "eq"
    "exp"
    "extcodecopy"
    "extcodehash"
    "extcodesize"
    "gas"
    "gaslimit"
    "gasprice"
    "gt"
    "invalid"
    "iszero"
    "jump"
    "jumpdest"
    "jumpi"
    "keccak256"
    "log0"
    "log1"
    "log2"
    "log3"
    "log4"
    "lt"
    "mload"
    "mod"
    "msize"
    "mstore"
    "mstore8"
    "mul"
    "mulmod"
    "not"
    "number"
    "or"
    "origin"
    "pc"
    "pop"
    "push1"
    "push10"
    "push11"
    "push12"
    "push13"
    "push14"
    "push15"
    "push16"
    "push17"
    "push18"
    "push19"
    "push2"
    "push20"
    "push21"
    "push22"
    "push23"
    "push24"
    "push25"
    "push26"
    "push27"
    "push28"
    "push29"
    "push3"
    "push30"
    "push31"
    "push32"
    "push4"
    "push5"
    "push6"
    "push7"
    "push8"
    "push9"
    "return"
    "returndatacopy"
    "returndatasize"
    "revert"
    "sar"
    "sdiv"
    "selfbalance"
    "selfdestruct"
    "sgt"
    "sha3"
    "shl"
    "shr"
    "signextend"
    "sload"
    "slt"
    "smod"
    "sstore"
    "staticcall"
    "stop"
    "sub"
    "swap1"
    "swap10"
    "swap11"
    "swap12"
    "swap13"
    "swap14"
    "swap15"
    "swap16"
    "swap2"
    "swap3"
    "swap4"
    "swap5"
    "swap6"
    "swap7"
    "swap8"
    "swap9"
    "timestamp"
    "xor")
  "List of EVM opcodes.")

(defconst evm-non-opcode-keywords
  '("assembly")
  "List of EVM non-opcode keywords.")

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Syntax highlighting

(defvar evm-syntax-table
  (let ((syntax-table (make-syntax-table)))
    ;; C++ style comment "// ..."
    (modify-syntax-entry ?\/ ". 124" syntax-table)
    (modify-syntax-entry ?* ". 23b" syntax-table)
    (modify-syntax-entry ?\n ">" syntax-table)
    syntax-table)
  "Syntax table for `evm-mode'.")

(defvar evm-opcode-regexp
  (concat
   (rx symbol-start)
   (regexp-opt evm-opcodes t)
   (rx symbol-end))
  "Regular expression to match EVM opcodes.")

(defvar evm-non-opcode-keyword-regexp
  (concat
   (rx symbol-start)
   (regexp-opt evm-non-opcode-keywords t)
   (rx symbol-end))
  "Regular expression to match EVM non-opcode keywords.")

(defun evm--match-regexp (re limit)
  "Generic regular expression matching wrapper for RE with a given LIMIT."
  (re-search-forward re
                     limit ; search bound
                     t     ; no error, return nil
                     nil   ; do not repeat
                     ))

(defun evm--match-functions (limit)
  "Search the buffer forward until LIMIT matching function names.
Highlight the 1st result."
  (evm--match-regexp
   (concat
    " *\\([a-zA-Z0-9_]+\\) *\(")
   limit))

(defconst evm-font-lock-keywords
  (list
   `(,evm-opcode-regexp . font-lock-keyword-face)
   `(,evm-non-opcode-keyword-regexp . font-lock-keyword-face)
   '(evm--match-functions (1 font-lock-function-name-face)))
  "Font lock keywords of `evm-mode'.")

;;;;;;;;;;;;;;;;;;;;;
;;; Imenu settings

(defvar evm--imenu-generic-expression
  '(("Block"
     "^\\s-*\\([a-zA-Z0-9_']+\\):\\s-*assembly\\s-*\{"
     1)
    ("Label"
     "^\\s-*\\([a-zA-Z0-9_']+\\):\\s-*$"
     1))
  "Regular expression to generate Imenu outline.")

(defun evm--imenu-create-index ()
  "Generate outline of EVM bytecode for imenu-mode."
  (save-excursion
    (imenu--generic-function evm--imenu-generic-expression)))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Major mode settings

;;;###autoload
(define-derived-mode evm-mode prog-mode
  "evm-mode"
  "Major mode for editing Ethereum EVM bytecode."
  :syntax-table evm-syntax-table

  ;; Syntax highlighting
  (setq font-lock-defaults '(evm-font-lock-keywords))

  ;; Indentation
  (set (make-local-variable 'indent-tabs-mode) nil)
  (set (make-local-variable 'indent-line-function) 'indent-relative)

  ;; Set comment command
  (set (make-local-variable 'comment-start) "//")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'comment-multi-line) nil)
  (set (make-local-variable 'comment-use-syntax) t)

  ;; Configure imenu
  (set (make-local-variable 'imenu-create-index-function)
       'evm--imenu-create-index))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.evm\\'" . evm-mode))

;; Finally export the `evm-mode'
(provide 'evm-mode)

;; Local Variables:
;; coding: utf-8
;; End:

;;; evm-mode.el ends here
