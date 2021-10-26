;;; shelldon.el --- An enhanced shell interface -*- lexical-binding: t; -*-

;; Copyright (C) 2021 overdr0ne

;; Author: overdr0ne <scmorris.dev@gmail.com>
;; Version: 1.0
;; Package-Version: 20211024.2053
;; Package-Commit: 232a52eb5d7a9c3ca9f5983140578ddd86ba33a1
;; URL: https://github.com/Overdr0ne/shelldon
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools, convenience

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

;; https://github.com/Overdr0ne/shelldon
;; Shelldon is largely just a modification of async-shell-command that
;; provides a more complete minibuffer workflow by separating command
;; outputs into searchable, separate buffers among other things.

;;; Code:

(require 'cl-lib)
(require 'shell)
(require 'dired)

(defgroup shelldon nil
  "A shell command interface that keeps track of output buffers."
  :group 'convenience
  :prefix "shelldon-")

(defcustom shelldon-prompt-str ">> "
  "A string prepending the shelldon prompt, much like the PS1 EV in BASH."
  :type 'editable-field)

(defcustom shelldon-ansi-colors nil
  "Toggle ANSI color output on shelldon’s output."
  :type 'toggle)

(defun shelldon-cd ()
  "Change directories without leaving shelldon context.

Get the workdir, then throw it back for the shelldon command to set it in that
context."
  (interactive)
  (let (shelldon-wd)
    (setq shelldon-wd (call-interactively #'cd))
    (throw 'shelldon-cwd shelldon-wd)))

(defvar shelldon-minibuffer-local-command-map
  (let ((map (copy-keymap minibuffer-local-shell-command-map)))
    (set-keymap-parent map minibuffer-local-map)
    (define-key map (kbd "C-x C-f") #'shelldon-cd)
    map)
  "Keymap used for completing shell commands in minibuffer.")

(defvar shelldon--hist '())
(defun shelldon-async-command (command)
  "Execute string COMMAND in inferior shell; display output, if any.
With prefix argument, insert the COMMAND's output at point.

This is just a copy-pasta of the `async-shell-command' that has all the
superfluous stuff ripped out.  It also sets up a process environment for
the command that optionally enables ANSI colors.

In Elisp, you will often be better served by calling `call-process' or
`start-process' directly, since they offer more control and do not
impose the use of a shell (with its need to quote arguments)."
  (interactive
   (list
    (read-from-minibuffer
     (if shell-command-prompt-show-cwd
         (format-message "%s%s"
                         (abbreviate-file-name
                          default-directory)
                         shelldon-prompt-str)
       shelldon-prompt-str)
     nil shelldon-minibuffer-local-command-map nil
     'shell-command-history
     (let ((filename
            (cond
             (buffer-file-name)
             ((eq major-mode 'dired-mode)
              (dired-get-filename nil t)))))
       (and filename (file-relative-name filename))))))
  ;; (when current-prefix-arg (setq output-buffer current-prefix-arg))
  ;; Look for a handler in case default-directory is a remote file name.
  (let* ((output-buffer (concat "*shelldon:" (number-to-string (length shelldon--hist)) ":" command "*"))
         (hidden-output-buffer (concat " " output-buffer))
         (error-buffer shell-command-default-error-buffer)
         (handler
	  (find-file-name-handler (directory-file-name default-directory)
				  'shell-command)))
    (add-to-list 'shelldon--hist `(,(concat (number-to-string (length shelldon--hist)) ":" command) . ,hidden-output-buffer))
    (if handler
	(funcall handler 'shell-command command output-buffer error-buffer)
      ;; Output goes in a separate buffer.
      ;; Preserve the match data in case called from a program.
      ;; FIXME: It'd be ridiculous for an Elisp function to call
      ;; shell-command and assume that it won't mess the match-data!
      (save-match-data
        (let* ((buffer (get-buffer-create output-buffer))
               (proc (get-buffer-process buffer))
               (directory default-directory))
	  (with-current-buffer buffer
            (shell-command-save-pos-or-erase)
	    (setq default-directory directory)
	    (let* ((process-environment
                    (nconc
                     (list
                      (format "TERM=%s" (if shelldon-ansi-colors "eterm-color" "dumb"))
                      (format "TERMINFO=%s" data-directory)
                      (format "INSIDE_EMACS=%s" emacs-version))
                     process-environment)))
	      (setq proc
		    (start-process-shell-command "Shell" buffer command)))
	    (setq mode-line-process '(":%s"))
	    (shelldon-mode)
            (set-process-sentinel proc #'shell-command-sentinel)
	    ;; Use the comint filter for proper handling of
	    ;; carriage motion (see comint-inhibit-carriage-motion).
            (set-process-filter proc #'comint-output-filter)
            (if async-shell-command-display-buffer
                ;; Display buffer immediately.
                (display-buffer buffer '(nil (allow-no-window . t)))
              ;; Defer displaying buffer until first process output.
              ;; Use disposable named advice so that the buffer is
              ;; displayed at most once per process lifetime.
              (let ((nonce (make-symbol "nonce")))
                (add-function :before (process-filter proc)
                              (lambda (proc _string)
                                (let ((buf (process-buffer proc)))
                                  (when (buffer-live-p buf)
                                    (remove-function (process-filter proc)
                                                     nonce)
                                    (display-buffer buf))))
                              `((name . ,nonce)))))
            ;; FIXME: When the output buffer is hidden before the shell process is started,
            ;; ANSI colors are not displayed. I have no idea why.
            (rename-buffer hidden-output-buffer))))))
  nil)

(define-derived-mode shelldon-mode shell-mode "Shelldon"
  "Mode for displaying shelldon output."
  (view-mode +1))

;;;###autoload
(defun shelldon ()
  "Execute given asynchronously in the minibuffer with output history.

If the user tries to change the workdir while the command is executing, catch
the change and re-execute in the new context."
  (interactive)
  (let ((rtn t))
    (while rtn
      (setq rtn (catch 'shelldon-cwd (call-interactively #'shelldon-async-command)))
      (when rtn
        (setq default-directory rtn)
        (setq list-buffers-directory rtn)))))

;;;###autoload
(defun shelldon-loop ()
  "Loops the shelldon command to more closely emulate a terminal."
  (interactive)
  (cl-loop (call-interactively #'shelldon)))

;;;###autoload
(defun shelldon-output-history ()
  "Displays the output of the selected command from the shelldon history."
  (interactive)
  (pop-to-buffer (cdr (assoc (completing-read shelldon-prompt-str shelldon--hist) shelldon--hist))))
(defalias 'shelldon--hist #'shelldon-output-history
  "shelldon--hist is deprecated, use shelldon-output-history")

(add-to-list 'display-buffer-alist
	     `("*\\(shelldon.*\\)"
	       (display-buffer-reuse-window display-buffer-in-previous-window display-buffer-in-side-window)
	       (side . right)
	       (slot . 0)
	       (window-width . 80)
	       (reusable-frames . visible)))

;;;###autoload
(defun shelldon-send-line-at-point ()
  "Send the current line to shelldon and display the result."
  (interactive)
  (let ((cmd (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
    (shelldon-async-command cmd)))

;;;###autoload
(defun shelldon-send-region (start end)
  "Send region from START to END to shelldon and display the result."
  (interactive "r")
  (unless (region-active-p)
    (user-error "No region"))
  (let ((cmd (buffer-substring-no-properties start end)))
    (shelldon-async-command cmd)))

(provide 'shelldon)
;;; shelldon.el ends here
