;;; mwim.el --- Switch between the beginning/end of line or code  -*- lexical-binding: t -*-

;; Copyright © 2015, 2016, 2018 Alex Kost

;; Author: Alex Kost <alezost@gmail.com>
;; Created: 9 Jan 2015
;; Version: 0.4
;; Package-Version: 20181110.1900
;; Package-Commit: b4f3edb4c0fb8f8b71cecbf8095c2c25a8ffbf85
;; URL: https://github.com/alezost/mwim.el
;; Keywords: convenience

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; MWIM stands for "Move Where I Mean".  This package is inspired by
;; <http://www.emacswiki.org/emacs/BackToIndentationOrBeginning>.  It
;; provides commands to switch between various positions on the current
;; line (particularly, to move to the beginning/end of code, line or
;; comment).

;; To install the package manually, add the following to your init file:
;;
;;   (add-to-list 'load-path "/path/to/mwim-dir")
;;   (autoload 'mwim "mwim" nil t)
;;   (autoload 'mwim-beginning "mwim" nil t)
;;   (autoload 'mwim-end "mwim" nil t)
;;   (autoload 'mwim-beginning-of-code-or-line "mwim" nil t)
;;   (autoload 'mwim-beginning-of-line-or-code "mwim" nil t)
;;   (autoload 'mwim-beginning-of-code-or-line-or-comment "mwim" nil t)
;;   (autoload 'mwim-end-of-code-or-line "mwim" nil t)
;;   (autoload 'mwim-end-of-line-or-code "mwim" nil t)

;; Then you can bind some keys to some of those commands and start
;; moving.  See README in the source repo for more details.

;;; Code:

(defgroup mwim nil
  "Move Where I Mean.
Move the point to various line positions."
  :group 'convenience)

(defcustom mwim-beginning-of-line-function
  '((t . beginning-of-line)
    (message-mode . message-beginning-of-line)
    (org-mode . org-beginning-of-line))
  "Function(s) used to move the point to the beginning of line.
Can either be a function or an alist of the following form:

  ((MODE-NAME . FUNCTION) ...)

where MODE-NAME is either a `major-mode' name or `t' (used as a
default value for any unspecified mode), and FUNCTION is the
moving function for this mode."
  :type '(choice (function-item beginning-of-visual-line)
                 (function-item beginning-of-line)
                 (alist :key-type symbol :value-type function)
                 (function :tag "Another function"))
  :group 'mwim)

(defcustom mwim-end-of-line-function
  '((t . end-of-line)
    (org-mode . org-end-of-line))
  "Function(s) used to move the point to the end of line.
See also `mwim-beginning-of-line-function'."
  :type '(choice (function-item end-of-visual-line)
                 (function-item end-of-line)
                 (alist :key-type symbol :value-type function)
                 (function :tag "Another function"))
  :group 'mwim)

(defcustom mwim-next-position-function nil
  "Function used to define the next position.

This function is called with a list of functions returning
available point positions as a single argument.  It should return
the next position where the point will be moved.

There are 2 functions to choose from: `mwim-next-position' and
`mwim-next-unique-position'.

`mwim-next-position' is faster as it calculates positions only
when needed, however there are some special cases when this
function will not return an expected position (when there are
more than 3 potential positions, and some of them are the same).

With `mwim-next-unique-position' you will always switch between
all available positions, but it is slower as it calculates all
positions at once.  Most likely, however, this slowness will be
insignificant as the number of potential positions is not big.

If this variable is nil, an appropriate function will be chosen
automatically.  This is the recommended value, as it provides the
speed when possible, and guaranteed cycling between all positions
for complex cases."
  :type '(choice (const nil :tag "Choose automatically")
                 (function-item mwim-next-position)
                 (function-item mwim-next-unique-position)
                 (function :tag "Another function"))
  :group 'mwim)

(defcustom mwim-beginning-position-functions
  '(mwim-block-beginning
    mwim-code-beginning
    mwim-line-beginning
    mwim-comment-beginning)
  "List of functions used by `\\[mwim-beginning]' command."
  :type '(repeat function)
  :group 'mwim)

(defcustom mwim-end-position-functions
  '(mwim-block-end
    mwim-code-end
    mwim-line-end)
  "List of functions used by `\\[mwim-end]' command."
  :type '(repeat function)
  :group 'mwim)

(defcustom mwim-position-functions
  '(mwim-line-beginning
    mwim-code-beginning
    mwim-comment-beginning
    mwim-code-end
    mwim-line-end)
  "List of functions used by `\\[mwim]' command."
  :type '(repeat function)
  :group 'mwim)

(defun mwim-function (fun-or-alist)
  "Return function depending on FUN-OR-ALIST and the current `major-mode'.
FUN-OR-ALIST should have the same form as
`mwim-beginning-of-line-function' variable."
  (cond
   ((functionp fun-or-alist)
    fun-or-alist)
   ((listp fun-or-alist)
    (or (cdr (assq major-mode fun-or-alist))
        (cdr (assq t fun-or-alist))))))


;;; Calculating positions

(defmacro mwim-point-at (&rest body)
  "Return point position after evaluating BODY in `save-excursion'."
  (declare (debug t) (indent 0))
  `(save-excursion ,@body (point)))

(defun mwim-first-position (functions &optional position)
  "Return the first point position that is not POSITION from
positions defined after calling FUNCTIONS.

If POSITION is nil, use the current point position.

Initially, the first function is called (without arguments).  If
the resulting position is not the same as POSITION, return it.
Otherwise, call the second function, etc.

If after calling all FUNCTIONS, all resulting positions are
the same as POSITION, return nil."
  (or position (setq position (point)))
  (pcase functions
    (`(,first . ,rest)
     (let ((pos (funcall first)))
       (if (and pos (/= pos position))
           pos
         (mwim-first-position rest position))))))

(defun mwim-next-position (functions &optional position fallback-position)
  "Return the next point position after POSITION from positions
defined after calling FUNCTIONS.

If POSITION is nil, use the current point position.

Initially, the first function is called (without arguments).  If
the resulting position is the same as POSITION, return position
defined after calling the second function.  If it is not the
same, compare the second position with POSITION, etc.

If after calling all FUNCTIONS, POSITION is not one of the
found positions, return FALLBACK-POSITION.  If it is nil, return
the first position."
  (or position (setq position (point)))
  (if (null functions)
      fallback-position
    (pcase functions
      (`(,first . ,rest)
       ;; If the last function is reached, there is no point to call it,
       ;; as the point should be moved to the first position anyway.
       (if (and (null rest) fallback-position)
           fallback-position
         (let ((pos (funcall first)))
           (if (and pos (= pos position))
               (or (mwim-first-position rest position)
                   fallback-position
                   pos)
             (mwim-next-position rest position
                                 (or fallback-position pos)))))))))

(defun mwim-delq-dups (list)
  "Like `delete-dups' but using `eq'."
  (let ((tail list))
    (while tail
      (setcdr tail (delq (car tail) (cdr tail)))
      (setq tail (cdr tail))))
  list)

(defun mwim-next-unique-position (functions &optional position
                                            sort-predicate)
  "Return the next point position after POSITION from positions
defined after calling FUNCTIONS.

If POSITION is nil, use the current point position.

Initially, all positions are calculated (all functions are
called).  If POSITION is the same as one of the resulting
positions, return the next one, otherwise return the first
position.

If SORT-PREDICATE is non-nil, it should be a function taken by
`sort'.  It is used to sort available positions, so most likely
you want to use either `<' or `>' for SORT-PREDICATE."
  (or position (setq position (point)))
  (let* ((positions (mwim-delq-dups
                     (delq nil (mapcar #'funcall functions))))
         (positions (if sort-predicate
                        (sort positions sort-predicate)
                      positions))
         (next-positions (cdr (memq position positions))))
    (car (or next-positions positions))))

(defun mwim-move-to-next-position (functions &optional sort-predicate)
  "Move point to position returned by the first function.
If the point is already there, move to the position returned by
the second function, etc.

FUNCTIONS are called without arguments and should return either a
number (point position) or nil (if this position should be
skipped).

If SORT-PREDICATE is non-nil, `mwim-next-unique-position' is
called with it."
  (let ((pos (if sort-predicate
                 (mwim-next-unique-position functions (point)
                                            sort-predicate)
               (funcall (or mwim-next-position-function
                            (if (> (length functions) 3)
                                #'mwim-next-unique-position
                              #'mwim-next-position))
                        functions))))
    (when pos (goto-char pos))))

;; This macro is not really needed, it is an artifact from the past.  It
;; is left in case some people use it to define their commands.
(defmacro mwim-goto-next-position (&rest expressions)
  "Wrapper for `mwim-move-to-next-position'."
  (declare (indent 0))
  `(mwim-move-to-next-position
    (list ,@(mapcar (lambda (exp) `(lambda () ,exp))
                    expressions))))


;;; Position functions

(defun mwim-current-comment-beginning ()
  "Return position of the beginning of the current comment.
Return nil, if not inside a comment."
  (let ((syn (syntax-ppss)))
    (and (nth 4 syn)
         (nth 8 syn))))

(defun mwim-line-comment-beginning ()
  "Return position of the beginning of comment on the current line.
Return nil, if there is no comment beginning on the current line."
  (let ((beg (save-excursion
               (end-of-line)
               (or (mwim-current-comment-beginning)
                   ;; There may be a marginal block comment, see
                   ;; <https://github.com/alezost/mwim.el/issues/3>.
                   (progn
                     (skip-chars-backward " \t")
                     (backward-char)
                     (mwim-current-comment-beginning))))))
    (and beg
         (<= (line-beginning-position) beg)
         beg)))

(defun mwim-line-comment-text-beginning ()
  "Return position of a comment start on the current line.
Comment start means beginning of the text inside the comment.
Return nil, if there is no comment beginning on the current line."
  ;; If `comment-start-skip' is not set by a major mode (this is the
  ;; case for `sql-mode', for example), then `comment-search-forward'
  ;; errors, so check that `comment-start-skip' is not nil.
  (when comment-start-skip
    (save-excursion
      (goto-char (line-beginning-position))
      (let ((beg (comment-search-forward (line-end-position) t)))
        (when beg (point))))))

(defalias 'mwim-comment-beginning #'mwim-line-comment-text-beginning)

(defun mwim-line-beginning ()
  "Return position in the beginning of line.
Use `mwim-beginning-of-line-function'."
  (mwim-point-at (mwim-beginning-of-line)))

(defun mwim-code-beginning ()
  "Return position in the beginning of code."
  (mwim-point-at (mwim-beginning-of-code)))

(defun mwim-line-end ()
  "Return position in the end of line.
Use `mwim-end-of-line-function'."
  (mwim-point-at (mwim-end-of-line)))

(defun mwim-code-end ()
  "Return position in the end of code."
  (mwim-point-at (mwim-end-of-code)))

(defun mwim-block-beginning ()
  "Return position in the beginning of code or comment.
If the point is inside a comment, return beginning position of
the current comment, otherwise - of the code."
  (if (mwim-current-comment-beginning)
      (mwim-comment-beginning)
    (mwim-code-beginning)))

(defun mwim-block-end ()
  "Return position in the end of code or line.
If the point is inside a comment, return end position of
the current comment, otherwise - of the code."
  (if (mwim-current-comment-beginning)
      (mwim-line-end)
    (mwim-code-end)))


;;; Moving commands

(defun mwim-beginning-of-comment ()
  "Move point to the beginning of comment on the current line.
If the comment does not exist, do nothing."
  (interactive "^")
  (let ((comment-beg (mwim-line-comment-beginning)))
    (when comment-beg
      (goto-char comment-beg))))

(defun mwim-beginning-of-line ()
  "Move point to the beginning of line.
Use `mwim-beginning-of-line-function'."
  (interactive "^")
  (funcall (or (mwim-function mwim-beginning-of-line-function)
               #'beginning-of-line)))

(defun mwim-end-of-line ()
  "Move point to the end of line.
Use `mwim-end-of-line-function'."
  (interactive "^")
  (funcall (or (mwim-function mwim-end-of-line-function)
               #'end-of-line)))

(defun mwim-beginning-of-code ()
  "Move point to the first non-whitespace character on the current line."
  (interactive "^")
  (mwim-beginning-of-line)
  (skip-syntax-forward " " (line-end-position)))

(defun mwim-end-of-code ()
  "Move point to the end of code.

'End of code' means before a possible comment and trailing
whitespaces.  Comments are recognized in any mode that sets
`syntax-ppss' properly.

If current line is fully commented (contains only comment), move
to the end of line."
  (interactive "^")
  (mwim-end-of-line)
  (let ((comment-beg (mwim-line-comment-beginning)))
    (when comment-beg
      (let ((eoc (mwim-point-at
                   (goto-char comment-beg)
                   (skip-chars-backward " \t"))))
        (when (< (line-beginning-position) eoc)
          (goto-char eoc)))))
  (skip-chars-backward " \t"))

(defmacro mwim-define-command (position &rest objects)
  "Define `mwim-POSITION-of-OBJECT1-or-OBJECT2-or-...' command.
POSITION is either `beginning' or `end'.
OBJECT1 and OBJECT2 can be `line', `code' or `comment'."
  (let* ((object1     (car objects))
         (direct-fun  (intern (format "mwim-%S-of-%S" position object1)))
         (fun-name    (intern
                       (concat "mwim-" (symbol-name position) "-of-"
                               (mapconcat #'symbol-name objects "-or-")))))
    `(defun ,fun-name (&optional arg)
       ,(concat (format "Move point to the %S of %S."
                        position object1)
                (mapconcat (lambda (object)
                             (format "
If the point is already there, move to the %S of %S."
                                     position object))
                           (cdr objects) "")
                "\n
If ARG is specified, move forward (or backward) this many lines.
See `forward-line' for details.")
       (interactive
        (progn
          (handle-shift-selection)
          (when current-prefix-arg
            (list (prefix-numeric-value current-prefix-arg)))))
       (if (or (null arg) (= 0 arg))
           (mwim-move-to-next-position
            ',(mapcar (lambda (object)
                        (intern (format "mwim-%S-%S" object position)))
                      objects))
         (forward-line arg)
         (,direct-fun)))))

(mwim-define-command beginning line code)
(mwim-define-command beginning code line)
(mwim-define-command beginning code line comment)
(mwim-define-command end line code)
(mwim-define-command end code line)

;;;###autoload (autoload 'mwim-beginning-of-line-or-code "mwim" nil t)
;;;###autoload (autoload 'mwim-beginning-of-code-or-line "mwim" nil t)
;;;###autoload (autoload 'mwim-beginning-of-code-or-line-or-comment "mwim" nil t)
;;;###autoload (autoload 'mwim-end-of-line-or-code "mwim" nil t)
;;;###autoload (autoload 'mwim-end-of-code-or-line "mwim" nil t)

;;;###autoload
(defun mwim-beginning (&optional arg)
  "Move point to the next beginning position
Available positions are defined by `mwim-beginning-position-functions'.
See `mwim-move-to-next-position' for details.
Interactively, with prefix argument, move to the previous position."
  (interactive "^P")
  (mwim-move-to-next-position
   (if arg
       (reverse mwim-beginning-position-functions)
     mwim-beginning-position-functions)))

;;;###autoload
(defun mwim-end (&optional arg)
  "Move point to the next end position.
Available positions are defined by `mwim-end-position-functions'.
See `mwim-move-to-next-position' for details.
Interactively, with prefix argument, move to the previous position."
  (interactive "^P")
  (mwim-move-to-next-position
   (if arg
       (reverse mwim-end-position-functions)
     mwim-end-position-functions)))

;;;###autoload
(defun mwim (&optional arg)
  "Switch between various positions on the current line.
Available positions are defined by `mwim-position-functions'
variable.
Interactively, with prefix argument, move to the previous position."
  (interactive "^P")
  (mwim-move-to-next-position mwim-position-functions
                              (if arg #'> #'<)))

(provide 'mwim)

;;; mwim.el ends here
