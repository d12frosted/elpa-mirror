;;; magit-gerrit.el --- Magit plugin for Gerrit Code Review  -*- lexical-binding: t -*-

;; Copyright (C) 2013 Brian Fransioli
;;
;; Author: Brian Fransioli <assem@terranpro.org>
;; URL: https://github.com/emacsorphanage/magit-gerrit
;; Package-Version: 20210831.1453
;; Package-Commit: 9104713f6ea918e9faaf25f2cc182c65029db936
;; Package-Requires: ((emacs "25.1") (magit "2.90.1") (transient "0.3.0"))
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see http://www.gnu.org/licenses/.

;;; Commentary:

;; Magit plugin to make Gerrit code review easy-to-use from Emacs and
;; without the need for a browser!
;;
;; This package isn't being maintained anymore.
;;
;; Currently uses the [deprecated] gerrit ssh interface, which has
;; meant that obtaining the list of reviewers is not possible, only
;; the list of approvals (those who have already verified and/or code
;; reviewed).

;;; Usage:

;; (require 'magit-gerrit)
;; (setq-default magit-gerrit-ssh-creds "myid@gerrithost.org")
;;
;; M-x `magit-status'
;; h R  <= magit-gerrit uses the R prefix, see help
;;
;;; Workflow:

;; 1) *check out branch => changes => (ma)git commit*
;; 2) R P  <= [ger*R*it *P*ush for review]
;; 3) R A  <= [ger*R*it *A*dd reviewer] (by email address)
;; 4) *wait for verification/code reviews* [approvals shown in status]
;; 5) R S  <= [ger*R*it *S*ubmit review]

;;; Other Comments:

;; `magit-gerrit-ssh-creds' is buffer local, so if you work with
;; multiple Gerrit's, you can make this a file or directory local
;; variable for one particular project.
;;
;; If your git remote for gerrit is not the default "origin", then
;; `magit-gerrit-remote' should be adjusted accordingly (e.g. "gerrit")
;;
;; Recommended to auto add reviewers via git hooks (precommit), rather
;; than manually performing 'R A' for every review.
;;
;; `magit-gerrit' will be enabled automatically on `magit-status' if
;; the git remote repo uses the same creds found in
;; `magit-gerrit-ssh-creds'.
;;
;; Ex:  magit-gerrit-ssh-creds == br.fransioli@gerrit.org
;; $ cd ~/elisp; git remote -v => https://github.com/terranpro/magit-gerrit.git
;; ^~~ `magit-gerrit-mode' would *NOT* be enabled here
;;
;; $ cd ~/gerrit/prja; git remote -v => ssh://br.fransioli@gerrit.org/.../prja
;; ^~~ `magit-gerrit-mode' *WOULD* be enabled here

;;; Code:

(require 'magit)
(require 'transient)
(require 'json)

(eval-when-compile
  (require 'cl-lib))

(defvar-local magit-gerrit-ssh-creds nil
  "Credentials used to execute gerrit commands via ssh of the form ID@Server.")

(defvar-local magit-gerrit-remote "origin"
  "Default remote name to use for gerrit (e.g. \"origin\", \"gerrit\").")

(defvar-local magit-gerrit-push-format "refs/%s%s/%s"
  "The format string used for the branch to push to when creating a review.

By default, this is set to \"refs/%s%s/%s\" but some
installations require \"refs/%s%s%%topic=%s\".

There are 3 elements to this string formatting:

  * First: The base reference to build the code review.
    Set by `magit-gerrit-push-to'.
  * Second: Target branch that the code review will be pushed to.
  * Third: The branch currently being pushed to.")

(defvar-local magit-gerrit-push-to "publish"
  "The branch used to push a review to.
Used as the first element in `magit-gerrit-push-format'.
Typical values would be \"publish\" or \"for\".")

(defcustom magit-gerrit-popup-prefix (kbd "R")
  "Key code to open magit-gerrit popup."
  :group 'magit-gerrit
  :type 'key-sequence)

(defun magit-gerrit--command (cmd &rest args)
  (let ((gcmd (concat
	       "-x -p 29418 "
	       (or magit-gerrit-ssh-creds
		   (error "`magit-gerrit-ssh-creds' must be set!"))
	       " "
	       "gerrit "
	       cmd
	       " "
	       (mapconcat 'identity args " "))))
    ;; (message (format "Using cmd: %s" gcmd))
    gcmd))

(defun magit-gerrit--query (prj &optional status)
  (magit-gerrit--command "query"
			 "--format=JSON"
			 "--all-approvals"
			 "--comments"
			 "--current-patch-set"
			 (concat "project:" prj)
			 (concat "status:" (or status "open"))))

(defun magit-gerrit--ssh-cmd (cmd &rest args)
  (apply #'call-process
	 "ssh" nil nil nil
	 (split-string (apply #'magit-gerrit--command cmd args))))

(defun magit-gerrit--review-abandon (prj rev)
  (magit-gerrit--ssh-cmd "review" "--project" prj "--abandon" rev))

(defun magit-gerrit--review-submit (prj rev &optional msg)
  (magit-gerrit--ssh-cmd "review" "--project" prj "--submit"
			 (or msg "") rev))

(defun magit-gerrit--code-review (prj rev score &optional msg)
  (magit-gerrit--ssh-cmd "review" "--project" prj "--code-review" score
			 (or msg "") rev))

(defun magit-gerrit--review-verify (prj rev score &optional msg)
  (magit-gerrit--ssh-cmd "review" "--project" prj "--verified" score
			 (or msg "") rev))

(defun magit-gerrit-get-remote-url ()
  (magit-git-string "ls-remote" "--get-url" magit-gerrit-remote))

(defun magit-gerrit-get-project ()
  (let* ((regx (rx (zero-or-one ?:) (zero-or-more (any digit)) ?/
		   (group (not (any "/")))
		   (group (one-or-more (not (any "."))))))
	 (str (or (magit-gerrit-get-remote-url) ""))
	 (sstr (car (last (split-string str "//")))))
    (and (string-match regx sstr)
	 (concat (match-string 1 sstr)
		 (match-string 2 sstr)))))

(defun magit-gerrit-string-trunc (str maxlen)
  (if (> (length str) maxlen)
      (concat (substring str 0 maxlen)
	      "...")
    str))

(defun magit-gerrit-create-branch-force (branch parent)
  "Switch 'HEAD' to new BRANCH at revision PARENT and update working tree.
Fails if working tree or staging area contain uncommitted changes.
Succeed even if branch already exist
\('git checkout -B BRANCH REVISION')."
  (cond ((run-hook-with-args-until-success
	  'magit-create-branch-hook branch parent))
	((and branch (not (string= branch "")))
	 (magit-save-repository-buffers)
	 (magit-run-git "checkout" "-B" branch parent))))

(defun magit-gerrit-pretty-print-reviewer (name email crdone vrdone)
  (let* ((crstr (propertize (if crdone (format "%+2d" (string-to-number crdone)) "  ")
			    'face '(magit-diff-lines-heading bold)))
	 (vrstr (propertize (if vrdone (format "%+2d" (string-to-number vrdone)) "  ")
			    'face '(magit-diff-added-highlight bold)))
	 (namestr (propertize (or name "") 'face 'magit-refname))
	 (emailstr (propertize (if email (concat "(" email ")") "")
			       'face 'change-log-name)))
    (format "%-12s%s %s" (concat crstr " " vrstr) namestr emailstr)))

(defun magit-gerrit-pretty-print-review (num subj owner-name &optional draft)
  ;; window-width - two prevents long line arrow from being shown
  (let* ((wid (- (window-width) 2))
	 (numstr (propertize (format "%-10s" num) 'face 'magit-hash))
	 (nlen (length numstr))
	 (authmaxlen (/ wid 4))
	 (author (propertize (magit-gerrit-string-trunc owner-name authmaxlen)
			     'face 'magit-log-author))
	 (subjmaxlen (- wid (length author) nlen 6))
	 (subjstr (propertize (magit-gerrit-string-trunc subj subjmaxlen)
			      'face
			      (if draft
				  'magit-signature-bad
				'magit-signature-good)))
	 (authsubjpadding (make-string
			   (max 0 (- wid (+ nlen 1 (length author) (length subjstr))))
			   ? )))
    (format "%s%s%s%s\n"
	    numstr subjstr authsubjpadding author)))

(defun magit-gerrit-wash-approval (approval)
  (let* ((approver (cdr-safe (assoc 'by approval)))
	 (approvname (cdr-safe (assoc 'name approver)))
	 (approvemail (cdr-safe (assoc 'email approver)))
	 (type (cdr-safe (assoc 'type approval)))
	 (verified (string= type "Verified"))
	 (codereview (string= type "Code-Review"))
	 (score (cdr-safe (assoc 'value approval))))
    (magit-insert-section (section approval)
      (insert (magit-gerrit-pretty-print-reviewer approvname approvemail
						  (and codereview score)
						  (and verified score))
	      "\n"))))

(defun magit-gerrit-wash-approvals (approvals)
  (mapc #'magit-gerrit-wash-approval approvals))

(defun magit-gerrit-wash-review ()
  (let* ((beg (point))
	 (jobj (json-read))
	 (end (point))
	 (num (cdr-safe (assoc 'number jobj)))
	 (subj (cdr-safe (assoc 'subject jobj)))
	 (owner (cdr-safe (assoc 'owner jobj)))
	 (owner-name (cdr-safe (assoc 'name owner)))
	 (patchsets (cdr-safe (assoc 'currentPatchSet jobj)))
	 ;; compare w/t since when false the value is => :json-false
	 (isdraft (eq (cdr-safe (assoc 'isDraft patchsets)) t))
	 (approvs (cdr-safe (if (listp patchsets)
				(assoc 'approvals patchsets)
			      (assoc 'approvals (aref patchsets 0))))))
    (when (and beg end)
      (delete-region beg end))
    (when (and num subj owner-name)
      (magit-insert-section (section subj)
	(insert (propertize
		 (magit-gerrit-pretty-print-review num subj owner-name isdraft)
		 'magit-gerrit-jobj
		 jobj))
	(unless (oref (magit-current-section) hidden)
	  (magit-gerrit-wash-approvals approvs))
	(add-text-properties beg (point) (list 'magit-gerrit-jobj jobj)))
      t)))

(defun magit-gerrit-wash-reviews (&rest _args)
  (magit-wash-sequence #'magit-gerrit-wash-review))

(defun magit-gerrit-section (type title washer &rest args)
  (let ((magit-git-executable "ssh")
	(magit-git-global-arguments nil))
    (magit-insert-section ((eval type) title)
      (magit-insert-heading title)
      (magit-git-wash washer (split-string (car args)))
      (insert "\n"))))

(defun magit-gerrit-remote-update (&optional _remote)
  nil)

(defun magit-gerrit-review-at-point ()
  (get-text-property (point) 'magit-gerrit-jobj))

(defsubst magit-gerrit-process-wait ()
  (while (and magit-this-process
	      (eq (process-status magit-this-process) 'run))
    (sleep-for 0.005)))

(defun magit-gerrit-view-patchset-diff ()
  "View the Diff for a Patchset."
  (interactive)
  (let ((jobj (magit-gerrit-review-at-point)))
    (when jobj
      (let ((ref (cdr (assoc 'ref (assoc 'currentPatchSet jobj))))
	    (dir default-directory))
	(magit-git-fetch magit-gerrit-remote ref)
	(message (format "Waiting a git fetch from %s to complete..."
			 magit-gerrit-remote))
	(magit-gerrit-process-wait)
	(message (format "Generating Gerrit Patchset for refs %s dir %s" ref dir))
	(apply #'magit-diff-setup-buffer
	       "FETCH_HEAD~1..FETCH_HEAD" nil
	       (magit-diff-arguments))))))

(defun magit-gerrit-download-patchset ()
  "Download a Gerrit Review Patchset."
  (interactive)
  (let ((jobj (magit-gerrit-review-at-point)))
    (when jobj
      (let ((ref (cdr (assoc 'ref (assoc 'currentPatchSet jobj))))
	    (dir default-directory)
	    (branch (format "review/%s/%s"
			    (cdr (assoc 'username (assoc 'owner jobj)))
			    (cdr (or (assoc 'topic jobj) (assoc 'number jobj))))))
	(message (format "Waiting a git fetch from %s to complete..."
			 magit-gerrit-remote))
	(magit-gerrit-process-wait)
	(message (format "Checking out refs %s to %s in %s" ref branch dir))
	(magit-gerrit-create-branch-force branch "FETCH_HEAD")))))

(defun magit-gerrit-browse-review ()
  "Browse the Gerrit Review with a browser."
  (interactive)
  (let ((jobj (magit-gerrit-review-at-point)))
    (if jobj
	(browse-url (cdr (assoc 'url jobj))))))

(defun magit-gerrit-copy-review (with-commit-message)
  "Copy review url and commit message."
  (let ((jobj (magit-gerrit-review-at-point)))
    (if jobj
	(with-temp-buffer
	  (insert
	   (concat (cdr (assoc 'url jobj))
		   (and with-commit-message
			(concat " " (car (split-string
					  (cdr (assoc 'commitMessage jobj))
					  "\n" t))))))
	  (clipboard-kill-region (point-min) (point-max))))))

(defun magit-gerrit-copy-review-url ()
  "Copy review url only."
  (interactive)
  (magit-gerrit-copy-review nil))

(defun magit-gerrit-copy-review-url-commit-message ()
  "Copy review url with commit message."
  (interactive)
  (magit-gerrit-copy-review t))

(defun magit-insert-gerrit-reviews ()
  (magit-gerrit-section 'gerrit-reviews
			"Reviews:" 'magit-gerrit-wash-reviews
			(magit-gerrit--query (magit-gerrit-get-project))))

(defun magit-gerrit-add-reviewer ()
  (interactive)
  ;; ssh -x -p 29418 user@gerrit gerrit set-reviewers \
  ;;   --project toplvlroot/prjname --add email@addr"
  (magit-gerrit--ssh-cmd "set-reviewers"
			 "--project" (magit-gerrit-get-project)
			 "--add" (read-string "Reviewer Name/Email: ")
			 (cdr-safe (assoc 'id (magit-gerrit-review-at-point)))))

(defun magit-gerrit-verify-review (args)
  "Verify a Gerrit Review."
  (interactive (magit-gerrit-arguments))
  (let ((score (completing-read "Score: "
				'("-2" "-1" "0" "+1" "+2")
				nil t
				"+1"))
	(rev (cdr-safe (assoc
			'revision
			(cdr-safe (assoc 'currentPatchSet
					 (magit-gerrit-review-at-point))))))
	(prj (magit-gerrit-get-project)))
    (magit-gerrit--review-verify prj rev score args)
    (magit-refresh)))

(defun magit-gerrit-code-review (args)
  "Perform a Gerrit Code Review."
  (interactive (magit-gerrit-arguments))
  (let ((score (completing-read "Score: "
				'("-2" "-1" "0" "+1" "+2")
				nil t
				"+1"))
	(rev (cdr-safe (assoc
			'revision
			(cdr-safe (assoc 'currentPatchSet
					 (magit-gerrit-review-at-point))))))
	(prj (magit-gerrit-get-project)))
    (magit-gerrit--code-review prj rev score args)
    (magit-refresh)))

(defun magit-gerrit-submit-review (args)
  "Submit a Gerrit Code Review."
  ;; ssh -x -p 29418 user@gerrit gerrit review REVISION  -- --project PRJ --submit
  (interactive (magit-gerrit-arguments))
  (magit-gerrit--ssh-cmd
   "review"
   (cdr-safe (assoc 'revision
		    (cdr-safe (assoc 'currentPatchSet
				     (magit-gerrit-review-at-point)))))
   "--project"
   (magit-gerrit-get-project)
   "--submit"
   args)
  (magit-git-fetch (magit-get-current-remote t)
		   (magit-fetch-arguments)))

(defun magit-gerrit-push-review (status)
  (let* ((branch (or (magit-get-current-branch)
		     (error "Don't push a detached head.  That's gross")))
	 (commitid (or (magit-section-value-if 'commit)
		       (error "Couldn't find a commit at point")))
	 (rev (magit-rev-parse (or commitid
				   (error "Select a commit for review"))))
	 (branch-remote (and branch (magit-get "branch" branch "remote"))))
    (let* ((branch-merge (if (or (null branch-remote)
				 (string= branch-remote "."))
			     (completing-read
			      "Remote Branch: "
			      (let ((rbs (magit-list-remote-branch-names)))
				(mapcar
				 #'(lambda (rb)
				     (and (string-match
					   (rx bos
					       (one-or-more (not (any "/")))
					       "/"
					       (group (one-or-more any))
					       eos)
					   rb)
					  (concat "refs/heads/"
						  (match-string 1 rb))))
				 rbs)))
			   (and branch (magit-get "branch" branch "merge"))))
	   (branch-pub (progn
			 (string-match
			  (rx "refs/heads" (group (one-or-more any)))
			  branch-merge)
			 (format magit-gerrit-push-format
				 status
				 (match-string 1 branch-merge)
				 branch))))
      (when (or (null branch-remote)
		(string= branch-remote "."))
	(setq branch-remote magit-gerrit-remote))
      (magit-run-git-async "push" "-v" branch-remote
			   (concat rev ":" branch-pub)))))

(defun magit-gerrit-create-review ()
  (interactive)
  (magit-gerrit-push-review magit-gerrit-push-to))

(defun magit-gerrit-create-draft ()
  (interactive)
  (magit-gerrit-push-review 'drafts))

(defun magit-gerrit-publish-draft ()
  (interactive)
  (let ((prj (magit-gerrit-get-project))
	(rev (cdr-safe (assoc
			'revision
			(cdr-safe (assoc 'currentPatchSet
					 (magit-gerrit-review-at-point)))))))
    (magit-gerrit--ssh-cmd "review" "--project" prj "--publish" rev))
  (magit-refresh))

(defun magit-gerrit-delete-draft ()
  (interactive)
  (let ((prj (magit-gerrit-get-project))
	(rev (cdr-safe (assoc
			'revision
			(cdr-safe (assoc 'currentPatchSet
					 (magit-gerrit-review-at-point)))))))
    (magit-gerrit--ssh-cmd "review" "--project" prj "--delete" rev))
  (magit-refresh))

(defun magit-gerrit-abandon-review ()
  (interactive)
  (let ((prj (magit-gerrit-get-project))
	(rev (cdr-safe (assoc
			'revision
			(cdr-safe (assoc 'currentPatchSet
					 (magit-gerrit-review-at-point)))))))
    (magit-gerrit--review-abandon prj rev)
    (magit-refresh)))

(defun magit-gerrit-read-comment (&rest _args)
  (format "\'\"%s\"\'"
	  (read-from-minibuffer "Message: ")))

(transient-define-prefix magit-gerrit-popup ()
  "Popup console for magit gerrit commands."
  ["Options"
   ("-m" "Comment" "--message "
    :class transient-option
    :reader magit-gerrit-read-comment)]
  ["Actions"
   ("P" "Push Commit For Review"       magit-gerrit-create-review)
   ("W" "Push Commit For Draft Review" magit-gerrit-create-draft)
   ("p" "Publish Draft Patchset"       magit-gerrit-publish-draft)
   ("k" "Delete Draft"                 magit-gerrit-delete-draft)
   ("A" "Add Reviewer"                 magit-gerrit-add-reviewer)
   ("V" "Verify"                       magit-gerrit-verify-review)
   ("c" "Copy Review"                  magit-gerrit-copy-review-popup)
   ("C" "Code Review"                  magit-gerrit-code-review)
   ("d" "View Patchset Diff"           magit-gerrit-view-patchset-diff)
   ("D" "Download Patchset"            magit-gerrit-download-patchset)
   ("S" "Submit Review"                magit-gerrit-submit-review)
   ("B" "Abandon Review"               magit-gerrit-abandon-review)
   ("b" "Browse Review"                magit-gerrit-browse-review)])

(defun magit-gerrit-arguments ()
  (or (transient-args 'magit-gerrit-popup)
      (list "")))

(transient-append-suffix 'magit-dispatch "%"
  (list magit-gerrit-popup-prefix "Gerrit" 'magit-gerrit-popup))

(transient-define-prefix magit-gerrit-copy-review-popup
  "Popup console for copy review to clipboard."
  ["Copy review"
   ("C" "url and commit message" magit-gerrit-copy-review-url-commit-message)
   ("c" "url only"               magit-gerrit-copy-review-url)])

(defvar magit-gerrit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map magit-gerrit-popup-prefix 'magit-gerrit-popup)
    map))

(define-minor-mode magit-gerrit-mode
  "Gerrit support for Magit."
  :lighter " Gerrit" :require 'magit-topgit :keymap 'magit-gerrit-mode-map
  (unless (derived-mode-p 'magit-mode)
    (error "This mode only makes sense with magit"))
  (unless magit-gerrit-ssh-creds
    (error "You *must* set `magit-gerrit-ssh-creds' to enable magit-gerrit-mode"))
  (unless (magit-gerrit-get-remote-url)
    (error "You *must* set `magit-gerrit-remote' to a valid Gerrit remote"))
  (cond
   (magit-gerrit-mode
    (magit-add-section-hook 'magit-status-sections-hook
			    'magit-insert-gerrit-reviews
			    'magit-insert-stashes t t)
    (add-hook 'magit-remote-update-command-hook
	      'magit-gerrit-remote-update nil t)
    (add-hook 'magit-push-command-hook
	      'magit-gerrit-push nil t))
   (t
    (remove-hook 'magit-after-insert-stashes-hook
		 'magit-insert-gerrit-reviews t)
    (remove-hook 'magit-remote-update-command-hook
		 'magit-gerrit-remote-update t)
    (remove-hook 'magit-push-command-hook
		 'magit-gerrit-push t)))
  (when (called-interactively-p 'any)
    (magit-refresh)))

(defun magit-gerrit-detect-ssh-creds (remote-url)
  "Derive magit-gerrit-ssh-creds from remote-url.
Assumes remote-url is a gerrit repo if scheme is ssh
and port is the default gerrit ssh port."
  (let ((url (url-generic-parse-url remote-url)))
    (when (and (string= "ssh" (url-type url))
	       (eq 29418 (url-port url)))
      (set (make-local-variable 'magit-gerrit-ssh-creds)
	   (format "%s@%s" (url-user url) (url-host url)))
      (message "Detected magit-gerrit-ssh-creds=%s" magit-gerrit-ssh-creds))))

(defun magit-gerrit-check-enable ()
  (let ((remote-url (magit-gerrit-get-remote-url)))
    (when (and remote-url
	       (or magit-gerrit-ssh-creds
		   (magit-gerrit-detect-ssh-creds remote-url))
	       (string-match magit-gerrit-ssh-creds remote-url))
      ;; update keymap with prefix incase it has changed
      (define-key magit-gerrit-mode-map magit-gerrit-popup-prefix 'magit-gerrit-popup)
      (magit-gerrit-mode t))))

;; Hack in dir-local variables that might be set for magit gerrit
(add-hook 'magit-status-mode-hook #'hack-dir-local-variables-non-file-buffer t)

;; Try to auto enable magit-gerrit in the magit-status buffer
(add-hook 'magit-status-mode-hook #'magit-gerrit-check-enable t)
(add-hook 'magit-log-mode-hook #'magit-gerrit-check-enable t)

;;; _
(provide 'magit-gerrit)
;; Local Variables:
;; indent-tabs-mode: t
;; End:
;;; magit-gerrit.el ends here
