;;; windsize.el --- Simple, intuitive window resizing

;; Copyright (C) 2011 Chris Perkins
;;
;; Author: Chris Perkins <chrisperkins99@gmail.com>
;; Created: 01 July, 2011
;; URL: http://github.com/grammati/windsize
;; Package-Version: 20181029.2257
;; Package-Commit: 62c2846bbe95b0a73e996c75e4a644d05f57aaaa
;; Version: 0.1
;; Keywords: window, resizing, convenience

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Use the arrow keys (C-S-<dir> by default) to move one of the
;; borders of the active window in that direction. Always prefers to
;; move the right or bottom border when possible, and falls back to
;; moving the left or top border otherwise.
;; 
;; Rather than me trying to explain that in detail, it's best to just
;; split your emacs frame in to several windows and try it - trust me,
;; it's intuitive once you give it a go.

;;; Usage

;; (require 'windsize)
;; (windsize-default-keybindings) ; C-S-<left/right/up/down>
;;
;; Or bind windsize-left, windsize-right, windsize-up, and
;; windsize-down to the keys you prefer.
;;
;; By default, resizes by 8 columns and by 4 rows. Customize by
;; setting windsize-cols and/or windsize-rows.
;; Note that these variables are not buffer-local, since resizing
;; windows usually affects at least 2 buffers.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(require 'windmove)

(defcustom windsize-cols 8
  "How much to resize horizontally."
  :type 'integer
  :group 'windsize)

(defcustom windsize-rows 4
  "How much to resize vertically."
  :type 'integer
  :group 'windsize)

(defun windsize-is-horizontal (dir)
  (or (eq dir 'left) (eq dir 'right)))

(defun windsize-default-amount (dir)
  (if (windsize-is-horizontal dir)
      windsize-cols
    windsize-rows))

;; Find the window in direction dir, without wrap-around.
(defun windsize-find-other-window (dir)
  ;; Let windmove do all the hard work (but temporarily disable wrap-around)
  ;; OK, there has to be a macro for this pattern (it's 'binding' in
  ;; clojure), but I'm new to elisp...
  (let ((temp windmove-wrap-around))
    (setq windmove-wrap-around nil)
    (let ((other (windmove-find-other-window dir)))
      (setq windmove-wrap-around temp)
      (if (window-minibuffer-p other)
        nil
        other))))

(defun windsize-resize (dir &optional arg)
  ;; For right and down: check for a window right/down. If there is
  ;; one, enlarge, otherwise shrink. (case 1)
  ;; For left and up: check for a window in the opposite direction. If
  ;; there is one, shrink, otherwise enlarge. (case 2)
  ;; This is dictated somewhat by the behaviour of enlarge-window - it
  ;; seems to usually (but not always) move the right or bottom edge.
  (let* ((horiz? (windsize-is-horizontal dir))
         (pref?  (or (eq dir 'right) (eq dir 'down))) ; right/down are the
                                                      ; "preferred" directions
         (other  (windsize-find-other-window (if horiz? 'right 'down)))
         (num    (or arg (windsize-default-amount dir)))
         (amount (if (or
                      (and pref? other)              ; case 1, above
                      (and (not pref?) (not other))) ; case 2, above
                     num                             ; enlarge
                   (- num))))                        ; shrink
    (enlarge-window amount horiz?)))

;;;###autoload
(defun windsize-left (&optional arg)
  "Resize the current window by moving one of its edges to the left."
  (interactive "P")
  (windsize-resize 'left arg))

;;;###autoload
(defun windsize-right (&optional arg)
  "Resize the current window by moving one of its edges to the right."
  (interactive "P")
  (windsize-resize 'right arg))

;;;###autoload
(defun windsize-up (&optional arg)
  "Resize the current window by moving one of its edges up."
  (interactive "P")
  (windsize-resize 'up arg))

;;;###autoload
(defun windsize-down (&optional arg)
  "Resize the current window by moving one of its edges down."
  (interactive "P")
  (windsize-resize 'down arg))

;;;###autoload
(defun windsize-default-keybindings ()
  (interactive)
  (global-set-key (kbd "C-S-<left>")  'windsize-left)
  (global-set-key (kbd "C-S-<right>") 'windsize-right)
  (global-set-key (kbd "C-S-<up>")    'windsize-up)
  (global-set-key (kbd "C-S-<down>")  'windsize-down)
  )


(provide 'windsize)
;;; windsize.el ends here
