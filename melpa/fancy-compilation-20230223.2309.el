;;; fancy-compilation.el --- Enhanced compilation output -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later
;; Copyright (C) 2022  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.org/ideasman42/emacs-fancy-compilation
;; Package-Version: 20230223.2309
;; Package-Commit: d5d790dee6b07f866d203c5c174440ec8a2b2215
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))

;;; Commentary:

;; Enable colors, improved scrolling and theme independent colors for compilation mode.
;; This package aims to bring some of the default behavior of compiling
;; from a terminal into Emacs, setting defaults accordingly.

;;; Usage

;; (fancy-compilation-mode) ; Activate for future compilation.


;;; Code:

(eval-when-compile
  (require 'compile)
  (require 'ansi-color))


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

(defcustom fancy-compilation-quiet-prelude t
  "Suppress text inserted before compilation starts."
  :type 'boolean)

(defcustom fancy-compilation-quiet-prolog t
  "Use less verbose text upon completing compilation."
  :type 'boolean)

(defcustom fancy-compilation-setup-hook nil
  "Hooks run just after the fancy-compilation buffer has been initialized.
Use this to set or override defaults."
  :type 'hook)

(defcustom fancy-compilation-scroll-output t
  "Like `compilation-scroll-output`, but defaults to `t` and specific to `fancy-compilation`."
  :type '(choice (const :tag "No scrolling" nil)
		 (const :tag "Scroll compilation output" t)
		 (const :tag "Stop scrolling at the first error" first-error)))


;; ---------------------------------------------------------------------------
;; Faces

(defface fancy-compilation-default-face
  (list (list t :background "black" :inherit 'ansi-color-grey))
  "Face used to render black color.")

(defface fancy-compilation-function-name-face (list (list t :foreground "cyan3"))
  "Face used to show function names.")

(defface fancy-compilation-line-number-face (list (list t :foreground "cyan3"))
  "Face used to show line numbers.")

(defface fancy-compilation-column-number-face (list (list t :foreground "cyan3"))
  "Face used to show column numbers.")

(defface fancy-compilation-info-face (list (list t :foreground "cyan3"))
  "Face used to show info text.")

(defface fancy-compilation-warning-face (list (list t :foreground "yellow3"))
  "Face used to show error text.")

(defface fancy-compilation-error-face (list (list t :foreground "dark orange"))
  "Face used to show error text.")

(defface fancy-compilation-complete-success-face
  (list (list t :foreground "black" :inherit 'ansi-color-green :extend t))
  "Face used to show success on completion.")

(defface fancy-compilation-complete-error-face
  (list (list t :foreground "black" :inherit 'ansi-color-red :extend t))
  "Face used to show success on completion.")


;; ---------------------------------------------------------------------------
;; Internal Variables

;; The window used for compilation (not essential, use when set & live).
(defvar-local fancy-compilation--window nil)

;; ---------------------------------------------------------------------------
;; Internal Utilities

(defmacro fancy-compilation--with-temp-hook (hook-sym fn-advice &rest body)
  "Execute BODY with hook FN-ADVICE temporarily added to HOOK-SYM."
  (declare (indent 2))
  `(let ((fn-advice-var ,fn-advice))
     (unwind-protect
         (progn
           (add-hook ,hook-sym fn-advice-var)
           ,@body)
       (remove-hook ,hook-sym fn-advice-var))))

(defun fancy-compilation--bounds-of-space-at-point (pos)
  "Return the range of space characters surrounding POS."
  (save-excursion
    (let ((skip "[:blank:]\n"))
      (goto-char pos)
      (skip-chars-backward skip)
      (cons
       (point)
       (progn
         (skip-chars-forward skip)
         (point))))))

;; ---------------------------------------------------------------------------
;; Internal Functions

(defun fancy-compilation--compilation-mode ()
  "Mode hook to set buffer local defaults."
  (when fancy-compilation-override-colors
    (setq-local face-remapping-alist
                (list
                 (cons 'default 'fancy-compilation-default-face)
                 (cons 'font-lock-function-name-face 'fancy-compilation-function-name-face)
                 (cons 'compilation-line-number 'fancy-compilation-line-number-face)
                 (cons 'compilation-column-number 'fancy-compilation-column-number-face)
                 (cons 'compilation-info 'fancy-compilation-info-face)
                 (cons 'compilation-warning 'fancy-compilation-warning-face)
                 (cons 'compilation-error 'fancy-compilation-error-face))))

  ;; Needed so `ansi-text' isn't converted to [...].
  (setq-local compilation-max-output-line-length nil)
  ;; Auto-scroll output.
  (setq-local compilation-scroll-output fancy-compilation-scroll-output)
  ;; Avoid jumping past the last line when correcting scroll.
  (setq-local scroll-conservatively most-positive-fixnum)
  ;; A margin doesn't make sense for compilation output.
  (setq-local scroll-margin 0)

  (run-hooks 'fancy-compilation-setup-hook))

(defun fancy-compilation--compile (fn &rest args)
  "Wrap the `compile' command (FN ARGS)."
  (let ((compilation-environment
         (cond
          ((string-empty-p fancy-compilation-term)
           compilation-environment)
          (t
           (cons (concat "TERM=" fancy-compilation-term) compilation-environment)))))
    (apply fn args)))


(defun fancy-compilation--compilation-start (fn &rest args)
  "Wrap `compilation-start' (FN ARGS)."
  ;; Lazily load when not compiling.
  (require 'ansi-color)
  (setq fancy-compilation--window nil)

  (let ((compile-buf nil))
    (fancy-compilation--with-temp-hook 'compilation-start-hook
        (lambda (proc) (setq compile-buf (process-buffer proc)))

      (prog1 (apply fn args)
        (when compile-buf
          (with-current-buffer compile-buf
            (setq fancy-compilation--window (get-buffer-window compile-buf))

            (when fancy-compilation-quiet-prelude
              ;; Ideally this text would not be added in the first place,
              ;; but overriding `insert' causes #2 (issues with native-compilation).
              (let ((inhibit-read-only t))
                (delete-region (point-min) (point-max))))))))))

(defun fancy-compilation--compilation-handle-exit (fn process-status exit-status msg)
  "Wrap `compilation-handle-exit' (FN PROCESS-STATUS, EXIT-STATUS & MSG)."
  (cond
   (fancy-compilation-quiet-prolog
    (let ((eof-orig (point-max)))
      (prog1 (funcall fn process-status exit-status msg)
        (pcase-let ((`(,trim-beg . ,trim-end)
                     (fancy-compilation--bounds-of-space-at-point eof-orig)))

          (let ((inhibit-read-only t))
            (delete-region trim-beg trim-end)

            (goto-char trim-beg)
            (insert "\n")
            (save-match-data
              (when (or (looking-at "[[:alnum:]]+ [[:alnum:]]+\\( at .*\\)")
                        (re-search-forward "\\( at .*\\)"))
                (delete-region (match-beginning 1) (match-end 1))))

            (let ((tail (car (fancy-compilation--bounds-of-space-at-point (point-max)))))
              (delete-region tail (point-max)))

            ;; Overlays are needed since compilation mode will overwrite the `face'.
            (when fancy-compilation-override-colors
              (let ((complete-face
                     (cond
                      ((zerop exit-status)
                       'fancy-compilation-complete-success-face)
                      (t
                       'fancy-compilation-complete-error-face))))
                (let ((overlay (make-overlay (1+ trim-beg) (point-max))))
                  (overlay-put overlay 'evaporate t)
                  (overlay-put overlay 'after-string (propertize "\n" 'face complete-face))
                  (overlay-put overlay 'face complete-face)))))))))

   (t
    (funcall fn process-status exit-status msg))))

(defun fancy-compilation--compilation-filter (fn proc string)
  "Wrap `compilation-filter' (FN PROC STRING) to support `ansi-color'."
  (let ((buf (process-buffer proc)))
    (when (buffer-live-p buf)
      (with-current-buffer buf
        (funcall fn proc string)
        (let ((inhibit-read-only t))
          ;; Rely on `ansi-color-context-region' to avoid re-coloring
          ;; the entire buffer every update.
          (ansi-color-apply-on-region (point-min) (point-max))

          ;; Avoid the horizontal scroll getting "stuck",
          ;; always snap back to the left hand side.
          (when fancy-compilation--window
            (cond
             ((window-live-p fancy-compilation--window)
              (unless (zerop (window-hscroll))
                (set-window-hscroll fancy-compilation--window 0)))
             (t ; Don't further check this window.
              (setq fancy-compilation--window nil)))))))))


;; ---------------------------------------------------------------------------
;; Internal Mode Management

(defun fancy-compilation--mode-enable ()
  "Turn on `fancy-compilation-mode' for the current buffer."
  (advice-add 'compile :around #'fancy-compilation--compile)
  (advice-add 'compilation-filter :around #'fancy-compilation--compilation-filter)
  (advice-add 'compilation-start :around #'fancy-compilation--compilation-start)
  (advice-add 'compilation-handle-exit :around #'fancy-compilation--compilation-handle-exit)
  (add-hook 'compilation-mode-hook #'fancy-compilation--compilation-mode))

(defun fancy-compilation--mode-disable ()
  "Turn off `fancy-compilation-mode' for the current buffer."
  (advice-remove 'compile #'fancy-compilation--compile)
  (advice-remove 'compilation-filter #'fancy-compilation--compilation-filter)
  (advice-remove 'compilation-start #'fancy-compilation--compilation-start)
  (advice-remove 'compilation-handle-exit #'fancy-compilation--compilation-handle-exit)
  (remove-hook 'compilation-mode-hook #'fancy-compilation--compilation-mode)

  (kill-local-variable 'fancy-compilation--window))


;; ---------------------------------------------------------------------------
;; Public API

;;;###autoload
(define-minor-mode fancy-compilation-mode
  "Enable enhanced compilation."
  :global t

  (cond
   (fancy-compilation-mode
    (fancy-compilation--mode-enable))
   (t
    (fancy-compilation--mode-disable))))


(provide 'fancy-compilation)
;; Local Variables:
;; fill-column: 99
;; indent-tabs-mode: nil
;; End:
;;; fancy-compilation.el ends here
