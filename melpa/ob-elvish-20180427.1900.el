;;; ob-elvish.el --- org-babel functions for Elvish shell

;; Copyright (C) 2018 Diego Zamboni

;; Author: Diego Zamboni <diego@zzamboni.org>
;; Keywords: literate programming, elvish, shell, languages, processes, tools
;; Package-Version: 20180427.1900
;; Package-Commit: 369181ceae1190bf971c71aebf9fc6133bd98c39
;; Homepage: https://github.com/zzamboni/ob-elvish
;; Version: 0.0.1

;;; License:

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;; THE SOFTWARE.

;;; Commentary:

;; Execute Elvish code inside org-mode src blocks.

;;; Requirements:

;; - The Elvish shell: https://elvish.io/
;; - The elvish-mode Emacs major mode: https://github.com/ALSchwalm/elvish-mode

;;; Code:
(require 'ob)
(require 'ob-ref)
(require 'ob-comint)
(require 'ob-eval)
;; possibly require modes required for your language

;; set the language mode to be used for Elvish blocks
(add-to-list 'org-src-lang-modes '("elvish" . elvish))

;; optionally define a file extension for this language
(add-to-list 'org-babel-tangle-lang-exts '("elvish" . "elv"))

;; optionally declare default header arguments for this language
(defvar org-babel-default-header-args:elvish '())

(defcustom org-babel-elvish-command "elvish"
  "Command to use for executing Elvish code."
  :group 'org-babel
  :type 'string)

(defcustom ob-elvish-command-options ""
  "Option string that should be passed to elvish."
  :group 'org-babel
  :type 'string)

;; This function expands the body of a source code block by prepending
;; module load statements and argument definitions to the body.
(defun org-babel-expand-body:elvish (body params &optional processed-params)
  "Expand BODY according to PARAMS, return the expanded body.
Optional argument PROCESSED-PARAMS may contain PARAMS preprocessed by ‘org-babel-process-params’."
  (let* ((pparams (or processed-params (org-babel-process-params params)))
         (vars (org-babel--get-vars pparams))
         (use (assq :use pparams))
         (uses (if use (split-string (cdr use) ", *") '())))
    (when (assq :debug params)
      (message "pparams=%s" pparams)
      (message "vars=%s" vars)
      (message "uses=%s" uses))
    (concat
     (mapconcat ;; use modules
      (apply-partially 'concat "use ") uses "\n")
     "\n"
     (mapconcat ;; define any variables
      (lambda (pair)
        (format "%s = %s"
                (car pair) (ob-elvish-var-to-elvish (cdr pair))))
      vars "\n") "\n" body "\n")))

;; This is the main function which is called to evaluate a code
;; block.
;;
;; This function will evaluate the body of the source code and return
;; its output. For Elvish the :results header argument has no effect,
;; the full output of the executed code is always returned.
;;
;; In addition to the standard header arguments, you can specify :use
;; to indicate modules which should be loaded with the `use' statement
;; before executing the code. You can specify multiple modules
;; separated by commas.
(defun org-babel-execute:elvish (body params)
  "Execute a BODY of Elvish code with org-babel with the given PARAMS.
This function is called by `org-babel-execute-src-block'"
  (message "executing Elvish source code block")
  (let* ((processed-params (org-babel-process-params params))
         ;; variables assigned for use in the block
         (vars (assoc :vars processed-params))
         ;; expand the body with `org-babel-expand-body:elvish'
         (full-body (org-babel-expand-body:elvish
                     body params processed-params)))
    (when (assq :debug params)
      (message "full-body=%s" full-body))
    (let* ((temporary-file-directory ".")
           (log (cdr (assoc :log params)))
           (tempfile (make-temp-file "elvish-")))
      (with-temp-file tempfile
        (insert full-body))
      (unwind-protect
          (shell-command-to-string
           (concat
            org-babel-elvish-command
            " "
            (when log (concat "--log " log ))
            " "
            ob-elvish-command-options
            " "
            (shell-quote-argument tempfile)))
        (delete-file tempfile)))
    ))

;; Format a variable passed with :var for assignment to an Elvish variable.
(defun ob-elvish-var-to-elvish (var)
  "Convert an elisp VAR into a string of Elvish source code specifying a var of the same value."
  (format "%S" var))

(provide 'ob-elvish)
;;; ob-elvish.el ends here
