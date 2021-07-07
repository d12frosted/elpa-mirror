;;; inf-crystal.el --- Run a Inferior-Crystal process in a buffer

;; Copyright (C) 2017-2018 Brantou

;; Author: Brantou <brantou89@gmail.com>
;; URL: https://github.com/brantou/inf-crystal.el
;; Package-Commit: 02007b2a2a3bea44902d7c83c4acba1e39d278e3
;; Package-Version: 20180119.211
;; Package-X-Original-Version: 20180105.1610
;; Keywords: languages crystal
;; Version: 0.1.1
;; Package-Requires: ((emacs "24.3") (crystal-mode "0.1.0"))

;; This file is not part of GNU Emacs.

;;; License:

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
;; inf-crystal provides a REPL buffer connected
;; to a [icr](https://github.com/crystal-community/icr) subprocess.
;; It's based on ideas from the popular `inferior-lisp` package.
;;
;; `inf-crystal` has two components - a basic crystal REPL
;; and a minor mode (`inf-crystal-minor-mode`), which
;; extends `crystal-mode` with commands to evaluate forms directly in the
;; REPL.
;;
;; `inf-crystal` provides a set of essential features for interactive
;; Crystal development:
;;
;; * REPL
;; * Interactive code evaluation
;;
;; ### ICR
;;
;; To be able to connect to [inf-crystal](https://github.com/brantou/inf-crystal.el),
;; you need to make sure that [icr](https://github.com/crystal-community/icr) is installed.
;; Installation instructions can be found on
;; the main page of [icr](https://github.com/crystal-community/icr#installation).
;;
;; ### Installation
;;
;; #### Via package.el
;;
;; TODO
;;
;; #### Manual
;;
;; If you're installing manually, you'll need to:
;; * drop the file somewhere on your load path (perhaps ~/.emacs.d)
;; * Add the following lines to your .emacs file:
;;
;; ```elisp
;;    (autoload 'inf-crystal "inf-crystal" "Run an inferior Crystal process" t)
;;    (add-hook 'crystal-mode-hook 'inf-crystal-minor-mode)
;; ```
;;
;; ### Usage
;;
;; Run one of the predefined interactive functions.
;;
;; See [Function Documentation](#function-documentation) for details.
;;

;;; Code:

(require 'comint)
(require 'crystal-mode)

(defgroup inf-crystal nil
  "Run inferior crystal process in an Emacs buffer"
  :group 'crystal
  :link '(url-link :tag "GitHub" "https://github.com/brantou/inf-crystal.el")
  :link '(emacs-commentary-link :tag "Commentary" "inf-crystal"))

(defcustom inf-crystal-prompt-read-only t
  "If non-nil, the prompt will be read-only.

Also see the description of `ielm-prompt-read-only'."
  :type 'boolean
  :group 'inf-crystal)

(defcustom inf-crystal-filter-regexp
  "\\`\\s *\\(:\\(\\w\\|\\s_\\)\\)?\\s *\\'"
  "What not to save on inferior Crystal's input history.
Input matching this regexp is not saved on the input history in Inferior Crystal
mode.  Default is whitespace followed by 0 or 1 single-letter colon-keyword
\(as in :a, :c, etc.)"
  :type 'regexp)

(defcustom inf-crystal-buffer-name "*inferior-crystal*"
  "Default buffer name for ‘inf-crystal’."
  :type 'string
  :safe 'stringp
  :group 'inf-crystal)

(defcustom inf-crystal-interpreter "icr"
  "Default crystal interpreter for ‘inf-crystal’."
  :type 'string
  :group 'inf-crystal)

(defvar inf-crystal-buffer  nil
  "*The live ‘inf-crystal’ process buffer.

MULTIPLE PROCESS SUPPORT
===========================================================================
To run multiple Crystal processes, you start the first up
with \\[inf-crystal].  It will be in a buffer named `*inf-crystal*'.
Rename this buffer with \\[rename-buffer].  You may now start up a new
process with another \\[inf-crystal].  It will be in a new buffer,
named `*inf-crystal*'.  You can switch between the different process
buffers with \\[switch-to-buffer].

Commands that send text from source buffers to Crystal processes --
like `crystal-send-definition' or `crystal-send-region' -- have to choose a
process to send to, when you have more than one Crystal process around.  This
is determined by the global variable `inf-crystal-buffer'.  Suppose you
have three inferior Crystals running:
    Buffer              Process
    foo                 inf-crystal
    bar                 inf-crystal<2>
    *inf-crystal*       inf-crystal<3>
If you do a \\[crystal-send-definition] command on some Crystal source code,
what process do you send it to?

- If you're in a process buffer (foo, bar, or *inf-crystal*),
  you send it to that process.
- If you're in some other buffer (e.g., a source file), you
  send it to the process attached to buffer `inf-crystal-buffer'.
This process selection is performed by function `inf-crystal-proc'.

Whenever \\[inf-crystal] fires up a new process, it resets
`inf-crystal-buffer' to be the new process's buffer.  If you only run
one process, this does the right thing.  If you run multiple
processes, you might need to change `inf-crystal-buffer' to
whichever process buffer you want to use.")

(defvar inf-crystal-mode-hook '()
  "Hook for customizing Inferior Crystal mode.")

(defcustom inf-crystal-prompt "icr([0-9]\\(\\.[0-9]+\\)+) >"
  "Regexp to recognize prompts in the Inferior Crystal mode."
  :type 'regexp
  :group 'inf-crystal)

(defcustom inf-crystal-use-same-window nil
  "Controls whether to display the REPL buffer in the current window or not."
  :type '(choice (const :tag "same" t)
                 (const :tag "different" nil))
  :safe #'booleanp
  :group 'inf-crystal)

(defvar inf-crystal-mode-map
  (let ((map (copy-keymap comint-mode-map)))
    (define-key map (kbd "C-x C-e") 'crystal-send-last-sexp)
    (define-key map (kbd "C-c C-d") 'inf-crystal-toggle-debug-mode)
    (define-key map (kbd "C-c C-p") 'inf-crystal-enable-paste-mode)
    (define-key map (kbd "C-c C-y") 'inf-crystal-disable-paste-mode)
    (define-key map (kbd "C-c C-r") 'inf-crystal-reset)
    (define-key map (kbd "C-c M-o") 'inf-crystal-clear-repl-buffer)
    (define-key map (kbd "C-c C-q") 'inf-crystal-quit)
    (easy-menu-define inf-crystal-mode-menu map
      "Inf Crystal Menu"
      '("Inf-Crystal"
        ["Eval Last Sexp" crystal-send-last-sexp t]
        "--"
        ["Toggle debug mode" inf-crystal-toggle-debug-mode t]
        ["Reset repl" inf-crystal-reset t]
        "--"
        ["Enable paste mode" inf-crystal-enable-paste-mode t]
        ["Disable paste mode" inf-crystal-disable-paste-mode t]
        "--"
        ["Clear REPL" inf-crystal-clear-repl-buffer]
        ["Restart" inf-crystal-restart]
        ["Quit" inf-crystal-quit]))
    map)
  "Mode map for `inf-crystal-mode'.")

(define-derived-mode inf-crystal-mode comint-mode "Inf-Crystal"
  "Major mode for interacting with an icr process."
  :syntax-table crystal-mode-syntax-table
  (crystal-mode-variables)
  (setq mode-line-process '(":%s on " (:eval (buffer-name inf-crystal-buffer))))
  (setq-local font-lock-defaults '((crystal-font-lock-keywords)))
  (setq comint-prompt-regexp inf-crystal-prompt)
  (setq comint-process-echoes t)
  (setq comint-input-ignoredups t)
  (setq comint-input-filter 'inf-crystal--input-filter)
  (setq comint-get-old-input 'inf-crystal--get-old-input)
  (add-hook 'comint-preoutput-filter-functions 'inf-crystal--preoutput-filter nil t)
  (setq-local comint-prompt-read-only inf-crystal-prompt-read-only)
  (ansi-color-for-comint-mode-on))

(defun inf-crystal--get-old-input()
  "Return a string containing the sexp ending at point."
  (save-excursion
    (let ((end (point)))
      (crystal-backward-sexp)
      (buffer-substring (point) end))))

(defun inf-crystal--preoutput-filter (output)
  "Filter paste mode OUTPUT."
  (if (and (string-match "Ctrl-D" output) (string-match "paste mode" output))
      "\n"
    output))

(defun inf-crystal--input-filter (str)
  "Return t if STR does not match `inf-crystal-filter-regexp'."
  (not (string-match inf-crystal-filter-regexp str)))

(defun inf-crystal-reset ()
  "Clear out all of the accumulated commands."
  (interactive)
  (comint-send-string (inf-crystal-proc) "reset\n"))

(defun inf-crystal-toggle-debug-mode ()
  "Toggle debug mode off and on.
In debug mode icr will print the code before executing it."
  (interactive)
  (comint-send-string (inf-crystal-proc) "debug\n"))

(defun inf-crystal-enable-paste-mode ()
  "Enable paste mode."
  (interactive)
  (comint-send-string (inf-crystal-proc) "paste\n"))

(defun inf-crystal-disable-paste-mode ()
  "Disable paste mode."
  (interactive)
  (with-current-buffer (inf-crystal-buffer)
    (comint-send-eof)))

(defun inf-crystal-clear-repl-buffer ()
  "Clear the REPL buffer."
  (interactive)
  (let ((comint-buffer-maximum-size 0))
    (comint-truncate-buffer)))

(defun inf-crystal-quit (&optional buffer)
  "Kill the REPL buffer and its underlying process.

You can pass the target BUFFER as an optional parameter
to suppress the usage of the target buffer discovery logic."
  (interactive)
  (let ((target-buffer (or buffer (inf-crystal-buffer))))
    (when (get-buffer-process target-buffer)
      (delete-process target-buffer))
    (kill-buffer target-buffer)))

(defun inf-crystal-restart (&optional buffer)
  "Restart the REPL buffer and its underlying process.

You can pass the target BUFFER as an optional parameter
to suppress the usage of the target buffer discovery logic."
  (interactive)
  (let* ((target-buffer (or buffer (inf-crystal-buffer)))
         (target-buffer-name (buffer-name target-buffer)))
    (inf-crystal-quit target-buffer)
    (inf-crystal inf-crystal-interpreter)
    (rename-buffer target-buffer-name)))

;;;###autoload
(defun inf-crystal (cmd)
  "Launch a crystal interpreter in a buffer.
using `inf-crystal-interpreter'as an inferior mode.

Argument CMD defaults to `inf-crystal-interpreter'.
When called interactively with `prefix-arg', it allows
the user to edit such value."
  (interactive (list (if current-prefix-arg
                         (read-string "Run inf-crystal: " inf-crystal-interpreter)
                       inf-crystal-interpreter)))
  (if (not (comint-check-proc inf-crystal-buffer-name))
      (let ((cmdlist (split-string cmd))
            (name "crystal"))
        (unless (member "--no-color" cmdlist)
          (setq cmdlist (append cmdlist '("--no-color"))))
        (set-buffer (apply 'make-comint-in-buffer
                           name
                           (get-buffer-create inf-crystal-buffer-name)
                           (car cmdlist)
                           nil
                           (cdr cmdlist)))
        (inf-crystal-mode)))
  (setq inf-crystal-buffer inf-crystal-buffer-name)
  (if inf-crystal-use-same-window
      (pop-to-buffer-same-window inf-crystal-buffer-name)
    (pop-to-buffer inf-crystal-buffer-name)))

;;;###autoload
(defalias 'run-crystal 'inf-crystal)

(defun inf-crystal-proc()
  "Returns the current inferior crystal process.
See variable `inf-crystal-buffer'."
  (let ((proc (get-buffer-process (if (derived-mode-p 'inf-crystal-mode)
                                      (current-buffer)
                                    inf-crystal-buffer))))
    (or proc
        (error "No inf-crystal subprocess, see variable inf-crystal-buffer"))))

(defun inf-crystal-buffer()
  "Returns the current inferior crystal buffer.
See variable `inf-crystal-buffer'."
  (let ((buf (if (derived-mode-p 'inf-crystal-mode)
                 (current-buffer)
               inf-crystal-buffer)))
    (or buf
        (error "No inf-crystal buffer, see variable inf-crystal-buffer"))))

(defun crystal-switch-to-inf(eob-p)
  "Switch to the inf-crystal process buffer.
With argument, positions cursor at end of buffer."
  (interactive "P")
  (if (get-buffer-process inf-crystal-buffer)
      (let ((pop-up-frames
             ;; Be willing to use another frame
             ;; that already has the window in it.
             (or pop-up-frames
                 (get-buffer-window inf-crystal-buffer t))))
        (pop-to-buffer inf-crystal-buffer))
    (run-crystal inf-crystal-interpreter))
  (cond (eob-p
         (push-mark)
         (goto-char (point-max)))))

(defun crystal-send-last-sexp ()
  "Send the previous sexp to the inferior crystal process."
  (interactive)
  (crystal-send-region (save-excursion (crystal-backward-sexp) (point)) (point)))

(defun crystal-send-line ()
  "Send the current line to the inferior crystal process."
  (interactive)
  (save-restriction
    (widen)
    (crystal-send-region (point-at-bol) (point-at-eol))))

;;(defun crystal-send-block ()
;;  "Send the current block to the inferior Crystal process."
;;  (interactive)
;;  (save-excursion
;;    (crystal-end-of-block)
;;    (end-of-line)
;;    (let ((end (point)))
;;      (crystal-beginning-of-block)
;;      (crystal-send-region (point) end))))
;;
;;(defun crystal-send-block-and-go ()
;;  "Send the current block to the inferior Crystal.
;;Then switch to the process buffer."
;;  (interactive)
;;  (crystal-send-block)
;;  (crystal-switch-to-inf t))

(defun crystal-send-definition ()
  "Send the current definition to the inferior crystal process."
  (interactive)
  (save-excursion
    (end-of-defun)
    (let ((end (point)))
      (crystal-beginning-of-defun)
      (crystal-send-region (point) end))))

(defun crystal-send-definition-and-go ()
  "Send the current definition to the inferior Crystal.
Then switch to the process buffer."
  (interactive)
  (crystal-send-definition)
  (crystal-switch-to-inf t))

(defun crystal-send-region (start end)
   "Send the region delimited by START and END to inferior crystal process."
  (interactive "r")
  (let* ((string (buffer-substring-no-properties start end))
         (_ (string-match "\\`\n*\\(.*\\)" string)))
    (message "Sent: %s..." (match-string 1 string))
    (if (string-match ".\n+." string) ;Multiline
        (progn
          (comint-send-string (inf-crystal-proc) "paste\n")
          (comint-send-string (inf-crystal-proc) string)
          (with-current-buffer (inf-crystal-buffer)
            (comint-send-eof)))
      (comint-send-string (inf-crystal-proc) string))
    (when (or (not (string-match "\n\\'" string))
              (string-match "\n[ \t].*\n?\\'" string))
      (comint-send-string (inf-crystal-proc) "\n"))))

(defun crystal-send-region-and-go (start end)
  "Send the region delimited by START and END to inferior crystal process.
Then switch to the process buffer."
  (interactive "r")
  (crystal-send-region start end)
  (crystal-switch-to-inf t))

(defun crystal-send-buffer ()
  "Send the current buffer to the inferior crystal process."
  (interactive)
  (save-restriction
    (widen)
    (crystal-send-region (point-min) (point-max))))

(defun crystal-send-buffer-and-go ()
  "Send the current buffer to the inferior crystal process.
Then switch to the process buffer."
  (interactive)
  (crystal-send-buffer)
  (crystal-switch-to-inf t))

(defvar inf-crystal-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-M-x") 'crystal-send-definition)
    (define-key map (kbd "C-x C-e") 'crystal-send-last-sexp)
    (define-key map (kbd "C-c C-l") 'crystal-send-line)
    (define-key map (kbd "C-c C-b") 'crystal-send-buffer)
    (define-key map (kbd "C-c M-b") 'crystal-send-buffer-and-go)
    (define-key map (kbd "C-c C-x") 'crystal-send-definition)
    (define-key map (kbd "C-c M-x") 'crystal-send-definition-and-go)
    (define-key map (kbd "C-c C-r") 'crystal-send-region)
    (define-key map (kbd "C-c M-r") 'crystal-send-region-and-go)
    (define-key map (kbd "C-c C-z") 'crystal-switch-to-inf)
    (define-key map (kbd "C-c C-s") 'inf-crystal)
    (define-key map (kbd "C-c C-q") 'inf-crystal-quit)
    (easy-menu-define
      inf-crystal-minor-mode-menu
      map
      "Inferior Crystal Minor Mode Menu"
      '("Inf-Crystal"
        ["Send last expression" crystal-send-last-sexp t]
        ["Send line" crystal-send-line t]
        ["Send definition" crystal-send-definition t]
        ["Send buffer" crystal-send-buffer t]
        ["Send region" crystal-send-region t]
        "--"
        ["Start REPL" inf-crystal t]
        ["Switch to REPL" crystal-switch-to-inf t]
        ["Restart REPL" inf-crystal-restart]
        ["Quit REPL" inf-crystal-quit]))
    map))

;;;###autoload
(define-minor-mode inf-crystal-minor-mode
  "Minor mode for interacting with the inferior process buffer.

The following commands are available:

\\{inf-crystal-minor-mode-map}"
  :lighter " Icr"
  :keymap inf-crystal-minor-mode-map)

(provide 'inf-crystal)
;;; inf-crystal.el ends here
