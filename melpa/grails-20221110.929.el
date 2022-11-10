;;; grails.el --- Minor mode for Grails projects
;;
;; Copyright (c) 2016 Alessandro Miliucci
;;
;; Authors: Alessandro Miliucci <lifeisfoo@gmail.com>
;; Version: 0.4.1
;; Package-Version: 20221110.929
;; Package-Commit: 3019f86e555ee94388795a0475cfa213e3897bbb
;; URL: https://github.com/lifeisfoo/emacs-grails
;; Package-Requires: ((emacs "24"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Description:

;; Grails.el is a minor mode that allows an easy
;; navigation of Gails projects.  It allows jump to a model, to a view,
;; to a controller or to a service.

;; Features:
;;  - Jump to the related Domain (from the current buffer)
;;  - Jump to the related Controller (from the current buffer)
;;  - Jump to the related Service (from the current buffer)
;;  - Jump to the related view(s) (from the current buffer)
;;  - Open the Bootstrap file
;;  - Open the UrlMappings file
;;  - Find file prompt for domain classes
;;  - Find file prompt for controller classes
;;  - Find file prompt for service classes
;;  - Find file prompt for views

;; For the complete documentation, see the project page at

;; https://github.com/lifeisfoo/emacs-grails

;; Installation:

;; Copy this file to to some location in your Emacs load path.  Then add
;; "(require 'grails)" to your Emacs initialization (.emacs,
;; init.el, or something).

;; Example config:

;;   (require 'grails)

;; To auto enable grails minor mode, create a .dir-locals.el file
;; in the root of the grails project with this configuration:

;;    ((nil . ((grails . 1))))

;; In this way, the grails minor mode will be always active inside your project tree.
;; The first time that this code is executed, Emacs will show a security
;; prompt: answer "!" to mark code secure and save your decision (a configuration
;; line is automatically added to your .emacs file).

;; Otherwise, if you want to have grails mode auto enabled only
;; when using certain major modes, place this inside your `.dir-locals.el`:

;;     ((groovy-mode (grails . 1))
;;     (html-mode (grails . 1))
;;     (java-mode (grails . 1)))

;; In this way, the grails mode will be auto enabled when any of
;; these modes are loaded (only in this directory tree - the project tree)
;; (you can attach it to other modes if you want).

;;; Code:

(defcustom grails-base-package ""
  "Grails source code base package."
  :type 'string
  :group 'grails)

(eval-and-compile
  (defvar grails-dir-name-by-type
    '((controller "controllers")
      (domain "domain")
      (service "services")
      (view "views"))))

(defvar grails-postfix-by-type
  '((controller "Controller.groovy")
    (domain ".groovy")
    (service "Service.groovy")
    (view ".gsp")))

(defvar grails-properties-by-version
  '((2 "application.properties" "^app.grails.version=")
    (3 "gradle.properties" "^grailsVersion=")
    (4 "gradle.properties" "^grailsVersion=")
    (5 "gradle.properties" "^grailsVersion=")    
    ))

(defvar grails-source-code-base-directory
  (s-replace "." "\/" grails-base-package)
  )

(defvar grails-urlmappings-by-version
  `((2 "conf/UrlMappings.groovy")
    (3 "controllers/UrlMappings.groovy")
    (4 ,(concat "controllers/" grails-source-code-base-directory "/UrlMappings.groovy"))
    (5 ,(concat "controllers/" grails-source-code-base-directory "/UrlMappings.groovy"))
    ))

;; TODO: refactor using only one list
(defvar grails-bootstrap-by-version
  `((2 "conf/BootStrap.groovy")
    (3 "init/BootStrap.groovy")
    (4 ,(concat "init/" grails-source-code-base-directory "/BootStrap.groovy"))
    (5 ,(concat "init/" grails-source-code-base-directory "/BootStrap.groovy"))
    ))

;;
;;
;; Utils functions
;;
;;

(defun util-string-from-file (file-path)
  "Return a string with file-path contents."
  (with-temp-buffer
    (insert-file-contents file-path)
    (buffer-string)))

;;
;;
;; Internal functions (non interactive)
;;
;;

(defun grails-grep-version (string)
  "Try all regex on the string to detect major version.

  E.g. string=grailsVersion=3.0.1 will return 3
  "
  (let (version)
    (dolist (elt grails-properties-by-version version)
      (if (string-match (car (cddr elt)) string)
          (setq version (car elt))))))

(defun grails-version-detect (file-path)
  "Try to detect the Grails version of the project from file-path.

   Grails 2 projects have an application.properties file.
   Grails 3 projects have a gradle.properties file.
  "
  (let (version)
    (dolist (elt grails-properties-by-version version)
      (let ((prop-file
             (concat (grails-project-root file-path) (car (cdr elt)))))
        (if (file-readable-p prop-file)
            (setq version
                  (grails-grep-version
                   (util-string-from-file prop-file))))))))

(defun grails-dir-by-type-and-name (type class-name base-path)
  "Return the file path (string) for the type and the class-name.
  
   E.g. type='domain, class-name=User and base-path=/prj/grails-app/
        will output /prj/grails-app/domain/User.groovy
  "
  (concat
   base-path
   (car (cdr (assoc type grails-dir-name-by-type)))
   "/"
   class-name
   (car (cdr (assoc type grails-postfix-by-type)))))

(defun grails-extract-name (file-path grails-type)
  "Transform MyClassController.groovy to MyClass, 
   or my/package/MyClassController.groovy to my/package/MyClass.
  "
  (cond ((eq grails-type 'controller)
         (let ((end (string-match "Controller\.groovy" file-path)))
           (substring file-path 0 end)))
        ((eq grails-type 'domain)
         (let ((end (string-match "\.groovy" file-path)))
           (substring file-path 0 end)))
        ((eq grails-type 'view)
         (error "Jumping from views isn't supported"))
        ((eq grails-type 'service)
         (let ((end (string-match "Service\.groovy" file-path)))
           (substring file-path 0 end)))
        (t (error "Grails type not recognized"))))

;;TODO - remove duplicated code
(defun grails-type-by-dir (file)
  "Detect current file type using its path"
  (string-match "\\(^.*/grails-app/\\)\\([a-zA-Z]+\\)/\\(.*\\)" file)
  (let ((dir-type (match-string 2 file)))
    (car (rassoc (cons dir-type '()) grails-dir-name-by-type))))

(defun grails-clean-name (file)
  "Detect current file type and extract it's clean class-name.

  E.g. ~/prj/grails-app/controllers/UserController.groovy
  will results in User

  Or ~/grails-app/domain/pkg/User.groovy
  will results in pkg/User
  "
  (string-match "\\(^.*/grails-app/\\)\\([a-zA-Z]+\\)/\\(.*\\)" file)
  (let ((base-path (match-string 1 file))
        (dir-type (match-string 2 file))
        (file-path (match-string 3 file)))
    (let ((grails-type (car (rassoc (cons dir-type '()) grails-dir-name-by-type))))
      (if grails-type
          (grails-extract-name file-path grails-type)
        (error "Current Grails filetype not recognized")))))

(defun grails-clean-name-no-pkg (file)
  "Same as grails-clean-name but without package prefix"
  (let ((clean-name (grails-clean-name file)))
    (string-match "\\([a-zA-Z0-9]+\\)$" clean-name)
    (match-string 1 clean-name)))

(defun grails-app-base (path)
  "Get the current grails app base path /my/abs/path/grails-app/.

  If exists return the app base path, else return nil.

  path must be a file or must end with / - see file-name-directory doc
  "
  (let ((project-root (grails-project-root path)))
    (if project-root
        (concat project-root "grails-app/")
      (error "Grails app not found"))))

(defun grails-project-root (path)
  "Find project root for dir.

  path must be a file or must end with / - see file-name-directory doc.
  "
  (locate-dominating-file (file-name-directory path) "grails-app"))

(defun grails-find-file-auto (grails-type current-file)
  "Generate the corresponding file path for the current-file and grails-type.

   grails-type is a symbol (e.g. 'domain, 'controller, 'service)
   current-file is a file path
      
   E.g. (grails-find-file-auto 
          'domain'
          '~/prj/grails-app/controllers/UserController.groovy')
   Will output: '~/prj/grails-app/domain/User.groovy'

  "
  (let ((base-path (grails-app-base current-file))
	(class-name (grails-clean-name current-file)))
    (grails-dir-by-type-and-name grails-type class-name base-path)))

(defun grails-string-is-action (line)
  "Detect if line contains a controller action name"
  (if (string-match "^.*def[[:blank:]]+\\([a-zA-Z0-9]+\\)[[:blank:]]*(.*).*{" line)
      (match-string 1 line)
    nil))

(defun grails-current-line-number ()
  "Return the current buffer line (cursor)"
  (1+ (count-lines 1 (point))))

(defun grails-find-current-controller-action ()
  "Loop from the current line backwards, looking for a controller action definition."
  (let ((continue 'true)
        (action-name nil))
;;  (setq continue 'true)
;;  (setq action-name nil)
    (save-excursion
      (while continue
        (if (> (grails-current-line-number) 1)
            (let ((cur-line
                   (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
              (if (grails-string-is-action cur-line)
                  (progn (setq continue nil) ;;break
                         (setq action-name (grails-string-is-action cur-line))))
              (forward-line -1))
          (setq continue nil)))
      (if action-name
          action-name
        (error "Action name not found")))))

(defun grails-view-from-string (view-name)
  "Open a view for the current controller and the view-name."
  (if (eq 'controller (grails-type-by-dir (buffer-file-name)))
      (switch-to-buffer
       (find-file-noselect
        (concat
         (grails-app-base (buffer-file-name))
         "views/"
         (downcase (grails-clean-name-no-pkg (buffer-file-name)))
         "/"
         view-name
         ".gsp")))
    (error "This is not a controller class")))

;;
;;
;; INTERACTIVE FUNCTIONS
;;
;;

(defun grails-version ()
  "Show Grails version for the project in the minibuffer"
  (interactive)
  (let ((version (grails-version-detect (buffer-file-name))))
    (if version
        (message (concat "Grails " (number-to-string version)))
      (error "Grails version not found"))))

;; TODO: refactor using a macro
(defun grails-urlmappings-file ()
  "Open the UrlMappings file"
  (interactive)
  (let ((version (grails-version-detect (buffer-file-name))))
    (if version
        (switch-to-buffer
         (find-file-noselect
          (concat (grails-app-base (buffer-file-name))
                  (car (cdr (assoc version grails-urlmappings-by-version))))))
      (error "Grails version not found"))))

;; TODO: refactor using a macro
(defun grails-bootstrap-file ()
  "Open the Bootstrap file"
  (interactive)
  (let ((version (grails-version-detect (buffer-file-name))))
    (if version
        (switch-to-buffer
         (find-file-noselect
          (concat (grails-app-base (buffer-file-name))
                  (car (cdr (assoc version grails-bootstrap-by-version))))))
      (error "Grails version not found"))))

(defun grails-view-from-cursor ()
  "Open a view from the current cursor."
  (interactive)
  (grails-view-from-string (thing-at-point 'word)))

(defun grails-view-from-context ()
  "Open a view for the current controller action."
  (interactive)
  (grails-view-from-string (grails-find-current-controller-action)))

(defmacro grails-fun-gen-from-file (grails-type)
  (let ((funsymbol (intern (concat "grails-" (symbol-name grails-type) "-from-file"))))
    `(defun ,funsymbol () (interactive) (switch-to-buffer
					 (find-file-noselect
					  (grails-find-file-auto
					   ',grails-type (buffer-file-name)))))))

(defmacro grails-fun-gen-from-name (grails-type)
  (let ((funsymbol (intern (concat "grails-" (symbol-name grails-type) "-from-name"))))
    `(defun ,funsymbol () (interactive)
	    (let ((x
		   (read-file-name
		    "Enter file name:"
		    (concat
		     (grails-app-base (buffer-file-name))
		     ,(concat (car (cdr (assoc grails-type grails-dir-name-by-type)))  "/")))))
	      (switch-to-buffer
	       (find-file-noselect x))))))

(defvar grails-key-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "C-c - d") (grails-fun-gen-from-file domain))
    (define-key keymap (kbd "C-c - c") (grails-fun-gen-from-file controller))
    (define-key keymap (kbd "C-c - s") (grails-fun-gen-from-file service))
    (define-key keymap (kbd "C-c - v v") 'grails-view-from-context)
    (define-key keymap (kbd "C-c - v w") 'grails-view-from-cursor)
    (define-key keymap (kbd "C-c - n d") (grails-fun-gen-from-name domain))
    (define-key keymap (kbd "C-c - n c") (grails-fun-gen-from-name controller))
    (define-key keymap (kbd "C-c - n s") (grails-fun-gen-from-name service))
    (define-key keymap (kbd "C-c - n v") (grails-fun-gen-from-name view))
    ;; p for project properties - TODO: show more information
    (define-key keymap (kbd "C-c - p") 'grails-version)
    (define-key keymap (kbd "C-c - u") 'grails-urlmappings-file)
    (define-key keymap (kbd "C-c - b") 'grails-bootstrap-file)
    keymap)
  "Keymap for `grails` mode.")

;;;###autoload
(define-minor-mode grails
  "Grails minor mode.
     With no argument, this command toggles the mode.
     Non-null prefix argument turns on the mode.
     Null prefix argument turns off the mode.
     When Grails minor mode is enabled you have some
     shortcut to fast navigate a Grails project."
  :init-value nil
  :lighter " Grails"
  :keymap grails-key-map
  :group 'grails)

(provide 'grails)

;;; grails.el ends here
