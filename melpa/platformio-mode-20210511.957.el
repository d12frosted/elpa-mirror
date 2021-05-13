;;; platformio-mode.el --- PlatformIO integration

;; Copyright (C) 2016 Zach Massia
;; Copyright (C) 2021 Dante Catalfamo

;; Author: Zach Massia <zmassia@gmail.com>
;;         Dante Catalfamo <dante@lambda.cx>
;; URL: https://github.com/zachmassia/platformio-mode
;; Package-Version: 20210511.957
;; Package-Commit: f4fd8932995a8aed80eab14e54232010c2889012
;; Version: 0.3.0
;; Package-Requires: ((emacs "25.1") (async "1.9.0") (projectile "0.13.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; A minor mode which allows quick building and uploading of PlatformIO
;; projects with a few short key sequences.
;;
;;; Code:

(require 'json)
(require 'async)
(require 'seq)
(require 'projectile)
(require 'compile)

;;; Customization
(defgroup platformio nil
  "PlatformIO integration for Emacs"
  :prefix "platformio-" :group 'tools
  :link '(url-link :tag "PlatformIO Documentation" "docs.platformio.org/en/latest/")
  :link '(url-link :tag "Submit PlatformIO Issue" "https://github.com/platformio/platformio/issues/"))

(defcustom platformio-mode-keymap-prefix (kbd "C-c i")
  "PlatformIO-mode keymap prefix."
  :group 'platformio
  :type 'string)

(defcustom platformio-mode-silent nil
  "Run PlatformIO commands with the silent argument."
  :group 'platformio
  :type 'boolean)

(defcustom platformio-board-list-buffer "*PlatformIO Boards*"
  "PlatformIO board list buffer name."
  :group 'platformio
  :type 'string)


(define-compilation-mode platformio-compilation-mode "PIOCompilation"
  "PlatformIO specific `compilation-mode' derivative."
  (setq-local compilation-scroll-output t)
  (require 'ansi-color)
  (add-hook 'compilation-filter-hook
            'platformio-compilation-filter-hook nil t))

(defun platformio-compilation-filter-hook ()
  "Apply colors."
  (when (eq major-mode 'platformio-compilation-mode)
    (ansi-color-apply-on-region compilation-filter-start (point-max))))

;;; User setup functions
(defun platformio-setup-compile-buffer ()
  "Deprecated function."
  (warn "The function platformio-setup-compile-buffer is deprecated, remove it from your config!"))

;;;###autoload
(defun platformio-conditionally-enable ()
  "Enable `platformio-mode' only when a `platformio.ini' file is present in project root."
  (condition-case nil
      (when (projectile-verify-file "platformio.ini")
        (platformio-mode 1))
    (error nil)))


;;; Internal functions
(defun platformio--exec (target)
  "Call `platformio ... TARGET' in the root of the project."
  (let ((default-directory (projectile-project-root))
        (cmd (concat "platformio -f -c emacs " target)))
    (unless default-directory
      (user-error "Not in a projectile project, aborting"))
    (save-some-buffers (not compilation-ask-about-save)
                       (lambda ()
                         (projectile-project-buffer-p (current-buffer)
                                                      default-directory)))
    (compilation-start cmd 'platformio-compilation-mode)))

(defun platformio--silent-arg ()
  "Return command line argument to make things silent."
  (when platformio-mode-silent
    "-s "))

(defun platformio--run (runcmd &optional NOTSILENT)
  "Execute command RUNCMD, optionally NOTSILENT."
  (platformio--exec (concat "run "
                  (unless NOTSILENT
                    (platformio--silent-arg))
                  runcmd)))


;;; Board list functions
(defun platformio--add-board (board)
  "Add a BOARD to a PlatformIO project."
  (platformio--exec (string-join (list "init --ide emacs --board " board))))

(defun platformio--build-board-table (_autoignore _noconfirm)
  "Return a list of all boards supported by PlatformIO."
  (setq revert-buffer-in-progress-p t)
  (setq mode-line-process ":refreshing")
  (async-start
   (lambda ()
     (require 'seq)
     (require 'json)
     (setq out nil)
     (seq-map
      (lambda (board)
        (push (list (alist-get 'id board)
                    (vector
                     `("Add" action
                       (lambda (_button) (platformio--add-board ,(alist-get 'id board))))
                     (alist-get 'name board)
                     (alist-get 'id board)
                     (alist-get 'mcu board)
                     (alist-get 'platform board)
                     (number-to-string (alist-get 'fcpu board))
                     (number-to-string (alist-get 'ram board))
                     (number-to-string (alist-get 'rom board))
                     (string-join (alist-get 'frameworks board) ", ")
                     (alist-get 'vendor board)
                     `("URL" action
                       (lambda (_button)
                         (browse-url-default-browser ,(alist-get 'url board))))
                     `("Docs" action
                       (lambda (_button)
                         (browse-url-default-browser ,(string-join (list "https://docs.platformio.org/en/latest/boards/"
                                                                         (alist-get 'platform board)
                                                                         "/"
                                                                         (alist-get 'id board)
                                                                         ".html")))))))
              out))
      (json-read-from-string
       (shell-command-to-string "platformio boards --json-output")))
     (nreverse out))

   (lambda (result)
     (with-current-buffer platformio-board-list-buffer
       (setq tabulated-list-entries result)
       (tabulated-list-revert)
       (setq revert-buffer-in-progress-p nil)
       (setq mode-line-process "")))))

(define-derived-mode platformio-boards-mode tabulated-list-mode "PlatformIO-Boards"
  "PlatformIO boards mode."
  (setq tabulated-list-format [("" 3 nil)
                               ("Name" 24 t)
                               ("ID" 30 t)
                               ("MCU" 17 t)
                               ("Platform" 16 t)
                               ("CPU Freq" 12 nil)
                               ("RAM" 12 nil)
                               ("ROM" 12 nil)
                               ("Frameworks" 35 nil)
                               ("Vendor" 20 t)
                               ("" 4 nil)
                               ("" 4 nil)])
  (setq tabulated-list-sort-key nil)
  (setq tabulated-list-padding 2)
  (tabulated-list-init-header)
  (setq revert-buffer-function #'platformio--build-board-table))


;;; User commands
(defun platformio-build (project)
  "Build PlatformIO PROJECT."
  (interactive "P")
  (platformio--run nil project))

(defun platformio-upload (project)
  "Upload PlatformIO PROJECT to device."
  (interactive "P")
  (platformio--run "-t upload" project))

(defun platformio-programmer-upload (project)
  "Upload PlatformIO PROJECT to device using external programmer."
  (interactive "P")
  (platformio--run "-t program" project))

(defun platformio-spiffs-upload (project)
  "Upload SPIFFS from PROJECT to device."
  (interactive "P")
  (platformio--run "-t uploadfs" project))

(defun platformio-clean (project)
  "Clean PlatformIO PROJECT."
  (interactive "P")
  (platformio--run "-t clean" project))

(defun platformio-update ()
  "Update installed PlatformIO libraries."
  (interactive)
  (platformio--exec "update"))

(defun platformio-init-update-workspace ()
  "Re-initialize project. Will update `.ccls' file."
  (interactive)
  (platformio--exec "init --ide emacs"))


(defun platformio-device-monitor ()
  "Open device monitor."
  (interactive)
  (platformio--exec "device monitor"))

(defun platformio-boards ()
  "List boards supported by PlatformIO."
  (interactive)
  (switch-to-buffer platformio-board-list-buffer)
  (platformio-boards-mode)
  (revert-buffer))


;;; Minor mode
(defvar platformio-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "b") #'platformio-build)
    (define-key map (kbd "u") #'platformio-upload)
    (define-key map (kbd "p") #'platformio-programmer-upload)
    (define-key map (kbd "s") #'platformio-spiffs-upload)
    (define-key map (kbd "c") #'platformio-clean)
    (define-key map (kbd "d") #'platformio-update)
    (define-key map (kbd "i") #'platformio-init-update-workspace)
    (define-key map (kbd "m") #'platformio-device-monitor)
    (define-key map (kbd "l") #'platformio-boards)
    map)
  "Keymap for PlatformIO mode commands after `platformio-mode-keymap-prefix'.")
(fset 'platformio-command-map platformio-command-map)

(defvar platformio-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map platformio-mode-keymap-prefix 'platformio-command-map)
    map)
  "Keymap for PlatformIO mode.")

(easy-menu-change
 '("Tools") "PlatformIO"
 '(["Build Project" platformio-build]
   ["Upload Project" platformio-upload]
   ["Upload using External Programmer" platformio-programmer-upload]
   ["Upload SPIFFS" platformio-spiffs-upload]
   ["Device monitor" platformio-device-monitor]
   "--"
   ["Add Boards" platformio-boards]
   ["Clean Project" platformio-clean]
   ["Update Project Libraries" platformio-update]
   ["Update Project Workspace and Index" platformio-init-update-workspace]))


;;;###autoload
(define-minor-mode platformio-mode
  "PlatformIO integration for Emacs."
  :lighter " PlatformIO"
  :keymap platformio-mode-map
  :group 'platformio
  :require 'platformio)

(provide 'platformio-mode)
;;; platformio-mode.el ends here
