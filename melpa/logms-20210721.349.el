;;; logms.el --- Log message with clickable links to context  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Shen, Jen-Chieh
;; Created date 2021-06-26 23:22:27

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Log message with clickable links to context
;; Keyword: debug log
;; Version: 0.3.1
;; Package-Version: 20210721.349
;; Package-Commit: 904d90665fc67b5baba0357bf1ef2ac87e8cd43b
;; Package-Requires: ((emacs "27.1") (f "0.20.0") (s "1.9.0") (ht "2.3"))
;; URL: https://github.com/jcs-elpa/logms

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Log message with clickable links to context.
;;

;;; Code:

(require 'backtrace)
(require 'button)
(require 'find-func)
(require 'subr-x)

(require 'cl-lib)
(require 'f)
(require 's)
(require 'ht)

(defgroup logms nil
  "Log message with clickable links to context."
  :prefix "logms-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/logms"))

(defcustom logms-guess t
  "If non-nil, try to guess the declaration from eval history."
  :type 'boolean
  :group 'logms)

(defvar logms--eval-history nil
  "Records of all evaluate buffers.

If the eval buffer exists, then it will not be on this list.")

(defconst logms--search-context
  '("logms" "funcall" "apply"
    "run-with-idle-timer" "run-idle-timer")
  "Regular expression to search for logms calls.")

(defvar logms--search-context-cache nil
  "Cache for variable `logms--search-context', save some performance.")

(defvar logms--log-map (ht-create)
  "Record the log situation between from last to current command.

This resolved printing the same log in same frame level by acutally counting
the program execution.")

(defvar logms--show-log nil
  "Show the debug message from this package.")

(defvar logms--ignore-rule
  '("progn"             ; This cause mismatch with nested level
    "funcall" "apply")  ; Don't consume call frame count!
  "List of token that are being ignore by Emacs' backtrace.")

(defvar logms--ignore-call-frame
  '(funcall apply timer-event-handler)
  "Rule we ignore from backtrace stack frame.")

;;
;; (@* "Util" )
;;

(defun logms--log (fmt &rest args)
  "Debug message like function `message' with same arguments FMT and ARGS."
  (when logms--show-log (apply 'message fmt args)))

(defun logms--inside-comment-or-string-p ()
  "Return non-nil if it's inside comment or string."
  (or (nth 4 (syntax-ppss)) (nth 8 (syntax-ppss))))

(defmacro logms-with-messages-buffer (&rest body)
  "Execute BODY within the *Messages* buffer."
  (declare (indent 0) (debug t))
  `(with-current-buffer "*Messages*"
     (let (buffer-read-only) (progn ,@body))))

(defun logms--form-search-context ()
  "Form search context for list of `logms--search-context'."
  (unless logms--search-context-cache
    (let ((regex (nth 0 logms--search-context)) first)
      (dolist (keyword logms--search-context)
        (when first
          (setq regex (concat regex "\\|" keyword)))
        (setq first t))
      ;; Update cache.
      (setq logms--search-context-cache (format "[(']\\<\\(%s\\)[ \t\"]*" regex))))
  logms--search-context-cache)

(defun logms--count-symbols (symbol beg end)
  "Count the SYMBOL from region BEG to END."
  (let ((count 0))
    (save-excursion
      (goto-char beg)
      (while (search-forward symbol end t)
        ;; Make sure symbols isn't in comment or string
        (unless (logms--inside-comment-or-string-p)
          (setq count (1+ count)))))
    count))

(defun logms--nest-level-in-region (beg end)
  "Return the nest level from region BEG to END."
  (let ((opens (logms--count-symbols "(" beg end))
        (closes (logms--count-symbols ")" beg end)))
    (abs (- opens closes))))

(defun logms--nest-level-at-point ()
  "Return a integer indicates the nested level from current point."
  (let ((left (logms--nest-level-in-region (point-min) (point)))
        (right (logms--nest-level-in-region (point) (point-max))))
    (/ (+ left right) 2)))

(defun logms--callers-at-point (start)
  "Return a list of callers at point to START.

For example,

   (when t (prog (prog $))

Above code should return a list '(when progn progn)."
  (let ((level (logms--nest-level-at-point)) match callers parent-level)
    (save-excursion
      (while (re-search-backward "([ ]*\\([a-zA-Z0-9-]+\\)[ \t\r\n]+" start t)
        (setq match (match-string 1)
              parent-level (logms--nest-level-at-point))
        (when (< parent-level level)
          (setq level parent-level)
          (push match callers))))
    callers))

(defun logms--frame-level-at-point (start)
  "Return the caller level to START.

Callers are stack frames but limited with the rule `logms--ignore-rule'.

See function `logms--callers-at-point' for example."
  (let ((callers (logms--callers-at-point start)))
    (setq callers (cl-remove-if (lambda (caller) (member caller logms--ignore-rule)) callers))
    (length callers)))

(defun logms--return-args-at-point ()
  "Parse all arguments including variable names from point and return it.

Notice this isn't an ideal solution, yet it's the best what I can do here."
  (let ((beg (point)) content args)
    (save-excursion
      (forward-sexp)
      (setq content (buffer-substring beg (point))))
    (setq content (s-replace "(" "" content)
          content (s-replace ")" "" content)
          content (s-replace-regexp "logms[ ]*" "" content))
    (setq args (split-string content "\"" t)
          ;; Remove all empty strings
          args (cl-remove-if (lambda (arg) (string-empty-p (string-trim arg))) args))
    args))

(defun logms--compare-args-string (lst1 lst2)
  "Compare arguments LST1 and LST2.

This is use to resolve when logms are pass in string with no variables."
  (let ((same t) (index 0) (len1 (length lst1)) (len2 (length lst2)) item1 item2)
    (unless (= len1 len2) (setq same nil))
    (while (and same (< index len1))
      (setq item1 (nth index lst1) item2 (nth index lst2)
            item1 (format "%s" item1) item2 (format "%s" item2)
            ;; Trim the argument string should be fine since we are comparing
            ;; arguments and not the string itself!
            item1 (string-trim item1) item2 (string-trim item2))
      (unless (string= item1 item2) (setq same nil))
      (setq index (1+ index)))
    same))

(defun logms--compare-args-variable (args locals)
  "Compare arguments ARGS and LOCALS.

Argument ARGS are parsed arguments from function `logms--return-args-at-point'.

Argument LOCALS are locals from function `backtrace-frame-locals', see the
function's description for more information.

This is use to resolve when logms are pass in with variables."
  (let (name (match-count 0) (locals-len (length locals)))
    (dolist (pair locals)
      (setq name (car pair))
      (dolist (arg args)
        ;; We are only comparing variable names and no values because another
        ;; function `logms--compare-args-string' already done the task for us
        (when (string= (symbol-name name) (string-trim arg))
          (setq match-count (1+ match-count)))))
    ;; The match should be exactly the same of the length of locals
    (= match-count locals-len)))

;;
;; (@* "Mode" )
;;

(defun logms--enable ()
  "Enable function `logms-mode'."
  (advice-add 'eval-buffer :before #'logms--eval)
  (advice-add 'eval-region :before #'logms--eval))

(defun logms--disable ()
  "Disable function `logms-mode'."
  (advice-remove 'eval-buffer #'logms--eval)
  (advice-remove 'eval-region #'logms--eval))

;;;###autoload
(define-minor-mode logms-mode
  "Minor mode for `logms'."
  :global t
  :require 'logms
  :group 'logms
  (if logms-mode (logms--enable) (logms--disable)))

;;
;; (@* "Core" )
;;

(defun logms--clean-eval-history ()
  "Clean up evaluate history."
  (delete-dups logms--eval-history)
  (setq logms--eval-history
        (cl-remove-if (lambda (buf) (or (not (buffer-live-p buf))
                                        (with-current-buffer buf (buffer-file-name))))
                      logms--eval-history)))

(defun logms--next-msg-point ()
  "Return max point in *Messages* buffer."
  (logms-with-messages-buffer (point-max)))

(defun logms--backtrace-timer-event (frames)
  "Report error if current backtrace FRAMES is from timer event.

Note there is no way you can track timer event since you cannot track a
delay function and expect to record states (window/frame/cursor, etc) that
already happened."
  (cl-some (lambda (frame)
             (equal (backtrace-frame-fun frame) 'timer-event-handler))
           frames))

(defun logms--last-call-stack-backtrace ()
  "Return the last stack frame right before of the logms function begin called.

By using this function to find the where the log came from.

It returns cons cell from by (current frame . backtrace)."
  (let* ((frames (backtrace-get-frames 'logms)) (frames-len (length frames))
         (backtrace (list (nth 0 frames)))  ; always has the base frame
         (index 1) break frame evald fun)
    (while (and (not break) (< index frames-len))
      (setq frame (nth index frames)
            evald (backtrace-frame-evald frame)
            fun (backtrace-frame-fun frame)
            index (1+ index))
      (push frame backtrace)
      (when (and evald (not (memq fun logms--ignore-call-frame)))
        (setq break t)))
    (unless (symbolp fun) (pop backtrace))
    (setq backtrace
          (cl-remove-if (lambda (f)
                          (let ((caller (backtrace-frame-fun f)))
                            (and (symbolp caller)
                                 (member (symbol-name caller) logms--ignore-rule))))
                        backtrace))
    (when (and (logms--backtrace-timer-event frames)  ; Is timer event?
               (or
                ;; If nearest frame is timer event, it has been called directly
                ;; like the following
                ;;
                ;;   (run-with-timer 1 nil #'logms SOME-TEXT)
                (and (symbolp fun) (eq fun 'timer-event-handler))
                ;; If nearest frame is lambda, it has been called with lambda
                ;; wrapper,
                ;;
                ;;   (run-with-timer 1 nil (lambda () (logms SOME-TEXT)))
                (and (consp fun) (symbolp (car fun)) (eq (car fun) 'lambda))))
      (user-error "[WARNING] Invalid timer event to `logms`, please define a valid source"))
    ;; FRAME is the up one level call stack. BACKTRACE is used to compare
    ;; the frame level.
    (cons frame (reverse backtrace))))

(defun logms--goto-starting-stack-frame (start)
  "Navigate to starting of the current call frame.

Argument START is the minimum boundary we can search through."
  (re-search-backward (logms--form-search-context) start t)  ; allow search for symbol '
  ;; Make sure we found the starting stack frame
  (when (equal (ignore-errors (string (char-after))) "'")
    (search-backward "(" nil t)))

(defun logms--find-logms-point (backtrace start frame-args)
  "Move to the source point.

Argument BACKTRACE is used to find the accurate position of the message.
Argument START to prevent search from the beginning of the file.

FRAME-ARGS is a list of cons cell represent variable names and values.  See
function `backtrace-frame-locals' for more information since we are getting
the data directly from it function."
  (goto-char start)
  ;; BACKTRACE will always return a list with minimum length of 1
  (let ((level (1- (length backtrace))) frame-level args parsed-args
        (end (or (ignore-errors (save-excursion (forward-sexp) (point)))
                 (point-max)))
        found (searching t)
        key val (count 0) missing)
    (while (and (not found) (not missing))
      (setq searching (re-search-forward (logms--form-search-context) end t))
      ;; If search failed, start from the beginning, this
      (unless searching
        ;; After search a round, if not found then it's missing
        (unless found (setq missing t))
        (goto-char start)  ; occures when inside a loop
        (setq searching (re-search-forward (logms--form-search-context) end t)))
      (logms--goto-starting-stack-frame start)
      (logms--log "\f")
      (logms--log "0: %s %s" (point) end)
      (unless (logms--inside-comment-or-string-p)  ; comment or string?
        (setq frame-level (logms--frame-level-at-point start))
        (logms--log "1: %s %s %s" level frame-level (point))
        ;; FIXME: The level comparison is not accurate but sufficient.
        ;;
        ;; The issue is backtrace frame does not take `progn' into an account
        ;; but `logms--nest-level-at-point' does take this into account (since
        ;; we are just only calculating the nesting level).
        (when (= level frame-level)  ; compare frame level
          (setq args (backtrace-frame-args (nth 0 backtrace))
                parsed-args (logms--return-args-at-point))
          (logms--log "2: %s | %s %s" parsed-args args frame-args)
          (when (or (logms--compare-args-string parsed-args args)
                    (logms--compare-args-variable parsed-args frame-args))  ; compare arguments
            (logms--log "3: found")
            ;; NOTE: LEVEL is inaccurate, FRAME-LEVEL should be correct
            (setq key (cons frame-args frame-level) val (ht-get logms--log-map key)
                  count (1+ count))
            (when (or (null val) (< val count))
              (setq found t)
              (ht-set logms--log-map key count)))))
      ;; Revert last search point
      (when searching (goto-char searching)))
    ;; Go back to the start of the symbol so it looks nicer
    (when found (logms--goto-starting-stack-frame start))
    (if missing 'missing (point))))

(defun logms--make-button (beg end source pt)
  "Make a button from BEG to END.
Argument SOURCE is the buffer prints the log.
Argument PT indicates where the log beging print inside SOURCE buffer."
  (ignore-errors
    (make-text-button beg end 'follow-link t
                      'action (lambda (&rest _)
                                ;; If source is string, then it has to be a file path
                                (when (and (stringp source) (file-exists-p source))
                                  (save-window-excursion  ; find it, and update source
                                    (find-file source)
                                    (setq source (current-buffer))))
                                ;; Display the source buffer and it's position
                                (if (not (buffer-live-p source))
                                    (user-error "Buffer no longer exists: %s" source)
                                  (unless (equal source (current-buffer))
                                    (switch-to-buffer-other-window source))
                                  (goto-char pt))))))

(defun logms--guess-buffer (caller)
  "Return guessed buffer and it's point from CALLER."
  (let (guessed-buffer point)
    (cl-some (lambda (buf)
               (with-current-buffer buf
                 (save-excursion
                   (goto-char (point-min))
                   (setq point (search-forward (symbol-name caller) nil t))
                   (when point
                     (goto-char point)
                     (search-backward "(" nil t)
                     (setq guessed-buffer buf
                           point (point)))))
               guessed-buffer)
             logms--eval-history)
    (cons guessed-buffer point)))

(defun logms--find-source (call)
  "Return the source information by CALL."
  (save-excursion
    (let* ((source (current-buffer)) (pt (point))
           (line (line-number-at-pos pt))
           (column (current-column))
           (frame (car call)) (caller (backtrace-frame-fun frame))
           (backtrace (cdr call))
           (old-buf-lst (buffer-list))
           find-function-after-hook found
           guessed-info guessed-buffer guessed-point
           (c-inter (eq caller this-command)) start)

      (save-window-excursion
        ;; * If symbol, there is defined call stack we can look for; unless
        ;; it's compiled and the source is from C code.
        ;;
        ;; * If not symbol, it's evaluate somewhere in memory
        ;;
        ;; * Excluding `funcall` and `apply`, both functions are compiled hence
        ;; the source is from C code.  (See bullet Pt. 1)
        (when (and (symbolp caller)
                   (not (memq caller logms--ignore-call-frame)))
          (add-hook 'find-function-after-hook (lambda () (setq found t)))
          (let ((message-log-max nil) (inhibit-message t))
            (ignore-errors (find-function caller))))

        (if found
            (setq source (buffer-file-name))  ; Update source information

          ;; guess from evaluate buffer history
          (if (and logms-guess (symbolp caller))
              (setq guessed-info (logms--guess-buffer caller)
                    guessed-buffer (car guessed-info)
                    guessed-point (cdr guessed-info))
            (backward-sexp)))

        (setq source (or guessed-buffer source))

        (with-current-buffer (if found (current-buffer) source)
          (goto-char (or guessed-point (point)))
          (setq start (point))
          (setq pt (logms--find-logms-point backtrace (point) (backtrace-frame-locals frame))
                line (line-number-at-pos (point))
                column (current-column)))

        (when (equal pt 'missing)
          (goto-char start)
          (setq pt start  ; revert
                line (line-number-at-pos (point))
                column (current-column))
          (when c-inter (user-error "Source missing, caller: %s" caller)))

        (when found
          ;; Kill if it wasn't opened
          (unless (= (length old-buf-lst) (length (buffer-list)))
            (kill-buffer (current-buffer)))))

      (list source pt line column))))

;;;###autoload
(defun logms (fmt &rest args)
  "Debug message like function `message' with same argument FMT and ARGS."
  (if (not logms-mode) (apply 'message fmt args)
    (add-hook 'post-command-hook #'logms--post-command)
    (let* ((call (logms--last-call-stack-backtrace))
           (info (logms--find-source call))
           (source (nth 0 info)) (pt (nth 1 info)) (line (nth 2 info)) (column (nth 3 info))
           (name (if (stringp source) (f-filename source) (buffer-name source)))
           (display (format "%s:%s:%s" name line column))
           (display-len (length display))
           (beg (logms--next-msg-point)) result)
      (setq result (apply 'message (concat "%s " fmt) display args))
      (logms-with-messages-buffer
        (unless (logms--make-button beg (+ beg display-len) source pt)
          (setq beg (save-excursion
                      (goto-char beg)
                      (when (= (line-beginning-position) (point-max))
                        (forward-line -1))
                      (line-beginning-position)))
          (logms--make-button beg (+ beg display-len) source pt)))
      result)))

(defun logms--post-command ()
  "Post command hook."
  (ht-clear logms--log-map)  ; clear it once after each command's execution
  ;; Remove hook, so we don't waste performance
  (remove-hook 'post-command-hook #'logms--post-command))

;;
;; (@* "Eval" )
;;

(defun logms--eval (&rest _)
  "Save evaluated buffer as history."
  (push (current-buffer) logms--eval-history)
  (logms--clean-eval-history))

(provide 'logms)
;;; logms.el ends here
