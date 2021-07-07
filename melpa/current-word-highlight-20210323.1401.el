;;; current-word-highlight.el --- Highlight the current word minor mode

;; Copyright (C) 2021 Kijima Daigo
;; Created date 2021-02-10 00:30 +0900

;; Author: Kijima Daigo <norimaking777@gmail.com>
;; Version: 1.0.4
;; Package-Version: 20210323.1401
;; Package-Commit: d860f4e170ffa4cef840da93647f458cc409d554
;; Keywords: highlight face convenience word
;; URL: https://github.com/kijimaD/current-word-highlight

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
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

;;; Commentary:
;; M-x current-word-highlight-mode or M-x global-current-word-highlight-mode
;; Enabling it in a hook is recommended.  But you don't want it enabled
;; for all buffers, just programming ones.
;; Example:
;; (add-hook 'prog-mode-hook 'current-word-highlight-mode)

;; I referred to idle-highlight-mode(by Phil Hagelberg, Cornelius Mika) for highlighting and commentary.

;;; Code:

(require 'thingatpt)

(defgroup current-word-highlight nil
  "Highlight the word on the cursor."
  :group 'convenience)

(defface current-word-highlight-face
  '((((class color)
      (background dark))
     (:background "DodgerBlue"))
    (((class color)
      (background light))
     (:background "DeepSkyBlue"))
    (t ()))
  "Face for main highlight."
  :group 'current-word-highlight)

(defface current-word-highlight-sub-face
  '((((class color)
      (background dark))
     (:background "MediumVioletRed"))
    (((class color)
      (background light))
     (:background "HotPink"))
    (t ()))
  "Face for sub highlight."
  :group 'current-word-highlight)

(defcustom current-word-highlight-time 0.4
  "Time after which to highlight the word at point."
  :group 'current-word-highlight
  :type 'float)

(defvar current-word-highlight-global-timer nil
  "Timer to trigger highlighting.")

(defvar current-word-highlight-overlay-list nil)
(make-variable-buffer-local 'current-word-highlight-overlay-list)

(defvar current-word-highlight-context t
  "Highlight the context also if non-nil.
Default is to highlight.")

(defvar current-word-highlight-thing 'word
  "Thing to highlight.
One of the possible things at point see `thingatpt'.
Default is 'word")

(defvar current-word-highlight-mode nil)

(defun current-word-highlight-mode-maybe ()
  "Fire up 'current-word-highlight-mode if not minibuffer."
  (if (and (not (minibufferp (current-buffer))))
      (current-word-highlight-mode t)))

(defun current-word-highlight-light-up (face)
  "Highlight the current word with FACE."
  (if (bounds-of-thing-at-point current-word-highlight-thing)
      (let* ((overlay (make-overlay
                       (car (bounds-of-thing-at-point current-word-highlight-thing))
                       (cdr (bounds-of-thing-at-point current-word-highlight-thing)) nil nil t)))
        ;; Display word-highlight before auto-highlight-symbol-mode. AHS's priority is 1000.
        (overlay-put overlay 'priority 1001)
        (overlay-put overlay 'face face)
        (push overlay current-word-highlight-overlay-list))))

(defun current-word-highlight-around ()
  "Highlight around words."
  ;; (forward-to-word 1) don't work well in language ​​without delimiters(ex. Japanese, Chinese).
  (save-excursion
    (if (and (bounds-of-thing-at-point current-word-highlight-thing)
             (beginning-of-thing current-word-highlight-thing))
        (forward-char -1))
    (forward-word -1)
    (forward-char 1)
    (current-word-highlight-light-up 'current-word-highlight-sub-face))

  (save-excursion
    (if (and (bounds-of-thing-at-point current-word-highlight-thing)
             (end-of-thing current-word-highlight-thing))
        (forward-char 1))
    (forward-word 1)
    (forward-char -1)
    (current-word-highlight-light-up 'current-word-highlight-sub-face)))

(defun current-word-highlight-unhighlight ()
  "Delete old highlight."
  (mapc 'delete-overlay current-word-highlight-overlay-list)
  (remove-hook 'pre-command-hook #'current-word-highlight-unhighlight))

(defun current-word-highlight-cancel-timer ()
  "Cancel timer."
  (when (timerp current-word-highlight-global-timer)
    (cancel-timer current-word-highlight-global-timer)
    (setq current-word-highlight-global-timer nil)))

(defun current-word-highlight-word-at-point ()
  "Highlight the word under the point.  If the point is not on a word, highlight the around word."
  (interactive)
  (current-word-highlight-unhighlight)
  (when current-word-highlight-mode
    (current-word-highlight-light-up 'current-word-highlight-face)
    (when current-word-highlight-context
      (current-word-highlight-around)))
  (add-hook 'pre-command-hook #'current-word-highlight-unhighlight))

;;;###autoload
(define-minor-mode current-word-highlight-mode
  "Current-Word-Highlight Minor Mode"
  :group 'current-word-highlight
  (if current-word-highlight-mode
      (progn (unless current-word-highlight-global-timer
               (setq current-word-highlight-global-timer
                     (run-with-idle-timer current-word-highlight-time
                                          :repeat 'current-word-highlight-word-at-point))))
    (current-word-highlight-cancel-timer)
    (current-word-highlight-unhighlight)))

;;;###autoload
(define-globalized-minor-mode global-current-word-highlight-mode
  current-word-highlight-mode current-word-highlight-mode-maybe
  :group 'current-word-highlight)

(provide 'current-word-highlight)

;;; current-word-highlight.el ends here
