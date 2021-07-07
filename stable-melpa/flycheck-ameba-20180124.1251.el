;;; flycheck-ameba.el --- Add support for Ameba to Flycheck

;; Copyright (C) 2017 V. Elenhaupt

;; Authors: V. Elenhaupt
;; URL: https://github.com/veelenga/ameba.el
;; Package-Version: 20180124.1251
;; Package-Commit: ca5faaa0d5115dc2c301e06e062e653a7b9cb927
;; Keywords: tools crystal ameba
;; Package-Requires: ((flycheck "30"))

;; This file is not part of GNU Emacs.

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

;; This package provides static syntax checking support for the Crystal language to the
;; Flycheck package.  To use it, have Flycheck installed, then add the following
;; to your init file:
;;
;;    (require 'flycheck-ameba)
;;    (add-hook 'ameba-mode 'flycheck-ameba)

;;; Code:

(require 'flycheck)

(defun flycheck-ameba--find-project-root (_checker)
  "Compute an appropriate working-directory for flycheck-ameba.
This is either a parent directory containing a .ameba.yml, or nil."
  (or
  (and
    buffer-file-name
    (locate-dominating-file buffer-file-name ".ameba.yml"))
  default-directory))

(flycheck-define-checker crystal-ameba
  "A Crystal static syntax checker using ameba linter"
  :command ("ameba"
            "--format" "flycheck"
            "--config" ".ameba.yml"
            source-inplace)
  :working-directory flycheck-ameba--find-project-root
  :error-patterns
  ((info line-start (file-name) ":" line ":" column ": C: "
         (optional (id (one-or-more (not (any ":")))) ": ") (message)
         line-end)

   (warning line-start (file-name) ":" line ":" column ": W: "
            (optional (id (one-or-more (not (any ":")))) ": ") (message)
            line-end)

   (error line-start (file-name) ":" line ":" column ": E: " (message)
          line-end))
  :modes crystal-mode
  )

(add-to-list 'flycheck-checkers 'crystal-ameba)

(provide 'flycheck-ameba)

;;; flycheck-crystal.el ends here

;;; flycheck-ameba.el ends here
