;;; morlock.el --- More font-lock keywords for elisp  -*- lexical-binding:t -*-

;; Copyright (C) 2013-2022 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/morlock
;; Keywords: convenience

;; Package-Requires: ((emacs "25.1") (compat "28.1.1.0"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This library defines more font-lock keywords for Emacs Lisp.

;; These keyword variables are available:

;; `morlock-el-font-lock-keywords' expressions that aren't
;;     covered by the default keywords.
;; `morlock-op-font-lock-keywords' expressions that would be
;;     operators in other languages: `or', `xor', `and' and `not'.
;; `morlock-cl-font-lock-keywords' expressions that used to be
;;     covered by the default keywords but aren't anymore since
;;     the `cl-' prefix was added.
;; `morlock-font-lock-keywords' combines the above three.

;; To use `morlock-font-lock-keywords' in `emacs-lisp-mode' and
;; `lisp-interaction-mode' enable `global-morlock-mode'.

;; If you want to only enable some of the keywords and/or only in
;; `emacs-lisp-mode', then require `morlock' and activate the keywords
;; in one of the variables using `font-lock-add-keywords'.  Doing so
;; is also slightly more efficient.

;;     (font-lock-add-keywords 'emacs-lisp-mode
;;                              morlock-el-font-lock-keywords)

;;; Code:

(require 'compat)

(defconst morlock-el-font-lock-keywords
  (eval-when-compile
    `((,(concat "(\\(define-button-type\\)\\>"
                "[ \t'\(]*"
                "\\(\\(?:\\sw\\|\\s_\\)+\\)?")
       (1 'font-lock-keyword-face)
       (2 'font-lock-variable-name-face nil t))))
  "Fresh expressions to highlight in Emacs-Lisp mode.")

(defconst morlock-op-font-lock-keywords
  '(("(\\(or\\|xor\\|and\\|not\\)\\>" 1 'font-lock-keyword-face)))

(defconst morlock-cl-font-lock-keywords
  (eval-when-compile
    `((,(concat "(\\(cl-" (regexp-opt '("dotimes" "dolist" "declare"))
                "\\)\\>")
       . 1)))
  "Exiled expressions to highlight in Emacs-Lisp mode.")

(defconst morlock-font-lock-keywords
  (append morlock-el-font-lock-keywords
          morlock-op-font-lock-keywords
          morlock-cl-font-lock-keywords)
  "More expressions to highlight in Emacs-Lisp mode.
This variable combines the keywords defined in
`morlock-el-font-lock-keywords',
`morlock-op-font-lock-keywords', and
`morlock-cl-font-lock-keywords'.")

;;;###autoload
(define-minor-mode morlock-mode
  "Highlight more font-lock keywords."
  :lighter ""
  (if morlock-mode
      (font-lock-add-keywords  nil morlock-font-lock-keywords 'append)
    (font-lock-remove-keywords nil morlock-font-lock-keywords))
  (when font-lock-mode
    (if (and (fboundp 'font-lock-flush)
             (fboundp 'font-lock-ensure))
        (save-restriction
          (widen)
          (font-lock-flush)
          (font-lock-ensure))
      (with-no-warnings
        (font-lock-fontify-buffer)))))

;;;###autoload
(define-globalized-minor-mode global-morlock-mode
  morlock-mode turn-on-morlock-mode-if-desired
  :group 'font-lock-extra-types)

(defun turn-on-morlock-mode-if-desired ()
  (when (derived-mode-p 'emacs-lisp-mode)
    (morlock-mode 1)))

;;; _
(provide 'morlock)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; morlock.el ends here
