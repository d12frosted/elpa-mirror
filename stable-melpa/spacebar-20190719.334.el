;;; spacebar.el --- Workspaces Bar  -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Matthias Margush <matthias.margush@gmail.com>

;; Author: Matthias Margush <matthias.margush@gmail.com>
;; URL: https://github.com/matthias-margush/spacebar
;; Package-Version: 20190719.334
;; Package-Commit: 2b2cd0e786877273103f048e62a06b0027deca2d
;; Version: 0.0.2
;; Package-Requires: ((eyebrowse "0.7.7") (emacs "25.4.0"))
;; Keywords: convenience

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Provides a tab bar for managing workspaces, using eyebrowse.

;; See the README for more info:
;; https://github.com/matthias-margush/spacebar

;;; Code:



;;; variables

(require 'eyebrowse)
(require 'seq)
(require 'subr-x)

(declare-function evil-ex-define-cmd "ext:evil-ex.el" '(cmd function) t)
(declare-function projectile-project-name "ext:projectile.el" nil t)

(defvar spacebar-mode-hook nil)

(defgroup spacebar nil
  "Vim-like tabs."
  :group 'convenience
  :prefix "spacebar-")

(defcustom spacebar-keymap-prefix (kbd "C-c C-w")
  "Prefix key for key-bindings."
  :type 'string)

(defvar spacebar-command-map
  (let ((map (make-sparse-keymap))
        (prefix-map (make-sparse-keymap)))
    (define-key prefix-map (kbd "<") #'spacebar-switch-prev)
    (define-key prefix-map (kbd ">") #'spacebar-switch)
    (define-key prefix-map (kbd "'") #'spacebar-switch-last)
    (define-key prefix-map (kbd "\"") #'spacebar-close)
    (define-key prefix-map (kbd ",") #'spacebar-rename)
    (define-key prefix-map (kbd ".") #'spacebar-switch)
    (define-key prefix-map (kbd "0") #'spacebar-switch-0)
    (define-key prefix-map (kbd "1") #'spacebar-switch-1)
    (define-key prefix-map (kbd "2") #'spacebar-switch-2)
    (define-key prefix-map (kbd "3") #'spacebar-switch-3)
    (define-key prefix-map (kbd "4") #'spacebar-switch-4)
    (define-key prefix-map (kbd "5") #'spacebar-switch-5)
    (define-key prefix-map (kbd "6") #'spacebar-switch-6)
    (define-key prefix-map (kbd "7") #'spacebar-switch-7)
    (define-key prefix-map (kbd "8") #'spacebar-switch-8)
    (define-key prefix-map (kbd "9") #'spacebar-switch-9)
    (define-key prefix-map (kbd "c") #'spacebar-open)
    (define-key prefix-map (kbd "C-c") #'spacebar-open)
    (define-key map spacebar-keymap-prefix prefix-map)
    map)
  "Key map for spacebar.")

(defcustom spacebar-active-label-format-string
  "[%s]"
  "Format string applied to the active space label."
  :type 'string)

(defcustom spacebar-inactive-label-format-string
  " %s "
  "Format string applied to the inactive space label."
  :type 'string)

(defcustom spacebar-perspective-label-format-string
  "⊣ %s ⊢ "
  "Format string applied to the perspective label."
  :type 'string)

(defcustom spacebar-deft-space-label
  "notes"
  "Label for space containing deft notes."
  :type 'string)

(defcustom spacebar-projectile-switch-project-action
  nil
  "Label for space containing deft notes."
  :type 'string)

(defcustom spacebar-window-height
  2
  "Spacebar top windows height expressed in lines."
  :type 'integer)

(defface spacebar-inactive
  '((t
     :inherit font-lock-keyword-face
     :weight normal
     :height 0.9
     :mouse-face default))
  "Face for inactive spacebar tabs."
  :group 'spacebar)

(defface spacebar-active
  '((t :inherit font-lock-keyword-face :weight bold :height 1.6))
  "Face for active spacebar tab."
  :group 'spacebar)

(defface spacebar-persp
  '((t :inherit font-lock-keyword-face :weight normal :height 1.0))
  "Face for perspective."
  :group 'spacebar)

;;;###autoload
(define-minor-mode spacebar-mode
  "Toggle 'spacebar mode'.

  This global minor mode provides a tab-like bar for workspaces."
  :keymap spacebar-command-map
  :global t
  (if spacebar-mode
      (spacebar--init)
    (spacebar--deinit)))


;;; functions
(defun spacebar--buffer-name (&optional frame)
  "Return the spacebar buffer name for FRAME, or the selected frame."
  (format " *spacebar* - %s" (or frame (selected-frame))))

(defun spacebar--perspective ()
  "Get the perspective name."
  (when (and (fboundp 'get-current-persp) (fboundp 'safe-persp-name))
    (format spacebar-perspective-label-format-string
            (safe-persp-name (get-current-persp)))))

(defvar spacebar--buffers nil "List of active spacebars.")
(defun spacebar--refresh (&optional frame)
  "Refresh the spacebar on FRAME.

If FRAME is not provided, refreshes the spacebar on the selected frame."
  (when spacebar-mode
    (with-current-buffer (get-buffer-create (spacebar--buffer-name frame))
      (add-to-list 'spacebar--buffers (current-buffer))
      ;; Fix up side window resizes
      (add-hook 'window-size-change-functions #'spacebar--window-size-changed)
      (set-frame-parameter nil 'spacebar--buffer (current-buffer))
      (setq-local window-size-fixed t)
      (read-only-mode)
      (let ((inhibit-read-only t)
            (current-space (eyebrowse--get 'current-slot))
            (spaces (eyebrowse--get 'window-configs)))
        (erase-buffer)
        (save-excursion
          (when-let ((persp (spacebar--perspective)))
            (put-text-property 0
                               (length persp)
                               'face 'spacebar-persp
                               persp)

            (insert persp))
          (dolist (space spaces)
            (let* ((activep (= current-space (spacebar--slot space)))
                   (space-name (spacebar--name space))
                   (label (spacebar--render-plain-text
                           activep
                           (spacebar--slot space)
                           space-name))
                   (click-map (make-sparse-keymap)))
              (when (not (string-empty-p space-name))
                (define-key click-map [mouse-2]
                  (lambda ()
                    (interactive)
                    (spacebar-switch (spacebar--slot space))))
                (define-key click-map [follow-link] 'mouse-face)
                (if activep
                    (put-text-property 0
                                       (length label)
                                       'face 'spacebar-active
                                       label)
                  (put-text-property 0
                                     (length label)
                                     'face 'spacebar-inactive
                                     label))
                (put-text-property 0
                                   (length label)
                                   'mouse-face 'default
                                   label)
                (put-text-property 0
                                   (length label)
                                   'keymap click-map
                                   label)
                (insert label)))))

        (display-buffer-in-side-window
         (current-buffer)
         `((side . top)
           (slot . 0)
           (window-height . ,spacebar-window-height)
           (preserve-size . (nil . t))
           (left-margin-width . 0)
           (right-margin-width . 0)
           (size-fixed . t)
           (window-parameters . ((no-other-window . t)
                                 (no-delete-other-windows . t)))))
        (setq mode-line-format nil)))))

(defun spacebar--window-size-changed (frame)
  "Keep spacebar window the same size on FRAME size change."
  (when-let ((buffer (frame-parameter frame 'spacebar--buffer))
             (window (get-buffer-window buffer)))
    (let* ((before (window-pixel-height-before-size-change window))
           (after (window-pixel-height window)))
      (when (not (frame-parameter frame 'spacebar--side-window-height))
        (set-frame-parameter frame 'spacebar--side-window-height after))
      (when-let ((height (frame-parameter frame 'spacebar--side-window-height)))
        (window-resize window (- height after) nil t t)))))

(defun spacebar--render-plain-text (activep _slot label)
  "Renders a tab label as plain text.

If ACTIVEP is true, the label is rendered as the active label.  SLOT
is the index of the space.  LABEL is the text to display."
  (if activep
      (format spacebar-active-label-format-string label)
    (format spacebar-inactive-label-format-string label)))

(defun spacebar--name (space)
  "Return the name of a SPACE."
  (caddr space))

(defun spacebar--config (space)
  "Return the eyebrowse configuration of a SPACE."
  (cdr space))

(defun spacebar--slot (space)
  "Return the slot (#) of a SPACE."
  (car space))

(defun spacebar--namedp (name)
  "Return a function that will take a space and check whether its name is NAME."
  (lambda (space)
    (string= name (spacebar--name space))))

(defun spacebar--named (name)
  "Find the space with the NAME."
  (seq-find (spacebar--namedp name) (eyebrowse--get 'window-configs)))

(defun spacebar--current-config ()
  "Get the active eyebrowse configuration."
  (assoc (eyebrowse--get 'current-slot)
         (eyebrowse--get 'window-configs)))

(defun spacebar-rename ()
  "Rename the active space."
  (interactive)
  (if (not spacebar-mode)
      (message "Spacebar mode is not enabled. M-x spacebar-mode to turn it on.")
    (let* ((space (spacebar--current-config))
           (name (read-string "Rename space: " (spacebar--name space))))
      (message "renaming to: %s" name)
      (eyebrowse-rename-window-config (spacebar--slot space) name)
      (spacebar--refresh))))

(defun spacebar-switch (space)
  "Switch to a space.

SPACE can be a slot number or name.

Returns t if already exists."
  (interactive "P")
  (if (not spacebar-mode)
      (message "Spacebar mode is not enabled. M-x spacebar-mode to turn it on.")
    (if (or (not space) (numberp space))
        (if space
            (if (< space 0)
                (eyebrowse-prev-window-config nil)
              (eyebrowse-switch-to-window-config
               (spacebar--slot (nth (1- space) (eyebrowse--get 'window-configs)))))
          (eyebrowse-next-window-config nil))
      (let ((space (spacebar--slot (spacebar--named space))))
        (when space
          (eyebrowse-switch-to-window-config space)
          (eyebrowse--get 'current-slot))))))

(defun spacebar-switch-prev ()
  "Switch to previous workspace."
  (interactive)
  (spacebar-switch -1))

(defun spacebar-switch-last ()
  "Switch to the last workspace."
  (interactive)
  (if (not spacebar-mode)
      (message "Spacebar mode is not enabled. M-x spacebar-mode to turn it on.")
    (eyebrowse-last-window-config)))

(defun spacebar-switch-0 ()
  "Switch to window configuration 0."
  (interactive)
  (spacebar-switch 0))

(defun spacebar-switch-1 ()
  "Switch to window configuration 1."
  (interactive)
  (spacebar-switch 1))

(defun spacebar-switch-2 ()
  "Switch to window configuration 2."
  (interactive)
  (spacebar-switch 2))

(defun spacebar-switch-3 ()
  "Switch to window configuration 3."
  (interactive)
  (spacebar-switch 3))

(defun spacebar-switch-4 ()
  "Switch to window configuration 4."
  (interactive)
  (spacebar-switch 4))

(defun spacebar-switch-5 ()
  "Switch to window configuration 5."
  (interactive)
  (spacebar-switch 5))

(defun spacebar-switch-6 ()
  "Switch to window configuration 6."
  (interactive)
  (spacebar-switch 6))

(defun spacebar-switch-7 ()
  "Switch to window configuration 7."
  (interactive)
  (spacebar-switch 7))

(defun spacebar-switch-8 ()
  "Switch to window configuration 8."
  (interactive)
  (spacebar-switch 8))

(defun spacebar-switch-9 ()
  "Switch to window configuration 9."
  (interactive)
  (spacebar-switch 9))

(defun spacebar-open (&optional name)
  "Open a new workspace with NAME."
  (interactive)
  (if (not spacebar-mode)
      (message "Spacebar mode is not enabled. M-x spacebar-mode to turn it on.")
    (let* ((name (or name (completing-read "Workspace: "
                                           (seq-map #'spacebar--name
                                                    (eyebrowse--get 'window-configs)))))
           (existsp (spacebar-switch name)))
      (unless existsp
        (unless (string= "" (spacebar--name (spacebar--current-config)))
          (eyebrowse-create-window-config))
        (eyebrowse-rename-window-config (eyebrowse--get 'current-slot) name)
        (spacebar--refresh))
      existsp)))

(defun spacebar-close ()
  "Close the active space."
  (interactive)
  (if (not spacebar-mode)
      (message "Spacebar mode is not enabled. M-x spacebar-mode to turn it on.")
    (eyebrowse-close-window-config)
    (spacebar--refresh)))

(defadvice persp-save-state-to-file
    (before spacebar--before-persp-save-state-to-file activate)
  "Disable spacebar before trying to save perspective."
  (spacebar-mode -1))

(defvar spacebar--original-cursor-in-non-selected-windows)
(defun spacebar--init ()
  "Initialize spacebar."
  (setq spacebar--original-cursor-in-non-selected-windows cursor-in-non-selected-windows)
  (setq-default cursor-in-non-selected-windows nil)
  (setq eyebrowse-mode-map nil)
  (setq eyebrowse-wrap-around t)
  (eyebrowse-mode)

  ;; Refresh spacebar view when switching eyebrowse windows
  (add-hook 'eyebrowse-post-window-switch-hook #'spacebar--refresh)

  ;; Refresh spacebar when switching perspectives
  (add-hook 'persp-activated-functions #'spacebar--activate-persp 1)

  ;; Refresh when reloading perspective
  (add-hook 'persp-after-load-state-functions #'spacebar--activate 1)

  (spacebar--activate))

(defun spacebar--deinit ()
  "Turn off spacebar."
  (setq cursor-in-non-selected-windows spacebar--original-cursor-in-non-selected-windows)
  ;; note: eyebrowse doesn't provide a way to turn off
  (remove-hook 'eyebrowse-post-window-switch-hook #'spacebar--refresh)
  (spacebar--deactivate))

(defun spacebar--activate (&rest _)
  "Refresh all frames."
  (dolist (frame (frame-list))
    (spacebar--refresh frame)))

(defun spacebar--activate-persp (type)
  "Refresh spacebar for perspective.

When added to the hook PERSP-ACTIVATED-FUNCTIONS, will be called with TYPE eq 'frame or 'window."
  (when (eq type 'frame)
    (spacebar--refresh (selected-frame))))

(defun spacebar--deactivate (&rest _)
  "Remove all spacebar buffers."
  (dolist (buffer spacebar--buffers)
    (kill-buffer buffer)))

(defvar evil-motion-state-map)

(defun spacebar-ensure-space (name init-function)
  "If a space with NAME exists, switch to it.

If it does not exist, creates it, switches to it, and initializes it
  with INIT-FUNCTION.  INIT-FUNCTION can be any function that takes no
  parameters."
  (unless (spacebar-open name)
    (delete-other-windows)
    (funcall init-function)))

(defun spacebar-open-space (name init-function)
  "If a space with NAME exists, switch to it and call INIT-FUNCTION.

If it does not exist, creates it, switches to it, and initializes it
  with INIT-FUNCTION.  INIT-FUNCTION can be any function that takes no
  parameters."
  (unless (spacebar-open name)
    (delete-other-windows))
  (funcall init-function))

(defvar spacebar--original-projectile-switch-project-action nil)

(defun spacebar-projectile-switch-project-action ()
  "Opens a space when opening a project."
  (spacebar-ensure-space (projectile-project-name)
                         spacebar--original-projectile-switch-project-action))

(defun spacebar-projectile-init ()
  "Create a space for each project."
  (if (boundp 'projectile-switch-project-action)
      (progn
        (unless (eq 'projectile-switch-project-action
                    'spacebar-projectile-switch-project-action)
          (setq spacebar--original-projectile-switch-project-action
                projectile-switch-project-action))

        (setq projectile-switch-project-action
              #'spacebar-projectile-switch-project-action)

        (with-eval-after-load 'projectile
          (defadvice projectile-kill-buffers
              (before close-projectile-spacebar activate)
            "Close space when projectile project is closed."
            (spacebar-close))))
    (message "spacebar: projectile is not installed")))

(defun spacebar-deft ()
  "Open a space with deft."
  (interactive)
  (if (not spacebar-mode)
      (message "Spacebar mode is not enabled. M-x spacebar-mode to turn it on.")
    (if (fboundp 'deft)
        (spacebar-open-space spacebar-deft-space-label #'deft)
      (message "spacebar: deft is not installed"))))

;;;###autoload
(defun spacebar-setup-evil-keys ()
  "Set up evil key bindings."
  (if (boundp 'evil-motion-state-map)
      (when spacebar-mode
        (define-key evil-motion-state-map (kbd "gt") #'spacebar-switch)
        (define-key evil-motion-state-map (kbd "gT") #'spacebar-switch-prev)
        (define-key evil-motion-state-map (kbd "g`") #'eyebrowse-last-window-config)
        (evil-ex-define-cmd "tabn[ext]" #'spacebar-switch)
        (evil-ex-define-cmd "tabp[revious]" #'spacebar-switch-prev)
        (evil-ex-define-cmd "tabN[ext]" #'spacebar-switch-prev)
        (evil-ex-define-cmd "tabr[ewind]" (lambda () (interactive) (spacebar-switch 1)))
        (evil-ex-define-cmd "tabf[irst]" (lambda () (interactive) (spacebar-switch 1)))
        (evil-ex-define-cmd "tabl[ast]" (lambda () (interactive) (spacebar-switch 1) (spacebar-switch-prev)))
        (evil-ex-define-cmd "tabnew" #'spacebar-open)
        (evil-ex-define-cmd "tabc[lose]" #'spacebar-close))
    (message "spacebar: evil needs to be installed to use evil keybindings.")))

;;;###autoload
(provide 'spacebar)
;;; spacebar.el ends here
