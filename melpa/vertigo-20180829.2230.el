;;; vertigo.el --- Jump across lines using the home row.

;; Author: Fox Kiester <noct@posteo.net>
;; URL: https://github.com/noctuid/vertigo.el
;; Package-Version: 20180829.2230
;; Package-Commit: 6303d17270ea92290a6960890bca515274f1682b
;; Created: September 18, 2015
;; Keywords: vim, vertigo
;; Package-Requires: ((dash "2.11.0"))
;; Version: 1.0

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This package is a port of the vim-vertigo plugin and gives commands that
;; allow the user to jump up or down a number of lines using the home row.
;; It will primarily be useful when relative line numbers are being used. To
;; jump down seven lines, for example, the user can press a key bound to
;; `vertigo-jump-down' and then press "j" since it is the seventh letter on the
;; home row. `vertigo-home-row' can be altered for non-QWERTY users. Since it is
;; unlikely that the user will want to use these commands to jump down one or
;; two lines, `vertigo-cut-off' can be set to determine that the first n keys
;; should accept another key afterwards. For example, if `vertigo-cut-off' is
;; set to its default value of 3, pressing "da" would jump 31 lines, pressing
;; "d;" would jump 30 lines, and pressing "f" would jump 4 lines.

;; A good alternative to this package is to use avy's `avy-goto-line'.

;; Additionally, vertigo provides commands to set the digit argument using the
;; same style of keypresses.

;; For more information see the README in the github repo.

;;; Code:
(require 'dash)

(defgroup vertigo nil
  "Gives commands for moving by lines using the home row."
  :group 'convenience
  :prefix "vertigo-")

(defcustom vertigo-home-row
  '(?a ?s ?d ?f ?g ?h ?j ?k ?l ?\;)
  "10 chars corresponding to the home row keys (or the numbers 1-9 and 0)."
  :group 'vertigo
  :type '(repeat char))

(defcustom vertigo-cut-off 3
  "This determines boundary key for whether one or two keys should be input.
For example, with the default value of 3, 39 lines at max can be jumped. The
third key in `vertigo-home-row' will jump 30 something lines (depending on the
second keypress). On the other hand, pressing the fourth key will jump down 4
lines without further user input. Setting this value to 0 will make all keys
immediately jump. Setting it to 10 will make no keys immediately jump. Note that
this variable only has an effect when `vertigo-max-digits' is 2. Regardless of
the value of these variables, inputting an uppercase letter will immediately
end the number (e.g. by default, inputting \"A\" corresponds to 1)."
  :type 'integer)

(defcustom vertigo-max-digits 2
  "The max number of digits that can be specified with vertigo commands.
The default value is 2, meaning that the max number that can be specified is
99."
  :type 'integer)

(defun vertigo--lower-p (char)
  "Return whether CHAR is lowercase."
  (= char (downcase char)))

(cl-defun vertigo--run (function prompt &optional no-message)
  "Call FUNCTION with a count determined by user-input characters.
PROMPT is the prompt to display when asking users to input keys and calling FUNCTION. When
NO-MESSAGE is non-nil, don't message with the prompt and chosen number
afterward calling FUNCTION."
  (let ((num-digits 1)
        (immediate-end-chars (-drop vertigo-cut-off vertigo-home-row))
        current-num-str)
    (while (let* ((char (read-char (concat prompt current-num-str)))
                  (index (or (-elem-index (downcase char) vertigo-home-row)
                             (cl-return-from vertigo--run 0)))
                  (num (if (= index 9)
                           0
                         (1+ index)))
                  (endp (or (= num-digits vertigo-max-digits)
                            (not (vertigo--lower-p char))
                            (and (= vertigo-max-digits 2)
                                 (memq (downcase char) immediate-end-chars)))))
             (cl-incf num-digits)
             (setq current-num-str (concat current-num-str (number-to-string num)))
             (not endp)))
    (let ((final-num (string-to-number current-num-str)))
      (funcall function final-num)
      (unless no-message
        (message (concat prompt current-num-str " --")))
      final-num)))

;;;###autoload
(defun vertigo-jump-down ()
  "Jump down a number of lines using the home row keys."
  (interactive)
  (vertigo--run #'forward-line "Jump down: "))

;;;###autoload
(defun vertigo-jump-up ()
  "Jump up a number of lines using the home row keys."
  (interactive)
  (vertigo--run (lambda (count) (forward-line (- count))) "Jump up: "))

;;;###autoload
(defun vertigo-visible-jump-down ()
  "Jump down a number of visible lines using the home row keys."
  (interactive)
  (vertigo--run #'forward-visible-line "Jump down: "))

;;;###autoload
(defun vertigo-visible-jump-up ()
  "Jump up a number of visible lines using the home row keys."
  (interactive)
  (vertigo--run (lambda (count) (forward-visible-line (- count))) "Jump up: "))

;;;###autoload
(defun vertigo-visual-jump-down ()
  "Jump down a number of visual lines using the home row keys."
  (interactive)
  (vertigo--run #'next-line "Jump down: "))

;;;###autoload
(defun vertigo-visual-jump-up ()
  "Jump up a number of visual lines using the home row keys."
  (interactive)
  (vertigo--run #'previous-line "Jump up: "))

(defun vertigo--set-digit-argument (num)
  "A simpler version of `set-digit-argument'; set `prefix-arg' to NUM."
  (setq prefix-arg num))

(defun vertigo--set-negative-digit-argument (num)
  "Set `prefix-arg' to negative NUM."
  (setq prefix-arg (- num)))

;;;###autoload
(defun vertigo-set-digit-argument (arg)
  "Set a positive digit argument using vertigo keys.
If ARG is non-nil, set a negative count."
  (interactive "P")
  (if arg
      (vertigo--run #'vertigo--set-negative-digit-argument "Set digit arg: ")
    (vertigo--run #'vertigo--set-digit-argument "Set digit arg: ")))

;;;###autoload
(defun vertigo-run-command-with-digit-argument (command-keys)
  "Like `vertigo-set-digit-argument', but the command is chosen first.
After keys have been pressed that correspond to a command, vertigo will prompt
to set the digit argument for that command and then run it."
  (interactive "k")
  ;; this will ensure the prompt is displayed
  (message "")
  (let ((times (number-to-string (vertigo--run #'vertigo--set-digit-argument
                                               "Set digit arg: "
                                               t))))
    (setq unread-command-events (listify-key-sequence command-keys))
    ;; this will be clobbered
    (message (concat command-keys " " times))))

;;;###autoload
(defun vertigo-alt-run-command-with-digit-argument (command-keys)
  "Like `vertigo-run-command-with-digit-agument' but properly messages.
A message showing the command and the prefix arg will be displayed in the
echo area afterwards. M-[0-9] must be mapped to `digit-argument' for this
command to work correctly."
  (interactive "k")
  (message "")
  (let ((times (number-to-string
                (vertigo--run (lambda (_)) "Set digit arg: " t))))
    (execute-kbd-macro (kbd (concat "M-" times " " command-keys)))
    (message (concat command-keys " " times))))

;;;###autoload
(defun vertigo-set-negative-digit-argument (arg)
  "Set a negative digit argument using vertigo keys.
If ARG is non-nil, set a positive count."
  (interactive "P")
  (vertigo-set-digit-argument (not arg)))

(provide 'vertigo)
;;; vertigo.el ends here
