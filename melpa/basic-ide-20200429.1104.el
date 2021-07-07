;;; basic-ide.el --- BASIC IDE c64                  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Fermin Munoz

;; Author: Fermin MF <fmfs@posteo.net>
;; Created: 20 Feb 2020
;; Version: 0.0.3
;; Package-Version: 20200429.1104
;; Package-Commit: 1d026b6ae70db9cde36596dcf46b101058a2e004
;; Keywords: languages, basic
;; URL: https://gitlab.com/sasanidas/emacs-c64-basic-ide
;; Package-Requires: ((emacs "25") (basic-mode "0.4.2") (company "0.9.12") (flycheck "0.22") (dash "2.12.0") (f "0.17.0"))
;; License: GPL-3.0-or-later

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

;; This is a minor mode for Emacs, that provide some IDE features for the basic-mode
;; it has flycheck and company  support, it also provide an easy way to integrate Simon’s BASIC and others similar libraries
;; Provide 3 interpreters cbmbasic, Bas 2.5 and of course VICE.
;; For the moment, it’s focus on the c64 support.

;;; Code:


(require 'cl-lib)
(require 'company)
(require 'flycheck)
(require 'eshell)
(require 'f)
(require 'dash)


;; ----------------------------------------------------------------------------
;; BASIC minor mode:
;; ----------------------------------------------------------------------------
(defgroup basic-ide nil
  "Basic IDE group declaration"
  :prefix "basic-ide-"
  :group 'languages)

;; ----------------------------------------------------------------------------
;; Customization:
;; ----------------------------------------------------------------------------

(defcustom basic-ide-basic-version "2"
  "Basic version to use in the project."
  :group 'basic-ide
  :type '(choice (const :tag "Basic v2.0" "2")
		 (const :tag "Basic v2.0 with Simons' Basic" "simon")))

(defcustom basic-ide-petcat-executable "petcat"
  "Basic IDE petcat executable location."
  :type 'string
  :group 'basic-ide)

(defcustom basic-ide-cbmbasic-executable "cbmbasic"
  "Basic IDE cmbasic executable location."
  :type 'string
  :group 'basic-ide)

(defcustom basic-ide-x64-executable "/usr/bin/x64"
  "Basic IDE x64 VICE executable."
  :type 'string
  :group 'basic-ide)

(defcustom basic-ide-x64-kernal "/usr/lib/vice/C64/kernal"
  "Basic IDE x64 VICE kernal file."
  :type 'string
  :group 'basic-ide)

(defcustom basic-ide-vice-simon-disk ""
  "Basic IDE simon's basic disk location."
  :type 'string
  :group 'basic-ide)



;; ----------------------------------------------------------------------------
;; Common functions:
;; ----------------------------------------------------------------------------


(defun basic-ide-eval-region ()
  "Evaluate the selected region."
  (interactive)
  (basic-ide-local-execute t "cbmbasic-region-output"))

(defun basic-ide-interactive-execute ()
  "Evaluate current buffer and open an interactive eshell.
And it execute the content with cbmbasic."
  (interactive)
  (let* ((file--name (buffer-file-name)))
    (eshell)
    (with-current-buffer "*eshell*"
      (eshell-kill-input)
      (goto-char (point-max))
      (insert (concat basic-ide-cbmbasic-executable " " file--name))
      (eshell-send-input)
      (goto-char (point-max))
      (yank))))


(defun basic-ide-local-execute (&optional use-region output-buffer-name)
  "Execute basic code locally with cbmbasic.
https://github.com/mist64/cbmbasic it has optional parameter
USE-REGION and OUTPUT-BUFFER-NAME."
  (interactive)
  (let* ((basic--region-file (make-temp-file "basic_ide_region"))
	 (command-output (shell-command-to-string (concat basic-ide-cbmbasic-executable " "
							  (shell-quote-argument
							   (if (and use-region (use-region-p))
							       (progn (write-region
								       (let* ((pos1 (region-beginning)) (pos2 (region-end)))
									 (filter-buffer-substring pos1 pos2))
								       nil basic--region-file)
								      basic--region-file)
							     (buffer-file-name))))))
	 (local-buffer-name (if output-buffer-name (format output-buffer-name) "cbmbasic-output")))
    (with-current-buffer
	(get-buffer-create
         local-buffer-name)
      (erase-buffer)
      (insert command-output))))


;; ----------------------------------------------------------------------------
;; Vice functions:
;; ----------------------------------------------------------------------------

(defun basic-ide-vice-start-session ()
  "Start a vice session and open the emulator.
https://vice-emu.sourceforge.net/ ."
  (interactive)
  (async-shell-command (concat  basic-ide-x64-executable " -remotemonitor -kernal " basic-ide-x64-kernal " ") nil nil))

(defun basic-ide-vice-execute ()
  "Basic IDE execute current buffer in vice emulator.
Execute the command `basic-ide-vice-start-session' first."
  (interactive)
  (let* ((prg--temp-file (make-temp-file "f")))
    (progn
      (shell-command-to-string (concat basic-ide-petcat-executable " -wsimon -o "
				       (shell-quote-argument prg--temp-file) " "
				       (shell-quote-argument (buffer-file-name)) ))
      (shell-command-to-string  "echo 'cl' | netcat -N  localhost 6510 ")
      (shell-command-to-string (concat "echo" " 'l \"" (shell-quote-argument prg--temp-file)
				       "\" 0' | netcat -N localhost 6510")))))

(defun basic-ide-vice-load-simon-basic ()
  "Basic IDE enables simon's basic commands for VICE emulator."
  (interactive)
  (shell-command-to-string (concat  "echo " "'attach \"" basic-ide-vice-simon-disk "\" 8' | netcat -N localhost 6510 "))
  (shell-command-to-string   "echo 'load \"*\" 8' | netcat -N localhost 6510 "))

(defun basic-ide-vice-reset ()
  "Basic IDE restart the current VICE session."
  (interactive)
  (shell-command-to-string  "echo 'reset 0' | netcat -N localhost 6510 "))





;; ----------------------------------------------------------------------------
;; Flycheck checker:
;; ----------------------------------------------------------------------------

(flycheck-define-checker basic
  "A syntax checker for the Bas 2.5 interpreter
http://www.moria.de/~michael/bas/"
  :command ("bas" (eval (buffer-file-name)) )
  :error-patterns
  ((error line-start  "Error: " (message) "in line " line " at:" line-end))
  :modes basic-mode)

(add-to-list 'flycheck-checkers 'basic)


;; ----------------------------------------------------------------------------
;; Company completion:
;; ----------------------------------------------------------------------------


;; FIX: There is an error with the first
(defun basic-ide--commands ()
  "Perform a petcat command from VICE for completion."
  (let* ((pet--commands (shell-command-to-string (concat basic-ide-petcat-executable " -k" basic-ide-basic-version ))))
    (split-string  pet--commands "\t")))

(defvar basic-ide-completion-backend
  (basic-ide--commands)
  "Backend list for company mode.")

(defun basic-ide-company-backend (command &optional arg &rest ignored)
  "Function that provide the necessary backend for company mode.
The completion, requires COMMAND &optional ARG &rest IGNORED."
  (cl-case command
    (interactive (company-begin-backend 'basic-ide-completion-backend))
    (prefix (and (eq major-mode 'basic-mode)
                 (company-grab-symbol)))
    (candidates
     (-when-let* ((basic-ide-backend  basic-ide-completion-backend ))
	 (cl-remove-if-not
		 (lambda (c) (string-prefix-p arg c))
		 basic-ide-backend)))))

;; ----------------------------------------------------------------------------
;; Minor mode definition:
;; ----------------------------------------------------------------------------

(define-minor-mode basic-ide-mode
  "Basic ide minor mode for editing an managing c64 basic files
it uses flycheck, helm and company integration to provide IDE
features."
  :lighter "Basic IDE"
  :group 'basic-ide
  (add-to-list 'company-backends '(basic-ide-company-backend)))

(provide 'basic-ide)
;;; basic-ide.el ends here
