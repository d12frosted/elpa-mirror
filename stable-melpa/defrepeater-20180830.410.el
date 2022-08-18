;;; defrepeater.el --- Easily make commands repeatable  -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Adam Porter

;; Author: Adam Porter <adam@alphapapa.net>
;; URL: http://github.com/alphapapa/defrepeater.el
;; Package-Version: 20180830.410
;; Package-Commit: 9c027a2561fe141dcfb79f75fcaee36cd0386ec1
;; Version: 1.0-pre
;; Package-Requires: ((emacs "25.2") (s "1.12.0"))
;; Keywords: convenience

;;; Commentary:

;; This package lets you easily define "repeating commands," which are commands
;; that can be repeated by repeatedly pressing the last key of the sequence
;; bound to it.

;; For example, let's say that you use "winner-mode", and you have "C-c C-w p"
;; bound to `winner-undo'.  Obviously, pressing that whole sequence repeatedly
;; is tiresome when you want to go several steps back.  But using this macro,
;; you can press "C-c C-w p" once, and then just press "p" to keep repeating
;; `winner-undo', until you press a different key (you could press "C-g" if you
;; needed to stop the repetition so you could press "p" normally).

;; First, define repeating commands:

;;     ;; Automatically defines `winner-redo-repeat' command:
;;     (defrepeater #'winner-redo)

;;     ;; Optionally specify the name of the repeater, like using `defalias':
;;     (defrepeater 'winner-undo-repeat #'winner-undo)

;; Then bind keys to the new commands (example using general.el):

;;     (general-def
;;       [remap winner-redo] #'winner-redo-repeat
;;       [remap winner-undo] #'winner-undo-repeat)

;; For example, "M-SPC w p" was bound to `winner-undo', so now "M-SPC w p p p" can be pressed to
;; call `winner-undo' 3 times.

;; `defrepeater' can also be used directly in a key-binding expression:

;;     (global-set-key (kbd "C-x o") (defrepeater #'other-window))

;;;; Installation

;;;;; MELPA

;; If you installed from MELPA, you're done.

;;;;; Manual

;; Put this file in your load-path, and put this in your init file:

;; (require 'defrepeater)

;;;; Usage

;; Use the `defrepeater' macro as described above.

;;;; Credits

;; This was inspired by this answer by Drew Adams: <https://emacs.stackexchange.com/a/13102>
;; Thanks also to Fox Keister <https://github.com/noctuid> for his feedback.

;;; License:

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

;;; Code:

;;;; Requirements

(require 'repeat)

(require 's)

;;;; Functions

;;;###autoload
(defmacro defrepeater (name-or-command &optional command)
  "Define NAME-OR-COMMAND as an interactive command which calls COMMAND repeatedly.
COMMAND is called every time the last key of the sequence bound
to NAME is pressed, until another key is pressed. If COMMAND is
given, the repeating command is named NAME-OR-COMMAND and calls
COMMAND; otherwise it is named `NAME-OR-COMMAND-repeat' and calls
NAME-OR-COMMAND.

The newly defined function's symbol is returned, so
e.g. `defrepeater' may be used in a key-binding expression."
  (let* ((name (if command
                   ;; `defalias' style
                   (cadr name-or-command)
                 ;; Automatic repeater function name
                 (intern (concat (symbol-name (cadr name-or-command)) "-repeat"))))
         (command (or command name-or-command))
         (docstring (concat (format "Repeatedly call `%s'." (cadr command))
                            "\n\n"
                            (s-word-wrap 80 (format "You may repeatedly press the last key of the sequence bound to this command to repeatedly call `%s'."
                                                    (cadr command))))))
    `(progn
       (when (fboundp ',name)
         (warn "Function is already defined: %s" ',name))
       (defun ,name ()
         ,docstring
         (interactive)
         (let ((repeat-message-function #'ignore))
           (setq last-repeatable-command ,command)
           (repeat nil)))
       ',name)))

;;;; Footer

(provide 'defrepeater)

;;; defrepeater.el ends here
