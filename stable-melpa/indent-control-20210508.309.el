;;; indent-control.el --- Management for indentation level  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Shen, Jen-Chieh
;; Created date 2019-07-30 09:37:44

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Management for indentation level.
;; Keyword: control indent tab generic level
;; Version: 0.3.4
;; Package-Version: 20210508.309
;; Package-Commit: ed99e867f81ef69854182b519db1b9141fcdb2a2
;; Package-Requires: ((emacs "26.1"))
;; URL: https://github.com/jcs-elpa/indent-control

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Interface that combine all the indentation variables from each major
;; mode to one giant list.
;;
;; You can set up the initial indentation level by changing the variable
;; `indent-control-records'.  This variable is a list on cons cell form
;; by (mode . level).  For example,
;;
;;   `(actionscript-mode . 4)`
;;
;; If you want to make the indentation level works consistently across
;; all buffer.  You would need to call function `indent-control-continue-with-record'
;; at the time you want the new buffer is loaded.
;;

;;; Code:

(defgroup indent-control nil
  "Visual Studio like line annotation in Emacs."
  :prefix "indent-control-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/indent-control"))

(defcustom indent-control-records
  '((actionscript-mode     . 4)
    (c-mode                . 4)
    (c++-mode              . 4)
    (csharp-mode           . 4)
    (css-mode              . 2)
    (dockerfile-mode       . 2)
    (elixir-mode           . 2)
    (elm-mode              . 4)
    (elisp-mode            . 2)
    (emacs-lisp-mode       . 2)
    (go-mode               . 4)
    (groovy-mode           . 4)
    (java-mode             . 4)
    (jayces-mode           . 4)
    (js-mode               . 2)
    (js2-mode              . 2)
    (json-mode             . 2)
    (kotlin-mode           . 4)
    (less-css-mode         . 2)
    (lisp-mode             . 2)
    (lisp-interaction-mode . 2)
    (lua-mode              . 4)
    (nasm-mode             . 4)
    (nix-mode              . 2)
    (nxml-mode             . 2)
    (objc-mode             . 4)
    (python-mode           . 4)
    (rjsx-mode             . 2)
    (ruby-mode             . 2)
    (rust-mode             . 4)
    (scss-mode             . 2)
    (sh-mode               . 2)
    (shader-mode           . 4)
    (ssass-mode            . 2)
    (sql-mode              . 1)
    (typescript-mode       . 4)
    (web-mode              . 2)
    (yaml-mode             . 2))
  "Indent level records for all `major-mode's."
  :type 'list
  :group 'indent-control)

(defcustom indent-control-alist
  '((actionscript-mode     . actionscript-indent-level)
    (c-mode                . c-basic-offset)
    (c++-mode              . c-basic-offset)
    (csharp-mode           . (c-basic-offset
                              csharp-mode-indent-offset))
    (elixir-mode           . elixir-smie-indent-basic)
    (elm-mode              . elm-indent-offset)
    (java-mode             . c-basic-offset)
    (jayces-mode           . c-basic-offset)
    (objc-mode             . c-basic-offset)
    (css-mode              . css-indent-offset)
    (less-css-mode         . css-indent-offset)
    (scss-mode             . css-indent-offset)
    (ssass-mode            . ssass-tab-width)
    (groovy-mode           . groovy-indent-offset)
    (javascript-mode       . js-indent-level)
    (js-mode               . js-indent-level)
    (js2-mode              . js2-basic-offset)
    (json-mode             . js-indent-level)
    (lisp-mode             . lisp-body-indent)
    (lisp-interaction-mode . lisp-body-indent)
    (emacs-lisp-mode       . lisp-body-indent)
    (lua-mode              . lua-indent-level)
    (nasm-mode             . nasm-basic-offset)
    (nxml-mode             . nxml-child-indent)
    (python-mode           . py-indent-offset)
    (rjsx-mode             . js-indent-level)
    (ruby-mode             . ruby-indent-level)
    (rust-mode             . rust-indent-offset)
    (sh-mode               . sh-basic-offset)
    (shader-mode           . shader-indent-offset)
    (sql-mode              . sql-indent-offset)
    (typescript-mode       . typescript-indent-level)
    (web-mode              . (web-mode-markup-indent-offset
                              web-mode-css-indent-offset
                              web-mode-code-indent-offset
                              web-mode-sql-indent-offset))
    (yaml-mode             . yaml-indent-offset))
  "AList that maps `major-mode' to each major-mode's indent level variable name."
  :type 'list
  :group 'indent-control)

(defcustom indent-control-delta 2
  "Delta value for increment/decrement indentation level."
  :type 'integer
  :group 'indent-control)

(defcustom indent-control-min-indentation-level 0
  "Minimum indentation level can be set to."
  :type 'integer
  :group 'indent-control)

(defcustom indent-control-max-indentation-level 8
  "Maximum indentation level can be set to."
  :type 'integer
  :group 'indent-control)

(defcustom indent-control-prefer-indent-size 4
  "Prefer indent size."
  :type 'integer
  :group 'indent-control)

;;
;; (@* "Util" )
;;

(defmacro indent-control--mute-apply (&rest body)
  "Execute BODY without message."
  (declare (indent 0) (debug t))
  `(let ((message-log-max nil))
     (with-temp-message (or (current-message) nil)
       (let ((inhibit-message t)) (progn ,@body)))))

(defmacro indent-control--no-log-apply (&rest body)
  "Execute BODY without write it to message buffer."
  (declare (indent 0) (debug t))
  `(let ((message-log-max nil)) (progn ,@body)))

(defun indent-control--clamp-integer (in-val in-min in-max)
  "Make sure the IN-VAL is between IN-MIN and IN-MAX."
  (cond ((<= in-val in-min) (setq in-val in-min))
        ((>= in-val in-max) (setq in-val in-max)))
  in-val)

(defun indent-control--major-mode-p (name)
  "Return non-nil if NAME is current variable `major-mode'."
  (cond ((stringp name) (string= (symbol-name major-mode) name))
        ((listp name)
         (let ((index 0) (len (length name)) current-mode-name found)
           (while (and (not found) (< index len))
             (setq current-mode-name (nth index name)
                   found (indent-control--major-mode-p current-mode-name)
                   index (1+ index)))
           found))
        ((symbolp name) (equal major-mode name))
        (t nil)))

;;
;; (@* "Core" )
;;

;;;###autoload
(defun indent-control-ensure-tab-width ()
  "Ensure variable `tab-width' is having a valid value."
  (when (null tab-width) (setq-local tab-width indent-control-prefer-indent-size)))

(defun indent-control--indent-level-name ()
  "Return symbol defined as indent level."
  (or (cdr (assoc major-mode indent-control-alist))
      (quote tab-width)))

(defun indent-control--indent-level-record (&optional record-name)
  "Return record of current indent level by RECORD-NAME."
  (unless record-name (setq record-name major-mode))
  (cdr (assoc record-name indent-control-records)))

(defun indent-control--set-indent-level-record (new-level &optional record-name)
  "Set NEW-LEVEL to RECORD-NAME indent record."
  (unless record-name (setq record-name major-mode))
  (if (assoc record-name indent-control-records)
      (setf (cdr (assoc record-name indent-control-records)) new-level)
    (indent-control-ensure-tab-width)
    (user-error "[WARNING] Indentation level record not found: %s" record-name)))

(defun indent-control-set-indent-level-by-mode (new-level)
  "Set the NEW-LEVEL for current major mode."
  (let ((var-symbol (indent-control--indent-level-name)))
    (cond ((listp var-symbol) (dolist (indent-var var-symbol) (set indent-var new-level)))
          (t (set var-symbol new-level))))
  (when (and (integerp new-level)
             (indent-control--set-indent-level-record new-level))
    (indent-control--no-log-apply
      (message "[INFO] Current indent level: %s" new-level))))

(defun indent-control-get-indent-level-by-mode ()
  "Get indentation level by mode."
  (let ((var-symbol (indent-control--indent-level-name)))
    (when (listp var-symbol) (setq var-symbol (nth 0 var-symbol)))
    (unless (symbol-value var-symbol) (indent-control-ensure-tab-width))
    (or (symbol-value var-symbol) tab-width)))

(defun indent-control--delta-indent-level (delta-value)
  "Increase/Decrease tab width by DELTA-VALUE."
  (let ((indent-level (indent-control-get-indent-level-by-mode)))
    (indent-control-set-indent-level-by-mode
     (indent-control--clamp-integer  ; Ensure this is the valid value.
      (+ indent-level delta-value)
      indent-control-min-indentation-level indent-control-max-indentation-level))))

;;;###autoload
(defun indent-control-inc-indent-level ()
  "Increase indent level by one level."
  (interactive)
  (indent-control--delta-indent-level indent-control-delta)
  (indent-for-tab-command))

;;;###autoload
(defun indent-control-dec-indent-level ()
  "Decrease indent level by one level."
  (interactive)
  (indent-control--delta-indent-level (- indent-control-delta))
  (indent-for-tab-command))

;;;###autoload
(defun indent-control-continue-with-record ()
  "Keep the tab width the same as last time modified."
  (indent-control-set-indent-level-by-mode (indent-control--indent-level-record)))

;;
;; (@* "Setup" )
;;

(defun indent-control--prog-mode-hook ()
  "Programming language mode hook."
  (indent-control--mute-apply (indent-control-continue-with-record)))

;;;###autoload
(define-minor-mode indent-control-mode
  "Minor mode 'indent-control-mode'."
  :global t
  :require 'indent-control
  :group 'indent-control
  (if indent-control-mode
      (progn
        (add-hook 'prog-mode-hook #'indent-control--prog-mode-hook)
        (indent-control--prog-mode-hook))  ; Activate it immediately
    (remove-hook 'prog-mode-hook #'indent-control--prog-mode-hook)))

(provide 'indent-control)
;;; indent-control.el ends here
