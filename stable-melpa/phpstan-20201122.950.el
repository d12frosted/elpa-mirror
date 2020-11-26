;;; phpstan.el --- Interface to PHPStan              -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 15 Mar 2018
;; Version: 0.5.0
;; Package-Version: 20201122.950
;; Package-Commit: 6863a5278fc656cddb604b0c6e165f05d0171d0a
;; Keywords: tools, php
;; Homepage: https://github.com/emacs-php/phpstan.el
;; Package-Requires: ((emacs "24.3") (php-mode "1.22.3"))
;; License: GPL-3.0-or-later

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

;; Static analyze for PHP code using PHPStan.
;; https://github.com/phpstan/phpstan
;;
;; ## Instalation
;;
;; You need to get either the local PHP runtime or Docker and prepare for PHPStan.
;; Please read the README for these details.
;; https://github.com/emacs-php/phpstan.el/blob/master/README.org
;;
;; If you are a Flycheck user, install `flycheck-phpstan' package.
;;
;; ## Directory local variables
;;
;; Put the following into .dir-locals.el files on the root directory of project.
;; Each variable can read what is documented by `M-x describe-variables'.
;;
;;     ((nil . ((php-project-root . git)
;;              (phpstan-executable . docker)
;;              (phpstan-working-dir . (root . "path/to/dir"))
;;              (phpstan-config-file . (root . "path/to/dir/phpstan-docker.neon"))
;;              (phpstan-level . 7))))
;;
;; If you want to know the directory variable specification, please refer to
;; M-x info [Emacs > Customization > Variables] or the following web page.
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html
;;

;;; Code:
(require 'cl-lib)
(require 'php-project)


;; Variables:

(defgroup phpstan nil
  "Interaface to PHPStan"
  :tag "PHPStan"
  :prefix "phpstan-"
  :group 'tools
  :group 'php
  :link '(url-link :tag "PHPStan" "https://github.com/phpstan/phpstan")
  :link '(url-link :tag "phpstan.el" "https://github.com/emacs-php/phpstan.el"))

(defcustom phpstan-flycheck-auto-set-executable t
  "Set flycheck phpstan-executable automatically."
  :type 'boolean
  :group 'phpstan)

(defcustom phpstan-enable-on-no-config-file t
  "If T, activate configuration from composer even when `phpstan.neon' is not found."
  :type 'boolean
  :group 'phpstan)

(defcustom phpstan-memory-limit nil
  "Set --memory-limit option."
  :type '(choice (string :tag "Specifies the memory limit in the same format php.ini accepts.")
                 (const :tag "Not set --memory-limit option" nil))
  :safe (lambda (v) (or (null v) (stringp v)))
  :group 'phpstan)

(defcustom phpstan-docker-image "ghcr.io/phpstan/phpstan"
  "Docker image URL or Docker Hub image name or NIL."
  :type '(choice
          (string :tag "URL or image name of Docker Hub.")
          (const :tag "Official Docker container" "ghcr.io/phpstan/phpstan")
          (const :tag "No specify Docker image"))
  :link '(url-link :tag "PHPStan Documentation" "https://phpstan.org/user-guide/docker")
  :link '(url-link :tag "GitHub Container Registry"
                   "https://github.com/orgs/phpstan/packages/container/package/phpstan")
  :safe (lambda (v) (or (null v) (stringp v)))
  :group 'phpstan)

;;;###autoload
(progn
  (defvar phpstan-working-dir nil
    "Path to working directory of PHPStan.

*NOTICE*: This is different from the project root.

STRING
     Absolute path to `phpstan' working directory.

`(root . STRING)'
     Relative path to `phpstan' working directory from project root directory.

NIL
     Use (php-project-get-root-dir) as working directory.")
  (make-variable-buffer-local 'phpstan-working-dir)
  (put 'phpstan-working-dir 'safe-local-variable
       #'(lambda (v) (if (consp v)
                         (and (eq 'root (car v)) (stringp (cdr v)))
                       (null v) (stringp v)))))

;;;###autoload
(progn
  (defvar phpstan-config-file nil
    "Path to project specific configuration file of PHPStan.

STRING
     Absolute path to `phpstan' configuration file.

`(root . STRING)'
     Relative path to `phpstan' configuration file from project root directory.

NIL
     Search phpstan.neon(.dist) in (phpstan-get-working-dir).")
  (make-variable-buffer-local 'phpstan-config-file)
  (put 'phpstan-config-file 'safe-local-variable
       #'(lambda (v) (if (consp v)
                         (and (eq 'root (car v)) (stringp (cdr v)))
                       (null v) (stringp v)))))

;;;###autoload
(progn
  (defvar-local phpstan-autoload-file nil
    "Path to autoload file for PHPStan.

STRING
     Path to `phpstan' autoload file.

`(root . STRING)'
     Relative path to `phpstan' configuration file from project root directory.

NIL
     If `phpstan-enable-on-no-config-file', search \"vendor/autoload.php\" in (phpstan-get-working-dir).")
  (put 'phpstan-autoload-file 'safe-local-variable
       #'(lambda (v) (if (consp v)
                         (and (eq 'root (car v)) (stringp (cdr v)))
                       (null v) (stringp v)))))

;;;###autoload
(progn
  (defvar-local phpstan-level nil
    "Rule level of PHPStan.

INTEGER or STRING
     Number of PHPStan rule level.

max
     The highest of PHPStan rule level.

NIL
     Use rule level specified in `phpstan' configuration file.")
  (put 'phpstan-level 'safe-local-variable
       #'(lambda (v) (or (null v)
                         (integerp v)
                         (eq 'max v)
                         (and (stringp v)
                              (string= "max" v)
                              (string-match-p "\\`[0-9]\\'" v))))))

;;;###autoload
(progn
  (defvar phpstan-replace-path-prefix)
  (make-variable-buffer-local 'phpstan-replace-path-prefix)
  (put 'phpstan-replace-path-prefix 'safe-local-variable
       #'(lambda (v) (or (null v) (stringp v)))))

(defconst phpstan-docker-executable "docker")

;;;###autoload
(progn
  (defvar phpstan-executable nil
    "PHPStan excutable file.

STRING
     Absolute path to `phpstan' executable file.

`docker'
     Use Docker using phpstan/docker-image.

`(root . STRING)'
     Relative path to `phpstan' executable file.

`(STRING . (ARGUMENTS ...))'
     Command name and arguments.

NIL
     Auto detect `phpstan' executable file.")
  (make-variable-buffer-local 'phpstan-executable)
  (put 'phpstan-executable 'safe-local-variable
       #'(lambda (v) (if (consp v)
                         (or (and (eq 'root (car v)) (stringp (cdr v)))
                             (and (stringp (car v)) (listp (cdr v))))
                       (or (eq 'docker v) (null v) (stringp v))))))

;; Functions:
(defun phpstan-get-working-dir ()
  "Return path to working directory of PHPStan."
  (cond
   ((and phpstan-working-dir (consp phpstan-working-dir) (eq 'root (car phpstan-working-dir)))
    (expand-file-name (cdr phpstan-working-dir) (php-project-get-root-dir)))
   ((stringp phpstan-working-dir) phpstan-working-dir)
   (t (php-project-get-root-dir))))

(defun phpstan-enabled ()
  "Return non-NIL if PHPStan configured or Composer detected."
  (and (not (file-remote-p default-directory)) ;; Not support remote filesystem
       (or (phpstan-get-config-file)
           (phpstan-get-autoload-file)
           (and phpstan-enable-on-no-config-file
                (php-project-get-root-dir)))))

(defun phpstan-get-config-file ()
  "Return path to phpstan configure file or `NIL'."
  (if phpstan-config-file
      (if (and (consp phpstan-config-file)
               (eq 'root (car phpstan-config-file)))
          ;; Use (php-project-get-root-dir), not phpstan-working-dir.
          (expand-file-name (cdr phpstan-config-file) (php-project-get-root-dir))
        phpstan-config-file)
    (let ((working-directory (phpstan-get-working-dir)))
      (when working-directory
        (cl-loop for name in '("phpstan.neon" "phpstan.neon.dist")
                 for dir  = (locate-dominating-file working-directory name)
                 if dir
                 return (expand-file-name name dir))))))

(defun phpstan-get-autoload-file ()
  "Return path to autoload file or NIL."
  (when phpstan-autoload-file
    (if (and (consp phpstan-autoload-file)
             (eq 'root (car phpstan-autoload-file)))
        (expand-file-name (cdr phpstan-autoload-file) (php-project-get-root-dir))
      phpstan-autoload-file)))

(defun phpstan-normalize-path (source-original &optional source)
  "Return normalized source file path to pass by `SOURCE-ORIGINAL' OR `SOURCE'.

If neither `phpstan-replace-path-prefix' nor executable docker is set,
it returns the value of `SOURCE' as it is."
  (let ((root-directory (expand-file-name (php-project-get-root-dir)))
        (prefix
         (or phpstan-replace-path-prefix
             (cond
              ((eq 'docker phpstan-executable) "/app")
              ((and (consp phpstan-executable)
                    (string= "docker" (car phpstan-executable))) "/app")))))
    (if prefix
        (expand-file-name
         (replace-regexp-in-string (concat "\\`" (regexp-quote root-directory))
                                   ""
                                   source-original t t)
         prefix)
      (or source source-original))))

(defun phpstan-get-level ()
  "Return path to phpstan configure file or `NIL'."
  (cond
   ((null phpstan-level) nil)
   ((integerp phpstan-level) (int-to-string phpstan-level))
   ((symbolp phpstan-level) (symbol-name phpstan-level))
   (t phpstan-level)))

(defun phpstan-get-memory-limit ()
  "Return --memory-limit value."
  phpstan-memory-limit)

(defun phpstan-analyze-file (file)
  "Analyze a PHPScript FILE using PHPStan."
  (interactive "fChoose a PHP script: ")
  (compile (mapconcat #'shell-quote-argument (append (phpstan-get-command-args) (list file)) " ")))

(defun phpstan-get-executable ()
  "Return PHPStan excutable file and arguments."
  (cond
   ((eq 'docker phpstan-executable)
    (list "run" "--rm" "-v"
          (concat (expand-file-name (php-project-get-root-dir)) ":/app")
          phpstan-docker-image))
   ((and (consp phpstan-executable)
         (eq 'root (car phpstan-executable)))
    (list
     (expand-file-name (cdr phpstan-executable) (php-project-get-root-dir))))
   ((and (stringp phpstan-executable) (file-exists-p phpstan-executable))
    (list phpstan-executable))
   ((and phpstan-flycheck-auto-set-executable
         (listp phpstan-executable)
         (stringp (car phpstan-executable))
         (listp (cdr phpstan-executable)))
    (cdr phpstan-executable))
   ((null phpstan-executable)
    (let ((vendor-phpstan (expand-file-name "vendor/bin/phpstan"
                                            (php-project-get-root-dir))))
      (cond
       ((file-exists-p vendor-phpstan) (list vendor-phpstan))
       ((executable-find "phpstan") (list (executable-find "phpstan")))
       (t (error "PHPStan executable not found")))))))

(defun phpstan-get-command-args ()
  "Return command line argument for PHPStan."
  (let ((executable (phpstan-get-executable))
        (path (phpstan-normalize-path (phpstan-get-config-file)))
        (autoload (phpstan-get-autoload-file))
        (memory-limit (phpstan-get-memory-limit))
        (level (phpstan-get-level)))
    (append executable
            (list "analyze" "--error-format=raw" "--no-progress" "--no-interaction")
            (and path (list "-c" path))
            (and autoload (list "-a" autoload))
            (and memory-limit (list "--memory-limit" memory-limit))
            (and level (list "-l" level))
            (list "--"))))

(provide 'phpstan)
;;; phpstan.el ends here
