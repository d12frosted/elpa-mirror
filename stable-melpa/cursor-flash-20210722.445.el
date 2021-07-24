;;; cursor-flash.el --- Highlight the cursor on buffer/window-switch

;; Copyright © 2021, Boruch Baum <boruch_baum@gmx.com>

;; Author/Maintainer: Boruch Baum <boruch_baum@gmx.com>
;; Homepage: https://github.com/Boruch-Baum/emacs-cursor-flash
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Keywords: convenience faces maint
;; Package-Version: 20210722.445
;; Package-Commit: 6bb54a1e2e1bf9df80926718b1b8b9ee49080484
;; Package: cursor-flash
;; Version: 1.0
;; Package-Requires: ((emacs "24.3"))

;;   (emacs "24.3") ; for: defvar-local, setq-local

;; This file is NOT part of GNU Emacs.

;; This is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your
;; option) any later version.

;; This software is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.

;; You should have received a copy of the GNU General Public License along
;; with this software. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;   This package temporarily highlights the area immediately
;;   surrounding POINT when navigating amongst buffers and windows. It
;;   is intended to assist in visually identifying the current POINT
;;   and the current window when many windows are on the same frame or
;;   when windows are very large.

;;   This package was inspired by:
;;      https://unix.stackexchange.com/questions/83167/emacs-finding-the-cursor-in-multiple-windows

;;; Usage:

;;   After installing the package: M-x `cursor-flash-mode'.

;;   To automatically enable the mode when starting Emacs, add an
;;   equivalent of the following to your init file:

;;     (require 'cursor-flash)
;;     (cursor-flash-mode 1)

;;; Customization:

;;   See variable `cursor-flash-interval' and face `cursor-flash-face'.

;;; Compatibility:

;;   * Tested on Debian Emacs 27 nox.

;;   * Includes support to operate nicely with `yascroll-bar-mode' and
;;     `vline-mode'. It temporarily suspends those modes locally
;;     during a flash in order not to make the buffer display jump
;;     around.

;;; Feedback:

;;   * It's best to contact me by opening an 'issue' on the package's
;;     github repository (see above) or, distant second-best, by
;;     direct e-mail.

;;   * Code contributions are welcome and github starring is
;;     appreciated.


;;; Code:

;;; External functions

(declare-function yascroll-bar-mode         "ext:yascroll.el")
(declare-function yascroll:show-scroll-bar  "ext:yascroll.el")
(declare-function vline-mode                "ext:vline.el")


;;; Faces:

(defface cursor-flash-face
  '((((class grayscale)
      (background light)) (:background "DimGray"))
    (((class grayscale)
      (background dark))  (:background "LightGray"))
    (((class color)
      (background light)) (:foreground "White" :background "DarkOrange1"))
    (((class color)
      (background dark))  (:foreground "Black" :background "DarkOrange1")))
  "Face used to highlight area surrounding cursor."
  :group 'cursor-flash)


;;; Customization variables:

(defcustom cursor-flash-interval 0.05
  "How many seconds to flash the cursor on window change.
A floating point number."
  :type 'number
  :group 'cursor-flash)


;;; Global variables:

(defvar cursor-flash-mode nil
  "Whether option `cursor-flash-mode' is active.
Never set this variable directly! Always use function
`cursor-flash-mode'.")

(defvar cursor-flash--window nil
  "The selected window prior to the current command.")

(defvar cursor-flash--buffer nil
  "The selected buffer prior to the current command.")


;;; Buffer-local variables:

(defvar-local cursor-flash--overlays nil
 "A list of fontified overlays performing the flash.")

(defvar-local cursor-flash--timer nil
 "A timer object to end the flash.")

(defvar-local cursor-flash--yascroll-bar nil
  ;; NOTE: It is desirable to suspend `yascroll-bar-mode' when flashing
  ;;       because when a flash overlay is on the same line as a
  ;;       yascroll-bar overlay the display becomes polluted.
  ;;
  ;; TODO: Figure out how to check whether a yascroll-bar overlay is
  ;;       on a flash line, and only disable `yascroll-bar-mode' in that
  ;;       case.
  "Holding state for minor mode `yascroll-bar-mode'.")

(defvar-local cursor-flash--vline nil
  ;; NOTE: It is desirable to suspend `vline-mode' when flashing
  ;;       because when a flash overlay is on the same line as a
  ;;       yascroll-bar overlay the display becomes polluted.
  "Holding state for minor mode `vline-mode'.")

(defvar-local cursor-flash--eolp nil
  "Holding state for POINT characteristic.
This is to work around unique display challenge when POINT is at EOL.")

(defvar-local cursor-flash--final-line-p nil
  "Holding state for POINT characteristic.
This is to work around unique display challenge when POINT is on a
buffer's final line.")


;;; Internal functions:

(defsubst cursor-flash--make-overlay (ovl-end-col)
  "Highlight a section of the current line near the cursor.
OVL-END-COL is the final column to be highlighted."
  (let* ((bol-pos          (line-beginning-position))
         (this-row-end-col (progn (end-of-line) (current-column)))
         (after-cols       (max 0 (- ovl-end-col this-row-end-col)))
         (after-spaces     (max 0 (- after-cols 3)))
         (after-hlight     (- after-cols after-spaces))
         (after-string     (concat (make-string after-spaces 32); space
                                   (propertize (make-string after-hlight 32)
                                               'face 'cursor-flash-face)))
         (ovl (make-overlay (if (< 3 after-cols) ; entirely past eolp column
                              (point) ; ie. line-end-position
                             (+ bol-pos (max 0 (- ovl-end-col 3))))
                            (if (zerop after-cols) ; entirely within eolp column
                              (+ bol-pos ovl-end-col)
                             (point))))) ; ie. line-end-position
    (overlay-put ovl 'category 'cursor-flash)
    (overlay-put ovl 'window cursor-flash--window)
    (overlay-put ovl 'face 'cursor-flash-face)
    (overlay-put ovl 'after-string after-string)
    (push ovl cursor-flash--overlays)))

(defun cursor-flash--delete (buf)
  "Remove the cursor-area highlight.
BUF is the buffer on which to act."
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (let ((inhibit-read-only t)
            ovl)
        (when (timerp cursor-flash--timer)
          (cancel-timer cursor-flash--timer)
          (setq cursor-flash--timer nil))
        (while (setq ovl (pop cursor-flash--overlays))
          (delete-overlay ovl))
        (with-silent-modifications
          (when cursor-flash--eolp
            (setq cursor-flash--eolp nil)
            (delete-char 1))
          (when cursor-flash--final-line-p
            (setq cursor-flash--final-line-p nil)
            (delete-region (1- (point-max)) (point-max))))
        (when cursor-flash--yascroll-bar
          (setq cursor-flash--yascroll-bar nil)
          ;; vline and yascroll modes interfere with each other in
          ;; ugly ways. We prioritize vline since it's likely the less
          ;; permanent and more immediate feature requested by the
          ;; user.
          (unless cursor-flash--vline
            (yascroll-bar-mode 1)
            (yascroll:show-scroll-bar)))
        (when cursor-flash--vline
          (setq cursor-flash--vline nil)
          (vline-mode 1))))))

(defun cursor-flash--flash ()
  "Perform the cursor flash.
This is intended to be a hook function for `post-command-hook'."
  (unless (or (minibuffer-window-active-p (selected-window))
              (and (eq cursor-flash--buffer (current-buffer))
                   (eq cursor-flash--window (selected-window))))
    (setq cursor-flash--window (selected-window))
    (setq cursor-flash--buffer (current-buffer))
    (setq cursor-flash--eolp (eolp))
    (let ((inhibit-read-only t)
          (return-pos (point))
          (end-col (min (window-width) (+ 2 (current-column)))))
      (when (bound-and-true-p yascroll-bar-mode)
        (setq-local cursor-flash--yascroll-bar t)
        (yascroll-bar-mode -1))
      (when (bound-and-true-p vline-mode)
        (setq-local cursor-flash--vline t)
        (vline-mode -1))
      (when (zerop (forward-line -1))
        (cursor-flash--make-overlay end-col)  ; optional overlay row #1, above POINT
        (forward-line))
      (with-silent-modifications
        (when cursor-flash--eolp
          (end-of-line)
          (insert-char 32)
          (backward-char))
        (cursor-flash--make-overlay end-col)  ; overlay row #2, at POINT's row
        (unless (zerop (forward-line 1))
          ;; row #2 is the final line of buffer
          (insert "\n")
          (setq cursor-flash--final-line-p t)))
      (cursor-flash--make-overlay end-col)    ; overlay row #3, below POINT
      (goto-char return-pos)
      (redisplay)
      (when (timerp cursor-flash--timer)
        (cancel-timer cursor-flash--timer))
      (setq cursor-flash--timer
        (run-at-time cursor-flash-interval nil #'cursor-flash--delete (current-buffer))))))


;;; Interactive functions:

(defun cursor-flash-mode (&optional arg)
  "Toggle flash around POINT upon entering window.
See variable `cursor-flash-interval' and face
`cursor-flash-face'. Optional argument ARG turns mode on when
positive, and turns it off otherwise."
  (interactive)
  (cond
    ((called-interactively-p 'interactive)
      (setq cursor-flash-mode (not cursor-flash-mode)))
    (arg
     (setq cursor-flash-mode (if (< 0 arg) t nil)))
    (t
     (setq cursor-flash-mode t)))
  (cond
   (cursor-flash-mode
     (add-hook 'post-command-hook #'cursor-flash--flash)
     (message "Cursor-Flash mode enabled"))
   (t
     (remove-hook 'post-command-hook #'cursor-flash--flash)
     (dolist (buf (buffer-list))
       (with-current-buffer buf
         (when (timerp cursor-flash--timer)
           (cancel-timer cursor-flash--timer)
           (setq cursor-flash--timer nil))))
     (message "Cursor-Flash mode disabled"))))


;;; Conclusion:

(provide 'cursor-flash)

;;; cursor-flash.el ends here
