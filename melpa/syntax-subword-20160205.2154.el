;;; syntax-subword.el --- make operations on words more fine-grained

;; Copyright (C) 2012 Jonathan Kotta

;; Author: Jonathan Kotta <jpkotta@gmail.com>
;; Version: 0.2
;; Package-Version: 20160205.2154
;; Package-Commit: 9aa9b3f846bfe2474370642458a693ac4760d9fe

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

;; This package provides `syntax-subword' minor mode, which extends
;; `subword-mode' to make word editing and motion more fine-grained.
;; Basically, it makes syntax changes, CamelCaseWords, and the normal
;; word boundaries the boundaries for word operations.  Here's an
;; example of where the cursor stops using `forward-word' in
;; `emacs-lisp-mode':
;;
;; (defun FooBar (arg) "doc string"
;; |     |      |    |     |      |  standard
;; |     |   |  |    |     |      |  subword-mode
;; ||    ||  |  |||  ||||  ||     || syntax-subword-mode
;; ||     |      ||  | ||   |     |  vim
;;
;; As you can see, syntax boundaries are places where the syntax
;; changes, i.e. we change from a bracket to a keyword, to a space, to
;; an argument, to a space, etc.  This makes word movement much more
;; fine-grained, to the point that you almost never need to operate by
;; single characters anymore.  Vim's word operations are similar to
;; this mode's.
;;
;; Stops on spaces can be eliminated by setting
;; `syntax-subword-skip-spaces' to non-nil.

;;; Code:


(require 'subword)

(defvar syntax-subword-skip-spaces nil
  "When non-nil, do not stop on spaces.  
When set to the special symbol 'consistent, stop at right edge of spaces 
regardless of direction.")

(defvar syntax-subword-mode-map
  (let ((map (make-sparse-keymap)))
    (dolist (old-and-new
             '((right-word         syntax-subword-right)
               (left-word          syntax-subword-left)
               (forward-word       syntax-subword-forward)
               (backward-word      syntax-subword-backward)
               (mark-word          syntax-subword-mark)
               (kill-word          syntax-subword-kill)
               (backward-kill-word syntax-subword-backward-kill)
               (transpose-words    syntax-subword-transpose)
               (capitalize-word    syntax-subword-capitalize)
               (upcase-word        syntax-subword-upcase)
               (downcase-word      syntax-subword-downcase)))
      (let ((oldcmd (car old-and-new))
            (newcmd (cadr old-and-new)))
        (define-key map (vector 'remap oldcmd) newcmd)))
    map)
  "Keymap used in `syntax-subword-mode' minor mode.")

;;;###autoload
(define-minor-mode syntax-subword-mode
  "This mode is like `subword-mode', but also treats syntax
  changes as word boundaries.  Syntax changes are generally the
  same as face changes when font lock is
  enabled. \\{syntax-subword-mode-map}"
    nil
    nil
    syntax-subword-mode-map
    (when (and syntax-subword-mode subword-mode)
      (subword-mode -1)
      (message "Disabling subword-mode"))
    )

;;;###autoload
(define-global-minor-mode global-syntax-subword-mode syntax-subword-mode
  (lambda () (syntax-subword-mode 1)))

(defun syntax-subword-forward (&optional n)
  "Go forward by either the next change in syntax or a
subword (see `subword-mode' for a description of subwords)."
  (interactive "^p")
  (syntax-subword-forward-1 n))
(put 'syntax-subword-forward 'CUA 'move)

(defun syntax-subword-backward (&optional n)
  "Go backward to the previous change in syntax or subword (see
  `subword-mode' for a description of subwords)."
  (interactive "^p")
 (syntax-subword-forward (- n)))
(put 'syntax-subword-backward 'CUA 'move)

(defun syntax-subword-right (&optional n)
  (interactive "^p")
  (if (eq (current-bidi-paragraph-direction) 'left-to-right)
      (syntax-subword-forward n)
    (syntax-subword-backward n)))
(put 'syntax-subword-right 'CUA 'move)

(defun syntax-subword-left (&optional n)
  (interactive "^p")
  (if (eq (current-bidi-paragraph-direction) 'left-to-right)
      (syntax-subword-backward n)
    (syntax-subword-forward n)))
(put 'syntax-subword-left 'CUA 'move)

(defun syntax-subword-kill (&optional n)
  (interactive "^p")
  (let ((beg (point))
        (end (save-excursion (syntax-subword-forward n) (point))))
    (kill-region beg end)))

(defun syntax-subword-backward-kill (&optional n)
  (interactive "^p")
  (syntax-subword-kill (- n)))

(defalias 'syntax-subword-mark 'subword-mark)
(defalias 'syntax-subword-transpose 'subword-transpose)
(defalias 'syntax-subword-capitalize 'subword-capitalize)
(defalias 'syntax-subword-downcase 'subword-downcase)
(defalias 'syntax-subword-upcase 'subword-upcase)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; internal functions

(defun syntax-subword-forward-syntax (&optional arg)
  "Like `forward-word', but jump to the next change in syntax.
  This is closer to Vim's behavior when moving by words."
  (interactive "p")
  (let* ((count (or arg 1))
         (inc (if (< count 0) 1 -1)))
    (while (not (or (= count 0) (and (> count 0) (eobp)) (and (< count 0) (bobp))))
      (if (> count 0)
          (skip-syntax-forward (string (char-syntax (char-after))))
        (skip-syntax-backward (string (char-syntax (char-before)))))
      (setq count (+ count inc)))))
(put 'syntax-subword-forward-syntax 'CUA 'move)

(defun syntax-subword-backward-syntax (&optional arg)
  "Like `backward-word', but jump to the next change in syntax.
  This is closer to Vim's behavior when moving by words."
  (interactive "p")
  (syntax-subword-forward-syntax (- 0 (or arg 1))))
(put 'syntax-subword-backward-syntax 'CUA 'move)

(defun syntax-subword-forward-1 (count)
  "Move point forward COUNT subwords or syntax changes.

If `syntax-subword-skip-spaces' is non-nil, keep going if at a
space (don't decrement count).

Negative COUNT moves backwards."
  (let* ((sign (cl-signum count))
         (count (abs count))
         subword-pos
         syntax-pos)
    (while (< 0 count)
      (save-excursion
        (syntax-subword-forward-syntax sign)
        (setq syntax-pos (point)))
      (save-excursion
        (subword-forward sign)
        (setq subword-pos (point)))
      ;; always move at least one char
      (if (< 0 sign)
          (goto-char (max (1+ (point)) (min subword-pos syntax-pos)))
        (goto-char (min (1- (point)) (max subword-pos syntax-pos))))
      (unless (cond ((eq syntax-subword-skip-spaces 'consistent)
                     (looking-at "[[:space:]]"))
                    (syntax-subword-skip-spaces
                     (or 
                      (and (< 0 sign) (looking-at "[[:space:]]"))
                      (and (> 0 sign) (looking-back "[[:space:]]")))))
        (setq count (1- count)))
      )))

(provide 'syntax-subword)
;;; syntax-subword.el ends here
