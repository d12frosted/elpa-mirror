;;; idle-highlight-mode.el --- Highlight the word the point is on -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-2.0-or-later
;; Copyright (C) 2008-2011 Phil Hagelberg, Cornelius Mika

;; Author: Phil Hagelberg, Cornelius Mika, Campbell Barton
;; URL: https://gitlab.com/ideasman42/emacs-idle-highlight-mode
;; Package-Version: 20220211.548
;; Package-Commit: 0a24f8e402383b0da1f956d946781317fba14bbc
;; Version: 1.1.3
;; Created: 2008-05-13
;; Keywords: convenience
;; EmacsWiki: IdleHighlight
;; Package-Requires: ((emacs "27.1"))

;;; Commentary:

;; M-x idle-highlight-mode sets an idle timer that highlights all
;; occurrences in the buffer of the symbol under the point.

;; Enabling it in a hook is recommended if you don't want it enabled
;; for all buffers, just programming ones.
;;
;; Example:
;;
;; (defun my-prog-mode-hook ()
;;   (idle-highlight-mode t))
;;
;; (add-hook 'prog-mode-hook 'my-prog-mode-hook)

;;; Code:


;; ---------------------------------------------------------------------------
;; Require Dependencies

(require 'thingatpt)


;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup idle-highlight nil "Highlight other occurrences of the word at point." :group 'faces)

(defface idle-highlight
  '((t (:inherit region)))
  "Face used to highlight other occurrences of the word at point.")

(defcustom idle-highlight-exceptions nil
  "List of words to be excepted from highlighting."
  :type
  '
  (choice
    (repeat :tag "A list of string literals that will be excluded." string)
    (function :tag "A function taking a string, non-nil result excludes.")))

(defcustom idle-highlight-exceptions-face '(font-lock-keyword-face font-lock-string-face)
  "List of exception faces."
  :type
  '
  (choice
    (repeat :tag "A list of face symbols that will be ignored." symbol)
    (function :tag "A function that takes a list of faces, non-nil result excludes.")))

(defcustom idle-highlight-exceptions-syntax "^w_"
  "Syntax table to to skip.

See documentation for `skip-syntax-forward', nil to ignore."
  :type '(choice (const nil) string))

(defcustom idle-highlight-exclude-point nil
  "Exclude the current symbol from highlighting."
  :type 'boolean)

(defcustom idle-highlight-visible-buffers nil
  "Apply the current highlight to all other visible buffers."
  :type 'boolean)

(defcustom idle-highlight-idle-time 0.35
  "Time after which to highlight the word at point (in seconds)."
  :type 'float)

(defcustom idle-highlight-ignore-modes nil
  "List of major-modes to exclude when `idle-highlight' has been enabled globally."
  :type '(repeat symbol))

(defvar-local global-idle-highlight-ignore-buffer nil
  "When non-nil, the global mode will not be enabled for this buffer.
This variable can also be a predicate function, in which case
it'll be called with one parameter (the buffer in question), and
it should return non-nil to make Global `idle-highlight' Mode not
check this buffer.")


;; ---------------------------------------------------------------------------
;; Internal Variables

(defvar-local idle-highlight--overlays nil "Buffer-local list of overlays.")


;; ---------------------------------------------------------------------------
;; Internal Functions

(defun idle-highlight--faces-at-point (pos)
  "Add the named faces that the `read-face-name' or `face' property use.
Argument POS return faces at this point."
  (let
    ( ;; List of faces to return.
      (faces nil)
      ;; NOTE: use `get-text-property' instead of `get-char-property' so overlays are excluded,
      ;; since this causes overlays with `hl-line-mode' (for example) to mask keywords, see: #1.
      (faceprop (or (get-text-property pos 'read-face-name) (get-text-property pos 'face))))
    (cond
      ((facep faceprop)
        (push faceprop faces))
      ((face-list-p faceprop)
        (dolist (face faceprop)
          (when (facep face)
            (push face faces)))))
    faces))

(defun idle-highlight--merge-overlapping-ranges (ranges)
  "Destructively modify and return RANGES with overlapping values removed.

Where RANGES is an unordered list of (min . max) cons cells."
  (cond
    ((cdr ranges)
      ;; Simple < sorting of cons cells.
      (setq ranges
        (sort
          ranges
          (lambda (x y) (or (< (car x) (car y)) (and (= (car x) (car y)) (< (cdr x) (cdr y)))))))
      ;; Step over `ranges', de-duplicating & adjusting elements as needed.
      (let
        (
          (ranges-iter ranges)
          (ranges-next (cdr ranges)))
        (while ranges-next
          (let
            (
              (head (car ranges-iter))
              (next (car ranges-next)))
            (cond
              ((< (cdr head) (car next))
                (setq ranges-iter ranges-next)
                (setq ranges-next (cdr ranges-next)))
              (t
                (when (< (cdr head) (cdr next))
                  (setcdr head (cdr next)))
                (setq ranges-next (cdr ranges-next))
                (setcdr ranges-iter ranges-next)))))
        ranges))

    (t ;; No need for complex logic single/empty lists.
      ranges)))


;; ---------------------------------------------------------------------------
;; Internal Context Checking Functions

(defun idle-highlight--check-symbol-at-point (pos)
  "Return non-nil if the symbol at POS can be used."
  (cond
    (idle-highlight-exceptions-syntax
      (save-excursion (zerop (skip-syntax-forward idle-highlight-exceptions-syntax (1+ pos)))))
    (t
      t)))

(defun idle-highlight--check-faces-at-point (pos)
  "Check if the position POS has faces that match the exclude argument."
  (cond
    (idle-highlight-exceptions-face
      (let ((result t))
        (let ((faces-at-pos (idle-highlight--faces-at-point pos)))
          (when faces-at-pos
            (cond
              ((functionp idle-highlight-exceptions-face)
                (when (funcall idle-highlight-exceptions-face faces-at-pos)
                  (setq result nil)))
              (t
                (while faces-at-pos
                  (let ((face (pop faces-at-pos)))
                    (when (memq face idle-highlight-exceptions-face)
                      (setq result nil)
                      ;; Break.
                      (setq faces-at-pos nil))))))))
        result))
    (t ;; Default to true, if there are no exceptions.
      t)))

(defun idle-highlight--check-word (target)
  "Return non-nil when TARGET should not be excluded."
  (not
    (cond
      ((functionp idle-highlight-exceptions)
        (funcall idle-highlight-exceptions target))
      (t
        (member target idle-highlight-exceptions)))))


;; ---------------------------------------------------------------------------
;; Internal Highlight Functions

(defun idle-highlight--unhighlight ()
  "Clear current highlight."
  (when idle-highlight--overlays
    (mapc 'delete-overlay idle-highlight--overlays)
    (setq idle-highlight--overlays nil)))

(defun idle-highlight--highlight (target target-beg target-end visible-ranges)
  "Highlight TARGET found between TARGET-BEG and TARGET-END.

Argument VISIBLE-RANGES is a list of (min . max) ranges to highlight."
  (idle-highlight--unhighlight)
  (save-excursion
    (let ((target-regexp (concat "\\_<" (regexp-quote target) "\\_>")))
      (dolist (range visible-ranges)
        (pcase-let ((`(,beg . ,end) range))
          (goto-char beg)
          (while (re-search-forward target-regexp end t)
            (let
              (
                (match-beg (match-beginning 0))
                (match-end (match-end 0)))
              (unless
                (and
                  idle-highlight-exclude-point
                  (eq target-beg match-beg)
                  (eq target-end match-end))
                (let ((ov (make-overlay match-beg match-end)))
                  (overlay-put ov 'face 'idle-highlight)
                  (push ov idle-highlight--overlays))))))))))

(defun idle-highlight--word-at-point-args ()
  "Return arguments for `idle-highlight--highlight'."
  (when (idle-highlight--check-symbol-at-point (point))
    (let ((target-range (bounds-of-thing-at-point 'symbol)))
      (when (and target-range (idle-highlight--check-faces-at-point (point)))
        (pcase-let ((`(,target-beg . ,target-end) target-range))
          (let ((target (buffer-substring-no-properties target-beg target-end)))
            (when (idle-highlight--check-word target)
              (cons target target-range))))))))

(defun idle-highlight--word-at-point-highlight (target target-range visible-ranges)
  "Highlight the word under the point across all VISIBLE-RANGES.

Arguments TARGET and TARGET-RANGE
should be the result of `idle-highlight--word-at-point-args'."
  (idle-highlight--unhighlight)
  (when target
    (pcase-let ((`(,target-beg . ,target-end) target-range))
      (idle-highlight--highlight target target-beg target-end visible-ranges))))


;; ---------------------------------------------------------------------------
;; Internal Timer Management
;;
;; This works as follows:
;;
;; - The timer is kept active as long as the local mode is enabled.
;; - Entering a buffer runs the buffer local `window-state-change-hook'
;;   immediately which checks if the mode is enabled,
;;   set up the global timer if it is.
;; - Switching any other buffer wont run this hook,
;;   rely on the idle timer it's self running, which detects the active mode,
;;   canceling it's self if the mode isn't active.
;;
;; This is a reliable way of using a global,
;; repeating idle timer that is effectively buffer local.
;;

;; Global idle timer (repeating), keep active while the buffer-local mode is enabled.
(defvar idle-highlight--global-timer nil)
;; When t, the timer will update buffers in all other visible windows.
(defvar idle-highlight--dirty-flush-all nil)
;; When true, the buffer should be updated when inactive.
(defvar-local idle-highlight--dirty nil)

(defun idle-highlight--time-callback-or-disable ()
  "Callback that run the repeat timer."

  (let
    ( ;; Ensure all other buffers are highlighted on request.
      (is-mode-active (bound-and-true-p idle-highlight-mode))
      (buf-current (current-buffer))
      (dirty-buffer-list (list))
      (force-all idle-highlight-visible-buffers))

    ;; When this buffer is not in the mode, flush all other buffers.
    (cond
      (is-mode-active
        (setq idle-highlight--dirty t))
      (t
        ;; If the timer ran when in another buffer,
        ;; a previous buffer may need a final refresh, ensure this happens.
        (setq idle-highlight--dirty-flush-all t)))

    (when force-all
      (setq idle-highlight--dirty-flush-all t))

    ;; Accumulate visible ranges in each buffers `idle-highlight--dirty'
    ;; value which is temporarily used as a list to store ranges.
    (dolist (frame (frame-list))
      (dolist (win (window-list frame -1))
        (let ((buf (window-buffer win)))
          (when
            (cond
              (idle-highlight--dirty-flush-all
                (and
                  (buffer-local-value 'idle-highlight-mode buf)
                  (or (buffer-local-value 'idle-highlight--dirty buf) force-all)))
              (t
                (eq buf buf-current)))

            (unless (memq buf dirty-buffer-list)
              (push buf dirty-buffer-list))

            (with-current-buffer buf
              (when (eq idle-highlight--dirty t)
                (setq idle-highlight--dirty nil))
              ;; Push a (min . max) cons cell,
              ;; expanded to line bounds (to avoid clipping words).
              (save-excursion
                (push
                  (cons
                    (progn
                      (goto-char (max (point-min) (window-start win)))
                      (line-beginning-position))
                    (progn
                      (goto-char (min (point-max) (window-end win)))
                      (line-end-position)))
                  idle-highlight--dirty)))))))


    (let ((target-args (and force-all (idle-highlight--word-at-point-args))))
      (dolist (buf dirty-buffer-list)
        (with-current-buffer buf
          (let ((visible-ranges idle-highlight--dirty))
            ;; Restore this values status as a boolean.
            (setq idle-highlight--dirty nil)

            (setq visible-ranges (idle-highlight--merge-overlapping-ranges visible-ranges))

            (unless force-all
              (setq target-args (idle-highlight--word-at-point-args)))

            (pcase-let ((`(,target . ,target-range) target-args))
              (when (and force-all (not (eq buf buf-current)))
                (setq target-range nil))
              (idle-highlight--word-at-point-highlight target target-range visible-ranges))))))

    (cond
      (is-mode-active
        ;; Always keep the current buffer dirty
        ;; so navigating away from this buffer will refresh it.
        (setq idle-highlight--dirty t))
      (t ;; Cancel the timer until the current buffer uses this mode again.
        (idle-highlight--time-ensure nil)))))

(defun idle-highlight--time-ensure (state)
  "Ensure the timer is enabled when STATE is non-nil, otherwise disable."
  (cond
    (state
      (unless idle-highlight--global-timer
        (setq idle-highlight--global-timer
          (run-with-idle-timer
            idle-highlight-idle-time
            :repeat 'idle-highlight--time-callback-or-disable))))
    (t
      (when idle-highlight--global-timer
        (cancel-timer idle-highlight--global-timer)
        (setq idle-highlight--global-timer nil)))))

(defun idle-highlight--time-reset ()
  "Run this when the buffer change was changed."
  ;; Ensure changing windows doesn't leave other buffers with stale highlight.
  (cond
    ((bound-and-true-p idle-highlight-mode)
      (setq idle-highlight--dirty-flush-all t)
      (setq idle-highlight--dirty t)
      (idle-highlight--time-ensure t))
    (t
      (idle-highlight--time-ensure nil))))

(defun idle-highlight--time-buffer-local-enable ()
  "Ensure buffer local state is enabled."
  ;; Needed in case focus changes before the idle timer runs.
  (setq idle-highlight--dirty-flush-all t)
  (setq idle-highlight--dirty t)
  (idle-highlight--time-ensure t)
  (add-hook 'window-state-change-hook #'idle-highlight--time-reset nil t))

(defun idle-highlight--time-buffer-local-disable ()
  "Ensure buffer local state is disabled."
  (kill-local-variable 'idle-highlight--dirty)
  (idle-highlight--time-ensure nil)
  (remove-hook 'window-state-change-hook #'idle-highlight--time-reset t))


;; ---------------------------------------------------------------------------
;; Internal Mode Management

(defun idle-highlight--enable ()
  "Enable the buffer local minor mode."
  (idle-highlight--time-buffer-local-enable))

(defun idle-highlight--disable ()
  "Disable the buffer local minor mode."
  (idle-highlight--time-buffer-local-disable)
  (idle-highlight--unhighlight)
  (kill-local-variable 'idle-highlight--overlays))

(defun idle-highlight--turn-on ()
  "Enable command `idle-highlight-mode'."
  (when
    (and
      ;; Not already enabled.
      (not (bound-and-true-p idle-highlight-mode))
      ;; Not in the mini-buffer.
      (not (minibufferp))
      ;; Not a special mode (package list, tabulated data ... etc)
      ;; Instead the buffer is likely derived from `text-mode' or `prog-mode'.
      (not (derived-mode-p 'special-mode))
      ;; Not explicitly ignored.
      (not (memq major-mode idle-highlight-ignore-modes))
      ;; Optionally check if a function is used.
      (or
        (null global-idle-highlight-ignore-buffer)
        (cond
          ((functionp global-idle-highlight-ignore-buffer)
            (not (funcall global-idle-highlight-ignore-buffer (current-buffer))))
          (t
            nil))))
    (idle-highlight-mode 1)))


;; ---------------------------------------------------------------------------
;; Public Functions

;;;###autoload
(define-minor-mode idle-highlight-mode
  "Idle-Highlight Minor Mode."
  :global nil

  (cond
    (idle-highlight-mode
      (idle-highlight--enable))
    (t
      (idle-highlight--disable))))

;;;###autoload
(define-globalized-minor-mode
  global-idle-highlight-mode

  idle-highlight-mode idle-highlight--turn-on)

(provide 'idle-highlight-mode)
;;; idle-highlight-mode.el ends here
