;;; highlight-function-calls.el --- Highlight function/macro calls  -*- lexical-binding: t; -*-

;; Author: Adam Porter <adam@alphapapa.net>
;; Url: http://github.com/alphapapa/highlight-function-calls
;; Package-Version: 20230416.445
;; Package-Commit: e2ed2da188aea5879b59ffffefdc5eca10e7ba83
;; Version: 0.1-pre
;; Package-Requires: ((emacs "24.4"))
;; Keywords: faces, highlighting

;;; Commentary:

;; This package highlights function symbols in function calls.  This
;; makes them stand out from other symbols, which makes it easy to see
;; where calls to other functions are.  Optionally, macros and special
;; forms can be highlighted as well.  Also, a list of symbols can be
;; excluded from highlighting; by default, ones like +/-, </>, error,
;; require, etc. are excluded.  Finally, the `not' function can be
;; highlighted specially.

;; Just run `highlight-function-calls-mode' to activate, or you can
;; add that to your `emacs-lisp-mode-hook' to do it automatically.

;;; License:

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

;;; Code:

(defgroup highlight-function-calls nil
  "Options for highlighting function/macro calls and special forms."
  :group 'faces)

(defface highlight-function-calls-face
  '((t (:underline t)))
  "Face for highlighting function calls."
  :group 'highlight-function-calls)

(defface highlight-function-calls--not-face
  '((t (:inherit font-lock-negation-char-face)))
  "Face for highlighting `not'."
  :group 'highlight-function-calls)

(defcustom highlight-function-calls-exclude-symbols
  '(
    =
    +
    -
    /
    *
    <
    >
    <=
    >=
    debug  ; Not intended as an interactive function
    error
    provide
    require
    signal
    throw
    user-error
    )
  "List of symbols to not highlight."
  :type '(repeat symbol))

(defcustom highlight-function-calls-macro-calls nil
  "Whether to highlight macro calls."
  :type 'boolean)

(defcustom highlight-function-calls-special-forms nil
  "Whether to highlight special-forms calls."
  :type 'boolean)

(defcustom highlight-function-calls-not nil
  "Whether to highlight `not'."
  :type 'boolean)

(defconst highlight-function-calls--keywords
  '((
     ;; First we match an opening paren, which prevents matching
     ;; function names as arguments.  We also avoid matching opening
     ;; parens immediately after quotes.

     ;; FIXME: This does not avoid matching opening parens in quoted
     ;; lists. I don't know if we can fix this, because `syntax-ppss'
     ;; doesn't give any information about this.  It might require
     ;; using semantic, which we probably don't want to mess with.

     ;; FIXME: It also doesn't avoid matching, e.g. the `map' in "(let
     ;; ((map".  I'm not sure why.
     "\\(?:^\\|[[:space:]]+\\|,\\)("  ; (rx (or bol (1+ space) ",") "(")

     ;; NOTE: The (0 nil) is required, although I don't understand
     ;; exactly why.  This was confusing enough, following the
     ;; docstring for `font-lock-add-keywords'.
     (0 nil)

     ;; Now we use a HIGHLIGHT MATCH-ANCHORED form to match the symbol
     ;; after the paren.  We call the `highlight-function-calls--matcher'
     ;; function to test whether the face should be applied.  We use a
     ;; PRE-MATCH-FORM to return a position at the end of the symbol,
     ;; which prevents matching function name symbols later on the
     ;; line, but we must not move the point in the process.  We do
     ;; not use a POST-MATCH-FORM.  Then we use the MATCH-HIGHLIGHT
     ;; form to highlight group 0, which is the whole symbol, we apply
     ;; the `highlight-function-calls-face' face, and we `prepend' it so
     ;; that it overrides existing faces; this way we even work with,
     ;; e.g. `rainbow-identifiers-mode', but only if we're activated
     ;; last.
     (highlight-function-calls--matcher
      (save-excursion
        (forward-symbol 1)
        (point))
      nil
      (0 highlight-function-calls--face-name prepend))))
  "Keywords argument for `font-lock-add-keywords'.")

(defvar highlight-function-calls--face-name nil)

(defun highlight-function-calls--matcher (end)
  "The matcher function to be used by font lock mode."
  (setq end (save-excursion (forward-symbol 1) (point)))
  (catch 'highlight-function-calls--matcher
    (when (not (nth 5 (syntax-ppss)))
      (while (re-search-forward (rx symbol-start (*? any) symbol-end) end t)
        (let ((match (intern-soft (match-string 0))))
          (when (and (or (functionp match)
                         (when highlight-function-calls-macro-calls
                           (macrop match))
                         (when highlight-function-calls-special-forms
                           (special-form-p match)))
                     (not (member match highlight-function-calls-exclude-symbols)))
            (goto-char (match-end 0))
            (setq highlight-function-calls--face-name
                  (pcase match
                    ((and (or 'not 'null) (guard highlight-function-calls-not)) 'highlight-function-calls--not-face)
                    (_ 'highlight-function-calls-face)))
            (throw 'highlight-function-calls--matcher t)))))
    nil))

;;;###autoload
(define-minor-mode highlight-function-calls-mode
  "Highlight function calls.

Toggle highlighting of function calls on or off.

With a prefix argument ARG, enable if ARG is positive, and
disable it otherwise. If called from Lisp, enable the mode if ARG
is omitted or nil, and toggle it if ARG is `toggle'."
  :init-value nil :lighter nil :keymap nil
  (let ((keywords highlight-function-calls--keywords))
    (font-lock-remove-keywords nil keywords)
    (when highlight-function-calls-mode
      (font-lock-add-keywords nil keywords 'append)))
  ;; Refresh font locking.
  (when font-lock-mode
    (if (fboundp 'font-lock-flush)
        (font-lock-flush)
      (with-no-warnings (font-lock-fontify-buffer)))))

(provide 'highlight-function-calls)

;;; highlight-function-calls.el ends here
