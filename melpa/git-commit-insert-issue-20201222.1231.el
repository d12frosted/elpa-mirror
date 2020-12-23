;;; git-commit-insert-issue.el --- Get issues list when typing "Fixes #"

;; Copyright (C) 2015-2016 vindarel <ehvince@mailz.org>

;; Author: Vindarel
;; URL: https://gitlab.com/emacs-stuff/git-commit-insert-issue/
;; Package-Version: 20201222.1231
;; Package-Commit: 51f6ec25242af14f46131838c23aef1fcd8a8c85
;; Keywords: git, github, gitlab, bitbucket, commit, issues
;; Version: 0.4
;; Package-Requires: ((projectile "0") (s "0") (ghub "0") (glab "0") (bitbucket "0"))
;; Summary: Get issues list when typeng "Fixes #" in a commit message. github, gitlab and bitbucket.

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This library provides a minor mode and an interactive function to
;; fetch issues of your project when you type "Fixes #" in a commit
;; message. Github, Gitlab and Bitbucket.

;;; Code:

(require 'ghub)
(require 'glab)
(require 'projectile)
(require 's)

(defvar git-commit-insert-issue-github-keywords '("Fixes" "fixes" "fix" "fixed"
                                "close" "closes" "closed"
                                "resolve" "resolves" "resolved")
  "List of keywords that github accepts to close issues.")

(defvar git-commit-insert-issue-gitlab-keywords '("see" "for")
  "List of keywords to reference an issue with gitlab. Gitlab works on 'fixes' and the like, but isn't limited to them. We can reference any issue with no keyword.")

(defvar git-commit-insert-issue-bitbucket-keywords '("see" "for")
  "Similar to Gitlab, Bitbucket can reference issues with or without keywords, see: https://confluence.atlassian.com/bitbucket/resolve-issues-automatically-when-users-push-code-221451126.html")

(defun git-username ()
  (s-trim (shell-command-to-string "git config user.name")))

(defun git-commit-insert-issue-project-id (&optional project username)
  (let* ((username (or username (insert-issue--get-group)))
         (project (or project (projectile-project-name))))
    (format "%s/%s" username project)))

(defun get-gitlab-issues (projectname username)
  "Manual call to Gitlab's AP v4: /projects/:id/issues. Get closed issues only.
  The project id is username%2Fprojectname.
  TODO: auth for private projects."
  (or projectname username
      (error (s-concat "We can't get Gitlab issues: we don't know the project name or the user name ('" projectname "' and '" username "').")))
  (let ((id (s-concat username "%2F" projectname)))
    (glab-get (s-concat "/projects/" id "/issues?state=opened") nil :auth 'none)))

(defun git-commit-insert-issue-gitlab-issues (&optional projectname username)
  "Return a list of the opened issues on gitlab."
  (or (gitlab--get-host)
      (error "We can't find your gitlab host. Did you set gitlab-[host, username, password] ?"))
  (get-gitlab-issues projectname username))

(defun git-commit-insert-issue-gitlab-issues-format (&optional username project-name)
  "Get issues and return a list of strings formatted with '#id - title'"
  (let* ((username (or username (insert-issue--get-group)))
         (project-name (or project-name (projectile-project-name)))
         (issues (git-commit-insert-issue-gitlab-issues project-name username)))
    (--map (format "#%i - %s" (alist-get 'iid it) (alist-get 'title it))
           issues)))

(defun git-commit-insert-issue-github-issues (&optional username project-name)
  "Return a plist of github issues, raw from the api request."
  (let ((project-name (or project-name (projectile-project-name)))
        (username (or username (insert-issue--get-group))))
    (ghub-get (s-concat "/repos/" username "/" project-name "/issues") nil :auth 'none)))

(defun git-commit-insert-issue-github-issues-format (&optional username project-name)
  "Get all the issues from the current project.
   Return a list of formatted strings: '#id - title'"
  (let* ((username (or username (insert-issue--get-group)))
         (project-name (or project-name (projectile-project-name)))
         (issues (git-commit-insert-issue-github-issues username project-name)))
    (if (string= (alist-get 'message issues) "Not Found")
          (error (concat "Nothing found with user " username " in project " project-name))
      (progn
        ;;todo: watch for api rate limit.
        (setq git-commit-insert-issue-project-issues
              (--map
               (format "#%i - %s" (alist-get 'number it) (alist-get 'title it))
               issues))))))

(defun git-commit-insert-issue-bitbucket-issues (&optional username project-name)
  "Return a list of bitbucket issues."
  (let* ((username (insert-issue--get-group))
          (project-name (projectile-project-name)))
          (bitbucket-issues-list-all username project-name)))

(defun git-commit-insert-issue-bitbucket-issues-format (&optional username project-name)
  "Get issues and return a list of strings formatted with '#id - title'"
  (--map (format "#%i - %s" (assoc-default 'id it) (assoc-default 'title it))
    (git-commit-insert-issue-bitbucket-issues username project-name)))

(defun git-commit-insert-issue-get-issues-github-or-gitlab-or-bitbucket-format ()
  "Get the list of issues, from github, gitlab or bitbucket."
  (cond ((string-equal "github.com" (insert-issue--get-server))
         (git-commit-insert-issue-github-issues-format))
        ((string-equal "bitbucket.org" (insert-issue--get-server))
         (git-commit-insert-issue-bitbucket-issues-format))
        ;; for every other choice it's gitlab atm, since github isn't self hosted it won't have other names.
        (t (git-commit-insert-issue-gitlab-issues-format))))

(defun git-commit-insert-issue--construct-regexp (kw)
  "From a list of words, constructs a regexp to match each one at
  a start of a line followed by a blank space:
  (\"fix\" \"close\") => \"fix |close \" "
  (let ((regexp (concat "^" (car kw) " ")))
    (concat regexp (mapconcat (lambda (it)
                                (concat "\\|" it " "))
                              (cdr kw)
                              ""))))

(defvar git-commit-insert-issue--completing-fun #'completing-read)

;;;###autoload
(defun git-commit-insert-issue-ask-issues ()
  "Ask for the issue to insert."
  (interactive)
  (let ((ido-separator "\n"))
    (insert (funcall git-commit-insert-issue--completing-fun
                     "Choose the issue: "
                     (git-commit-insert-issue-get-issues-github-or-gitlab-or-bitbucket-format)))))

(defun git-commit-insert-issue-gitlab-insert ()
  "Choose and insert the issue id"
  (interactive)
  (let ((ido-separator "\n"))
    (insert (completing-read "Gitlab issue ? " (git-commit-insert-issue-gitlab-issues-format)))))

(defun insert-issue--get-remotes ()
  "Get this repo's remote names"
  (s-split "\n" (s-trim (shell-command-to-string "git remote"))))

(defun insert-issue--get-first-remote ()
  "Get the first remote name found in git config. It should be the prefered one."
  (let* ((first-remote
          (with-temp-buffer
            (insert-file-contents (concat (projectile-project-root) ".git/config"))
            (if (search-forward "[remote \"")
                (progn
                  (buffer-substring-no-properties (line-beginning-position) (line-end-position))))))
         (first-remote (car (cdr (s-split " " first-remote))))
         (first-remote (s-replace "\"" "" first-remote))
         (first-remote (s-chop-suffix "]" first-remote)))
    first-remote))

(defun insert-issue--get-remote-url ()
  "Get the url of the first remote" ;XXX: shall we ask if many remotes ?
  (shell-command-to-string (format "git config remote.%s.url"
                                   ;; (-first-item (insert-issue--get-remotes))))) ;; -first-item may not be the one we want.
                                   (insert-issue--get-first-remote))))

(defun insert-issue--get-server ()
  "Check the git host.
   From git@server.com:group/project.git or https://server.com/group/project, get server.com"
  (let* ((url (insert-issue--get-remote-url)) ;; git@gitlab.com:emacs-stuff/project-name.git
         ;; Dealing with different protocols: git@foo:bar or https://foo/bar
         ;; Could definitely be proper.
         (server-group-name (if (s-contains? "@" url)
                                (-first-item (cdr (s-split "@" url)))
                              (if (s-contains? "://" url)
                                  (-first-item (cdr (s-split "://" url))))))) ;; gitlab.com:emacs-stuff/project-name.git
    (when server-group-name
      (if (s-contains? ":" server-group-name)
          (car (s-split ":" server-group-name))
        (if (s-contains? "/" server-group-name)
            (car (s-split "/" server-group-name)))))))

(defun insert-issue--get-group ()
  "The remote group can be different than the author.
   From git@server.com:group/project.git, get group"
  ;; Again, dealing with git@ or https?://
  (let* ((url (insert-issue--get-remote-url)) ;; git@gitlab.com:emacs-stuff/project-name.git
         (server-group-name (if (s-contains? "@" url)
                                (-first-item (cdr (s-split "@" url)))
                              (car (cdr (s-split "://" url))))) ;; gitlab.com:emacs-stuff/project-name.git
         (group-project (when server-group-name
                          (if (s-contains? ":" server-group-name)
                              (cdr (s-split ":" server-group-name))
                            (cdr (s-split "/" server-group-name))))) ;; emacs-stuff/project-name.git
         (group (when group-project
                  (-first-item (s-split "/" (-first-item group-project)))))) ;; emacs-stuff
    (if group
        group
      (error "git-commit-insert-issue: we did not find the project name by reading your remote URL. To help us you can make sure your first [remote] in your .git/config is one of Github, Gitlab or Bitbucket."))))


;;;###autoload
(define-minor-mode git-commit-insert-issue-mode
  "See the issues when typing 'Fixes #' in a commit message."
  :global nil
  :group 'git
  (if git-commit-insert-issue-mode
      (progn
        (define-key git-commit-mode-map "#"
          (lambda () (interactive)
             (if (looking-back
                  (git-commit-insert-issue--construct-regexp (append
                                                              git-commit-insert-issue-github-keywords
                                                              git-commit-insert-issue-gitlab-keywords)))
                 (git-commit-insert-issue-ask-issues)
               (self-insert-command 1)))))
    (define-key git-commit-mode-map "#" (insert "#"))))

(provide 'git-commit-insert-issue)

;;; git-commit-insert-issue.el ends here
