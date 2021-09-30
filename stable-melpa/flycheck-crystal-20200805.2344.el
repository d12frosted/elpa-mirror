;;; flycheck-crystal.el --- Add support for Crystal to Flycheck

;; Copyright (C) 2015-2018 crystal-lang-tools

;; Authors: crystal-lang-tools
;; URL: https://github.com/crystal-lang-tools/emacs-crystal-mode
;; Package-Version: 20200805.2344
;; Package-Commit: 3e37f282af06a8b82d266b2d7a7863f3df2ffc3b
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
(require 'json)

(defgroup flycheck-crystal nil
  "Crystal mode's flycheck checker."
  :group 'crystal)

(defcustom flycheck-crystal-show-instantiating nil
  "Whether \"instantiated by\" messages should be shown.
These messages typically show the (static) backtrace of an error and are of
little interest."
  :type 'boolean
  :group 'flycheck-crystal)

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
            "-f" "json"
            "--stdin-filename"
            (eval (buffer-file-name)))
  :working-directory flycheck-crystal--find-default-directory
  :error-parser flycheck-crystal--error-parser
  :modes crystal-mode
  :standard-input t
  )

(defun flycheck-crystal--error-parser (output checker buffer)
  (unless (zerop (length output))
    (mapcan
     (lambda (err)
       (when (or flycheck-crystal-show-instantiating
                 (not (string-prefix-p "instantiating" (cdr-safe (assoc 'message err)))))
         (list (flycheck-error-new-at (cdr-safe (assoc 'line err))
                                      (cdr-safe (assoc 'column err))
                                      'error
                                      (cdr-safe (assoc 'message err))
                                      :checker checker
                                      :buffer buffer
                                      :filename (cdr-safe (assoc 'file err))))))
     (json-read-from-string output))))

(add-to-list 'flycheck-checkers 'crystal-build)

(provide 'flycheck-crystal)

;;; flycheck-crystal.el ends here
