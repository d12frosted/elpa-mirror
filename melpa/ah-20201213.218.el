;;; ah.el --- Additional hooks -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020 Takaaki ISHIKAWA

;; Author: Takaaki ISHIKAWA <takaxp at ieee dot org>
;; Keywords: convenience
;; Package-Version: 20201213.218
;; Package-Commit: 869219e7853510aeb00af3580aede0e5d49b324a
;; Version: 0.9.2
;; Maintainer: Takaaki ISHIKAWA <takaxp at ieee dot org>
;; URL: https://github.com/takaxp/ah
;; Package-Requires: ((emacs "25.1"))
;; Twitter: @takaxp

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package provides a set of additional hooks.
;; - ah-before-move-cursor-hook
;; - ah-after-move-cursor-hook
;; - ah-before-c-g-hook
;; - ah-after-c-g-hook
;; - ah-before-enable-theme-hook
;; - ah-after-enable-theme-hook

;;; Change Log:

;;; Code:

;; `ah-before-move-cursor-hook' and `ah-after-move-cursor-hook'

(defgroup ah nil
  "Additional hooks."
  :group 'convenience)

(defcustom ah-lighter " Hooks"
  "Lighter for this."
  :type 'string
  :group 'ah)

(defcustom ah-before-move-cursor-hook nil
  "Hook runs before moving the cursor."
  :type 'hook
  :group 'ah)

(defcustom ah-after-move-cursor-hook nil
  "Hook runs after moving the cursor."
  :type 'hook
  :group 'ah)

(defcustom ah-before-c-g-hook nil
  "Hook runs before \\[keyboard-quit] and related commands."
  :type 'hook
  :group 'ah)

(defcustom ah-after-c-g-hook nil
  "Hook runs after \\[keyboard-quit] and related commands."
  :type 'hook
  :group 'ah)

(defcustom ah-before-enable-theme-hook nil
  "Hook runs before \\[enable-theme]."
  :type 'hook
  :group 'ah)

(defcustom ah-after-enable-theme-hook nil
  "Hook runs after \\[enable-theme]."
  :type 'hook
  :group 'ah)

(defun ah--cur-next-line (f &optional arg try-vscroll)
  "Extend `next-line'.
F is the original function.
ARG and TRY-VSCROLL are identical to the original arguments."
  (run-hooks 'ah-before-move-cursor-hook)
  (funcall f arg try-vscroll)
  (run-hooks 'ah-after-move-cursor-hook))

(defun ah--cur-previous-line (f &optional arg try-vscroll)
  "Extend `previous-line'.
F is the original function.
ARG and TRY-VSCROLL are identical to the original arguments."
  (run-hooks 'ah-before-move-cursor-hook)
  (funcall f arg try-vscroll)
  (run-hooks 'ah-after-move-cursor-hook))

(defun ah--cur-forward-char (f &optional N)
  "Extend `forward-char'.
F is the original function.
N is identical to the original arguments."
  (run-hooks 'ah-before-move-cursor-hook)
  (funcall f N)
  (run-hooks 'ah-after-move-cursor-hook))

(defun ah--cur-backward-char (f &optional N)
  "Extend `backward-char'.
F is the original function.
N is identical to the original arguments."
  (run-hooks 'ah-before-move-cursor-hook)
  (funcall f N)
  (run-hooks 'ah-after-move-cursor-hook))

(defun ah--cur-syntax-subword-forward (f &optional N)
  "Extend `syntax-subword-forward'.
F is the original function.
N is identical to the original arguments."
  (run-hooks 'ah-before-move-cursor-hook)
  (funcall f N)
  (run-hooks 'ah-after-move-cursor-hook))

(defun ah--cur-syntax-subword-backward (f &optional N)
  "Extend `syntax-subword-backward'.
F is the original function.
N is identical to the original arguments."
  (run-hooks 'ah-before-move-cursor-hook)
  (funcall f N)
  (run-hooks 'ah-after-move-cursor-hook))

(defun ah--cur-move-beginning-of-line (f ARG)
  "Extend `move-beginning-of-line'.
F is the original function.
ARG is identical to the original arguments."
  (run-hooks 'ah-before-move-cursor-hook)
  (funcall f ARG)
  (run-hooks 'ah-after-move-cursor-hook))

(defun ah--cur-move-end-of-line (f ARG)
  "Extend `move-end-of-line'.
F is the original function.
ARG is identical to the original arguments."
  (run-hooks 'ah-before-move-cursor-hook)
  (funcall f ARG)
  (run-hooks 'ah-after-move-cursor-hook))

(defun ah--cur-beginning-of-buffer (f &optional ARG)
  "Extend `beginning-of-buffer'.
F is the original function.
ARG is identical to the original arguments."
  (run-hooks 'ah-before-move-cursor-hook)
  (funcall f ARG)
  (run-hooks 'ah-after-move-cursor-hook))

(defun ah--cur-end-of-buffer (f &optional ARG)
  "Extend `end-of-buffer'.
F is the original function.
ARG is identical to the original arguments."
  (run-hooks 'ah-before-move-cursor-hook)
  (funcall f ARG)
  (run-hooks 'ah-after-move-cursor-hook))

(defun ah--cg-post-processing ()
  "Post processing for aborting of the target command."
  (when (memq this-command '(keyboard-quit isearch-abort))
    (run-hooks 'ah-after-c-g-hook))
  (remove-hook 'post-command-hook #'ah--cg-post-processing))

(defun ah--cg-keyboard-quit (f)
  "Extend `keyboard-quit'.
F is the original function."
  (when ah-after-c-g-hook
    (add-hook 'post-command-hook #'ah--cg-post-processing))
  (run-hooks 'ah-before-c-g-hook)
  (funcall f))

(defun ah--cg-isearch-abort (f)
  "Extend `isearch-abort'.
F is the original function."
  (when ah-after-c-g-hook
    (add-hook 'post-command-hook #'ah--cg-post-processing))
  (run-hooks 'ah-before-c-g-hook)
  (funcall f))

(defun ah--enable-theme (f theme)
  "Extend `enable-theme'.
F is the original function.
THEME is identical to the original arguments."
  (when (eq theme 'user)
    (run-hooks 'ah-before-enable-theme-hook))
  (funcall f theme)
  (when (eq theme 'user)
    (run-hooks 'ah-after-enable-theme-hook)))

(defun ah--setup ()
  "Setup."
  ;; For `ah-before-move-cursor-hook' and `ah-after-move-cursor-hook'
  (advice-add 'next-line :around #'ah--cur-next-line)
  (advice-add 'previous-line :around #'ah--cur-previous-line)
  (advice-add 'forward-char :around #'ah--cur-forward-char)
  (advice-add 'backward-char :around #'ah--cur-backward-char)
  (advice-add 'syntax-subword-forward :around #'ah--cur-syntax-subword-forward)
  (advice-add 'syntax-subword-backward :around
              #'ah--cur-syntax-subword-backward)
  (advice-add 'move-beginning-of-line :around #'ah--cur-move-beginning-of-line)
  (advice-add 'move-end-of-line :around #'ah--cur-move-end-of-line)
  (advice-add 'beginning-of-buffer :around #'ah--cur-beginning-of-buffer)
  (advice-add 'end-of-buffer :around #'ah--cur-end-of-buffer)
  (advice-add 'keyboard-quit :around #'ah--cg-keyboard-quit)
  (advice-add 'isearch-abort :around #'ah--cg-isearch-abort)
  (advice-add 'enable-theme :around #'ah--enable-theme))

(defun ah--abort ()
  "Abort."
  ;; For `ah-before-move-cursor-hook' and `ah-after-move-cursor-hook'
  (advice-remove 'next-line #'ah--cur-next-line)
  (advice-remove 'previous-line #'ah--cur-previous-line)
  (advice-remove 'forward-char #'ah--cur-forward-char)
  (advice-remove 'backward-char #'ah--cur-backward-char)
  (advice-remove 'syntax-subword-forward #'ah--cur-syntax-subword-forward)
  (advice-remove 'syntax-subword-backward #'ah--cur-syntax-subword-backward)
  (advice-remove 'move-beginning-of-line #'ah--cur-move-beginning-of-line)
  (advice-remove 'move-end-of-line #'ah--cur-move-end-of-line)
  (advice-remove 'beginning-of-buffer #'ah--cur-beginning-of-buffer)
  (advice-remove 'end-of-buffer #'ah--cur-end-of-buffer)
  (advice-remove 'keyboard-quit #'ah--cg-keyboard-quit)
  (advice-remove 'isearch-abort #'ah--cg-isearch-abort)
  (advice-remove 'enable-theme #'ah--enable-theme))

;;;###autoload
(define-minor-mode ah-mode
  "Toggle the minor mode `ah-mode'."
  :init-value nil
  :lighter (:eval (format "%s" ah-lighter))
  :global t
  :group 'ah
  (if ah-mode
      (ah--setup)
    (ah--abort)))

(provide 'ah)

;;; ah.el ends here
