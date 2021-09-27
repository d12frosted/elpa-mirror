;;; better-scroll.el --- Improve user experience when scrolling window  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Shen, Jen-Chieh
;; Created date 2020-07-23 18:26:34

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Improve user experience when scrolling window.
;; Keyword: scrolling scroll window better improvement
;; Version: 0.1.4
;; Package-Version: 20210715.1004
;; Package-Commit: 319c24d9aa46a66d43cf689134c7e1703288d251
;; Package-Requires: ((emacs "24.3"))
;; URL: https://github.com/jcs-elpa/better-scroll

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Improve user experience when scrolling window.
;;

;;; Code:

(require 'cl-lib)

(defgroup better-scroll nil
  "Improve user experience when scrolling window."
  :prefix "better-scroll-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/better-scroll"))

(defcustom better-scroll-allow-boundary-movement t
  "Allow cursor moves to boundary point after moving to the beginning/end
of buffer."
  :type 'boolean
  :group 'better-scroll)

(defcustom better-scroll-align-type 'center
  "Type of scroll's aligment to cursor position."
  :type '(choice  (const :tag "center" center)
                  (const :tag "relative" relative))
  :group 'better-scroll)

;;; Util

(defun better-scroll--goto-line (ln)
  "Goto LN line number."
  (goto-char (point-min)) (forward-line (1- ln)))

(defun better-scroll--recenter-positions (type)
  "Return the recenter position value by TYPE."
  (cl-case type (top '(top)) (middle '(middle)) (bottom '(bottom))))

(defun better-scroll--recenter-top-bottom (type)
  "Recenter the window by TYPE."
  (let ((recenter-positions (better-scroll--recenter-positions type)))
    (recenter-top-bottom)))

(defun better-scroll--move-to-window-line-top-bottom (type)
  "Move to window line by TYPE."
  (let ((recenter-positions (better-scroll--recenter-positions type)))
    (move-to-window-line-top-bottom)))

(defun better-scroll--first-display-line ()
  "Return the first display line number."
  (save-excursion (move-to-window-line 0) (line-number-at-pos nil t)))

(defun better-scroll--line-diff-to-first ()
  "Difference of first display line number and current line number."
  (- (line-number-at-pos nil t) (better-scroll--first-display-line)))

;;; Core

(defun better-scroll--do-relative (rel-ln)
  "Do the relative line action by REL-LN."
  (better-scroll--goto-line (+ (better-scroll--first-display-line) rel-ln)))

(defun better-scroll--do-by-type (rel-ln)
  "Do scroll action by passing all needed params, REL-LN."
  (cl-case better-scroll-align-type
    (center
     (better-scroll--move-to-window-line-top-bottom 'middle)
     (when (= (point) (point-max)) (better-scroll--recenter-top-bottom 'middle)))
    (relative (better-scroll--do-relative rel-ln))))

(defun better-scroll--move-boundry (dc fnc)
  "Move boundry by direction (DC) and function (FNC)."
  (let ((prev-pt (point)) (prev-col (current-column)))
    (funcall fnc)
    (move-to-column prev-col)
    (when (and better-scroll-allow-boundary-movement (= (point) prev-pt))
      (goto-char (cl-case dc (down (point-min)) (up (point-max)))))))

;;;###autoload
(defun better-scroll-down ()
  "Scroll down."
  (interactive)
  (better-scroll--move-boundry
   'down
   (lambda ()
     (let ((rel-ln (better-scroll--line-diff-to-first)))
       (ignore-errors (scroll-down))
       (better-scroll--do-by-type rel-ln)))))

;;;###autoload
(defun better-scroll-up ()
  "Scroll up."
  (interactive)
  (better-scroll--move-boundry
   'up
   (lambda ()
     (let ((rel-ln (better-scroll--line-diff-to-first)))
       (ignore-errors (scroll-up))
       (better-scroll--do-by-type rel-ln)))))

;;;###autoload
(defun better-scroll-down-other-window ()
  "Scroll down other window."
  (interactive)
  (save-selected-window (other-window 1) (better-scroll-down)))

;;;###autoload
(defun better-scroll-up-other-window ()
  "Scroll up other window."
  (interactive)
  (save-selected-window (other-window 1) (better-scroll-up)))

(provide 'better-scroll)
;;; better-scroll.el ends here
