;;; helm-open-github.el --- Utilities of Opening Github Page -*- lexical-binding: t; -*-

;; Copyright (C) 2016 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-helm-open-github
;; Package-Version: 20170220.159
;; Package-Commit: 2f03d97552a1233db7694116d5f80ecde7612756
;; Version: 0.15
;; Package-Requires: ((emacs "24.4") (helm-core "1.7.7") (gh "0.8.2"))

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

;; Open github URL utilities. This package is inspired by URL below.
;;   - http://shibayu36.hatenablog.com/entry/2013/01/18/211428

;;; Code:

(require 'cl-lib)

(require 'helm)
(require 'gh-issues)
(require 'gh-pulls)

(defgroup helm-open-github nil
  "Utilities of opeg "
  :prefix "helm-open-github-"
  :group 'http)

(defcustom helm-open-github-commit-limit 100
  "Limit of commit id collected"
  :type 'integer)

(defcustom helm-open-github-issues-api
  (gh-issues-api "api" :sync t :cache nil :num-retries 1)
  "Github API instance. This is-a `gh-issues'"
  :type 'gh-issues-api)

(defcustom helm-open-github-pulls-api
  (gh-pulls-api "api" :sync t :cache nil :num-retries 1)
  "Github API instance. This is-a `gh-pulls'"
  :type 'gh-pulls-api)

(defcustom helm-open-github-closed-issue-since 19
  "Only issues updated this number of days ago are returned."
  :type 'integer)

(defcustom helm-open-github-closed-issue-sort-direction "asc"
  "Direction of the sort for closed issues.
Either \"asc\" or \"desc\"."
  :type '(radio :tag "Preferred direction of the sort"
          (const :tag "Ascendent" "asc")
          (const :tag "Descendent" "desc")))

(defcustom helm-open-github-requires-pattern nil
  "Minimal length to search. As fetching data is an expensive
operation with potentially many results, higher number is
recomended for bigger projects or slower connections.
If this value is non-nil, delayed search is disabled."
  :type '(choice (integer :tag "Minimal length")
                 (boolean :tag "Disable delayed search" nil)))

(defun helm-open-github--collect-commit-id ()
  (with-current-buffer (helm-candidate-buffer 'global)
    (let ((ret (call-process "git" nil t nil
                             "--no-pager" "log"
                             "-n" (number-to-string helm-open-github-commit-limit)
                             "--pretty=oneline" "--abbrev-commit")))
      (unless (zerop ret)
        (error "Failed: get commit ID")))))

(defun helm-open-github--command-one-line (cmd args)
  (with-temp-buffer
    (when (zerop (apply 'call-process cmd nil t nil args))
      (goto-char (point-min))
      (buffer-substring-no-properties
       (line-beginning-position) (line-end-position)))))

(defun helm-open-github--full-commit-id (abbrev-id)
  (or (helm-open-github--command-one-line "git" `("rev-parse" ,abbrev-id))
      (error "Failed: 'git rev-parse %s'" abbrev-id)))

(defun helm-open-github--root-directory ()
  (let ((root (helm-open-github--command-one-line "git" '("rev-parse" "--show-toplevel"))))
    (if (not root)
        (error "Error: here is not Git repository")
      (file-name-as-directory root))))

(defun helm-open-github--host ()
  (or (helm-open-github--command-one-line "git" '("config" "--get" "hub.host"))
      "github.com"))

(defun helm-open-github--remote-url ()
  (or (helm-open-github--command-one-line "git" '("config" "--get" "remote.origin.url"))
      (error "Failed: Can't get remote.origin URL")))

(defun helm-open-github--extract-user-host (remote-url)
  (if (string-match "[:/]\\([^/]+\\)/\\([^/]+?\\)\\(?:\\.git\\)?\\'" remote-url)
      (cl-values (match-string 1 remote-url) (match-string 2 remote-url))
    (error "Failed: match %s" remote-url)))

(defun helm-open-github--commit-url (host remote-url commit-id)
  (cl-multiple-value-bind (user repo) (helm-open-github--extract-user-host remote-url)
    (format "https://%s/%s/%s/commit/%s"
            host user repo commit-id)))

(defun helm-open-github--from-commit-open-url-common (commit-id)
  (let* ((host (helm-open-github--host))
         (remote-url (helm-open-github--remote-url)))
    (browse-url
     (helm-open-github--commit-url host remote-url commit-id))))

(defun helm-open-github--full-commit-id-from-candidate (line)
  (let ((commit-line (split-string line " ")))
    (helm-open-github--full-commit-id (car commit-line))))

(defun helm-open-github--from-commit-id-persistent-action (line)
  (let* ((commit-id (helm-open-github--full-commit-id-from-candidate line))
         (str (shell-command-to-string
               (format "git show --stat --oneline %s" commit-id))))
    (with-help-window (help-buffer)
      (princ str))))

(defun helm-open-github--from-commit-open-url (_candidate)
  (dolist (commit-line (helm-marked-candidates))
    (let ((commit-id (helm-open-github--full-commit-id-from-candidate commit-line)))
      (helm-open-github--from-commit-open-url-common commit-id))))

(defun helm-open-github--from-commit-open-url-with-input (_candidate)
  (let ((commit-id (read-string "Input Commit ID: ")))
    (helm-open-github--from-commit-open-url-common
     (helm-open-github--full-commit-id commit-id))))

(defun helm-open-github--show-commit-id-common (commit-id)
  (with-current-buffer (get-buffer-create "*open-github-issues*")
    (unless (call-process "git" nil t nil "show" "--stat" "-p" commit-id)
      (error "Error: 'git show --stat -p %s'" commit-id))
    (goto-char (point-min))
    (pop-to-buffer (current-buffer))))

(defun helm-open-github--show-commit-id (line)
  (let* ((commit-line (split-string line " "))
         (commit-id (helm-open-github--full-commit-id (car commit-line))))
    (helm-open-github--show-commit-id-common commit-id)))

(defun helm-open-github--show-commit-id-with-input (_candidate)
  (let ((commit-id (read-string "Input Commit ID: ")))
    (helm-open-github--show-commit-id-common
     (helm-open-github--full-commit-id commit-id))))

(defvar helm-open-github--from-commit-source
  (helm-build-in-buffer-source "Open Github From Commit"
    :init #'helm-open-github--collect-commit-id
    :persistent-action #'helm-open-github--from-commit-id-persistent-action
    :action (helm-make-actions
             "Open Commit Page" #'helm-open-github--from-commit-open-url
             "Show Detail" #'helm-open-github--show-commit-id)))

(defvar helm-open-github--from-commit-direct-input-source
  (helm-build-sync-source "Open Github From Commit Direct Input"
   :candidates '("Input Commit ID")
   :action (helm-make-actions
            "Open Commit Page" #'helm-open-github--from-commit-open-url-with-input
            "Show Detail" #'helm-open-github--show-commit-id-with-input)))

;;;###autoload
(defun helm-open-github-from-commit ()
  (interactive)
  (helm :sources '(helm-open-github--from-commit-source
                   helm-open-github--from-commit-direct-input-source)
        :buffer "*helm open github*"))

(defun helm-open-github--collect-files ()
  (let ((root (helm-open-github--root-directory)))
    (with-current-buffer (helm-candidate-buffer 'global)
      (let ((default-directory root))
        (unless (zerop (call-process "git" nil t nil "ls-files"))
          (error "Failed: 'git ls-files' at %s" default-directory))))))

(defun helm-open-github--branch ()
  (let ((branch (helm-open-github--command-one-line "git" '("symbolic-ref" "HEAD"))))
    (if (not branch)
        (error "Failed: 'git symbolic-ref HEAD'")
      (replace-regexp-in-string "\\`refs/heads/" "" branch))))

(defun helm-open-github--file-url (host remote-url branch file marker)
  (cl-multiple-value-bind (user repo) (helm-open-github--extract-user-host remote-url)
    (format "https://%s/%s/%s/blob/%s/%s%s"
            host user repo branch file marker)))

(defun helm-open-github--highlight-marker (start end)
  (cond ((and start end)
         (format "#L%s..L%s" start end))
        (start
         (format "#L%s" start))
        (t "")))

(defun helm-open-github--from-file-action (file &optional start end)
  (let ((host (helm-open-github--host))
        (remote-url (helm-open-github--remote-url))
        (branch (helm-open-github--branch))
        (marker (helm-open-github--highlight-marker start end)))
    (browse-url
     (helm-open-github--file-url host remote-url branch file marker))))

(defun helm-open-github--from-file-highlight-region-action (file)
  (let ((start-line (read-number "Start Line: "))
        (end-line (read-number "End Line: ")))
    (helm-open-github--from-file-action file start-line end-line)))

(defun helm-open-github--from-file-highlight-line-action (file)
  (let ((start-line (read-number "Start Line: ")))
    (helm-open-github--from-file-action file start-line)))

(defvar helm-open-github--from-file-source
  (helm-build-in-buffer-source "Open Github From File"
    :init #'helm-open-github--collect-files
    :action (helm-make-actions
             "Open File" (lambda (_cand)
                           (dolist (file (helm-marked-candidates))
                             (helm-open-github--from-file-action file)))
             "Open File and Highlight Line" #'helm-open-github--from-file-highlight-line-action
             "Open File and Highlight Region" #'helm-open-github--from-file-highlight-region-action)))

(defun helm-open-github--from-file-direct (file start end)
  (let* ((root (helm-open-github--root-directory))
         (repo-path (file-relative-name file root))
         (start-line (line-number-at-pos start))
         (end-line (line-number-at-pos end)))
    (helm-open-github--from-file-action repo-path start-line end-line)))

;;;###autoload
(defun helm-open-github-from-file ()
  (interactive)
  (if mark-active
      (helm-open-github--from-file-direct (buffer-file-name) (region-beginning) (region-end))
    (helm :sources '(helm-open-github--from-file-source)
          :buffer "*helm open github*")))

(defun helm-open-github--collect-issues ()
  (let ((remote-url (helm-open-github--remote-url)))
    (cl-multiple-value-bind (user repo) (helm-open-github--extract-user-host remote-url)
      (let ((issues (gh-issues-issue-list helm-open-github-issues-api user repo)))
        (if (null issues)
            (error "This repository has no issues!!")
          (sort (oref issues data)
                (lambda (a b) (> (oref a number) (oref b number)))))))))

(defmethod gh-issues-issue-list-closed ((api gh-issues-api) user repo)
  (gh-api-authenticated-request
   api (gh-object-list-reader (oref api issue-cls)) "GET"
   (format "/repos/%s/%s/issues" user repo)
   nil `(("state" . "closed")
         ("since" . ,(format-time-string
                      "%y-%m-%dT%H:%M:%SZ"
                      (time-subtract
                       (current-time)
                       (seconds-to-time
                        (* (* (* helm-open-github-closed-issue-since 24)
                              60) 60)))))
         ("direction" . ,helm-open-github-closed-issue-sort-direction))))

(defun helm-open-github--collect-closed-issues ()
  (let ((remote-url (helm-open-github--remote-url)))
    (cl-multiple-value-bind (user repo) (helm-open-github--extract-user-host remote-url)
      (let ((issues (gh-issues-issue-list-closed helm-open-github-issues-api user repo)))
        (if (null issues)
            (error "This repository has no issues!!")
            (sort (oref issues data)
                  (lambda (a b) (> (oref a number) (oref b number)))))))))

(defun helm-open-github--convert-issue-api-url (url)
  (replace-regexp-in-string
   "api\\." ""
   (replace-regexp-in-string "/repos" "" url)))

(defun helm-open-github--from-issues-format-candidate (issue)
  (with-slots (number title state) issue
    (propertize (format "#%-4d [%s] %s" number state title)
                'helm-realvalue issue)))

(defun helm-open-github--open-issue-url (_candidate)
  (dolist (issue (helm-marked-candidates))
    (browse-url (oref issue html-url)
                (helm-open-github--convert-issue-api-url (oref issue url)))))

(defvar helm-open-github--issues-cache (make-hash-table :test 'equal))
(defvar helm-open-github--from-issues-source
  (helm-build-in-buffer-source "Open Github From Open Issues"
    :init (lambda ()
            (let* ((key (helm-open-github--remote-url))
                   (issues (gethash key helm-open-github--issues-cache)))
              (unless issues
                (setq issues
                      (puthash key (helm-open-github--collect-issues)
                               helm-open-github--issues-cache)))
              (helm-init-candidates-in-buffer 'global
                (cl-loop for c in issues
                         collect (helm-open-github--from-issues-format-candidate c)))))
    :delayed (not (null helm-open-github-requires-pattern))
    :requires-pattern helm-open-github-requires-pattern
    :get-line 'buffer-substring
    :action (helm-make-actions
             "Open issue page with browser" #'helm-open-github--open-issue-url)))

(defvar helm-open-github--closed-issues-cache (make-hash-table :test 'equal))
(defvar helm-open-github--from-closed-issues-source
  (helm-build-in-buffer-source "Open Github From closed Issues"
    :init (lambda ()
            (let* ((key (helm-open-github--remote-url))
                   (issues (gethash key helm-open-github--closed-issues-cache)))
              (unless issues
                (setq issues
                      (puthash key (helm-open-github--collect-closed-issues)
                               helm-open-github--closed-issues-cache)))
              (helm-init-candidates-in-buffer 'global
                (cl-loop for c in issues
                         collect (helm-open-github--from-issues-format-candidate c)))))
    :delayed (not (null helm-open-github-requires-pattern))
    :requires-pattern helm-open-github-requires-pattern
    :get-line 'buffer-substring
    :action (helm-make-actions
             "Open issue page with browser" #'helm-open-github--open-issue-url)))

(defun helm-open-github--construct-issue-url (host remote-url issue-id)
  (cl-multiple-value-bind (user repo) (helm-open-github--extract-user-host remote-url)
    (format "https://%s/%s/%s/issues/%s"
            host user repo issue-id)))

(defun helm-open-github--from-issues-direct (host)
  (let ((remote-url (helm-open-github--remote-url))
        (issue-id (read-number "Issue ID: ")))
    (browse-url
     (helm-open-github--construct-issue-url host remote-url issue-id))))

;;;###autoload
(defun helm-open-github-from-issues (arg)
  (interactive "P")
  (let ((host (helm-open-github--host))
        (url (helm-open-github--remote-url)))
    (when arg
      (remhash url helm-open-github--closed-issues-cache)
      (remhash url helm-open-github--issues-cache))
    (if (not (string= host "github.com"))
        (helm-open-github--from-issues-direct host)
      (helm :sources '(helm-open-github--from-issues-source
                       helm-open-github--from-closed-issues-source)
            :buffer  "*helm open github*"))))

(defvar helm-open-github--pull-requests nil)
(defun helm-open-github--collect-pullreqs ()
  (let ((remote-url (helm-open-github--remote-url)))
    (cl-multiple-value-bind (user repo) (helm-open-github--extract-user-host remote-url)
      (let ((pullreqs (gh-pulls-list helm-open-github-pulls-api user repo)))
        (if (null pullreqs)
            (error "This repository has no pull requests!!")
          (setq helm-open-github--pull-requests
                (sort (oref pullreqs data)
                      (lambda (a b) (< (oref a number) (oref b number))))))))))

(defun helm-open-github--pulls-view-common (url)
  (with-current-buffer (get-buffer-create "*open-github-diff*")
    (view-mode -1)
    (erase-buffer)
    (unless (zerop (call-process "curl" nil t nil "-s" url))
      (error "Can't download %s" url))
    (goto-char (point-min))
    (diff-mode)
    (view-mode +1)
    (pop-to-buffer (current-buffer))))

(defun helm-open-github--pulls-view-diff (candidate)
  (helm-open-github--pulls-view-common (oref candidate diff-url)))

(defun helm-open-github--pulls-view-patch (candidate)
  (helm-open-github--pulls-view-common (oref candidate patch-url)))

(defvar helm-open-github--from-pulls-source
  (helm-build-sync-source "Open Github From Issues"
    :init #'helm-open-github--collect-pullreqs
    :candidates 'helm-open-github--pull-requests
    :volatile t
    :delayed (not (null helm-open-github-requires-pattern))
    :requires-pattern helm-open-github-requires-pattern
    :real-to-display 'helm-open-github--from-issues-format-candidate
    :action (helm-make-actions
             "Open issue page with browser" #'helm-open-github--open-issue-url
             "View Diff" #'helm-open-github--pulls-view-diff
             "View Patch" #'helm-open-github--pulls-view-patch)))

;;;###autoload
(defun helm-open-github-from-pull-requests ()
  (interactive)
  (let ((host (helm-open-github--host)))
    (if (not (string= host "github.com"))
        (helm-open-github--from-issues-direct host)
      (helm :sources '(helm-open-github--from-pulls-source)
            :buffer  "*helm open github*"))))

(provide 'helm-open-github)

;;; helm-open-github.el ends here
