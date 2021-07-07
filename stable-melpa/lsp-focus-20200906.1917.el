;;; lsp-focus.el --- focus.el support for lsp-mode    -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020  Vibhav Pant <vibhavp@gmail.com>

;; Author: Vibhav Pant
;; Version: 1.0.0
;; Package-Version: 20200906.1917
;; Package-Commit: d01f0af156e4e78dcb9fa8e080a652cf8f221d30
;; Keywords: languages lsp-mode
;; Package-Requires: ((emacs "26.1") (focus "0.1.1") (lsp-mode "6.1"))
;; URL: https://github.com/emacs-lsp/lsp-focus

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

;; lsp-focus provides support for focus.el using language server
;; protocol's "textDocument/foldingRange" functionality.  It can be enabled
;; with
;; (require 'lsp-focus)
;; (add-hook 'focus-mode-hook #'lsp-focus-mode)

;;; Code:

(require 'focus)
(require 'lsp-mode)

(defgroup lsp-focus nil
  "LSP support for focus.el"
  :group 'lsp-mode)

(defcustom lsp-focus-thing 'lsp--range
  "`Thing' to use for focus.el."
  :type '(choice (const lsp--range)
                 (const lsp--folding-range)))

;;;###autoload
(define-minor-mode lsp-focus-mode
  "Enables LSP support for focus.el."
  :group 'lsp-focus
  (cond
   (lsp-focus-mode
    (unless (lsp--capability "foldingRangeProvider")
      (signal 'lsp-capability-not-supported (list "foldingRangeProvider")))
    (make-local-variable 'focus-mode-to-thing)
    (setq focus-mode-to-thing
          (append `((,major-mode . ,lsp-focus-thing))
                  (assq-delete-all major-mode focus-mode-to-thing))))
   (t
    (kill-local-variable 'focus-mode-to-thing))))

(provide 'lsp-focus)
;;; lsp-focus.el ends here
