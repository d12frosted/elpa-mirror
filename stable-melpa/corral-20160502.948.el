;;; corral.el --- Quickly surround text with delimiters

;; Copyright (C) 2015 Kevin Liu
;; Author: Kevin Liu <mail@nivekuil.com>
;; Created: 16 May 2015
;; Homepage: http://github.com/nivekuil/corral
;; Version: 0.3.0
;; Package-Version: 20160502.948
;; Package-Commit: e7ab6aa118e46b93d4933d1364bc273f57cd6911

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

;; This package adds commands that allow the user to quickly and intuitively
;; wrap a desired amount of text within delimiters, including parentheses and
;; quotes.  After calling one of the interactive commands, repeated calls will
;; shift the corral instead of inserting new delimiters, expanding the amount
;; of text contained within the delimiters.

;;; Code:

(require 'cl-lib)

(defcustom corral-preserve-point nil
  "Preserve the position of the point instead of following a delimiter."
  :type 'boolean
  :group 'corral)

(defcustom corral-default-no-wrap nil
  "Flag to toggle insertion of open/close character at point (without wrapping).

If this variable is set to t, when inserting using a -forward command, the
opening character is inserted at point instead of wrapping the current balanced
expression (e.g. word) backward.  Conversely, when using a -backward command,
the closing character is inserted at point instead of wrapping the current
balanced expression forward.  This affects only the first corral command, and
not the subsequent repetitions.

The default behavior can be toggled by using the prefix command
\(\\[universal-argument]) before calling a corral-forward/backward function."
  :type 'boolean
  :group 'corral)

(defvar corral-syntax-entries nil
  "Syntax rules to apply when coralling text.

An example usage to have # and * be counted as symbols so that they are wrapped
as words:
\(setq corral-syntax-entries '((?# \"_\")
                               (?* \"_\")))

You can also use `add-to-list', like this:
\(add-to-list 'corral-syntax-entries '(?# \"_\"))")

(defvar corral--virtual-point 0
  "Virtual point position to use for shifting when preserving the real point.")

(defun corral-wrap-backward (open close &optional wrap-toggle)
  "Wrap OPEN and CLOSE delimiters around sexp, leaving point at OPEN.

If WRAP-TOGGLE is passed and evaluates to non-nil, the default behavior
controlled by `corral-default-no-wrap' is toggled:

* If `corral-default-no-wrap' is nil and WRAP-TOGGLE is nil, then CLOSE is
  inserted after the current balanced expression using `forward-sexp'.

* If `corral-default-no-wrap' is nil and WRAP-TOGGLE is non-nil, then CLOSE
  is inserted at point.

* If `corral-default-no-wrap' is non-nil and WRAP-TOGGLE is nil, then CLOSE is
  inserted at point.

* If `corral-default-no-wrap' is non-nil and WRAP-TOGGLE is non-nil, then CLOSE
  is inserted after the current balanced expression using `forward-sexp'."
  (let ((p (point)))
    (when (and (char-after) (char-before) ;Check that trailing chars are non-nil
               (string-match-p "\\w" (char-to-string (char-after)))
               (string-match-p "\\W" (char-to-string (char-before))))
      (forward-char))
    (backward-sexp)
    (save-excursion
      (if (or (and corral-default-no-wrap wrap-toggle)
              (and (not corral-default-no-wrap) (not wrap-toggle)))
          (forward-sexp)
        (goto-char p))
      (insert close))
    (insert open)
    (backward-char)))

(defun corral-wrap-forward (open close &optional wrap-toggle)
  "Wrap OPEN and CLOSE around sexp, leaving point at CLOSE.

If WRAP-TOGGLE is passed and evaluates to non-nil, the default behavior
controlled by `corral-default-no-wrap' is toggled:

* If `corral-default-no-wrap' is nil and WRAP-TOGGLE is nil, then OPEN is
  inserted after the current balanced expression using `backward-sexp'.

* If `corral-default-no-wrap' is nil and WRAP-TOGGLE is non-nil, then OPEN
  is inserted at point.

* If `corral-default-no-wrap' is non-nil and WRAP-TOGGLE is nil, then OPEN is
  inserted at point.

* If `corral-default-no-wrap' is non-nil and WRAP-TOGGLE is non-nil, then OPEN
  is inserted after the current balanced expression using `backward-sexp'."
  (let ((p (point)))
    (when (and (char-after) (char-before) ;Check that trailing chars are non-nil
               (string-match-p "\\w" (char-to-string (char-before)))
               (string-match-p "\\W" (char-to-string (char-after))))
      (forward-char))
    (forward-sexp)
    (save-excursion
      (if (or (and corral-default-no-wrap wrap-toggle)
              (and (not corral-default-no-wrap) (not wrap-toggle)))
          (backward-sexp)
        (goto-char p))
      (insert open))
    (insert close)))

(defun corral-shift-backward (open close)
  "Shift OPEN delimiter backward one sexp.  CLOSE is not moved."
  (cond
   ((eq (char-before) open)
    (backward-char) (corral-shift-backward open close))
   ((eq (char-after) open)
    (save-excursion (backward-sexp))    ; Handle scan error
    (delete-char 1) (backward-sexp) (insert open) (backward-char))
   (t (backward-sexp) (corral-shift-backward open close))))

(defun corral-shift-forward (open close)
  "Without moving OPEN, shift CLOSE delimiter forward one sexp."
  (cond
   ((eq (char-after) close)
    (forward-char) (corral-shift-forward open close))
   ((eq (char-before) close)
    (save-excursion (forward-sexp))     ; Handle scan error
    (delete-char -1) (forward-sexp) (insert close))
   (t (forward-sexp) (corral-shift-forward open close))))

(defun corral-command-backward (open close backward forward
                                     &optional wrap-toggle)
  "Handle command with OPEN and CLOSE from commands BACKWARD and FORWARD.

If WRAP-TOGGLE is passed and evaluates to non-nil, the OPEN character is
inserted at point instead of wrap around the balanced expression at point."
  (save-excursion
    (let ((temp-syntax-table
           (make-syntax-table (syntax-table)))) ;Inherit current syntax table
      ;; Loop through corral syntax entries and apply them temporarily
      (cl-loop for entry in corral-syntax-entries collect
               (apply (lambda (x y)
                        (modify-syntax-entry x y temp-syntax-table)) entry))
      (with-syntax-table temp-syntax-table
        (if (or (eq last-command forward)
                (eq last-command backward))
            (progn (goto-char corral--virtual-point)
                   (corral-shift-backward open close))
          (corral-wrap-backward open close wrap-toggle)))
      (setq corral--virtual-point (point))))
  (unless corral-preserve-point
    (goto-char corral--virtual-point)))

(defun corral-command-forward (open close backward forward
                                    &optional wrap-toggle)
  "Handle command with OPEN and CLOSE from commands BACKWARD and FORWARD.

If WRAP-TOGGLE is passed and evaluates to non-nil, the OPEN character is
inserted at point instead of wrap around the balanced expression at point."
  (save-excursion
    (let ((temp-syntax-table
           (make-syntax-table (syntax-table)))) ;Inherit current syntax table
      ;; Loop through corral syntax entries and apply them temporarily
      (cl-loop for entry in corral-syntax-entries collect
               (apply (lambda (x y)
                        (modify-syntax-entry x y temp-syntax-table)) entry))
      (with-syntax-table temp-syntax-table
        (if (or (eq last-command forward)
                (eq last-command backward))
            (progn (goto-char corral--virtual-point)
                   (corral-shift-forward open close))
          (corral-wrap-forward open close wrap-toggle)))
      (setq corral--virtual-point (point))))
  (unless corral-preserve-point
    (goto-char corral--virtual-point)))

;;;###autoload
(defun corral-parentheses-backward (&optional wrap-toggle)
  "Wrap parentheses around sexp, moving point to the closing parentheses.

WRAP-TOGGLE inverts the behavior of closing parenthesis insertion compared to
the `corral-default-no-wrap' variable."
  (interactive "P")
  (corral-command-backward ?( ?)
                           'corral-parentheses-backward
                           'corral-parentheses-forward
                           wrap-toggle))

;;;###autoload
(defun corral-parentheses-forward (&optional wrap-toggle)
  "Wrap parentheses around sexp, moving point to the closing parentheses.

WRAP-TOGGLE inverts the behavior of opening parenthesis insertion compared to
the `corral-default-no-wrap' variable."
  (interactive "P")
  (corral-command-forward ?( ?)
                          'corral-parentheses-backward
                          'corral-parentheses-forward
                          wrap-toggle))

;;;###autoload
(defun corral-brackets-backward (&optional wrap-toggle)
  "Wrap brackets around sexp, moving point to the opening bracket.

WRAP-TOGGLE inverts the behavior of closing bracket insertion compared to the
`corral-default-no-wrap' variable."
  (interactive "P")
  (corral-command-backward ?[ ?]
                           'corral-brackets-backward
                           'corral-brackets-forward
                           wrap-toggle))

;;;###autoload
(defun corral-brackets-forward (&optional wrap-toggle)
  "Wrap brackets around sexp, moving point to the closing bracket.

WRAP-TOGGLE inverts the behavior of opening bracket insertion compared to the
`corral-default-no-wrap' variable."
  (interactive "P")
  (corral-command-forward ?[ ?]
                          'corral-brackets-backward
                          'corral-brackets-forward
                          wrap-toggle))

;;;###autoload
(defun corral-braces-backward (&optional wrap-toggle)
  "Wrap brackets around sexp, moving point to the opening bracket.

WRAP-TOGGLE inverts the behavior of closing bracket insertion compared to the
`corral-default-no-wrap' variable."
  (interactive "P")
  (corral-command-backward ?{ ?}
                           'corral-braces-backward
                           'corral-braces-forward
                           wrap-toggle))

;;;###autoload
(defun corral-braces-forward (&optional wrap-toggle)
  "Wrap brackets around sexp, moving point to the closing bracket.

WRAP-TOGGLE inverts the behavior of opening bracket insertion compared to the
`corral-default-no-wrap' variable."
  (interactive "P")
  (corral-command-forward ?{ ?}
                          'corral-braces-backward
                          'corral-braces-forward
                          wrap-toggle))

;;;###autoload
(defun corral-single-quotes-backward (&optional wrap-toggle)
  "Wrap single quotes around sexp, moving point to the opening single quote.

WRAP-TOGGLE inverts the behavior of closing quote insertion compared to the
`corral-default-no-wrap' variable."
  (interactive "P")
  (corral-command-backward ?' ?'
                           'corral-single-quotes-backward
                           'corral-single-quotes-forward))

;;;###autoload
(defun corral-single-quotes-forward (&optional wrap-toggle)
  "Wrap single quotes around sexp, moving point to the closing single quote.

WRAP-TOGGLE inverts the behavior of opening quote insertion compared to the
`corral-default-no-wrap' variable."
  (interactive "P")
  (corral-command-forward ?' ?'
                          'corral-single-quotes-backward
                          'corral-single-quotes-forward
                          wrap-toggle))

;;;###autoload
(defun corral-double-quotes-backward (&optional wrap-toggle)
  "Wrap double quotes around sexp, moving point to the opening double quote.

WRAP-TOGGLE inverts the behavior of closing quote insertion compared to the
`corral-default-no-wrap' variable."
  (interactive "P")
  (corral-command-backward ?\" ?\"
                           'corral-double-quotes-backward
                           'corral-double-quotes-forward
                           wrap-toggle))

;;;###autoload
(defun corral-double-quotes-forward (&optional wrap-toggle)
  "Wrap double quotes around sexp, moving point to the closing double quote.

WRAP-TOGGLE inverts the behavior of opening quote insertion compared to the
`corral-default-no-wrap' variable."
  (interactive "P")
  (corral-command-forward ?\" ?\"
                          'corral-double-quotes-backward
                          'corral-double-quotes-forward
                          wrap-toggle))

;;;###autoload
(defun corral-backquote-backward (&optional wrap-toggle)
  "Wrap double quotes around sexp, moving point to the opening double quote.

WRAP-TOGGLE inverts the behavior of closing quote insertion compared to the
`corral-default-no-wrap' variable."
  (interactive "P")
  (corral-command-backward ?\` ?\`
                           'corral-backquote-backward
                           'corral-backquote-forward
                           wrap-toggle))

;;;###autoload
(defun corral-backquote-forward (&optional wrap-toggle)
  "Wrap double quotes around sexp, moving point to the closing double quote.

WRAP-TOGGLE inverts the behavior of opening quote insertion compared to the
`corral-default-no-wrap' variable."
  (interactive "P")
  (corral-command-forward ?\` ?`
                          'corral-backquote-backward
                          'corral-backquote-forward
                          wrap-toggle))
(provide 'corral)

;;; corral.el ends here
