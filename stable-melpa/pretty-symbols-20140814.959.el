;;; pretty-symbols.el --- Draw tokens as Unicode glyphs.

;; Copyright (C) 2012 David Röthlisberger

;; Author: David Röthlisberger <david@rothlis.net>
;; URL: http://github.com/drothlis/pretty-symbols
;; Package-Version: 20140814.959
;; Package-Commit: ab82b3fba129fae14e4031eb7fd648c1a92d0e71
;; Version: 2.0
;; Keywords: faces

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; Minor mode for drawing multi-character tokens as Unicode glyphs
;; (lambda -> λ).
;;
;; Only works when `font-lock-mode' is enabled.
;;
;; This mode is heavily inspired by Trent Buck's pretty-symbols-mode[1]
;; and Arthur Danskin's pretty-mode[2]; but aims to replace those modes, and
;; the many others scattered on emacswiki.org, with:
;;
;; * A simple framework that others can use to define their own symbol
;;   replacements,
;; * that doesn't turn on all sorts of crazy mathematical symbols by default,
;; * is a self-contained project under source control, open to contributions,
;; * available from the MELPA package repository[4].
;;
;; You probably won't want to use this with haskell-mode which has its own much
;; fancier fontification[3]. Eventually it would be nice if this package grew
;; in power and became part of Emacs, so other packages could use it instead of
;; rolling their own.
;;
;; Add your own custom symbol replacements to the list
;; `pretty-symbol-patterns'.
;;
;; Only tested with GNU Emacs 24.
;;
;; [1] http://paste.lisp.org/display/42335/raw
;; [2] http://www.emacswiki.org/emacs/pretty-mode.el
;; [3] https://github.com/haskell/haskell-mode/blob/master/haskell-font-lock.el
;; [4] http://melpa.milkbox.net/

;;; Code:

;;;###autoload
(define-minor-mode pretty-symbols-mode
  "Draw multi-character tokens as Unicode glyphs.
For example, in lisp modes draw λ instead of the characters
l a m b d a. The on-disk file keeps the original characters.

This may sound like a neat trick, but be extra careful: it
changes the line length and can thus lead to surprises with
respect to alignment and layout.

To enable, add to the hooks of the major modes you want pretty
symbols in: (add-hook 'emacs-lisp-mode-hook 'pretty-symbols-mode)."
  nil " λ" nil
  (if pretty-symbols-mode
      (font-lock-add-keywords nil (pretty-symbol-keywords) t)
    (font-lock-remove-keywords nil (pretty-symbol-keywords))
    ;; TODO: Disabling the mode doesn't decompose existing symbols.
    ;; Is the following safe to do -- what else uses composition?
    ;; (remove-text-properties (point-min) (point-max) '(composition nil))
    ))


;; User options

(defgroup pretty-symbols nil
  "Draw multi-character tokens as Unicode glyphs."
  :group 'font-lock)

;;;###autoload
(defcustom pretty-symbol-patterns
  (let ((lisps '(emacs-lisp-mode inferior-lisp-mode inferior-emacs-lisp-mode
                 lisp-mode scheme-mode))
        (c-like '(c-mode c++-mode go-mode java-mode js-mode
                  perl-mode cperl-mode ruby-mode
                  python-mode inferior-python-mode)))
    `(
      ;; Basic symbols, enabled by default
      (?λ lambda "\\<lambda\\>" (,@lisps python-mode inferior-python-mode))
      (?ƒ lambda "\\<function\\>" (js-mode))
      ;; Relational operators --
      ;; enable by adding 'relational to `pretty-symbol-categories'
      (?≠ relational "!=" (,@c-like))
      (?≠ relational "/=" (,@lisps))
      (?≥ relational ">=" (,@c-like ,@lisps))
      (?≤ relational "<=" (,@c-like ,@lisps))
      ;; Logical operators
      (?∧ logical "&&" (,@c-like))
      (?∧ logical "\\<and\\>" (,@lisps))
      (?∨ logical "||" (,@c-like))
      (?∨ logical "\\<or\\>" (,@lisps))
      ;;(?¬ logical "\\<!\\>" (,@c-like)) ; TODO: Fix regex so that ! matches
                                        ; but != doesn't. (\< and \> don't work
                                        ; because ! isn't considered part of
                                        ; a word). This will require support
                                        ; for subgroups and not replacing the
                                        ; whole match.
      (?¬ logical "\\<not\\>" (,@lisps))
      (?∅ nil "\\<nil\\>" (,@lisps))
      ))
  "A list of ((character category pattern major-modes) ...).
For each entry in the list, if the buffer's major mode (or one of
its parent modes) is listed in MAJOR-MODES, occurrences of
PATTERN will be shown as CHARACTER instead.

The replacement will only happen if CATEGORY is present in
`pretty-symbol-categories' before this mode is enabled.

Note that a major mode's presence in this list doesn't turn on
pretty-symbols-mode; you have to do so in the major mode's hook."
  :group 'pretty-symbols
  :type '(repeat
          (list (character :tag "Pretty character")
                (symbol :tag "Category")
                (regexp :tag "Pattern to replace")
                (repeat :tag "Enable in major modes"
                        (symbol :tag "Mode")))))

;;;###autoload
(defcustom pretty-symbol-categories (list 'lambda)
  "A list of the categories in `pretty-symbol-patterns' to enable.

By default, only lambdas (and the equivalents in other languages)
are prettified, so that users can use this minor mode to add their
own patterns, without being saddled with a whole lot of confusing
symbols.

This must be set before `pretty-symbols-mode' is enabled.

The available symbols are:

lambda          Prettify the keyword for lambdas (anonymous functions).
relational      Relational operators: ≠ ≤ ≥
logical         Logical operators: ∧ ∨ ¬

To set this list from your init file:
\(setq pretty-symbol-categories '(lambda relational logical))
"
  :group 'pretty-symbols
  :type '(list
          (set :tag "Standard Categories"
               :inline t
               (const lambda)
               (const relational)
               (const logical)
               (const nil))
          (repeat :tag "Additional Categories"
                  :inline t
                  (symbol :tag "Category"))))


;; Internal functions

(defun pretty-symbol-keywords ()
  "Return the pretty font-lock keywords for the current major mode."
  (delq nil (mapcar (lambda (x) (apply 'pretty-symbol-pattern-to-keyword x))
                    pretty-symbol-patterns)))

(defun pretty-symbol-pattern-to-keyword (char category pattern modes &optional idx)
  "For a single entry in `pretty-symbol-patterns' return a list
suitable as a single entry in `font-lock-keywords'."
  (let ((idx (or idx 0)))
    (if (and (memq category pretty-symbol-categories)
             (apply 'derived-mode-p modes))
        `(,pattern (,idx (progn (compose-region (match-beginning ,idx) (match-end ,idx)
                                                ,char 'decompose-region)
                                nil))))))


(provide 'pretty-symbols)

;; Local Variables:
;; coding: utf-8
;; eval: (if (fboundp 'pretty-symbols-mode) (pretty-symbols-mode -1))
;; End:

;;; pretty-symbols.el ends here
