;;; gorepl-mode.el --- Go REPL Interactive Development in top of Gore -*- lexical-binding: t -*-

;; Copyright © 2015-2016 Manuel Alonso

;; Author: Manuel Alonso <manuteali@gmail.com>
;; Maintainer: Manuel Alonso <manuteali@gmail.com>
;; URL: http://www.github.com/manute/gorepl-mode
;; Package-Version: 20170905.945
;; Package-Commit: 6a73bf352e8d893f89cad36c958c4db2b5e35e07
;; Version: 1.0.0
;; Package-Requires: ((emacs "24") (s "1.11.0") (f "0.19.0") (hydra "0.13.0"))
;; Keywords: languages, go, golang, gorepl

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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
;;
;; This library provides a Go repl interactive development environment for Emacs, built on
;; top of Gore (https://github.com/motemen/gore).
;;
;;; Code:

(require 's)
(require 'f)
(require 'hydra)

(defgroup gorepl nil
  "GO repl interactive"
  :prefix "gorepl-"
  :group 'applications
  :link '(url-link :tag "Github" "https://github.com/manute/gorepl-mode")
  :link '(emacs-commentary-link :tag "Commentary" "gorepl"))

(defcustom gorepl-command
  "gore"
  "The command used to execute gore."
  :type 'string
  :group 'gorepl)


(defcustom gorepl-mode-hook nil
  "Hook called by `gorepl-mode'."
  :type 'hook
  :group 'gorepl)


(defconst gorepl-version "1.0.0")
(defconst gorepl-buffer "*Go REPL*")
(defconst gorepl-buffer-name "Go REPL")


;; MANY THANKS to masteringenmacs for this:
;; https://www.masteringemacs.org/article/comint-writing-command-interpreter
(defun gorepl--run-gore (args)
  "Run an inferior instance of `gore' inside Emacs."
  (let* ((buffer (comint-check-proc gorepl-buffer-name)))
    ;; pop to the "*GO REPL Buffer*" buffer if the process is dead, the
    ;; buffer is missing or it's got the wrong mode.
    (display-buffer
     (if (or buffer (not (derived-mode-p 'gorepl-mode))
             (comint-check-proc (current-buffer)))
         (get-buffer-create (or buffer gorepl-buffer))
       (current-buffer)))
    ;; create the comint process if there is no buffer.
    (unless buffer
      (apply 'make-comint-in-buffer gorepl-buffer-name buffer
             gorepl-command nil args)
      (gorepl-mode))))


;;;;;;;;;;;;;;;;;;;;;;;
;; API
;;;;;;;;;;;;;;;;;;;;;;

(defun gorepl-version ()
  "Display GoREPL's version."
  (interactive)
  (message "GOREPL %s" gorepl-version))

(defun gorepl-run ()
  "Start or switch to the GoREPL buffer"
  (interactive)
  (message "Entering gore session...")
  (gorepl--run-gore '()))

(defun gorepl-eval (stmt)
  "Send `stmt' to gore, maybe starting it"
  (interactive)
  (gorepl-run)
  (with-current-buffer gorepl-buffer
    (insert stmt)
    (comint-send-input)
    (message (format "Just sent to gore: %s" stmt))))

(defun gorepl-eval-region (begin end)
  "Evaluate region selected."
  (interactive "r")
  (gorepl-mode t)
  (let ((cmd (buffer-substring begin end)))
    (gorepl-eval cmd)))

(defun gorepl-eval-line (&optional arg)
  "Evaluate current line."
  (interactive "P")
  (unless arg
    (setq arg 1))
  (when (> arg 0)
    (gorepl-eval-region
     (line-beginning-position)
     (line-end-position arg))))

(defun gorepl-run-load-current-file ()
  "Run a GoREPL with a context file in it"
  (interactive)
  (gorepl--run-gore (list "-context" (buffer-file-name))))

(defun gorepl-import ()
  "Import <pkg path>"
  (interactive)
  (catch 'err
    (let ((name (read-string "Package path? ")))
      (unless name
        (message "No package specified")
        (throw 'err nil))
      (let ((name (s-trim (s-chomp name))))
        (unless (s-present? name)
          (message "No package specified")
          (throw 'err nil))
        (when (s-contains? " " name)
          (message "Package names can't contain a space")
          (throw 'err nil))
        (message (format "Package specified: %s" name))
        (let ((stmt (format ":import %s" name)))
          (gorepl-eval stmt))))))

(defun gorepl-print ()
  "Print the source code from this session"
  (interactive)
  (gorepl-eval ":print"))

(defun gorepl-write ()
  "Write the source code from this session out to a file"
  (interactive)
  (let ((name (read-file-name "Output file name? ")))
    (message (format "Output file name: %s" name))
    (let ((name (f-expand name)))
      (catch 'err
        (when (s-blank? name)
          (message "Aborted write: no file name given")
          (throw 'err nil))
        (if (f-exists? name) (progn (message "Stomping: %s" name) (f-touch name))
          (progn
            (f-write-text (format "// gore dump on `%s' by `%s'\n\n"
                                  (format-time-string
                                   "%a %b %d %H:%M:%S %Z %Y"
                                   (current-time))
                                  (user-original-login-name))
                          'utf-8
                          name)))
        (let ((stmt (format ":write %s" name)))
          (gorepl-eval stmt))))))

(defun gorepl-doc ()
  "Show documentation on <expression or package "
  (interactive)
  (let ((exp-or-pkg (read-string "Expression or package? ")))
    (if (not exp-or-pkg) (message "Aborted documentation: no expression or package provided")
      (let ((stmt (format ":doc %s" exp-or-pkg)))
        (gorepl-eval stmt)))))

(defun gorepl-help ()
  "Show help"
  (interactive)
  (let ((stmt ":help"))
    (gorepl-eval stmt)))

(defun gorepl-quit ()
  "Quit"
  (interactive)
  (if (comint-check-proc gorepl-buffer)
      (let ((stmt ":quit"))
        (gorepl-eval stmt))
    (message "gore is already stopped")))

(defun gorepl-restart ()
  "Restart gore. In others words: start a fresh gore session."
  (interactive)
  (gorepl-quit)
  (sleep-for 1)
  (gorepl-run))

(defun gorepl-eval-line-goto-next-line ()
  "Evaluate this line and move to next."
  (interactive)
  (call-interactively 'gorepl-eval-line)
  (call-interactively 'next-logical-line))

(defhydra gorepl-hydra (:color teal :hint nil)
  "
^(Go RE)PL
 Run^              ^| ^Eval^         | ^REPL^
-^-----------------^+--------------+------------------------------------
 _d_: Run empty     | _j_: Selection | _t_: Import <pkg path>
 _f_: Run this file | _k_: Line+Step | _y_: Print this source
 _q_: Quit Hydra    | _K_: Line      | _u_: Write this sourceto <file name>
                  ^^|              ^^| _o_: List `these' actual commands
                  ^^|              ^^| _r_: Restart this REPL
                  ^^|              ^^| _p_: Quit this REPL (or C-d)
"
  ("d" gorepl-run)
  ("f" gorepl-run-load-current-file)
  ("j" gorepl-eval-region)
  ("r" gorepl-restart)
  ("k" gorepl-eval-line-goto-next-line :exit nil)
  ("K" gorepl-eval-line)
  ("t" gorepl-import)
  ("y" gorepl-print)
  ("u" gorepl-write)
  ("i" gorepl-doc)
  ("o" gorepl-help)
  ("p" gorepl-quit)
  ("q" nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DEFINE MINOR MODE
;;
;; Many thanks -> https://github.com/ruediger/rusti.el
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar gorepl-mode-map
  (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c C-g") #'gorepl-run)
            (define-key map (kbd "C-c C-l") #'gorepl-run-load-current-file)
            (define-key map (kbd "C-c C-e") #'gorepl-eval-region)
            (define-key map (kbd "C-c C-r") #'gorepl-eval-line)
            map)
  "Mode map for `gorepl-mode'.")

(defcustom gorepl-mode-lighter " Gorepl"
  "Text displayed in the mode line (Lighter) if `gorepl-mode' is active."
  :group 'gorepl
  :type 'string)

;;;###autoload
(define-minor-mode gorepl-mode
  "A minor mode for run a go repl on top of gore"
  :group 'gorepl
  :lighter gorepl-mode-lighter
  :keymap gorepl-mode-map)


(provide 'gorepl-mode)
;;; gorepl-mode.el ends here
