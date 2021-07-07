;;; composer.el --- Interface to PHP Composer -*- lexical-binding: t -*-

;; Copyright (C) 2020  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 5 Dec 2015
;; Version: 0.2.0
;; Package-Version: 20200616.1717
;; Package-Commit: 7c7f89df226cac69664d7eca5e913b544dc475c5
;; Keywords: tools php dependency manager
;; Homepage: https://github.com/zonuexe/composer.el
;; Package-Requires: ((emacs "24.3") (s "1.9.0") (f "0.17") (seq "1.9") (php-runtime "0.1.0"))
;; License: GPL-3.0-or-later

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

;; `composer.el' is PHP Composer interface for Emacs.
;;
;; ## Commands
;;
;;  - M-x composer  - Run composer sub command (with completing read)
;;  - C-u M-x composer  - Run composer (global) sub command (with completing read)
;;  - M-x composer-install  - Run composer install command
;;  - M-x composer-require  - Run composer require command
;;  - M-x composer-update  - Run composer update command
;;  - C-u M-x composer-require  - Run composer require --dev command
;;  - M-x composer-dump-autoload - Run composer dump-autoload command
;;  - M-x composer-find-json-file  - Open composer.json of the project
;;  - M-x composer-view-lock-file  - Open composer.lock of the project (as read-only)

;;; Code:
(require 'php-runtime nil t)
(require 'compile)
(require 'cl-lib)
(require 'json)
(require 'seq)
(require 's)
(require 'f)

;;; Variables
(defvar composer-executable-bin nil
  "Path to `composer.phar' exec file.")

(defvar composer-use-managed-phar nil
  "Use composer.phar managed by Emacs package when `composer-use-managed-phar' is t.")

(defvar composer--async-use-compilation t)

(defvar composer--execute-interactive nil)

(defvar composer--quote-shell-argument t)

(defvar composer-global-command nil
  "Execute composer global command when `composer-global-command' is t.")

(defvar composer-recent-version "1.10.7"
  "Known latest version of `composer.phar'.")

(defconst composer-installer-url "https://getcomposer.org/installer")

(defconst composer-unsafe-phar-url
  "https://getcomposer.org/download/1.10.7/composer.phar")

(defconst composer-unsafe-phar-md5sum
  "66eea3af31cf357e2d8cac648abc21f3")

(defconst composer-known-executable-names
  '("composer" "composer.phar"))

;;; Customize
(defgroup composer nil
  "Interface to PHP Composer."
  :group 'external
  :group 'tools
  :group 'php
  :tag "Composer"
  :prefix "composer-")

(defcustom composer-directory-to-managed-file (f-join user-emacs-directory "var")
  "Path to directory of `composer.phar' file managed by Emacs package."
  :type 'directory
  :group 'composer)

(defcustom composer-use-ansi-color nil
  "Use ansi color code on execute `composer' command."
  :type 'boolean)

(defcustom composer-interactive-sub-commands
  '("init" "remove" "search")
  "List of sub commands of interactive execution."
  :type '(repeat string))

(defcustom composer-unsafe-skip-verify-installer-signature nil
  "This setting is risky.

Please enable this setting at your own risk in an environment old Emacs or PHP linked with old OpenSSL."
  :type 'boolean
  :risky t
  :group 'composer)


;;; Utility
(defun composer-find-executable ()
  "Return list of `composer' command and executable file."
  (or (composer--find-executable-1)
      (user-error "Install Composer manually or run M-x composer-setup-managed-phar")))

(defun composer--find-executable-1 ()
  "Return list of `composer' command and executable file."
  (if (and composer-executable-bin (file-exists-p composer-executable-bin))
      (if (file-executable-p composer-executable-bin)
          (list (expand-file-name composer-executable-bin))
        (list (if (boundp 'php-executable) php-executable "php")
              (expand-file-name composer-executable-bin)))
    (cl-loop for cmd in composer-known-executable-names
             if (executable-find cmd)
             return (list cmd))))

(defun composer--find-composer-root (directory)
  "Return directory path which include composer.json by `DIRECTORY'."
  (let ((composer-json (f-join directory "composer.json")) parent)
    (if (file-exists-p composer-json)
        (concat (f-dirname composer-json) "/")
      (setq parent (f-dirname directory))
      (if (null parent)
          nil
        (composer--find-composer-root (f-dirname directory))))))

(defun composer--make-command-string (sub-command args)
  "Return command string by `SUB-COMMAND' and `ARGS'."
  (mapconcat
   (if composer--quote-shell-argument 'shell-quote-argument 'identity)
   (append
    (let ((composer-executable-bin (if composer-use-managed-phar
                               (composer--get-path-to-managed-composer-phar)
                             composer-executable-bin)))
      (composer-find-executable))
    (append (if composer-global-command '("global") nil)
            (list sub-command)
            (if composer--execute-interactive nil '("--no-interaction"))
            (composer--args-with-global-options args)))
   " "))

(defun composer--args-with-global-options (args)
  "Set global options to `ARGS'."
  (unless composer-use-ansi-color
    (setq args (push "--no-ansi" args)))
  args)

(defun composer--parse-json (dir)
  "Parse `composer.json' in `DIR'."
  (json-read-file (f-join dir "composer.json")))

(defun composer--get-vendor-bin-dir ()
  "Return path to project bin dir."
  (let* ((dir (composer--find-composer-root default-directory))
         (config (if dir (composer--parse-json dir) nil)))
    (or
     (cdr-safe (assq 'bin-dir (cdr-safe (assq 'config config))))
     "vendor/bin")))

(defun composer--get-vendor-bin-files ()
  "Return executable file names of `vendor/bin' dir."
  (let* ((default-directory (or (composer--find-composer-root default-directory)
                                default-directory))
         (bin-dir (composer--get-vendor-bin-dir)))
    (if (null bin-dir)
        nil
      (directory-files (f-join default-directory bin-dir) nil "\\`[^.]"))))

(defun composer--get-vendor-bin-path (command)
  "Return executable file path by `COMMAND'."
  (let* ((default-directory (or (composer--find-composer-root default-directory)
                                default-directory))
         (bin-dir (composer--get-vendor-bin-dir))
         (command-path (if (and bin-dir command) (f-join bin-dir command) nil)))
    (if (not (and command-path (file-executable-p command-path)))
        (error "%s command is not exists" command)
      command-path)))

(defun composer--get-scripts ()
  "Return script names in composer.json, excluding pre and post hooks."
  (let ((output (composer--command-execute "run" "-l")))
    (seq-filter (lambda (script) (not (member script '("pre" "post"))))
                (mapcar (lambda (line) (car (s-split-words line)))
                        (s-split "\n" (cadr (s-split "Scripts:\n" output)))))))

(defun composer--command-async-execute (sub-command &rest args)
  "Asynchronous execute `composer.phar' command SUB-COMMAND by ARGS."
  (let ((default-directory (or (composer--find-composer-root default-directory)
                               default-directory)))
    (if composer--async-use-compilation
        (compile (composer--make-command-string sub-command args))
      (async-shell-command (composer--make-command-string sub-command args) nil nil))))

(defun composer--command-execute (sub-command &rest args)
  "Execute `composer.phar' command SUB-COMMAND by ARGS."
  ;; You are running composer with xdebug enabled. This has a major impact on runtime performance. See https://getcomposer.org/xdebug
  (let ((default-directory (or (composer--find-composer-root default-directory)
                               default-directory)))
    (if composer--execute-interactive
        (compile (composer--make-command-string sub-command args) t)
      (replace-regexp-in-string
       "^.+getcomposer.org/xdebug\n" ""
       (s-chomp
        (shell-command-to-string (composer--make-command-string sub-command args)))))))

(defun composer--list-sub-commands ()
  "List `composer' sub commands."
  (let ((output (composer--command-execute "list")))
    (mapcar (lambda (line) (car (s-split-words line)))
            (s-split "\n" (cadr (s-split "Available commands:\n" output))))))

(defun composer--get-version ()
  "Return version string of composer."
  (car-safe (s-match "[0-9]+\\.[0-9]+\\.[0-9]+" (composer--command-execute "--version"))))

(defun composer--get-global-dir ()
  "Return path to global composer directory."
  (seq-find
   'file-exists-p
   (seq-remove
    'null
    (list
     (getenv "COMPOSER_HOME")
     (when (eq system-type 'windows-nt) (f-join (getenv "APPDATA") "Composer"))
     (when (getenv "XDG_CONFIG_HOME") (f-join (getenv "XDG_CONFIG_HOME") "composer"))
     (when (getenv "HOME") (f-join (getenv "HOME") ".composer"))))))

(defun composer--get-path-to-managed-composer-phar ()
  "Return path to `composer.phar' file managed by Emacs package."
  (let ((user-emacs-directory composer-directory-to-managed-file))
    (locate-user-emacs-file "./composer.phar")))

(define-obsolete-function-alias 'composer--get-path-tomanaged-composer-phar 'composer--get-path-to-managed-composer-phar
  "0.2.0")

(defun composer--ensure-exist-managed-composer-phar ()
  "Install latest version of `composer.phar' if that was not installed."
  (let ((composer-executable-bin (composer--get-path-to-managed-composer-phar)))
    (unless (and (file-exists-p composer-executable-bin)
                 (version<= composer-recent-version (composer--get-version)))
      (if composer-unsafe-skip-verify-installer-signature
          (composer--unsafe-fallback-download-composer-phar composer-directory-to-managed-file)
        (composer--download-composer-phar composer-directory-to-managed-file)))))


(defun composer--hash-file-sha384 (path)
  "Return SHA-384 hash of the file `PATH'."
  (cond
   ((and (fboundp 'secure-hash-algorithms)
         (memq 'sha384 (secure-hash-algorithms)))
    (secure-hash 'sha384 (f-read-bytes path)))
   ((string= "1" (php-runtime-expr "in_array('sha384', hash_algos())"))
    (s-trim (php-runtime-expr (format "hash_file('SHA384', '%s')" path))))
   (t (error "No method for SHA-384 hash.  Please install latest version of Emacs or PHP linked with OpenSSL"))))

(defun composer--unsafe-fallback-download-composer-phar (path-to-dest)
  "Download composer.phar and copy to `PATH-TO-DEST' directory."
  (let ((dest-filename (expand-file-name "composer.phar" path-to-dest))
        actual-signature)
    (php-runtime-eval (format "copy('%s', '%s');" composer-unsafe-phar-url dest-filename))
    (setq actual-signature
          (php-runtime-expr (format "md5_file('%s')" dest-filename)))
    (unless (string= composer-unsafe-phar-md5sum actual-signature)
      (php-runtime-expr (format "unlink('%s')" dest-filename))
      (error "Invalid composer.phar md5 signature"))
    (php-runtime-expr (format "chmod('%s', 0755)" dest-filename))))

(defun composer--download-composer-phar (path-to-dest)
  "Download composer.phar and copy to `PATH-TO-DEST' directory.

https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md"
  (unless (featurep 'php-runtime)
    (error "This feature requires `php-runtime' package"))
  (let ((path-to-temp (f-join temporary-file-directory "composer-setup.php"))
        (expected-signature
         (s-trim (php-runtime-eval "readfile('https://composer.github.io/installer.sig');")))
        actual-signature)
    (php-runtime-eval (format "copy('%s', '%s');" composer-installer-url path-to-temp))
    (setq actual-signature (composer--hash-file-sha384 path-to-temp))
    (unless (string= expected-signature actual-signature)
      (php-runtime-expr (format "unlink('%s')" path-to-temp))
      (error "Invalid Composer installer signature"))
    (let ((default-directory path-to-dest))
      (shell-command (format "php %s" (shell-quote-argument path-to-temp))))))

;;; API

;;;###autoload
(defun composer-get-config (name)
  "Return config value by `NAME'."
  (let* ((default-directory (if composer-global-command (composer--get-global-dir) default-directory))
         (output (s-lines (composer--command-execute "config" name))))
    (if (eq 1 (length output)) (car output) nil)))

;; (composer--command-async-execute "require" "--dev" "phpunit/phpunit:^4.8")
;; (composer--command-async-execute "update")
;; (let ((composer--async-use-compilation nil)) (composer--command-execute "update"))
;; (composer--command-execute "update")
;; (composer-get-config "bin-dir")
;; (let ((composer-global-command t)) (composer-get-config "bin-dir"))
;; (composer--make-command-string "hoge" '("fuga"))

;;;###autoload
(defun composer-get-bin-dir ()
  "Retrurn path to Composer bin directory."
  (if composer-global-command
      (or (getenv "COMPOSER_BIN_DIR")
          (f-join (composer--get-global-dir) "vendor/bin"))
    (let ((path (composer--find-composer-root default-directory)))
      (when path
        (f-join path (composer-get-config "bin-dir"))))))

;;; Command

;;;###autoload
(defun composer-install ()
  "Execute `composer.phar install' command."
  (interactive)
  (composer--command-async-execute "install"))

;;;###autoload
(defun composer-dump-autoload ()
  "Execute `composer.phar install' command."
  (interactive)
  (let ((composer--async-use-compilation nil))
    (composer--command-async-execute "dump-autoload")))

;;;###autoload
(defun composer-require (is-dev &optional package)
  "Execute `composer.phar require (--dev)' command.  Add --dev option if `IS-DEV' is t.  Require `PACKAGE' is package name."
  (interactive "p")
  (when (called-interactively-p 'interactive)
    (setq is-dev (not (eq is-dev 1)))
    (setq package (read-string
                   (if is-dev "Input package name(dev): " "Input package name: "))))
  (unless package
    (error "A argument `PACKAGE' is required"))
  (let ((args (list package)))
    (when is-dev (push "--dev" args))
    (apply 'composer--command-async-execute "require" args)))

;;;###autoload
(defun composer-update ()
  "Execute `composer.phar update' command."
  (interactive)
  (composer--command-async-execute "update"))

;;;###autoload
(defun composer-find-json-file ()
  "Open composer.json of the project."
  (interactive)
  (find-file (f-join (composer--find-composer-root default-directory) "composer.json")))

;;;###autoload
(defun composer-view-lock-file ()
  "Open composer.lock of the project."
  (interactive)
  (find-file (f-join (composer--find-composer-root default-directory) "composer.lock"))
  (view-mode))

;;;###autoload
(defun composer-run-vendor-bin-command (command)
  "Run command `COMMAND' in `vendor/bin' of the composer project."
  (interactive (list (completing-read "Run command in vendor/bin: " (composer--get-vendor-bin-files))))
  (let ((default-directory (or (composer--find-composer-root default-directory)
                               default-directory))
        (command-path (composer--get-vendor-bin-path command)))
    (if command-path
        (compile command-path)
      (error "`%s' is not executable file" command))))

;;;###autoload
(defun composer-run-script (script)
  "Run script `SCRIPT` as defined in the composer.json."
  (interactive (list (completing-read "Run scripts: " (composer--get-scripts))))
  (composer--command-async-execute "run-script" script))

;;;###autoload
(defun composer-self-update ()
  "Execute `composer.phar self-update' command."
  (interactive)
  (when (yes-or-no-p "Do composer self-update? ")
    (composer--command-async-execute "self-update")))

(make-obsolete 'composer-self-update 'composer "0.0.5")

;;;###autoload
(defun composer-setup-managed-phar (&optional force)
  "Setup `composer.phar'.  Force re-setup when `FORCE' option is non-NIL."
  (interactive "p")
  (when (called-interactively-p 'interactive)
    (setq force (not (eq force 1))))
  (when (and force (file-exists-p (composer--get-path-to-managed-composer-phar)))
    (delete-file (composer--get-path-to-managed-composer-phar)))
  (composer--ensure-exist-managed-composer-phar)
  (let ((composer-use-managed-phar t))
    (message "%s" (composer--command-execute "--version"))))

;;;###autoload
(defun composer (global &optional sub-command option)
  "Execute `composer.phar'.  Execute `global' sub command If GLOBAL is t.  Require SUB-COMMAND is composer sub command.  OPTION is optional commandline arguments."
  (interactive "p")
  (when (called-interactively-p 'interactive)
    (setq global (not (eq global 1)))
    (setq sub-command (completing-read
                       (if global "Composer (global) sub command: " "Composer sub command: ")
                       (composer--list-sub-commands)))
    (setq option (read-string (format "Input `composer %s' argument: " sub-command))))
  (unless sub-command
    (error "A argument `SUB-COMMAND' is required"))
  (let ((composer--quote-shell-argument nil)
        (composer-global-command global)
        (composer--execute-interactive (member sub-command composer-interactive-sub-commands)))
    (apply (if composer--execute-interactive 'composer--command-execute 'composer--command-async-execute)
           sub-command (list option))))

(provide 'composer)
;;; composer.el ends here
