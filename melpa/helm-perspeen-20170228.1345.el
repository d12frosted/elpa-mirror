;;; helm-perspeen.el --- Helm interface for perspeen.

;; Copyright (C) 2017 jimo1001 <jimo1001@gmail.com>
;;
;; Author: Yoshinobu Fujimoto
;; Version: 0.1.2
;; Package-Version: 20170228.1345
;; Package-Commit: 7fe2922d85608bfa9e18269fc44181428b8849ff
;; URL: https://github.com/jimo1001/helm-perspeen
;; Created: 2017-01-30
;; Package-Requires: ((perspeen "0.1.0") (helm "2.5.0"))
;; Keywords: projects, lisp

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

;;
;; Configurations:
;;   Basic:
;;     (require 'helm-perspeen)
;;
;;   Use `use-package.el':
;;     (use-package helm-perspeen :ensure t)
;;
;; Dependencies:
;;   - perspeen
;;      - https://github.com/seudut/perspeen/blob/master/perspeen
;;   - helm
;;     - https://emacs-helm.github.io/helm/
;;   - (Optional) helm-projectile
;;     - https://github.com/bbatsov/helm-projectile
;;
;; Commands:
;;   - M-x helm-perspeen
;;
;; Helm Sources:
;;   - helm-source-perspeen-tabs
;;   - helm-source-perspeen-workspaces
;;   - helm-source-perspeen-create-workspace
;;

;;; Code:



(require 'helm)
(require 'perspeen)

(defgroup helm-perspeen nil
  "Helm support for perspeen."
  :prefix "helm-perspeen-"
  :group 'perspeen
  :link `(url-link :tag "GitHub" "https://github.com/jimo1001/helm-perspeen"))

(defface helm-perspeen-directory
  '((t (:foreground "DarkGray")))
  "Face used for directories in `helm-source-perspeen-tabs' and `helm-source-perspeen-workspaces'."
  :group 'helm-perspeen)


(defun helm-perspeen--switch-to-tab (index)
  "Select the tab of specified INDEX."
  (perspeen-tab-switch-internal index) nil)

(defun helm-perspeen--kill-tab (index)
  "Kill a tab of INDEX."
  (interactive)
  (let ((tabs (perspeen-tab-get-tabs))
        (current-index (perspeen-tab-get-current-tab-index)))
    (delq (nth index tabs) tabs)
    (perspeen-tab-switch-internal
     (cond ((> index current-index) current-index)
           ((> current-index 0) (- current-index 1))
           (t 0)))))

(defun helm-perspeen--switch-to-buffer-tab (buffer)
  "Open a BUFFER with new tab."
  (perspeen-tab-create-tab buffer 0 t) nil)

(defun helm-perspeen--open-file-tab (filename)
  "Open a FILENAME with new tab."
  (helm-perspeen--switch-to-buffer-tab (find-file-noselect filename)) nil)

(defcustom helm-source-perspeen-tabs-actions
  (helm-make-actions
   "Switch to Tab" #'helm-perspeen--switch-to-tab
   "Kill Tab `M-D'" #'helm-perspeen--kill-tab)
  "Actions for `helm-source-perspeen-tabs'."
  :group 'helm-perspeen
  :type '(alist :key-type string :value-type function))

(defvar helm-perspeen-tabs-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "M-D")
      #'(lambda ()
          (interactive)
          (helm-exit-and-execute-action 'helm-perspeen--kill-tab)))
    map)
  "Keymap for `helm-perspeen'.")

(defun helm-perspeen--compact-filename (filename)
  "Return compact FILENAME."
  (replace-regexp-in-string (concat "^" (getenv "HOME")) "~" (expand-file-name filename)))

(defvar helm-source-perspeen-tabs
  (helm-build-sync-source "Tabs (perspeen)"
    :candidates
    (lambda ()
      (if perspeen-tab-configurations
          (let ((index -1))
            (mapcar (lambda (tab)
                      (let* ((buffer (get tab 'current-buffer))
                             (current-dir (or (file-name-directory (or (buffer-file-name buffer) ""))
                                              default-directory)))
                        (setq index (1+ index))
                        (cons (format "%-36s  %s"
                                      (buffer-name buffer)
                                      (propertize
                                       (format "(in `%s')" (helm-perspeen--compact-filename current-dir)) 'face 'helm-perspeen-directory))
                              index)))
                    (perspeen-tab-get-tabs)))
        nil))
    :action 'helm-source-perspeen-tabs-actions
    :keymap 'helm-perspeen-tabs-map)
  "The helm source which are perspeen's tabs in the current workspace.")

(defun helm-perspeen--switch-to-workspace (ws)
  "Switch to the WS.
Save the old windows configuration and restore the new configuration.
Argument WS the workspace to swith to."
  (perspeen-switch-ws-internal ws)
  (perspeen-update-mode-string)
  nil)

(defun helm-perspeen--kill-workspace (ws)
  "Kill the WS."
  (interactive)
  (helm-perspeen--switch-to-workspace ws)
  (perspeen-delete-ws))

(defun helm-perspeen--rename-workspace (ws)
  "Rename the WS."
  (let ((new-name (read-string "Enter the new name: ")))
    (helm-perspeen--switch-to-workspace ws)
    (perspeen-rename-ws new-name)))

(defun helm-perspeen--run-eshell (ws)
  "Invoke `eshell' in the WS's root."
  (interactive)
  (helm-perspeen--switch-to-workspace ws)
  (perspeen-ws-eshell))

(defcustom helm-source-perspeen-workspaces-actions
  (helm-make-actions
   "Switch to Workspace" #'helm-perspeen--switch-to-workspace
   "Rename Workspace `M-R'" #'helm-perspeen--rename-workspace
   "Invoke `eshell'" #'helm-perspeen--run-eshell
   "Kill Workspace `M-D'" #'helm-perspeen--kill-workspace)
  "Actions for `helm-source-perspeen-workspaces'."
  :group 'helm-perspeen
  :type '(alist :key-type string :value-type function))

(defvar helm-perspeen-workspaces-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "M-D") #'(lambda ()
                                    (interactive)
                                    (helm-exit-and-execute-action 'helm-perspeen--kill-workspace)))
    (define-key map (kbd "M-R") #'(lambda ()
                                    (interactive)
                                    (helm-exit-and-execute-action 'helm-perspeen--rename-workspace)))
    map)
  "Keymap for `helm-perspeen'.")

(defvar helm-source-perspeen-workspaces
  (helm-build-sync-source "WorkSpaces (perspeen)"
    :candidates
    (lambda ()
      (mapcar (lambda (ws)
                (let ((name (perspeen-ws-struct-name ws))
                      (root-dir (perspeen-ws-struct-root-dir ws)))
                  (cons (format "%-36s  %s"
                                name
                                (propertize (format "(in `%s')" (helm-perspeen--compact-filename root-dir))
                                            'face 'helm-perspeen-directory))
                        ws)))
              perspeen-ws-list))
    :action 'helm-source-perspeen-workspaces-actions
    :keymap 'helm-perspeen-workspaces-map)
  "The workspaces helm source for perspeen.")

(defvar helm-source-perspeen-create-workspace
  (helm-build-dummy-source
      "Create perspeen workspace"
    :action (helm-make-actions
             "Create Workspace (perspeen)"
             (lambda (candidate)
               (perspeen-create-ws)
               (perspeen-rename-ws candidate) nil))))

(defun helm-perspeen--create-workspace (dir)
  "Create new workspace with project directory.
DIR is project root directory."
  (perspeen-create-ws)
  (perspeen-change-root-dir dir))

;;;###autoload
(eval-after-load 'helm-buffers
  '(progn
     (define-key helm-buffer-map (kbd "C-c t")
       #'(lambda ()
           (interactive)
           (helm-exit-and-execute-action 'helm-perspeen--switch-to-buffer-tab)))
     (add-to-list 'helm-type-buffer-actions
                  '("Open buffer with new perspeen's tab" . helm-perspeen--switch-to-buffer-tab) t)))

;;;###autoload
(eval-after-load 'helm-files
  '(progn
     (define-key helm-find-files-map (kbd "C-c t")
       #'(lambda ()
           (interactive)
           (helm-exit-and-execute-action 'helm-perspeen--open-file-tab)))
     (add-to-list 'helm-find-files-actions
                  '("Open file with new perspeen's tab" . helm-perspeen--open-file-tab) t)
     (add-to-list 'helm-type-file-actions
                  '("Open file with new perspeen's tab" . helm-perspeen--open-file-tab) t)))

;;;###autoload
(eval-after-load 'helm-projectile
  '(progn
     (define-key helm-projectile-projects-map (kbd "C-c w")
       #'(lambda ()
           (interactive)
           (helm-exit-and-execute-action 'helm-perspeen--create-workspace)))
     (add-to-list 'helm-source-projectile-projects-actions
                  '("Create perspeen's WorkSpace `C-c w'" . helm-perspeen--create-workspace) t)))

;;;###autoload
(defun helm-perspeen ()
  "Display workspaces (perspeen) with helm interface."
  (interactive
   (helm '(helm-source-perspeen-tabs helm-source-perspeen-workspaces helm-source-perspeen-create-workspace))))

(provide 'helm-perspeen)

;;; helm-perspeen.el ends here
