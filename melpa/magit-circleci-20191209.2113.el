;;; magit-circleci.el --- CircleCI integration for Magit -*- lexical-binding: t; -*-

;; Copyright (C) 2019, Adrien Brochard

;; This file is NOT part of Emacs.

;; This  program is  free  software; you  can  redistribute it  and/or
;; modify it  under the  terms of  the GNU  General Public  License as
;; published by the Free Software  Foundation; either version 2 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT  ANY  WARRANTY;  without   even  the  implied  warranty  of
;; MERCHANTABILITY or FITNESS  FOR A PARTICULAR PURPOSE.   See the GNU
;; General Public License for more details.

;; You should have  received a copy of the GNU  General Public License
;; along  with  this program;  if  not,  write  to the  Free  Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
;; USA

;; Version: 1.0
;; Package-Version: 20191209.2113
;; Package-Commit: 2d4bdacf498ed3ff7d2c3574d346b2d24cbb12da
;; Author: Adrien Brochard
;; Keywords: circleci continuous integration magit vc tools
;; URL: https://github.com/abrochard/magit-circleci
;; License: GNU General Public License >= 3
;; Package-Requires: ((dash "2.16.0") (transient "0.1.0") (magit "2.90.0") (emacs "25.3"))

;;; Commentary:

;; Magit extension to integrate with CircleCI.
;; See the latest builds from the magit status buffer.

;;; Setup:

;; Get your token (https://circleci.com/docs/api/#add-an-api-token)
;; and shove it as (setq magit-circleci-token "XXXXXXXX")
;; or set it as environment variable CIRCLECI_TOKEN

;;; Usage:

;; M-x magit-circleci-mode : to activate
;; C-c C-o OR RET : to visit the build at point
;; " : in magit status to open the CircleCI Menu
;; " f : to pull latest builds for the current repo


;;; Customization:

;; By default, the extension fetches and shows the last 5 builds,
;; you can change that by customizing the `magit-circleci-n-builds' variable.

;;; Code:

(require 'json)
(require 'url-http)
(require 'magit)
(require 'transient)
(require 'dash)

(defvar url-http-end-of-headers)  ; silence byte-compiler warnings

(defgroup magit-circleci nil
  "CircleCI integration for Magit."
  :group 'extensions
  :group 'tools
  :link '(url-link :tag "Repository" "https://github.com/abrochard/magit-circleci"))

(defcustom magit-circleci-host "https://circleci.com"
  "CircleCI API host."
  :group 'magit-circleci
  :type 'string)

(defvar magit-circleci-token
  (getenv "CIRCLECI_TOKEN"))

(defcustom magit-circleci-n-builds 5
  "Total number of builds per project requested from CircleCI API."
  :group 'magit-circleci
  :type 'number)

(defvar magit-circleci--cache nil)

(defun magit-circleci--request (method endpoint &rest args)
  "Make a request to the circleCI API.

METHOD is the request mothod.
ENDPOINT is the endpoint.
ARGS is the url arguments."
  (let ((url (concat magit-circleci-host "/api/v1.1" endpoint
                     "?circle-token=" magit-circleci-token
                     "&" (mapconcat #'identity args "&")))
        (url-request-method method)
        (url-request-extra-headers '(("Accept" . "application/json"))))
    (with-current-buffer (url-retrieve-synchronously url)
      (goto-char url-http-end-of-headers)
      (json-read)))) ;; TODO: utf-8 support

(defun magit-circleci--projects ()
  "Get all the projects from CircleCI."
  (mapcar (lambda (x) (list (assoc 'reponame x) (assoc 'username x) (assoc 'vcs_type x)))
          (magit-circleci--request "GET" "/projects")))

(defun magit-circleci--recent-builds (vcs-type username project)
  "Get the most recent builds.

VCS-TYPE is the csv type.
USERNAME is the username.
PROJECT is the project name."
  (mapcar (lambda (x) (list (assoc 'status x) (assoc 'subject x)
                            (assoc 'build_url x) (assoc 'build_num x)
                            (assoc 'workflow_id (assoc 'workflows x))
                            (assoc 'job_name (assoc 'workflows x))
                            (assoc 'workflow_name (assoc 'workflows x))))
          (magit-circleci--request
           "GET"
           (format "/project/%s/%s/%s" vcs-type username project)
           (format "limit=%s" magit-circleci-n-builds))))

(defun magit-circleci--current-project ()
  "Get the current CircleCI project."
  (let ((reponame (magit-circleci--reponame)))
    (car (seq-filter (lambda (x) (equal reponame (cdr (assoc 'reponame x))))
                     (magit-circleci--projects)))))

;; (defun magit-circleci--last-builds ()
;;   "Fetch last builds for current project."
;;   (let ((project (magit-circleci--current-project)))
;;     (when project
;;       (let ((reponame (cdr (assoc 'reponame project)))
;;             (vcs-type (cdr (assoc 'vcs_type project)))
;;             (username (cdr (assoc 'username project))))
;;         (magit-circleci--recent-builds vcs-type username reponame)))))

(defun magit-circleci--reponame ()
  "Get the name of the current repo."
  (file-name-nondirectory (directory-file-name (magit-toplevel))))

(defun magit-circleci--repo-has-config ()
  "Look if current repo has a circle config."
  (file-exists-p (concat (magit-toplevel) ".circleci/config.yml")))

(defun magit-circleci--find-build (repo build-num)
  "Find the specific build from cache.

REPO is the repo name.
BUILD-NUM is the build number."
  (car (seq-filter (lambda (x) (equal build-num (cdr (assoc 'build_num x))))
                   (cdr (assoc repo magit-circleci--cache)))))

(defun magit-circleci--cache-file-location ()
  "Get the filename of the cache file for current repo."
  (format "%s.git/circleci" (magit-toplevel)))

(defun magit-circleci--cache-file-exists ()
  "Return t if the cache file exists."
  (file-exists-p (magit-circleci--cache-file-location)))

(defun magit-circleci--write-cache-file (data)
  "Write the cache data to a `circleci` file in the .git folder.

DATA is the circleci data."
  (with-temp-buffer
    (prin1 data (current-buffer))
    (write-file (magit-circleci--cache-file-location))))

(defun magit-circleci--read-cache-file ()
  "Read the data that was cached into the `circleci` file in the .git folder."
  (car (read-from-string (with-temp-buffer
                           (insert-file-contents (magit-circleci--cache-file-location))
                           (buffer-string)))))

(defun magit-circleci--update-cache (reponame data)
  "Update the memory cache with data for reponame.

REPONAME is the name of the repo.
DATA is the circleci data."
  (delete (assoc reponame magit-circleci--cache) magit-circleci--cache)
  (push (cons reponame data) magit-circleci--cache)
  (magit-circleci--write-cache-file data))

(defun magit-circleci-pull ()
  "Pull last builds of current repo and put them in cache."
  (interactive)
  (when (magit-circleci--repo-has-config)
    (let ((project (magit-circleci--current-project)))
      (when project
        (let ((reponame (cdr (assoc 'reponame project)))
              (vcs-type (cdr (assoc 'vcs_type project)))
              (username (cdr (assoc 'username project))))
          (magit-circleci--update-cache reponame (magit-circleci--recent-builds vcs-type username reponame))
          (message "Done")
          (magit))))))

(defun magit-circleci-browse-build ()
  "Browse build under cursor."
  (interactive)
  (let ((build-num (save-excursion (beginning-of-line)
                                   (number-at-point)))
        (repo (magit-circleci--reponame)))
    (when build-num
      (browse-url
       (alist-get 'build_url (magit-circleci--find-build repo build-num))))))

(defun magit-circleci--insert-build (build)
  "Insert current build.

BUILD is the build object."
  (let ((status (cdr (assoc 'status build)))
        (subject (cdr (assoc 'subject build)))
        (num (cdr (assoc 'build_num build))))
    (magit-section-hide
     (magit-insert-section (circleci)
       (magit-insert-heading
         (concat (propertize (format "%s" num) 'face
                             (if (equal status "success") 'success 'error))
                 (format " %s\n" (cdr (assoc 'job_name build)))))))))

(defun magit-circleci--insert-workflow (builds)
  "Insert the builds as workflows.

BUILDS are the circleci builds."
  (let ((name (cdr (assoc 'workflow_name (nth 1 builds))))
        (subject (cdr (assoc 'subject (nth 1 builds)))))
    (magit-insert-section (workflow)
      (magit-insert-heading (propertize (format "%s / %s" name subject) 'face 'magit-section-secondary-heading))
      (dolist (elt (cdr builds))
        (magit-circleci--insert-build elt)))))

(defun magit-circleci--group-workflows (builds)
  "Group the builds into workflows.

BUILDS are the circleci builds."
  (-group-by (lambda (x) (cdr (assoc 'workflow_id x))) builds))

(defun magit-circleci--section ()
  "Insert CircleCI section in magit status."
  (let* ((memcache (assoc (magit-circleci--reponame) magit-circleci--cache))
         (builds (cond (memcache memcache)
                       ((magit-circleci--cache-file-exists)
                        (cons (magit-circleci--reponame)
                              (magit-circleci--read-cache-file))))))
    (when builds
      (magit-insert-section (root)
        (magit-insert-heading (propertize "CircleCi" 'face 'magit-section-heading))
        (dolist (elt (magit-circleci--group-workflows (cdr builds)))
          (magit-circleci--insert-workflow elt))
        (insert "\n")))))

(define-transient-command circleci-transient ()
  "Dispatch a CircleCI Command"
  ["Fetch"
   ("f" "builds" magit-circleci-pull)])

(defvar magit-circleci-section-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap magit-browse-thing] #'magit-circleci-browse-build)
    (define-key map [remap magit-visit-thing] #'magit-circleci-browse-build)
    map))

(defun magit-circleci--activate ()
  "Add the circleci section and hook up the transient."
  (magit-add-section-hook 'magit-status-sections-hook #'magit-circleci--section
                          'magit-insert-staged-changes 'append)
  (transient-append-suffix 'magit-dispatch "%"
    '("\"" "CircleCI" circleci-transient ?%))
  (with-eval-after-load 'magit-mode
    (define-key magit-mode-map "\"" #'circleci-transient)))

(defun magit-circleci--deactivate ()
  "Remove the circleci section and the transient."
  (remove-hook 'magit-status-sections-hook #'magit-circleci--section)
  (transient-remove-suffix 'magit-dispatch "\""))

;;;###autoload
(define-minor-mode magit-circleci-mode
  "CircleCI integration for Magit"
  :group 'magit-circleci
  :global t
  (if (member 'magit-circleci--section magit-status-sections-hook)
      (magit-circleci--deactivate)
    (magit-circleci--activate)))

(provide 'magit-circleci)
;;; magit-circleci.el ends here
