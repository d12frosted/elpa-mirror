;;; ob-svgbob.el --- Babel Functions for svgbob            -*- lexical-binding: t; -*-

;; Copyright (C) 2018 mgxm

;; Author: Marcio Giaxa <i@mgxm.me>
;; Keywords: literate programming, svg, ascii
;; Package-Version: 20181024.58
;; Package-Commit: 9a930b1ed93e5ce1818029b2ec9e7662c098dbf4
;; Homepage: https://github.com/mgxm/ob-svgbob
;; Version:  0.0.1

;; This file is not part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Org-Babel support for evaluating svgbob source code.
;;
;; For information on svgbob see https://github.com/ivanceras/svgbob

;;; Code:
(require 'ob)

(defvar org-babel-default-header-args:svgbob
  '((:results . "file")
	(:exports . "results"))
  "Default arguments to use when evaluating a svgbob source block.")

(defun org-babel-execute:svgbob (body params)
  "Execute a block of Svgbob code with org-babel.
This function is called by `org-babel-execute-src-block'."
  (let* ((out-file (or (cdr (assq :file params))
					   (error "You need to specify a :file parameter")))
		 (cmd (or (cdr (assq :cmd params)) "svgbob"))
		 (options (cdr (assq :options params)))
		 (in-file (org-babel-temp-file "svgbob-")))
	(with-temp-file in-file (insert body))
	(org-babel-eval
	 (concat cmd
			 " " (org-babel-process-file-name in-file)
			 " " options
			 " -o " (org-babel-process-file-name out-file)) "")
	nil))

(defun org-babel-prep-session:svgbob (_session _params)
  "Return an error because svgbob does not support sessions."
  (error "Svgbob does not support sessions"))

(provide 'ob-svgbob)

;;; ob-svgbob.el ends here
