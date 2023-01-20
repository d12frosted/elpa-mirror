;;; my-repo-pins.el --- Keep your git repositories organized -*- lexical-binding: t -*-

;;; Copyright (C) 2022-2023 Félix Baylac Jacqué
;;; Author: Félix Baylac Jacqué <felix at alternativebit.fr>
;;; Maintainer: Félix Baylac Jacqué <felix at alternativebit.fr>
;;; Version: 0.5
;; Package-Version: 20230120.1105
;; Package-Commit: e6fe3864e244e6db74b668d24857c04472b2d475
;;; Homepage: https://alternativebit.fr/projects/my-repo-pins/
;;; Package-Requires: ((emacs "26.1"))
;;; License:
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>
;;
;;; Commentary:
;; Open source developers often have to jump between projects, either
;; to read code, or to craft patches. My Repo Pins reduces the
;; friction so that it becomes trivial to do so.

;; The idea of the plugin is based on this idea; if the repository
;; URLs can be translated to a filesystem location, the local disk can
;; be used like a cache. My Repo Pins lazily clones the repo to the
;; filesystem location if needed, and then jumps into the project in
;; one single command. You don't have to remember where you put the
;; project on the local filesystem because it's always using the same
;; location. Something like this:
;;
;; ~/code-root
;; ├── codeberg.org
;; │   └── Freeyourgadget
;; │       └── Gadgetbridge
;; └── github.com
;;     ├── BaseAdresseNationale
;;     │   └── fantoir
;;     ├── mpv-player
;;     │   └── mpv
;;     └── NinjaTrappeur
;;         ├── cinny
;;         └── my-repo-pins
;;
;; The main entry point of this package is the my-repo-pins command.
;; Using it, you can either:
;;
;; - Open Dired in a local project you already cloned.
;; - Query remote forges for a repository, clone it, and finally open
;;   Dired in the clone directory.
;; - Clone a git clone URL and open Dired to the right directory.
;;
;; The minimal configuration consists in setting the directory in
;; which you want to clone all your git repositories via the
;; my-repo-pins-code-root variable.
;;
;; Let's say you'd like to store all your git repositories in the
;; ~/code-root directory. You'll want to add the following snippet in
;; your Emacs configuration file:
;;
;;    (require 'my-repo-pins)
;;    (setq my-repo-pins-code-root "~/code-root")
;;
;; You can then call the M-x my-repo-pins command to open a
;; project living in your ~/code-root directory or clone a new
;; project in your code root.
;;
;; Binding this command to a global key binding might make things a
;; bit more convenient. I personally like to bind it to M-h. You can
;; add the following snippet to your Emacs configuration to set up
;; this key binding:
;;
;;    (global-set-key (kbd "M-h") 'my-repo-pins)
;;
;; The my-repo-pins-open-function variable can be customized if you
;; would prefer to land in some other program than Dired.  Good
;; candidates might be the builtin 'vc-dir or 'magit-status if you use
;; the popular Magit package:
;;
;;    (setq my-repo-pins-open-function 'vc-dir)

;;; Code:

(require 'json)
(require 'url)
(require 'cl-lib)
;; Required to batch eval the module: the substring functions are
;; loaded by default in interactive emacs, not in batch-mode emacs.
(eval-when-compile (require 'subr-x))

(defgroup my-repo-pins-group nil
  "Variables used to setup the my-repo-pins project manager."
  :group 'Communication)

;; Internal: git primitives

(defcustom my-repo-pins-git-bin "git"
  "Path pointing to the git binary.
By default, it'll look for git in the current $PATH."
  :type 'file
  :group 'my-repo-pins-group)

(defun my-repo-pins--git-path ()
  "Find the git binary path using ‘my-repo-pins-git-bin’.

Errors out if we can't find it."
  (if (file-executable-p my-repo-pins-git-bin)
      my-repo-pins-git-bin
    (let ((git-from-bin-path (locate-file my-repo-pins-git-bin exec-path)))
      (if (file-executable-p git-from-bin-path)
          git-from-bin-path
          (user-error "Can't find git. Is my-repo-pins-git-bin correctly set?")))))

(defun my-repo-pins--call-git-in-dir-process-filter (str)
    "Filtering the git output for ‘my-repo-pins--call-git-in-dir’ call.

By default, git seems to be terminating its stdout/stderr lines using
the CR; sequence instead of the traditional CR;LF; unix sequence.

This filter tries to detect these isolated CR sequences and convert
them in a CR;LF sequence.

STR being the string we have to process."
    (replace-regexp-in-string "\r" "\n" str))

(defun my-repo-pins--call-git-in-dir (dir &optional callback &rest args)
  "Call the git binary as pointed by ‘my-repo-pins-git-bin’ in DIR with ARGS.

Once the git subprocess exists, call CALLBACK with a the process exit
code as single argument. If CALLBACK is set to nil, don't call any
callback.

Returns the git PROCESS object."
  (let* ((git-buffer (get-buffer-create "*my repo pins git log*"))
        (git-window nil)
        (current-buffer (current-buffer))
        (git-filter (lambda
                      (proc str)
                      (with-current-buffer (process-buffer proc)
                        (insert (my-repo-pins--call-git-in-dir-process-filter str)))))
        (git-sentinel (lambda
                        (process _event)
                        (let ((exit-code (process-exit-status process)))
                          (if (window-valid-p git-window)
                              (delete-window git-window))
                          (if callback
                              (funcall callback exit-code))))))
    (set-buffer git-buffer)
    (erase-buffer)
    (setq default-directory dir)
    (setq git-window (display-buffer git-buffer))
    (prog1
        (make-process
         :name "my-repo-pins-git-subprocess"
         :buffer git-buffer
         :command (seq-concatenate 'list `(,(my-repo-pins--git-path)) args)
         :filter git-filter
         :sentinel git-sentinel)
      (set-buffer current-buffer))))


(defun my-repo-pins--is-clone-url-in-code-root (clone-url code-root)
  "Check if CLONE-URL has been already cloned to the CODE-ROOT.

Return t if that's the case, nil if it's not."
  (let ((clone-filepath (my-repo-pins--filepath-from-clone-url clone-url)))
    (and
     (not (eq nil clone-filepath))
     (file-directory-p
      (concat code-root
              (my-repo-pins--filepath-from-clone-url clone-url))))))

(defun my-repo-pins--git-clone-in-dir (clone-url checkout-filepath &optional callback)
  "Clone the CLONE-URL repo at CHECKOUT-FILEPATH.

Call CALLBACK with the git exit code once the git subprocess exits.
Checks first whether or not CLONE-URL is valid using
‘my-repo-pins--git-ls-remote-in-dir’ to prevent git clone from
creating an empty directory at CHECKOUT-FILEPATH."
  (my-repo-pins--git-ls-remote-in-dir
   clone-url
   (lambda (exit-code)
     (if (eq exit-code 0)
         (my-repo-pins--call-git-in-dir "~/" callback "clone" clone-url checkout-filepath)
       (funcall callback exit-code)))))

(defun my-repo-pins--git-ls-remote-in-dir (clone-url &optional callback)
  "Check if a CLONE-URL is valid using git ls-remote.

Call CALLBACK with no arguments once the git subprocess exists."
  (my-repo-pins--call-git-in-dir "~/" callback "ls-remote" "-q" "--exit-code" clone-url))

;;===========================
;; Internal: builtin fetchers
;;===========================

;; Generic fetcher infrastructure
(defvar my-repo-pins--builtins-forge-fetchers
  '(("GitHub.com" .
     ((query-user-repo . my-repo-pins--query-github-owner-repo)))
    ("GitLab.com" .
     ((query-user-repo . (lambda (owner repo cb) (my-repo-pins--query-gitlab-owner-repo "gitlab.com" owner repo cb)))))
    ("git.sr.ht" .
     ((query-user-repo . (lambda (owner repo cb) (my-repo-pins--query-sourcehut-owner-repo "git.sr.ht" owner repo cb)))))
    ("Codeberg.org" .
     ((query-user-repo . (lambda (owner repo cb) (my-repo-pins--query-gitea-owner-repo "codeberg.org" owner repo cb))))))

  "Fetchers meant to be used in conjunction with ‘my-repo-pins-forge-fetchers’.

This variable contains fetchers for:
- github.com")

(defcustom my-repo-pins-forge-fetchers
  my-repo-pins--builtins-forge-fetchers
  "List of forges for which we want to remote fetch projects."
  :type '(alist
          :key-type symbol
          :value-type (alist
                        :key-type symbol
                        :value-type (choice function string)))
  :group 'my-repo-pins-group)

(defvar my-repo-pins--forge-fetchers-state nil

  "Internal state where we keep a forge request status.

We use that state to populate the UI buffer.

This state is reprensented by a alist and looks something like that:

\((\"FORGE-NAME1\"
  (ssh . SSH-CHECKOUT-URL)
  (https . HTTPS-CHECKOUT-URL)))

A ongoing/failed lookup will also be represented by an entry in this alist:

\(\"FORGE-NAME1\" . 'loading)
\(\"FORGE-NAME1\" . 'not-found)")

(defvar my-repo-pins--forge-fetchers-state-mutex
  (make-mutex "my-repo-pins-ui-mutex")
  "Mutex in charge of preventing several fetchers to update the state concurently.")

(defcustom my-repo-pins-max-depth
  2
  "Maximum search depth starting from the ‘my-repo-pins-code-root’ directory.

Set this variable to nil if you don't want any limit.

This is a performance stop gap. It'll prevent my repo pins from
accidentally walking too deep if it fails to detect a project
boundary.

By default, this limit is set to 2 to materialize the
<forge>/<username> directories that are supposed to contain the
projects.

We won't search further once we reach this limit. A warning message is
issued to the *Messages* buffer to warn the user the limit has been
reached."
  :type 'integer
  :group 'my-repo-pins-group)

;; Sourcehut Fetcher
(defun my-repo-pins--query-sourcehut-owner-repo (instance-url user-name repo-name callback)
  "Query the INSTANCE-URL Sourcehut instance and retrieve some infos about a repo.

This function will try to determine whether or not the
USER-NAME/REPO-NAME repository exists in the INSTANCE-URL sourcehut
instance.

If so, calls the CALLBACK function with a alist containing the ssh and
https clone URLs. If the repo does not exists, calls the callback with
nil as parameter.

Note: the sourcehut GraphQL API isn't currently accessible without a
authentication token. We can't really afford to ask the user to
manually generate such a token for this plugin. We want it to work out
of the box. Meaning, instead of using the API, we query the webapp
using a HEAD request and infer the clone links from there."
  (setq url-request-method "HEAD")
  (url-retrieve
   (format "https://%s/~%s/%s" instance-url user-name repo-name)
   (lambda (status &rest _rest)
     (let ((repo-not-found (plist-get status :error)))
       (if repo-not-found
           (funcall callback nil)
         (funcall
          callback
          `((ssh . ,(format "git@%s:~%s/%s" instance-url user-name repo-name))
            (https . ,(format "https://%s/~%s/%s" instance-url user-name repo-name))))))))
  (setq url-request-method nil))

;; Gitlab Fetcher
(defun my-repo-pins--query-gitlab-owner-repo (instance-url user-name repo-name callback)
  "Queries the INSTANCE-URL Gitlab instance and retrieve some infos about a repo.

This function will try to determine whether or not the
USER-NAME/REPO-NAME repository exists in the INSTANCE-URL Gitlab
instance.

If so, calls the CALLBACK function with a alist containing the ssh and
https clone URLs. If the repo does not exists, calls the callback with
nil as parameter.

Note: the gitlab GraphQL API is not accessible without a bearing
token, the gitlab REST API doesn't provide a endpoint to retrieve the
clone URL of a repository. Meaning instead of using an API, we make a
HEAD request to the repository HTTP endpoint and infer by ourselves
the clone URLs. It might go south at some point, but that's sadly the
only option we have for now."
  (setq url-request-method "HEAD")
  (url-retrieve
   (format "https://%s/%s/%s" instance-url user-name repo-name)
   (lambda (status &rest _rest)
     (let ((repo-not-found (plist-get status :error)))
       (if repo-not-found
           (funcall callback nil)
         (funcall
          callback
          `((ssh . ,(format "git@%s:%s/%s.git" instance-url user-name repo-name))
            (https . ,(format "https://%s/%s/%s.git" instance-url user-name repo-name))))))))
  (setq url-request-method nil))

;; Github Fetcher
(defun my-repo-pins--query-github-owner-repo (user-name repo-name callback)
  "Queries the GitHub API to retrieve some infos about a GitHub repo.
This function will first try to determine whether
github.com/USER-NAME/REPO-NAME exists.

If so, calls the CALLBACK function with a alist containing the ssh and
https clone URLs. If the repo does not exists, calls the callback with
nil as parameter."
  (url-retrieve
   (format "https://api.github.com/repos/%s/%s" user-name repo-name)
   (lambda (&rest _rest) (funcall callback (my-repo-pins--fetch-github-parse-response(current-buffer))))))


(defun my-repo-pins--fetch-github-parse-response (response-buffer)
  "Parse the RESPONSE-BUFFER containing a GET response from the GitHub API.

Parsing a response from a GET https://api.github.com/repos/user/repo request.

If the repo does exists, returns a alist in the form of:

`(
  (ssh . SSH-CHECKOUT-URL)
  (https . HTTPS-CHECKOUT-URL))

Returns nil if the repo does not exists."
  (set-buffer response-buffer)
  (goto-char (point-min))
  (when (not(eq(re-search-forward "^HTTP/1.1 200 OK$" nil t) nil))
    (goto-char (point-min))
    (re-search-forward "^$")
    (delete-region (point) (point-min))
    (let* ((parsed-buffer (json-read))
           (ssh-url (alist-get 'ssh_url parsed-buffer))
           (https-url (alist-get 'clone_url parsed-buffer)))
      `((ssh . ,ssh-url)
        (https . ,https-url)))))

;; Gitea Fetcher
(defun my-repo-pins--query-gitea-owner-repo (instance-url user-name repo-name callback)
  "Queries the INSTANCE-URL gitea instance to retrieve a repo informations.
This function will first try to determine whether the
USER-NAME/REPO-NAME exists.

If so, calls the CALLBACK function with a alist containing the ssh and
https clone URLs. If the repo does not exists, calls the callback with
nil as parameter."
  (url-retrieve
   (format "https://%s/api/v1/repos/%s/%s" instance-url user-name repo-name)
   (lambda (&rest _rest) (funcall callback (my-repo-pins--fetch-gitea-parse-response(current-buffer))))))

(defun my-repo-pins--fetch-gitea-parse-response (response-buffer)
  "Parse the RESPONSE-BUFFER containing a GET response from the Gitea API.

Parsing a response from a GET https://instance/api/v1/repos/user/repo request.

If the repo does exists, returns a alist in the form of:

`(
  (ssh . SSH-CHECKOUT-URL)
  (https . HTTPS-CHECKOUT-URL))

Returns nil if the repo does not exists."
  (set-buffer response-buffer)
  (goto-char (point-min))
  (when (not(eq(re-search-forward "^HTTP/1.1 200 OK$" nil t) nil))
    (goto-char (point-min))
    (re-search-forward "^$")
    (delete-region (point) (point-min))
    (let* ((parsed-buffer (json-read))
           (ssh-url (alist-get 'ssh_url parsed-buffer))
           (https-url (alist-get 'clone_url parsed-buffer)))
      `((ssh . ,ssh-url)
        (https . ,https-url)))))

;;==========================
;; Internal: repo URI parser
;;==========================

(defun my-repo-pins--parse-repo-identifier (query-str)
  "Do its best to figure out which repo the user meant by QUERY-STR.

A valid QUERY-STR is in one of the 4 following formats:

1. project
   Jump to the project if available, do not fetch a remote forge
   project.
2. owner/project
   Open a promp with available projects + fetch all the remote
   forges.
3. forge.tld/owner/project
   Open the project is available, fetch it if not.
4. https://forge.tld/owner/project
   Open the project is available, fetch it if not.

This function will return a tagged union in the form of a alist. For
each kind of format, it'll return something along the line of:

\(('tag . 'full-url) ('full-url .\
\"https://full-url.org/path/to/git/repo/checkout\"))
or
\(('tag . 'owner-repo) ('owner . \"NinjaTrappeur\") ('repo\
. \"my-repo-pins\"))
or
\(('tag . 'repo) ('repo . \"my-repo-pins\"))"
  (cond
   ;; Full-url case
   ((or (string-match "^https?://.*/.*/.*$" query-str)
        (string-match "^.*/.*/.*$" query-str)
        (string-match "^.*@.*:?.*$" query-str))
    `((tag . full-url) (full-url . ,query-str)))
   ;; owner/repo case
   ((string-match "^.*/.*$" query-str)
    (let*
        ((splitted-query (split-string query-str "/"))
         (owner (car splitted-query))
         (repo (cadr splitted-query)))
    `((tag . owner-repo) (owner . ,owner) (repo . ,repo))))
   ;; repo case
   (t `((tag . repo) (repo . ,query-str)))))

(defun my-repo-pins--filepath-from-clone-url (clone-url)
  "Return the relative path relative to the coderoot for CLONE-URL.

CLONE-STR being the git clone URL we want to find the local path for."
  (let*
      ((is-http (string-match-p "^https?://.*$" clone-url))
       (is-ssh (string-match-p "^\\(ssh://\\)?.*@.*:.*$" clone-url)))
    (cond (is-http
           (string-remove-suffix
            ".git"
            (cadr(split-string clone-url "//"))))
          (is-ssh
           (let*
               ((url-without-user (cadr(split-string clone-url "@")))
                (colon-split (split-string url-without-user ":"))
                (fqdn (car colon-split))
                (repo-url (string-remove-suffix ".git" (cadr colon-split))))
             (format "%s/%s" fqdn repo-url))))))

;;=========================================
;; Internal: code-root management functions
;;=========================================

(defcustom my-repo-pins-code-root nil
  "Root directory containing all your projects.
my-repo-pins organise the git repos you'll checkout in a tree
fashion.

All the code fetched using my-repo-pins will end up in this root directory. A
tree of subdirectories will be created mirroring the remote URI.

For instance, after checking out
https://git.savannah.gnu.org/git/emacs/org-mode.git, the source code
will live in the my-repo-pins-code-root/git.savannah.gnu.org/git/emacs/org-mode/
local directory"
  :type 'directory
  :group 'my-repo-pins-group)

(defun my-repo-pins--safe-get-code-root ()
    "Ensure ‘my-repo-pins-code-root’ is correctly set, then canonalize the path.
Errors out if ‘my-repo-pins-code-root’ has not been set yet."
    (when (not my-repo-pins-code-root)
      (user-error "My-Repo-Pins-code-root has not been set. Please point it to your code root"))
    (expand-file-name (file-name-as-directory my-repo-pins-code-root)))


(defun my-repo-pins--find-git-dirs-recursively (dir max-depth)
  "Vendored, slightly modified version of ‘directory-files-recursively’.

This library isn't available for Emacs > 25.1. Vendoring it for
backward compatibility.

We take advantage of vendoring this function to tailor it a bit more
for our needs.

Return list of all git repositories under directory DIR. This function works
recursively. Files are returned in \"depth first\" order, and files
from each directory are sorted in alphabetical order. Each file name
appears in the returned list in its absolute form.

The recursion will halt once MAX-DEPTH is reached. In that case, a
information message will be written to the message buffer.

If MAX-DEPTH is set to nil, do not use any recursion stop gap."
  (cl-labels
      ((recurse-in-dir
        (dir depth)
        (let* ((projects nil)
               (recur-result nil)
               (dir (directory-file-name dir)))
          (dolist (file (sort (file-name-all-completions "" dir)
			      'string<))
            (unless (member file '("./" "../"))
	      (if (directory-name-p file)
                  (let ((full-file (concat dir "/" file)))
	            ;; Don't follow symlinks to other directories.
	            (when (not (file-symlink-p full-file))
                      (if (my-repo-pins--is-git-dir full-file)
                          ;; It's a git repo, let's stop here.
                          (setq projects (nconc projects (list full-file)))
                        ;; It's not a git repo, let's recurse into it.
                        (if max-depth
                            ;; if we didn't reach the max depth yet, recurse.
                            (if (not (> (+ depth 1) max-depth))
                              (setq recur-result
                                    (nconc recur-result
                                           (recurse-in-dir full-file (+ depth 1))))
                              ;; we reached the max depth limit, issue a info message
                              (message
                               (concat
                                "my-repo-pins: max depth reached for "
                                "%s, we won't search for projects in that directory. "
                                "We might miss some projects. "
                                "Increase the my-repo-pins-max-depth variable value if "
                                "you want to look for projects in that directory.")
                               full-file))
                          ;; There's no max depth, let's recurse.
                          (setq recur-result
                                (nconc recur-result
                                       (recurse-in-dir full-file nil))))))))))
          (nconc recur-result (nreverse projects)))))
    (if max-depth
          (recurse-in-dir dir 0)
      (recurse-in-dir dir nil))))

(defun my-repo-pins--is-git-dir (dir)
  "Return non-nil if DIR is a git directory."
  (file-exists-p (concat (file-name-as-directory dir) ".git")))

(defun my-repo-pins--get-code-root-projects (code-root max-depth)
  "Retrieve the projects contained in the CODE-ROOT directory.
We're going to make some hard assumptions about how the
‘my-repo-pins-code-root’ directory should look like. First of all, if
a directory seem to be a git repository, it'll automatically be
considered as a project root.

It means that after encountering a git repository, we won't recurse
any further.

We also won't recurse for directories nested deeper than MAX-DEPTH.

If MAX-DEPTH is set to -1, do not use any recursion stop gap.

If the directory pointed by ‘my-repo-pins-code-root’ does not exists
yet, returns an empty list."
  (if (not (file-directory-p code-root))
      nil
    (let*
        ((remove-code-root-prefix-and-trailing-slash
          (lambda (path)
            (let ((path-without-prefix (string-remove-prefix code-root path)))
                (substring path-without-prefix 0 (1- (length path-without-prefix))))))
         (projects-absolute-path (my-repo-pins--find-git-dirs-recursively code-root max-depth))
         (projects-relative-to-code-root
          (mapcar remove-code-root-prefix-and-trailing-slash projects-absolute-path)))
      projects-relative-to-code-root)))

(defcustom my-repo-pins-open-function 'find-file
  "Function to call once the repository is located and available."
  :type 'function
  :group 'my-repo-pins-group)

(defun my-repo-pins--open (dir)
  "Open the DIR directory using the ‘my-repo-pins-code-root’ function."
  (funcall my-repo-pins-open-function dir))

;;=============
;; Internal: UI
;;=============

(defun my-repo-pins--evil-safe-binding (kbd action)
  "Bind ACTION to the KBD keyboard key.

This key binding will be bound to the current buffer. If ‘evil-mode’
is used, the key binding will be bound to the normal mode as well."
  (let ((evil-mode-enabled (member 'evil-mode minor-mode-list)))
    (if evil-mode-enabled
        (progn
          (local-set-key kbd action)
          (when (require 'evil-core nil t)
              (declare-function evil-local-set-key "ext:evil-core.el" "STATE" "KEY" "DEF" t)
              (evil-local-set-key 'normal kbd action)))
      (local-set-key kbd action))))

(defun my-repo-pins--draw-ui-buffer (forge-query-status user-query)
  "Draws the UI depending on the app state.

FORGE-QUERY-STATUS being a alist in the form of (FORGE-NAME . LOOKUP-STATUS)
where FORGE-NAME is a string representing the name of a forge,
LOOKUP-STATUS an atom that is either 'loading, 'not-found or a list
containing the lookup result.

USER-QUERY being the original user query we're trying to find a repo
to clone for.

We're going to draw these forge query status results in a buffer and
associate each of them with a key binding.

, ‘my-repo-pins--draw-forge-status’ is in charge of
drawing the forge status in the my-repo-pins buffer."
  (let* (
        (my-repo-pins-buffer (get-buffer-create "my-repo-pins-ui-buffer"))
        (my-repo-pins-window nil)
        (previous-buffer (current-buffer))
        (forge-status-with-keys (my-repo-pins--add-keys-to-forge-status forge-query-status)))
    (set-buffer my-repo-pins-buffer)
    (setq buffer-read-only nil)
    (erase-buffer)
    (insert (format "Looking up for %s in different forges:\n\n\n" user-query))
    (set-text-properties 1 (point) `(face (:foreground "orange" :weight bold)))
    (seq-map
     (lambda (e) (my-repo-pins--draw-forge-status e)) forge-status-with-keys)
    (insert "\n\nPlease select the forge we should clone the project from.\n")
    (insert "Press q to close this window.")
    (setq buffer-read-only t)
    (my-repo-pins--evil-safe-binding (kbd "q")
                                     `(lambda () (interactive)
                                          (delete-window)
                                          (kill-buffer ,my-repo-pins-buffer)))
    (set-buffer previous-buffer)
    (setq my-repo-pins-window (display-buffer my-repo-pins-buffer))
    (select-window my-repo-pins-window)))

(defun my-repo-pins--add-keys-to-forge-status (forge-query-status)
  "Add key bindings to relevant FORGE-QUERY-STATUS entries.

FORGE-QUERY-STATUS is list of alists in the form of ((FORGE-NAME .
LOOKUP-STATUS)) where LOOKUP-STATUS is either a list containing the
lookup results or the 'not-found atom when no results could be found.
This function adds a key binding alist to the LOOKUP-STATUS list when
results have been found, nothing if the repo couldn't be found.

‘my-repo-pins--find-next-available-key-binding’ is in charge of generating the
key bindings."
  (reverse
   (cdr
    (cl-reduce
     (lambda
       ;; In this fold, car of acc is the next key binding to
       ;; associate, cdr the new forge-query-status.
       (acc e)
       (let* ((status (cdr e))
              (key (car acc))
              (isFound (listp status))
              (nextKeybinding
               (if isFound (my-repo-pins--find-next-available-key-binding (car acc)) (car acc)))
              (forge-status-with-key
               (if isFound
                   `((status . ,status)
                     (key . ,key))
                 `((status . ,status)))))
         (append `(,nextKeybinding
                   (,(car e) . ,forge-status-with-key))
                 (cdr acc))))
     forge-query-status
     :initial-value '(?1 . ())))))

(defun my-repo-pins--draw-forge-status (forge-result)
  "Draws FORGE-RESULT status to the current buffer.

FORGE-STATUS being a alist in the form of (FORGE-NAME . LOOKUP-STATUS).

LOOKUP-STATUS being either in the form of ('status . 'not-found),
\('status . 'loading) or (('status . (ssh . ssh-checkout-url) (https .
https-checkout-url)) ('key . \"1\"))."
  (let*
      ((status (alist-get 'status forge-result))
       (key (alist-get 'key forge-result))
       (forge-name (car forge-result))
       (status-text (cond
              ((eq status 'loading) (format "[?] %s (loading...)" forge-name))
              ((eq status 'not-found) (format "[X] %s" forge-name))
              ((listp status) (format "[✓] %s" forge-name))
              (t (error "my-repo-pins--draw-forge-status: Invalid forge status %s" status))))
       (text (if (null key)
                 (format "%s\n" status-text)
               (format "%s [%s]\n" status-text (char-to-string key))))
       (font-color (cond
                    ((eq status 'loading) "orange")
                    ((eq status 'not-found) "red")
                    ((listp status) "green")
                    (t (error "my-repo-pins--draw-forge-status: Invalid forge status %s" status))))
       (my-repo-pins-buffer (current-buffer))
       (original-point (point)))
    (if key
        (my-repo-pins--evil-safe-binding (kbd (format "%s" (char-to-string key)))
                                         `(lambda ()
                                            (interactive)
                                            (delete-window)
                                            (kill-buffer ,my-repo-pins-buffer)
                                            (my-repo-pins--clone-from-forge-result ',forge-result))))
    (insert text)
    ;; Set color for status indicator
    (set-text-properties original-point
                         (+ original-point 4)
                         `(face (:foreground ,font-color :weight bold)))
    ;; Set color for key binding (if there's one)
    (if key
        (set-text-properties (- (point) 4) (point)
                             '(face (:foreground "orange" :weight bold))))))

(defun my-repo-pins--find-next-available-key-binding (cur-key-binding)
  "Find a key binding starting CUR-KEY-BINDING for the my-repo-pins buffer.

We're using the 1-9 numbers, then, once all the numbers are already in
use, we start allocating the a-Z letters."
  (cond ((= cur-key-binding ?9) ?a)
        ((= cur-key-binding ?z) (error "Keys exhausted, can't bind any more"))
        (t (+ cur-key-binding 1))))

(defun my-repo-pins--clone-from-forge-result (forge-result)
  "Clone a repository using the FORGE-RESULT alist.

The FORGE-RESULT alist is in the form of (status . (https .
HTTPS-CHECKOUT-URL) (ssh . SSH-CHECKOUT-URL))

We'll first try to clone the ssh url: it's more convenient for the
user auth-wise. If the ssh clone fails, we'll fallback on the HTTPS
url."
  (let*
      ((forge-result-status (alist-get 'status (cdr forge-result)))
       (ssh-url (alist-get 'ssh forge-result-status))
       (http-url (alist-get 'https forge-result-status))
       (code-root (my-repo-pins--safe-get-code-root))
       (dest-dir (concat code-root (my-repo-pins--filepath-from-clone-url http-url))))
    (if (my-repo-pins--is-clone-url-in-code-root http-url code-root)
        (my-repo-pins--open dest-dir)
      (progn
        (message "Cloning %s to %s" ssh-url dest-dir)
        (cl-flet*
            ((clone-http
              ()
              (my-repo-pins--git-clone-in-dir
               http-url
               dest-dir
               (lambda (exit-code)
                 (if (not (equal exit-code 0))
                     (error "Cannot clone %s nor %s" ssh-url http-url)
                   (progn
                     (message "Successfully cloned %s" dest-dir)
                     (my-repo-pins--open dest-dir))))))
             (clone-ssh
              ()
              (my-repo-pins--git-clone-in-dir
               ssh-url
               dest-dir
               (lambda (exit-code)
                 (if (not (equal exit-code 0))
                     (progn
                       (message "Failed to clone %s" ssh-url)
                       (message "Trying again with %s" http-url)
                       (clone-http))
                   (progn
                     (message "Successfully cloned %s" dest-dir)
                     (my-repo-pins--open dest-dir)))))))
          (clone-ssh))))))

(defun my-repo-pins--clone-from-full-url (full-url &optional callback)
  "Clone a repository from a fully-qualified FULL-URL git URL.

CALLBACK is called once the git process exited. It takes a single
exit-code parameter containing the process exit code."
  (let*
      ((code-root (my-repo-pins--safe-get-code-root))
       (dest-dir (concat code-root (my-repo-pins--filepath-from-clone-url full-url))))
    (if (my-repo-pins--is-clone-url-in-code-root full-url code-root)
        (my-repo-pins--open dest-dir)
      (my-repo-pins--git-clone-in-dir
       full-url
       dest-dir
       (lambda (exit-code)
         (if callback
             (funcall callback exit-code))
         (if (equal exit-code 0)
             (my-repo-pins--open dest-dir)
           (error "Cannot clone %s" full-url)))))))

;;=========================================
;; Internal: improving builtin autocomplete
;;=========================================

(defun my-repo-pins--completing-read-or-custom (prompt collection)
  "Behaves similarly to ‘completing-read’.

See the ‘completing-read’ documentation for more details about PROMPT
and COLLECTION.

Behaves similarly to ‘completing-read’ with REQUIRE-MATCH set to nil
except it'll return an extra element specifying whether the input was
found in COLLECTION or if the result is a custom user-provided input.

Returns either ('in-collection . READ-RESULT) or ('user-provided .
READ-RESULT)"
  (let ((read-result (completing-read prompt collection nil nil "")))
    (if (member read-result collection)
        `(in-collection . ,read-result)
      `(user-provided . ,read-result))))

;;====================================
;; Internal: Internal state management
;;====================================

(defun my-repo-pins--init-forges-state (forge-fetchers)
  "Initialize ‘my-repo-pins--forge-fetchers-state’.

We iterate through the forges set in FORGE-FETCHERS and associate
each of them with a pending status. We then return this new state
alist."
  (seq-map (lambda (e) `(,(car e) . loading)) forge-fetchers))

(defun my-repo-pins--update-forges-state (forge-name new-state user-query)
  "Update ‘my-repo-pins--forge-fetchers-state’ for FORGE-NAME with NEW-STATE.

USER-QUERY was the original query for this state update."
  (mutex-lock my-repo-pins--forge-fetchers-state-mutex)
  (setq my-repo-pins--forge-fetchers-state (assq-delete-all forge-name my-repo-pins--forge-fetchers-state))
  (setq my-repo-pins--forge-fetchers-state (cons `(,forge-name . ,new-state) my-repo-pins--forge-fetchers-state))
  (my-repo-pins--draw-ui-buffer my-repo-pins--forge-fetchers-state user-query)
  (mutex-unlock my-repo-pins--forge-fetchers-state-mutex))


(defun my-repo-pins--query-forge-fetchers (repo-query)
  "Find repo matches to the relevant forges for REPO-QUERY then query forge."
  (let* ((parsed-repo-query (my-repo-pins--parse-repo-identifier repo-query))
         (repo-query-kind (alist-get 'tag parsed-repo-query)))
    (cond
     ((equal repo-query-kind 'owner-repo)
      (seq-map
       (lambda (forge)
         (let* ((owner (alist-get 'owner parsed-repo-query))
                (repo (alist-get 'repo parsed-repo-query))
                (fetch-func (alist-get 'query-user-repo forge))
                (forge-str (car forge)))
           (apply `(,fetch-func
                    ,owner
                    ,repo
                    (lambda (result)
                      (let ((new-state
                             (if (null result) 'not-found result)))
                        (my-repo-pins--update-forges-state ,forge-str new-state ,repo-query)))))))
       my-repo-pins-forge-fetchers))
     ((equal repo-query-kind 'repo) (user-error "Can't checkout %s (for now), please specify a owner" repo-query))
     ((equal repo-query-kind 'full-url) (my-repo-pins--clone-from-full-url repo-query))
     (t (error repo-query-kind)))))

;;=====================
;; Interactive Commands
;;=====================

(defun my-repo-pins--clone-project (user-query)
  "Clone USER-QUERY in its appropriate directory in ‘my-repo-pins-code-root’."
  (setq my-repo-pins--forge-fetchers-state (my-repo-pins--init-forges-state my-repo-pins-forge-fetchers))
  (my-repo-pins--query-forge-fetchers user-query))

;;;###autoload
(defun my-repo-pins ()
  "Open a project contained in the ‘my-repo-pins-code-root’ directory.
If the project is not in the ‘my-repo-pins-code-root’ yet, check it out from the
available forge sources."
  (interactive)
  (let* ((user-query
         (my-repo-pins--completing-read-or-custom
           "Jump to project: "
           (my-repo-pins--get-code-root-projects (my-repo-pins--safe-get-code-root) my-repo-pins-max-depth))))
    (cond
     ((equal (car user-query) 'in-collection)
      (let ((selected-project-absolute-path (concat (my-repo-pins--safe-get-code-root) (cdr user-query))))
        (my-repo-pins--open selected-project-absolute-path)))
     ((equal (car user-query) 'user-provided)
      (my-repo-pins--clone-project (cdr user-query))))))


(provide 'my-repo-pins)
;;; my-repo-pins.el ends here
