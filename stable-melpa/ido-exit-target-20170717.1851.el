;;; ido-exit-target.el --- Commands and keys for selecting other window and frame targets within ido

;; Copyright (C) 2015 justin talbott

;; Author: justin talbott <justin@waymondo.com>
;; Keywords: convenience, tools, extensions
;; Package-Version: 20170717.1851
;; Package-Commit: e56fc6928649c87ccf39d56d84ab53ebaced1f73
;; URL: https://github.com/waymondo/ido-exit-target
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4"))
;; Filename: ido-exit-target.el
;; License: GNU General Public License version 3, or (at your option) any later version
;;

;;; Commentary:
;;

;;; Code:

(require 'ido)
(require 'nadvice)

(eval-when-compile
  (defvar ido-exit-target--target))

(defun ido-exit-target-one-window ()
  "Select the current `ido' item to fill the entire frame."
  (interactive)
  (setq ido-exit-target--target 'one-window)
  (ido-exit-minibuffer))

(defun ido-exit-target-split-window-below ()
  "Select the current `ido' item for a new window below."
  (interactive)
  (setq ido-exit-target--target 'split-window-below)
  (ido-exit-minibuffer))

(defun ido-exit-target-split-window-right ()
  "Select the current `ido' item for a new window to the right."
  (interactive)
  (setq ido-exit-target--target 'split-window-right)
  (ido-exit-minibuffer))

(defun ido-exit-target-other-window ()
  "Select the current `ido' item for `other-window'. It will create one if it doesn't exist."
  (interactive)
  (setq ido-exit-target--target 'other-window)
  (ido-exit-minibuffer))

(defun ido-exit-target-other-frame ()
  "Select the current `ido' item for `other-frame'. It will create one if it doesn't exist."
  (interactive)
  (setq ido-exit-target--target 'other-frame)
  (ido-exit-minibuffer))

(defun ido-exit-target--switch-to-target (orig-fun &rest args)
  "Advise `ido-read-internal' on where to view the chosen selection."
  (let* (ido-exit-target--target
         (res (apply orig-fun args)))
    (cond
     ((equal ido-exit-target--target 'other-window)
      (switch-to-buffer-other-window nil))
     ((equal ido-exit-target--target 'one-window)
      (delete-other-windows))
     ((equal ido-exit-target--target 'split-window-below)
      (split-window-below)
      (other-window 1))
     ((equal ido-exit-target--target 'split-window-right)
      (split-window-right)
      (other-window 1))
     ((equal ido-exit-target--target 'other-frame)
      (switch-to-buffer-other-frame nil)))
    res))

(advice-add 'ido-read-internal :around #'ido-exit-target--switch-to-target)

(defgroup ido-exit-target nil
  "Commands and keys for selecting other window and frame targets within ido."
  :group 'tools
  :group 'convenience)

(defcustom ido-exit-target-keymap-prefix (kbd "<C-return>")
  "Keymap prefix for ido exit targets."
  :group 'ido-exit-target
  :type 'string)

(defvar ido-exit-target-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "1") 'ido-exit-target-one-window)
    (define-key map (kbd "2") 'ido-exit-target-split-window-below)
    (define-key map (kbd "3") 'ido-exit-target-split-window-right)
    (define-key map (kbd "4") 'ido-exit-target-other-window)
    (define-key map (kbd "5") 'ido-exit-target-other-frame)
    (define-key map (kbd "o") 'ido-exit-target-other-window)
    map)
  "Keymap for commands after `ido-exit-target-keymap-prefix'.")

(fset 'ido-exit-target-command-map ido-exit-target-command-map)

(define-key ido-common-completion-map ido-exit-target-keymap-prefix 'ido-exit-target-command-map)

(provide 'ido-exit-target)
;;; ido-exit-target.el ends here
