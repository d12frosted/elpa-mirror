;;; flycheck-crystal.el --- Add support for Crystal to Flycheck

;; Copyright (C) 2015 crystal-lang-tools

;; Authors: crystal-lang-tools
;; URL: https://github.com/crystal-lang-tools/emacs-crystal-mode
;; Package-Version: 20171124.1540
;; Package-Commit: 0fe6815201bebe4c5ff6857bd541d95b05132b10
;; Keywords: tools crystal
;; Version: 0.1
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

;; This package provides error-checking support for the Crystal language to the
;; Flycheck package.  To use it, have Flycheck installed, then add the following
;; to your init file:
;;
;;    (require 'flycheck-crystal)
;;    (add-hook 'crystal-mode-hook 'flycheck-mode)

;;; Code:

(require 'flycheck)

(defun flycheck-crystal--find-default-directory (_checker)
  "Come up with a suitable default directory to run CHECKER in.
This will either be the directory that contains `shard.yml' or,
if no such file is found in the directory hierarchy, the directory
of the current file."
  (or
   (and
    buffer-file-name
    (locate-dominating-file buffer-file-name "shard.yml"))
default-directory))

(flycheck-define-checker crystal-build
  "A Crystal syntax checker using crystal build"
  :command ("crystal"
            "build"
            "--no-codegen"
            "--no-color"
            source-inplace)
  :working-directory flycheck-crystal--find-default-directory
  :error-patterns
  ((error line-start "Error in " (file-name) ":" line ":" (message) line-end)
   (error line-start "Syntax error in " (file-name) ":" line ":" (message) line-end)
   (warning line-start "Warning in " (file-name) ":" line ":" (message) line-end)
   )
  :modes crystal-mode
  )

(add-to-list 'flycheck-checkers 'crystal-build)

(provide 'flycheck-crystal)

;;; flycheck-crystal.el ends here
