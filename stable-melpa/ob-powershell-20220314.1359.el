;;; ob-powershell.el --- Run Powershell from org mode source blocks
;;; SPDX-License-Identifier: MIT

;; Copyright (C) 2022 Rob Kiggen

;; Author: Rob Kiggen <robby.kiggen@essential-it.be>
;; Maintainer: Mois Moshev <mois.moshev@bottleshipvfx.com>
;; Version: 1.0
;; Package-Version: 20220314.1359
;; Package-Commit: f351429590ed68b26a9c8f9847066ca4205e524b
;; Package-Requires: ((emacs "26.1"))
;; Keywords: powershell, shell, execute, outlines, processes
;; URL: https://github.com/rkiggen/ob-powershell

;;; Commentary:

;; Currently this only supports the external compilation and execution
;; of Powershell code blocks (i.e., no session support).
;;; Code:

(require 'ob)

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("powershell" . "ps1"))

(defcustom ob-powershell-powershell-command "powershell"
  "Name of command used to evaluate powershell blocks."
  :group 'org-babel
  :version "24.3"
  :type 'string)


(defun org-babel-execute:powershell (body params)
  "Execute a block of Powershell code BODY with Babe passing PARAMS.
This function is called by `org-babel-execute-src-block'."
  (let ((scriptfile (org-babel-temp-file "powershell-script-" ".ps1"))
        (full-body (org-babel-expand-body:generic
		                body params (org-babel-variable-assignments:powershell params))))
    (message full-body)
    (with-temp-file scriptfile (insert full-body))
    (org-babel-eval (concat ob-powershell-powershell-command " " scriptfile) "")))

(defun org-babel-variable-assignments:powershell (params)
  "Return a list of Powershell statements parsed from PARAMS, assigning the block's variables."
  (mapcar
   (lambda (pair)
     (format "$env:%s=%s"
             (car pair)
             (ob-powershell-var-to-powershell (cdr pair))))
   (org-babel--get-vars params)))

(defun ob-powershell-var-to-powershell (var)
  "Convert :var into a powershell variable.
Convert an elisp value, VAR, into a string of poershell source code
specifying a variable of the same value."
  (if (listp var)
      (concat "[" (mapconcat #'ob-powershell-var-to-powershell var ", ") "]")
    (format "$%S" var)))

(defun org-babel-prep-session:powershell (session params)
  "Return an error because Powershell does not support sessions.
SESSION refers to the babel session.
PARAMS are the passed parameters."
  (error "Sessions are not (yet) supported for Powershell"))


(provide 'ob-powershell)
;;; ob-powershell.el ends here
