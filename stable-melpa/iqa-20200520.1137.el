;;; iqa.el --- Init file(and directory) Quick Access -*- lexical-binding: t -*-

;; Homepage: https://github.com/a13/iqa.el
;; Version: 0.0.1
;; Package-Version: 20200520.1137
;; Package-Commit: 03f90a2f68b2f05d8a2509bf3612a337d3d5b67f
;; Package-Requires: ((emacs "24.3"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; Sadly, Emacs (unlike Spacemacs, which has `spacemacs/find-dotfile') doesn't have
;; a function to open its own init file, so thousands of users have to write their owns.
;; I'm not different :)
;;
;; `iqa-find-user-init-file' is a shorthand to open user init file.
;; By default `user-init-file' is used.  If your configuration is generated
;; from org-mode source you may want to point it to your org file.
;;
;; (setq iqa-user-init-file (concat user-emacs-directory "init.org"))
;;
;; File is opened by `find-file', but you can redefine it by e.g.
;;
;; (setq iqa-find-file-function #'find-file-other-window)
;;
;; `iqa-reload-user-init-file' reloads `user-init-file' (not `iqa-user-init-file')
;; For a full restart take a look at `restart-emacs' package.
;;
;; `iqa-find-user-custom-file' opens custom-file
;;
;; `iqa-find-user-init-directory' opens init file directory
;;
;; `iqa-setup-default' defines keybindings:
;; "C-x M-f" — `iqa-find-user-init-file'
;; "C-x M-c" — `iqa-find-user-custom-file'
;; "C-x M-r" — `iqa-reload-user-init-file'
;; "C-x M-d" — `iqa-find-user-init-directory'
;;
;;
;; Installation:
;;
;; (use-package iqa
;;   ;; use this if your config is generated from an org file
;;   ;; :custom
;;   ;; (iqa-user-init-file (concat user-emacs-directory "README.org") "Edit README.org by default.")
;;   :config
;;   (iqa-setup-default))

;;; Code:

(require 'cus-edit)
(require 'bookmark)

(defgroup iqa nil
  "Init file quick access."
  :group 'startup)

(defcustom iqa-user-init-file
  nil
  "Default init file to open instead of `user-init-file'."
  :group 'iqa
  :type 'file)

(defcustom iqa-find-file-function
  #'find-file
  "Find file function.  Should take one required FILENAME argument."
  :group 'iqa
  :type 'function)

(defun iqa--init-file ()
  "Return init file name."
  (or iqa-user-init-file user-init-file))

;;;###autoload
(defun iqa-find-user-init-file ()
  "Open user init file using `iqa-find-file-function'."
  (interactive)
  (funcall iqa-find-file-function (iqa--init-file)))

;;;###autoload
(defun iqa-find-user-custom-file ()
  "Open user custom file using `iqa-find-file-function'."
  (interactive)
  (funcall iqa-find-file-function (custom-file)))

;;;###autoload
(defun iqa-reload-user-init-file (save-all)
  "Load user init file.  Call `save-some-buffers' if the prefix SAVE-ALL is set.
Ask for saving only `iqa--init-file' otherwise."
  (interactive "P")
  (if save-all
      (save-some-buffers)
    (let* ((init-file (iqa--init-file))
           (init-file-buffer (get-file-buffer init-file)))
      (when (and init-file-buffer
                 (buffer-modified-p init-file-buffer)
                 (y-or-n-p (format "Save file %s? " init-file)))
        (with-current-buffer init-file-buffer
          (save-buffer)))))
  (load-file user-init-file))

;;;###autoload
(defun iqa-find-user-init-directory ()
  "Open user init file directory using `iqa-find-file-function'."
  (interactive)
  (funcall iqa-find-file-function (file-name-directory (iqa--init-file))))

;; TODO: add global minor mode
;;;###autoload
(defun iqa-setup-default ()
  "Setup default shortcuts for iqa."
  (interactive)
  (define-key ctl-x-map "\M-f" #'iqa-find-user-init-file)
  (define-key ctl-x-map "\M-c" #'iqa-find-user-custom-file)
  (define-key ctl-x-map "\M-r" #'iqa-reload-user-init-file)
  (define-key ctl-x-map "\M-d" #'iqa-find-user-init-directory))


;;;###autoload
(defun iqa-add-bookmarks ()
  "Add bookmarks for user init files and directories."
  (interactive)
  (bookmark-store "Emacs custom file" `((filename . ,(custom-file))) nil)
  (bookmark-store "Emacs init directory" `((filename . ,user-emacs-directory)) nil)
  (bookmark-store "Emacs init file" `((filename . ,(iqa--init-file))) nil))


(provide 'iqa)

;;; iqa.el ends here
