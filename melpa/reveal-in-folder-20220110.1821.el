;;; reveal-in-folder.el --- Reveal current file in folder  -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2022  Shen, Jen-Chieh
;; Created date 2019-11-06 23:14:19

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Reveal current file in folder.
;; Keyword: folder finder reveal file explorer
;; Version: 0.1.2
;; Package-Version: 20220110.1821
;; Package-Commit: 8d4dd03f8c12ea4b40fea90d0ae1de122caa5451
;; Package-Requires: ((emacs "24.3") (f "0.20.0") (s "1.12.0"))
;; URL: https://github.com/jcs-elpa/reveal-in-folder

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
;; Reveal current file in folder.
;;

;;; Code:

(require 'f)
(require 'ffap)
(require 's)

(defgroup reveal-in-folder nil
  "Reveal current file in folder."
  :prefix "reveal-in-folder-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/reveal-in-folder"))

(defcustom reveal-in-folder-select-file t
  "Select the file when shown in file manager."
  :type 'boolean
  :group 'reveal-in-folder)

(defun reveal-in-folder--safe-execute-p (in-cmd)
  "Correct way to check if IN-CMD execute with or without errors."
  (let ((inhibit-message t) (message-log-max nil))
    (= 0 (shell-command in-cmd))))

(defun reveal-in-folder--signal-shell (path)
  "Send the shell command by PATH."
  (let ((default-directory
          (if path (f-dirname (expand-file-name path)) default-directory))
        (buf-name (if (and reveal-in-folder-select-file path)
                      (shell-quote-argument (expand-file-name path))
                    nil))
        cmd)
    (cond
     ;; Windows
     ((memq system-type '(cygwin windows-nt ms-dos))
      (cond (buf-name
             (setq buf-name (s-replace "/" "\\" buf-name)
                   cmd (format "explorer /select,%s" buf-name)))
            ((ignore-errors (file-directory-p path))
             (setq path (s-replace "/" "\\" path)
                   cmd (format "explorer /select,%s" path)))
            (t (setq cmd "explorer ."))))
     ;; macOS
     ((eq system-type 'darwin)
      (cond (buf-name
             (setq cmd (format "open -R %s" buf-name)))
            ((ignore-errors (file-directory-p path))
             (setq cmd (format "open -R %s" path)))
            (t (setq cmd "open ."))))
     ;; Linux
     ((eq system-type 'gnu/linux)
      (setq cmd "xdg-open .")
      ;; TODO: I don't think Linux has defualt way to do it across all distro.
      )
     ;; BSD
     ((eq system-type 'berkeley-unix)
      ;; TODO: Not sure what else command do I need to make it work in BSD.
      (setq cmd "open .")
      (cond (buf-name
             (setq cmd (format "open -R %s" buf-name)))
            ((ignore-errors (file-directory-p path))
             (setq cmd (format "open -R %s" path)))
            (t (setq cmd "open ."))))
     (t (error "[ERROR] Unknown Operating System type")))
    (when cmd (reveal-in-folder--safe-execute-p cmd))))

;;;###autoload
(defun reveal-in-folder-at-point ()
  "Reveal the current file in folder at point."
  (interactive)
  (reveal-in-folder--signal-shell (ffap-guesser)))

;;;###autoload
(defun reveal-in-folder-this-buffer ()
  "Reveal the current buffer in folder."
  (interactive)
  (reveal-in-folder--signal-shell (buffer-file-name)))

;;;###autoload
(defun reveal-in-folder ()
  "Reveal buffer/path depends on cursor condition."
  (interactive)
  (if (ffap-file-at-point) (reveal-in-folder-at-point) (reveal-in-folder-this-buffer)))

(provide 'reveal-in-folder)
;;; reveal-in-folder.el ends here
