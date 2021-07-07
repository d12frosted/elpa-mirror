;;; numbers.el --- Display information and trivia about numbers -*- lexical-binding: t -*-
;; Copyright 2017 by Dave Pearson <davep@davep.org>

;; Author: Dave Pearson <davep@davep.org>
;; Version: 1.4
;; Package-Version: 20170802.1134
;; Package-Commit: dd02508b788a13b7d4dbcc4923fa23134b783ab3
;; Keywords: games, trivia, maths, numbers
;; URL: https://github.com/davep/numbers.el
;; Package-Requires: ((emacs "24"))

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; numbers.el is a little wrapper around http://numbersapi.com/ that can be
;; used to display maths information and trivia about numbers.
;;
;; Two main commands are provided:
;;
;; `numbers-math' - Shows/inserts a maths-related fact about a number.
;;
;; `numbers-trivia' - Shows/inserts some trivia about a number.
;;
;; In both cases calling the command will prompt for a number. If there
;; appears to be a number in the current buffer, near the current point,
;; that number will be used as the default.
;;
;; If `universal-argument' is invoked first the result will be inserted into
;; the current buffer, otherwise it is displayed in the message area. On the
;; other hand, if number is provided as the prefix argument it is looked up
;; and the result is displayed.
;;
;; In addition, a couple of commands are provided for getting facts and
;; trivia about a random number:
;;
;; `numbers-random-math' - Shows/inserts a maths-related fact about a random
;; number.
;;
;; `numbers-random-trivia' - Shows/inserts some trivia about a random
;; number.

;;; Code:

(require 'url-vars)
(require 'thingatpt)

(defconst numbers-math-api-url "http://numbersapi.com/%d/math"
  "URL for getting maths information about a number.")

(defconst numbers-trivia-api-url "http://numbersapi.com/%d"
  "URL for getting trivia about a number.")

(defconst numbers-random-math-api-url "http://numbersapi.com/random/math"
  "URL for getting maths information about a random number.")

(defconst numbers-random-trivia-api-url "http://numbersapi.com/random/trivia"
  "URL for getting trivia about a random number.")

(defconst numbers-user-agent "numbers.el"
  "User agent to send when requesting number information.")

(defun numbers-get (url &optional number)
  "Visit URL getting information, optionally about NUMBER."
  (let* ((url-request-extra-headers `(("User-Agent" . ,numbers-user-agent)))
         (buffer (url-retrieve-synchronously (if number (format url number) url) t t)))
    (when buffer
      (with-current-buffer buffer
        (set-buffer-multibyte t)
        (setf (point) (point-min))
        (when (search-forward-regexp "^$" nil t)
          (buffer-substring (1+ (point)) (point-max)))))))

(defun numbers-get-math (number)
  "Get some maths information about NUMBER."
  (numbers-get numbers-math-api-url number))

(defun numbers-get-math-random ()
  "Get some maths information about a random number."
  (numbers-get numbers-random-math-api-url))

(defun numbers-get-trivia (number)
  "Get some trivia about NUMBER."
  (numbers-get numbers-trivia-api-url number))

(defun numbers-get-trivia-random ()
  "Get trivia about a random number."
  (numbers-get numbers-random-trivia-api-url))

(defun numbers-reader ()
  "Get a number finding arguments from the user.

The return value is a list of the form:

  (number insert)

If `current-prefix-arg' tests as `numberp' the number is taken to
be its value, and insert will be nil.

If `current-prefix-arg' doesn't test as `numberp' then the user
will be prompted for a number (using any number `thing-at-point'
could find at `point' as the default) and number will be what
they input. insert will then be the value of
`current-prefix-arg'."
  (if (numberp current-prefix-arg)
      (list current-prefix-arg nil)
    (list
     (read-number "Number: " (thing-at-point 'number))
     current-prefix-arg)))

(defun numbers-reveal (getter fail-message insert)
  "Use GETTER to find and reveal something about a number.

If the get fails, reveal FAIL-MESSAGE.

If INSERT is non-nil use `insert' to reveal the finding,
otherwise use `message'."
  (let ((finding (or (funcall getter) fail-message)))
    (if insert
        (insert finding)
      (message "%s" finding))))

(defun numbers-reveal-number (getter number insert)
  "Use GETTER to find and reveal something about NUMBER.

If INSERT is non-nil use `insert' to reveal the finding,
otherwise use `message'."
  (numbers-reveal
   (lambda () (funcall getter number))
   (format "Unable to get anything for %d." number)
   insert))

(defun numbers-reveal-random (getter description insert)
  "Use GETTER to find and reveal something about a random number.

DESCRIPTION will be used to compose a failure message.

If INSERT is non-nil use `insert' to reveal the finding,
otherwise use `message'."
  (numbers-reveal getter (format "Unable to get %s" description) insert))

;;;###autoload
(defun numbers-math (number &optional insert)
  "Display some maths information about NUMBER.

If INSERT is non-nil `insert' the information rather than display
it."
  (interactive (numbers-reader))
  (numbers-reveal-number #'numbers-get-math number insert))

;;;###autoload
(defun numbers-trivia (number &optional insert)
  "Display some trivia about NUMBER.

If INSERT is non-nil `insert' the information rather than display
it."
  (interactive (numbers-reader))
  (numbers-reveal-number #'numbers-get-trivia number insert))

;;;###autoload
(defun numbers-random-math (&optional insert)
  "Display or insert a maths fact about a random number.

The fact is displayed in the message area, or inserted at `point'
if INSERT is non-nil."
  (interactive "P")
  (numbers-reveal-random #'numbers-get-math-random "a random maths fact" insert))

;;;###autoload
(defun numbers-random-trivia (&optional insert)
  "Display or insert some trivia about a random number.

The trivia is displayed in the message area, or inserted at
`point' if INSERT is non-nil."
  (interactive "P")
  (numbers-reveal-random #'numbers-get-trivia-random "some random number trivia" insert))

;;;###autoload
(defun numbers-random (&optional insert)
  "Display a maths fact or some trivia about a random number.

When called this command randomly calls `numbers-random-math' or
`numbers-random-trivia'."
  (interactive "P")
  (funcall (if (zerop (random 2)) #'numbers-random-math #'numbers-random-trivia) insert))

(provide 'numbers)

;;; numbers.el ends here
