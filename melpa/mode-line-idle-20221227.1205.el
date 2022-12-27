;;; mode-line-idle.el --- Evaluate mode line content when idle -*- lexical-binding:t -*-

;; SPDX-License-Identifier: GPL-2.0-or-later
;; Copyright (C) 2021  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.org/ideasman42/emacs-mode-line-idle
;; Package-Version: 20221227.1205
;; Package-Commit: ded89387212e09097ce055ea8a47a9694ea02d57
;; Version: 0.2
;; Package-Requires: ((emacs "28.1"))

;;; Commentary:

;; Simple delayed text evaluation for the mode-line.

;;; Usage

;; (defvar my-word '(:eval (count-words (point-min) (point-max))))
;; (setq-default mode-line-format
;;   (list "Word Count " '(:eval (mode-line-idle 1.0 my-word "?" :interrupt t))))
;;

;;; Code:

(eval-when-compile
  ;; For `pcase-dolist'.
  (require 'pcase))


;; ---------------------------------------------------------------------------
;; Generic Utility Functions

(defun mode-line-idle--tree-to-string (tree)
  "Convert TREE recursively to a string.
TREE can be one of the following:
- lists with `car' `:eval'
  - The `cdr' is evaluated and the result
    is passed to `mode-line-idle--tree-to-string'
- Lists with `car' `:propertize'
  - The `caar' is passed to `mode-line-idle--tree-to-string'.
  - The `cddr' is passed to as properties to `propertize'.
- Other lists: element-wise processed with `mode-line-idle--tree-to-string'
- A string is passed through (with any associated properties).
- A nil value is treated as an empty string.
- A symbol, it's value will be passed to `mode-line-idle--tree-to-string'.
- Any other element is converted into a string using `prin1-to-string'."
  (cond
   ((stringp tree)
    ;; Check for strings as falling back to `prin1-to-string' removes any properties
    ;; that may have been set on the string, see bug #2.
    tree)
   ((null tree)
    "")
   ((symbolp tree)
    ;; Support non-string symbols, allows numbers etc to be included.
    (mode-line-idle--tree-to-string (symbol-value tree)))
   ((listp tree)
    (let ((tree-type (car-safe tree)))
      (cond
       ((eq tree-type :eval)
        (mode-line-idle--tree-to-string (eval (cons 'progn (cdr tree)) t)))
       ((eq tree-type :propertize)
        (pcase-let ((`(,item . ,rest) (cdr tree)))
          (apply #'propertize (cons (mode-line-idle--tree-to-string item) rest))))
       (t
        (mapconcat #'mode-line-idle--tree-to-string tree "")))))
   (t
    ;; For convenience, support other values being coerced into strings.
    (prin1-to-string tree t))))


;; ---------------------------------------------------------------------------
;; Internal Variables

;; One off timers.
(defvar-local mode-line-idle--timers nil)
;; Cache evaluated expressions.
(defvar-local mode-line-idle--values nil)
;; Prevent timer creation when running the timer callback.
(defconst mode-line-idle--timer-lock nil)


;; ---------------------------------------------------------------------------
;; Internal Functions

(defun mode-line-idle--update-and-redisplay ()
  "Refresh the mode-line after refreshing it's contents."
  (force-mode-line-update)
  ;; Prevent `mode-line-idle' from starting new idle timers
  ;; since it can cause continuous updates.
  (let ((mode-line-idle--timer-lock t))
    (redisplay t)))

(defun mode-line-idle--timer-callback-impl (item &optional force)
  "Calculate all values for ITEM.
When FORCE is non-nil, don't check for interruption and don't re-display.

Return non-nil when any values were calculated."
  (let ((found nil)
        (has-input nil)
        (interrupt-args (list)))
    (pcase-dolist (`(,content . ,keywords) (cdr item))
      (let
          ( ;; Arguments which may be set from `keywords'.
           (kw-interrupt nil)
           (kw-literal nil))

        ;; Extract keyword argument pairs.
        (let ((kw-iter keywords))
          (while kw-iter
            (let ((key (car kw-iter)))
              (unless (setq kw-iter (cdr kw-iter))
                (message "Error, key has no value: %S" key))
              (cond
               ((eq key ':interrupt)
                (setq kw-interrupt (car kw-iter)))
               ((eq key ':literal)
                (setq kw-literal (car kw-iter)))
               (t
                (message "Error, unknown property for `mode-line-idle'found: %S" key)))
              (setq kw-iter (cdr kw-iter)))))

        (when force
          (setq kw-interrupt nil))

        ;; Replace the previous value, if it exists.
        (let ((value nil))
          (cond

           ;; Execute with support for interruption.
           (kw-interrupt
            (unless has-input
              (while-no-input
                (setq value (mode-line-idle--tree-to-string content)))
              (unless value
                (setq has-input t)))

            ;; Execution was interrupted, re-run later.
            (unless value
              (let ((default-text (cdr (assq content mode-line-idle--values))))
                ;; Build a list with cons, add it to `interrupt-args'
                (push (cons (car item) (cons content (cons default-text keywords))) interrupt-args))))

           ;; Default execution.
           (t
            (setq value (mode-line-idle--tree-to-string content))))

          ;; May be nil when interrupted.
          (when value

            ;; Prevent `mode-line-format' from interpreting `%'.
            (when kw-literal
              (setq value (string-replace "%" "%%" value)))

            (assq-delete-all content mode-line-idle--values)
            (push (cons content value) mode-line-idle--values)
            (setq found t)))))


    (unless force
      (when found
        (mode-line-idle--update-and-redisplay))

      ;; Re-create interrupted timers.
      (dolist (args interrupt-args)
        (apply #'mode-line-idle args)))

    found))

(defun mode-line-idle--timer-callback (buf item)
  "Calculate all values in BUF for the times associated with ITEM."
  ;; It's possible the buffer was removed since the timer started.
  ;; In this case there is nothing to do as the timer only runs once
  ;; and the variables are local.
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (mode-line-idle--timer-callback-impl item nil)
      ;; Remove this item.
      (setq mode-line-idle--timers (delq item mode-line-idle--timers)))))


;; ---------------------------------------------------------------------------
;; Public Functions

;;;###autoload
(defun mode-line-idle (delay-in-seconds content default-text &rest keywords)
  "Delayed evaluation of CONTENT, delayed by DELAY-IN-SECONDS.

Argument KEYWORDS is a property list of optional keywords:

- `:interrupt' When non-nil, interrupt evaluation on keyboard input
  (use for long running actions).
- `:literal' When non-nil, replace `%' with `%%',
  to prevent `mode-line-format' from formatting these characters."

  ;; Check if this is running within `mode-line-idle--timer-callback'.
  (unless mode-line-idle--timer-lock
    (let ((item (assoc delay-in-seconds mode-line-idle--timers)))
      (unless item
        ;; Use a float so `equal' comparisons can be used when the input is an int.
        (unless (floatp delay-in-seconds)
          (setq delay-in-seconds (float delay-in-seconds)))
        (setq item (cons delay-in-seconds (list)))
        ;; Since this is a one-off timer, no need to manage, fire and forget.
        (run-with-idle-timer delay-in-seconds nil #'mode-line-idle--timer-callback
                             (current-buffer)
                             item)
        (push item mode-line-idle--timers))

      ;; Add the symbol to the timer list.
      (let ((content-alist (cdr item)))
        ;; Paranoid check we don't add twice.
        (setq content-alist (assq-delete-all content content-alist))
        (push (cons content keywords) content-alist)
        (setcdr item content-alist))))

  ;; Return the cached value.
  (let ((value (cdr (assq content mode-line-idle--values))))
    (or value default-text)))

;;;###autoload
(defun mode-line-idle-force-update (&optional delay-in-seconds)
  "Calculate pending `mode-line-idle' entries immediately.
When DELAY-IN-SECONDS is nil, all pending values are calculated,
otherwise ignore pending timers over this time.
Return non-nil when the mode-line was updated."
  (let ((found nil))
    (dolist (item mode-line-idle--timers)
      (when (or (null delay-in-seconds) (<= (car item) delay-in-seconds))
        (when (mode-line-idle--timer-callback-impl item t)
          (setq found t))
        ;; The idle timer isn't removed, nothing left to compute.
        ;; An alternative solution would be to cancel the idle timer but that means storing
        ;; the idle timer to support a fairly rare use-case.
        (setcdr item nil)))
    (when found
      (mode-line-idle--update-and-redisplay))
    found))


(provide 'mode-line-idle)
;;; mode-line-idle.el ends here
