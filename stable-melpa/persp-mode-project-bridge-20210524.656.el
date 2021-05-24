;;; persp-mode-project-bridge.el --- Integration of persp-mode + project.el -*- lexical-binding: t -*-

;; Copyright (C) 2017 Constantin Kulikov
;; Copyright (C) 2021 Siavash Askari Nasr
;;
;; Author: Constantin Kulikov (Bad_ptr) <zxnotdead@gmail.com>
;;      Siavash Askari Nasr <siavash.askari.nasr@gmail.com>
;; Maintainer: Siavash Askari Nasr <siavash.askari.nasr@gmail.com>
;; Version: 0.1
;; Package-Version: 20210524.656
;; Package-Commit: c8a2b76c4972c1e00648def5a9b59a2942bd462a
;; Package-Requires: ((emacs "27.1") (persp-mode "2.9"))
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Keywords: vc, persp-mode, perspective, project, project.el
;; URL: https://github.com/CIAvash/persp-mode-project-bridge

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

;; Creates a perspective for each project.el project.  (Based on the persp-mode-projectile-bridge)

;;; Usage:

;; Installation:

;; M-x package-install-file RET persp-mode-project-bridge RET

;; Example configuration:

;; (with-eval-after-load "persp-mode-project-bridge-autoloads"
;;   (add-hook 'persp-mode-project-bridge-mode-hook
;;             (lambda ()
;;                 (if persp-mode-project-bridge-mode
;;                     (persp-mode-project-bridge-find-perspectives-for-all-buffers)
;;                   (persp-mode-project-bridge-kill-perspectives))))
;;   (add-hook 'after-init-hook
;;             (lambda ()
;;                 (persp-mode-project-bridge-mode 1))
;;             t))


;;; Code:


(require 'persp-mode)
(require 'project)
(require 'cl-lib)

(declare-function project-root "project")

(defvar persp-mode-project-bridge-mode nil)

(defgroup persp-mode-project-bridge nil
  "persp-mode project.el integration."
  :group 'persp-mode
  :group 'project
  :prefix "persp-mode-project-bridge-"
  :link
  '(url-link
    :tag "Github" "https://github.com/CIAvash/persp-mode-project-bridge"))

(defcustom persp-mode-project-bridge-persp-name-prefix "[p] "
  "Prefix to use for project perspective names."
  :group 'persp-mode-project-bridge
  :type 'string
  :set (lambda (sym val)
         (if persp-mode-project-bridge-mode
             (let ((old-prefix (symbol-value sym)))
               (custom-set-default sym val)
               (let (old-name)
                 (mapc (lambda (p)
                         (when (and
                                p (persp-parameter
                                   'persp-mode-project-bridge p))
                           (setq old-name
                                 (substring (persp-name p)
                                            (string-width old-prefix)))
                           (persp-rename (concat val old-name) p)))
                       (persp-persps))))
           (custom-set-default sym val))))


(defun persp-mode-project-bridge-add-new-persp (name)
  "Create a new perspective NAME."
  (let ((persp (persp-get-by-name name *persp-hash* :nil)))
    (if (eq :nil persp)
        (prog1
            (setq persp (persp-add-new name))
          (when persp
            (set-persp-parameter 'persp-mode-project-bridge t persp)
            (set-persp-parameter 'dont-save-to-file t persp)
            (persp-add-buffer (cl-remove-if-not #'get-file-buffer (project-files (project-current)))
                              persp nil nil)))
      persp)))

(defun persp-mode-project-bridge-find-perspective-for-buffer (b)
  "Find a perspective for buffer B."
  (when (buffer-live-p b)
    (with-current-buffer b
      (when (and persp-mode-project-bridge-mode
                 (buffer-name b) (project-current))
        (let ((persp (persp-mode-project-bridge-add-new-persp
                      (concat persp-mode-project-bridge-persp-name-prefix
                              (file-name-nondirectory
                               (directory-file-name
                                (if (fboundp 'project-root)
                                    (project-root (project-current))
                                  (car (project-roots (project-current))))))))))
          (when persp
            (persp-add-buffer b persp nil nil)
            persp))))))

(defun persp-mode-project-bridge-hook-switch (&rest _args)
  "Switch to a perspective when hook is activated."
  (let ((persp
         (persp-mode-project-bridge-find-perspective-for-buffer
          (current-buffer))))
    (when persp
      (persp-frame-switch (persp-name persp)))))

(defun persp-mode-project-bridge-find-perspectives-for-all-buffers ()
  "Find perspectives for all buffers."
  (when persp-mode-project-bridge-mode
    (mapc #'persp-mode-project-bridge-find-perspective-for-buffer
          (buffer-list))))

(defun persp-mode-project-bridge-kill-perspectives ()
  "Kill all bridge perspectives."
  (when persp-mode
    (mapc #'persp-kill
          (mapcar #'persp-name
                  (cl-delete-if-not
                   (apply-partially
                    #'persp-parameter
                    'persp-mode-project-bridge)
                   (persp-persps))))))

(defvar persp-mode-project-bridge-switch-hooks
  (list 'find-file-hook 'dired-mode-hook 'vc-dir-mode-hook 'eshell-mode-hook))

;;;###autoload
(define-minor-mode persp-mode-project-bridge-mode
  "`persp-mode' and `project.el' integration.
Creates perspectives for project.el projects."
  :require 'persp-mode-project-bridge
  :group 'persp-mode-project-bridge
  :init-value nil
  :global t

  (if persp-mode-project-bridge-mode
      (if persp-mode
          (progn
            ;; Add hooks
            (add-hook 'persp-mode-hook
                      (lambda ()
                        (unless persp-mode
                          (persp-mode-project-bridge-mode -1))))
            (dolist (hook persp-mode-project-bridge-switch-hooks)
              (add-hook hook #'persp-mode-project-bridge-hook-switch)))
        (message "You can not enable persp-mode-project-bridge-mode \
unless persp-mode is active.")
        (setq persp-mode-project-bridge-mode nil))
    ;; Remove hooks
    (dolist (hook persp-mode-project-bridge-switch-hooks)
      (remove-hook hook #'persp-mode-project-bridge-hook-switch))))

(provide 'persp-mode-project-bridge)

;;; persp-mode-project-bridge.el ends here
