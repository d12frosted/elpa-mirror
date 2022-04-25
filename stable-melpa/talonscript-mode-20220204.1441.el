;;; talonscript-mode.el --- Major mode for Talon Voice's .talon files  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Jcaw

;; Author: Jcaw <toastedjcaw@gmail.com>
;; Keywords: languages
;; Package-Version: 20220204.1441
;; Package-Commit: b6eb61f56349e0d47276270163ec611c2d5b188e
;; Version: 1.0.0
;; URL: https://github.com/jcaw/talonscript-mode
;; Package-Requires: ((emacs "24.3"))

;; This program is free software; you can redistribute it and/or modify
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

;; Major mode for editing Talon Voice's .talon files.

;; Does what it says on the tin. This isn't a big mode, it just covers the
;; basics - adds syntax highlighting and defines comment syntax.

;;; Code:


(defconst talonscript-font-lock-definitions
  (list
   ;; Matches speech commands at the start of a line, but NOT actions.
   ;; Excludes actions by disallowing parens next to letters.
   ;;
   ;; It's difficult to stop this highlighting left-hand expressions before the
   ;; divider (-). It's easier to let it highlight those with the same format,
   ;; so we tolerate variable syntax too.
   (cons "^\\(\\^?[(]?\\([]a-z-A-Z0-9[<>{} ._|)]\\|\\([^-a-zA-Z0-9_](\\)\\)*\\)[$]?[ \t]*:"
         '(1 font-lock-function-name-face))

   ;; Matches the start & end anchors (^ and $)
   ;;
   ;; FIXME: This will also highlight $ and ^ in keypresses.
   (cons "[$^]" '(0 font-lock-type-face t))

   ;; Matches variables in spoken form - doesn't match them elsewhere
   ;;
   ;; TODO: Match all occurrences of the variable.
   (cons "<\\([-a-zA-Z0-9_.]*\\)>" '(0 font-lock-constant-face t))

   ;; Matches references to variables in strings (and lists on left-hand side).
   (cons "{\\([-a-zA-Z0-9_.]*\\)}" '(0 font-lock-constant-face t))

   ;; Matches keys that are function calls, e.g will match "action" in:
   ;; action(edit.zoom_in): key(ctrl-+)
   (cons "^\\([a-zA-Z0-9_-.]*\\)(" '(1 font-lock-type-face t))

   ;; Matches function references
   ;; (cons "\\(\\([-a-zA-Z0-9_](\\)\\|:\\)[ \t]*\\([-a-zA-Z0-9_.]+\\)"
   ;;       '(3 font-lock-keyword-face t))

   ;; Matches stuff inside an action binding.
   ;; (cons "^[-a-zA-Z0-9_]+(\\([-a-zA-Z0-9_.]*\\))"
   ;;       '(1 font-lock-variable-name-face t))

   ;; Matches the context/bindings divider
   (cons "^-+" 'font-lock-keyword-face)

   ;; Matches all keywords defined by tup/keywords-regexp.
   ;;
   ;; TODO: Audit keywords - do we want to highlight any?
   ;;
   ;; Built-in namespaces:
   ;;
   ;; '("core" "dictate" "edit" "code" "app" "win" "browser" "speech")
   ;;
   ;; (cons talonscript-keywords-regexp font-lock-keyword-face)
   )
  "A map of regular expressions to font-lock faces.")


;;;###autoload
(define-derived-mode talonscript-mode prog-mode "TalonScript"
  "Major mode for editing .talon files (for Talon Voice).

.talon commands are used to register commands for Talon's speech
recognition."

  ;; syntax highlighting
  (setq-local font-lock-defaults '(talonscript-font-lock-definitions nil t))
  (setq-local require-final-newline t)
  (modify-syntax-entry ?# "<" talonscript-mode-syntax-table)
  (modify-syntax-entry ?\n ">" talonscript-mode-syntax-table)
  (setq-local comment-start "# ")
  (setq-local comment-start-skip "#+[\t ]*")
  ;; TODO: Convenient indentation
  ;; (setq-local indent-line-function 'talonscript-toggle-indent)
  )


;;;###autoload
(add-to-list 'auto-mode-alist '("\\.talon\\'" . talonscript-mode))


(provide 'talonscript-mode)
;;; talonscript-mode.el ends here
