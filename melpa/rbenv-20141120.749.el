;;; rbenv.el --- Emacs integration for rbenv

;; Copyright (C) 2013 Yves Senn

;; URL: https://github.com/senny/rbenv.el
;; Package-Version: 20141120.749
;; Package-Commit: 2ea1a5bdc1266caef1dd77700f2c8f42429b03f1
;; Author: Yves Senn <yves.senn@gmail.com>
;; Version: 0.0.3
;; Created: 10 February 2013
;; Keywords: ruby rbenv

;; This file is NOT part of GNU Emacs.

;;; License:

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

;; M-x global-rbenv-mode toggle the configuration done by rbenv.el

;; M-x rbenv-use-global prepares the current Emacs session to use
;; the global ruby configured with rbenv.

;; M-x rbenv-use allows you to switch the current session to the ruby
;; implementation of your choice.

;;; Compiler support:

;; helper function used in variable definitions
(defcustom rbenv-installation-dir (or (getenv "RBENV_ROOT")
                                      (concat (getenv "HOME") "/.rbenv/"))
  "The path to the directory where rbenv was installed."
  :group 'rbenv
  :type 'directory)

(defun rbenv--expand-path (&rest segments)
  (let ((path (mapconcat 'identity segments "/"))
        (installation-dir (replace-regexp-in-string "/$" "" rbenv-installation-dir)))
    (expand-file-name (concat installation-dir "/" path))))

(defcustom rbenv-interactive-completion-function
  (if ido-mode 'ido-completing-read 'completing-read)
  "The function which is used by rbenv.el to interactivly complete user input"
  :group 'rbenv
  :type 'function)

(defcustom rbenv-show-active-ruby-in-modeline t
  "Toggles wether rbenv-mode shows the active ruby in the modeline."
  :group 'rbenv
  :type 'boolean)

(defcustom rbenv-modeline-function 'rbenv--modeline-with-face
  "Function to specify the rbenv representation in the modeline."
  :group 'rbenv
  :type 'function)

(defvar rbenv-executable (rbenv--expand-path "bin" "rbenv")
  "path to the rbenv executable")
  
(defvar rbenv-ruby-shim (rbenv--expand-path "shims" "ruby")
  "path to the ruby shim executable")

(defvar rbenv-global-version-file (rbenv--expand-path "version")
  "path to the global version configuration file of rbenv")

(defvar rbenv-version-environment-variable "RBENV_VERSION"
  "name of the environment variable to configure the rbenv version")

(defvar rbenv-binary-paths (list (cons 'shims-path (rbenv--expand-path "shims"))
                                 (cons 'bin-path (rbenv--expand-path "bin")))
  "these are added to PATH and exec-path when rbenv is setup")

(defface rbenv-active-ruby-face
  '((t (:weight bold :foreground "Red")))
  "The face used to highlight the current ruby on the modeline.")

(defvar rbenv--initialized nil
  "indicates if the current Emacs session has been configured to use rbenv")

(defvar rbenv--modestring nil
  "text rbenv-mode will display in the modeline.")
(put 'rbenv--modestring 'risky-local-variable t)

;;;###autoload
(defun rbenv-use-global ()
  "activate rbenv global ruby"
  (interactive)
  (rbenv-use (rbenv--global-ruby-version)))

;;;###autoload
(defun rbenv-use-corresponding ()
  "search for .ruby-version and activate the corresponding ruby"
  (interactive)
  (let ((version-file-path (or (rbenv--locate-file ".ruby-version")
                               (rbenv--locate-file ".rbenv-version"))))
    (if version-file-path (rbenv-use (rbenv--read-version-from-file version-file-path))
      (message "[rbenv] could not locate .ruby-version or .rbenv-version"))))

;;;###autoload
(defun rbenv-use (ruby-version)
  "choose what ruby you want to activate"
  (interactive
   (let ((picked-ruby (rbenv--completing-read "Ruby version: " (rbenv/list))))
     (list picked-ruby)))
  (rbenv--activate ruby-version)
  (message (concat "[rbenv] using " ruby-version)))

(defun rbenv/list ()
  (append '("system")
          (split-string (rbenv--call-process "versions" "--bare") "\n")))

(defun rbenv--setup ()
  (when (not rbenv--initialized)
    (dolist (path-config rbenv-binary-paths)
      (let ((bin-path (cdr path-config)))
        (setenv "PATH" (concat bin-path ":" (getenv "PATH")))
        (add-to-list 'exec-path bin-path)))
    (setq eshell-path-env (getenv "PATH"))
    (setq rbenv--initialized t)
    (rbenv--update-mode-line)))

(defun rbenv--teardown ()
  (when rbenv--initialized
    (dolist (path-config rbenv-binary-paths)
      (let ((bin-path (cdr path-config)))
        (setenv "PATH" (replace-regexp-in-string (regexp-quote (concat bin-path ":")) "" (getenv "PATH")))
        (setq exec-path (remove bin-path exec-path))))
    (setq eshell-path-env (getenv "PATH"))
    (setq rbenv--initialized nil)))

(defun rbenv--activate (ruby-version)
  (setenv rbenv-version-environment-variable ruby-version)
  (rbenv--update-mode-line))

(defun rbenv--completing-read (prompt options)
  (funcall rbenv-interactive-completion-function prompt options))

(defun rbenv--global-ruby-version ()
  (if (file-exists-p rbenv-global-version-file)
      (rbenv--read-version-from-file rbenv-global-version-file)
    "system"))

(defun rbenv--read-version-from-file (path)
  (with-temp-buffer
    (insert-file-contents path)
    (rbenv--replace-trailing-whitespace (buffer-substring-no-properties (point-min) (point-max)))))

(defun rbenv--locate-file (file-name)
  "searches the directory tree for an given file. Returns nil if the file was not found."
  (let ((directory (locate-dominating-file default-directory file-name)))
    (when directory (concat directory file-name))))

(defun rbenv--call-process (&rest args)
  (with-temp-buffer
    (let* ((success (apply 'call-process rbenv-executable nil t nil
                           (delete nil args)))
           (raw-output (buffer-substring-no-properties
                        (point-min) (point-max)))
           (output (rbenv--replace-trailing-whitespace raw-output)))
      (if (= 0 success)
          output
        (message output)))))

(defun rbenv--replace-trailing-whitespace (text)
  (replace-regexp-in-string "[[:space:]\n]+\\'" "" text))

(defun rbenv--update-mode-line ()
  (setq rbenv--modestring (funcall rbenv-modeline-function
                                   (rbenv--active-ruby-version))))

(defun rbenv--modeline-with-face (current-ruby)
  (append '(" [")
          (list (propertize current-ruby 'face 'rbenv-active-ruby-face))
          '("]")))

(defun rbenv--modeline-plain (current-ruby)
  (list " [" current-ruby "]"))

(defun rbenv--active-ruby-version ()
  (or (getenv rbenv-version-environment-variable) (rbenv--global-ruby-version)))

;;;###autoload
(define-minor-mode global-rbenv-mode
  "use rbenv to configure the ruby version used by your Emacs."
  :global t
  (if global-rbenv-mode
      (progn
        (when rbenv-show-active-ruby-in-modeline
          (unless (memq 'rbenv--modestring global-mode-string)
            (setq global-mode-string (append (or global-mode-string '(""))
                                             '(rbenv--modestring)))))
        (rbenv--setup))
    (setq global-mode-string (delq 'rbenv--modestring global-mode-string))
    (rbenv--teardown)))

(provide 'rbenv)

;;; rbenv.el ends here
