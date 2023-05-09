;;; define-scratch.el --- Define new commands to make scratch buffers -*- lexical-binding: t -*-

;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-define-scratch
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.3"))
;; Keywords: languages util
;; SPDX-License-Identifier: ISC

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Define new commands to make scratch buffers. Example:

;;     (when (require 'define-scratch nil t)
;;       (define-scratch scheme-scratch scheme-mode)
;;       (define-scratch text-scratch text-mode auto-fill-mode))

;;; Code:

(defun define-scratch--get-or-create-blank-buffer (base-name)
  "Internal function to generate a unique buffer from BASE-NAME.

Like `generate-new-buffer' but re-uses blank buffers."
  (let ((name base-name)
        (number 1)
        (max-number 100)
        (result nil))
    (while (and (not result) (<= number max-number))
      (let ((buffer (get-buffer-create name)))
        (if (and buffer (zerop (buffer-size buffer)))
            (setq result buffer)
          (setq number (1+ number)
                name (format "%s<%d>" base-name number)))))
    (or result (error "Too many scratch buffers"))))

(defun define-scratch--switch-to-buffer (name base-name mode minor-modes)
  "Internal function to get, create, and switch to a scratch buffer.

NAME, when non-nil, is an explicit buffer name to use.

Otherwise BASE-NAME is a template for the buffer name.

MODE and MINOR-MODES are the modes to use in the buffer."
  (let ((buffer
         (let* ((home-directory
                 (expand-file-name
                  (file-name-as-directory "~")))
                (default-directory
                  home-directory))
           (if name
               (get-buffer-create name)
             (define-scratch--get-or-create-blank-buffer base-name)))))
    (switch-to-buffer buffer)
    (unless (eq major-mode mode)
      (funcall mode)
      (dolist (minor-mode minor-modes)
        (funcall minor-mode)))
    buffer))

(defmacro define-scratch (scratch-command mode &rest minor-modes)
  "Define SCRATCH-COMMAND as a command to create a scratch buffer.

MODE is the major mode that buffers created with this command will use.

MINOR-MODES are extra minor modes (if any) to enable."
  (let ((base-name (format "*%s*" scratch-command)))
    `(defun ,scratch-command (&optional name)
       ,(concat (format "Create a new scratch buffer in %s.\n" mode)
                "\n"
                "With a prefix argument, prompt for buffer NAME.\n")
       (interactive
        (list (and current-prefix-arg
                   (read-from-minibuffer
                    "Name of new scratch buffer: "
                    ,base-name))))
       (define-scratch--switch-to-buffer
         name
         ,base-name
         ',mode
         ',minor-modes))))

(provide 'define-scratch)

;;; define-scratch.el ends here
