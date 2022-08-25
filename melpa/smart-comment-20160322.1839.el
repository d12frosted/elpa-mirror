;;; smart-comment.el --- smarter commenting -*- lexical-binding: t; -*-

;; Copyright (C) 2016 Simon Friis Vindum

;; Author: Simon Friis Vindum <simon@vindum.io>
;; Keywords: lisp
;; Package-Version: 20160322.1839
;; Package-Commit: ad4e0de29115dc010733b9060d3dab02836b15e1
;; Version: 0.0.1

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

;; Code gets rewritten when refactoring to accomidate for new features or
;; when fixing bugs. An approach used by many developers is to disable a
;; piece of code with comments, then rewrite an improved version below,
;; test that is works and then delete the commented code. smart-comment
;; makes this and similair workflows much swifter.

;; smart-comment is implemented on top of the commenting functions built
;; in to Emacs. It is meant to replace `comment-dwim` as the function you
;; bind to `M-;`.

;; It triggers different comment actions taking the current location of
;; the point into acount. Commenting out lines of code is faster.
;; Commented lines can be marked for later deletion and then all removed
;; with a single command.


;;; Code:

;;* Customization
(defgroup smart-comment nil
  "Smarter commenting."
  :prefix "smart-comment-"
  :group 'fill)

(defcustom smart-comment-beg-action 'smart-comment-line
  "Function to call when commenting at beginning of a line."
  :type 'function)

(defcustom smart-comment-mid-action 'smart-comment-line
  "Function to call when commenting in the middle of a line."
  :type 'function)

(defcustom smart-comment-end-action 'comment-dwim
  "Function to call when commenting at end of line."
  :type 'function)

(defcustom smart-comment-mark-string "❌"
  "String used to indicate that a line is marked for removal."
  :type 'string)

(defun smart-comment--comment-end ()
  "Return string that match the ending of a comment."
  (concat comment-start
          (if (string= " " (substring comment-start -1)) "" " ")))

(defun smart-comment--mark ()
  "Return string that match a marker after a comment."
  (concat (smart-comment--comment-end) smart-comment-mark-string))

(defun smart-comment-is-at-beg ()
  "Is point at the beginning of a line."
  (let ((orig-point (point)))
    (save-excursion (back-to-indentation) (<= orig-point (point)))))

(defun smart-comment-mark-line ()
  (interactive "*")
  (save-excursion
    (beginning-of-line)
    (when (search-forward (smart-comment--comment-end) (line-end-position) t)
      (insert smart-comment-mark-string " "))))

(defun smart-comment-remove-mark-line ()
  (interactive "*")
  (save-excursion
    (beginning-of-line)
    (when (search-forward (smart-comment--comment-end) (line-end-position) t)
      (when (looking-at smart-comment-mark-string)
        (delete-forward-char 2)))))

(defun smart-comment-toggle-mark-line ()
  (interactive "*")
  (let ((end (line-end-position)))
    (beginning-of-line)
    (when (search-forward (smart-comment--comment-end))
      (if (looking-at smart-comment-mark-string)
          (delete-forward-char 2)
        (insert smart-comment-mark-string " ")))))

;;;###autoload
(defun smart-comment-cleanup ()
  "Remove lines marked for deletion."
  (interactive "*")
  (save-excursion
    (beginning-of-buffer)
    (while (search-forward (smart-comment--mark) nil t)
      (kill-whole-line))))

;;;###autoload
(defun smart-comment-mark-line (arg)
  "Mark a line for deletion. ARG is ignored."
  (interactive "*P")
  (smart-comment-line 4))

;;;###autoload
(defun smart-comment-mark-region (beg end arg)
  "Mark a region from BEG to END for deletion. ARG is ignored."
  (interactive "*r\nP")
  (let ((lines (count-lines beg end)))
    (comment-normalize-vars)
    (unless (comment-only-p beg end)
      (comment-region beg end))
    (save-excursion
      (goto-char beg)
      (dotimes (i lines)
        (smart-comment-toggle-mark-line)
        (forward-line)))))

;;;###autoload
(defun smart-comment-region (beg end arg)
  "Comment or uncomment a region from BEG to END. ARG is ignored."
  (interactive "*r\nP")
  (if (= 4 (prefix-numeric-value arg)) (smart-comment-mark-region beg end arg)
    (comment-normalize-vars)
    (if (not (comment-only-p beg end))
        (comment-region beg end arg)
      (let ((len (+ 1 (length smart-comment-mark-string)))
            (lines (count-lines beg end)))
        (save-excursion
          (goto-char beg)
          (dotimes (i lines)
            (when (search-forward (smart-comment--mark) (line-end-position) t)
              (delete-backward-char len)
              (setq end (- end len)))
            (forward-line))))
      (uncomment-region beg end arg))))

;;;###autoload
(defun smart-comment-line (arg)
  "Comment or uncomment a line. ARG is ignored."
  (interactive "*P")
  (smart-comment-region (line-beginning-position) (line-end-position) arg))

;;;###autoload
(defun smart-comment (arg)
  "Smart commenting based on the location of point on line.
A single ARG is passed along to the function being invoked. Two
universal arguments invoke `smart-comment-cleanup' which deletes
all lines marked for deletion."
  (interactive "*P")
  (cond ((= 16 (prefix-numeric-value arg))
         (smart-comment-cleanup))
        ((and mark-active transient-mark-mode)
         (smart-comment-region (region-beginning) (region-end) arg))
        ((looking-at "\\s-*$")
         (funcall smart-comment-end-action arg))
        ((smart-comment-is-at-beg)
         (funcall smart-comment-beg-action arg))
        (t (funcall smart-comment-mid-action arg))))

(provide 'smart-comment)
;;; smart-comment.el ends here
