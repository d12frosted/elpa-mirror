;;; vertigo.el --- Jump across lines using the home row.

;; Author: Fox Kiester <noct@openmailbox.org>
;; URL: https://github.com/noctuid/vertigo.el
;; Package-Version: 20160323.106
;; Package-Commit: ebfa068d9e2fc39ba6d1744618c4e31dad6f629b
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
  :prefix 'vertigo)

(defcustom vertigo-home-row
  '(?a ?s ?d ?f ?g ?h ?j ?k ?l ?\;)
  "10 chars corresponding to the home row keys."
  :group 'vertigo
  :type '(repeat char))

(defcustom vertigo-cut-off
  3
  "This determines boundary key for whether one or two keys should be input.
For example, with the default value of 3, 39 lines at max can be jumped. The
third key in `vertigo-home-row' will jump 30 something lines (depending on the
second keypress). On the other hand, pressing the fourth key will jump down 4
lines without further user input. Setting this value to 0 will make all keys
immediately jump. Setting it to 10 will make no keys immediately jump."
  :group 'vertigo
  :type 'integer)


(defun vertigo--jump (jump-function prompt)
  "Helper function to be used for jumps in either direction.
JUMP-FUNCTION is the function to be used. PROMPT is the prompt to to display
when asking users to input keys and after the jump."
  (let* ((immediate-jump-chars (-drop vertigo-cut-off vertigo-home-row))
         (delayed-jump-chars (-take vertigo-cut-off vertigo-home-row))
         (first-char (read-char prompt))
         (immediate-index (-elem-index first-char immediate-jump-chars))
         (delayed-index (-elem-index first-char delayed-jump-chars)))
    (if immediate-index
        (funcall jump-function (+ immediate-index vertigo-cut-off 1))
      (when delayed-index
        (let* ((second-char (read-char
                             (concat prompt
                                     (number-to-string (1+ delayed-index)))))
               (final-index (-elem-index second-char vertigo-home-row))
               (jump-lines
                (when final-index
                  (string-to-number
                   (concat (number-to-string (1+ delayed-index))
                           (number-to-string (if (= final-index 9)
                                                 0
                                               (1+ final-index))))))))
          (when jump-lines
            (funcall jump-function jump-lines)
            (message (concat prompt (number-to-string jump-lines) " --"))))))))

;;;###autoload
(defun vertigo-jump-down ()
  "Jump down a number of lines using the home row keys."
  (interactive)
  (vertigo--jump #'forward-line "Jump down: "))

;;;###autoload
(defun vertigo-jump-up ()
  "Jump up a number of lines using the home row keys."
  (interactive)
  (vertigo--jump (lambda (count) (forward-line (- count))) "Jump up: "))

;;;###autoload
(defun vertigo-visible-jump-down ()
  "Jump down a number of visible lines using the home row keys."
  (interactive)
  (vertigo--jump #'forward-visible-line "Jump down: "))

;;;###autoload
(defun vertigo-visible-jump-up ()
  "Jump up a number of visible lines using the home row keys."
  (interactive)
  (vertigo--jump (lambda (count) (forward-visible-line (- count))) "Jump up: "))

;;;###autoload
(defun vertigo-visual-jump-down ()
  "Jump down a number of visual lines using the home row keys."
  (interactive)
  (vertigo--jump #'next-line "Jump down: "))

;;;###autoload
(defun vertigo-visual-jump-up ()
  "Jump up a number of visual lines using the home row keys."
  (interactive)
  (vertigo--jump #'previous-line "Jump up: "))

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
      (vertigo--jump #'vertigo--set-negative-digit-argument "Set digit arg: ")
    (vertigo--jump #'vertigo--set-digit-argument "Set digit arg: ")))

;;;###autoload
(defun vertigo-set-negative-digit-argument (arg)
  "Set a negative digit argument using vertigo keys.
If ARG is non-nil, set a positive count."
  (interactive "P")
  (vertigo-set-digit-argument (not arg)))

(provide 'vertigo)
;;; vertigo.el ends here
