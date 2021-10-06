;;; recomplete.el --- Immediately (re)complete actions -*- lexical-binding: t -*-

;; Copyright (C) 2020  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-recomplete
;; Package-Version: 20211006.1406
;; Package-Commit: 8b794d194799468443252d9a54489b5beb01eb76
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides mechanism for immediate completion, running again cycles over options.

;;; Usage

;;
;; A key can be bound to a completion action,
;; to cycle in the reverse direction you can either press \\[keyboard-quit]
;; which causes the next completion to move in the opposite direction
;; or bind a key to cycle backward.
;;
;; Example:
;;
;;   ;; Map Alt-P to correct the current word.
;;   (global-set-key (kbd "M-p") 'recomplete-ispell-word)

;;; Code:

(eval-when-compile (require 'seq))

;; TODO: make this lazy load (not everyone needs to use).
(require 'dabbrev)


;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup recomplete nil "Extensible, immediate completion utility." :group 'tools)

(defcustom recomplete-single-line-display t
  "Display completion options to a single line, centered around the current item."
  :type 'boolean)


;; ---------------------------------------------------------------------------
;; Internal Variables

;; Notes on the use of this variable.
;;
;; - This stores the undo state such that we can undo and perform a new action.
;; - This is set to nil via `recomplete--alist-clear-hook' when incompatible functions run.
;;
;; Keys are:
;; - `buffer-undo-list': The undo state before execution.
;; - `pending-undo-list': The undo state before execution.
;; - `point' The point before execution.
;; - `msg-text' The point before execution.
;; - `cycle-index' The position in the list of options to cycle through.
;; - `cycle-reverse' when t, reverse the cycle direction.
;; - `fn-symbol' The symbol to identify the type of chain being cycled.
;; - `fn-cache' Optional cache for the callback to use
;;   (stored between calls to the same chain, avoids unnecessary recalculation).
;;   Using this is optional, it can be left nil by callbacks.
;; - `is-first-post-command' Detect if the `post-command-hook' runs immediately
;;   after `recomplete-with-callback', so we know not to break the chain in that case.
(defvar-local recomplete--alist nil "Internal properties for repeated `recomplete' calls.")

;; ---------------------------------------------------------------------------
;; Generic Functions/Macros

(defmacro recomplete--with-advice (fn-orig where fn-advice &rest body)
  "Execute BODY with advice added.

WHERE using FN-ADVICE temporarily added to FN-ORIG."
  `
  (let ((fn-advice-var ,fn-advice))
    (unwind-protect
      (progn
        (advice-add ,fn-orig ,where fn-advice-var)
        ,@body)
      (advice-remove ,fn-orig fn-advice-var))))


;; See: https://emacs.stackexchange.com/a/54412/2418
(defmacro recomplete--with-undo-collapse (&rest body)
  "Like `progn' but perform BODY with undo collapsed."
  (declare (indent 0) (debug t))
  (let
    (
      (handle (make-symbol "--change-group-handle--"))
      (success (make-symbol "--change-group-success--")))
    `
    (let
      (
        (,handle (prepare-change-group))
        ;; Don't truncate any undo data in the middle of this.
        (undo-outer-limit nil)
        (undo-limit most-positive-fixnum)
        (undo-strong-limit most-positive-fixnum)
        (,success nil))
      (unwind-protect
        (progn
          (activate-change-group ,handle)
          (prog1 ,(macroexp-progn body)
            (setq ,success t)))
        (cond
          (,success
            (accept-change-group ,handle)
            (undo-amalgamate-change-group ,handle))
          (t
            (cancel-change-group ,handle)))))))

(defmacro recomplete--with-messages-as-list (message-list &rest body)
  "Run BODY adding any message call to the MESSAGE-LIST list."
  (declare (indent 1))
  `
  (let ((temp-message-list (list)))
    (recomplete--with-advice 'message
      :override
      (lambda (&rest args)
        ;; Only check if non-null because this is a signal not to log at all.
        (when message-log-max
          (push (apply #'format-message args) temp-message-list)))
      (unwind-protect
        (progn
          ,@body)
        ;; Protected.
        (setq ,message-list (append ,message-list (reverse temp-message-list)))))))

(defun recomplete--rotate-list-by-elt-and-remove (seq elt)
  "Split SEQ at ELT, removing it, so the elements after it are positioned first."
  (let ((p (seq-position seq elt)))
    (cond
      ((null p)
        (seq-subseq seq 0))
      ((zerop p)
        (seq-subseq seq 1))
      (t
        (append (seq-subseq seq (1+ p)) (seq-subseq seq 0 p))))))

(defun recomplete--rotate-list-by-elt (seq elt)
  "Split SEQ at ELT, so the elements after it are positioned first."
  (let ((p (seq-position seq elt)))
    (cond
      ((null p)
        (seq-subseq seq 0))
      (t
        (setq p (mod (1+ p) (length seq)))
        (append (seq-subseq seq p) (seq-subseq seq 0 p))))))

(defun recomplete--undo-next (list)
  "Get the next undo step in LIST.

Argument LIST compatible list `buffer-undo-list'."
  (while (car list)
    (setq list (cdr list)))
  (while (and list (null (car list)))
    (setq list (cdr list)))
  list)


;; ---------------------------------------------------------------------------
;; Internal Functions/Macros

;; Since this stores undo-data, we only want to keep the information between successive calls.
(defun recomplete--alist-clear-hook ()
  "Clear internal `recomplete' data after running an incompatible function."

  ;; Should always be true, harmless if it's not.
  (cond
    ;; Continue with this chain.
    ((alist-get 'is-first-post-command recomplete--alist)
      (setf (alist-get 'is-first-post-command recomplete--alist) nil))

    ;; Reverse direction.
    ((eq this-command 'keyboard-quit)

      ;; Toggle reverse direction.
      (let ((cycle-reverse (not (alist-get 'cycle-reverse recomplete--alist))))

        ;; Re-display the message.
        (let
          (
            (msg-prefix
              (cond
                (cycle-reverse
                  "<")
                (t
                  ">")))
            (msg-text (alist-get 'msg-text recomplete--alist)))
          (message "%s%s" msg-prefix msg-text))

        (setf (alist-get 'cycle-reverse recomplete--alist) cycle-reverse)))

    ;; Break the chain.
    (t
      (remove-hook 'post-command-hook 'recomplete--alist-clear-hook t)
      (setq recomplete--alist nil))))


;; ---------------------------------------------------------------------------
;; Implementation: ISpell Word

(defun recomplete-impl-ispell (cycle-index fn-cache)
  "Run `ispell-word', using the choice at CYCLE-INDEX.
Argument FN-CACHE stores the result for reuse."
  (pcase-let ((`(,result-choices ,word-beg ,word-end) (or fn-cache '(nil nil nil))))

    (unless result-choices
      (recomplete--with-advice 'ispell-command-loop
        :override
        (lambda (miss _guess _word start end)
          (when miss
            (setq result-choices miss)
            (setq word-beg (marker-position start))
            (setq word-end (marker-position end))
            ;; Return the word would make the correction, we do this ourselves next.
            nil))
        (ispell-word))

      (when result-choices
        (setq fn-cache (list result-choices word-beg word-end))))

    (when result-choices
      (let ((word-at-index (nth (mod cycle-index (length result-choices)) result-choices)))
        (goto-char word-beg)
        (delete-region word-beg word-end)
        (insert word-at-index)))

    (list result-choices fn-cache)))


;; ---------------------------------------------------------------------------
;; Implementation: Case Style Cycle

(defun recomplete-impl-case-style (cycle-index fn-cache)
  "Cycle case styles using the choice at CYCLE-INDEX.
Argument FN-CACHE stores the result for reuse."
  (pcase-let ((`(,result-choices ,word-beg ,word-end) (or fn-cache '(nil nil nil))))

    (unless result-choices
      (let ((word-range (bounds-of-thing-at-point 'symbol)))
        (unless word-range
          (user-error "No symbol under cursor"))
        (setq word-beg (car word-range))
        (setq word-end (cdr word-range)))

      (let*
        (
          (word-init (buffer-substring-no-properties word-beg word-end))
          (word-split
            (mapcar
              'downcase
              (split-string
                (string-trim
                  (replace-regexp-in-string
                    "\\([[:lower:]]\\)\\([[:upper:]]\\)"
                    "\\1_\\2"
                    word-init)
                  "_")
                "[_\\-]"))))

        (push (string-join (mapcar #'capitalize word-split) "") result-choices)

        (cond
          ;; Single word, just add lower-case.
          ((null (cdr word-split))
            (push (car word-split) result-choices))
          ;; Multiple words.
          (t
            (dolist (ch (list ?- ?_))
              (push (string-join word-split (char-to-string ch)) result-choices))))

        ;; Exclude this word from the list of options (if it exists at all).
        (setq result-choices (recomplete--rotate-list-by-elt result-choices word-init))
        (setq fn-cache (list result-choices word-beg word-end))))

    (let ((word-at-index (nth (mod cycle-index (length result-choices)) result-choices)))
      (goto-char word-beg)
      (delete-region word-beg word-end)
      (insert word-at-index))

    (list result-choices fn-cache)))


;; ---------------------------------------------------------------------------
;; Implementation: `dabbrev'

(defun recomplete-impl-dabbrev (cycle-index fn-cache)
  "Cycle case styles using the choice at CYCLE-INDEX.
Argument FN-CACHE stores the result for reuse."
  (pcase-let ((`(,result-choices ,word-beg ,word-end) (or fn-cache '(nil nil nil))))

    ;; Call `dabbrev' when not cached.
    (unless result-choices
      ;; In case this fails entirely.
      (save-excursion
        (save-match-data
          (dabbrev--reset-global-variables)

          (let ((word-init (dabbrev--abbrev-at-point)))
            (setq word-beg
              (progn
                (search-backward word-init)
                (point)))
            (setq word-end
              (progn
                (search-forward word-init)
                (point)))

            (let ((ignore-case-p (dabbrev--ignore-case-p word-init)))
              (setq result-choices (dabbrev--find-all-expansions word-init ignore-case-p)))

            (unless result-choices
              ;; Trim the string since it can contain newlines.
              (user-error "No abbreviations for %S found!" (string-trim word-init)))

            ;; Exclude this word from the list of options (if it exists at all).
            (setq result-choices
              (recomplete--rotate-list-by-elt-and-remove result-choices word-init)))

          (setq fn-cache (list result-choices word-beg word-end)))))

    (let ((word-at-index (nth (mod cycle-index (length result-choices)) result-choices)))
      (goto-char word-beg)
      (delete-region word-beg word-end)
      (insert word-at-index))

    (list result-choices fn-cache)))


;; ---------------------------------------------------------------------------
;; Public Functions

;; Make public since users may want to add their own callbacks.

;;;###autoload
(defun recomplete-with-callback (fn-symbol cycle-offset)
  "Run FN-SYMBOL, chaining executions for any function in FN-GROUP.

Argument CYCLE-OFFSET The offset for cycling words,
1 or -1 for forward/backward."

  ;; Default to 1 (one step forward).
  (setq cycle-offset (or cycle-offset 1))

  ;; While we could support completion without undo,
  ;; it doesn't seem so common to disable undo?
  (when (eq buffer-undo-list t)
    (user-error "(re)complete: undo disabled for this buffer"))

  (let
    ( ;; Initial values if not overwritten by the values in `recomplete--alist'.
      (point-init (point))
      (buffer-undo-list-init buffer-undo-list)
      (pending-undo-list-init pending-undo-list)
      (cycle-index 0)
      (cycle-reverse nil)
      (fn-cache nil)

      (message-list (list)))

    ;; Roll-back and cycle through corrections.
    (let ((alist recomplete--alist))

      ;; Always build a new list on each call, reusing this value
      ;; after any error could cause unpredictable behavior so set this to nil immediately.
      (setq recomplete--alist nil)

      ;; Check for the case of consecutive calls which use incompatible `fn-symbol'.
      ;; This isn't an error, just clear `alist' in this case.
      ;;
      ;; While we could check `this-command', this isn't set properly when called indirectly.
      ;; Simply check if the internal symbol changes.
      (when (and alist (not (eq fn-symbol (alist-get 'fn-symbol alist))))
        (setq alist nil))

      ;; We only need to check if `recomplete--alist' is set here,
      ;; no need to check `last-command' as `recomplete--alist-clear-hook' ensures this variable
      ;; is cleared when the chain is broken.
      (when alist

        ;; Update vars from previous state.
        (setq point-init (alist-get 'point alist))
        (setq buffer-undo-list-init (alist-get 'buffer-undo-list alist))
        (setq pending-undo-list-init (alist-get 'pending-undo-list alist))
        (setq cycle-reverse (alist-get 'cycle-reverse alist))
        (setq fn-cache (alist-get 'fn-cache alist))

        (when cycle-reverse
          (setq cycle-offset (- cycle-offset)))
        (setq cycle-index (+ cycle-offset (cdr (assq 'cycle-index alist))))

        ;; Undo with strict checks so we know _exactly_ whats going on
        ;; and don't allow some unknown state to be entered.
        (let
          ( ;; Skip the 'nil' car of the list.
            (undo-data (cdr buffer-undo-list))
            (undo-data-init (cdr buffer-undo-list-init)))

          ;; Since setting undo-data could corrupt the buffer if there is an unexpected state,
          ;; ensure we have exactly one undo step added, so calling undo returns to a known state.
          ;;
          ;; While this should never happen, prefer an error message over a corrupt buffer.
          (unless (eq undo-data-init (recomplete--undo-next undo-data))
            (user-error "(re)complete: unexpected undo-state before undo, abort!"))

          (let
            ( ;; Roll back the edit, override `this-command' so we have predictable undo behavior.
              ;; Also so setting it doesn't overwrite the current `this-command'
              ;; which is checked above as `last-command'.
              (this-command nil)
              ;; We never want to undo in region (unlikely, set just to be safe).
              (undo-in-region nil)
              ;; The "Undo" message is just noise, don't log it or display it.
              (inhibit-message t)
              (message-log-max nil))

            (undo-only)

            ;; Ensure a single undo step was rolled back, if not,
            ;; early exit as we must _never_ set undo data for an unexpected state.
            (setq undo-data (cdr buffer-undo-list))
            (unless (eq undo-data-init (recomplete--undo-next (recomplete--undo-next undo-data)))
              (user-error "(re)complete: unexpected undo-state after undo, abort!"))))

        ;; Roll back the buffer state, checks above assure us this won't cause any problems.
        (setq buffer-undo-list buffer-undo-list-init)
        (setq pending-undo-list pending-undo-list-init)

        (goto-char point-init)))

    (pcase-let
      (
        (`(,result-choices ,result-fn-cache)
          ;; Store messages, only display failure, as we will typically show a word list.
          ;; Without storing these in a list we get an unsightly flicker.
          (recomplete--with-messages-as-list message-list
            ;; Needed in case the operation does multiple undo pushes.
            (recomplete--with-undo-collapse
              (apply (symbol-function fn-symbol) (list cycle-index fn-cache))))))

      (cond
        ((null result-choices)
          ;; Log the message, since there was failure we might want to know why.
          (dolist (message-text message-list)
            (message "%s" message-text))
          ;; Result, nothing happened!
          nil)

        (t
          ;; Set to wrap around.
          (setq cycle-index (mod cycle-index (length result-choices)))

          (let
            (
              (msg-prefix
                (cond
                  (cycle-reverse
                    "<")
                  (t
                    ">")))

              ;; Notes on formatting output:
              ;; - Use double spaces as a separator even though it uses more room because:
              ;;   - Words may visually run together without this.
              ;;   - Some completions may contain spaces.
              ;; - Formatting ensures text doesn't *move* when the active item changes.
              (msg-text
                (string-join
                  (let ((iter-index 0))
                    (mapcar
                      (lambda (iter-word)
                        (prog1
                          (cond
                            ((eq iter-index cycle-index)
                              (format "[%s]" (propertize iter-word 'face 'match)))
                            (t
                              (format " %s " iter-word)))
                          (setq iter-index (1+ iter-index))))
                      result-choices))
                  "")))

            ;; Single line display.
            (when recomplete-single-line-display
              (with-current-buffer (window-buffer (minibuffer-window))
                (let
                  (
                    (msg-width (string-width msg-text))
                    (display-width (- (window-width (minibuffer-window)) (length msg-prefix))))
                  (when (> msg-width display-width)
                    (let
                      (
                        (msg-start nil)
                        (msg-end nil)
                        (ellipsis "..."))
                      (let*
                        (
                          (word-beg (next-property-change 0 msg-text))
                          (word-end (next-property-change word-beg msg-text)))
                        (setq msg-start
                          (max
                            0
                            (min
                              (- (/ (+ word-beg word-end) 2) (/ display-width 2))
                              (- msg-width display-width))))
                        (setq msg-end (min msg-width (+ msg-start display-width))))

                      (setq msg-text
                        (truncate-string-to-width msg-text msg-end msg-start 0 ellipsis))

                      (unless (zerop msg-start)
                        (setq msg-text
                          (concat ellipsis (substring msg-text (length ellipsis)))))))))
              ;; End single line display.

              ;; Run last so we can ensure it's the last text in the message buffer.
              ;; Don't log because it's not useful to keep the selection.
              (let ((message-log-max nil))
                (message "%s%s" msg-prefix msg-text))

              ;; Set the state for redoing the correction.
              (setq recomplete--alist
                (list
                  (cons 'buffer-undo-list buffer-undo-list-init)
                  (cons 'pending-undo-list pending-undo-list-init)
                  (cons 'point point-init)
                  (cons 'cycle-index cycle-index)
                  (cons 'cycle-reverse cycle-reverse)
                  (cons 'fn-symbol fn-symbol)
                  (cons 'fn-cache result-fn-cache)
                  (cons 'is-first-post-command t)
                  (cons 'msg-text msg-text)))

              ;; Ensure a local hook, which removes it's self on the first non-successive call
              ;; to a command that doesn't execute `recomplete-with-callback' with `fn-symbol'.
              (add-hook 'post-command-hook 'recomplete--alist-clear-hook 0 t)))

          ;; Result, success.
          t)))))

;; ISpell.
;;;###autoload
(defun recomplete-ispell-word (arg)
  "Run `ispell-word', using the first suggestion, or cycle forward.
ARG is the offset to cycle, default is 1, -1 to cycle backwards."
  (interactive "p")
  (recomplete-with-callback 'recomplete-impl-ispell arg))

;; Case Style Cycle.
;;;###autoload
(defun recomplete-case-style (arg)
  "Cycles over common case-styles.
ARG is the offset to cycle, default is 1, -1 to cycle backwards."
  (interactive "p")
  (recomplete-with-callback 'recomplete-impl-case-style arg))

;; Abbreviations.
;;;###autoload
(defun recomplete-dabbrev (arg)
  "Run `dabbrev', using the first suggestion, or cycle forward.
ARG is the offset to cycle, default is 1, -1 to cycle backwards."
  (interactive "p")
  (recomplete-with-callback 'recomplete-impl-dabbrev arg))

(provide 'recomplete)
;;; recomplete.el ends here
