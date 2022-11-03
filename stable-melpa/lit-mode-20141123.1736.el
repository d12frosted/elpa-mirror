;;; lit-mode.el --- Major mode for lit

;; Copyright (C) 2014 Hector A Escobedo

;; Author: Hector A Escobedo <ninjahector.escobedo@gmail.com>
;; Keywords: languages, tools
;; Version: 0.1.1

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

;; This is a major mode to support using lit:
;; <https://github.com/cdosborn/lit>. Could be very useful combined
;; with polymode. Markdown support is planned. I also plan to add
;; console integration support, so for example C-c C-c would run 'lit
;; -c <file>' and something else 'lit -m <file>'.

;;; Code:

(defgroup lit nil
  "Major mode for editing lit literate source files"
  :group 'languages
  :prefix "lit-")

;; lit grammar regexes
;; Actually a very simple grammar

(defconst lit-macro-delimiters-rx
  (rx (or "<<" ">>" ">>=")))

(defconst lit-macro-definition-rx
  (rx "<<" (1+ blank) (group-n 1 (minimal-match (1+ (not (any ?> ))))) (1+ blank) ">>=" eol))

(defconst lit-macro-reference-rx
  (rx "<<" (1+ blank) (group-n 1 (minimal-match (1+ (not (any ?> ))))) (1+ blank) ">>" eol))

;; The narrative is anything that isn't indented at all.
;; In other words, not part of a macro or macro reference.
(defconst lit-narrative-rx
  (rx bol (not (syntax whitespace)) (0+ not-newline)))

;; Font-lock data for syntax highlighting
(defconst lit-font-lock-defaults
  `((
     ( ,lit-narrative-rx . font-lock-doc-face)
     ( ,lit-macro-delimiters-rx . font-lock-keyword-face)
     ( ,lit-macro-definition-rx 1 font-lock-variable-name-face)
     ( ,lit-macro-reference-rx 1 font-lock-variable-name-face)
     ))
  "Basic lit syntax.")

(defvar lit-mode-tab-width 8
  "Standard tab width for lit.
Set to nil to disable so you can use a custom width.")

;; Derives from text-mode to prevent string highlighting
(define-derived-mode lit-mode text-mode "lit"
  "Major mode for editing lit literate source files."
  (setq font-lock-defaults lit-font-lock-defaults)
  (when lit-mode-tab-width
    (setq tab-width lit-mode-tab-width)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.lit$" . lit-mode))

(provide 'lit-mode)
;;; lit-mode.el ends here

;; Local variables:
;; comment-column: 32
;; End:
