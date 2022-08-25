;;; helm-rails.el --- Helm extension for Rails projects.

;; Copyright (C) 2012 Adam Sokolnicki

;; Author:            Adam Sokolnicki <adam.sokolnicki@gmail.com>
;; URL:               https://github.com/asok/helm-rails
;; Package-Version: 20130424.1519
;; Package-Commit: 723c2a27f3843570ec1039e3c526953e48b4ed40
;; Version:           0.2
;; Keywords:          helm, rails, git
;; Package-Requires:  ((helm "1.5.1") (inflections "1.1"))

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
;;
;; Helm Rails extension provides snappy navigation through rails
;; projects. It is possible to traverse through
;; resource and files related to the current file.
;;
;;; Code:

(require 'helm-locate)
(require 'inflections)

(defgroup helm-rails nil
  "Helm completion for rails projects under git."
  :group 'helm)

(defcustom helm-rails-default-grep-exts
  '("*.rb" "*.html" "*.js" "*.erb" "*.haml" "*.slim" "*.yml" "*.yaml" "*.json" "*.coffee" "*.css" "*.scss" "*.sass")
  "Extenstions of files to look in when greping whole project with `helm-rails-grep-all'"
  :group 'helm-rails
  :type '(repeat string))

(defcustom helm-rails-views-grep-exts
  '("*.rb" "*.html" "*.js" "*.erb" "*.haml" "*.slim" "*.json" "*.coffee")
  "Extenstions of files to look in when greping views with `helm-rails-grep-views'"
  :group 'helm-rails
  :type '(repeat string))

(defcustom helm-rails-javascripts-grep-exts
  '("*.js" "*.coffee")
  "Extenstions of files to look in when greping javascripts with `helm-rails-grep-javascripts'"
  :group 'helm-rails
  :type '(repeat string))

(defcustom helm-rails-stylesheets-grep-exts
  '("*.css" "*.scss" "*.sass")
  "Extenstions of files to look in when greping stylesheets with `helm-rails-grep-stylesheets'"
  :group 'helm-rails
  :type '(repeat string))

(defvar helm-rails-resources-schema
  '((:name models
           :exts '("*.rb")
	   :re "^app/models/(.+)$"
	   :path "app/models/")
    (:name views
           :exts helm-rails-views-grep-exts
	   :re "^app/views/(.+)$"
	   :path "app/views/")
    (:name controllers
           :exts '("*.rb")
	   :re "^app/controllers/(.+)$"
	   :path "app/controllers/")
    (:name helpers
           :exts '("*.rb")
	   :re "^app/helpers/(.+)$"
	   :path "app/helpers/")
    (:name mailers
           :exts '("*.rb")
	   :re "^app/mailers/(.+)$"
	   :path "app/mailers/")
    (:name specs
           :exts '("*.rb")
	   :re "^spec/(.+_spec\.rb)$"
	   :path "spec/")
    (:name libs
           :exts '("*.rb")
	   :re "^lib/(.+)$"
	   :path "lib/")
    (:name javascripts
           :exts helm-rails-javascripts-grep-exts
	   :re "^(public/javascripts/.+|app/assets/javascripts/.+|lib/assets/javascripts/.+|vendor/assets/javascripts/.+)$"
	   :path "")
    (:name stylesheets
           :exts helm-rails-stylesheets-grep-exts
	   :re "^(public/stylesheets/.+|app/assets/stylesheets/.+)$"
	   :path "")
    (:name all
           :exts helm-rails-default-grep-exts
	   :re "^(.+)$"
	   :path "")
    )
  )

(defvar helm-rails-not-found-c-source
  '((name . "Run helm-rails-all")
    (dummy)
    (action . (lambda (c) (helm-rails-all c)))))

(defmacro helm-rails-def-c-source (name path regexp)
  `(defvar ,(intern (format "helm-rails-%S-c-source" name))
     '((name . ,(format "%S" name))
       (helm-rails-relative-path . ,(format "%s" path))
       (init . (lambda ()
		 (helm-init-candidates-in-buffer
		  'local
		  (helm-rails-seded-files ,regexp))))
       (candidates-in-buffer)
       (help-message . helm-generic-file-help-message)
       (candidate-number-limit . 30)
       (mode-line . helm-generic-file-mode-line-string)
       (filtered-candidate-transformer . helm-rails-transformer)
       (action . ,(cdr (helm-get-actions-from-type helm-source-locate)))
       (type . file)))
  )

(defmacro helm-rails-def-current-scope-c-source (name)
  `(defvar ,(intern (format "helm-rails-current-scope-%S-c-source" name))
     '((name . "current scope")
       (helm-rails-relative-path . "")
       (init . (lambda ()
  		 (helm-init-candidates-in-buffer 'local
						 (helm-rails-current-scope-files
						  (quote ,(intern (format "%S" name)))))))
       (candidates-in-buffer)
       (help-message . helm-generic-file-help-message)
       (candidate-number-limit . 10)
       (mode-line . helm-generic-file-mode-line-string)
       (filtered-candidate-transformer . helm-rails-transformer)
       (action . ,(cdr (helm-get-actions-from-type helm-source-locate)))
       (type . file)))
  )

(defmacro helm-rails-def-command (name)
  `(defun ,(intern (format "helm-rails-%S" name)) (&optional input)
     ,(format "Search for %S" name)
     (interactive)
     (unless (helm-rails-project-p)
       (error "Not inside a rails git repository"))
     (helm :sources (list
		     ,(intern (format "helm-rails-current-scope-%S-c-source" name))
		     ,(intern (format "helm-rails-%S-c-source" name))
                     ,(unless (string= "all" name) 'helm-rails-not-found-c-source)
		     )
           :input input
	   :prompt ,(format "%S: " name))
     )
  )

(defmacro helm-rails-def-grep-command (name path exts)
  `(defun ,(intern (format "helm-rails-grep-%S" name)) ()
     ,(format "Grep %S" name)
     (interactive)
     (helm-do-grep-1
      (list (concat (helm-rails-root) ,path)) t nil ,exts )))

(defun helm-rails-current-resource ()
  "Returns a resource name extracted from the name of the currently visiting file"
  (let ((file-name (buffer-file-name)))
    (if file-name
        (singularize-string
         (catch 'break (loop
                        for re in '("app/models/\\(.+\\)\\.rb$"
                                    "/\\([a-z_]+\\)_controller\\.rb$"
                                    "app/views/\\(.+\\)/[^/]+$"
                                    "app/helpers/\\(.+\\)_helper\\.rb$"
                                    "spec/.*/\\([a-z_]+?\\)\\(_controller\\)?_spec\\.rb$")
                        do (if (string-match re file-name)
                               (throw 'break (match-string 1 file-name)))))))
    )
  )

(defun helm-rails-transformer (candidates source)
  (loop with root = (helm-rails-root)
        for i in candidates
        collect
        (cons
         (propertize (cdr i) 'face 'helm-ff-file)
         (expand-file-name (concat (assoc-default 'helm-rails-relative-path source) (cdr i)) root))))

(defun helm-rails-root ()
  "Returns root of the rails git project"
  (let ((root (locate-dominating-file default-directory ".git")))
    (and root (file-name-as-directory (file-truename root)))))

(defun helm-rails-file-relative-path (file-name)
  (when file-name
    (substring (file-truename file-name) (length (helm-rails-root)))))

(defun helm-rails-git-output (command)
  (let ((file-path (helm-rails-file-relative-path (buffer-file-name)))
        (args (format "( git ls-files --full-name --other --exclude-standard ; git ls-files --full-name -- %s ) | %s" (helm-rails-root) command))
        (shell-file-name "/bin/bash"))
    (shell-command-to-string (if file-path (concat args " | grep -v " file-path) args))))

(defun helm-rails-seded-files (regexp)
  "Returns output of git ls-files sed-ed against given regexp.
The regexp should include one match group. Each line of the output
will be truncated to hold only the contents of the match group.
It excludes the currently visiting file."
  (helm-rails-git-output (format "sed -nE 's;%s;\\1;p'" regexp)))

(defun helm-rails-greped-files (regexp)
  "Returns output of git ls-files greped against given regexp.
It excludes the currently visiting file."
  (helm-rails-git-output (format "grep -E %s" regexp)))

(defun helm-rails-current-scope-files (target)
  (let ((current-resource (helm-rails-current-resource)))
    (if current-resource
        (helm-rails-greped-files
         (cond ((equal target 'models)
                (format "app/models/%s\.rb" current-resource))
               ((equal target 'javascripts)
                (format "app/assets/javascripts/\\(.+/\\)?%s\\..+" (pluralize-string current-resource)))
               ((equal target 'stylesheets)
                (format "app/assets/stylesheets/\\(.+/\\)?%s\\..+" (pluralize-string current-resource)))
               ((equal target 'controllers)
                (format "app/controllers/\\(.+/\\)?%s_controller\\.rb" (pluralize-string current-resource)))
               ((equal target 'helpers)
                (format "app/helpers/%s_helper\.rb" (pluralize-string current-resource)))
               ((equal target 'views)
                (format "app/views/\\(.+/\\)?%s/[^/]+" (pluralize-string current-resource)))
               ((equal target 'specs)
                (format "spec/.*\\(%s_controller\\|%s\\|%s_helper\\)_spec\\.rb"
                        (pluralize-string current-resource)
                        current-resource
                        (pluralize-string current-resource)))
               )
         )
      '()
      )
    )
  )

(defun helm-rails-project-p ()
  "Returns t if we are inside a rails git repository"
  (condition-case nil
      (file-exists-p (expand-file-name "config/environment.rb" (helm-rails-root)))
    (error nil)))

(defun helm-rails-def-resource (name path re &optional exts)
  (eval
   `(progn
      (helm-rails-def-c-source ,name ,path ,re)
      (helm-rails-def-current-scope-c-source ,name)
      (helm-rails-def-command ,name)
      (helm-rails-def-grep-command ,name ,path (or ,exts helm-rails-default-grep-exts)))))

(loop for resource in helm-rails-resources-schema
      do (helm-rails-def-resource (plist-get resource :name)
                                  (plist-get resource :path)
                                  (plist-get resource :re)
                                  (plist-get resource :exts)))

(provide 'helm-rails)

;;; helm-rails.el ends here
