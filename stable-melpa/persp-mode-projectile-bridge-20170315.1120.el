;;; persp-mode-projectile-bridge.el --- persp-mode + projectile integration. -*- lexical-binding: t -*-

;; Copyright (C) 2017 Constantin Kulikov
;;
;; Author: Constantin Kulikov (Bad_ptr) <zxnotdead@gmail.com>
;; Version: 0.1
;; Package-Version: 20170315.1120
;; Package-Commit: f6453cd7b8b4352c06e771706f2c5b7e2cdff1ce
;; Package-Requires: ((persp-mode "2.9") (projectile "0.13.0") (cl-lib "0.5"))
;; Date: 2017/03/04 10:10:41
;; License: GPL either version 3 or any later version
;; Keywords: persp-mode, projectile
;; URL: https://github.com/Bad-ptr/persp-mode-projectile-bridge.el

;;; License:

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; Creates a perspective for each projectile project.

;;; Usage:

;; Installation:

;; M-x package-install-file RET persp-mode-projectile-bridge.el RET

;; Example configuration:

;; (with-eval-after-load "persp-mode-projectile-bridge-autoloads"
;;   (add-hook 'persp-mode-projectile-bridge-mode-hook
;;             #'(lambda ()
;;                 (if persp-mode-projectile-bridge-mode
;;                     (persp-mode-projectile-bridge-find-perspectives-for-all-buffers)
;;                   (persp-mode-projectile-bridge-kill-perspectives))))
;;   (add-hook 'after-init-hook
;;             #'(lambda ()
;;                 (persp-mode-projectile-bridge-mode 1))
;;             t))


;;; Code:


(require 'persp-mode)
(require 'projectile)
(require 'cl-lib)


(defvar persp-mode-projectile-bridge-mode nil)

(defgroup persp-mode-projectile-bridge nil
  "persp-mode projectile integration."
  :group 'persp-mode
  :group 'projectile
  :prefix "persp-mode-projectile-bridge-"
  :link
  '(url-link
    :tag "Github" "https://github.com/Bad-ptr/persp-mode-projectile-bridge.el"))

(defcustom persp-mode-projectile-bridge-persp-name-prefix "[p] "
  "Prefix to use for projectile perspective names."
  :group 'persp-mode-projectile-bridge
  :type 'string
  :set #'(lambda (sym val)
           (if persp-mode-projectile-bridge-mode
               (let ((old-prefix (symbol-value sym)))
                 (custom-set-default sym val)
                 (let (old-name)
                   (mapc #'(lambda (p)
                             (when (and
                                    p (persp-parameter
                                       'persp-mode-projectile-bridge p))
                               (setq old-name
                                     (substring (persp-name p)
                                                (string-width old-prefix)))
                               (persp-rename (concat val old-name) p)))
                         (persp-persps))))
             (custom-set-default sym val))))


(defun persp-mode-projectile-bridge-add-new-persp (name)
  (let ((persp (persp-get-by-name name *persp-hash* :nil)))
    (if (eq :nil persp)
        (prog1
            (setq persp (persp-add-new name))
          (when persp
            (set-persp-parameter 'persp-mode-projectile-bridge t persp)
            (set-persp-parameter 'dont-save-to-file t persp)
            (persp-add-buffer (projectile-project-buffers)
                              persp nil nil)))
      persp)))

(defun persp-mode-projectile-bridge-find-perspective-for-buffer (b)
  (when (buffer-live-p b)
    (with-current-buffer b
      (when (and persp-mode-projectile-bridge-mode
                 (buffer-file-name b) (projectile-project-p))
        (let ((persp (persp-mode-projectile-bridge-add-new-persp
                      (concat persp-mode-projectile-bridge-persp-name-prefix
                              (projectile-project-name)))))
          (when persp
            (persp-add-buffer b persp nil nil)
            persp))))))

(defvar persp-mode-projectile-bridge-before-switch-selected-window-buffer nil)
(defun persp-mode-projectile-bridge-hook-before-switch (&rest _args)
  (let ((win (if (minibuffer-window-active-p (selected-window))
                 (minibuffer-selected-window)
               (selected-window))))
    (when (window-live-p win)
      (setq persp-mode-projectile-bridge-before-switch-selected-window-buffer
            (window-buffer win)))))

(defun persp-mode-projectile-bridge-hook-switch (&rest _args)
  (let ((persp
         (persp-mode-projectile-bridge-find-perspective-for-buffer
          (current-buffer))))
    (when persp
      (when (buffer-live-p
             persp-mode-projectile-bridge-before-switch-selected-window-buffer)
        (let ((win (selected-window)))
          (unless (eq (window-buffer win)
                      persp-mode-projectile-bridge-before-switch-selected-window-buffer)
            (set-window-buffer
             win persp-mode-projectile-bridge-before-switch-selected-window-buffer)
            (setq persp-mode-projectile-bridge-before-switch-selected-window-buffer nil))))
      (persp-frame-switch (persp-name persp)))))

(defun persp-mode-projectile-bridge-hook-find-file (&rest _args)
  (let ((persp
         (persp-mode-projectile-bridge-find-perspective-for-buffer
          (current-buffer))))
    (when persp
      (persp-add-buffer (current-buffer) persp nil nil))))

(defun persp-mode-projectile-bridge-find-perspectives-for-all-buffers ()
  (when (and persp-mode-projectile-bridge-mode)
    (mapc #'persp-mode-projectile-bridge-find-perspective-for-buffer
          (buffer-list))))

(defun persp-mode-projectile-bridge-kill-perspectives ()
  (when (and persp-mode projectile-mode)
    (mapc #'persp-kill
          (mapcar #'persp-name
                  (cl-delete-if-not
                   (apply-partially
                    #'persp-parameter
                    'persp-mode-projectile-bridge)
                   (persp-persps))))))


;;;###autoload
(define-minor-mode persp-mode-projectile-bridge-mode
  "`persp-mode' and `projectile-mode' integration.
Creates perspectives for projectile projects."
  :require 'persp-mode-projectile-bridge
  :group 'persp-mode-projectile-bridge
  :init-value nil
  :global t

  (if persp-mode-projectile-bridge-mode
      (if (and persp-mode projectile-mode)
          (progn
            (add-hook 'find-file-hook
                      #'persp-mode-projectile-bridge-hook-find-file)
            (add-hook 'projectile-mode-hook
                      #'(lambda ()
                          (unless projectile-mode
                            (persp-mode-projectile-bridge-mode -1))))
            (add-hook 'persp-mode-hook
                      #'(lambda ()
                          (unless persp-mode
                            (persp-mode-projectile-bridge-mode -1))))
            (add-hook 'projectile-before-switch-project-hook
                      #'persp-mode-projectile-bridge-hook-before-switch)
            (add-hook 'projectile-after-switch-project-hook
                      #'persp-mode-projectile-bridge-hook-switch)
            (add-hook 'projectile-find-file-hook
                      #'persp-mode-projectile-bridge-hook-switch))
        (message "You can not enable persp-mode-projectile-bridge-mode \
unless persp-mode and projectile-mode are active.")
        (setq persp-mode-projectile-bridge-mode nil))
    (remove-hook 'find-file-hook
                 #'persp-mode-projectile-bridge-hook-find-file)
    (remove-hook 'projectile-before-switch-project-hook
                 #'persp-mode-projectile-bridge-hook-before-switch)
    (remove-hook 'projectile-after-switch-project-hook
                 #'persp-mode-projectile-bridge-hook-switch)
    (remove-hook 'projectile-find-file-hook
                 #'persp-mode-projectile-bridge-hook-switch)))


(provide 'persp-mode-projectile-bridge)

;;; persp-mode-projectile-bridge.el ends here
