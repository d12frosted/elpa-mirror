;;; ob-d2.el --- Org-babel functions for d2  -*- lexical-binding:t -*-

;; Copyright (C) 2022-2023 Xavier Capaldi

;; Author: Xavier Capaldi
;; URL: https://github.com/xcapaldi/ob-d2
;; Package-Version: 20230314.352
;; Package-Commit: 5d197f8225a9fb4da997235b231abe30049c6825
;; Keywords: languages
;; Version: 0.0.3
;; Created: 26th Dec 2022
;; Package-Requires: ((emacs "24.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Org-Babel support for evaluating d2 diagram scripting source code.
;;
;; d2 differs from most standard languages in that:
;;
;; 1) there is no such thing as a "session" in d2
;;
;; 2) we are only going to return results of type "file"
;;
;; 3) you can specify `:flags' headers to be passed to the `d2' command
;;
;; 4) there are no variables (at least for now)

;;; Requirements:

;; - You must have d2 installed and d2 should be in your `exec-path'. If not,
;;   feel free to modify `ob-d2-command' to the location of your d2
;;   command.
;;
;; - `d2-mode' is also recommended for syntax highlighting and formatting,
;;   however it is not required.

;;; TODO:

;; - Provide better error feedback.

;;; Code:
(require 'ob)
(require 'org-compat)

(add-to-list 'org-babel-tangle-lang-exts '("d2" . "d2"))

(defvar org-babel-default-header-args:d2
  '((:results . "file")
    (:exports . "results"))
  "Default arguments for evaluating a D2 source block.")

(defvar ob-d2-command "d2"
  "The d2 command to use to compile and run the D2 code.")

(defun org-babel-execute:d2 (body params)
  "Execute a BODY of D2 code with org-babel and additional PARAMS.
This function is called by `org-babel-execute-src-block'."
  (let* ((out-file (or (cdr (assq :file params))
		       (error
			"D2 code block requires :file header argument")))
	 (flags (cdr (assq :flags params)))
	 (in-file (org-babel-temp-file "d2-src-" ".d2"))
	 (cmd (concat ob-d2-command
		          " " flags
                  " " (org-babel-process-file-name in-file)
                  " " (org-babel-process-file-name out-file))))

    (with-temp-file in-file (insert body))
    (message cmd)
    (shell-command cmd)
    nil))

(defun org-babel-prep-session:d2 (&rest _args)
  "Return an error because D2 does not support sessions."
  (error "D2 does not support sessions"))

(provide 'ob-d2)
;;; ob-d2.el ends here
