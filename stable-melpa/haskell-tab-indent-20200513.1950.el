;;; haskell-tab-indent.el --- tab-based indentation for haskell-mode -*- lexical-binding: t; -*-

;; Copyright (C) 2015, 2017, 2020  Sean Whitton

;; Author: Sean Whitton <spwhitton@spwhitton.name>
;; URL: https://spwhitton.name/tech/code/haskell-tab-indent/
;; Package-Commit: 3239e814d6999f31ad845cc58df53395ad299059
;; Version: 0.3
;; Package-Version: 20200513.1950
;; Package-X-Original-Version: 0.3
;; Keywords: indentation, haskell

;; This file is NOT part of GNU Emacs.

;;; License:

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provides `haskell-tab-indent-mode', a simple indentation
;; mode for Haskell projects which require tabs for indentation and do
;; not permit spaces (except for where clauses, as a special case).
;;
;; The user may use TAB to cycle between possible indentations.
;;
;; Installation:
;;
;; If you set `indent-tabs-mode' in the .dir-locals.el file for a
;; project requiring tabs, you can use something like this in your
;; init file to enable this mode for such projects:
;;
;;    (add-hook 'haskell-mode-hook
;;                (lambda ()
;;                  (add-hook 'hack-local-variables-hook
;;                            (lambda ()
;;                              (if indent-tabs-mode
;;                                  (haskell-tab-indent-mode 1)
;;                                (haskell-indentation-mode 1)))
;;                            nil t))) ; local hook

;;; Code:

(require 'cl-lib)
(require 'seq)

(cl-flet ((count-line-tabs () (save-excursion
                                (back-to-indentation)
                                (length (seq-filter (lambda (c) (equal c ?\t))
                                                    (buffer-substring
                                                     (line-beginning-position)
                                                     (point))))))
          (tabs (n) (make-string n ?\t)))
  (defun haskell-tab-indent ()
    "Auto indentation on TAB for `haskell-tab-indent-mode'."
    (interactive)
    (let ((this-line-tabs (count-line-tabs))
          (prev-line-tabs (save-excursion
                            (cl-loop do    (beginning-of-line 0)
                                     while (looking-at "[[:space:]]*$"))
                            (count-line-tabs)))
          ;; determine whether previous line is a declaration
          (prev-line-decl (save-excursion
                            (beginning-of-line 0)
                            (looking-at "^[[:blank:]]*[[:graph:]]+ :: ")))
          ;; determine whether previous line is the first line of a where clause
          (prev-line-where (save-excursion
                             (beginning-of-line 0)
                             (looking-at "^[[:blank:]]*where$"))))
      (save-excursion
        (back-to-indentation)
        (let ((indent (cond ((looking-at "where$")
                             ;; if user explicitly requested an indent
                             ;; change, cycle indentation of the where
                             ;; clause, but no deeper than the level of the
                             ;; previous line.  Otherwise, just ensure it's
                             ;; preceded by two spaces
                             (if (eq this-command 'indent-for-tab-command)
                                 (if (>= this-line-tabs prev-line-tabs)
                                     "  "
                                   (concat (tabs (1+ this-line-tabs)) "  "))
                               (concat (tabs this-line-tabs) "  ")))
                            ;; if the previous line is a declaration, then
                            ;; this line should be either empty, or at the
                            ;; same indent level as that declaration
                            (prev-line-decl
                             (tabs prev-line-tabs))
                            ;; if the previous line was the beginning of a
                            ;; where clause, indent should be exactly one
                            ;; more
                            (prev-line-where
                             ;; also check indentation of the 'where' itself
                             (save-excursion
                               (beginning-of-line 0)
                               (skip-chars-forward "\t")
                               (unless (looking-at "  where$")
                                 (insert "  ")))
                             (tabs (1+ prev-line-tabs)))
                            ;; if the user explicitly requested an indent
                            ;; change, cycle through the plausible indents
                            ((eq this-command 'indent-for-tab-command)
                             (if (>= this-line-tabs (1+ prev-line-tabs))
                                 ""
                               (tabs (1+ this-line-tabs))))
                            ;; otherwise, indent to same level as previous line
                            (t
                             (tabs prev-line-tabs)))))
          (setf (buffer-substring (line-beginning-position) (point)) indent))))
    ;; on a line with only indentation, ensure point is at the end
    (when (save-excursion (beginning-of-line) (looking-at "[[:space:]]*$"))
      (end-of-line))))

;;;###autoload
(define-minor-mode haskell-tab-indent-mode
  "Haskell indentation mode for projects requiring that only tabs
-- with no spaces -- be used for indentation.

Binds the TAB key to cycle between possible indents."
  :lighter " TabInd"
  (kill-local-variable 'indent-line-function)
  (when haskell-tab-indent-mode
    ;; recent `haskell-mode' considers `haskell-indentation-mode' to
    ;; be the default, and unconditionally turns it on.  Follow recent
    ;; `haskell-indent-mode' and turn it off when activating our mode
    (when (and (bound-and-true-p haskell-indentation-mode)
               (fboundp 'haskell-indentation-mode))
      (haskell-indentation-mode 0))
    (set (make-local-variable 'indent-line-function) 'haskell-tab-indent)
    (set (make-local-variable 'indent-tabs-mode) t)))

(provide 'haskell-tab-indent)
;;; haskell-tab-indent.el ends here
