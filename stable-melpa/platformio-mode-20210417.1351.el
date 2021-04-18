;;; platformio-mode.el --- PlatformIO integration

;; Author: Zach Massia <zmassia@gmail.com>
;; URL: https://github.com/zachmassia/platformio-mode
;; Package-Version: 20210417.1351
;; Package-Commit: 7a831e31f01e23c29817d3bd8117a274ef0d9fa9
;; Version: 0.1.0
;; Package-Requires: ((projectile "0.13.0"))

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

(define-compilation-mode platformio-compilation-mode "PIOCompilation"
  "PlatformIO specific `compilation-mode' derivative."
  (setq-local compilation-scroll-output t)
  (require 'ansi-color)
  (add-hook 'compilation-filter-hook
            'platformio-compilation-filter-hook nil t))

(defun platformio-compilation-filter-hook ()
  (when (eq major-mode 'platformio-compilation-mode)
    (ansi-color-apply-on-region compilation-filter-start (point-max))))

;;; User setup functions
(defun platformio-setup-compile-buffer ()
  "Deprecated function."
  (warn "The function platformio-setup-compile-buffer is deprecated, remove it from your config!"))


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
    (save-some-buffers (not compilation-ask-about-save)
                       (lambda ()
                         (projectile-project-buffer-p (current-buffer)
                                                      default-directory)))
    (compilation-start cmd 'platformio-compilation-mode)))

(defun platformio--silent-arg ()
  (if platformio-mode-silent
      "-s "
    nil))

(defun platformio--run (runcmd &optional NOSILENT)
  (platformio--exec (concat "run "
                            (unless NOSILENT
                              (platformio--silent-arg))
                            runcmd)))

;;; User commands
(defun platformio-build (arg)
  "Build PlatformIO project."
  (interactive "P")
  (platformio--run nil arg))

(defun platformio-upload (arg)
  "Upload PlatformIO project to device."
  (interactive "P")
  (platformio--run "-t upload" arg))

(defun platformio-programmer-upload (arg)
  "Upload PlatformIO project to device using external programmer."
  (interactive "P")
  (platformio--run "-t program" arg))

(defun platformio-spiffs-upload (arg)
  "Upload SPIFFS to device."
  (interactive "P")
  (platformio--run "-t uploadfs" arg))

(defun platformio-clean (arg)
  "Clean PlatformIO project."
  (interactive "P")
  (platformio--run "-t clean" arg))

(defun platformio-update ()
  "Update installed PlatformIO libraries."
  (interactive)
  (platformio--exec "update"))

(defun platformio-init-update-workspace ()
  "Re-initialize project. Will update `.ccls' file."
  (interactive)
  (platformio--exec "init --ide emacs"))


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
   "--"
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
