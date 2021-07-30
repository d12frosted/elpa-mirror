;;; gomacro-mode.el --- Gomacro mode and Go REPL integration -*- lexical-binding: t -*-

;; Copyright © 2020 Petter Storvik

;; Author: Petter Storvik
;; URL: https://github.com/storvik/gomacro-mode
;; Package-Version: 20200326.1103
;; Package-Commit: 3112e56d2d5e645a3e0fd877f3e810dbccbf989f
;; Version: 0.1.0
;; Created: 2019-10-28
;; Package-Requires: ((emacs "24.4") (go-mode "1.5.0"))
;; Keywords: gomacro repl languages tools processes

;; This file is NOT part of GNU Emacs.

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
;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This Emacs package provides bindings for working with Gomacro, a
;; read eval print loop for Go.
;;
;; Function for interfacing with the gomacro REPL are provided through
;; the "M-x" interface.  Most important functions to check out are:
;; - `gomacro-run'
;; - `gomacro-verbose-toggle'
;; - `gomacro-eval'
;; - `gomacro-eval-region'
;; - `gomacro-eval-line'
;; - `gomacro-eval-defun'
;; - `gomacro-eval-buffer'
;;
;; When `gomacro-mode' is activated the following keybindings are
;; defined:
;; - C-M-x `gomacro-eval-defun'
;; - C-c C-r `gomacro-eval-region'
;; - C-c C-l `gomacro-eval-line'
;; - C-c C-t `gomacro-verbose-toggle'
;;
;; For more information, see the readme at https://github.com/storvik/gomacro-mode

;;; Code:

(require 'comint)
(require 'go-mode)

(defconst gomacro-buffer "*GoMacro REPL*")
(defconst gomacro-buffer-name "GoMacro REPL")

(defgroup gomacro nil
  "Gomacro settings and functions."
  :group 'external
  :tag "gomacro"
  :prefix "gomacro-")

(defcustom gomacro-command "gomacro"
  "Gomacro command."
  :type 'string
  :group 'gomacro)

(defcustom gomacro-cli-arguments '()
  "Gomacro custom command line arguments."
  :type '(string)
  :group 'gomacro)

(defcustom gomacro-wait-timeout 0.1
  "Gomacro timeout when evaluating to `gomacro-buffer'.

Value will affect responsiveness."
  :type 'number
  :group 'gomacro)

(defcustom gomacro-verbose-eval nil
  "Enable verbose evaluation of statements.

If set eval functions will print statements to `gomacro-buffer'
before evaluating them.  Can be changed by calling `gomacro-verbose-toggle'
function."
  :type 'boolean
  :group 'gomacro)

(defcustom gomacro-prompt-regexp "\\(\. \. \. \. +\\)\\|\\(gomacro> \\)"
  "Prompt regexp for `gomacro-run'."
  :type 'string
  :group 'gomacro)

(defun gomacro--get-process ()
  "Get current gomacro process associated with `gomacro-buffer'."
  (get-buffer-process gomacro-buffer))

;;; GoMacro REPL and its major mode

(defvar gomacro-inferior-mode-map
  (let ((map (nconc (make-sparse-keymap) comint-mode-map)))
    ;; example definition
    (define-key map "\t" 'completion-at-point)
    map)
  "Basic mode map for `gomacro-run'.")

;;;###autoload
(defun gomacro-run ()
  "Run an inferior instance of `gomacro' inside Emacs."
  (interactive)
  (let* ((buffer (comint-check-proc gomacro-buffer)))
    ;; pop to the `*Gomacro REPL*' buffer if the process is dead, the
    ;; buffer is missing or it's got the wrong mode.
    (pop-to-buffer
     (if (or buffer (not (derived-mode-p 'gomacro-inferior-mode))
             (comint-check-proc (current-buffer)))
         (get-buffer-create gomacro-buffer)
       (current-buffer)))
    ;; create the comint process if there is no buffer.
    (unless buffer
      (apply 'make-comint-in-buffer gomacro-buffer-name buffer
             gomacro-command nil gomacro-cli-arguments)
      (gomacro-inferior-mode))))

(defun gomacro-verbose-toggle ()
  "Toggle `gomacro-verbose-eval'."
  (interactive)
  (setq gomacro-verbose-eval (not gomacro-verbose-eval)))

(defun gomacro-running-p ()
  "Check if gomacro REPL is running or not."
  (comint-check-proc gomacro-buffer))

(defun gomacro-eval (stmt)
  "Evaluate STMT in `gomacro-buffer'."
  (interactive "MEval statement: \n")
  (unless (gomacro-running-p)
    (gomacro-run))
  (with-current-buffer gomacro-buffer
    (while (not (looking-back gomacro-prompt-regexp nil))
      (goto-char (point-max))
      (sit-for gomacro-wait-timeout))
    (goto-char (point-max))
    (insert stmt)
    (comint-send-input)))

(defun gomacro--eval-silent (stmt &optional history)
  "Evaluate STMT in `gomacro-buffer' without printing STMT.

If HISTORY is set STMT is also added to comint history."
  (unless (gomacro-running-p)
    (gomacro-run))
  (with-current-buffer gomacro-buffer
    (comint-send-string (gomacro--get-process) (concat stmt "\n"))
    (when history
      (comint-add-to-input-history stmt))))

(defun gomacro--print-text (str &optional cancel-prompt)
  "Print STR in `gomacro-buffer'.

If CANCEL-PROMPT is set new new prompt will be cancelled."
  (unless (gomacro-running-p)
    (gomacro-run))
  (with-current-buffer gomacro-buffer
    (while (not (looking-back gomacro-prompt-regexp nil))
      (goto-char (point-max))
      (sit-for gomacro-wait-timeout))
    (goto-char (point-max))
    (comint-goto-process-mark)
    (insert str)
    (when cancel-prompt
      (insert "\n"))
    (comint-set-process-mark)
    (unless cancel-prompt
      (comint-send-input))))

(defun gomacro--sanitize-string (str)
  "Sanitize create valid Go code from STR.

Removes newlines from STR and replaces them with semicolons."
  (replace-regexp-in-string
   "  +" " "
   (replace-regexp-in-string
    "\\(\n\\|\t\\)" ""
    (replace-regexp-in-string
     "[^{\\|(\\|,]\\(\n\\)" ";"
     (replace-regexp-in-string " *?//.*" "" str) nil nil 1))))

(defconst gomacro-keywords
  '(":debug" ":env" ":help" ":inspect" ":options" ":package" ":quit" ":unload" ":write")
  "Special keywords that should be highlighted.")

(defvar gomacro-font-lock-keywords
  (list
   `(,(concat (regexp-opt gomacro-keywords)) . font-lock-keyword-face))
  "Additional expressions to highlight in `gomacro-inferior-mode'.")

(define-derived-mode gomacro-inferior-mode comint-mode gomacro-buffer-name
  "Major mode for `gomacro-run' comint buffer.

\\<gomacro-inferior-mode-map>"
  nil gomacro-buffer-name
  :syntax-table go-mode-syntax-table
  (setq comint-prompt-read-only t)
  (setq comint-prompt-regexp gomacro-prompt-regexp)
  ;; (setq comint-use-prompt-regexp t)
  (set (make-local-variable 'paragraph-separate) "\\'")
  (set (make-local-variable 'font-lock-defaults) '(gomacro-font-lock-keywords t))
  (set (make-local-variable 'paragraph-start) gomacro-prompt-regexp))

;;; GoMacro minor mode

(defun gomacro-eval-region (begin end)
  "Evaluate selected region between BEGIN and END.

If `gomacro-verbose-eval' is set text is sent to `gomacro-buffer' line by line."
  (interactive "r")
  (if gomacro-verbose-eval
      (mapcar 'gomacro-eval (split-string (buffer-substring-no-properties begin end) "\n"))
    (gomacro--print-text "Region sent to gomacro REPL" t)
    (gomacro--eval-silent (gomacro--sanitize-string (buffer-substring-no-properties begin end)))))

(defun gomacro-eval-line ()
  "Evaluate current line."
  (interactive)
  (gomacro-eval-region (line-beginning-position) (line-end-position)))

(defun gomacro-eval-defun ()
  "Evaluate the nearest function, type or import statement.

This function will select whichever function, type or import statement that is
nearest to current cursor position and pass it to `gomacro-buffer' REPL."
  (interactive)
  (let ((nearest '(-1 -1))              ; -1 is an invalid position
        (lst (list (gomacro--get-nearest-function)
                   (gomacro--get-nearest-type)
                   (gomacro--get-nearest-import))))
    (dolist (element lst nearest)
      (when (car element)
        (when (> (car element) (car nearest))
          (setq nearest element))))
    (if (= (car nearest) -1)
        (message "No function, type or import found.")
      (apply 'gomacro-eval-region nearest))))

(defun gomacro--get-nearest-function ()
  "Find nearest function and return a list (beginning end)."
  (save-excursion
    (goto-char (line-end-position))
    `(,(re-search-backward "^func\ \\(.*\\)+\ [a-zA-z]*\\(.*\\)\ {" nil t)
      ,(re-search-forward "^}"))))

(defun gomacro--get-nearest-type ()
  "Find nearest type definition and return a list (beginning end)."
  (save-excursion
    (goto-char (line-end-position))
    `(,(re-search-backward "^type [a-zA-z]* \\(struct\\|interface\\) {" nil t)
      ,(re-search-forward "^}"))))

(defun gomacro--get-nearest-import ()
  "Find nearest import statement  and return a list (beginning end)."
  (save-excursion
    (goto-char (line-end-position))
    `(,(re-search-backward "^import (" nil t)
      ,(re-search-forward "^)"))))

(defun gomacro-eval-buffer ()
  "Evaluate entire buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (re-search-forward "package .*\n")
    (gomacro-eval-region (point) (point-max))))

(defun gomacro-eval-file (gofile)
  "Evaluate GOFILE.

If run interactively function will prompt for file."
  (interactive "fFind file to evaluate: ")
  (with-temp-buffer
    (insert-file-contents gofile)
    (gomacro-eval-buffer)))

(defun gomacro-eval-package (gopath)
  "Evaluate all files in dir GOPATH.

If run interactively function will prompt for path.  When
GOPATH is set to filename all other files in given directory
will be processed too."
  (interactive "GEnter path to package: ")
  (mapc 'gomacro-eval-file
        (directory-files (file-name-directory gopath) t ".go$")))

(defvar gomacro-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-M-x") #'gomacro-eval-defun)
    (define-key map (kbd "C-c C-r") #'gomacro-eval-region)
    (define-key map (kbd "C-c C-l") #'gomacro-eval-line)
    (define-key map (kbd "C-c C-t") #'gomacro-verbose-toggle)
    map)
  "Gomacro minor mode keymap.")

(defvar gomacro-mode-lighter " Gomacro"
  "Text displayed in the mode line (lighter) gomacro minor mode is active.")

;;;###autoload
(define-minor-mode gomacro-mode
  "A minor mode for for interacting with the gomacro REPL."
  :group 'gomacro
  :lighter gomacro-mode-lighter
  :keymap gomacro-mode-map)

(provide 'gomacro-mode)

;;; gomacro-mode.el ends here
