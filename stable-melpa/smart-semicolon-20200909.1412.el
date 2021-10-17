;;; smart-semicolon.el --- Insert semicolon smartly -*- lexical-binding: t -*-

;; Copyright (C) 2017 by Iku Iwasa

;; Author:    Iku Iwasa <iku.iwasa@gmail.com>
;; URL:       https://github.com/iquiw/smart-semicolon
;; Package-Version: 20200909.1412
;; Package-Commit: 2c140accd576062f69dbe7db1d43ba038b347b9b
;; Version:   0.3.0
;; Package-Requires: ((emacs "26"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This is a minor mode to insert semicolon smartly, like Eclipse does.
;;
;; When `smart-semicolon-mode' is enabled, typing ";" inserts
;; semicolon at the end of line if there is no semicolon there.
;;
;; If there is semicolon at the end of line, typing ";" inserts
;; semicolon at the point.
;;
;; After smart semicolon insert, backspace command reverts the behavior
;; as if ";" is inserted normally.
;;
;; To enable it, add `smart-semicolon-mode' to some major mode hook.
;;
;;     (add-hook 'c-mode-common-hook #'smart-semicolon-mode)
;;

;;; Code:

(defgroup smart-semicolon nil
  "Smart Semicolon"
  :group 'editing)

(defcustom smart-semicolon-trigger-chars '(?\;)
  "List of characters that trigger smart semicolon behavior."
  :type '(repeat character))

(defcustom smart-semicolon-block-chars '(?\; ?\})
  "List of characters that block smart semicolon behavior if they are at eol."
  :type '(repeat character))

(defcustom smart-semicolon-backspace-commands
  '(backward-delete-char delete-backward-char c-electric-backspace)
  "List of commands that are treated as backspace command."
  :type '(repeat symbol))

(defvar smart-semicolon--last-change nil)
(defvar smart-semicolon--last-command nil)

(defun smart-semicolon-revert-move ()
  "Revert smart-semicolon behavior by backspace command.
If backspace command is called after smart semicolon insert,
it reverts smart semicolon behavior, that is, as if semicolon is inserted as is.

This function is to be called as `post-command-hook'.

Backspace command can be configured by `smart-semicolon-backspace-commands'."
  (cond
   ((and smart-semicolon--last-change
         (memq this-command smart-semicolon-backspace-commands))
    (pcase-let ((`(,ch ,origin ,dest) smart-semicolon--last-change))
      (when (eq (point) dest)
        (goto-char origin)
        (insert ch)
        (setq smart-semicolon--last-change nil))))
   ((not (eq this-command smart-semicolon--last-command))
    (setq smart-semicolon--last-change nil))))

(defun smart-semicolon-post-self-insert-function ()
  "Insert semicolon at appropriate place when it is typed."
  (setq smart-semicolon--last-command this-command)
  (when (and (eq (char-before) last-command-event)
             (memq last-command-event smart-semicolon-trigger-chars))
    (let ((origin (point))
          (ppss (syntax-ppss))
          dest)
      (unless (or (elt ppss 4)
                  (smart-semicolon--for-loop-hack))
        (end-of-line)
        (smart-semicolon--skip-comments-and-spaces origin)
        (setq dest (1- (point)))
        (if (memq (char-before) smart-semicolon-block-chars)
            (goto-char origin)
          (insert last-command-event)
          (save-excursion
            (goto-char origin)
            (delete-char -1))
          (setq smart-semicolon--last-change
                (list last-command-event (1- origin) dest)))))))

(defun smart-semicolon--for-loop-hack ()
  "Return non-nil if the line is started with keyword \"for\"."
  (save-excursion
    (let ((origin (point)))
      (beginning-of-line)
      (re-search-forward "\\_<for\\_>" origin t))))

(defun smart-semicolon--skip-comments-and-spaces (bound)
  "Skip comments and spaces before the point until BOUND position."
  (let (current prev)
    (while (and (> (setq current (point)) bound)
                (or (null prev) (/= prev current)))
      (let ((comment-start (or (smart-semicolon--comment-start current)
                               (smart-semicolon--comment-start (1- current)))))
        (if comment-start
            (goto-char comment-start)
          (goto-char current))
        (skip-chars-backward "[:blank:]"))
      (setq prev current))))

(defun smart-semicolon--comment-start (point)
  "Return position of comment start if POINT is in comment.
Otherwise, return nil."
  (let ((ppss (syntax-ppss point)))
    (and (nth 4 ppss)
         (nth 8 ppss))))

;;;###autoload
(define-minor-mode smart-semicolon-mode
  "Minor mode to insert semicolon smartly."
  :lighter " (;)"
  (if smart-semicolon-mode
      (progn
        (add-hook 'post-self-insert-hook
                  #'smart-semicolon-post-self-insert-function nil t)
        (add-hook 'post-command-hook
                  #'smart-semicolon-revert-move nil t))
    (remove-hook 'post-self-insert-hook
                 #'smart-semicolon-post-self-insert-function t)
    (remove-hook 'post-command-hook
                 #'smart-semicolon-revert-move t)))

(provide 'smart-semicolon)
;;; smart-semicolon.el ends here
