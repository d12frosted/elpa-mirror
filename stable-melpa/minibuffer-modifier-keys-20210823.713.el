;;; minibuffer-modifier-keys.el --- Use spacebar as a modifier key in the minibuffer -*- lexical-binding: t -*-

;; Author: SpringHan
;; Maintainer: SpringHan
;; Version: 1.0
;; Package-Version: 20210823.713
;; Package-Commit: 38da548225f51ca7bca22d3e9b0de78e3b9e6cdd
;; Package-Requires: ((emacs "24.3"))
;; Homepage: https://github.com/SpringHan/minibuffer-modifier-keys.git
;; Keywords: tools


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; A package allows you to avoid Ctrl,Meta in minibuffer

;; You can use (minibuffer-modifier-keys-setup t) to enable this package.
;; Or use (minibuffer-modifier-keys-setup nil) to disable it.

;;; Code:

(defcustom minibuffer-modifier-keys-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap self-insert-command] 'minibuffer-modifier-keys-self-insert)
    (define-key map (kbd "SPC") 'minibuffer-modifier-keys-start-or-stop)
    map)
  "The keymap for minibuffer-keypad state."
  :type 'keymap
  :group 'minibuffer-modifier-keys)

(defcustom minibuffer-modifier-keys-prefix "C-"
  "The prefix for minibuffer-keypad."
  :type 'string
  :group 'minibuffer-modifier-keys)

;;;###autoload
(define-minor-mode minibuffer-modifier-keys
  "Minibuffer keypad mode."
  nil nil minibuffer-modifier-keys-map)

(defun minibuffer-modifier-keys-setup (enable)
  "Setup or disable minibuffer-modifier-keys.
Enable the mode when ENABLE is non-nil."
  (if enable
      (add-hook 'minibuffer-setup-hook
                (lambda ()
                  (define-key (current-local-map) (kbd "SPC") #'minibuffer-modifier-keys-start-or-stop)))
    (remove-hook 'minibuffer-setup-hook
                 (lambda ()
                   (define-key (current-local-map) (kbd "SPC") #'minibuffer-modifier-keys-start-or-stop)))))

(defun minibuffer-modifier-keys--index (ele list)
  "Get the index of ELE in LIST."
  (catch 'result
    (dotimes (i (length list))
      (when (equal (nth i list) ele)
        (throw 'result i)))))

(defun minibuffer-modifier-keys--convert-prefix (prefix)
  "Convert PREFIX from string to char or from char to string."
  (let* ((prefix-string '("C-" "M-" "C-M-"))
         (prefix-char '(?, ?. ?/))
         (from (if (stringp prefix)
                   prefix-string
                 prefix-char))
         (to (if (stringp prefix)
                 prefix-char
               prefix-string))
         index)
    (setq index (minibuffer-modifier-keys--index prefix from))
    (when index
      (nth index to))))

(defun minibuffer-modifier-keys-keypad (external-char &optional no-convert)
  "Execute the keypad command.
EXTERNAL-CHAR is the entrance for minibuffer-keypad mode.
NO-CONVERT means not to convert the EXTERNAL-CHAR to prefix."
  (interactive)
  (let* ((prefix-used-p nil)
         (key (when (and (null no-convert)
                         (memq external-char '(?, ?. ?/))
                         (/= (minibuffer-modifier-keys--convert-prefix
                              minibuffer-modifier-keys-prefix)
                             external-char))
                (setq-local minibuffer-modifier-keys-prefix
                            (minibuffer-modifier-keys--convert-prefix external-char))
                (setq external-char t
                      prefix-used-p t)))
         tmp command)
    (unless (stringp key)
      (setq key (concat minibuffer-modifier-keys-prefix
                        (when (numberp external-char)
                          (concat (char-to-string external-char) " ")))))

    (message key)
    (catch 'stop
      (when (and (numberp external-char)
                 (commandp (setq command (key-binding (read-kbd-macro (substring key 0 -1))))))
        (throw 'stop nil))
      (while (setq tmp (read-char))
        (if (= tmp 127)
            (setq key (substring key 0 -2))
          (when (= tmp 59)
            (keyboard-quit))
          (setq key (concat key
                            (cond ((and (= tmp ?,)
                                        (null prefix-used-p))
                                   (setq prefix-used-p t)
                                   "C-")
                                  ((and (= tmp ?.)
                                        (null prefix-used-p))
                                   (setq prefix-used-p t)
                                   "M-")
                                  ((and (= tmp ?/)
                                        (null prefix-used-p))
                                   (setq prefix-used-p t)
                                   "C-M-")
                                  ((= tmp 32)
                                   (setq prefix-used-p t)
                                   "")
                                  (t
                                   (when prefix-used-p
                                     (setq prefix-used-p nil))
                                   (concat (char-to-string tmp) " "))))))
        (message key)
        (when (commandp (setq command (key-binding (read-kbd-macro (substring key 0 -1)))))
          (throw 'stop nil))))
    (call-interactively command)))

(defun minibuffer-modifier-keys-start-or-stop ()
  "Start or stop the minibuffer-keypad mode."
  (interactive)
  (if current-input-method
      (if (and (= (char-before) 32)
               (not (= (point) (line-beginning-position))))
          (progn
            (minibuffer-modifier-keys (if minibuffer-modifier-keys
                                          -1
                                        t))
            (call-interactively (key-binding (read-kbd-macro (char-to-string 127)))))
        (self-insert-command 1 32))
    (self-insert-command 1 32)
    (let ((char (read-char)))
      (if (= 32 char)
          (progn
            (minibuffer-modifier-keys (if minibuffer-modifier-keys
                                          -1
                                        t))
            (call-interactively (key-binding (read-kbd-macro (char-to-string 127)))))
        (if (and minibuffer-modifier-keys
                 (memq char '(?, ?. ?/)))
            (progn
              (call-interactively (key-binding (read-kbd-macro (char-to-string 127))))
              (minibuffer-modifier-keys-keypad char t))
          (minibuffer-modifier-keys-self-insert))))))

(defun minibuffer-modifier-keys-self-insert ()
  "The function to insert the input key or execute the function."
  (interactive)
  (if minibuffer-modifier-keys
      (minibuffer-modifier-keys-keypad last-input-event)
    (if (or (symbolp last-input-event)
            (< last-input-event 33)
            (> last-input-event 126))
        (let (command)
          (if (commandp (setq command
                              (key-binding
                               (vector last-input-event))))
              (let ((last-command-event last-input-event))
                (ignore-errors
                  (call-interactively command)))
            (execute-kbd-macro (vector last-input-event))))
      (let ((last-command-event last-input-event))
        (call-interactively #'self-insert-command)))))

(provide 'minibuffer-modifier-keys)

;;; minibuffer-modifier-keys.el ends here
