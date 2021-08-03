;;; magit-gitflow.el --- gitflow extension for magit           -*- lexical-binding: t; -*-

;; Copyright (C) 2014, 2015, 2016, 2017  Jan Tatarik

;; Author: Jan Tatarik <Jan.Tatarik@gmail.com>
;; Keywords: vc tools
;; URL: https://github.com/jtatarik/magit-gitflow
;; Package: magit-gitflow
;; Package-Requires: ((magit "2.1.0") (magit-popup "2.2.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Gitflow plugin for Magit.
;;
;; (require 'magit-gitflow)
;; (add-hook 'magit-mode-hook 'turn-on-magit-gitflow)
;;
;; C-f in magit status buffer will invoke the gitflow popup.
;;

;;; Code:

(require 'magit)
(require 'magit-popup)
(require 'magit-process)
(require 'subr-x)

(defvar magit-gitflow-mode-lighter " GitFlow")

(defvar magit-gitflow-popup-key "C-f")

(defvar magit-gitflow-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd magit-gitflow-popup-key) 'magit-gitflow-popup)
    map))

(define-minor-mode magit-gitflow-mode
  "GitFlow support for Magit."
  :lighter magit-gitflow-mode-lighter
  :keymap  magit-gitflow-mode-map
  (or (derived-mode-p 'magit-mode)
      (user-error "This mode only makes sense with magit")))

;;;###autoload
(defun turn-on-magit-gitflow ()
  "Unconditionally turn on `magit-gitflow-mode'."
  (magit-gitflow-mode 1))

(easy-menu-define magit-gitflow-extension-menu nil
  "GitFlow extension menu"
  '("GitFlow" :visible magit-gitflow-mode

    ("Initialization/setup"
     ["Initialize defaults" magit-gitflow-init
      :help "Initialize GitFlow in the current repository"]
     ["Set feature prefix" magit-gitflow-init-feature]
     ["Set release prefix" magit-gitflow-init-release]
     ["Set hotfix prefix" magit-gitflow-init-hotfix]
     ["Set support prefix" magit-gitflow-init-support]
     ["Set versiontag prefix" magit-gitflow-init-versiontag])

    ("Feature"
     ["Start" magit-gitflow-feature-start-popup]
     ["Finish" magit-gitflow-feature-finish-popup]
     ["Publish" magit-gitflow-feature-publish]
     ["Delete" magit-gitflow-feature-delete-popup]
     ["Track" magit-gitflow-feature-track]
     ["Diff" magit-gitflow-feature-diff]
     ["Rebase" magit-gitflow-feature-rebase-popup])

    ("Bugfix"
     ["Start" magit-gitflow-bugfix-start-popup]
     ["Finish" magit-gitflow-bugfix-finish-popup]
     ["Publish" magit-gitflow-bugfix-publish]
     ["Delete" magit-gitflow-bugfix-delete-popup]
     ["Track" magit-gitflow-bugfix-track]
     ["Diff" magit-gitflow-bugfix-diff]
     ["Rebase" magit-gitflow-bugfix-rebase-popup])

    ("Release"
     ["Start" magit-gitflow-release-start-popup]
     ["Finish" magit-gitflow-release-finish-popup]
     ["Publish" magit-gitflow-release-publish]
     ["Delete" magit-gitflow-release-delete-popup]
     ["Track" magit-gitflow-release-track])

    ("Hotfix"
     ["Start" magit-gitflow-hotfix-start-popup]
     ["Finish" magit-gitflow-hotfix-finish-popup]
     ["Publish" magit-gitflow-hotfix-publish]
     ["Delete" magit-gitflow-hotfix-delete-popup])

    ["Support" magit-gitflow-support-start-popup]))


(easy-menu-add-item 'magit-mode-menu '("Extensions")
                    magit-gitflow-extension-menu)


;;; Commands

(magit-define-popup magit-gitflow-popup
  "Popup console for GitFlow commands."
  'magit-popups
  :actions '((?i "Init"     magit-gitflow-init-popup)
             (?f "Feature"  magit-gitflow-feature-popup)
             (?b "Bugfix"   magit-gitflow-bugfix-popup)
             (?r "Release"  magit-gitflow-release-popup)
             (?h "Hotfix"   magit-gitflow-hotfix-popup)
             (?s "Support"  magit-gitflow-support-start-popup)))

;;
;; git flow INIT
;;

(magit-define-popup magit-gitflow-init-popup
  "Popup console for GitFlow 'init' command."
  'magit-gitflow-popup
  :actions '((?i "Initialize defaults" magit-gitflow-init)
             (?f "Feature prefix"      magit-gitflow-init-feature)
             (?b "Bugfix prefix"       magit-gitflow-init-bugfix)
             (?r "Release prefix"      magit-gitflow-init-release)
             (?h "Hotfix prefix"       magit-gitflow-init-hotfix)
             (?s "Support prefix"      magit-gitflow-init-support)
             (?v "Version tag prefix"  magit-gitflow-init-versiontag))
  :switches '((?f "Force reinitialization" "--force")))

;;
;; git flow FEATURE
;;

(magit-define-popup magit-gitflow-feature-popup
  "Popup console for GitFlow 'feature' command."
  'magit-gitflow-popup
  :actions '((?s "Start"    magit-gitflow-feature-start-popup)
             (?f "Finish"   magit-gitflow-feature-finish-popup)
             (?p "Publish"  magit-gitflow-feature-publish)
             (?d "Delete"   magit-gitflow-feature-delete-popup)
             (?t "Track"    magit-gitflow-feature-track)
             (?D "Diff"     magit-gitflow-feature-diff)
             (?r "Rebase"   magit-gitflow-feature-rebase-popup)))

(magit-define-popup magit-gitflow-feature-start-popup
  "Popup console for GitFlow 'feature start' command."
  'magit-gitflow-feature-popup
  :actions '((?s "Start" magit-gitflow-feature-start))
  :switches '((?F "Fetch" "--fetch")))

(magit-define-popup magit-gitflow-feature-finish-popup
  "Popup console for GitFlow 'feature finish' command."
  'magit-gitflow-feature-popup
  :actions '((?f   "Finish" magit-gitflow-feature-finish))
  :switches '((?F   "Fetch"               "--fetch")
              (?r   "Rebase"              "--rebase")
              (?p   "Preserve merges"     "--preserve-merges")
              (?k   "Keep branch"         "--keep")
              (?R   "Keep remote branch"  "--keepremote")
              (?L   "Keep local branch"   "--keeplocal")
              (?D   "Force delete branch" "--force_delete")
              (?S   "Squash"              "--squash")
              (?n   "No fast-forward"     "--no-ff")))

(magit-define-popup magit-gitflow-feature-delete-popup
  "Popup console for GitFlow 'feature delete' command."
  'magit-gitflow-feature-popup
  :actions '((?d "Delete" magit-gitflow-feature-delete))
  :switches '((?f "Force"         "--force")
              (?r "Delete remote" "--remote")))


(magit-define-popup magit-gitflow-feature-rebase-popup
  "Popup console for GitFlow 'feature rebase' command."
  'magit-gitflow-feature-popup
  :actions '((?r "Rebase" magit-gitflow-feature-rebase))
  :switches '((?i "Interactive"     "--interactive")
              (?p "Preserve merges" "--preserve-merges")))


;;
;; git flow BUGFIX
;;

(magit-define-popup magit-gitflow-bugfix-popup
  "Popup console for GitFlow 'bugfix' command."
  'magit-gitflow-popup
  :actions '((?s "Start"    magit-gitflow-bugfix-start-popup)
             (?f "Finish"   magit-gitflow-bugfix-finish-popup)
             (?p "Publish"  magit-gitflow-bugfix-publish)
             (?d "Delete"   magit-gitflow-bugfix-delete-popup)
             (?t "Track"    magit-gitflow-bugfix-track)
             (?D "Diff"     magit-gitflow-bugfix-diff)
             (?r "Rebase"   magit-gitflow-bugfix-rebase-popup)))

(magit-define-popup magit-gitflow-bugfix-start-popup
  "Popup console for GitFlow 'bugfix start' command."
  'magit-gitflow-bugfix-popup
  :actions '((?s "Start" magit-gitflow-bugfix-start))
  :switches '((?F "Fetch" "--fetch")))

(magit-define-popup magit-gitflow-bugfix-finish-popup
  "Popup console for GitFlow 'bugfix finish' command."
  'magit-gitflow-bugfix-popup
  :actions '((?f    "Finish" magit-gitflow-bugfix-finish))
  :switches '((?F   "Fetch"               "--fetch")
              (?r   "Rebase"              "--rebase")
              (?p   "Preserve merges"     "--preserve-merges")
              (?k   "Keep branch"         "--keep")
              (?R   "Keep remote branch"  "--keepremote")
              (?L   "Keep local branch"   "--keeplocal")
              (?D   "Force delete branch" "--force_delete")
              (?S   "Squash"              "--squash")
              (?n   "No fast-forward"     "--no-ff")))

(magit-define-popup magit-gitflow-bugfix-delete-popup
  "Popup console for GitFlow 'bugfix delete' command."
  'magit-gitflow-bugfix-popup
  :actions '((?d "Delete" magit-gitflow-bugfix-delete))
  :switches '((?f "Force"         "--force")
              (?r "Delete remote" "--remote")))


(magit-define-popup magit-gitflow-bugfix-rebase-popup
  "Popup console for GitFlow 'bugfix rebase' command."
  'magit-gitflow-bugfix-popup
  :actions '((?r "Rebase" magit-gitflow-bugfix-rebase))
  :switches '((?i "Interactive"     "--interactive")
              (?p "Preserve merges" "--preserve-merges")))


;;
;; git flow RELEASE
;;

(magit-define-popup magit-gitflow-release-popup
  "Popup console for GitFlow 'release' command."
  'magit-gitflow-popup
  :actions '((?s "Start"    magit-gitflow-release-start)
             (?f "Finish"   magit-gitflow-release-finish-popup)
             (?p "Publish"  magit-gitflow-release-publish)
             (?d "Delete"   magit-gitflow-release-delete-popup)
             (?t "Track"    magit-gitflow-release-track)))

(magit-define-popup magit-gitflow-release-start-popup
  "Popup console for GitFlow 'release start' command."
  'magit-gitflow-release-popup
  :actions '((?s "Start" magit-gitflow-release-start))
  :switches '((?F "Fetch" "--fetch")))

(magit-define-popup magit-gitflow-release-finish-popup
  "Popup console for GitFlow 'release finish' command."
  'magit-gitflow-release-popup
  :actions '((?f "Finish" magit-gitflow-release-finish))
  :options '((?u "Signing key"      "--signingkey="   read-file-name)
             (?m "Tag message"      "--message="      read-string)
             (?f "Tag message file" "--messagefile="  read-file-name))
  :switches '((?F "Fetch before finish"     "--fetch")
              (?s "Sign"                    "--sign")
              (?p "Push after finish"       "--push")
              (?k "Keep branch"             "--keep")
              (?R "Keep remote branch"      "--keepremote")
              (?L "Keep local branch"       "--keeplocal")
              (?D "Force delete branch"     "--force_delete")
              (?n "Don't tag"               "--notag")
              (?b "Don't back-merge master" "--nobackmerge")
              (?S "Squash"                  "--squash")))

(magit-define-popup magit-gitflow-release-delete-popup
  "Popup console for GitFlow 'release delete' command."
  'magit-gitflow-release-popup
  :actions '((?d "Delete" magit-gitflow-release-delete))
  :switches '((?f "Force"                "--force")
              (?r "Delete remote branch" "--remote")))

;;
;; git flow HOTFIX
;;

(magit-define-popup magit-gitflow-hotfix-popup
  "Popup console for GitFlow 'hotfix' command."
  'magit-gitflow-popup
  :actions '((?s "Start"    magit-gitflow-hotfix-start-popup)
             (?f "Finish"   magit-gitflow-hotfix-finish-popup)
             (?p "Publish"  magit-gitflow-hotfix-publish)
             (?d "Delete"   magit-gitflow-hotfix-delete-popup)))

(magit-define-popup magit-gitflow-hotfix-start-popup
  "Popup console for GitFlow 'hotfix start' command."
  'magit-gitflow-hotfix-popup
  :actions '((?s "Start"  magit-gitflow-hotfix-start))
  :switches '((?F "Fetch" "--fetch")))

(magit-define-popup magit-gitflow-hotfix-finish-popup
  "Popup console for GitFlow 'hotfix finish' command."
  'magit-gitflow-hotfix-popup
  :actions '((?f "Finish" magit-gitflow-hotfix-finish))
  :options '((?u "Signing key"      "--signingkey="   read-file-name)
             (?m "Tag message"      "--message="      read-string)
             (?f "Tag message file" "--messagefile="  read-file-name))
  :switches '((?F "Fetch before finish"     "--fetch")
              (?s "Sign"                    "--sign")
              (?p "Push after finish"       "--push")
              (?k "Keep branch"             "--keep")
              (?R "Keep remote branch"      "--keepremote")
              (?L "Keep local branch"       "--keeplocal")
              (?D "Force delete branch"     "--force_delete")
              (?n "Don't tag"               "--notag")
              (?b "Don't back-merge master" "--nobackmerge")))

(magit-define-popup magit-gitflow-hotfix-delete-popup
  "Popup console for GitFlow 'hotfix delete' command."
  'magit-gitflow-hotfix-popup
  :actions '((?d "Delete" magit-gitflow-hotfix-delete))
  :switches '((?f "Force"                "--force")
              (?r "Delete remote branch" "--remote")))


;;
;; git flow SUPPORT
;;

(magit-define-popup magit-gitflow-support-start-popup
  "Popup console for GitFlow 'support start' command."
  'magit-gitflow-popup
  :actions '((?s "Start"    magit-gitflow-support-start))
  :switches '((?F "Fetch" "--fetch")))



;;; Utilities

(defun magit-run-gitflow (&rest args)
  "Execute 'git flow' with given ARGS."
  (apply #'magit-run-git "flow" args))

(defun magit-gitflow-get-config-key (key)
  "Read gitconfig value for gitflow KEY."
  (or (magit-get (format "gitflow.%s" key))
      (user-error "Not a gitflow-enabled repo, please run 'git flow init' first")))

(defmacro define-magit-gitflow-cmd (cmd)
  "Define function to execute 'git flow CMD' commands.

The new function will be called magit-run-gitflow-CMD."
  (let ((defun-name (intern (format "magit-run-gitflow-%s" cmd)))
        (version-prompt (format "%s name" (upcase-initials cmd)))
        (config-key (format "prefix.%s" cmd)))

    `(defun ,defun-name (args)
       (let* ((prefix (magit-gitflow-get-config-key ,config-key))
              (current-branch (magit-get-current-branch))
              (current-feature (if (string-prefix-p prefix current-branch)
                                   (substring current-branch (length prefix))
                                 "")))

         (magit-run-gitflow ,cmd args
                            magit-current-popup-args
                            (string-remove-prefix
                             prefix
                             (magit-completing-read ,version-prompt
                                                    (magit-list-refnames "refs/heads")
                                                    (lambda (ref) (string-prefix-p prefix ref))
                                                    t
                                                    current-branch)))))))

(define-magit-gitflow-cmd "feature")
(define-magit-gitflow-cmd "bugfix")
(define-magit-gitflow-cmd "release")
(define-magit-gitflow-cmd "hotfix")


(defmacro define-magit-gitflow-branch-cmd (branch cmd)
  "Define function that executes 'git flow BRANCH CMD' commands.

The new function will be called magit-gitflow-BRANCH-CMD."

  (let ((branch-execute (intern (format "magit-run-gitflow-%s" branch)))
        (defun-name (intern (format "magit-gitflow-%s-%s" branch cmd))))

    `(defun ,defun-name ()
       (interactive)
       (,branch-execute ,cmd))))


;;
;; git flow INIT
;;
(defun magit-gitflow-init ()
  (interactive)
  (magit-run-gitflow "init" "-d" magit-current-popup-args))

(defun magit-gitflow-init-prefix (key prompt)
  (let* ((config-key (format "gitflow.prefix.%s" key))
         (default-prefix (or (magit-get config-key) "")))
    (magit-set
     (read-string prompt default-prefix) config-key)))

(defun magit-gitflow-init-feature ()
  (interactive)
  (magit-gitflow-init-prefix "feature" "Feature branch prefix: "))

(defun magit-gitflow-init-bugfix ()
  (interactive)
  (magit-gitflow-init-prefix "bugfix" "Bugfix branch prefix: "))

(defun magit-gitflow-init-release ()
  (interactive)
  (magit-gitflow-init-prefix "release" "Release branch prefix: "))

(defun magit-gitflow-init-hotfix ()
  (interactive)
  (magit-gitflow-init-prefix "hotfix" "Hotfix branch prefix: "))

(defun magit-gitflow-init-support ()
  (interactive)
  (magit-gitflow-init-prefix "support" "Support branch prefix: "))

(defun magit-gitflow-init-versiontag ()
  (interactive)
  (magit-gitflow-init-prefix "versiontag" "Version tag prefix: "))


;;
;; git flow FEATURE
;;
(defun magit-gitflow-feature-start (name)
  (interactive "sFeature name: ")
  (magit-run-gitflow "feature" "start"  magit-current-popup-args name))

(define-magit-gitflow-branch-cmd "feature" "finish")
(define-magit-gitflow-branch-cmd "feature" "publish")
(define-magit-gitflow-branch-cmd "feature" "delete")

(defun magit-gitflow-feature-rebase ()
  (interactive)
  (let* ((prefix (magit-gitflow-get-config-key "prefix.feature"))
         (current-branch (magit-get-current-branch))
         (args (append '("feature" "rebase") magit-current-popup-args (list (string-remove-prefix prefix current-branch)))))

    (when (string-prefix-p prefix current-branch)
      (magit-run-git-with-editor "flow" args))))

(defun magit-gitflow-feature-diff ()
  (interactive)
  (let* ((prefix (magit-gitflow-get-config-key "prefix.feature"))
         (current-branch (magit-get-current-branch))
         (base (magit-get (format "gitflow.branch.%s.base" current-branch))))

    (when (and (string-prefix-p prefix current-branch) base)
      (magit-diff base current-branch))))

(defun magit-gitflow-feature-track ()
  (interactive)
  (let ((prefix (magit-gitflow-get-config-key "prefix.feature")))
    (magit-run-gitflow "feature" "track"
                       (string-remove-prefix prefix (magit-read-remote-branch "Feature" "origin")))))


;;
;; git flow BUGFIX
;;
(defun magit-gitflow-bugfix-start (name)
  (interactive "sBugfix name: ")
  (magit-run-gitflow "bugfix" "start"  magit-current-popup-args name))

(define-magit-gitflow-branch-cmd "bugfix" "finish")
(define-magit-gitflow-branch-cmd "bugfix" "publish")
(define-magit-gitflow-branch-cmd "bugfix" "delete")

(defun magit-gitflow-bugfix-rebase ()
  (interactive)
  (let* ((prefix (magit-gitflow-get-config-key "prefix.bugfix"))
         (current-branch (magit-get-current-branch))
         (args (append '("bugfix" "rebase") magit-current-popup-args (list (string-remove-prefix prefix current-branch)))))

    (when (string-prefix-p prefix current-branch)
      (magit-run-git-with-editor "flow" args))))

(defun magit-gitflow-bugfix-diff ()
  (interactive)
  (let* ((prefix (magit-gitflow-get-config-key "prefix.bugfix"))
         (current-branch (magit-get-current-branch))
         (base (magit-get (format "gitflow.branch.%s.base" current-branch))))

    (when (and (string-prefix-p prefix current-branch) base)
      (magit-diff base current-branch))))

(defun magit-gitflow-bugfix-track ()
  (interactive)
  (let ((prefix (magit-gitflow-get-config-key "prefix.bugfix")))
    (magit-run-gitflow "bugfix" "track"
                       (string-remove-prefix prefix (magit-read-remote-branch "Bugfix" "origin")))))

;;
;; git flow RELEASE
;;
(defun magit-gitflow-release-start (version)
  (interactive "sRelease name: ")
  (magit-run-gitflow "release" "start" magit-current-popup-args version))

(defun magit-gitflow-release-finish ()
  (interactive)
  (let* ((prefix (magit-gitflow-get-config-key "prefix.release"))
        (current-branch (magit-get-current-branch))
        (current-release (if (string-prefix-p prefix current-branch)
                             (substring current-branch (length prefix))
                           ""))
        (args (append '("release" "finish") magit-current-popup-args (list (read-string "Release name: " current-release)))))
    (magit-run-git-with-editor "flow" args)))

(define-magit-gitflow-branch-cmd "release" "publish")
(define-magit-gitflow-branch-cmd "release" "delete")

(defun magit-gitflow-release-track ()
  (interactive)
  (let ((prefix (magit-gitflow-get-config-key "prefix.release")))
    (magit-run-gitflow "release" "track"
                       (string-remove-prefix prefix (magit-read-remote-branch "Release" "origin")))))


;;
;; git flow HOTFIX
;;
(defun magit-gitflow-hotfix-start (version)
  (interactive "sHotfix name: ")
  (magit-run-gitflow "hotfix" "start" magit-current-popup-args version))

(defun magit-gitflow-hotfix-finish ()
  (interactive)
  (let* ((prefix (magit-gitflow-get-config-key "prefix.hotfix"))
         (current-branch (magit-get-current-branch))
         (current-hotfix (if (string-prefix-p prefix current-branch)
                              (substring current-branch (length prefix))
                            ""))
         (args (append '("hotfix" "finish") magit-current-popup-args (list (read-string "Hotfix name: " current-hotfix)))))
    (magit-run-git-with-editor "flow" args)))

(define-magit-gitflow-branch-cmd "hotfix" "publish")
(define-magit-gitflow-branch-cmd "hotfix" "delete")


;;
;; git flow SUPPORT
;;
(defun magit-gitflow-support-start ()
  (interactive)
  (magit-run-gitflow "support" "start" magit-current-popup-args
                     (read-string "Support branch name: ")
                     (magit-read-local-branch-or-ref "Base")))

(provide 'magit-gitflow)
;;; magit-gitflow.el ends here
