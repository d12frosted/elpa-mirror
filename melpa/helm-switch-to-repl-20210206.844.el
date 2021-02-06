;;; helm-switch-to-repl.el --- Helm action to switch directory in REPLs -*- lexical-binding: t; -*-

;; Copyright (C) 2020, 2021 Pierre Neidhardt

;; Author: Pierre Neidhardt <mail@ambrevar.xyz>
;; Maintainer: Pierre Neidhardt <mail@ambrevar.xyz>
;; URL: https://github.com/emacs-helm/helm-switch-to-repl
;; Package-Version: 20210206.844
;; Package-Commit: f0e732e7217fc0373b0805245fa15920cf676619
;; Version: 0.1.2
;; Package-Requires: ((emacs "26.1") (helm "3"))

;; This file is not part of GNU Emacs.

;;; License:
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <https://www.gnu.org/licenses/>

;;; Commentary:
;;
;; Helm "Switch-to-REPL" offers the `helm-switch-to-repl' action, a generalized
;; and extensible version of `helm-ff-switch-to-shell'.  It can be added to
;; `helm-find-files' and other `helm-type-file' sources such as `helm-locate'.
;;
;; Call `helm-switch-to-repl-setup' to install the action and bind it to "M-e".
;;
;; Extending support to more REPLs is easy, it's just about adding a couple of
;; specialized methods.  Look at the implementation of for `shell-mode' for an
;; example.

;;; Code:
(require 'helm)
(require 'helm-files)
(require 'helm-mode)
(require 'cl-generic)

;; Forward declarations to silence compiler warnings.
(defvar term-char-mode-point-at-process-mark)
(defvar term-char-mode-buffer-read-only)

(defgroup helm-switch-to-repl nil
  "Emacs Helm actions to switch to REPL from `helm-find-files' and
other `helm-type-file' sources."
  :group 'helm)

(defcustom helm-switch-to-repl-delayed-execution-modes '()
  "REPL modes running a separate process must be added to this list.
Example to include: `shell-mode' and `term-mode'.
Conversely, Eshell need not be included."
  :type 'list
  :group 'helm-swith-to-repl)

(cl-defgeneric helm-switch-to-repl-cd-repl (_mode)
  "Change current REPL directory to `helm-ff-default-directory'."
  nil)

(cl-defgeneric helm-switch-to-repl-new-repl (_mode)
  "Spawn new REPL in given mode."
  nil)

(cl-defgeneric helm-switch-to-repl-interactive-buffer-p (_buffer _mode)
  "Return non-nil if buffer is a REPL in the given mode."
  nil)

(cl-defgeneric helm-switch-to-repl-shell-alive-p (_mode)
  "Return non-nil when a process is running inside buffer in given mode.")

(defun helm-switch-to-repl--format-cd ()
  "Return a command string to switch directly in shells."
  (format "cd %s"
          (shell-quote-argument
           (or (file-remote-p
                helm-ff-default-directory 'localname)
               helm-ff-default-directory))))

(defun helm-switch-to-repl--has-next-prompt? (next-prompt-fn)
  "Return non-nil if current buffer has at least one prompt.
NEXT-PROMPT-FN is used to find the prompt."
  (save-excursion
    (goto-char (point-min))
    (funcall next-prompt-fn 1)
    (null (eql (point) (point-min)))))

(defun helm-switch-to-repl (candidate)
  "Like `helm-ff-switch-to-shell' but supports more modes.
CANDIDATE's directory is used outside of `helm-find-files'."
  ;; `helm-ff-default-directory' is only set in `helm-find-files'.
  ;; For other `helm-type-file', use the candidate directory.
  (let ((helm-ff-default-directory (or helm-ff-default-directory
                                       (if (file-directory-p candidate)
                                           candidate
                                         (file-name-directory candidate))))
        ;; Reproduce the Emacs-25 behavior to be able to edit and send
        ;; command in term buffer.
        term-char-mode-buffer-read-only ; Emacs-25 behavior.
        term-char-mode-point-at-process-mark ; Emacs-25 behavior.
        (bufs (cl-loop for b in (mapcar #'buffer-name (buffer-list))
                       when (helm-switch-to-repl-interactive-buffer-p
                             b (with-current-buffer b major-mode))
                       collect b)))
    ;; Jump to a shell buffer or open a new session.
    (helm-aif (and (not helm-current-prefix-arg)
                   (if (cdr bufs)
                       (helm-comp-read "Switch to shell buffer: " bufs
                                       :must-match t)
                     (car bufs)))
        ;; Display in same window by default to preserve the
        ;; historical behaviour
        (pop-to-buffer it '(display-buffer-same-window))
      (helm-switch-to-repl-new-repl helm-ff-preferred-shell-mode))
    ;; Now cd into directory.
    (helm-aif (and (memq major-mode helm-switch-to-repl-delayed-execution-modes)
                   (get-buffer-process (current-buffer)))
        (accept-process-output it 0.1))
    (unless (helm-switch-to-repl-shell-alive-p major-mode)
      (helm-switch-to-repl-cd-repl major-mode))))

(defun helm-run-switch-to-repl ()
  "Run switch to REPL action from `helm-source-find-files' or \"Helm type file\" sources."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-switch-to-repl)))
(put 'helm-run-switch-to-repl 'helm-only t)

;;;###autoload
(defun helm-switch-to-repl-setup ()
  "Install `helm-switch-to-repl' actions.
It adds it to `helm-find-files' and other \"Helm type file\"
sources such as `helm-locate'."
  (interactive)
  ;; `helm-type-file':
  (add-to-list 'helm-type-file-actions
               '("Switch to REPL `M-e'" . helm-switch-to-repl)
               :append)
  (define-key helm-generic-files-map (kbd "M-e") 'helm-run-switch-to-repl)

  ;; helm-source-find-files:
  (add-to-list 'helm-find-files-actions
               '("Switch to REPL `M-e'" . helm-switch-to-repl)
               :append)
  (define-key helm-find-files-map (kbd "M-e") 'helm-run-switch-to-repl)
  ;; Remove binding from "Switch to Eshell" action name:
  (let ((eshell-action (assoc "Switch to Eshell `M-e'"
                              helm-find-files-actions)))
    (when eshell-action
      (setcar eshell-action "Switch to shell"))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Eshell
(declare-function eshell/cd "em-dirs.el")
(declare-function eshell-next-prompt "em-prompt.el")
(declare-function eshell-reset "esh-mode.el")

(cl-defmethod helm-switch-to-repl-cd-repl ((_mode (eql eshell-mode)))
  "Change Eshell directory to `helm-ff-default-directory'."
  (eshell/cd helm-ff-default-directory)
  (eshell-reset))

(cl-defmethod helm-switch-to-repl-new-repl ((_mode (eql eshell-mode)))
  "Spawn new Eshell."
  (eshell helm-current-prefix-arg))

(cl-defmethod helm-switch-to-repl-interactive-buffer-p ((buffer t) (_mode (eql eshell-mode)))
  "Return non-nil if BUFFER is an Eshell."
  (with-current-buffer buffer
    (helm-switch-to-repl--has-next-prompt? #'eshell-next-prompt)))

(cl-defmethod helm-switch-to-repl-shell-alive-p ((_mode (eql eshell-mode)))
  "Return non-nil when a process is running inside Eshell."
  (get-buffer-process (current-buffer)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Shell
(push 'shell-mode helm-switch-to-repl-delayed-execution-modes)

(cl-defmethod helm-switch-to-repl-cd-repl ((_mode (eql shell-mode)))
  "Change shell directory to `helm-ff-default-directory'."
  (goto-char (point-max))
  (comint-delete-input)
  (insert (helm-switch-to-repl--format-cd))
  (comint-send-input)
  ;; While `shell-directory-tracker' is supposed to automatically set
  ;; `default-directory' for us, it fails on directories like "foo & bar".  Also
  ;; see `shell-command-regexp'.
  (cd helm-ff-default-directory))

(cl-defmethod helm-switch-to-repl-new-repl ((_mode (eql shell-mode)))
  "Spawn new shell."
  (shell (helm-aif (and helm-current-prefix-arg
                        (prefix-numeric-value
                         helm-current-prefix-arg))
             (format "*shell<%s>*" it))))

(cl-defmethod helm-switch-to-repl-interactive-buffer-p ((buffer t) (_mode (eql shell-mode)))
  "Return non-nil if BUFFER is a shell."
  (with-current-buffer buffer
    (helm-switch-to-repl--has-next-prompt? #'comint-next-prompt)))

(cl-defmethod helm-switch-to-repl-shell-alive-p ((_mode (eql shell-mode)))
  "Return non-nil when a process is running inside a shell."
  (save-excursion
    (comint-goto-process-mark)
    (or (null comint-last-prompt)
        (not (eql (point)
                  (marker-position (cdr comint-last-prompt)))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SLY
(declare-function sly-change-directory "sly.el")
(declare-function sly "sly.el")

(push 'sly-mrepl-mode helm-switch-to-repl-delayed-execution-modes)

(cl-defmethod helm-switch-to-repl-cd-repl ((_mode (eql sly-mrepl-mode)))
  "Change SLY directory to `helm-ff-default-directory'."
  (let ((dir helm-ff-default-directory))
    ;; From `sly-mrepl-set-directory':
    (sly-mrepl--eval-for-repl
     `(slynk:set-default-directory
       (slynk-backend:filename-to-pathname
        ,(sly-to-lisp-filename dir))))
    (sly-mrepl--insert-note (format "Setting directory to %s" dir))
    (cd dir)))

(cl-defmethod helm-switch-to-repl-new-repl ((_mode (eql sly-repl-mode)))
  "Spawn new SLY."
  (sly))

(cl-defmethod helm-switch-to-repl-interactive-buffer-p ((buffer t)
                                                        (_mode (eql sly-mrepl-mode)))
  "Return non-nil if BUFFER is a SLY REPL."
  (with-current-buffer buffer
    (helm-switch-to-repl--has-next-prompt? #'comint-next-prompt)))

(cl-defmethod helm-switch-to-repl-shell-alive-p ((_mode (eql sly-mrepl-mode)))
  "Return non-nil when a process is running inside a SLY REPL."
  (helm-switch-to-repl-shell-alive-p 'shell-mode))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Term
(declare-function term-char-mode "term.el")
(declare-function term-line-mode "term.el")
(declare-function term-send-input "term.el")
(declare-function term-next-prompt "term.el")
(declare-function term-process-mark "term.el")

(push 'term-mode helm-switch-to-repl-delayed-execution-modes)

(cl-defmethod helm-switch-to-repl-cd-repl ((_mode (eql term-mode)))
  "Change term buffer directory to `helm-ff-default-directory'."
  (goto-char (point-max))
  (insert (helm-switch-to-repl--format-cd))
  (term-char-mode)
  (term-send-input))

(cl-defmethod helm-switch-to-repl-new-repl ((_mode (eql term-mode)))
  "Spawn new term buffer."
  (ansi-term (getenv "SHELL")
             (helm-aif (and helm-current-prefix-arg
                            (prefix-numeric-value
                             helm-current-prefix-arg))
                 (format "*ansi-term<%s>*" it)))
  (term-line-mode))

(cl-defmethod helm-switch-to-repl-interactive-buffer-p ((buffer t) (_mode (eql term-mode)))
  "Return non-nil if BUFFER is a term buffer."
  (with-current-buffer buffer
    (helm-switch-to-repl--has-next-prompt? #'term-next-prompt)))

(cl-defmethod helm-switch-to-repl-shell-alive-p ((_mode (eql term-mode)))
  "Return non-nil when a process is running inside a term buffer."
  (save-excursion
    (goto-char (term-process-mark))
    (not (looking-back "\\$ " (- (point) 2)))))


(provide 'helm-switch-to-repl)
;;; helm-switch-to-repl.el ends here
