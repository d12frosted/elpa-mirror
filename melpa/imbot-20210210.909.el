;;; imbot.el --- Automatic system input method switcher -*- lexical-binding: t; -*-

;; URL: https://github.com/QiangF/imbot
;; Package-Version: 20210210.909
;; Package-Commit: 4083ad2e5a840467668a7c2fb809177726a7c519
;; Created: July 24th, 2020
;; Keywords: convenience
;; Package-Requires: ((emacs "25.1"))
;; Version: 3.0

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;;; Commentary:
;; imbot is inspired by https://github.com/laishulu/emacs-smart-input-source
;; usage:
;; emacs uses xim, make sure environment variables are set correctly, in case of ibus, eg:
;; export XIM="ibus"
;; export XIM_PROGRAM="ibus"
;; ibus is slow in restoring application im state, make sure to share ibus state in all apllications 
;; 1. redefine these functions according to your input method manager:
;;    imbot--active-p, imbot--activate, imbot--deactivate
;; 2. disable inline english with:
;;    (delq 'imbot--english-p imbot--suppression-predicates)
;; 3. the key to exit inline english is return
;; 4. add imbot-mode to relevant startup hooks, eg:
;;    (add-hook 'evil-mode-hook 'imbot-mode)

;;; Code:

(require 'seq)

(defvar imbot--active-saved nil
  "Buffer local input method state, changes only at manual input method toggling.")

(make-variable-buffer-local 'imbot--active-saved)

(defvar imbot--active-checked nil
  "True input method state checked at pre-command-hook, is t whenever input method is active.")

;; For fcitx, the command is "fcitx-remote"
(defvar imbot-command "/usr/bin/ibus engine"
  "Input method management command.")

;; For fcitx, the tag is "1"
(defvar imbot-english-engine-tag "xkb:us::eng"
  "Tag for the english engine.")

;; For fcitx the switch is "-o"
(defvar imbot-input-activate-switch "rime"
  "Switch for the non english engine.")

;; For fcitx the switch is "-c"
(defvar imbot-input-deactivate-switch "xkb:us::eng"
  "Switch for the english engine.")

(defun imbot--active-p ()
  "Return t when input method is active (in non English state)."
  (with-temp-buffer
    (call-process imbot-command nil t)
    (not (string-equal (string-trim (buffer-string))
                       imbot-english-engine-tag))))

(defun imbot--activate ()
  "Set input method in non English state."
  (unless imbot--active-checked
    (setq imbot--active-checked t)
    (call-process imbot-command nil nil nil imbot-input-activate-switch)))

(defun imbot--deactivate ()
  "Set input method in English state."
  (when imbot--active-checked
    (setq imbot--active-checked nil)
    (call-process imbot-command nil nil nil imbot-input-deactivate-switch)))

(defun imbot--update-cursor ()
  "Set cursor color according to input method state."
  (if imbot--active-checked
      (set-cursor-color "green")
      (set-cursor-color "white")))

;; disable imbot-mode before looking up key definition start with imbot--prefix-override-keys
(defvar imbot--prefix-override-keys
  '("C-c" "C-x" "C-h" "<f1>")
  "Prefix keys not handled by input method, which disable input method temperarily.")

(defvar imbot--prefix-override-map-alist nil
  "An `emulation-mode-map-alists keymap.")

(let ((keymap (make-sparse-keymap)))
  (dolist (prefix
           imbot--prefix-override-keys)
    (define-key keymap (kbd prefix)
      #'imbot--prefix-override-handler))
  (setq imbot--prefix-override-map-alist
        `((imbot--active-checked . ,keymap))))

(defun imbot--prefix-override-add (&optional _args)
  "Setup `emulation-mode-map-alist."
  (add-to-list 'emulation-mode-map-alists 'imbot--prefix-override-map-alist))

(defun imbot--prefix-override-remove (&optional _args)
  "Unset `emulation-mode-map-alist."
  (setq emulation-mode-map-alists
        (delq 'imbot--prefix-override-map-alist emulation-mode-map-alists)))

(defvar imbot--prefix-reinstate-triggers
  '(evil-local-mode yas-minor-mode eaf-mode)
  "Handle modes that mess `emulation-mode-map-alists.")

(defun imbot--prefix-override-handler (arg)
  "Prefix key handler with ARG."
  (interactive "P")
  (let* ((keys (this-command-keys)))
    (imbot--deactivate)
    ;; Restore the prefix arg
    (setq prefix-arg arg)
    (setq last-command 'imbot--prefix-override-handler)
    (prefix-command-preserve-state)
    ;; Push the key back on the event queue
    (setq unread-command-events
          (append (mapcar (lambda (e) `(t . ,e)) (listify-key-sequence keys))
                  unread-command-events))))

(defvar imbot--overlay nil
  "Inline english overlay.")

(defface imbot--inline-face '()
  "Face to show inline english (input method temperarily disabled) is active."
  :group 'imbot)

(set-face-attribute
 'imbot--inline-face nil
 :foreground (face-attribute 'font-lock-constant-face :foreground)
 :inverse-video t)

(defun imbot--english-region-p ()
  "Buffer is in `prog-mode or `conf-mode, and buffer string is not in a string or comment."
  (when (derived-mode-p 'prog-mode 'conf-mode)
    (not (or (nth 3 (syntax-ppss))
             (nth 4 (syntax-ppss))))))

(defun imbot--delete-overlay ()
  (delete-overlay imbot--overlay)
  (setq imbot--overlay nil))

(defun imbot--english-context-p ()
  "Return t if English should be inputed at cursor point."
  (unless (eq last-command 'imbot--inline-english-deactivate)
    (let* ((line-beginning (line-beginning-position))
           (point (point))
           (overlay-active (overlayp imbot--overlay))
           (english-context
             (or
              ;; 中文后面紧接1个空格切换到英文输入
              ;; \cC represents any character of category “C”, according to “M-x describe-categories”
              (looking-back "\\cc " (max line-beginning (- point 2)))
              (string-match "^\\s-*[0-9]+$" (buffer-substring-no-properties line-beginning point))
              (looking-back "[a-zA-Z\\-\\*]" (max line-beginning (1- point))))))
      (if overlay-active
          (if english-context
              (progn (move-overlay imbot--overlay line-beginning (line-end-position))
                     t)
              (progn (imbot--delete-overlay)
                     nil))
          (if (and imbot--active-checked english-context)
              (progn (setq imbot--overlay (make-overlay line-beginning (line-end-position) nil t t ))
                     (overlay-put imbot--overlay 'face 'imbot--inline-face)
                     (overlay-put imbot--overlay 'keymap
                                  (let ((keymap (make-sparse-keymap)))
                                    (define-key keymap (kbd "RET")
                                      #'imbot--inline-english-deactivate)
                                    (define-key keymap (kbd "<return>")
                                      #'imbot--inline-english-deactivate)
                                    keymap))
                     t)
              nil)))))

(defun imbot--inline-english-deactivate ()
  "Deactivate the inline english overlay."
  (interactive)
  (imbot--delete-overlay)
  (imbot--activate))

(defun imbot--english-p ()
  "Check context."
  (when imbot--active-saved
    (or (imbot--english-region-p)
        (imbot--english-context-p))))

(defvar evil-normal-state-minor-mode)

(defvar evil-visual-state-minor-mode)

(defvar evil-motion-state-minor-mode)

(defvar god-local-mode)

(defvar hydra-curr-map)

(defvar imbot--suppression-watch-list
  '(evil-normal-state-minor-mode
    evil-visual-state-minor-mode
    evil-motion-state-minor-mode
    god-local-mode
    hydra-curr-map)
  "Enable suppression if any variables in this list is t.")

(defvar imbot--suppression-major-mode
  '(dired-mode debugger-mode)
  "Enable suppression if buffer's major-mode matches any element of this list.")

(defun imbot--prefix-override-p ()
  "This-command becomes non nil after prefix sequence completion."
  (or (equal last-command 'imbot--prefix-override-handler)
      (equal real-this-command 'imbot--prefix-override-handler)))

(defvar imbot--suppression-predicates
  (list #'imbot--english-p #'imbot--prefix-override-p)
  "Conditions in which input method should be suppressed, in order of priority.")

(defvar imbot--suppressed nil
  "Buffer local suppression state.")

(make-variable-buffer-local 'imbot--suppressed)

(defvar imbot--active-omit-check nil
  "Omit setting imbot--active-checked when t.

Checking at every command execution may cause the pre-command-function removed from pre-command-hook
due to possible errors, so setting with emacsclient on im state change via hotkey outside emacs
may be a better solution.")

(defun imbot--pre-command-check ()
  "Update imbot--active-checked."
  (setq imbot--active-checked (imbot--active-p)))

(defun imbot--pre-command-function ()
  "Update imbot--active-saved."
  (unless imbot--active-omit-check
    (add-hook 'post-command-hook #'imbot--post-command-function -100)
    (imbot--pre-command-check))
  (unless imbot--suppressed
    (setq imbot--active-saved imbot--active-checked)))

(defun imbot--post-command-function ()
  "Restore input state."
  ;; When an editing command returns to the editor command loop, the buffer is still the original
  ;; buffer, buffer change after Emacs automatically calls set-buffer on the buffer shown in the
  ;; selected window.
  (run-with-timer 0 nil
                  (lambda ()
                    (when imbot--active-saved
                      (if (or (eval `(or ,@imbot--suppression-watch-list))
                              (seq-find 'funcall imbot--suppression-predicates nil)
                              (member major-mode imbot--suppression-major-mode))
                          (progn (setq imbot--suppressed t)
                                 (imbot--deactivate))
                          ;; restore input state
                          (imbot--activate)
                          (setq imbot--suppressed nil)))
                    (add-hook 'pre-command-hook #'imbot--pre-command-function -100)
                    (imbot--update-cursor))))

(defvar imbot-pre-command-hook-list '(pre-command-hook)
  "List of hook names to add imbot--pre-command functions into.")

(defvar imbot-post-command-hook-list '(post-command-hook dired-mode-hook)
  "List of hook names to add `imbot--post-command-function into.")

(defun imbot--hook-handler (add-or-remove)
  "Setup hooks, ADD-OR-REMOVE."
  (funcall add-or-remove 'minibuffer-setup-hook 'imbot--deactivate)
  (dolist (hook-name imbot-pre-command-hook-list)
    (funcall add-or-remove hook-name #'imbot--pre-command-function))
  (dolist (hook-name imbot-post-command-hook-list)
    (funcall add-or-remove hook-name #'imbot--post-command-function)))

;;;###autoload
(define-minor-mode imbot-mode
  "Input method managing bot."
  :global t
  :init-value nil
  (if imbot-mode
      (progn
        (imbot--hook-handler 'add-hook)
        (imbot--prefix-override-add)
        (dolist (trigger imbot--prefix-reinstate-triggers)
          (advice-add trigger :after #'imbot--prefix-override-add)))
      (imbot--hook-handler 'remove-hook)
      (imbot--prefix-override-remove)
      (dolist (trigger imbot--prefix-reinstate-triggers)
        (advice-remove trigger #'imbot--prefix-override-add))))

(provide 'imbot)
;;; imbot.el ends here
