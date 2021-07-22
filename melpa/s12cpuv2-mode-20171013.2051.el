;;; s12cpuv2-mode.el --- Major-mode for S12CPUV2 assembly -*- lexical-binding: t -*-

;; Copyright 2017 Adam Niederer.

;; Author: Adam Niederer <adam.niederer@gmail.com>
;; URL: https://github.com/AdamNiederer/s12cpuv2-mode
;; Package-Version: 20171013.2051
;; Package-Commit: b17d4cf848dec1e20e66458e5c7ff77a2c051a8c
;; Version: 0.1
;; Keywords: s12cpuv2 assembly languages
;; Package-Requires: ((emacs "24.3"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode for S12CPUV2 Assembly

;;; Code:

(defgroup s12cpuv2 nil
  "Major mode for editing S12CPUV2 microcontroller assembly"
  :prefix "s12cpuv2-"
  :group 'languages
  :link '(url-link :tag "Github" "https://github.com/AdamNiederer/s12cpuv2-mode")
  :link '(emacs-commentary-link :tag "Commentary" "s12cpuv2-mode"))

(defconst s12cpuv2-instructions
  '("ABA" "ABX" "ABY" "ADCA" "ADCB" "ADDA" "ADDB" "ADDD" "ADDR" "ANDA" "ANDB"
    "ANDCC" "ASL" "ASLA" "ASLB" "ASLD" "ASR" "ASRA" "ASRB" "BCC" "BCD" "BCLR"
    "BCS" "BEQ" "BGE" "BGNT" "BGT" "BHI" "BHS" "BITA" "BITB" "BLE" "BLO" "BLS"
    "BLT" "BMI" "BNE" "BPL" "BRA" "BRCLR" "BRN" "BRSET" "BSET" "BSR" "BVC" "BVS"
    "CALL" "CBA" "CCR" "CLC" "CLI" "CLR" "CLRA" "CLRB" "CLV" "CMPA" "CMPB" "COM"
    "COMA" "COMB" "COP" "CPD" "CPS" "CPX" "CPY" "DAA" "DBEQ" "DBNE" "DEC" "DECA"
    "DECB" "DES" "DEX" "DEY" "EDIV" "EDIVS" "EMACS" "EMAXD" "EMAXM" "EMIND"
    "EMINM" "EMUL" "EMULS" "EORA" "EORB" "ETLB" "EXG" "FDIV" "IBEQ" "IBNE"
    "IDIV" "IDIVS" "INC" "INCA" "INCB" "INS" "INX" "INY" "JMP" "JSR" "LBCC"
    "LBCS" "LBEQ" "LBGE" "LBGT" "LBHI" "LBHS" "LBLE" "LBLO" "LBLS" "LBLT" "LBMI"
    "LBNE" "LBPL" "LBRA" "LBRN" "LBVC" "LBVS" "LDAA" "LDAB" "LDD" "LDS" "LDX"
    "LDY" "LEAS" "LEAX" "LEAY" "LSL" "LSLA" "LSLB" "LSLD" "LSR" "LSRA" "LSRB"
    "LSRD" "MAXA" "MAXM" "MEM" "MINA" "MINM" "MOVB" "MOVW" "MUL" "NEG" "NEGA"
    "NEGB" "NOP" "ORAA" "ORAB" "ORCC" "PSHA" "PSHB" "PSHC" "PSHD" "PSHX" "PSHY"
    "PULA" "PULB" "PULC" "PULD" "PULX" "PULY" "REV" "REVW" "ROL" "ROLA" "ROLB"
    "ROR" "RORA" "RORB" "RTC" "RTI" "RTS" "SBA" "SBCA" "SBCB" "SEC" "SEI" "SEV"
    "SEX" "STAA" "STAB" "STD" "STOP" "STX" "STY" "SUBA" "SUBB" "SUBD" "SWI"
    "TAB" "TAP" "TBA" "TBEQ" "TBL" "TBNE" "TFR" "TPA" "TRAP" "TST" "TSTA" "TSTB"
    "TSX" "TSY" "TXS" "TYS" "WAI" "WAV" "XGDX" "XGDY"

    "aba" "abx" "aby" "adca" "adcb" "adda" "addb" "addd" "addr" "anda" "andb"
    "andcc" "asl" "asla" "aslb" "asld" "asr" "asra" "asrb" "bcc" "bcd" "bclr"
    "bcs" "beq" "bge" "bgnt" "bgt" "bhi" "bhs" "bita" "bitb" "ble" "blo" "bls"
    "blt" "bmi" "bne" "bpl" "bra" "brclr" "brn" "brset" "bset" "bsr" "bvc" "bvs"
    "call" "cba" "ccr" "clc" "cli" "clr" "clra" "clrb" "clv" "cmpa" "cmpb" "com"
    "coma" "comb" "cop" "cpd" "cps" "cpx" "cpy" "daa" "dbeq" "dbne" "dec" "deca"
    "decb" "des" "dex" "dey" "ediv" "edivs" "emacs" "emaxd" "emaxm" "emind"
    "eminm" "emul" "emuls" "eora" "eorb" "etlb" "exg" "fdiv" "ibeq" "ibne"
    "idiv" "idivs" "inc" "inca" "incb" "ins" "inx" "iny" "jmp" "jsr" "lbcc"
    "lbcs" "lbeq" "lbge" "lbgt" "lbhi" "lbhs" "lble" "lblo" "lbls" "lblt" "lbmi"
    "lbne" "lbpl" "lbra" "lbrn" "lbvc" "lbvs" "ldaa" "ldab" "ldd" "lds" "ldx"
    "ldy" "leas" "leax" "leay" "lsl" "lsla" "lslb" "lsld" "lsr" "lsra" "lsrb"
    "lsrd" "maxa" "maxm" "mem" "mina" "minm" "movb" "movw" "mul" "neg" "nega"
    "negb" "nop" "oraa" "orab" "orcc" "psha" "pshb" "pshc" "pshd" "pshx" "pshy"
    "pula" "pulb" "pulc" "puld" "pulx" "puly" "rev" "revw" "rol" "rola" "rolb"
    "ror" "rora" "rorb" "rtc" "rti" "rts" "sba" "sbca" "sbcb" "sec" "sei" "sev"
    "sex" "staa" "stab" "std" "stop" "stx" "sty" "suba" "subb" "subd" "swi"
    "tab" "tap" "tba" "tbeq" "tbl" "tbne" "tfr" "tpa" "trap" "tst" "tsta" "tstb"
    "tsx" "tsy" "txs" "tys" "wai" "wav" "xgdx" "xgdy"))

(defconst s12cpuv2-ops
  '("ABSENTRY"
    "ORG" ".ORG"
    "EQU" "SET"
    "DC.B" "DB" "FCB" ".BYTE"
    "FCC"
    "DC.W" "DW" "FDB" ".WORD"
    "DC.L" "DL" ".LONG"
    "DS" "DS.B" "RMB" ".BLKB"
    "DS.W" ".BLKW"
    "DS.L" ".BLKL"
    "END" ".END"
    "XDEF"

    "absentry"
    "org" ".org"
    "equ" "set"
    "dc.b" "db" "fcb" ".byte"
    "fcc"
    "dc.w" "dw" "fdb" ".word"
    "dc.l" "dl" ".long"
    "ds" "ds.b" "rmb" ".blkb"
    "ds.w" ".blkw"
    "ds.l" ".blkl"
    "end" ".end"
    "xdef"))

(defconst s12cpuv2-registers
  '("A" "B" "D" "SP" "X" "Y" "PC" "C"
    "a" "b" "d" "sp" "x" "y" "pc" "c"))

(defconst s12cpuv2-label-re
  "^[a-zA-Z0-9_$.]+:?")

(defconst s12cpuv2-empty-label-re
  (concat s12cpuv2-label-re " *$"))

(defconst s12cpuv2-instruction-re
  (regexp-opt s12cpuv2-instructions 'words))

(defconst s12cpuv2-register-re
  (regexp-opt s12cpuv2-instructions 'words))

(defconst s12cpuv2-ops-re
  (regexp-opt s12cpuv2-ops 'words))

(defconst s12cpuv2-font-lock-defaults
  `((;; labels
     (,s12cpuv2-label-re . font-lock-function-name-face)
     ;; Instructions and operations
     (,s12cpuv2-instruction-re . font-lock-keyword-face)
     (,s12cpuv2-ops-re . font-lock-keyword-face)
     ;; registers
     (,s12cpuv2-register-re . font-lock-variable-name-face))))

(defcustom s12cpuv2-tab-width 16
  "Width of a tab for S12CPUV2 mode."
  :tag "Tab width"
  :group 's12cpuv2
  :type 'integer)

(defvar s12cpuv2-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "<backtab>") 's12cpuv2-dedent)
    (define-key map (kbd "C-c C-l") 's12cpuv2-goto-label-at-cursor)
    (define-key map (kbd "C-c C-k") 's12cpuv2-goto-label)
    map)
  "Keymap for s12cpuv2-mode.")

(defun s12cpuv2-indent ()
  "Indent the current line according to `s12cpuv2-tab-width'."
  (interactive)
  (cond
   ;; Line consists solely of a label
   ((string-match-p s12cpuv2-empty-label-re (buffer-substring (point-at-bol) (point-at-eol)))
    (end-of-line)
    (let ((instr-space-delta (- (point) (point-at-bol) 16)))
      (if (> instr-space-delta 0)
            (delete-char (- instr-space-delta))
        (insert (make-string (- instr-space-delta) ?\s)))))
   ;; Line is of the form INSTR ARGS COMMENT?
   ((string-match-p (regexp-opt (append s12cpuv2-ops s12cpuv2-instructions) 'words)
                    (buffer-substring (point-at-bol)
                                      (save-excursion
                                        (beginning-of-line)
                                        (forward-word)
                                        (point))))
    (indent-line-to s12cpuv2-tab-width))
   ;; Line is of the form LABEL INSTR ARGS COMMENT?
   ((string-match-p s12cpuv2-label-re
                    (buffer-substring (point-at-bol)
                       (save-excursion
                         (beginning-of-line)
                         (forward-word)
                         (point))))
    (indent-line-to 0)
    (save-excursion
      ;; Align instruction to `s12cpuv2-tab-width' characters
      (beginning-of-line)
      (re-search-forward s12cpuv2-instruction-re)
      (backward-word)
      (let ((instr-space-delta (- (point) (point-at-bol) 16)))
        (if (> instr-space-delta 0)
            (delete-char (- instr-space-delta))
          (insert (make-string (- instr-space-delta) ?\s))))))
   ;; Line is in a large block of instructions
   ((string-match-p s12cpuv2-instruction-re
                    (buffer-substring (save-excursion
                                        (forward-line -1)
                                        (point-at-bol))
                                      (save-excursion
                                        (forward-line -1)
                                        (point-at-eol))))
    (indent-line-to s12cpuv2-tab-width))
   (t (indent-line-to 0))))

(defun s12cpuv2-dedent ()
  "Dedent the current line."
  (interactive)
  (indent-line-to 0))

(defun s12cpuv2-goto-label (&optional label)
  "Go to the definition of LABEL."
  (interactive)
  (let ((label (or label (read-minibuffer "Go to Label: "))))
    (goto-char (point-min))
    (re-search-forward (format "^%s " label))))

(defun s12cpuv2-goto-label-at-cursor ()
  "Go to the definition of the label under point."
  (interactive)
  (s12cpuv2-goto-label (symbol-at-point)))

;;;###autoload
(define-derived-mode s12cpuv2-mode prog-mode "S12CPUV2"
  "Major mode for editing S12CPUV2 assembler code."

  (setq-local font-lock-defaults s12cpuv2-font-lock-defaults)
  (when s12cpuv2-tab-width
    (setq-local tab-width s12cpuv2-tab-width))

  (setq-local comment-start ";")
  (setq-local comment-end "")
  (setq-local indent-line-function 's12cpuv2-indent)

  (modify-syntax-entry ?' "\"" s12cpuv2-mode-syntax-table)
  (modify-syntax-entry ?\; "< b" s12cpuv2-mode-syntax-table)
  (modify-syntax-entry ?* "< b" s12cpuv2-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" s12cpuv2-mode-syntax-table))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.s12cpuv2\\'" . s12cpuv2-mode))

(provide 's12cpuv2-mode)
;;; s12cpuv2-mode.el ends here
