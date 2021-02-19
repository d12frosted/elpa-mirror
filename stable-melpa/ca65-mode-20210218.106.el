;;; ca65-mode.el --- Major mode for ca65 assembly files      -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Wendel Scardua

;; Author: Wendel Scardua <wendel@scardua.net>
;; Keywords: languages, assembly, ca65, 6502
;; Package-Version: 20210218.106
;; Package-Commit: 590d90cc0e1c1864dd7ce03df99b741ba866d52a
;; Version: 0.3.3
;; Homepage: https://github.com/wendelscardua/ca65-mode
;; Package-Requires: ((emacs "26.1"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU Affero General Public License
;; as published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU Affero General Public
;; License along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides font-locking and indentation support to ca65 assembly files.

;;; Code:

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.s\\'" . ca65-mode))
(add-to-list 'auto-mode-alist '("\\.inc\\'" . ca65-mode))

(defconst ca65-font-lock-keywords-1
  (list
   ;; upper case instructions
   '("\\<\\(A\\(?:DC\\|ND\\|SL\\)\\|B\\(?:C[CS]\\|EQ\\|IT\\|MI\\|NE\\|PL\\|RK\\|V[CS]\\)\\|C\\(?:L[CDIV]\\|MP\\|P[XY]\\)\\|DE[CXY]\\|EOR\\|IN[CXY]\\|J\\(?:MP\\|SR\\)\\|L\\(?:D[AXY]\\|SR\\)\\|NOP\\|ORA\\|P\\(?:H[AP]\\|L[AP]\\)\\|R\\(?:O[LR]\\|T[IS]\\)\\|S\\(?:BC\\|E[CDI]\\|T[AXY]\\)\\|T\\(?:A[XY]\\|SX\\|X[AS]\\|YA\\)\\)\\>" . font-lock-keyword-face)
   ;; lower case instructions
   '("\\<\\(a\\(?:dc\\|nd\\|sl\\)\\|b\\(?:c[cs]\\|eq\\|it\\|mi\\|ne\\|pl\\|rk\\|v[cs]\\)\\|c\\(?:l[cdiv]\\|mp\\|p[xy]\\)\\|de[cxy]\\|eor\\|in[cxy]\\|j\\(?:mp\\|sr\\)\\|l\\(?:d[axy]\\|sr\\)\\|nop\\|ora\\|p\\(?:h[ap]\\|l[ap]\\)\\|r\\(?:o[lr]\\|t[is]\\)\\|s\\(?:bc\\|e[cdi]\\|t[axy]\\)\\|t\\(?:a[xy]\\|sx\\|x[as]\\|ya\\)\\)\\>" . font-lock-keyword-face)
   ;; things like .proc, .ifdef
   '("\\.\\w+\\>" . font-lock-preprocessor-face)
   ;; X, Y registers
   '("\\<[XY]\\>" . font-lock-keyword-face)
   ;; constants like PPUDATA
   '("\\<[A-Z_][A-Z_]*\\>" . font-lock-constant-face)
   ;; labels
   '("^[ \t]*@?\\w**:" . font-lock-type-face)
   ;; prefix stuff, like #42, #%00101010, #<address
   '("[#$%<>]+" . font-lock-type-face)
   ;; relative label references, like :-, :++
   '(":[+-]+" . font-lock-type-face)
   ;; usage of labels (as addresses, variables, functions),
   ;; like JSR FamiToneInit or LDA foobar, X
   '("\\<[A-Za-z_][A-Za-z0-9_]*\\>" . font-lock-variable-name-face))
  "Highlighting for ca65 mode.")

(defvar ca65-font-lock-keywords ca65-font-lock-keywords-1
  "Default highlight expressions for ca65 mode.")

;; Indent rules:
;; 1. At start of buffer, indent 0
;; 2. at .end*, decrease indent
;; 3. if before we have an .end*, use that line's indent
;; 4. if before we have a .proc, .if*, .scope, .enum, .struct, increase indent
;; 5. labels use zero indent
;; 6. if using line continuation (\), indent the next line on last space except the one next to \
;; 7. ignore indent otherwise
;; 8. exception: empty label ':' is treated like space for indent purposes
(defun ca65-indent-line ()
  "Indent current line as ca65 code."
  (interactive)
  (beginning-of-line)
  (if (bobp) ;; rule 1
      (indent-line-to 0)
    (if (looking-at "^[ \t]*@?\\w+:") ;; rule 5
        (indent-line-to 0)
      (let ((not-indented t) cur-indent)
        (if (looking-at "^[ \t]*[.]\\(else\\|end\\)") ;; rule 2
            (progn
              (save-excursion
                (while not-indented
                  (forward-line -1)
                  (if (or (bobp)
                          (not (looking-at "^[ \t]*@?\\w*:")))
                      (setq not-indented nil)))
                (setq cur-indent (- (current-indentation) tab-width))
                (if (< cur-indent 0)
                    (setq cur-indent 0))))
          (progn
            (save-excursion
              (forward-line -1)
              (if (looking-at ".*\\\\ *\n") ;; rule 7
                  (progn
                    (string-match " [^ ]* ?\\\\" (thing-at-point 'line t))
                    (setq cur-indent (+ 1 (match-beginning 0)))
                    (setq not-indented nil))))
            (save-excursion
              (while not-indented
                (forward-line -1)
                (if (looking-at "^[ \t]*[.]end") ;; rule 3
                    (progn
                      (setq cur-indent (current-indentation))
                      (setq not-indented nil))
                  ;; rule 4
                  (if (looking-at "^[ \t]*[.]\\(enum\\>\\|else\\>\\|if\\|mac\\>\\|macro\\>\\|proc\\>\\|repeat\\>\\|scope\\>\\|struct\\>\\)")
                      (progn
                        (setq cur-indent (+ (current-indentation) tab-width))
                        (setq not-indented nil))
                    (if (bobp) ;; rule 7
                        (setq not-indented nil))))))))
        (if cur-indent
            (if (looking-at "^[ \t]*:.+\n") ;; rule 8
                (progn
                  (re-search-forward "^[ \t]*:" nil t)
                  (replace-match " ")
                  (beginning-of-line)
                  (indent-line-to cur-indent)
                  (beginning-of-line)
                  (if (looking-at " ")
                      (progn
                        (delete-char 1)
                        (insert ":")
                        (beginning-of-line))))
              (if (looking-at "^[ \t]*:")
                  (indent-line-to 0)
                (indent-line-to cur-indent)))
          (indent-line-to 0))))))

;;;###autoload
(define-derived-mode ca65-mode prog-mode "ca65"
  "Major mode for editing ca65 assembly files."
  (setq-local font-lock-defaults `(ca65-font-lock-keywords))
  (setq-local indent-line-function #'ca65-indent-line)
  (setq-local comment-start ";")
  (setq-local comment-end ";")
  (modify-syntax-entry ?_ "w" ca65-mode-syntax-table)
  (modify-syntax-entry ?# "w" ca65-mode-syntax-table)
  (modify-syntax-entry ?$ "w" ca65-mode-syntax-table)
  (modify-syntax-entry ?% "w" ca65-mode-syntax-table)
  (modify-syntax-entry ?\; "<" ca65-mode-syntax-table)
  (modify-syntax-entry ?\n ">" ca65-mode-syntax-table)
  (modify-syntax-entry ?\" "\"" ca65-mode-syntax-table)
  (modify-syntax-entry ?\' "'" ca65-mode-syntax-table))

(provide 'ca65-mode)
;;; ca65-mode.el ends here
