;;; jit-lock-stealth-progress.el --- JIT lock stealth mode-line progress -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-3.0-or-later
;; Copyright (C) 2022  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.org/ideasman42/emacs-jit-lock-stealth-progress
;; Package-Version: 20230105.932
;; Package-Commit: 016a945cd5a490b260a1bc8c6c511c8d0198f3c9
;; Version: 0.1
;; Package-Requires: ((emacs "28.1"))

;;; Commentary:

;; This package exposes a buffer-local variable that can be used to access
;; the progress of stealthy fontifications (used when `jit-lock-stealth-time' is non-nil).
;; This can the be displayed in the mode-line to indicate the state of fontification.

;;; Usage

;; (jit-lock-stealth-progress-mode) ;; Expose jit-lock-progress.
;; This will show the value of `jit-lock-stealth-progress-info' in the mode-line.


;;; Code:

(defgroup jit-lock-stealth-progress nil
  "Sets a progress variable for stealthy font locking mode for use in the mode-line."
  :group 'mode-line)

(defcustom jit-lock-stealth-progress-info ""
  "The text to show when the progress is not active."
  :type 'string)

(defcustom jit-lock-stealth-progress-info-format "%5.1f%%"
  "Format string for the progress, a float percentage in [0..100]."
  :type 'string)

(defcustom jit-lock-stealth-progress-add-to-mode-line t
  "Add to the end `mode-line-format' when the mode is enabled.
With a customized mode-line it may be preferable to include
`jit-lock-stealth-progress-info' directly in the `mode-line-format'."
  :type 'boolean)


;; ---------------------------------------------------------------------------
;; Internal Variables

(defconst jit-lock-stealth-progress--mode-line-format '(list 1 jit-lock-stealth-progress-info))

;; When non-nil, a cons cell representing (min . max).
(defvar-local jit-lock-stealth-progress--range-done nil)

;; ---------------------------------------------------------------------------
;; Utility Functions

(defmacro jit-lock-stealth-progress--with-advice (fn-orig where fn-advice &rest body)
  "Execute BODY with WHERE advice on FN-ORIG temporarily enabled."
  (declare (indent 3))
  `(let ((fn-advice-var ,fn-advice))
     (unwind-protect
         (progn
           (advice-add ,fn-orig ,where fn-advice-var)
           ,@body)
       (advice-remove ,fn-orig fn-advice-var))))


;; ---------------------------------------------------------------------------
;; Mode Line Format

(defsubst jit-lock-stealth-progress--mode-line-set-p ()
  "Return non-nil when `mode-line-format' includes progress."
  (and (listp mode-line-format)
       (memq jit-lock-stealth-progress--mode-line-format mode-line-format)))

(defun jit-lock-stealth-progress--mode-line-ensure ()
  "Ensure the `mode-line-format' includes progress display."
  (unless (jit-lock-stealth-progress--mode-line-set-p)
    (setq mode-line-format
          (append mode-line-format (list jit-lock-stealth-progress--mode-line-format)))))

(defun jit-lock-stealth-progress--mode-line-remove ()
  "Ensure the `mode-line-format' has progress display removed."
  (when (jit-lock-stealth-progress--mode-line-set-p)
    (setq mode-line-format (delete jit-lock-stealth-progress--mode-line-format mode-line-format))))


;; ---------------------------------------------------------------------------
;; Internal Functions

(defun jit-lock-stealth-progress--clear-variables ()
  "Clear all buffer-local variables."
  (when jit-lock-stealth-progress-add-to-mode-line
    (jit-lock-stealth-progress--mode-line-remove))
  (kill-local-variable 'jit-lock-stealth-progress-info)
  (kill-local-variable 'jit-lock-stealth-progress--range-done))

(defun jit-lock-stealth-progress--fontify-wrapper (orig-fn &rest args)
  "Wrapper for `jit-lock-stealth-fontify' as (ORIG-FN ARGS) to set progress."
  (let* ((this-progress-buffer (current-buffer))
         (is-first
          (or (null
               (buffer-local-boundp 'jit-lock-stealth-progress-info this-progress-buffer))
              (null (memq this-progress-buffer jit-lock-stealth-buffers))
              (null jit-lock-stealth-progress--range-done)))
         (did-font-lock-run nil)
         (do-mode-line-update nil))

    (jit-lock-stealth-progress--with-advice 'jit-lock-fontify-now
        :around
        (lambda (orig-fn-2 beg end)
          (prog1 (funcall orig-fn-2 beg end)
            ;; Stealthy font locking may update other buffers,
            ;; these aren't so useful to show in the mode-line.
            (when (eq this-progress-buffer (current-buffer))

              (when is-first
                (when jit-lock-stealth-progress-add-to-mode-line
                  (jit-lock-stealth-progress--mode-line-ensure))
                (setq jit-lock-stealth-progress--range-done (cons (point) (point))))

              (setq did-font-lock-run t)
              ;; When first is backwards, all points ahead of (point) have been calculated.
              (when (and is-first (< beg (point)))
                (setcdr jit-lock-stealth-progress--range-done (point-max)))

              (setcar
               jit-lock-stealth-progress--range-done
               (min beg (car jit-lock-stealth-progress--range-done)))
              (setcdr
               jit-lock-stealth-progress--range-done
               (min (max end (cdr jit-lock-stealth-progress--range-done)) (point-max)))
              (let ((range-full (- (point-max) (point-min)))
                    (range-done (-
                                 (cdr jit-lock-stealth-progress--range-done)
                                 (car jit-lock-stealth-progress--range-done))))
                (let ((progress
                       (*
                        100.0
                        (- 1.0
                           (/ (float
                               (- range-full range-done))
                              range-full)))))
                  (setq-local
                   jit-lock-stealth-progress-info
                   (format jit-lock-stealth-progress-info-format progress))))
              (setq do-mode-line-update t))))

      (prog1 (apply orig-fn args)
        (when (and (null is-first) (null did-font-lock-run))
          ;; Complete, clear the variable.
          (jit-lock-stealth-progress--clear-variables)
          (setq do-mode-line-update t))))

    ;; Defer so any font locking changes aren't picked up by the mode-line.
    (when do-mode-line-update
      (force-mode-line-update))))


;; ---------------------------------------------------------------------------
;; Internal Mode Management

(defun jit-lock-stealth-progress--mode-enable ()
  "Turn on `jit-lock-stealth-progress-mode' for the current buffer."
  (advice-add 'jit-lock-stealth-fontify :around #'jit-lock-stealth-progress--fontify-wrapper))

(defun jit-lock-stealth-progress--mode-disable ()
  "Turn off `jit-lock-stealth-progress-mode' for the current buffer."
  (advice-remove 'jit-lock-stealth-fontify #'jit-lock-stealth-progress--fontify-wrapper)

  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (jit-lock-stealth-progress--clear-variables))))

;; ---------------------------------------------------------------------------
;; Public API

;;;###autoload
(define-minor-mode jit-lock-stealth-progress-mode
  "Enable progress display when `jit-lock-stealth-time' is set."
  :global t

  (cond
   (jit-lock-stealth-progress-mode
    (jit-lock-stealth-progress--mode-enable))
   (t
    (jit-lock-stealth-progress--mode-disable))))

(provide 'jit-lock-stealth-progress)

;;; jit-lock-stealth-progress.el ends here
