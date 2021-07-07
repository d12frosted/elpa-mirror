;;; real-auto-save.el --- Automatically save your buffers/files at regular intervals  -*- lexical-binding: t; -*-

;; Copyright (C) 2008-2015, Chaoji Li, Anand Reddy Pandikunta

;; Author: Chaoji Li <lichaoji AT gmail DOT com>
;;         Anand Reddy Pandikunta <anand21nanda AT gmail DOT com>
;; Version: 0.4
;; Package-Version: 20200505.1537
;; Package-Commit: 481a2d1460ab5a9b6df3721dda76ad515923bfd1
;; Date: January 27, 2015
;; URL: https://github.com/ChillarAnand/real-auto-save
;; Package-Requires: ((emacs "24.4"))

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

;; Put this file in a folder where Emacs can find it.

;; Add following lines to your .emacs initialization file
;; to enable auto save in all programming modes.

;;     (require 'real-auto-save)
;;     (add-hook 'prog-mode-hook 'real-auto-save-mode)

;; Auto save interval is 10 seconds by default.
;; You can change it to whatever value you want at any point.

;;     (setq real-auto-save-interval 5) ;; in seconds

;;; Code:

(defgroup real-auto-save nil
  "Save buffers automatically."
  :group 'convenience
  :prefix "real-auto-save-")

(defcustom real-auto-save-interval 10
  "Time interval of real auto save."
  :type 'integer
  :group 'real-auto-save
  :set (lambda (sym value)
         (set sym value)
         (when (bound-and-true-p real-auto-save-buffers-list)
           (real-auto-save--start-timer 'restart))))

(defvar real-auto-save-buffers-list nil
  "List of buffers that will be saved automatically.")

(defvar real-auto-save-timer nil
  "Real auto save timer.")

(defun real-auto-save-buffers ()
  "Automatically save all buffers in real-auto-save-buffers-list."
  (save-current-buffer
    (dolist (elm real-auto-save-buffers-list)
      (if (and (buffer-live-p elm)
               (with-current-buffer elm (buffer-file-name)))
          (with-current-buffer elm
            (when (buffer-modified-p)
              (let ((message-log-max nil))
                (with-temp-message (or (current-message) "")
                  (save-buffer)))))
        (setq real-auto-save-buffers-list
              (delq elm real-auto-save-buffers-list))))))

(defun real-auto-save--disable ()
  "Just do nothing function.
Unlinke `ignore', this function is not interactive function."
  (ignore))

(defun real-auto-save--start-timer (&optional restart)
  "Start real-auto-save-timer.
If RESTART is non-nil, restart timer."
  (when restart
    (when (timerp real-auto-save-timer)
      (cancel-timer real-auto-save-timer))
    (setq real-auto-save-timer nil))
  (unless real-auto-save-timer
    (setq real-auto-save-timer
          (run-with-idle-timer real-auto-save-interval t 'real-auto-save-buffers))))

(defun real-auto-save--setup ()
  "Setup real-auto-save-mode."
  (real-auto-save--start-timer)
  (add-to-list 'real-auto-save-buffers-list (current-buffer))
  (advice-add 'makefile-warn-suspicious-lines :override 'real-auto-save--disable)
  (advice-add 'makefile-warn-continuations    :override 'real-auto-save--disable))

(defun real-auto-save--teardown ()
  "Teardown real-auto-save-mode."
  (setq real-auto-save-buffers-list
        (delq (current-buffer) real-auto-save-buffers-list)))

;;;###autoload
(define-minor-mode real-auto-save-mode
  "Save your buffers automatically."
  :lighter " RAS"
  :keymap nil
  (if real-auto-save-mode
      (real-auto-save--setup)
    (real-auto-save--teardown)))

(provide 'real-auto-save)
;;; real-auto-save.el ends here
