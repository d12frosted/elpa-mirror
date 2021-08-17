;;; fix-word.el --- Convenient word transformation -*- lexical-binding: t; -*-
;;
;; Copyright © 2015–present Mark Karpov <markkarpov92@gmail.com>
;;
;; Author: Mark Karpov <markkarpov92@gmail.com>
;; URL: https://github.com/mrkkrp/fix-word
;; Package-Version: 20210319.1414
;; Package-Commit: e967dd4ac98d777deeede8b497d6337634c06df4
;; Version: 0.2.0
;; Package-Requires: ((emacs "24.1") (cl-lib "0.5"))
;; Keywords: word, convenience
;;
;; This file is not part of GNU Emacs.
;;
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

;; This is a package that allows us to transform words intelligently.  It
;; provides the function `fix-word' that lifts functions that do string
;; transformation into commands with interesting behavior.  There are also
;; some built-in commands built on top of `fix-word'.

;;; Code:

(require 'cl-lib)

(defgroup fix-word nil
  "Convenient word transformation."
  :group  'convenience
  :tag    "Fix word"
  :prefix "fix-word-"
  :link   '(url-link :tag "GitHub" "https://github.com/mrkkrp/fix-word"))

(defcustom fix-word-bounds-of-thing-function
  #'bounds-of-thing-at-point
  "Function to get the boundaries of a thing at point.

This variable lets you customize the way this package determines
the boundaries of a word."
  :group 'fix-word
  :type  'function)

(defcustom fix-word-thing 'word
  "The default transformation target of fix-word.

This should be a symbol that can be passed as the argument to
`bounds-of-thing-at-point' or its compatible function."
  :group 'fix-word
  :type 'symbol)

;;;###autoload
(defun fix-word (fnc)
  "Lift function FNC into command that operates on words and regions.

The following behaviors are implemented:

If the point is placed outside of a word, apply FNC to the
previous word.  When the command is invoked repeatedly, every its
invocation transforms one more word moving from right to left.
For example (upcasing, ^ shows the position of the point):

  The quick brown fox jumps over the lazy dog.^
  The quick brown fox jumps over the lazy DOG.^
  The quick brown fox jumps over the LAZY DOG.^
  The quick brown fox jumps over THE LAZY DOG.^

The point doesn't move, this allows us to fix recently entered
words and continue typing.

If the point is placed inside a word, the entire word is
transformed.  The point is moved to the first character of the
next word.  This allows us to transform several words by invoking
the command repeatedly.

  ^The quick brown fox jumps over the lazy dog.
  THE ^quick brown fox jumps over the lazy dog.
  THE QUICK ^brown fox jumps over the lazy dog.
  THE QUICK BROWN ^fox jumps over the lazy dog.

If there is an active region, all words in that region are
transformed.

Use `fix-word' to create new commands like this:

\(defalias 'command-name (fix-word #'upcase)
  \"Description of the command.\")

There is also a macro that defines such commands for you:
`fix-word-define-command'."
  (lambda (&optional arg)
    (interactive "p")
    (if (region-active-p)
        (fix-word--fix-region fnc)
      (funcall
       (if (looking-at "\\w+\\>")
           #'fix-word--fix-and-move
         #'fix-word--fix-quickly)
       fnc arg))))

(defun fix-word--fix-region (fnc)
  "Transform the active region with function FNC."
  (let* ((from (point))
         (to   (mark))
         (str  (buffer-substring-no-properties from to)))
    (delete-region from to)
    (insert (funcall fnc str))
    (goto-char from)))

(defun fix-word--fix-and-move (fnc &optional arg)
  "Transform the current word with function FNC and move to the next word.

If the argument ARG is supplied, repeat the operation ARG times."
  (dotimes (_ (or arg 1))
    (fix-word--transform-word fnc)
    (forward-word 2)
    (backward-word)))

(defvar fix-word--quick-fix-times 1
  "How many times `fix-word--fix-quickly' has been invoked consequently.")

(defun fix-word--fix-quickly (fnc &optional arg)
  "Transform the previous word with the function FNC.

If this function is invoked repeatedly, transform more words
moving from right to left.  If the argument ARG is supplied,
repeat the operation ARG times."
  (interactive)
  (let* ((origin (point))
         (i (if (eq last-command this-command)
                (setq fix-word--quick-fix-times
                      (1+ fix-word--quick-fix-times))
              (setq fix-word--quick-fix-times 1))))
    (backward-word i)
    (fix-word--transform-word fnc)
    (when arg
      (dotimes (_ (1- arg))
        (backward-word)
        (fix-word--transform-word fnc))
      (setq fix-word--quick-fix-times
            (+ fix-word--quick-fix-times arg -1)))
    (goto-char origin)))

(defun fix-word--transform-word (fnc)
  "Transform the word at the point with the function FNC."
  (let ((bounds (funcall (or fix-word-bounds-of-thing-function
                             'bounds-of-thing-at-point)
                         (or fix-word-thing 'word))))
    (when bounds
      (cl-destructuring-bind (from . to) bounds
        (let ((origin (point))
              (str    (buffer-substring-no-properties from to)))
          (delete-region from to)
          (insert (funcall fnc str))
          (goto-char origin))))))

;;;###autoload
(defmacro fix-word-define-command (name fnc &optional doc)
  "Define a `fix-word'-based command named NAME.

FNC is the processing function and DOC is the documentation string."
  (declare (indent defun))
  `(defalias ',name (fix-word ,fnc)
     ,(concat (or doc "Name of the command should be self-explanatory.")
"\n\nArgument ARG, if given, specifies how many times to perform the command.
\nThis command is `fix-word'-based. See its description for more information.")))

;; Here are some default commands implemented with `fix-word'.

;;;###autoload
(fix-word-define-command fix-word-upcase #'upcase
  "Upcase words intelligently.")
;;;###autoload
(fix-word-define-command fix-word-downcase #'downcase
  "Downcase words intelligently.")
;;;###autoload
(fix-word-define-command fix-word-capitalize #'capitalize
  "Capitalize words intelligently.")

(provide 'fix-word)

;;; fix-word.el ends here
