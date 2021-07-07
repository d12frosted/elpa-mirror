;;; git-commit-insert-issue.el --- Get issues list when typing "Fixes #"

;; Copyright (C) 2015-2021 vindarel <ehvince@mailz.org>

;; Author: Vindarel
;; URL: https://gitlab.com/emacs-stuff/git-commit-insert-issue/
;; Package-Version: 20210107.2018
;; Package-Commit: 6cfb8b4b5b23ae881cf3d005da4d7f60d91cd2cd
;; Keywords: tools, vc, github, gitlab, bitbucket, commit, issues
;; Version: 0.4.1
;; Package-Requires: ((emacs "25") (projectile "0") (s "0") (ghub "0") (bitbucket "0"))
;; Summary: Get issues list when typing "Fixes #" (or another keyword) in a commit message. For Github, Gitlab and Bitbucket.

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
(require 'projectile)  ;; update, 2020: now only used to get the project root. Alternatives?
(require 's)

(defvar git-commit-insert-issue-github-keywords '("Fixes" "fixes" "fix" "fixed"
                                "close" "closes" "closed"
                                "resolve" "resolves" "resolved")
  "List of keywords that github accepts to close issues.")

(defvar git-commit-insert-issue-gitlab-keywords '("see" "for")
  "List of keywords to reference an issue with Gitlab. Gitlab works on 'fixes' and the like, but isn't limited to them. We can reference any issue with a sharpsign only.")

(defvar git-commit-insert-issue-bitbucket-keywords
  '("see" "for"
    "closing" "resolving"
    "reopen" "reopens" "reopening"
    "hold" "holds" "holding"
    "wontfix"
    "invalidate" "invalidates" "invalidated" "invalidating"
    "addresses" "re" "references" "ref" "refs")
  "Similar to Gitlab, Bitbucket can reference issues with or without keywords, see: https://confluence.atlassian.com/bitbucket/resolve-issues-automatically-when-users-push-code-221451126.html")

(defvar +git-commit-insert-issues-gitlab-api-error+ "HTTP error to Gitlab's API for %s. If it is not a self-hosted Gitlab, you might want to change the order of your remotes in .git/config."
  "Error message with a projectname placeholder. This can happen when we assume that a remote is a self-hosted Gitlab but is not.
  The order of the remotes in .git/config is important, we take the first one.")

(defun git-commit-insert-issue-project-id (&optional project username)
  (let* ((group/project (or username (git-commit-insert-issue--get-group/project)))
         (project (or project (second group/project))))
    (format "%s/%s" (first group/project) project)))

(defun git-commit-insert-issue-get-gitlab-issues (projectname username)
  "Manual call to Gitlab's AP v4: /projects/:id/issues. Get closed issues only.
  The project id is username%2Fprojectname.
  TODO: auth for private projects."
  (or projectname username
      (error (s-concat "We can't get Gitlab issues: we don't know the project name or the user name ('" projectname "' and '" username "').")))
  (let ((id (s-concat username "%2F" projectname)))
    (condition-case nil
        (glab-get (s-concat "/projects/" id "/issues?state=opened") nil :auth 'none)
      (error
                                        ;XXX: catch only the HTTP error?
       (error (format +git-commit-insert-issues-gitlab-api-error+ username))))))

(defun git-commit-insert-issue-gitlab-issues (&optional projectname username)
  "Return a list of the opened issues on gitlab."
  (git-commit-insert-issue-get-gitlab-issues projectname username))

(defun git-commit-insert-issue-gitlab-issues-format (&optional username project-name)
  "Get issues and return a list of strings formatted with '#id - title'"
  (let* ((group/project (or username (git-commit-insert-issue--get-group/project)))
         (project (or project-name (second group/project)))
         (issues (git-commit-insert-issue-gitlab-issues project (first group/project))))
    (--map (format "#%i - %s" (alist-get 'iid it) (alist-get 'title it))
           issues)))

(defun git-commit-insert-issue-github-issues (&optional username project-name)
  "Return a plist of github issues, raw from the api request."
  (let ((group/project (or username (git-commit-insert-issue--get-group/project)))
        (project (or project-name (second (group/project)))))
    (ghub-get (s-concat "/repos/" (first group/project) "/" project "/issues") nil :auth 'none)))

(defun git-commit-insert-issue-github-issues-format (&optional username project-name)
  "Get all the issues from the current project.
   Return a list of formatted strings: '#id - title'"
  (let* ((group/project (or username (git-commit-insert-issue--get-group/project)))
         (project (or project-name (second group/project)))
         (issues (git-commit-insert-issue-github-issues (first group/project) project)))
    (if (string= (alist-get 'message issues) "Not Found")
          (error (concat "Nothing found with user " (first group/project) " in project " (second group/project)))
      (progn
        ;;todo: watch for api rate limit.
        (setq git-commit-insert-issue-project-issues
              (--map
               (format "#%i - %s" (alist-get 'number it) (alist-get 'title it))
               issues))))))

(defun git-commit-insert-issue-bitbucket-issues (&optional username project-name)
  "Return a list of bitbucket issues."
  (let* ((group/project (git-commit-insert-issue--get-group/project))
         (project (or project-name (second group/project))))
    (bitbucket-issues-list-all (first group/project) project)))

(defun git-commit-insert-issue-bitbucket-issues-format (&optional username project-name)
  "Get issues and return a list of strings formatted with '#id - title'"
  (--map (format "#%i - %s" (assoc-default 'id it) (assoc-default 'title it))
    (git-commit-insert-issue-bitbucket-issues username project-name)))

(defun git-commit-insert-issue-get-issues-github-or-gitlab-or-bitbucket-format ()
  "Get the list of issues, from Github, Gitlab or Bitbucket."
  (let ((remote-server-name (git-commit-insert-issue--get-server)))
    (cond ((string-equal "github.com" remote-server-name)
           (git-commit-insert-issue-github-issues-format))
          ((string-equal "bitbucket.org" remote-server-name)
           (git-commit-insert-issue-bitbucket-issues-format))
          ;; for every other choice it's gitlab atm, since github isn't self hosted it won't have other names.
          ((s-contains-p "gitlab" remote-server-name)
           (git-commit-insert-issue-gitlab-issues-format))
          (t
           (message (s-concat "git-commit-insert-issue: we found a remote named " remote-server-name ", and we'll assume it is a Gitlab self-hosted server."))
           (git-commit-insert-issue-gitlab-issues-format)))))

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

(defun git-commit-insert-issue--get-remotes ()
  "Get this repo's remote names"
  (s-split "\n" (s-trim (shell-command-to-string "git remote"))))

(defun git-commit-insert-issue--get-first-remote ()
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

(defun git-commit-insert-issue--get-remote-url ()
  "Get the url of the first remote" ;XXX: shall we ask if many remotes ?
  (shell-command-to-string (format "git config remote.%s.url"
                                   ;; (-first-item (git-commit-insert-issue--get-remotes))))) ;; -first-item may not be the one we want.
                                   (git-commit-insert-issue--get-first-remote))))

(defun git-commit-insert-issue--get-server ()
  "Return the git host name of the first remote for this project

  We read the .git/config file, we find the first remote:

  [remote \"origin\"]
      url = git@gitlab.com:emacs-stuff/git-commit-insert-issue.git
      fetch = +refs/heads/*:refs/remotes/origin/*

  and we get the server part, here gitlab.com."
  (let* ((url (git-commit-insert-issue--get-remote-url)) ;; git@gitlab.com:emacs-stuff/project-name.git
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

(defun git-commit-insert-issue--get-group/project ()
  "The remote group can be different than the author.
   The project name can be different than the directory.
   From git@server.com:group/project.git, get group and project.
   Return: a list."
  ;; Again, dealing with git@ or https?://
  (let* ((url (git-commit-insert-issue--get-remote-url)) ;; git@gitlab.com:emacs-stuff/project-name.git
         (server-group-name (if (s-contains? "@" url)
                                (-first-item (cdr (s-split "@" url)))
                              (car (cdr (s-split "://" url))))) ;; gitlab.com:emacs-stuff/project-name.git
         (group-project (when server-group-name
                          (if (s-contains? ":" server-group-name)
                              (cdr (s-split ":" server-group-name))
                            (cdr (s-split "/" server-group-name))))) ;; emacs-stuff/project-name.git
         (group (when group-project
                  (-first-item (s-split "/" (-first-item group-project)))))  ;; emacs-stuff
         (project (when group-project
                    (second (s-split "/" (-first-item group-project))))) ;; project-name.git
         (project (when project
                    (first (s-split "\\." project))))) ;; project-name
    (unless group
        (error "git-commit-insert-issue: we did not find the project's group name by reading your remote URL. To help us you can make sure your first [remote] in your .git/config is one of Github, Gitlab or Bitbucket."))
    (unless project
        (error "git-commit-insert-issue: we did not find the project name by reading your remote URL. To help us you can make sure your first [remote] in your .git/config is one of Github, Gitlab or Bitbucket."))
    (list group project)))

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
                                                              git-commit-insert-issue-bitbucket-keywords
                                                              git-commit-insert-issue-gitlab-keywords)))
                 (git-commit-insert-issue-ask-issues)
               (self-insert-command 1)))))
    (define-key git-commit-mode-map "#" (insert "#"))))

(provide 'git-commit-insert-issue)

;;; git-commit-insert-issue.el ends here
