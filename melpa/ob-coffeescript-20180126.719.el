;;; ob-coffeescript.el --- org-babel functions for coffee-script evaluation, and fully implementation!

;; Copyright (C) 2017 Brantou

;; Author: Brantou <brantou89@gmail.com>
;; URL: https://github.com/brantou/ob-coffeescript
;; Package-Version: 20180126.719
;; Package-Commit: 5a5bb04aea9c2a6eab5b05f90f5c7cb6de7b4261
;; Keywords: coffee-script, literate programming, reproducible research
;; Homepage: http://orgmode.org
;; Version:  1.0.0
;; Package-Requires: ((emacs "24.4"))

;;; License:

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

;; This file is not part of GNU Emacs.

;;; Commentary:
;;
;; Org-Babel support for evaluating coffee-script code.
;;
;; It was created based on the usage of ob-template.
;; fully implementation:
;; - Support session(multi-session independent) and external evaluation.
;; - Support :results value and output .
;; - Can handle table and list input.
;;

;;; Requirements:
;;
;; - node :: https://nodejs.org/en/
;;
;; - coffee-script :: http://coffeescript.org/
;;
;; - coffee-mode :: Can be installed through ELPA, or from
;;   https://raw.githubusercontent.com/defunkt/coffee-mode/master/coffee-mode.el
;;
;; - inf-coffee :: Can be installed through from
;;   https://raw.githubusercontent.com/brantou/inf-coffee/master/inf-coffee.el
;;

;;; TODO

;;
;; - Provide better error feedback.
;;
;; - more robust for session evaluation.
;;

;;; Code:
(require 'ob)
(require 'ob-eval)
(require 'ob-tangle)

(defvar inf-coffee-default-implementation)
(defvar inf-coffee-implementations)

(defvar org-babel-tangle-lang-exts)
(add-to-list 'org-babel-tangle-lang-exts '("coffeescript" . "coffee"))

(defvar org-babel-default-header-args:coffeescript '()
  "Default header arguments for coffee code blocks.")

(defcustom org-babel-coffeescript-command "coffee"
  "Name of command used to evaluate coffee blocks."
  :group 'org-babel
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'string)

(defcustom org-babel-coffee-mode
  (if (or (featurep 'inf-coffee) (fboundp 'run-coffee))
      'inf-coffee
    'coffee-mode)
  "Preferred coffee mode for use in running coffee interactively.
This will typically be either `coffee' or `coffee-mode'."
  :group 'org-babel
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'symbol)

(defvar org-babel-coffeescript-eoe-indicator  "'org_babel_coffee_eoe'"
  "String to indicate that evaluation has completed.")

(defvar org-babel-coffeescript-function-wrapper
  "
fs = require('fs')
_wrapper = ->
%s

fs.writeFile('%s', '' + _wrapper()) "
  "coffee-script code to print value of body.")

(defun org-babel-execute:coffeescript (body params)
  "Execute a block of Coffee code with org-babel.
 This function is called by `org-babel-execute-src-block'"
  (message "executing Coffee source code block")
  (let* ((org-babel-coffeescript-command
          (or (cdr (assq :coffeescript params))
              org-babel-coffeescript-command))
         (session (org-babel-coffeescript-initiate-session
                   (cdr (assq :session params))))
         (result-params (cdr (assq :result-params params)))
         (result-type (cdr (assq :result-type params)))
         (full-body (org-babel-expand-body:generic
                     body params (org-babel-variable-assignments:coffeescript params)))
         (result (org-babel-coffeescript-evaluate
                  session full-body result-type result-params)))
    (org-babel-reassemble-table
     result
     (org-babel-pick-name (cdr (assq :colname-names params))
                          (cdr (assq :colnames params)))
     (org-babel-pick-name (cdr (assq :rowname-names params))
                          (cdr (assq :rownames params))))))

(defun org-babel-coffeescript-evaluate
    (session body &optional result-type result-params preamble)
  "Evaluate BODY as Coffee code."
  (if session
      (org-babel-coffeescript-evaluate-session
       session body result-type result-params)
    (org-babel-coffeescript-evaluate-external-process
     body result-type result-params)))

(defun org-babel-coffeescript-evaluate-external-process
    (body &optional result-type result-params)
  "Evaluate BODY in external coffee process.
If RESULT-TYPE equals `output' then return standard output as a
string.  If RESULT-TYPE equals `value' then return the value of the
last statement in BODY, as elisp."
  (let ((result
         (let* ((script-file (org-babel-temp-file "coffee-script-" ".coffee"))
                (tmp-file (org-babel-temp-file "coffee-")))
           (with-temp-file script-file
             (insert
              (if (string= result-type "value")
                  (format org-babel-coffeescript-function-wrapper
                          (mapconcat
                           (lambda (line) (format "\t%s" line))
                           (split-string (org-remove-indentation (org-trim body))
                                         "[\r\n]")
                           "\n")
                          (org-babel-process-file-name tmp-file 'noquote))
                full-body)))
           (let ((eval-cmd
                  (format "%s %s"
                          org-babel-coffeescript-command
                          (org-babel-process-file-name script-file))))
             (pcase result-type
               (`output (org-babel-eval eval-cmd ""))
               (`value (when (org-babel-eval eval-cmd "")
                         (org-babel-eval-read-file tmp-file))))))))
    (org-babel-result-cond result-params
      result (org-babel-coffeescript-read result))))

(defun org-babel-coffeescript-evaluate-session
    (session body &optional result-type result-params)
  "Pass BODY to the Python process in SESSION.
If RESULT-TYPE equals `output' then return standard output as a
string.  If RESULT-TYPE equals `value' then return the value of the
last statement in BODY, as elisp."
  (let ((result
         (pcase result-type
           (`output
            (let ((tmp-redir-file (org-babel-temp-file "coffee-redir-")))
              (org-babel-comint-with-output
                  (session org-babel-coffeescript-eoe-indicator t body)
                (comint-send-input nil t)
                (mapc
                 (lambda (line)
                   (insert (org-babel-chomp line)) (comint-send-input nil t))
                 (append
                  (list
                   (format "_stdout=console._stdout;console._stdout=fs.createWriteStream('%s');"
                           (org-babel-process-file-name tmp-redir-file 'noquote)))
                  (list body)
                  (list "console._stdout=_stdout;")
                  (list org-babel-coffeescript-eoe-indicator)))
                (comint-send-input nil t))
              (org-babel-eval-read-file tmp-redir-file)))
           (`value
            (let* ((tmp-file (org-babel-temp-file "coffee-")))
              (org-babel-comint-with-output
                  (session org-babel-coffeescript-eoe-indicator t body)
                (comint-send-input nil t)
                (mapc
                 (lambda (line)
                   (insert (org-babel-chomp line)) (comint-send-input nil t))
                 (append
                  (list body)
                  (list (format "fs.writeFile('%s', _.toString())"
                                (org-babel-process-file-name tmp-file 'noquote)))
                  (list org-babel-coffeescript-eoe-indicator)))
                (comint-send-input nil t))
              (org-babel-eval-read-file tmp-file))))))
    (unless (string= (substring org-babel-coffeescript-eoe-indicator 1 -1) result)
      (org-babel-result-cond result-params
        result
        (org-babel-coffeescript-read (org-trim result))))))

(defun org-babel-prep-session:coffeescript (session params)
  "Prepare SESSION according to the header arguments specified in PARAMS."
  (let* ((session (org-babel-coffeescript-initiate-session session))
         (var-lines (org-babel-variable-assignments:coffeescript params)))
    (org-babel-comint-in-buffer session
      (sit-for .5) (goto-char (point-max))
      (mapc (lambda (var)
              (insert var) (comint-send-input nil t)
              (org-babel-comint-wait-for-output session)
              (sit-for .1) (goto-char (point-max))) var-lines))
    session))

(defun org-babel-load-session:coffeescript (session body params)
  "Load BODY into SESSION."
  (save-window-excursion
    (let ((buffer (org-babel-prep-session:coffeescript session params)))
      (with-current-buffer buffer
        (goto-char (process-mark (get-buffer-process (current-buffer))))
        (insert (org-babel-chomp body)))
      buffer)))

(defun org-babel-coffeescript-initiate-session (&optional session)
  "If there is not a current inferior-process-buffer in SESSION then create.
 Return the initialized session."
  (unless (string= session "none")
    (when (string= session "") (setq session "coffee"))
    (require org-babel-coffee-mode)
    (let* ((cmd (when (featurep 'inf-coffee)
                  (cdr (assoc inf-coffee-default-implementation
                              inf-coffee-implementations))))
           (buffer (get-buffer (if (featurep 'inf-coffee)
                                   (format "*%s*" session)
                                 (format "*%s*" "CoffeeREPL"))))
           (session-buffer
            (or (when (and buffer (org-babel-comint-buffer-livep buffer))
                  buffer)
                (save-window-excursion
                  (cond
                   ((and (eq 'inf-coffee org-babel-coffee-mode)
                         (fboundp 'run-coffee))
                    (run-coffee cmd session))
                   ((and (eq 'coffee-mode org-babel-coffee-mode)
                         (fboundp 'coffee-repl))
                    (coffee-repl))
                   (t (error "No function available for running an inferior Coffee")))
                  (current-buffer)))))
      (if (org-babel-comint-buffer-livep session-buffer)
          (progn (sit-for .25) session-buffer)
        (sit-for .5)
        (error "Failed to initiate session for running an inferior Coffee")))))

(defun org-babel-coffeescript-var-to-coffee (var)
  "Convert an elisp var into a string of coffee source code
 specifying a var of the same value."
  (if (listp var)
      (concat "[" (mapconcat #'org-babel-coffeescript-var-to-coffee var ", ") "]")
    (replace-regexp-in-string "\n" "\\\\n" (format "%S" var))))

(defun org-babel-variable-assignments:coffeescript (params)
  "Return list of Javascript statements assigning the block's variables."
  (mapcar
   (lambda (pair) (format "%s=%s"
                          (car pair) (org-babel-coffeescript-var-to-coffee (cdr pair))))
   (org-babel-coffeescript-get-vars params)))

(defun org-babel-coffeescript-get-vars (params)
  "org-babel-get-header was removed in org version 8.3.3"
  (if (fboundp 'org-babel-get-header)
      (mapcar #'cdr (org-babel-get-header params :var))
    (org-babel--get-vars params)))

(defun org-babel-coffeescript-read (results)
  "Convert RESULTS into an appropriate elisp value.
If RESULTS look like a table, then convert them into an
Emacs-lisp table, otherwise return the results as a string."
  (org-babel-read
   (if (and (stringp results)
            (string-prefix-p "[" results)
            (string-suffix-p "]" results))
       (org-babel-read
        (concat "'"
                (replace-regexp-in-string
                 "\\[" "(" (replace-regexp-in-string
                            "\\]" ")" (replace-regexp-in-string
                                       ",[[:space:]]" " "
                                       (replace-regexp-in-string
                                        "'" "\"" results))))))
     results)))

(provide 'ob-coffeescript)
 ;;; ob-coffeescript.el ends here
