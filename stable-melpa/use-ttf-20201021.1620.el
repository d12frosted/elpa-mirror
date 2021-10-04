;;; use-ttf.el --- Keep font consistency across different OSs  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Shen, Jen-Chieh
;; Created date 2018-05-22 15:23:44

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Keep font consistency across different OSs.
;; Keyword: customize font install ttf
;; Version: 0.1.1
;; Package-Version: 20201021.1620
;; Package-Commit: 418d8617f5c6431b72baa3d22e5b67dc5307870f
;; Package-Requires: ((emacs "24.4") (s "1.12.0"))
;; URL: https://github.com/jcs-elpa/use-ttf

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

(require 's)

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

(defun use-ttf--is-contain-list-string (in-list in-str)
  "Check if IN-STR contain in any string in the IN-LIST."
  (cl-some #'(lambda (lb-sub-str) (string-match-p (regexp-quote lb-sub-str) in-str)) in-list))

(defun use-ttf--get-file-name-or-last-dir-from-path (in-path &optional ignore-errors-t)
  "Get the either the file name or last directory from the IN-PATH.
If optional argument IGNORE-ERRORS-T is non-nil; then ignore errors for this function."
  ;; TODO: Future might implement just include directory and not each single .ttf file.
  (if (and (not (or (file-directory-p in-path) (file-exists-p in-path)))
           (not ignore-errors-t))
      (error "Directory/File you trying get does not exists : %s" in-path)
    (let ((result-dir-or-file nil)
          (split-dir-file-list '()) (split-dir-file-list-len 0))

      (cond
       ((string-match-p "/" in-path)
        (setq split-dir-file-list (split-string in-path "/")))
       ((string-match-p "\\" in-path)
        (setq split-dir-file-list (split-string in-path "\\")))
       ((string-match-p "\\\\" in-path)
        (setq split-dir-file-list (split-string in-path "\\\\"))))

      ;; Get the last element/item in the list.
      (setq split-dir-file-list-len (1- (length split-dir-file-list)))

      ;; Result is alwasy the last item in the list.
      (setq result-dir-or-file (nth split-dir-file-list-len split-dir-file-list))

      ;; Return result.
      result-dir-or-file)))

;;;###autoload
(defun use-ttf-install-fonts ()
  "Install all .ttf fonts in the `use-ttf-default-ttf-fonts'."
  (interactive)
  (dolist (default-ttf-font use-ttf-default-ttf-fonts)
    (let ((font-path default-ttf-font)
          (ttf-file-name (use-ttf--get-file-name-or-last-dir-from-path default-ttf-font t))
          (this-font-install nil)
          install-font-path)
      ;; NOTE: Start installing to OS.
      (cond
       ((string= system-type "windows-nt")  ; Windows
        ;; NOTE: DOS/Windows use `slash' instead of `backslash'.
        (setq font-path (concat (getenv "HOME") default-ttf-font)
              font-path (s-replace "/" "\\" font-path))

        (when (file-exists-p font-path)
          ;; Add font file to `Windows/Fonts' directory.
          (shell-command (concat "echo F|xcopy /y /s /e /o "
                                 (shell-quote-argument font-path)
                                 " \"%systemroot%\\Fonts\""))
          ;; Then add it to the register.
          (shell-command
           (concat "reg add "
                   (shell-quote-argument "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts")
                   " /v "
                   (shell-quote-argument (concat ttf-file-name " (TrueType)"))
                   " /t REG_SZ /d "
                   (shell-quote-argument ttf-file-name)
                   " /f"))

          (setq this-font-install t)))
       ((string= system-type "darwin")  ; macOS
        ;; NOTE: MacOS use `backslash' instead of `slash'.
        (setq font-path (concat (getenv "HOME") default-ttf-font)
              font-path (s-replace "\\" "/" font-path))

        (when (file-exists-p font-path)
          ;; NOTE: Should `install-font-path' => `~/Library/Fonts'.
          (setq install-font-path (concat (getenv "HOME") "/Library/Fonts"))

          (unless (file-directory-p install-font-path)
            (mkdir install-font-path t))

          (shell-command
           (concat "cp "
                   (shell-quote-argument font-path)
                   " "
                   (shell-quote-argument install-font-path)))

          (setq this-font-install t)))
       ((string= system-type "gnu/linux")  ; Linux Distro
        ;; NOTE: Linux use `backslash' instead of `slash'.
        (setq font-path (concat (getenv "HOME") default-ttf-font)
              font-path (s-replace "\\" "/" font-path))

        (when (file-exists-p font-path)
          ;; NOTE: Should `install-font-path' => `~/.fonts'.
          (setq install-font-path (concat (getenv "HOME") "/.fonts"))

          (unless (file-directory-p install-font-path)
            (mkdir install-font-path t))

          (shell-command
           (concat "cp "
                   (shell-quote-argument font-path)
                   " "
                   (shell-quote-argument install-font-path)))
          (shell-command "fc-cache -f -v")

          (setq this-font-install t))))

      ;; NOTE: Prompt when install the font.
      (if this-font-install
          (message "[Done install font '%s'.]" ttf-file-name)
        (message "[Font '%s' you specify is not install.]" ttf-file-name))))
  (message "[Done install all the fonts.]"))

;;;###autoload
(defun use-ttf-set-default-font ()
  "Use the font by `use-ttf-default-ttf-font-name` variable.
This will actually set your Emacs to your target font."
  (interactive)
  (if (or (not use-ttf-default-ttf-font-name)
          (and (stringp use-ttf-default-ttf-font-name)
               (string= use-ttf-default-ttf-font-name "")))
      (user-error "Your default font name cannot be 'nil' or 'empty string'")
    ;; NOTE: Install font if not installed.
    (unless (use-ttf--is-contain-list-string (font-family-list) use-ttf-default-ttf-font-name)
      (call-interactively #'use-ttf-install-fonts))

    (if (use-ttf--is-contain-list-string (font-family-list) use-ttf-default-ttf-font-name)
        (progn
          (set-frame-font use-ttf-default-ttf-font-name nil t)
          (message "[Set default font to '%s'.]" use-ttf-default-ttf-font-name))
      ;; NOTE: Logically, no need to output error message about
      ;; installation, because `use-ttf-install-fonts' handles itself.
      (message "[Install fonts process still running, please call 'use-ttf-set-default-font' after a while.]"))))

(provide 'use-ttf)
;;; use-ttf.el ends here
