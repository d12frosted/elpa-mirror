;;; fancy-compilation.el --- Enhanced compilation output -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later
;; Copyright (C) 2022  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.org/ideasman42/emacs-fancy-compilation
;; Package-Version: 20220717.2251
;; Package-Commit: 913fa36583e89032ca258a75df18b45b530cc9d9
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))

;;; Commentary:

;; Enable colors, improved scrolling and theme independent colors for compilation mode.
;; This package aims to bring some of the default behavior of compiling
;; from a terminal into Emacs, setting defaults accordingly.

;;; Usage

;; (fancy-compilation-mode) ;; Activate for future compilation.


;;; Code:

(require 'ansi-color)

(eval-when-compile (require 'compile))

;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup fancy-compilation nil
  "Options to configure enhanced compilation settings."
  :group 'convenience)

(defcustom fancy-compilation-term "tmux-256color"
  "The TERM environment variable to use (use an empty string to disable)."
  :type 'string)

(defcustom fancy-compilation-override-colors t
  "Override theme faces (foreground/background)."
  :type 'boolean)

(defface fancy-compilation-default-face
  (list (list t :foreground "#C0C0C0" :background "#000000"))
  "Face used to render black color.
Use when `fancy-compilation-override-colors' is non-nil.")

(defcustom fancy-compilation-quiet-prelude t
  "Clear text inserted before compilation starts."
  :type 'boolean)


;; ---------------------------------------------------------------------------
;; Internal Utilities

(defmacro fancy-compilation--with-advice (fn-orig where fn-advice &rest body)
  "Execute BODY with advice added.

WHERE using FN-ADVICE temporarily added to FN-ORIG."
  `
  (let ((fn-advice-var ,fn-advice))
    (unwind-protect
      (progn
        (advice-add ,fn-orig ,where fn-advice-var)
        ,@body)
      (advice-remove ,fn-orig fn-advice-var))))


;; ---------------------------------------------------------------------------
;; Internal Functions

(defun fancy-compilation--compilation-mode ()
  "Mode hook to set buffer local defaults."
  (when fancy-compilation-override-colors
    (setq-local face-remapping-alist (list (cons 'default 'fancy-compilation-default-face))))

  ;; Needed so `ansi-text' isn't converted to [...].
  (setq-local compilation-max-output-line-length nil)
  ;; Auto-scroll output.
  (setq-local compilation-scroll-output t)
  ;; Avoid jumping past the last line when correcting scroll.
  (setq-local scroll-conservatively most-positive-fixnum)
  ;; A margin doesn't make sense for compilation output.
  (setq-local scroll-margin 0))

(defun fancy-compilation--compile (f &rest args)
  "Wrap the `compile' command (F ARGS)."
  (let
    (
      (compilation-environment
        (cond
          ((string-empty-p compilation-environment)
            compilation-environment)
          (t
            (cons (concat "TERM=" fancy-compilation-term) compilation-environment)))))
    (apply f args)))


(defun fancy-compilation--compilation-start (f &rest args)
  "Wrap `compilation-start' (F ARGS)."
  (cond
    (fancy-compilation-quiet-prelude
      (fancy-compilation--with-advice 'insert
        :override (lambda (&rest _args) nil)
        (fancy-compilation--with-advice 'put-text-property
          :override (lambda (&rest _args) nil)
          ;; Call the function without any additional text.
          (apply f args))))
    (t
      (apply f args))))

(defun fancy-compilation--compilation-filter (f proc string)
  "Wrap `compilation-filter' (F PROC STRING) to support `ansi-color'."
  (let ((buf (process-buffer proc)))
    (when (buffer-live-p buf)
      (with-current-buffer buf
        (funcall f proc string)
        (let ((inhibit-read-only t))
          ;; Rely on `ansi-color-context-region' to avoid re-coloring
          ;; the entire buffer every update.
          (ansi-color-apply-on-region (point-min) (point-max)))))))


;; ---------------------------------------------------------------------------
;; Internal Mode Management

(defun fancy-compilation-mode-enable ()
  "Turn on `fancy-compilation-mode' for the current buffer."
  (advice-add 'compile :around #'fancy-compilation--compile)
  (advice-add 'compilation-filter :around #'fancy-compilation--compilation-filter)
  (advice-add 'compilation-start :around #'fancy-compilation--compilation-start)
  (add-hook 'compilation-mode-hook #'fancy-compilation--compilation-mode))

(defun fancy-compilation-mode-disable ()
  "Turn off `fancy-compilation-mode' for the current buffer."
  (advice-remove 'compile #'fancy-compilation--compile)
  (advice-remove 'compilation-filter #'fancy-compilation--compilation-filter)
  (advice-remove 'compilation-start #'fancy-compilation--compilation-start)
  (remove-hook 'compilation-mode-hook #'fancy-compilation--compilation-mode))

(defun fancy-compilation-mode-turn-on ()
  "Enable command `fancy-compilation-mode'."
  (when (and (not (minibufferp)) (not (bound-and-true-p fancy-compilation-mode)))
    (fancy-compilation-mode 1)))


;; ---------------------------------------------------------------------------
;; Public API

;;;###autoload
(define-minor-mode fancy-compilation-mode
  "Enable enhanced compilation."
  :global t

  (cond
    (fancy-compilation-mode
      (fancy-compilation-mode-enable))
    (t
      (fancy-compilation-mode-disable))))


(provide 'fancy-compilation)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; fancy-compilation.el ends here
