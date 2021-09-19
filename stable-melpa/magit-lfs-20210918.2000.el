;;; magit-lfs.el --- Magit plugin for Git LFS

;; Copyright (C) 2017 Junyoung Clare Jang

;; Author: Junyoung/Clare Jang <jjc9310@gmail.com>
;; Maintainer: Junyoung/Clare Jang <jjc9310@gmail.com>
;; Created: 25 Feb 2017
;; Version: 0.4.1
;; Package-Version: 20210918.2000
;; Package-Commit: ee005580c1441cce4251734dd239c84d9e88639e
;; Package-Requires: ((emacs "24.4") (magit "2.10.3") (dash "2.13.0"))
;; Keywords: magit git lfs tools vc
;; URL: https://github.com/ailrun/magit-lfs

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with package-stack; see the file COPYING.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; The `magit-lfs' is plugin for `magit', most famous Emacs-Git integration.
;; This plugin is `magit' integrated frontend for Git LFS,
;; Git Large File System.
;;
;; To use this plugin,
;;
;; 1. Install git-lfs.
;;
;; 2. Use following codes in your Emacs setting.
;;
;; - For Vanilla Emacs (After install magit, magit-lfs):
;;
;;   (require 'magit-lfs)
;;
;; - For Emacs with `use-package' (After load magit, dash):
;;
;;   (use-package magit-lfs
;;      :ensure t
;;      :pin melpa)
;;
;; - For Emacs with `req-package' (After install dash):
;;
;;   (req-package magit-lfs
;;      :loader :elpa
;;      :pin melpa
;;      :require (magit))
;;
;; For more detail information, please see README.md

;;; Code:

(require 'dash)
(require 'magit)
(require 'transient)

(defgroup magit-lfs nil
  "Magit powered by git-lfs."
  :group 'magit)

(defcustom magit-lfs-git-lfs-executable "git-lfs"
  "Git LFS executable for magit-lfs."
  :group 'magit-lfs
  :version "0.0.1"
  :type 'string)

(defcustom magit-lfs-git-lfs-command "lfs"
  "Git LFS command for magit-lfs."
  :group 'magit-lfs
  :version "0.0.1"
  :type 'string)

(defcustom magit-lfs-suffix ":"
  "Suffix key for magit-lfs in transient popup."
  :group 'magit-lfs
  :version "0.4.0"
  :type 'string)

(defun magit-lfs-with-lfs (magit-function command &rest args)
  "Internal function for magit-lfs to run MAGIT-FUNCTION with COMMAND and ARGS."
  (declare (indent 1))
  (if (null (executable-find magit-lfs-git-lfs-executable))
      (user-error "Git LFS executable %s is not installed; aborting"
             magit-lfs-git-lfs-executable)
    (apply magit-function magit-lfs-git-lfs-command command args)))

(define-transient-command magit-lfs ()
  "Popup console for top-level magit-lfs commands."
  :man-page "git-lfs"
  ["Actions"
   ("f" "fetch, Download file" magit-lfs-fetch)
   ("F" "pull, Fetch & checkout files" magit-lfs-pull)
   ("i" "install, Install configuration" magit-lfs-install)
   ;; ("l" "logs, Show error logs for LFS" magit-lfs-logs)
   ("P" "push, Push files to end point" magit-lfs-push)
   ("U" "update, Update hook for repo" magit-lfs-update)
   ("!" "fsck, Check file" magit-lfs-fsck)])

(transient-append-suffix 'magit-dispatch '(0 -1 -1)
  `(magit-lfs
    :key ,magit-lfs-suffix
    :description "Magit-LFS"))
(define-key magit-status-mode-map
  magit-lfs-suffix #'magit-lfs)

(define-transient-command magit-lfs-fetch ()
  ""
  :man-page "git-lfs-fetch"
  ["Arguments"
   ("-p" "Prune old/unreferenced after fetch" "--prune")
   ("-a" "Download all objects" "--all")
   ("-r" "Download recent changes" "--recent")
   ("-I" "Include" "--include=")
   ("-X" "Exclude" "--exclude=")]
  ["Fetch from"
   ("p" magit-lfs-fetch-from-pushremote)
   ("u" magit-lfs-fetch-from-upstream)
   ("e" "elsewhere" magit-lfs-fetch-elsewhere)]
  ["Fetch"
   ("o" "another branch" magit-lfs-fetch-branch)])

(define-transient-command magit-lfs-pull ()
  ""
  :man-page "git-lfs-pull"
  ["Arguments"
   ("-I" "Include" "--include=")
   ("-X" "Exclude" "--exclude=")]
  [:description
   (lambda ()
     (if-let ((branch (magit-get-current-branch)))
         (concat
          (propertize "Pull into " 'face 'transient-heading)
          (propertize branch       'face 'magit-branch-local)
          (propertize " from"      'face 'transient-heading))
       (propertize "Pull from" 'face 'transient-heading)))
   ("p" magit-lfs-pull-from-pushremote)
   ("u" magit-lfs-pull-from-upstream)
   ("e" "elsewhere" magit-lfs-pull-elsewhere)]
  ["Fetch"
   ("o" "another branch" magit-lfs-fetch-branch)])

(define-transient-command magit-lfs-install ()
  ""
  :man-page "git-lfs-install"
  ["Arguments"
   ("-F" "Set LFS by overwriting values" "--force")
   ("-s" "Skips automatic downloading for clone/pull" "--skip-smudge")]
  ["Set in"
   ("l" "Local repository's config" magit-lfs-install-to-local-config)
   ("g" "Global config" magit-lfs-install-to-global-config)])

;; (define-transient-command magit-lfs-logs ()
;;   ""
;;   :man-page "git-lfs-logs"
;;   :actions '("Actions"
;;              (?b "Triggers a dummy exception" magit-lfs-logs-boomtown)
;;              (?c "Clear error logs" magit-lfs-logs-clear)
;;              (?s "Show logs" magit-lfs-logs-show)))

(define-transient-command magit-lfs-push ()
  ""
  :man-page "git-lfs-push"
  ["Arguments"
   ("-d" "Dry run" "--dry-run")
   ("-a" "Push all objects to remote" "--all")]
  [:description
   (lambda ()
     (when-let ((branch (magit-get-current-branch)))
       (concat (propertize "Push " 'face 'transient-heading)
               (propertize branch  'face 'magit-branch-local)
               (propertize " to"   'face 'transient-heading))))
   ("p" magit-lfs-push-current-to-pushremote)
   ("u" magit-lfs-push-current-to-upstream)
   ("e" "elsewhere" magit-lfs-push-current-to-elsewhere)]
  ["Push"
   ("o" "another branch" magit-lfs-push-another-branch)])

(define-transient-command magit-lfs-update ()
  ""
  :man-page "git-lfs-update"
  ["Arguments"
   ("-f" "Update hook, clobbering existing contents" "--force")]
  ["Updates"
   ("h" "hooks" magit-lfs-update-hooks)])


(defun magit-lfs-fsck ()
  "Magit binding for git lfs fsck."
  (interactive)
  (magit-lfs-with-lfs 'magit-run-git-async "fsck"))


(defun magit-lfs-fetch-arguments nil
  ""
  (transient-args 'magit-lfs-fetch))

(defun magit-lfs-git-lfs-fetch (remote args)
  "Internal function for git lfs fetch REMOTE with ARGS."
  (run-hooks 'magit-credential-hook)
  (magit-lfs-with-lfs 'magit-run-git-async "fetch" remote args))

(define-suffix-command magit-lfs-fetch-from-pushremote (args)
  "Magit binding for git lfs fetch push-remote of the current branch with ARGS."
  :description 'magit-fetch--pushremote-description
  (interactive (list (magit-lfs-fetch-arguments)))
  (let ((remote (magit-get-push-remote)))
    (when (or current-prefix-arg
              (not (member remote (magit-list-remotes))))
      (let ((var (magit--push-remote-variable)))
        (setq remote
              (magit-read-remote (format "Set %s and fetch from there" var)))
        (magit-set remote var)))
    (magit-lfs-git-lfs-fetch remote args)))

(define-suffix-command magit-lfs-fetch-from-upstream (upstream args)
  "Magit binding for git lfs fetch UPSTREAM with ARGS."
  :if (lambda () (magit-get-current-remote t))
  :description (lambda () (magit-get-current-remote t))
  (interactive (list (magit-get-current-remote t)
                     (magit-lfs-fetch-arguments)))
  (unless upstream
    (error "The \"current\" upstream could not be determined"))
  (magit-lfs-git-lfs-fetch upstream args))

(defun magit-lfs-fetch-elsewhere (remote args)
  "Magit binding for git lfs fetch REMOTE with ARGS."
  (interactive (list (magit-read-remote "Fetch remote")
                     (magit-lfs-fetch-arguments)))
  (magit-lfs-git-lfs-fetch remote args))

(defun magit-lfs-fetch-branch (remote branch args)
  "Magit binding for git lfs fetch REMOTE/BRANCH with ARGS."
  (interactive
   (let ((remote (magit-read-remote-or-url "Fetch from remote or url")))
     (list remote
           (magit-read-remote-branch "Fetch branch" remote)
           (magit-lfs-fetch-arguments))))
  (magit-lfs-git-lfs-fetch remote (cons branch args)))


(defun magit-lfs-install-arguments nil
  ""
  (transient-args 'magit-lfs-install))

(defun magit-lfs-git-lfs-install (args)
  "Internal function for git lfs install with ARGS."
  (magit-lfs-with-lfs 'magit-run-git-async "install" args))

(defun magit-lfs-install-to-local-config (args)
  "Magit binding for git lfs install --local with ARGS."
  (interactive (list (magit-lfs-install-arguments)))
  (magit-lfs-git-lfs-install (cons "--local" args)))

(defun magit-lfs-install-to-global-config (args)
  "Magit binding for git lfs install with ARGS."
  (interactive (list (magit-lfs-install-arguments)))
  (magit-lfs-git-lfs-install args))


;; (defun magit-lfs-logs-boomtown ()
;;   "Magit binding for git lfs logs --boomtown.")

;; (defun magit-lfs-logs-clear ()
;;   "Magit binding for git lfs logs --clear.")

;; (defun magit-lfs-logs-show ()
;;   "Magit binding for git lfs logs --show.")


;; (defun magit-lfs-ls-files ()
;;   "Magit binding for git lfs ls-files.")


(defun magit-lfs-pull-arguments nil
  ""
  (transient-args 'magit-lfs-pull))

(defun magit-lfs-git-lfs-pull (remote branch args)
  "Internal function for git lfs pull REMOTE/BRANCH with ARGS."
  (run-hooks 'magit-credential-hook)
  (magit-lfs-with-lfs 'magit-run-git-with-editor "pull" args remote branch))

(define-suffix-command magit-lfs-pull-from-pushremote (args)
  "Magit binding for git lfs pull push-remote of the current branch with ARGS."
  :if 'magit-get-current-branch
  :description 'magit-pull--pushbranch-description
  (interactive (list (magit-lfs-pull-arguments)))
    (pcase-let ((`(,branch ,remote)
               (magit--select-push-remote "pull from there")))
      (run-hooks 'magit-credential-hook)
      (magit-lfs-git-lfs-pull remote branch args)))

(define-suffix-command magit-lfs-pull-from-upstream (args)
  "Magit binding for git lfs pull upstream with ARGS."
  :if 'magit-get-current-branch
  :description 'magit-pull--upstream-description
  (interactive (list (magit-lfs-pull-arguments)))
  (let* ((branch (or (magit-get-current-branch)
                     (user-error "No branch is checked out")))
         (remote (magit-get "branch" branch "remote"))
         (merge  (magit-get "branch" branch "merge")))
    (when (or current-prefix-arg
              (not (or (magit-get-upstream-branch branch)
                       (magit--unnamed-upstream-p remote merge))))
      (magit-set-upstream-branch
       branch (magit-read-upstream-branch
               branch (format "Set upstream of %s and pull from there" branch)))
      (setq remote (magit-get "branch" branch "remote"))
      (setq merge  (magit-get "branch" branch "merge")))
    (run-hooks 'magit-credential-hook)
    (magit-lfs-git-lfs-pull remote merge args)))

(defun magit-lfs-pull-elsewhere (source args)
  "Magit binding for git lfs pull SOURCE with ARGS."
  (interactive (list (magit-read-remote-branch "Pull" nil nil nil t)
                     (magit-lfs-pull-arguments)))
  (pcase-let ((`(,remote . ,branch)
               (magit-get-tracked source)))
    (magit-lfs-git-lfs-pull remote branch args)))


(defun magit-lfs-push-arguments nil
  ""
  (transient-args 'magit-lfs-push))

(defun magit-lfs-git-lfs-push-raw (remote refspec args)
  "Internal function for git lfs push REMOTE REFSPEC with ARGS."
  (run-hooks 'magit-credential-hook)
  (magit-lfs-with-lfs 'magit-run-git-async "push" "-v" args remote refspec))

(defun magit-lfs-git-lfs-push (branch target args)
  "Internal function for git lfs push with ARGS."
  (pcase-let ((namespace (if (magit-get-tracked target) "" "refs/heads/"))
              (`(,remote . ,target)
               (magit-split-branch-name target)))
    (magit-lfs-git-lfs-push-raw remote (format "%s:%s%s" branch namespace target) args)))

(define-suffix-command magit-lfs-push-current-to-pushremote (args)
  "Magit binding for git lfs push current branch to PUSH-REMOTE with ARGS."
  :if 'magit-get-current-branch
  :description 'magit-push--pushbranch-description
  (interactive (list (magit-lfs-push-arguments)))
  (pcase-let ((`(,_ ,remote)
               (magit--select-push-remote "push there")))
    (magit-lfs-git-lfs-push-raw remote "HEAD" args)))

(define-suffix-command magit-lfs-push-current-to-upstream (args)
  "Magit binding for git lfs push current branch to UPSTREAM with ARGS."
  :if 'magit-get-current-branch
  :description 'magit-push--upstream-description
  (interactive (list (magit-lfs-push-arguments)))
  (let* ((branch (or (magit-get-current-branch)
                     (user-error "No branch is checked out")))
         (remote (magit-get "branch" branch "remote"))
         (merge  (magit-get "branch" branch "merge")))
    (when (or current-prefix-arg
              (not (or (magit-get-upstream-branch branch)
                       (magit--unnamed-upstream-p remote merge)
                       (magit--valid-upstream-p remote merge))))
      (let* ((branches (-union (--map (concat it "/" branch)
                                      (magit-list-remotes))
                               (magit-list-remote-branch-names)))
             (upstream (magit-completing-read
                        (format "Set upstream of %s and push there" branch)
                        branches nil nil nil 'magit-revision-history
                        (or (car (member (magit-remote-branch-at-point) branches))
                            (car (member "origin/master" branches)))))
             (upstream (or (magit-get-tracked upstream)
                           (magit-split-branch-name upstream))))
        (setq remote (car upstream))
        (setq merge  (cdr upstream))
        (unless (string-prefix-p "refs/" merge)
          ;; User selected a non-existent remote-tracking branch.
          ;; It is very likely, but not certain, that this is the
          ;; correct thing to do.  It is even more likely that it
          ;; is what the user wants to happen.
          (setq merge (concat "refs/heads/" merge))))
      (cl-pushnew "--set-upstream" args :test #'equal))
    (run-hooks 'magit-credential-hook)
    (magit-lfs-git-lfs-push-raw remote (concat branch ":" merge) args)))

(defun magit-lfs-push-current-to-elsewhere (target args)
  "Magit binding for git lfs push current branch to TARGET with ARGS."
  (interactive
   (--if-let (magit-get-current-branch)
       (list (magit-read-remote-branch (format "Push %s to" it) nil nil it 'confirm)
             (magit-lfs-push-arguments))
     (user-error "No branch is checked out")))
  (magit-lfs-git-lfs-push (magit-get-current-branch) target args))

(defun magit-lfs-push-another-branch (branch target args)
  "Magit binding for git lfs push BRANCH to TARGET with ARGS."
  (interactive
   (let ((branch (magit-read-local-branch-or-commit "Push")))
     (list branch
           (magit-read-remote-branch
            (format "Push %s to" branch) nil
            (if (magit-local-branch-p branch)
                (or (magit-get-push-branch branch)
                    (magit-get-upstream-branch branch))
              (and (magit-rev-ancestor-p branch "HEAD")
                   (or (magit-get-push-branch)
                       (magit-get-upstream-branch))))
            branch 'confirm)
           (magit-lfs-push-arguments))))
  (magit-lfs-git-lfs-push branch target args))


(defun magit-lfs-update-arguments ()
  ""
  (transient-args 'magit-lfs-update))

(defun magit-lfs-update-hooks (args)
  "Magit binding for git lfs update with ARGS."
  (interactive (list (magit-lfs-update-arguments)))
  (magit-lfs-with-lfs 'magit-run-git-async "update" args))



(provide 'magit-lfs)

;;; magit-lfs.el ends here
