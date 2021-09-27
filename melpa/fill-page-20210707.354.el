;;; fill-page.el --- Fill buffer so you don't see empty lines at the end  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Shen, Jen-Chieh
;; Created date 2020-08-16 18:37:21

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Fill buffer so you don't see empty lines at the end.
;; Keyword: fill page buffer
;; Version: 0.3.7
;; Package-Version: 20210707.354
;; Package-Commit: 562d6d5118097b4e62f20773fd90d600ab19fb61
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/jcs-elpa/fill-page

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
;; Fill buffer so you don't see empty lines at the end.
;;

;;; Code:

(require 'face-remap)

(defgroup fill-page nil
  "Fill buffer so you don't see empty lines at the end."
  :prefix "fill-page-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/fill-page"))


(defvar-local fill-page--max-line -1
  "Record of the total line.")

(defvar fill-page--show-debug-message nil
  "Log out detail information.")

;;; Entry

(defun fill-page--enable ()
  "Enable `fill-page' in current buffer."
  (fill-page--update-max-line)
  (add-hook 'after-change-functions #'fill-page--after-change-functions nil t)
  (add-hook 'window-configuration-change-hook #'fill-page--do-fill-page nil t)
  (add-hook 'window-scroll-functions #'fill-page--do-fill-page nil t))

(defun fill-page--disable ()
  "Disable `fill-page' in current buffer."
  (remove-hook 'after-change-functions #'fill-page--after-change-functions t)
  (remove-hook 'window-configuration-change-hook #'fill-page--do-fill-page t)
  (remove-hook 'window-scroll-functions #'fill-page--do-fill-page t))

;;;###autoload
(define-minor-mode fill-page-mode
  "Minor mode 'fill-page-mode'."
  :lighter " F-Pg"
  :group fill-page
  (if fill-page-mode (fill-page--enable) (fill-page--disable)))

(defun fill-page--turn-on-fill-page-mode ()
  "Turn on the 'fill-page-mode'."
  (fill-page-mode 1))

;;;###autoload
(define-globalized-minor-mode global-fill-page-mode
  fill-page-mode fill-page--turn-on-fill-page-mode
  :require 'fill-page)

;;; Util

(defun fill-page--debug-message (fmt &rest args)
  "Debug message like function `message' with same argument FMT and ARGS."
  (when fill-page--show-debug-message (apply #'message fmt args)))

(defun fill-page--first-display-line ()
  "Return the first display line number."
  (save-excursion (move-to-window-line 0) (line-number-at-pos nil t)))

(defun fill-page--last-display-line ()
  "Return the last display line number."
  (save-excursion (move-to-window-line -1) (line-number-at-pos nil t)))

(defun fill-page--window-height ()
  "`line-spacing'-aware calculation of `window-height'."
  (if (and (fboundp 'window-pixel-height)
           (fboundp 'line-pixel-height)
           (display-graphic-p))
      (/ (window-pixel-height) (line-pixel-height))
    (window-height)))

;;; Core

;;;###autoload
(defun fill-page-fill-p (&optional buffer-or-name)
  "Return non-nil, if the page are already filled.
Return nil, if there are unnecessary lines showing at the end of buffer.

The optional argument BUFFER-OR-NAME must be a string or buffer.  Or else
will use the current buffer instead."
  (unless buffer-or-name (setq buffer-or-name (current-buffer)))
  (with-current-buffer buffer-or-name
    (let* ((available-lines (1- (fill-page--window-height)))
           (full-lines (save-excursion (1+ (move-to-window-line -1)))))
      (= 0 (- available-lines full-lines)))))

;;;###autoload
(defun fill-page (&optional buffer-or-name)
  "Fill the page to BUFFER-OR-NAME.

The optional argument BUFFER-OR-NAME must be a string or buffer.  Or else
will use the current buffer instead."
  (unless buffer-or-name (setq buffer-or-name (current-buffer)))
  (with-current-buffer buffer-or-name
    (save-excursion
      (goto-char (point-max))
      (recenter -1))))

(defun fill-page--update-max-line (&optional max-ln)
  "Update MAX-LN."
  (unless max-ln (setq max-ln (line-number-at-pos (point-max) t)))
  (setq fill-page--max-line max-ln))

;;;###autoload
(defun fill-page-if-unfill ()
  "Do fill page if it's unfill."
  (unless (fill-page-fill-p) (fill-page)))

(defun fill-page--do-fill-page (&rest _)
  "Do the fill page once."
  (let ((win-lst (get-buffer-window-list)))
    (when (and (window-live-p (selected-window)) win-lst)
      (fill-page--update-max-line)
      (save-selected-window
        (dolist (win win-lst)
          (select-window win)
          (fill-page-if-unfill))))))

;;; Registry

(defun fill-page--after-change-functions (beg end len)
  "For `fill-page' after change, BEG, END and LEN."
  (when (get-buffer-window)
    (let ((adding-p (<= (+ beg len) end)) max-ln)
      (unless adding-p
        (setq max-ln (line-number-at-pos (point-max) t))
        (unless (= max-ln fill-page--max-line)
          (fill-page--update-max-line max-ln)
          (fill-page--do-fill-page))))))

(provide 'fill-page)
;;; fill-page.el ends here
