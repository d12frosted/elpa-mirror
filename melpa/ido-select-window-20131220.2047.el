;;; ido-select-window.el --- Select a window using ido and buffer names -*- lexical-binding: t -*-
;;
;; Copyright (C) 2013 Peter Jones <pjones@devalot.com>
;;
;; Author: Peter Jones <pjones@devalot.com>
;; URL: https://github.com/pjones/ido-select-window
;; Package-Version: 20131220.2047
;; Package-Commit: 946db3db7a3fec582cc1a0097877f1250303b53a
;; Package-Requires: ((emacs "24.1"))
;; Version: 0.1.0
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; A very simple alternative to the numerous packages that allow you
;; to easily switch between windows.  When you have more than two
;; windows in the current frame and you invoke ido-select-window
;; you'll be prompted in the mini-buffer via ido to select a window
;; based on its buffer name.
;;
;;; License:
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;;
;;; Code:

(defgroup ido-select-window nil
  "A simple package to switch windows using ido."
  :version "0.1.0"
  :prefix "ido-select-window-"
  :group 'applications)

(defcustom ido-select-window-prompt "Window: "
  "The mini-buffer prompt to use when selecting a window."
  :type 'string
  :group 'ido-select-window)

;;;###autoload
(defun ido-select-window ()
  "Switch the focus to another window.

Choose a buffer name in the mini-buffer using ido.  The currently
selected window is excluded from the list of windows."
  (interactive)
  (let* ((wins (cdr (window-list)))
         (mapping (mapcar
                   (lambda (w) (cons (buffer-name (window-buffer w)) w))
                   wins))
         (names (mapcar 'car mapping)))
    (if (> (length wins) 1)
        ; There are more than 2 windows in this frame.
        (select-window
         (cdr (assoc
               (ido-completing-read ido-select-window-prompt names)
               mapping)))
      ; There are 2 or fewer windows in this frame.
      (call-interactively 'other-window))))

(provide 'ido-select-window)
;;; ido-select-window.el ends here
