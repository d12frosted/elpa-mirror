;;; fortune-cookie.el --- Print a fortune in your scratch buffer.

;; Copyright (C) 2015 Andrew Schwartzmeyer

;; Author: Andrew Schwartzmeyer <andrew@schwartzmeyer.com>
;; Created: 09 Nov 2015
;; Version: 1.0
;; Package-Version: 20181223.842
;; Package-Commit: 6c1c08f5be83822c0b762872ab25e3dbee96f333
;; Package-Requires: ()
;; Keywords: fortune cowsay scratch startup
;; Homepage: https://github.com/andschwa/fortune-cookie

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This sets `initial-scratch-message' with an `emacs-lisp-mode'
;; commented output of a call to `fortune'.
;;
;; See README.md

;;; Code:

(require 'files)
(require 'simple)

(defgroup fortune-cookie nil
  "Print a fortune in your scratch buffer."
  :prefix "fortune-cookie-"
  :group 'scratch)

(defcustom fortune-cookie-fortune-command (executable-find "fortune")
  "Path to `fortune' command.

Defaults to the first on your path."
  :type 'string
  :group 'fortune-cookie)

(defcustom fortune-cookie-fortune-args nil
  "Arguments passed to `fortune'."
  :type '(repeat string)
  :group 'fortune-cookie)

(defcustom fortune-cookie-cowsay-enable nil
  "Pipes `fortune' through `cowsay' if true."
  :type 'boolean
  :group 'fortune-cookie)

(defcustom fortune-cookie-cowsay-command (executable-find "cowsay")
  "Path to `cowsay' command.

Defaults to the first on your path."
  :type 'string
  :group 'fortune-cookie)

(defcustom fortune-cookie-cowsay-args nil
  "Arguments passed to `cowsay'."
  :type '(repeat string)
  :group 'fortune-cookie)

(defcustom fortune-cookie-comment-start ";; "
  "String prepended to each line of fortune.

The default assumes `emacs-lisp-mode'."
  :type 'string
  :group 'fortune-cookie)

(defcustom fortune-cookie-fortune-string nil
  "String to use for fortune instead of calling the program."
  :type 'string
  :group 'fortune-cookie)

;;;###autoload
(defun fortune-cookie ()
  "Get a fortune cookie (maybe with cowsay)."
  (interactive)
  (or fortune-cookie-fortune-string
      fortune-cookie-fortune-command
      (display-warning 'fortune-cookie "`fortune' program was not found" :error))
  (when (and fortune-cookie-cowsay-enable
             (not fortune-cookie-cowsay-command))
    (display-warning
     'fortune-cookie
     "`cowsay' program was not found; disable this warning by"
     "setting `fortune-cookie-cowsay-enable' to nil"))
  (or fortune-cookie-cowsay-enable)
  (let ((fortune (or fortune-cookie-fortune-string
                     (shell-command-to-string
                      (combine-and-quote-strings
                       (append (list fortune-cookie-fortune-command)
                               fortune-cookie-fortune-args))))))
    (if (and fortune-cookie-cowsay-enable
             fortune-cookie-cowsay-command)
        (fortune-cowsay fortune t) fortune)))

(defun fortune-cowsay (str &optional skip-kill)
  "Return STR wrapped in cowsay. If SKIP-KILL, do not add to kill ring."
  (interactive "MWhat do you want to say? \nP")
  (unless fortune-cookie-cowsay-command
    (display-warning 'fortune-cookie "`cowsay' program was not found" :error))
  (let ((cow (shell-command-to-string
              (message (combine-and-quote-strings
                        (append (list "echo" str "|"
                                      fortune-cookie-cowsay-command)
                                fortune-cookie-cowsay-args))))))
    (unless skip-kill (kill-new cow)) (message "Copied cow to kill ring") cow))

;;;###autoload
(defun fortune-cookie-comment (arg prefix)
  "Comment ARG with PREFIX.

ARG is the input string.
PREFIX is prepended to each line of ARG."
  (interactive)
  (mapconcat
   (lambda (x) (concat prefix x))
   (split-string arg "\n" t) "\n"))

;;;###autoload
(define-minor-mode fortune-cookie-mode
  "Set `initial-scratch-message' to a commented fortune cookie."
  :global
  :group 'fortune-cookie
  (setq initial-scratch-message
	(concat (fortune-cookie-comment (fortune-cookie) fortune-cookie-comment-start) "\n\n")))

(provide 'fortune-cookie)

;;; fortune-cookie.el ends here
