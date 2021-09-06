;;; git-identity.el --- Identity management for (ma)git -*- lexical-binding: t -*-

;; Copyright (C) 2019-2021 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.2.0
;; Package-Version: 20210905.1208
;; Package-Commit: e2620767694d8cd2860b632c47fbe92e20a9ef14
;; Package-Requires: ((emacs "25.1") (dash "2.10") (hydra "0.14") (f "0.20"))
;; Keywords: git vc convenience
;; URL: https://github.com/akirak/git-identity.el

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This Emacs package lets you manage local Git identities, i.e.
;; user.name and user.email options in .git/config, inside
;; Emacs.  It can be useful if you satisfy all of the following
;; conditions:

;; - You have multiple Git identities on the same machine(s).
;; 
;; - You use Emacs.
;; 
;; - You almost always use magit for Git operations on your
;;   machine(s).

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'f)
(require 'dash)
(require 'hydra)

(declare-function magit-commit "ext:magit-commit")

(defgroup git-identity nil
  "Identity management for Git."
  :group 'vc)

;;;; Custom vars

;;;###autoload
(defcustom git-identity-git-executable "git"
  "Executable file of Git."
  :group 'git-identity
  :type 'string)

;;;###autoload
(defcustom git-identity-default-username
  (when (and (stringp user-full-name)
             (not (string-empty-p user-full-name)))
    user-full-name)
  "Default full name of the user set in Git repositories."
  :group 'git-identity
  :type 'string)

;;;###autoload
(defcustom git-identity-list nil
  "List of plists of Git identities."
  :group 'git-identity
  :type '(alist :tag "Identity setting"
                :key-type (string :tag "E-mail address (user.email)")
                :value-type (plist :tag "Options"
                                   :options
                                   (((const :tag "Full name" :name)
                                     string)
                                    ((const :tag "Host names" :domains)
                                     (repeat string))
                                    ((const :tag "Organizations" :organizations)
                                     (repeat string))
                                    ((const :tag "Excluded organizations" :exclude-organizations)
                                     (repeat string))
                                    ((const :tag "Directories" :dirs)
                                     (repeat string))))))

(defcustom git-identity-verify t
  "When non-nil, check if the identity is consistent.

This check is run if the repository doesn't have a local
identity.
If the repository is expected to have a certain
identity according to the domain name or the local directory (see
`git-identity-list'), and the identity is different from the
global setting, `git-identity-magit-mode' asks if you want to
add a local identity setting to the repository.
This ensures that your identity policies defined in
`git-identity-list' are applied properly when you have a global
identity setting."
  :group 'git-identity
  :type 'boolean)

;;;; Identity operations
(defun git-identity-username (identity)
  "Extract the user name in IDENTITY or return the default."
  (or (plist-get (cdr identity) :name)
      (git-identity--default-username)))

(defun git-identity-email (identity)
  "Extract the email in IDENTITY."
  (car identity))

(defun git-identity--default-username ()
  "Retrieve the default user name."
  (or git-identity-default-username
      (customize-set-variable
       'git-identity-default-username
       (read-string "Enter your full name used as the default: "
                    nil nil
                    (when (and (stringp user-full-name)
                               (not (string-empty-p user-full-name)))
                      user-full-name)))))

;;;; Guessing identity for the current repository

(cl-defun git-identity-guess-identity (&key (url (git-identity--some-origin-url))
                                            (directory default-directory)
                                            (verbose t))
  "Pick an identity which seems suitable for the current repo.

It returns an item of `git-identity-list' if there is a matching
entity, or nil.

You can specify URL and DIRECTORY explicitly. This is intended
for testing.

If VERBOSE is non-nil, log the reason for picking an identity to
Messages buffer."
  (pcase (or (when url
               (git-identity--match-identity-on-url url))
             (when directory
               (git-identity--match-identity-on-directory directory))
             (when url
               (git-identity--match-identity-on-url url :fallback t)))
    (`(domain ,domain ,ent)
     (when verbose
       (message "Chosen an identity based on domain %s" domain))
     ent)
    (`(ancestor ,ancestor ,ent)
     (when verbose
       (message "Chosen an identity based on an ancestor directory %s" ancestor))
     ent)))

(defun git-identity--some-origin-url ()
  "Return a URL of origin, if any.

This function returns a URL configured as origin.

If there is \"pushurl\" of the remote, it takes precedence,
because it IS the URL the user uses to push his/her changes."
  (or (git-identity--git-config-get "remote.origin.pushurl")
      (git-identity--git-config-get "remote.origin.url")))

(cl-defun git-identity--match-identity-on-url (url &key fallback)
  "Return the matching information of an IDENTITY against URL.

This function returns '(domain DOMAIN IDENTITY) where DOMAIN is a
string and IDENTITY is an item of `git-identity-list'.

When FALLBACK is non-nil and there are multiple identities
matching the url, it tries to pick one without organizations."
  (let ((domain (git-identity-git-url-host url))
        (remote-dirs (-some--> (git-identity-git-url-directory url)
                       (split-string it "/")
                       (-map #'downcase it))))
    (when-let (identity
               (cl-flet
                   ((match-orgs (organizations)
                                (cl-intersection remote-dirs
                                                 (-map #'downcase organizations)
                                                 :test #'string-equal)))
                 (pcase (->> git-identity-list
                             (-filter (pcase-lambda (`(_ . ,plist))
                                        (let ((domains (plist-get plist :domains))
                                              (excluded-orgs (plist-get plist :exclude-organizations)))
                                          (and domains
                                               ;; The domain should match one of the domains.
                                               (string-match-p (rx-to-string `(and (or bos ".")
                                                                                   (or ,@domains)
                                                                                   eos))
                                                               domain)
                                               ;; The directory should never match any of the blacklist.
                                               (not (match-orgs excluded-orgs)))))))
                   ('() nil)
                   ;; If there is only one matching identity, use it
                   (`(,identity)
                    ;;  unless it has an organization
                    ;; (unless (plist-get (cdr identity) :organizations)
                    ;;   identity)
                    identity)
                   ;; If there are multiple matches, try to pick one smartly
                   (matches
                    (if-let (identity (or (-find (lambda (x)
                                                   ;; Prefer one that matches one of the organizations
                                                   (match-orgs (plist-get (cdr x) :organizations)))
                                                 matches)
                                          (when fallback
                                            (-find (lambda (x)
                                                     ;; Prefer one without organizations
                                                     ;; (only in fallback mode)
                                                     (not (plist-get (cdr x) :organizations)))
                                                   matches))))
                        identity
                      (message "There are multiple matches matching the domain %s" domain)
                      (car matches))))))
      (list 'domain domain identity))))

(defun git-identity--match-identity-on-directory (directory)
  "Return the matching information of an IDENTITY against DIRECTORY.

This function returns '(domain ANCESTOR IDENTITY) where ANCESTOR
is the matching ancestor directory and IDENTITY is an item of
`git-identity-list'."
  (cl-some (lambda (ent)
             (when-let (ancestor (git-identity--inside-dirs-p
                                  directory
                                  (plist-get (cdr ent) :dirs)))
               (list 'ancestor ancestor ent)))
           git-identity-list))

(defun git-identity-ancestor-directories-from-url (url)
  "Return a list of possible ancestors matching a Git URL.

This function returns the :dirs value of an identity matching the
url. This can be used, for example, to determine possible values
of an ancestor directory into which you clone a repository."
  (when-let (identity (git-identity-guess-identity
                       :url url :directory nil :verbose nil))
    (plist-get (cdr identity) :dirs)))

(eval-and-compile
  (defconst git-identity--xalpha
    (let* ((safe "-$=_@.&+")
           (extra "!*(),~")
           ;; According to the specification of URIs, there can be URLS that
           ;; contain double/single quotes.
           ;; 
           ;; I think it is rare in Git URLs, so I won't support such patterns.
           ;;
           ;; (extra "!*\"'(),")
           (escape '(and "%" (char hex) (char hex))))
      `(or ,escape (char alpha digit ,safe ,extra))))

  (defconst git-identity--scp-user-pattern
    '(+ (any "-_." alnum)))

  (defconst git-identity--host-pattern
    (let* ((xalpha git-identity--xalpha)
           (ialpha `(and (char alpha) (* ,xalpha)))
           (hostname `(and ,ialpha (* (and "." ,ialpha))))
           (hostnumber '(and (+ (char digit))
                             (repeat 3 (and "." (+ (char digit)))))))
      `(or ,hostname ,hostnumber)))

  (defconst git-identity--repo-url-pattern
    (rx bol
        ;; Allow URLs of Git repositories with git-remote-hg backend:
        ;; <https://github.com/felipec/git-remote-hg>
        (? "hg::")
        (or (and (?  (eval git-identity--scp-user-pattern) "@")
                 (group (eval git-identity--host-pattern))
                 ":" (? "~") (? "/"))
            (and (or (and (or "http" "ftp") (?  "s"))
                     "ssh"
                     "git")
                 "://"
                 (?  (eval git-identity--scp-user-pattern) "@")
                 (group (eval git-identity--host-pattern))
                 (?  ":" (+ (char digit)))
                 "/"))
        (? (group (* (and (+ (eval git-identity--xalpha)) "/"))
                  (+ (eval git-identity--xalpha)))
           "/")
        (group (+ (eval git-identity--xalpha)))
        (?  ".git")
        (?  "/")
        eol)))

(defun git-identity-git-url-host (url)
  "Extract the host from the URL of a Git repository."
  (save-match-data
    (if (string-match git-identity--repo-url-pattern url)
        (or (match-string 1 url)
            (match-string 2 url))
      (error "Failed to match URL: %s" url))))

(defun git-identity-git-url-directory (url)
  "Extract all but last path components of a Git repository URL."
  (save-match-data
    (if (string-match git-identity--repo-url-pattern url)
        (match-string 3 url)
      (error "Failed to match URL: %s" url))))

(defun git-identity--inside-dirs-p (target maybe-ancestors)
  "Return non-nil if a directory is a descendant of directories.

This function returns non-nil if the target is a descendant of
one of the directories in the list.

TARGET must be the root directory of a repository.

MAYBE-ANCESTORS is a list of directories of an identity in
`git-identity-list'."
  (let ((abs-target (expand-file-name target)))
    (--some (f-ancestor-of-p (expand-file-name it) abs-target)
            maybe-ancestors)))

;;;; Querying and setting an identity in a repository

;;;###autoload
(defun git-identity-complete (prompt)
  "Display PROMPT and select an identity from `git-identity-list'."
  (let ((input (completing-read prompt git-identity-list
                                nil nil nil nil
                                (car
                                 (git-identity-guess-identity)))))
    (or (assoc input git-identity-list)
        (if (git-identity--validate-mail-address input)
            (let* ((name (read-string "Name: "))
                   (newent (list input :name name)))
              (customize-set-variable git-identity-list
                                      (cons newent git-identity-list)))
          (user-error "Not a valid mail address: %s" input)))))

(defun git-identity--validate-mail-address (_input)
  "Return non-nil if _INPUT is a valid e-mail address."
  ;; TODO: Really validate the input
  t)

;;;###autoload
(defun git-identity-set-identity (&optional prompt)
  "Set the identity for the repository at the working directory.

This function lets the user choose an identity for the current
repository using `git-identity-complete' function and sets the
user name and the email address in the local configuration of the
Git repository.

Optionally, you can set PROMPT for the identity.
If it is omitted, the default prompt is used."
  (interactive)
  (let ((root (git-identity--find-repo)))
    (unless root
      (user-error "Not in a Git repository"))
    (let* ((default-directory root)
           (identity (git-identity-complete
                      (or prompt
                          (format "Select an identity in %s: " root)))))
      (git-identity--set-identity identity))))

(defun git-identity--has-identity-p ()
  "Return non-nil If the current repository has an identity."
  (and (git-identity--git-config-get "user.name" "--local")
       (git-identity--git-config-get "user.email" "--local")))

(defun git-identity--find-repo (&optional startdir)
  "Find a Git working directory which is STARTDIR or its ancestor."
  (let ((startdir (or startdir default-directory)))
    (if (file-directory-p ".git")
        startdir
      (locate-dominating-file startdir ".git"))))

(defun git-identity--set-identity (identity &optional noconfirm)
  "Set the identity in the current repo.

IDENTITY is an identity.

When NOCONFIRM is non-nil, confirmation is skipped."
  (funcall (if noconfirm
               #'git-identity--git-config-set-noconfirm
             #'git-identity--git-config-set)
           "user.name" (git-identity-username identity)
           "user.email" (git-identity-email identity)))

;;;; Hydra

(defhydra git-identity-hydra ()
  "
Git identity in %s(git-identity--find-repo)
=======================================================
User name: %(git-identity--git-config-get \"user.name\")
E-mail: %s(git-identity--git-config-get \"user.email\")
-------------------------------------------------------
"
  ("s" (progn
         (git-identity-set-identity)
         (hydra-keyboard-quit))
   "Set an identity")
  ("C" (customize-variable 'git-identity-list)
   "Configure your identities"))

;;;###autoload (autoload 'git-identity-info "git-identity")
(defun git-identity-info ()
  "Display the identity information of the current repository."
  (interactive)
  (git-identity--block-if-not-in-repo #'git-identity-hydra/body))

(defun git-identity--block-if-not-in-repo (orig &rest args)
  "Prevent running ORIG function with ARGS if not in a Git repo."
  (if (git-identity--find-repo)
      (apply orig args)
    (user-error "Not inside a Git repo")))

;;;; Mode definition
;;;###autoload
(defun git-identity-ensure ()
  "Ensure that the current repository has an identity."
  (let ((local-email (git-identity--git-config-get "user.email" "--local"))
        (local-name (git-identity--git-config-get "user.name" "--local"))
        (global-email (git-identity--git-config-get "user.email" "--global"))
        (global-name (git-identity--git-config-get "user.name" "--global"))
        (expected-identity (git-identity-guess-identity)))
    (cond
     ;; No identity is configured yet, but there is an expected identity.
     ((and (or local-email global-email)
           (string-equal (or local-email global-email)
                         (git-identity-email expected-identity))
           (string-equal (or local-name global-name)
                         (git-identity-username expected-identity))))
     ((not (git-identity--has-identity-p))
      (if (and expected-identity
               (yes-or-no-p
                (format "Set the identity in %s to \"%s\" <%s>? "
                        (git-identity--find-repo)
                        (git-identity-username expected-identity)
                        (git-identity-email expected-identity))))
          (git-identity--set-identity expected-identity 'noconfirm)
        (git-identity-set-identity "A proper identity is not set. Select one: ")))
     ;; There is no local setting, and the global setting is contradictory
     ;; with the expectation. Ask if you want to apply the local setting.
     ((and git-identity-verify
           (not local-email)
           (not (equal (git-identity-email expected-identity)
                       global-email))
           (yes-or-no-p
            (format "This repository (%s) is supposed to have an identity of\n\
\"%s\", but \"%s\" is about to be used \n\
because of a global setting.\n\
Apply the expected identity \"%s\" <%s>\n\
to this repository? "
                    (git-identity--find-repo)
                    (git-identity-email expected-identity)
                    global-email
                    (git-identity-username expected-identity)
                    (git-identity-email expected-identity))))
      (git-identity--set-identity expected-identity 'noconfirm)))))


;;;###autoload
(define-minor-mode git-identity-magit-mode
  "Global minor mode for running Git identity checks in Magit.

This mode enables the following features:

- Add a hook to `magit-commit' to ensure that you have a
  global/local identity configured in the repository."
  :global t
  (cond
   ;; Activate the mode
   (git-identity-magit-mode
    (advice-add #'magit-commit :before #'git-identity-ensure))
   ;; Deactivate the mode
   (t
    (advice-remove #'magit-commit #'git-identity-ensure))))

;;;; Git utilities
(defun git-identity--git-config-set (&rest pairs)
  "Set a PAIRS of Git options."
  (unless (yes-or-no-p (format "Are you sure you want to set the following Git options in %s?\n\n%s"
                               (git-identity--find-repo)
                               (mapconcat (pcase-lambda (`(,key ,value))
                                            (format "%s=%s" key value))
                                          (-partition 2 pairs)
                                          "\n")))
    (user-error "Aborted"))
  (apply #'git-identity--git-config-set-noconfirm pairs))

(defun git-identity--git-config-set-noconfirm (&rest pairs)
  "Set a PAIRS of Git options without confirmation."
  (cl-loop for (key value . _) on pairs by #'cddr
           do (git-identity--run-git "config" "--local" key value)))

(defun git-identity--run-git (&rest args)
  "Run Git with ARGS."
  (apply #'process-file git-identity-git-executable nil nil nil args))

(defun git-identity--git-config-get (key &optional scope)
  "Get the value of a Git option.

KEY is the name of the option, and optional SCOPE is a string passed
as an argument to Git command to specify the scope, which is either
\"--global\" or \"--local\"."
  (with-temp-buffer
    (when (= 0 (apply #'process-file git-identity-git-executable nil t nil
                      (delq nil `("config" "--get" ,scope ,key))))
      (string-trim-right (buffer-string)))))

(provide 'git-identity)
;;; git-identity.el ends here
