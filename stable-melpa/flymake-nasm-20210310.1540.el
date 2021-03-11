;;; flymake-nasm.el --- A flymake handler for asm-mode files using nasm -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Jürgen Hötzel

;; Author: Jürgen Hötzel <juergen@hoetzel.info>
;; URL: http://github.com/juergenhoetzel/flymake-nasm
;; Package-Version: 20210310.1540
;; Package-Commit: 27e58d7f3a48ca6fc12238fe6c888a3fdffc3f75
;; Maintainer: Jürgen Hötzel
;; Keywords: tools, languages
;; Package-Requires: ((flymake-quickdef "1.0.0") (emacs "26.1"))
;; Version: 1.0.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This package adds asm syntax checker nasm to flymake.

;;; Code:

(require 'flymake-quickdef)

(defgroup flymake-nasm nil "flymake-nasm preferences." :group 'flymake-nasm)

(defcustom flymake-nasm-executable "nasm"
  "The nasm executable to use for syntax checking."
  :safe #'stringp
  :type 'string
  :group 'flymake-nasm)

(defcustom flymake-nasm-format "elf64"
  "The nasm output format."
  :type 'string
  :group 'flymake-nasm)

(flymake-quickdef-backend flymake-nasm-backend
  :pre-let ((nasm-exec (executable-find flymake-nasm-executable)))
  :pre-check (unless nasm-exec (error "Not found nasm on PATH"))
  :write-type 'file
  :proc-form `(,nasm-exec  ,(concat "-f" flymake-nasm-format) ,fmqd-temp-file)
  :search-regexp "^.+:\\([0-9]+\\): \\(.+\\): \\(.+\\)$"
  :prep-diagnostic
  (let* ((lnum (string-to-number (match-string 1)))
	 (severity (match-string 2))
	 (msg (match-string 3))
	 (pos (flymake-diag-region fmqd-source lnum))
	 (beg (car pos))
	 (end (cdr pos))
	 (type (cond
		((string= severity "error") :error)
		((string= severity "warning") :warning)
		(t :note))))
    (list fmqd-source beg end type msg)))

;;;###autoload
(defun flymake-nasm-setup ()
  "Enable flymake backend."
  (interactive)
  (add-hook 'flymake-diagnostic-functions
	    #'flymake-nasm-backend nil t))

(provide 'flymake-nasm)
;;; flymake-nasm.el ends here

;; Local Variables:
;; fill-column: 80
;; End:
