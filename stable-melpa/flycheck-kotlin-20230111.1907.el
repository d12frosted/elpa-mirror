;;; flycheck-kotlin.el --- Support kotlin in flycheck

;; Copyright (C) 2017 Elric Milon <whirm@__REMOVETHIS__gmx.com>
;;
;; Author: Elric Milon <whirm_REMOVETHIS__@gmx.com>
;; Created: 20 January 2017
;; Version: 0.1
;; Package-Version: 20230111.1907
;; Package-Commit: a2a6abb9a7f85c6fb15ce327459ec3c8ff780188
;; Package-Requires: ((flycheck "0.20"))

;;; Commentary:

;; This package adds support for kotlin to flycheck. To use it, add
;; to your init.el:

;; (require 'flycheck-kotlin)
;; (add-hook 'kotlin-mode-hook 'flycheck-mode)

;;; License:

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(require 'flycheck)

(flycheck-define-checker kotlin-ktlint
  "A Kotlin syntax and style checker using the ktlint utility.
See URL `https://github.com/shyiko/ktlint'."
  :command ("ktlint" "--stdin")
  :error-patterns
  ((error line-start "<stdin>:" line ":" column ": " (message) "(" (id (1+ (not ")"))) ")" line-end))
  :modes (kotlin-mode kotlin-ts-mode)
  :standard-input t)

;;;###autoload
(defun flycheck-kotlin-setup ()
  "Setup Flycheck for Kotlin."
  (add-to-list 'flycheck-checkers 'kotlin-ktlint))

(provide 'flycheck-kotlin)
;;; flycheck-kotlin.el ends here
