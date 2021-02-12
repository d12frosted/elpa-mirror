This package lets you easily define "repeating commands," which are commands
that can be repeated by repeatedly pressing the last key of the sequence
bound to it.

For example, let's say that you use "winner-mode", and you have "C-c C-w p"
bound to `winner-undo'.  Obviously, pressing that whole sequence repeatedly
is tiresome when you want to go several steps back.  But using this macro,
you can press "C-c C-w p" once, and then just press "p" to keep repeating
`winner-undo', until you press a different key (you could press "C-g" if you
needed to stop the repetition so you could press "p" normally).

First, define repeating commands:

    ;; Automatically defines `winner-redo-repeat' command:
    (defrepeater #'winner-redo)

    ;; Optionally specify the name of the repeater, like using `defalias':
    (defrepeater 'winner-undo-repeat #'winner-undo)

Then bind keys to the new commands (example using general.el):

    (general-def
      [remap winner-redo] #'winner-redo-repeat
      [remap winner-undo] #'winner-undo-repeat)

For example, "M-SPC w p" was bound to `winner-undo', so now "M-SPC w p p p" can be pressed to
call `winner-undo' 3 times.

`defrepeater' can also be used directly in a key-binding expression:

    (global-set-key (kbd "C-x o") (defrepeater #'other-window))

;; Installation

;;; MELPA

If you installed from MELPA, you're done.

;;; Manual

Put this file in your load-path, and put this in your init file:

(require 'defrepeater)

;; Usage

Use the `defrepeater' macro as described above.

;; Credits

This was inspired by this answer by Drew Adams: <https://emacs.stackexchange.com/a/13102>
Thanks also to Fox Keister <https://github.com/noctuid> for his feedback.
