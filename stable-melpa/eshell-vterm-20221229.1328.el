;;; eshell-vterm.el --- Vterm for visual commands in eshell -*- lexical-binding: t; -*-

;; Author: Illia Ostapyshyn <ilya.ostapyshyn@gmail.com>
;; Maintainer: Illia Ostapyshyn <ilya.ostapyshyn@gmail.com>
;; Created: 2021-06-29
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (vterm "0.0.1"))
;; Keywords: eshell, vterm, terminals, shell, visual, tools, processes
;; URL: https://github.com/iostapyshyn/eshell-vterm

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a global minor mode allowing eshell to use
;; vterm for visual commands.

;;; Code:

(require 'vterm)
(require 'em-term)
(require 'esh-ext)

(defvar eshell-parent-buffer)

(defun eshell-vterm-exec-visual (&rest args)
  "Run the specified PROGRAM in a terminal emulation buffer.
ARGS are passed to the program.  At the moment, no piping of input is
allowed.  In case ARGS is nil, a new VTerm session is created."
  (if args
      (let* (eshell-interpreter-alist
             (interp (eshell-find-interpreter (car args) (cdr args)))
             (program (car interp))
             (args (flatten-tree
                    (eshell-stringify-list (append (cdr interp)
                                                   (cdr args)))))
             (args (mapconcat #'shell-quote-argument args " "))
             (term-buf (generate-new-buffer
                        (concat "*" (file-name-nondirectory program) "*")))
             (eshell-buf (current-buffer))
             (vterm-shell (concat (shell-quote-argument
                                   (file-local-name program))
                                  " " args)))
        (save-current-buffer
          (switch-to-buffer term-buf)
          (vterm-mode)
          (setq-local eshell-parent-buffer eshell-buf)
          (let ((proc (get-buffer-process term-buf)))
            (if (and proc (eq 'run (process-status proc)))
                (set-process-sentinel proc #'eshell-vterm-sentinel)
              (error "Failed to invoke visual command")))))
    (vterm '(4))) ; Start a new session
  nil)

(defun eshell-vterm-sentinel (proc msg)
  "Clean up the buffer visiting PROC with message MSG.
If `eshell-destroy-buffer-when-process-dies' is non-nil, destroy
the buffer."
  (let ((vterm-kill-buffer-on-exit nil))
    (vterm--sentinel proc msg)) ;; First call the normal term sentinel.
  (when eshell-destroy-buffer-when-process-dies
    (let ((proc-buf (process-buffer proc)))
      (when (and proc-buf (buffer-live-p proc-buf)
                 (not (eq 'run (process-status proc)))
                 (= (process-exit-status proc) 0))
        (if (eq (current-buffer) proc-buf)
            (let ((buf (and (boundp 'eshell-parent-buffer)
                            eshell-parent-buffer
                            (buffer-live-p eshell-parent-buffer)
                            eshell-parent-buffer)))
              (if buf
                  (switch-to-buffer buf))))
        (kill-buffer proc-buf)))))

;;;###autoload
(define-minor-mode eshell-vterm-mode
  "Use Vterm for eshell visual commands."
  :global t
  :group 'eshell-vterm
  (if eshell-vterm-mode
      (advice-add #'eshell-exec-visual :override #'eshell-vterm-exec-visual)
    (advice-remove #'eshell-exec-visual #'eshell-vterm-exec-visual)))

(provide 'eshell-vterm)
;;; eshell-vterm.el ends here
