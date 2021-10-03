;;; psalm.el --- Interface to Psalm              -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 31 Mar 2020
;; Version: 0.6.0
;; Package-Version: 20211002.1552
;; Package-Commit: 28d546a79cb865a78b94cd7e929d66d720505faa
;; Keywords: tools, php
;; Homepage: https://github.com/emacs-php/psalm.el
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

;; Static analyze for PHP code using Psalm.
;; https://psalm.dev/
;;
;; ## Instalation
;;
;; You need to get either the local PHP runtime or Docker and prepare for Psalm.
;; Please read the README for these details.
;; https://github.com/emacs-php/psalm.el/blob/master/README.org
;;
;; If you are a Flycheck user, install `flycheck-psalm' package.
;;
;; ## Directory local variables
;;
;; Put the following into .dir-locals.el files on the root directory of project.
;; Each variable can read what is documented by `M-x describe-variables'.
;;
;;     ((nil . ((php-project-root . git)
;;              (psalm-executable . docker)
;;              (psalm-working-dir . (root . "path/to/dir"))
;;              (psalm-config-file . (root . "path/to/dir/psalm-docker.xml")))
;;
;; If you want to know the directory variable specification, please refer to
;; M-x info [Emacs > Customization > Variables] or the following web page.
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html
;;

;;; Code:
(require 'php-project)


;; Variables:

(defgroup psalm nil
  "Interaface to Psalm"
  :tag "Psalm"
  :prefix "psalm-"
  :group 'tools
  :group 'php
  :link '(url-link :tag "Psalm" "https://github.com/psalm/psalm")
  :link '(url-link :tag "psalm.el" "https://github.com/emacs-php/psalm.el"))

(defcustom psalm-flycheck-auto-set-executable t
  "Set flycheck `psalm-executable' automatically."
  :type 'boolean
  :group 'psalm)

(defcustom psalm-enable-on-no-config-file nil
  "If T, activate configuration from composer even when `psalm.xml' is not found."
  :type 'boolean
  :group 'psalm)

(defcustom psalm-show-info t
  "If non-NIL, add `--show-info=true' option to command line argument."
  :type 'boolean
  :local t
  :safe #'booleanp
  :group 'psalm)

(defcustom psalm-docker-image nil
  "Docker image name for execute Psalm command."
  :type '(choice
          (string :tag "DockerHub image name")
          (const :tag "Unspecified" null))
  :group 'psalm)

;;;###autoload
(progn
  (defvar psalm-working-dir nil
    "Path to working directory of Psalm.

*NOTICE*: This is different from the project root.

STRING
     Absolute path to `psalm' working directory.

`(root . STRING)'
     Relative path to `psalm' working directory from project root directory.

NIL
     Use (php-project-get-root-dir) as working directory.")
  (make-variable-buffer-local 'psalm-working-dir)
  (put 'psalm-working-dir 'safe-local-variable
       #'(lambda (v) (if (consp v)
                         (and (eq 'root (car v)) (stringp (cdr v)))
                       (null v) (stringp v)))))

;;;###autoload
(progn
  (defvar psalm-config-file nil
    "Path to project specific configuration file of Psalm.

STRING
     Absolute path to `psalm' configuration file.

`(root . STRING)'
     Relative path to `psalm' configuration file from project root directory.

NIL
     Search psalm.xml(.dist) in (psalm-get-working-dir).")
  (make-variable-buffer-local 'psalm-config-file)
  (put 'psalm-config-file 'safe-local-variable
       #'(lambda (v) (if (consp v)
                         (and (eq 'root (car v)) (stringp (cdr v)))
                       (null v) (stringp v)))))

;;;###autoload
(progn
  (defvar psalm-replace-path-prefix)
  (make-variable-buffer-local 'psalm-replace-path-prefix)
  (put 'psalm-replace-path-prefix 'safe-local-variable
       #'(lambda (v) (or (null v) (stringp v)))))

(defconst psalm-docker-executable "docker")

;;;###autoload
(progn
  (defvar psalm-executable nil
    "Psalm excutable file.

STRING
     Absolute path to `psalm' executable file.

`docker'
     Use Docker using psalm/docker-image.

`(root . STRING)'
     Relative path to `psalm' executable file.

`(STRING . (ARGUMENTS ...))'
     Command name and arguments.

NIL
     Auto detect `psalm' executable file.")
  (make-variable-buffer-local 'psalm-executable)
  (put 'psalm-executable 'safe-local-variable
       #'(lambda (v) (if (consp v)
                         (or (and (eq 'root (car v)) (stringp (cdr v)))
                             (and (stringp (car v)) (listp (cdr v))))
                       (or (eq 'docker v) (null v) (stringp v))))))

;; Functions:
(defun psalm-get-working-dir ()
  "Return path to working directory of Psalm."
  (cond
   ((and psalm-working-dir (consp psalm-working-dir) (eq 'root (car psalm-working-dir)))
    (expand-file-name (cdr psalm-working-dir) (php-project-get-root-dir)))
   ((stringp psalm-working-dir) psalm-working-dir)
   (t (php-project-get-root-dir))))

(defun psalm-enabled ()
  "Return non-NIL if Psalm configured or Composer detected."
  (and (not (file-remote-p default-directory)) ;; Not support remote filesystem
       (or (psalm-get-config-file)
           (and psalm-enable-on-no-config-file
                (php-project-get-root-dir)))))

(defun psalm-get-config-file ()
  "Return path to psalm configure file or `NIL'."
  (if psalm-config-file
      (if (and (consp psalm-config-file)
               (eq 'root (car psalm-config-file)))
          ;; Use (php-project-get-root-dir), not psalm-working-dir.
          (expand-file-name (cdr psalm-config-file) (php-project-get-root-dir))
        psalm-config-file)
    (let ((working-directory (psalm-get-working-dir)))
      (when working-directory
        (cl-loop for name in '("psalm.xml" "psalm.xml.dist")
                 for dir  = (locate-dominating-file working-directory name)
                 if dir
                 return (expand-file-name name dir))))))

(defun psalm-normalize-path (source-original &optional source)
  "Return normalized source file path to pass by `SOURCE-ORIGINAL' OR `SOURCE'.

If neither `psalm-replace-path-prefix' nor executable docker is set,
it returns the value of `SOURCE' as it is."
  (let ((root-directory (expand-file-name (php-project-get-root-dir)))
        (prefix
         (or psalm-replace-path-prefix
             (cond
              ((eq 'docker psalm-executable) "/app")
              ((and (consp psalm-executable)
                    (string= "docker" (car psalm-executable))) "/app")))))
    (if prefix
        (expand-file-name
         (replace-regexp-in-string (concat "\\`" (regexp-quote root-directory))
                                   ""
                                   source-original t t)
         prefix)
      (or source source-original))))

(defun psalm-get-executable ()
  "Return Psalm excutable file and arguments."
  (cond
   ((eq 'docker psalm-executable)
    (if (null psalm-docker-image)
        (user-error "Not specified psalm-docker-image to execute Psalm")
      (list "run" "--rm" "-v"
            (concat (expand-file-name (php-project-get-root-dir)) ":/app")
            psalm-docker-image)))
   ((and (consp psalm-executable)
         (eq 'root (car psalm-executable)))
    (list
     (expand-file-name (cdr psalm-executable) (php-project-get-root-dir))))
   ((and (stringp psalm-executable) (file-exists-p psalm-executable))
    (list psalm-executable))
   ((and psalm-flycheck-auto-set-executable
         (listp psalm-executable)
         (stringp (car psalm-executable))
         (listp (cdr psalm-executable)))
    (cdr psalm-executable))
   ((null psalm-executable)
    (let ((vendor-psalm (expand-file-name "vendor/bin/psalm"
                                            (php-project-get-root-dir))))
      (cond
       ((file-exists-p vendor-psalm) (list vendor-psalm))
       ((executable-find "psalm") (list (executable-find "psalm")))
       ((executable-find "psalm.phar") (list (executable-find "psalm.phar")))
       (t (error "Psalm executable not found")))))))

(defun psalm-get-command-args ()
  "Return command line argument for Psalm."
  (let ((executable (psalm-get-executable))
        (path (psalm-normalize-path (psalm-get-config-file))))
    (append executable
            (list "--no-progress" "--output-format=emacs")
            (when psalm-show-info (list "--show-info=true"))
            (and path (list "-c" path))
            (list "--"))))

(provide 'psalm)
;;; psalm.el ends here
