;;; imake.el --- Simple, opinionated make target runner  -*- lexical-binding: t -*-

;; Copyright (C) 2017-2021  Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Package-Requires: ((emacs "24.3"))
;; Package-Version: 20210918.2046
;; Package-Commit: e69a09e7962afe81474aa6c88974a1e6add15624
;; Homepage: https://github.com/tarsius/imake

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

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
                      "^\t$(info make \\([^)]*\\))" nil t)
                (push (match-string-no-properties 1) targets))
            (user-error "There is no help target"))
          (nreverse targets)))
    (user-error "There is no Makefile in %s" default-directory)))

(provide 'imake)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; imake.el ends here
