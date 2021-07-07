;;; vdm-comint.el --- REPL support for vdm-mode -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Peter W. V. Tran-Jørgensen
;; Author: Peter W. V. Tran-Jørgensen <peter.w.v.jorgensen@gmail.com>
;; Maintainer: Peter W. V. Tran-Jørgensen <peter.w.v.jorgensen@gmail.com>
;; URL: https://github.com/peterwvj/vdm-mode
;; Package-Version: 20181127.2023
;; Package-Commit: 89e7db6ee1a89b8c1f7ce36ce6800c32b5c4ba2d
;; Created: 11th November 2018
;; Version: 0.0.4
;; Keywords: languages
;; Package-Requires: ((emacs "25") (vdm-mode "0.0.4"))

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; vdm-comint enables you to run a VDM interpreter inside Emacs.  Both
;; the Overture and VDMJ interpreters are supported.


;;; Code:

(require 'vdm-mode)
(require 'vdm-mode-util)
(require 'comint)

(defgroup vdm-comint nil
  "Run a VDM interpreter in a buffer."
  :group 'vdm-comint)

(defcustom vdm-comint-command nil
  "VDM interpreter."
  :type 'string
  :group 'vdm-comint)

(defcustom vdm-comint-extra-args '()
  "Extra arguments passed to the interpreter."
  :type '(repeat string)
  :group 'vdm-comint)

(defvar vdm-comint-buffer "VDM REPL"
  "Name of the repl buffer.")

(defun vdm-comint-get-process ()
  "Get repl process."
  (and vdm-comint-buffer
       (get-process vdm-comint-buffer)))

(defun vdm-comint-get-buffer ()
  "Get repl buffer."
  (and vdm-comint-buffer
       (get-buffer (vdm-comint-get-buffer-name))))

(defun vdm-comint-get-buffer-name ()
  "Get repl buffer name."
  (format "*%s*" vdm-comint-buffer))

(defun vdm-comint-send-string (str)
  "Send STR to repl."
  (comint-send-string (vdm-comint-get-process)
                      (concat "p " str "\n")))

(defun vdm-comint-find-command ()
  "Find the VDM interpreter command.
  
Prefer 'vdm-comint-command' but fall back on
'flycheck-vdm-tool-jar-path'."
  (or vdm-comint-command
      (and (boundp 'flycheck-vdm-tool-jar-path)
           flycheck-vdm-tool-jar-path)))

;;;###autoload
(defun vdm-comint-kill-repl ()
  "Kill repl, if it exists."
  (interactive)
  (when (vdm-comint-get-process)
    ;; Also send 'stop' in case the debugger is active.
    (process-send-string (vdm-comint-get-process) "stop\nquit\n")))

;;;###autoload
(defun vdm-comint-send-region ()
  "Send the current region to the repl.
If no region is selected, you can manually input an expression."
  (interactive)
  (let ((str (if (region-active-p)
                 (buffer-substring-no-properties (region-beginning) (region-end))
               (read-string "Input VDM expression: "))))
    (message "Input: %s" str)
    (vdm-comint-send-string str)))

;;;###autoload
(defun vdm-comint-load-project-or-switch-to-repl ()
  "Switch to existing repl or load current VDM project in a new repl."
  (interactive)
  ;; Perform this check so we do not have to build the list of VDM
  ;; files if the repl already exists.
  (if (vdm-comint-get-process)
      (pop-to-buffer (vdm-comint-get-buffer))
    (let ((dialect (vdm-mode-util-get-dialect-arg)))
      (if dialect
          (vdm-comint-start-or-switch-to-repl dialect (vdm-mode-util-find-vdm-files))
        (error "Current buffer is not associated with a VDM file!")))))

;;;###autoload
(defun vdm-comint-start-or-switch-to-repl (&optional vdm-dialect-option vdm-files)
  "Switch to existing repl or start a new one.

VDM-DIALECT-OPTION the VDM dialect option.  If this parameter is
nil then the caller will be asked to specify a dialect.

VDM-FILES the VDM files to load in a newly created repl.

To load all VDM files associated with the current project use
'vdm-comint-load-project-or-switch-to-repl'"
  (interactive)
  (if (vdm-comint-get-process)
      (pop-to-buffer (vdm-comint-get-buffer))
    (let ((dialect (or vdm-dialect-option
                       (completing-read "Dialect: " '("-vdmsl" "-vdmpp" "-vdmrt") nil t))))
      (if dialect
          (let ((repl (vdm-comint-find-command)))
            (if repl
                (progn
                  (pop-to-buffer
                   (apply 'make-comint vdm-comint-buffer "java" nil "-jar"
                          repl dialect
                          `(
                            ,@vdm-comint-extra-args
                            ,@vdm-files "-i"
                            ))))
              (error "VDM interpreter not found!")))
        (error "Current file is not a VDM file"))
      (vdm-comint-mode))))

;;;###autoload
(define-derived-mode vdm-comint-mode comint-mode "VDM REPL"
  :group 'vdm-comint
  :syntax-table vdm-mode-syntax-table
  (set (make-local-variable 'font-lock-defaults) `((
                                                    ( ,vdm-mode-constant-regex . font-lock-constant-face)
                                                    ( ,(vdm-mode-get-keyword-regex) . font-lock-keyword-face)
                                                    ( ,vdm-mode-type-regex . font-lock-type-face)
                                                    ( ,vdm-mode-negation-char-regex . font-lock-negation-char-face)
                                                    )))

  (when (version<= "24.4" emacs-version)
    (set (make-local-variable 'prettify-symbols-alist) vdm-mode-prettify-symbols)
    (prettify-symbols-mode))

  ;; No echo
  (setq comint-process-echoes t)
  ;; Ignore duplicates
  (setq comint-input-ignoredups t))

(provide 'vdm-comint)

;;; vdm-comint.el ends here
