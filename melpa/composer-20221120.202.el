;;; composer.el --- Interface to PHP Composer -*- lexical-binding: t -*-

;; Copyright (C) 2020  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 5 Dec 2015
;; Version: 0.2.0
;; Package-Version: 20221120.202
;; Package-Commit: 2299cd731205906350d615021f99a66d7a8905c2
;; Keywords: tools php dependency manager
;; Homepage: https://github.com/zonuexe/composer.el
;; Package-Requires: ((emacs "25.1") (seq "1.9") (php-runtime "0.1.0"))
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
(require 'consult nil t)

(eval-when-compile
  (declare-function
   consult--read "ext:consult"
   (candidates &rest options &key
               prompt predicate require-match history default
               keymap category initial narrow add-history annotate
               state preview-key sort lookup group inherit-input-method)))

;;; Variables
(defvar composer-executable-bin nil
  "Path to `composer.phar' exec file.")

(defvar composer-use-managed-phar nil
  "When not-NIL, use `composer.phar' managed by Emacs package.")

(defvar composer--async-use-compilation t)

(defvar composer--execute-interactive nil)

(defvar composer--quote-shell-argument t)

(defvar composer-global-command nil
  "When not-NIL, execute composer global command.")

(defconst composer-installer-url "https://getcomposer.org/installer")

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

(defcustom composer-directory-to-managed-file (expand-file-name "var" user-emacs-directory)
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
  "Return path which include `composer.json' by DIRECTORY."
  (or (locate-dominating-file directory "composer.json")
      (locate-dominating-file directory "composer.lock")))

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
  "Parse `composer.json' in DIR."
  (json-read-file (expand-file-name "composer.json" dir)))

(defun composer--parse-json-string (json)
  "Parse `composer.json' from JSON string."
  (with-temp-buffer
    (insert json)
    (goto-char (point-min))
    (if (eval-when-compile (and (fboundp 'json-serialize)
                                (fboundp 'json-parse-buffer)))
        (with-no-warnings
          (json-parse-buffer :object-type 'alist :array-type 'array))
      (let ((json-object-type 'alist) (json-array-type 'vector))
        (json-read-object)))))

(defun composer--get-vendor-bin-dir ()
  "Return path to project bin dir."
  (let* ((dir (composer--find-composer-root default-directory))
         (config (if dir (composer--parse-json dir) nil)))
    (or
     (cdr-safe (assq 'bin-dir (cdr-safe (assq 'config config))))
     "vendor/bin")))

(defun composer--get-vendor-bin-files ()
  "Return executable file names of `vendor/bin' dir."
  (let ((default-directory (or (composer--find-composer-root default-directory)
                               default-directory))
        path)
    (when-let (bin-dir (composer--get-vendor-bin-dir))
      (setq path (expand-file-name bin-dir default-directory))
      (when (file-directory-p path)
        (directory-files path nil "\\`[^.]")))))

(defun composer--get-vendor-bin-path (command)
  "Return executable file path by COMMAND."
  (let* ((default-directory (or (composer--find-composer-root default-directory)
                                default-directory))
         (bin-dir (composer--get-vendor-bin-dir))
         (command-path (if (and bin-dir command) (expand-file-name command bin-dir) nil)))
    (if (and command-path (file-executable-p command-path))
        command-path
      (user-error "%s command is not exists" command))))

(defun composer--get-scripts ()
  "Return script names in composer.json, excluding pre and post hooks."
  (let ((output (composer--command-execute "run-script" "-l")))
    (seq-filter (lambda (script) (not (or (null script) (member script '("pre" "post")))))
                (mapcar (lambda (line) (car (split-string line " " t)))
                        (split-string (or (cadr (split-string output "Scripts:\n")) "") "\n")))))

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
       (string-trim-right (shell-command-to-string (composer--make-command-string sub-command args)))))))

(defun composer--list-sub-commands ()
  "List `composer' sub commands."
  (let ((output (composer--command-execute "list" "--format=json")))
    (delq nil
          (seq-map (lambda (command)
                     (let ((name (cdr-safe (assq 'name command))))
                       (when (and name (not (string-prefix-p "_" name)))
                         (list name :description (cdr-safe (assq 'description command))))))
                   (cdr-safe (assq 'commands (composer--parse-json-string output)))))))

(defun composer--completion-read-sub-command (global)
  "Completing read composer sum command.

When GLOBAL is non-NIL, execute sub command in global context."
  (let* ((commands (composer--list-sub-commands))
         (prompt (if global "Composer (global) sub command: " "Composer sub command: ")))
    (if (fboundp 'consult--read)
        (let* ((max (seq-max (seq-map (lambda (cand) (length (car cand))) commands)))
               (align (propertize " " 'display `(space :align-to (+ left ,max 4))))
               (annotator (lambda (cand)
                            (when-let (description (plist-get (cdr-safe (assoc-string cand commands)) :description))
                              (concat align description)))))
          (consult--read commands
                         :prompt prompt
                         :annotate annotator))
      (completing-read prompt commands))))

(defun composer--get-version ()
  "Return version string of composer."
  (save-match-data
    (let ((v (composer--command-execute "--version")))
      (when (string-match "[0-9]+\\.[0-9]+\\.[0-9]+" v)
        (match-string 0 v)))))

(defun composer--get-global-dir ()
  "Return path to global composer directory."
  (seq-find
   #'file-exists-p
   (delq
    nil
    (nconc
     (list (getenv "COMPOSER_HOME")
           (when (eval-when-compile (eq system-type 'windows-nt))
             (expand-file-name "Composer" (getenv "APPDATA")))
           (when-let (xdg-home (getenv "XDG_CONFIG_HOME")) (expand-file-name "composer") xdg-home))
     (when-let (home (getenv "HOME"))
       (list (expand-file-name ".config/composer" home)
             (expand-file-name ".composer" home)))))))

(defun composer--get-path-to-managed-composer-phar ()
  "Return path to `composer.phar' file managed by Emacs package."
  (let ((user-emacs-directory composer-directory-to-managed-file))
    (locate-user-emacs-file "./composer.phar")))

(defun composer--ensure-exist-managed-composer-phar ()
  "Install latest version of `composer.phar' if that was not installed."
  (let ((composer-executable-bin (composer--get-path-to-managed-composer-phar)))
    (unless (file-exists-p composer-executable-bin)
      (composer--download-composer-phar composer-directory-to-managed-file))))

(defun composer--hash-file-sha384 (path)
  "Return SHA-384 hash of the file PATH."
  (cond
   ((eval-when-compile (and (fboundp 'secure-hash-algorithms)
                            (memq 'sha384 (secure-hash-algorithms))))
    (secure-hash 'sha384 (with-temp-buffer
                           (insert-file-contents-literally path)
                           (buffer-substring-no-properties (point-min) (point-max)))))
   ((string= "1" (php-runtime-expr "in_array('sha384', hash_algos())"))
    (string-trim (php-runtime-expr (format "hash_file('SHA384', '%s')" path))))
   (error "No method for SHA-384 hash.  Please install latest version of Emacs or PHP linked with OpenSSL")))

(defun composer--download-composer-phar (path-to-dest)
  "Download composer.phar and copy to `PATH-TO-DEST' directory.

https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md"
  (unless (featurep 'php-runtime)
    (error "This feature requires `php-runtime' package"))
  (let ((path-to-temp (expand-file-name "composer-setup.php" temporary-file-directory))
        (expected-signature
         (string-trim (php-runtime-eval "readfile('https://composer.github.io/installer.sig');")))
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
         (output (split-string (composer--command-execute "config" name) "\n")))
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
          (expand-file-name "vendor/bin" (composer--get-global-dir)))
    (let ((path (composer--find-composer-root default-directory)))
      (when path
        (expand-file-name (composer-get-config "bin-dir") path)))))

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
  (prog1 t
    (let ((output (composer--command-execute "dump-autoload")))
      (when (called-interactively-p 'interactive)
        (message "Composer: %s"
                 (car-safe (last (split-string output "\n"))))))))

;;;###autoload
(defun composer-require (is-dev &optional package)
  "Execute `composer require' command.

When IS-DEV is not-NIL, add `--dev' to option.
Require PACKAGE is package name."
  (interactive "p")
  (when (called-interactively-p 'interactive)
    (setq is-dev (not (eq is-dev 1)))
    (setq package (read-string
                   (if is-dev "Input package name(dev): " "Input package name: "))))
  (unless package
    (user-error "An argument PACKAGE is required"))
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
  (find-file (expand-file-name "composer.json" (composer--find-composer-root default-directory))))

;;;###autoload
(defun composer-view-lock-file ()
  "Open composer.lock of the project."
  (interactive)
  (find-file (expand-file-name "composer.lock" (composer--find-composer-root default-directory)))
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
  "Execute `composer' SUB-COMMAND with OPTION arguments.

When called with prefix argument GLOBAL, execute in global context."
  (interactive "p")
  (when (called-interactively-p 'interactive)
    (setq global (not (eq global 1)))
    (setq sub-command (composer--completion-read-sub-command global))
    (setq option (read-string (format "Input `composer %s' argument: " sub-command))))
  (unless sub-command
    (error "An argument SUB-COMMAND is required"))
  (let ((composer--quote-shell-argument nil)
        (composer-global-command global)
        (composer--execute-interactive (member sub-command composer-interactive-sub-commands)))
    (apply (if composer--execute-interactive 'composer--command-execute 'composer--command-async-execute)
           sub-command (list option))))

(provide 'composer)
;;; composer.el ends here
