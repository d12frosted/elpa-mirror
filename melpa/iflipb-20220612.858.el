;;; iflipb.el --- Interactively flip between recently visited buffers
;;
;; Copyright (C) 2007-2022 Joel Rosdahl
;;
;; Author: Joel Rosdahl <joel@rosdahl.net>
;; Version: 1.6
;; Package-Version: 20220612.858
;; Package-Commit: 9ec1888335107bd314e8f40b3e113d525fed8083
;; License: BSD-3-clause
;; URL: https://github.com/jrosdahl/iflipb
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;; 3. Neither the name of the author nor the names of its contributors
;;    may be used to endorse or promote products derived from this software
;;    without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
;; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;; DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
;; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
;; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
;; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
;; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;
;; ============================================================================
;;
;;; Commentary:
;;
;; iflipb lets you flip between recently visited buffers in a way that
;; resembles what Alt-(Shift-)TAB does in Microsoft Windows and other graphical
;; window managers.
;;
;; See <https://github.com/jrosdahl/iflipb/blob/master/README.md> for more
;; information and configuration instructions.
;;
;;; Code:

(defgroup :iflipb nil
  "Interactively flip between recently visited buffers."
  :group 'convenience)

(defcustom iflipb-ignore-buffers "^[*]"
  "Which buffers to ignore by default.

This variable determines which buffers to ignore when a prefix
argument has not been given to `iflipb-next-buffer'. The value
should be a regexp string, a function or a list. If the value is
a regexp string, it describes buffer names to exclude from the
buffer list. If the value is a function, the function will get a
buffer name as an argument and should return `nil' if the buffer
should be excluded, otherwise non-`nil'. If the value is a list,
the filter matches if any of the list elements match."
  :type '(choice
          (regexp :tag "Regexp that describes buffer names to exclude")
          (function :tag "Function that takes a buffer name")
          (list (string :tag "Buffer to exclude")))
  :group 'iflipb)

(defcustom iflipb-always-ignore-buffers "^ "
  "Which buffers to always ignore.

This variable determines which buffers to always ignore. The
value should be a regexp string, a function or a list. If the
value is a regexp string, it describes buffer names to exclude
from the buffer list. If the value is a function, the function
will get a buffer name as an argument and should return `nil' if
the buffer should be excluded, otherwise non-`nil'. If the value
is a list, the filter matches if any of the list elements match."
  :type '(choice
          (regexp :tag "Regexp that describes buffer names to exclude")
          (function :tag "Function that takes a buffer name")
          (list (string :tag "Buffer to always exclude")))
  :group 'iflipb)

(defcustom iflipb-wrap-around nil
  "Whether buffer cycling should wrap around edges.

This variable determines whether buffer cycling should wrap
around when an edge is reached in the buffer list."
  :type 'boolean
  :safe #'booleanp
  :group 'iflipb)

(defcustom iflipb-permissive-flip-back nil
  "Whether flipping backward should be allowed as the first command.

This variable determines whether `iflipb-previous-buffer' should
be able to go to the last buffer when it's the first
iflipb-*-buffer command in a row. In other words: Running
`iflipb-previous-buffer' after editing a buffer will act as if
the current buffer was not visited; it will stay in its original
place in the buffer list."
  :type 'boolean
  :safe #'booleanp
  :group 'iflipb)

(defface iflipb-other-buffer-face
  '((t (:inherit default)))
  "Face used for a non-current buffer name."
  :group 'iflipb)

(defface iflipb-current-buffer-face
  '((t (:inherit minibuffer-prompt)))
  "Face used for the current buffer name."
  :group 'iflipb)

(defcustom iflipb-other-buffer-template
  "%s"
  "String template for displaying other buffers.

This template string says how to display a non-current buffer
name. \"%s\" expands to the buffer name. Note: don't enter the
surrounding quotes in the input field."
  :type 'string
  :group 'iflipb)

(defcustom iflipb-current-buffer-template
  "[%s]"
  "String template for displaying the current buffer.

This is the template string that will be applied to the current
buffer name. Use \"%s\" to refer to the buffer name. Note: don't
enter the surrounding quotes in the input field."
  :type 'strings
  :group 'iflipb)

(defcustom iflipb-buffer-list-function
  #'iflipb-buffer-list
  "The function to be used to retrieve the buffer list.

The current options are `iflipb-buffer-list' and
`iflipb-ido-buffer-list'."
  :type 'function
  :group 'iflipb)

(defcustom iflipb-format-buffers-function
  #'iflipb-format-buffers-horizontally
  "The function to be used to format buffers.

This function is used to format buffer names. The function will
get the current buffer and a buffer list as arguments. A return
value is a string to be displayed. Predefined functions are
`iflipb-format-buffers-horizontally' for a horizontal list and
`iflipb-format-buffers-vertically' for a vertical list. See also
`iflipb-format-buffers-height'."
  :type '(choice
          (function-item
           :tag "Horizontally" iflipb-format-buffers-horizontally)
          (function-item
           :tag "Vertically" iflipb-format-buffers-vertically)
          (function :tag "Other function"))
  :group 'iflipb)

(defcustom iflipb-format-buffers-height 5
  "Minibuffer height for displaying buffers when using
`iflipb-format-buffers-vertically'.

The actual height will not exceed the height indicated by
`max-mini-window-height'."
  :type 'integer
  :group 'iflipb)

(defvar iflipb-current-buffer-index 0
  "Index of the currently displayed buffer in the buffer list.")

(defvar iflipb-include-more-buffers nil
  "Whether all buffers should be included while flipping.")

(defvar iflipb-saved-buffers nil
  "Saved buffer list state.

This is the original order of buffers to the left of
`iflipb-current-buffer-index'.")

(defun iflipb-first-n (n list)
  "Return the first N elements of LIST."
  (butlast list (- (length list) n)))

(defun iflipb-filter (pred elements)
  "Return elements from ELEMENTS that satisfy predicate PRED."
  (let ((result nil))
    (while elements
      (let ((elem (car elements))
            (rest (cdr elements)))
        (when (funcall pred elem)
          (setq result (cons elem result)))
        (setq elements rest)))
    (nreverse result)))

(defun iflipb-any (elements)
  "Return non-nil if and only if any element in ELEMENTS is non-nil."
  (iflipb-filter (lambda (x) (not (null x))) elements))

(defun iflipb-match-filter (string filter)
  "Return non-nil if STRING matches FILTER, otherwise nil."
  (cond ((null filter) nil)
        ((functionp filter) (funcall filter string))
        ((listp filter)
         (iflipb-any (mapcar (lambda (f) (iflipb-match-filter string f))
                             filter)))
        ((stringp filter) (string-match filter string))
        (t (error "Bad iflipb ignore filter element: %s" filter))))

(defun iflipb-buffer-list ()
  "Buffer list for iflipb."
  (buffer-list (selected-frame)))

(defun iflipb-ido-buffer-list ()
  "Ido buffer list for iflipb."
  (require 'ido)
  (declare-function ido-make-buffer-list "ido")
  (let* ((ido-process-ignore-lists t)
         ido-ignored-list
         ido-ignore-buffers
         ido-use-virtual-buffers
         (bufs (mapcar 'get-buffer (ido-make-buffer-list nil))))
    (remove nil
            (mapcar (lambda (b) (if (memq b bufs) b))
                    (buffer-list (selected-frame))))))

(defun iflipb-buffers-not-matching-filter (filter)
  "Return a list of buffer names not matching FILTER."
  (iflipb-filter
   (lambda (b) (not (iflipb-match-filter (buffer-name b) filter)))
   (funcall iflipb-buffer-list-function)))

(defun iflipb-interesting-buffers ()
  "Return buffers that will be in the displayed buffer list."
  (iflipb-buffers-not-matching-filter
   (append
    (list iflipb-always-ignore-buffers)
    (if iflipb-include-more-buffers
        nil
      (list iflipb-ignore-buffers)))))

(defun iflipb-first-iflipb-buffer-switch-command ()
  "Determine if this is the first iflipb invocation this round."
  (and (symbolp last-command) ; Could be a lambda
       (not (string-match "^iflipb-" (symbol-name last-command)))))

(defun iflipb-restore-buffers ()
  "Helper function that restores the buffer list to the original state."
  (mapc 'switch-to-buffer (reverse iflipb-saved-buffers)))

(defun iflipb-format-buffer (current-buffer buffer)
  "Format a buffer name for inclusion in the minibuffer buffer list."
  (let* ((type (if (eq current-buffer buffer) "current" "other"))
         (face (intern (format "iflipb-%s-buffer-face" type)))
         (template (intern (format "iflipb-%s-buffer-template" type)))
         (name (concat (buffer-name buffer)))) ; concat to copy the string
    (add-text-properties 0 (length name) `(face ,face) name)
    (format (symbol-value template) name)))

(defun iflipb-format-buffers (current-buffer buffers)
  "Format buffer names for displaying them in the minibuffer."
  (funcall iflipb-format-buffers-function current-buffer buffers))

(defun iflipb-format-buffers-horizontally (current-buffer buffers)
  "Format buffer names for displaying them horizontally."
  (truncate-string-to-width
   (mapconcat
    (lambda (buffer)
      (iflipb-format-buffer current-buffer buffer))
    buffers
    " ")
   (1- (window-width (minibuffer-window)))))

(defun iflipb-format-buffers-vertically (current-buffer buffers)
  "Format buffer names for displaying them vertically."
  (let ((height
         (min iflipb-format-buffers-height
              (cond ((integerp max-mini-window-height)
                     max-mini-window-height)
                    ((floatp max-mini-window-height)
                     (floor (* (frame-height)
                               max-mini-window-height)))
                    (t (error "Invalid value of `max-mini-window-height': %s"
                              max-mini-window-height)))))
        (rest buffers)
        (n 0)
        nrest buffs)
    (while (and rest (or (null nrest) (> nrest 0)))
      (let ((b (car rest)))
        (setq buffs (cons b buffs)
              rest (cdr rest)
              n (1+ n))
        (cond ((eq current-buffer b)
               (setq nrest (- height (min n (ceiling height 2)))))
              ((numberp nrest)
               (setq nrest (1- nrest))))))
    (mapconcat
     (lambda (b) (iflipb-format-buffer current-buffer b))
     (nreverse (iflipb-first-n height buffs))
     "\n")))

(defun iflipb-message (text)
  (let (message-log-max)
    (message "%s" text)))

(defun iflipb-select-buffer (index)
  "Helper function that shows the buffer with a given index."
  (iflipb-restore-buffers)
  (setq iflipb-saved-buffers nil)
  (let* ((buffers (iflipb-interesting-buffers))
         (current-buffer (nth index buffers)))
    (setq iflipb-current-buffer-index index)
    (setq iflipb-saved-buffers (iflipb-first-n index buffers))
    (iflipb-message (iflipb-format-buffers current-buffer buffers))
    (switch-to-buffer current-buffer)))

;;;###autoload
(defun iflipb-next-buffer (arg)
  "Flip to the next buffer in the buffer list.

Consecutive invocations switch to less recent buffers in the
buffer list. Buffers matching `iflipb-always-ignore-buffers' are
always ignored. Without a prefix argument, buffers matching
`iflipb-ignore-buffers' are also ignored."
  (interactive "P")
  (when (iflipb-first-iflipb-buffer-switch-command)
    (setq iflipb-current-buffer-index 0)
    (setq iflipb-saved-buffers nil))
  (if arg
      (setq iflipb-include-more-buffers t)
    (when (iflipb-first-iflipb-buffer-switch-command)
      (setq iflipb-include-more-buffers nil)))
  (let ((buffers (iflipb-interesting-buffers)))
    (if (or (null buffers)
            (and (memq (window-buffer) buffers)
                 (= iflipb-current-buffer-index
                    (1- (length buffers)))))
        (if iflipb-wrap-around
            (iflipb-select-buffer 0)
          (iflipb-message "No more buffers."))
      (iflipb-select-buffer (1+ iflipb-current-buffer-index)))
    (setq last-command 'iflipb-next-buffer)))

;;;###autoload
(defun iflipb-previous-buffer ()
  "Flip to the previous buffer in the buffer list.

Consecutive invocations switch to more recent buffers in the
buffer list."
  (interactive)
  (when (and (not iflipb-permissive-flip-back)
             (iflipb-first-iflipb-buffer-switch-command))
    (setq iflipb-current-buffer-index 0)
    (setq iflipb-saved-buffers nil))
  (if (= iflipb-current-buffer-index 0)
      (if iflipb-wrap-around
          (iflipb-select-buffer (1- (length (iflipb-interesting-buffers))))
        (iflipb-message "You are already looking at the top buffer."))
    (iflipb-select-buffer (1- iflipb-current-buffer-index)))
  (setq last-command 'iflipb-previous-buffer))

;;;###autoload
(defun iflipb-kill-buffer ()
  "Same as `kill-buffer' but keep the iflipb buffer list state."
  (interactive)
  (call-interactively #'kill-buffer)
  (if (iflipb-first-iflipb-buffer-switch-command)
      (setq last-command 'kill-buffer)
    (if (< iflipb-current-buffer-index (length (iflipb-interesting-buffers)))
        (iflipb-select-buffer iflipb-current-buffer-index)
      (iflipb-select-buffer (1- iflipb-current-buffer-index)))
    (setq last-command 'iflipb-kill-buffer)))

(provide 'iflipb)

;;; iflipb.el ends here
