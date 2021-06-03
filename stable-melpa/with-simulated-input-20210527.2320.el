;;; with-simulated-input.el --- A macro to simulate user input non-interactively -*- lexical-binding: t -*-

;; Copyright (C) 2017 Ryan C. Thompson

;; Filename: with-simulated-input.el
;; Maintainer: Ryan C Thompson <rct@thompsonclan.org>
;; Author: Ryan C. Thompson <rct@thompsonclan.org>
;;    Nikita Bloshchanevich <nikblos@outlook.com>
;; Created: Thu Jul 20 11:56:23 2017 (-0700)
;; Version: 3.0
;; Package-Version: 20210527.2320
;; Package-Commit: 0f43fe46d4ab098c18a90b9df18cb96bab8e4a35
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/DarwinAwardWinner/with-simulated-input
;; Keywords: lisp, tools, extensions

;; This file is NOT part of GNU Emacs.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:

;; This package provides a single macro, `with-simulated-input', which
;; evaluates one or more forms while simulating a sequence of input
;; events for those forms to read. The result is the same as if you
;; had evaluated the forms and then manually typed in the same input.
;; This macro is useful for non-interactive testing of normally
;; interactive commands and functions, such as `completing-read'.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'files)
(require 'cl-lib)

(defvar wsi-last-used-next-action-bind nil
  "Last keybind used by `with-simulated-input', if any.")

(cl-defun wsi-key-bound-p (key)
  "Return non-nil if KEY is bound in any keymap.

This function checks every keymap in `obarray' for a binding for
KEY, and returns t if it finds and and nil otherwise. Note that
this checks ALL keymaps, not just currently active ones."
  (catch 'bound
    (mapatoms
     (lambda (sym)
       (let ((keymap
              (when (boundp sym)
                (symbol-value sym))))
         (when (keymapp keymap)
           (let ((binding (lookup-key keymap (kbd key))))
             (when binding
               (throw 'bound t)))))))
    (throw 'bound nil)))

(cl-defun wsi-get-unbound-key
    (&optional (modifiers '("C-M-A-s-H-" "C-M-A-s-" "C-M-A-H-"))
               (keys "abcdefghijklmnopqrstuvwxyz0123456789"))
  "Return a key binding that is not bound in any known keymap.

This function will check every letter from a to z and every
number from 0 through 9 with several combinations of multiple
modifiers (i.e. control, meta, alt, super, hyper). For each such
key combination, it will check for bindings in all known keymaps,
and return the first combination for which no such bindings
exist. Thus, it should be safe to bind this key in a new keymap
without interfering with any existing keymap.

Optional arguments MODIFIERS and KEYS can be used the change the
search space. MODIFIERS is a list of strings representing
modifier combinations, e.g.:

    '(\"C-\" \"M-\" \"C-M-\")

for control, meta, or both. KEYS is a string containing all keys
to check.

When this function returns, it also sets
`wsi-last-used-next-action-bind' to the return value. The next
time it is called, it checks this variable to see if it is still
usable, and returns it if so, even if it isn't a valid choice
given the value of MODIFIERS and KEYS."
  (declare (advertised-calling-convention (&optional modifiers keys) nil))
  (when (stringp modifiers)
    (setq modifiers (list modifiers)))
  (when (listp keys)
    (setq keys (apply #'concat keys)))
  (if (and wsi-last-used-next-action-bind
           (not (wsi-key-bound-p wsi-last-used-next-action-bind)))
      wsi-last-used-next-action-bind
    (cl-loop
     named findkey
     for modifier in modifiers
     do (cl-loop
         for char across keys
         for bind = (concat modifier (string char))
         when (not (wsi-key-bound-p bind))
         do (cl-return-from findkey
              (setq wsi-last-used-next-action-bind bind)))
     finally do (error "Could not find an unbound key with the specified modifiers"))))

(defsubst wsi--looks-constant-p (expr)
  "Return non-nil if EXPR looks like a constant expression.

This function may return nil for some constant expressions, but if
it returns non-nil, then EXPR is definitely constant.
\"Constant\" means that EXPR will always evaluate to the same
value and will never have side effects. In general, this means
that EXPR consists only of calls to pure functions with constant
arguments."
  (pcase expr
    ((pred hack-one-local-variable-constantp) t)
    ;; Any symbol not matched by the above is a variable, i.e. not
    ;; constant.
    ((pred symbolp) nil)
    ((pred atom) t)
    ((pred functionp) t)
    ;; Quoted expressions are constant
    (`(quote ,_x) t)
    (`(function ,_x) t)))

(defsubst wsi--looks-pure-p (expr)
  "Return non-nil if EXPR looks like a pure expression.

In this context, \"pure\" means that the expression has no side
effects and its value depends only on its arguments. In general,
this means that EXPR consists only of calls to pure functions,
constants, and variables. In particular, any constant expression
is pure.

This function may return nil for some pure expressions, but if it
returns non-nil, then EXPR is definitely pure."
  ;; TODO: Use the pure/side-effect-free symbol properties to more
  ;; aggressively identify expressions that will not read input/have
  ;; side effects.
  (pcase expr
    ((pred symbolp) t)
    ((pred wsi--looks-constant-p) t)))

(defsubst wsi--looks-input-free-p (expr)
  "Return non-nil if EXPR definitely does not read input.

This function may return nil for some expressions that don't read
input, but if it returns non-nil, then EXPR definitely does not
read input."
  (wsi--looks-pure-p expr))

(defun wsi--remove-irrelevant-keys (keys &optional quiet)
  "Filter out irrelevant elements from KEYS.

Helper function for `with-simulated-input'. The only relevant
elements of KEYS are strings, characters, nil, and expressions
that will have side effects (e.g. `(insert \"hello\")'). Other
elements are filtered out, and an appropriate warning is
generated for each one unless QUIET is non-nil."
  (cl-loop
   for key in keys
   if (stringp key) collect key
   else if (characterp key) collect key
   ;; It is occasionally useful to include nil as an element of
   ;; KEYS, so we don't produce a warning for it.
   else if (null key) do (ignore)
   else if (wsi--looks-pure-p key) do
   (unless quiet
     (display-warning
      'with-simulated-input-1
      ;; Generate an appropriate warning message for the specific
      ;; type of pure expression
      (concat
       "Non-string forms in KEYS are evaluated for side effects only. "
       (format
        (cond
         ((functionp key)
          "Functions in KEYS have no effect unless they are called: %S")
         ((wsi--looks-constant-p key)
          "Non-string constants in KEYS have no effect: %S")
         ((symbolp key)
          "Variables in KEYS have no effect: %S")
         (t
          "Pure expressions in KEYS have no effect: %S"))
        key))))
   ;; Anything else might be an expression with side effects.
   else collect key))

;;;###autoload
(defun with-simulated-input-1 (main &rest keys)
  "Internal `with-simulated-input' helper.

MAIN is a zero-argument function containing the body forms to be
evaluated, and KEYS is a list of key sequences (as strings) or
other actions to simulate user interaction (as zero-argument
functions, which are called only for their side effects)."
  (let* ((next-action-key (wsi-get-unbound-key))
         ;; Ensure we don't interfere with any outside catching.
         (result-sym (make-symbol "result"))
         (error-sym (make-symbol "error"))
         (orig-buf (current-buffer))
         (actions
          (nconc
           (list (lambda ()
                   (switch-to-buffer orig-buf)
                   (throw result-sym (funcall main))))
           (cl-remove-if-not #'functionp keys)
           (list (lambda ()
                   (error "Aborted evaluation of BODY after reaching end of KEYS without returning")))))
         (overriding-terminal-local-map
          (if overriding-terminal-local-map
              (copy-keymap overriding-terminal-local-map)
            (make-sparse-keymap))))
    (define-key overriding-terminal-local-map (kbd next-action-key)
      (lambda ()
        (interactive)
        (condition-case data
            (funcall (pop actions))
          (error (throw error-sym data)))))
    (catch result-sym
      ;; Signals are not passed through `read-from-minibuffer'.
      (let ((err (catch error-sym
                   (execute-kbd-macro
                    (kbd (mapconcat
                          #'identity
                          (nconc (list next-action-key)
                                 (cl-loop for key in keys collect
                                          (if (stringp key) key next-action-key))
                                 (list next-action-key))
                          " "))))))
        (signal (car err) (cdr err))))))

;;;###autoload
(defmacro with-simulated-input (keys &rest body)
  "Eval BODY forms with KEYS as simulated input.

This macro is intended for automated testing of normally
interactive functions by simulating input. If BODY tries to read
user input (e.g. via `completing-read'), it will read input
events from KEYS instead, as if the user had manually typed those
keys after initiating evaluation of BODY.

KEYS should be a string representing a sequence of key presses,
in the format understood by `kbd'. In the most common case of
typing in some text and pressing RET, KEYS would be something
like `\"hello RET\"'. Note that spaces must be indicated
explicitly using `SPC', e.g. `\"hello SPC world RET\"'.

KEYS can also be a single character, which is equivalent to a
string of length 1.

KEYS can also be a list of strings (or characters), which will be
used as consecutive inputs. (This list should not be quoted,
since `with-simulated-input' is a macro.) Elements of the list
can also be function calls, which will be evaluated at that point
in the input sequence. This can be used as an alternative to
writing out a full key sequence. For example, `\"hello SPC world
RET\"' could also be written as:

    `((insert \"hello world\") \"RET\")'

It can also be used to implement more complex logic, such as
conditionally inserting a string. Note that the return value of
any function call in KEYS is ignored, so the function should
actually perform some kind of action, or else it will have no
effect.

Lastly, KEYS can also be the name of a variable whose value is a
string. The variable's value will be used as described above.

If BODY tries to read more input events than KEYS provides, an
error is signaled. This is to ensure that BODY will never get
stuck waiting for input, since this macro is intended for
non-interactive use. If BODY does not consume all the input
events in KEYS, the remaining input events in KEYS are discarded,
and any remaining function calls in KEYS are never evaluated. In
particular, if KEYS is nil, then an error will be signaled if
BODY attempts to read any input, and if BODY is nil, a constant
expression, or an expression that does not read any input, then
KEYS will be ignored completely.

Any errors generated by any means during the evaluation of BODY
or the evaluation of function calls in KEYS are propagated
normally.

The return value is the last form in BODY, as if it was wrapped
in `progn'.

(Note: KEYS supports some additional semantics for
backward-compatibilty reasons. These semantics are considered
deprecated and are left intentionally undocumented. They should
not be used in newly written code, since they will stop working
in a future release.)"
  (declare
   (indent 1)
   (debug ([&or ("quote" (&rest &or stringp characterp form)) ; quoted list of keys
                (&rest &or stringp characterp form) ; un-quoted list of keys
                stringp                 ; single literal string
                characterp              ; single literal character
                symbolp                 ; single variable name (or nil)
                ([&or functionp macrop] &rest form) ; arbitrary lisp function call
                ]
           body)))
  (cond
   ;; This case applies when BODY consists of only constant
   ;; expressions (or no expressions at all). Since all the
   ;; expressions are constant, there's no point in evaluating any of
   ;; them except the last one, and there's no possibility that any
   ;; input will be read, so we can skip all the proprocessing and
   ;; just return the last element of BODY.
   ((not (cl-find-if-not #'wsi--looks-constant-p body))
    (display-warning
     'with-simulated-input
     (if body
         "BODY consists of only constant expressions; KEYS will be ignored."
       "BODY is empty; KEYS will be ignored."))
    (car (last body)))
   ;; This case applies when BODY is not constant, but *is* known not
   ;; to contain any expressions that read input. In this case, all
   ;; expressions in BODY need to be evaluated, but KEYS can still be
   ;; ignored.
   ((not (cl-find-if-not #'wsi--looks-input-free-p body))
    (display-warning
     'with-simulated-input
     "BODY does not read input; KEYS will be ignored.")
    `(progn ,@body))
   ;; If KEYS is nil, we don't have to do any pre-processing on it. We
   ;; still need to call `with-simulated-input-1', which will evaluate
   ;; BODY and throw an error if it tries to read input.
   ((null keys)
    `(with-simulated-input-1
      (lambda ()
        ,@body)
      nil))
   ;; If KEYS is a symbol, then it is a variable reference. This is
   ;; supported if the value is a string, a character, or nil. (Other
   ;; values are currently supported for backwards-compatibility, but
   ;; are deprecated.)
   ((and keys (symbolp keys))
    (when (keywordp keys)
      (error "KEYS must be a string, character, or list, not keyword: %s"
             keys))
    `(cond
      ((null ,keys)
       (with-simulated-input-1
        (lambda ()
          ,@body)
        nil))
      ((stringp ,keys)
       (with-simulated-input-1
        (lambda ()
          ,@body)
        ,keys))
      ((characterp ,keys)
       (with-simulated-input-1
        (lambda ()
          ,@body)
        (key-description (string ,keys))))
      ((consp ,keys)
       (display-warning
        'with-simulated-input
        "Passing a variable with a list value as KEYS is deprecated and will not be supported in future releases.")
       (apply
        #'with-simulated-input-1
        (lambda ()
          ,@body)
        (cl-loop
         for key in (wsi--remove-irrelevant-keys ,keys)
         if (stringp key) collect key
         else if (characterp key) collect (key-description (string key))
         else if key collect `(lambda () ,key))))
      (t
       (error "KEYS must be a string, character, or list, not %s: %s = %S"
              (type-of ,keys) ',keys ,keys))))
   ;; If KEYS is a list whose first element is a function other than
   ;; `quote', then it is a function call, whose return value will be
   ;; used as the value of KEYS. This is *definitely* deprecated.
   ((and (listp keys)
         (not (eq (car keys) 'quote))
         (or (functionp (car keys))
             (macrop (car keys))))
    (display-warning
     'with-simulated-input
     (format
      "Passing a function call as KEYS is deprecated and will not be supported in future releases: %S"
      keys))
    (let ((evaluated-keys-sym (make-symbol "evaluated-keys")))
      `(let ((,evaluated-keys-sym (,@keys)))
         (pcase ,evaluated-keys-sym
           (`(quote ,x)
            (prog1 (setq ,evaluated-keys-sym x)
              (display-warning
               'with-simulated-input
               "Passing a quoted list as KEYS is deprecated and will not be supported in future releases.")))
           ((guard (not (listp ,evaluated-keys-sym))) (cl-callf list ,evaluated-keys-sym)))
         (apply
          #'with-simulated-input-1
          (lambda ()
            ,@body)
          (cl-loop
           for key in (wsi--remove-irrelevant-keys ,evaluated-keys-sym)
           if (stringp key) collect key
           else if (characterp key) collect (key-description (string key))
           else if key collect `(lambda () ,key))))))
   ;; The primary supported KEYS syntax: either a string, or an
   ;; un-quoted list of strings and list expressions to execute as
   ;; input.
   (t
    ;; Unwrap a quoted expression
    (pcase keys
      (`(quote ,x)
       (display-warning
        'with-simulated-input
        (format
         "Passing a quoted list as KEYS is deprecated and will not be supported in future releases: %S" keys))
       (setq keys x)))
    ;; Ensure KEYS has the correct type, and convert a non-list keys
    ;; into a 1-element list.
    (unless (listp keys)
      (if (or (null keys)
              (stringp keys)
              (characterp keys))
          (setq keys (list keys))
        (error "KEYS must be a string, character, or list, not %s: KEYS = %S"
               (type-of keys) keys)))
    `(with-simulated-input-1
      (lambda ()
        ,@body)
      ,@(cl-loop
         for key in (wsi--remove-irrelevant-keys keys)
         if (stringp key) collect key
         else if (characterp key) collect (key-description (string key))
         else if key collect `(lambda () ,key))))))

(defvar wsi-simulated-idle-time nil
  "The current simulated idle time.

While simulating idle time using `wsi-simulated-idle-time', this
variable will always be set to the amount of idle time that has
been simulated so far. For example, if an idle time is set to run
every 5 seconds while idle, then on its first run, this will be
set to 5 seconds, then 10 seconds the next time, and so on.")

(defun current-idle-time@simulate-idle-time (orig-fun &rest args)
  "Return the faked value while simulating idle time.

While executing `wsi-simulate-idle-time', this advice causes the
simulated idle time to be returned instead of the real value.

ORIG-FUN is the original function, passed by `advice-add'; ARGS
are the arguments given to it."
  (if wsi-simulated-idle-time
      (when (time-less-p (seconds-to-time 0) wsi-simulated-idle-time)
        wsi-simulated-idle-time)
    (apply orig-fun args)))
(advice-add 'current-idle-time
            :around #'current-idle-time@simulate-idle-time)

(cl-defun wsi-simulate-idle-time (&optional secs actually-wait)
  "Run all idle timers with delay less than SECS.

This simulates resetting the idle time to zero and then being
idle for SECS seconds. Hence calling this function twice with
SECS = 1 is not equivalent to 2 seconds of idle time.

If ACTUALLY-WAIT is non-nil, this function will also wait for the
specified amount of time before running each timer.

If SECS is nil, simulate enough idle time to run each timer in
`timer-idle-list' at least once. (It's possible that some timers
will be run more than once, since each timer could potentially
add new timers to the list.)

While each timer is running, `current-idle-time' will be
overridden to return the current simulated idle time.

The idle time simulation provided by this function is not
perfect. For example, this function does not run any timers in
`timer-list', even though they would run as normal during real
idle time. In addition, weird effects may occur if idle timers
add other idle timers."
  (interactive
   "nSeconds of idle time: \nP")
  ;; SECS defaults to the maximum idle time of any currently active
  ;; timer.
  (unless secs
    (setq secs
          (cl-loop for timer in timer-idle-list
                   maximize (float-time (timer--time timer)))))
  ;; Add a small fudge factor to deal with SECS being exactly equal to
  ;; a timer's time, to avoid floating point issues.
  (setq secs (+ secs 0.0001))
  (cl-loop
   with already-run-timers = nil
   with stop-time = (seconds-to-time secs)
   with wsi-simulated-idle-time = (seconds-to-time 0)
   ;; We have to search `timer-idle-list' from the beginning each time
   ;; through the loop because each timer that runs might add more
   ;; timers to the list, and picking up at the same list position
   ;; would ignore those new timers.
   for next-timer = (car (cl-member-if-not
                          (lambda (timer)
                            (and (memq timer already-run-timers)))
                          timer-idle-list))
   ;; Stop if we reach the end of the idle timer list, or if the next
   ;; timer's idle time is greater than SECS
   while (and next-timer (time-less-p (timer--time next-timer) stop-time))
   for previous-idle-time = wsi-simulated-idle-time
   if (time-less-p wsi-simulated-idle-time
                   (timer--time next-timer))
   do (setq wsi-simulated-idle-time
            (timer--time next-timer))
   when actually-wait
   do (sleep-for (float-time (time-subtract wsi-simulated-idle-time
                                            previous-idle-time)))
   while (time-less-p wsi-simulated-idle-time stop-time)
   when (not (timer--triggered next-timer))
   do (timer-event-handler next-timer)
   do (push next-timer already-run-timers)
   finally do
   (when actually-wait
     (sleep-for (float-time (time-subtract stop-time
                                           wsi-simulated-idle-time))))))

(defun with-simulated-input-unload-function ()
  "Unload the `with-simulated-input' library."
  (advice-remove 'current-idle-time
                 #'current-idle-time@simulate-idle-time))

(provide 'with-simulated-input)

;;; with-simulated-input.el ends here
