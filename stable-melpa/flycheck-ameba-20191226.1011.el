;;; flycheck-ameba.el --- Add support for Ameba to Flycheck -*- lexical-binding: t; -*-

;; Copyright (C) 2017 V. Elenhaupt

;; Authors: V. Elenhaupt
;; URL: https://github.com/crystal-ameba/ameba.el
;; Package-Version: 20191226.1011
;; Package-Commit: 0c4925ae0e998818326adcb47ed27ddf9761c7dc
;; Keywords: tools crystal ameba
;; Version: 0
;; Package-Requires: ((emacs "24.4") (flycheck "30"))

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
;;    (flycheck-ameba-setup)

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
  :error-explainer
  (lambda (error)
    (let*
        ((filename (flycheck-error-filename error))
         (line (number-to-string (flycheck-error-line error)))
         (column (number-to-string (flycheck-error-column error)))
         (point (concat filename ":" line ":" column)))
      (with-output-to-string
        (call-process "ameba" nil standard-output nil "--explain" point "--no-color"))))
  :modes crystal-mode)

;;;###autoload
(defun flycheck-ameba-setup ()
  "Setup Flycheck Ameba."
  (interactive)
  (add-to-list 'flycheck-checkers 'crystal-ameba))

(provide 'flycheck-ameba)

;;; flycheck-ameba.el ends here
