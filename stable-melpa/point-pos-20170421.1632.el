;;; point-pos.el --- Save and restore point positions

;; Copyright © 2012–2014, 2017 Alex Kost

;; Author: Alex Kost <alezost@gmail.com>
;; Created: 24 Aug 2012
;; Version: 0.1
;; Package-Version: 20170421.1632
;; Package-Commit: 442bccb40791832cbc2d6f5c8f53be745aea2b73
;; URL: https://github.com/alezost/point-pos.el
;; Keywords: tools convenience

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

;; The package provides commands for managing the history of saved point
;; positions.

;; To install the package, add the following to your emacs init file:
;;
;;   (add-to-list 'load-path "/path/to/point-pos")
;;   (autoload 'point-pos-save "point-pos" nil t)

;; Commands:
;;
;; "M-x point-pos-save"     - save current position;
;; "M-x point-pos-goto"     - return to the last saved position;
;; "M-x point-pos-next"     - return to the next saved position;
;; "M-x point-pos-previous" - return to the previous saved position;
;; "M-x point-pos-delete"   - delete current position from history.

;;; Code:

(defvar point-pos-current nil
  "Current point position (marker object).")

(defvar point-pos-back-stack nil
  "Stack (list) of previous point positions.
Each element of the list has a form of `point-pos-current'.")

(defvar point-pos-forward-stack nil
  "Stack (list) of next point positions.
Each element of the list has a form of `point-pos-current'.")

(defun point-pos-get-current (&optional noerror)
  "Return current point position.
If NOERROR is non-nil, return nil if there is no saved point
position instead of raising an error."
  (or point-pos-current
      (if noerror
          nil
        (error "No saved point positions"))))

(defun point-pos-set-current (pos)
  "Set current point position to POS."
  (setq point-pos-current pos))

;;;###autoload
(defun point-pos-save ()
  "Save current point position in history."
  (interactive)
  (when point-pos-current
    (push point-pos-current point-pos-back-stack))
  (point-pos-set-current (point-marker))
  (message "Current point position has been saved."))

(defun point-pos-delete (&optional arg)
  "Delete current point position and move to the previous one.
If ARG is non-nil (with prefix), delete all point positions."
  (interactive "P")
  (if arg
      (when (y-or-n-p "Delete all saved point positions? ")
        (setq point-pos-back-stack nil
              point-pos-forward-stack nil
              point-pos-current nil)
        (message "All point positions have been deleted."))
    (point-pos-move 'point-pos-forward-stack 'point-pos-back-stack t)))

(defun point-pos-next ()
  "Go forward to the next point position."
  (interactive)
  (point-pos-move 'point-pos-back-stack 'point-pos-forward-stack))

(defun point-pos-previous ()
  "Go backward to the previous point position."
  (interactive)
  (point-pos-move 'point-pos-forward-stack 'point-pos-back-stack))

(defun point-pos-move (tail head &optional del-current)
  "Move to the next point position in the direction from TAIL to HEAD.
TAIL and HEAD are symbols `point-pos-forward-stack' or
`point-pos-back-stack'.
If DEL-CURRENT is non-nil, delete current position."
  (let ((pos (point-pos-get-current))
        (tail-stack (symbol-value tail))
        (head-stack (symbol-value head)))
    (if head-stack
        (progn
          (or del-current
              (set tail (cons pos tail-stack)))
          (point-pos-set-current (car head-stack))
          (set head (cdr head-stack))
          (point-pos-goto))
      (if tail-stack
          (progn
            (set head (nreverse tail-stack))
            (set tail nil)
            (point-pos-move tail head del-current))
        (if del-current
            (progn
              (point-pos-set-current nil)
              (message "A single point position has been deleted."))
          (point-pos-goto)
          (message "This is a single saved point position."))))))

(defun point-pos-goto ()
  "Go to the current point position.
If the current position is dead (if its buffer was killed),
delete it and go to the next saved position."
  (interactive)
  (let* ((pos    (point-pos-get-current))
         (buffer (marker-buffer pos)))
    (if (null buffer)
        (point-pos-delete)
      (switch-to-buffer buffer)
      (goto-char (marker-position pos)))))

(provide 'point-pos)

;;; point-pos.el ends here
