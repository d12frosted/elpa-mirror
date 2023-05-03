;;; use-ttf.el --- Keep font consistency across different OSs  -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2022  Shen, Jen-Chieh
;; Created date 2018-05-22 15:23:44

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/jcs-elpa/use-ttf
;; Package-Version: 20230503.1015
;; Package-Commit: a01d9aef26ffc45dbe8d57d7c061a3a80eb79a2b
;; Version: 0.1.3
;; Package-Requires: ((emacs "26.1"))
;; Keywords: convenience customize font install ttf

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Keep font consistency across different OSs.
;;

;;; Code:

(defgroup use-ttf nil
  "Use .ttf file in Emacs."
  :prefix "use-ttf-"
  :group 'appearance
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/use-ttf"))

(defcustom use-ttf-default-ttf-fonts '()
  "List of TTF fonts you want to use in the currnet OS."
  :type 'list
  :group 'use-ttf)

(defcustom use-ttf-default-ttf-font-name ""
  "Name of the font we want to use as default.
This you need to check the font name in the system manually."
  :type 'string
  :group 'use-ttf)

(defmacro use-ttf-inhibit-log (&rest body)
  "Execute BODY without write it to message buffer."
  (declare (indent 0) (debug t))
  `(let (message-log-max) ,@body))

(defmacro use-ttf-silent (&rest body)
  "Execute BODY without message."
  (declare (indent 0) (debug t))
  `(use-ttf-inhibit-log
     (with-temp-message (or (current-message) nil)
       (let ((inhibit-message t)) ,@body))))

(defun use-ttf--s-replace (old new s)
  "Replace OLD with NEW in S."
  (replace-regexp-in-string (regexp-quote old) new s t t))

(defun use-ttf--windows-add-reg (ttf root)
  "Add TTF registry to ROOT."
  (shell-command
   (concat "reg add "
           (shell-quote-argument (concat root "\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts"))
           " /v "
           (shell-quote-argument (concat ttf " (TrueType)"))
           " /t REG_SZ /d "
           (shell-quote-argument ttf)
           " /f")))

(defun use-ttf--inst-windows (font ttf)
  "Install FONT TTF in Windows."
  (when-let* ((path (expand-file-name font (getenv "HOME")))
              ;; NOTE: DOS/Windows use `slash' instead of `backslash'
              (path (use-ttf--s-replace "/" "\\" path))
              ((file-exists-p path)))
    ;; Add font file to `Windows/Fonts' directory
    (shell-command (concat "echo F|xcopy /y /s /e /o "
                           (shell-quote-argument path)
                           " \"%systemroot%\\Fonts\""))
    ;; Then add it to the register
    (use-ttf--windows-add-reg ttf "HKLM")
    (use-ttf--windows-add-reg ttf "HKEY_CURRENT_USER")))

(defun use-ttf--inst-macos (font)
  "Install FONT in macOS."
  (when-let* ((path (expand-file-name font (getenv "HOME")))
              ((file-exists-p path))
              (install-location (expand-file-name "/Library/Fonts" (getenv "HOME"))))
    (ignore-errors (make-directory install-location t))
    (shell-command
     (concat "cp " (shell-quote-argument path) " "
             (shell-quote-argument install-location)))))

(defun use-ttf--inst-linux (font)
  "Install FONT in Linux."
  (when-let* ((path (expand-file-name font (getenv "HOME")))
              ((file-exists-p path))
              (install-location (expand-file-name "/.fonts" (getenv "HOME"))))
    (ignore-errors (make-directory install-location t))
    (shell-command
     (concat "cp " (shell-quote-argument path) " "
             (shell-quote-argument install-location)))
    (shell-command "fc-cache -f -v")))

;;;###autoload
(defun use-ttf-install-fonts ()
  "Install all .ttf fonts in the `use-ttf-default-ttf-fonts'."
  (interactive)
  (let (failed)
    (dolist (font use-ttf-default-ttf-fonts)
      (let ((ttf (file-name-nondirectory font)) installed-p)
        (use-ttf-silent
          ;; NOTE: Start installing to OS
          (setq installed-p
                (cond
                 ((memq system-type '(cygwin windows-nt ms-dos))
                  (use-ttf--inst-windows font ttf))
                 ((eq system-type 'darwin) (use-ttf--inst-macos font))
                 ((eq system-type 'gnu/linux) (use-ttf--inst-linux font)))))
        ;; NOTE: Prompt when installing the font
        (if installed-p
            (message "[Done install the font '%s'.]" ttf)
          (message "[Font '%s' you specify is not installed.]" ttf)
          (setq failed t))))
    (if failed
        (message "[Some fonts are not installed, see above log for more information.]")
      (message "[Done install all fonts.]"))))

;;;###autoload
(defun use-ttf-set-default-font ()
  "Use the font by `use-ttf-default-ttf-font-name` variable.
This will actually set your Emacs to your target font."
  (interactive)
  (cond
   ((not (display-graphic-p))
    (message "[Can't set default '%s' in terminal mode, please change the terminal font.]"
             use-ttf-default-ttf-font-name))
   ((or (not use-ttf-default-ttf-font-name)
        (and (stringp use-ttf-default-ttf-font-name)
             (string-empty-p use-ttf-default-ttf-font-name)))
    (user-error "Your default font name cannot be 'nil' or 'empty string'"))
   ((member use-ttf-default-ttf-font-name (font-family-list))
    (set-frame-font use-ttf-default-ttf-font-name nil t)
    (message "[Set the default font to '%s'.]" use-ttf-default-ttf-font-name))
   (t
    ;; NOTE: Logically, no need to output error message about installation,
    ;; because `use-ttf-install-fonts' handles itself
    (use-ttf-install-fonts)
    (message "[Font installtion is still running, please call 'use-ttf-set-default-font' after a while.]"))))

(provide 'use-ttf)
;;; use-ttf.el ends here
