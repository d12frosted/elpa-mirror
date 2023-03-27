;;; ob-drawtiming.el --- Functions for drawtiming evaluation in org-babel

;; Copyright (C) 2023 Fabien Perez

;; Author: Fabien Perez
;; Keywords: tools, multimedia
;; Package-Version: 20230312.1740
;; Package-Commit: 813736e20ce1c223700c87a6e70e3f126a11e933
;; Homepage: https://github.com/perfab71/ob-drawtiming
;; Version: 2023-03-10
;; Package-Requires: ((emacs "24.1") (org "8.0"))

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

;; org-babel support for evaluating drawtiming script.
;;
;; Drawtiming is available and documented at
;; http://drawtiming.sourceforge.net/index.html
;;
;; This differs from most standard languages in that
;;
;; 1) there is no such thing as a "session"
;; 2) we are generally only going to return results of type "file"
;; 3) we are adding the "file" and "cmdline" header arguments
;; 4) there are no variables

;;; Requirements:

;; drawtiming   http://drawtiming.sourceforge.net/index.html

;;; Code:
(require 'ob)

(defvar org-babel-default-header-args:drawtiming
  '((:results . "file") (:exports . "results"))
  "Default arguments for evaluating a drawtiming source block.")

(defcustom org-drawtiming-path "/usr/bin/drawtiming"
  "Path to the drawtiming executable file."
  :group 'org-babel
  :version "24.1"
  :type 'string)

(defun org-babel-execute:drawtiming (body params)
  "Execute a block of drawtiming code with org-babel.
This function is called by `org-babel-execute-src-block'
which pass BODY and PARAMS."
  (let* ((result-params (split-string (or (cdr (assoc :results params)) "")))
	 (out-file (or (cdr (assoc :file params))
		       (error "Drawtiming requires a \":file\" header argument")))
	 (cmdline (cdr (assoc :cmdline params)))
	 (in-file (org-babel-temp-file "drawtiming-"))
	 (cmd (if (string= "" org-drawtiming-path)
		  (error "`org-drawtiming-path' is not set")
		(concat (shell-quote-argument
			 (expand-file-name org-drawtiming-path))
                        " -o " out-file
                        " " in-file))))
    (unless (file-exists-p org-drawtiming-path)
      (error "Could not find drawtiming executable at %s" org-drawtiming-path))
    (with-temp-file in-file (insert body))
    (message "%s" cmd)
    (org-babel-eval cmd "")
    nil))

(provide 'ob-drawtiming)

;;; ob-drawtiming.el ends here
