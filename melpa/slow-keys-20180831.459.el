;;; slow-keys.el --- Slow keys mode to avoid RSI -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Manuel Uberti

;; Author: Manuel Uberti <manuel.uberti@inventati.org>
;; URL: https://github.com/manuel-uberti/slow-keys
;; Package-Version: 20180831.459
;; Package-Commit: b89b4fbddb4b6b95fcc7301ec543ea535b2cc4d7
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.1"))
;; Keywords: convenience

;; This file is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 3, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.

;; For a full copy of the GNU General Public License see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides the minor mode `slow-keys-mode' that forces you to type
;; slowly.

;; It is a porting of Chris Done's original code, that can be found here:
;; https://github.com/chrisdone/chrisdone-emacs/blob/master/packages/slow-keys/slow-keys.el

;;; Code:

(defvar slow-keys-repeat 0)
(defvar slow-keys-last-press 0)

(defgroup slow-keys nil
  "Customization of user options for slow-keys."
  :group 'convenience)

(defcustom slow-keys-sleep-for 0.5
  "Time, in seconds, to wait before start typing again."
  :group 'slow-keys
  :type 'number)

(defcustom slow-keys-min-delay 0.1
  "Delay, in seconds, between key presses."
  :group 'slow-keys
  :type 'number)

(defun slow-keys-slow-down (msg)
  "Display warning MSG and sleep before let typing begin again."
  (message "%s" (propertize msg 'face 'compilation-error))
  (redisplay)
  (sleep-for slow-keys-sleep-for))

(defun slow-keys-typing-cmd (cmd)
  "Check whether CMD is `self-insert-command' or `org-self-insert-command'."
  (or (eq cmd 'self-insert-command)
      (eq cmd 'org-self-insert-command)))

(defun slow-keys-ignore-cmd (cmd)
  "Check whether CMD should be ignored by slow typing check."
  (eq cmd 'mwheel-scroll))

(defun slow-keys-do ()
  "Check whether typing or running a command is done slowly enough."
  (unless (or executing-kbd-macro
              (slow-keys-ignore-cmd this-command))
    (setq slow-keys-repeat
          (if (eq last-command this-command)
              (1+ slow-keys-repeat)
            0))
    (when (and (> slow-keys-repeat 3)
               (not (slow-keys-typing-cmd this-command)))
      (slow-keys-slow-down
       (format "Use repetition numbers or more high-level commands: %S"
               this-command)))
    (let ((now (float-time)))
      (cond
       ((and (slow-keys-typing-cmd this-command)
             (slow-keys-typing-cmd last-command)
             (< (- now slow-keys-last-press) slow-keys-min-delay))
        (slow-keys-slow-down "Slow down typing!"))
       ((and (not (slow-keys-typing-cmd this-command))
             (not (slow-keys-typing-cmd last-command))
             (< (- now slow-keys-last-press) slow-keys-min-delay))
        (slow-keys-slow-down "Slow down command running!")))
      (setq slow-keys-last-press now))))

;;;###autoload
(define-minor-mode slow-keys-mode
  "Type slowly to avoid RSI."
  nil
  :lighter " Slow"
  :require 'slow-keys
  :global t
  (if slow-keys-mode
      (add-hook 'post-command-hook #'slow-keys-do)
    (remove-hook 'post-command-hook #'slow-keys-do)))

(provide 'slow-keys)

;;; slow-keys.el ends here
