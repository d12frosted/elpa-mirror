;;; imake.el --- Simple, opinionated make target runner  -*- lexical-binding:t -*-

;; Copyright (C) 2017-2022 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/imake
;; Keywords: convenience
;; Package-Version: 20221022.2233
;; Package-Commit: d9b5cb5c0a5483e663cc3c345df7659ddf08b61e

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

;; This package provides the command `imake', which prompts for
;; a `make' target and runs it in the current directory.

;; This is an opinionated command suitable for simple Makefiles
;; such as those that can be found in the repositories of some
;; Emacs packages.  The make targets to be offered as completion
;; candidates have to be documented like so:
;;
;;   help:
;;           $(info make lisp  - generate byte-code and autoloads)
;;           $(info make clean - remove generated files)

;; More precisely, a `help' target containing lines that match
;; the regexp "^\t$(info make \\([^)]*\\))" is expected.

;;; Code:

(require 'compat)

;;;###autoload
(defun imake (target)
  "Run make target TARGET.

Prompt for a make target described in the `help' make target and
run it.  This function only detects targets that are documented
like so:

  help:
          $(info make lisp     - generate byte-code and autoloads)
          $(info make clean    - generate info manual)

More precisely, a `help' target containing lines that match the
regular expression \"^\t$(info make \\([^)]*\\))\" is expected."
  (interactive
   (let ((choice (completing-read "Target: " (imake-targets))))
     (string-match "^\\([^ ]*\\)" choice)
     (list (match-string 1 choice))))
  (async-shell-command (concat "make " (shell-quote-argument target))))

(defun imake-targets ()
  "Return a list of make targets."
  (if (file-exists-p "Makefile")
      (let (targets)
        (with-temp-buffer
          (save-excursion
            (insert-file-contents "Makefile"))
          (if (re-search-forward "^help:")
              (while (re-search-forward
                      "^\t$(info make \\(\\(\\([^ ]*\\) *\\)\\([^)]*\\)\\))"
                      nil t)
                (let ((name (match-string-no-properties 3)))
                  (if (string-match-p "\\`\\[[^]]+\\]\\'" name)
                      (let ((len (length (match-string 2)))
                            (desc (match-string-no-properties 4)))
                        (dolist (name (split-string (substring name 1 -1) "|"))
                          (push (concat name
                                        (make-string (- len (length name)) ?\s)
                                        desc)
                                targets)))
                    (push (match-string-no-properties 1) targets))))
            (user-error "There is no help target"))
          (nreverse targets)))
    (user-error "There is no Makefile in %s" default-directory)))

(provide 'imake)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; imake.el ends here
