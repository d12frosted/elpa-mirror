;;; repeater.el --- Repeat recent repeated commands  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Xu Chunyang

;; Author: Xu Chunyang <mail@xuchunyang.me>
;; Homepage: https://github.com/xuchunyang/repeater
;; Package-Requires: ((emacs "24.4"))
;; Package-Version: 20180418.1212
;; Package-Commit: 854b874542b186b2408cbc58ad0591fe8eb70b6c
;; Keywords: convenience
;; Created: Fri, 30 Mar 2018 22:16:53 +0800

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

;; C-n C-n C-n ...........................................................

;;; Code:

(defgroup repeater nil
  "Repeat recent repeated commands."
  :group 'tools)

(defcustom repeater-min-times 3
  "The minimum number of times of a repeated command to consider."
  :group 'repeater
  :type 'number)

(defcustom repeater-interval 0.1
  "Interval between repeating."
  :group 'repeater
  :type 'number)

(defcustom repeater-ignore-functions '(repeater-default-ignore-function)
  "Functions to call with no argument to check about repeating.
If any of these functions returns non-nil, repeater will not repeat."
  :group 'repeater
  :type 'hook)

(defcustom repeater-ignore-commands
  '(kill-this-buffer
    keyboard-quit
    ignore
    ;; Some delete commands, such as `backward-kill-word', set `this-command' to
    ;; `kill-region', I don't know to handle this case.  See also (info "(elisp)
    ;; Command Loop Info")
    kill-region)
  "Don't repeat these commands."
  :group 'repeater
  :type '(repeat function))

(defcustom repeater-query-function 'repeater-default-query-function
  "Function to call with no argument to query about repeating.
If any of these functions returns nil, repeater will not repeat."
  :group 'repeater
  :type 'hook)

(defun repeater-equals (first &rest rest)
  "Return t if args are all equal."
  (catch 'repeater-equals--break
    (dolist (elt rest)
      (or (equal elt first)
          (throw 'repeater-equals--break nil)))
    t))

(defvar repeater-ring nil
  "List of recent commands.")

(defun repeater-ring-push (elt)
  (let ((repeater-ring-max repeater-min-times))
    (push elt repeater-ring)
    (when (> (length repeater-ring) repeater-ring-max)
      (setcdr (nthcdr (1- repeater-ring-max) repeater-ring) nil))))

(defun repeater-default-ignore-function ()
  (or (minibufferp)
      (bound-and-true-p edebug-active)
      (memq this-command repeater-ignore-commands)
      ;; Suggested by @casouri at https://emacs-china.org/t/topic/5414/2
      (and (derived-mode-p 'markdown-mode)
           (equal (this-command-keys-vector) [?\`]))
      (and (derived-mode-p 'js-mode)
           (equal (this-command-keys-vector) [?=]))
      (and (eq major-mode 'python-mode)
           (or (equal (this-command-keys-vector) [?\"])
               (equal (this-command-keys-vector) [?\'])))))

(defvar repeater-sit-for .5)
(defvar repeater-confirm-timeout 1)

(defun repeater-default-query-function ()
  (and (sit-for repeater-sit-for)
       (message "About to repeat '%s' (Hit any key to stop)" this-command)
       (sit-for repeater-confirm-timeout)))

(defun repeater-post-command ()
  (repeater-ring-push (cons this-command (this-command-keys-vector)))
  (when (and (= (length repeater-ring) repeater-min-times)
             (apply #'repeater-equals repeater-ring))
    (let ((message-log-max nil))
      (when (and (null (run-hook-with-args-until-success 'repeater-ignore-functions))
                 (run-hook-with-args-until-success 'repeater-query-function))
        (unwind-protect
            (let ((count 0))
              (while (and (condition-case err
                              (prog1 t (call-interactively this-command))
                            (error
                             (message "%s" (error-message-string err))
                             nil))
                          (sit-for repeater-interval))
                (setq count (1+ count))
                (message "Repeating '%s' [%d times] (Hit any key to stop)"
                         this-command
                         count)))
          (discard-input)
          (message "Quit")
          (setq repeater-ring nil))))))

;;;###autoload
(define-minor-mode repeater-mode
  "If you run the same command for 3 times, repeat it."
  :global t
  :lighter " Repeater"
  :require 'repeater
  (if repeater-mode
      (add-hook 'post-command-hook #'repeater-post-command)
    (remove-hook 'post-command-hook #'repeater-post-command)))

(provide 'repeater)
;;; repeater.el ends here
