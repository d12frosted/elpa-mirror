;;; vc-fossil.el --- VC backend for the fossil sofware configuraiton management system

;; Author: Venkat Iyer <venkat@comit.com>
;; Maintainer: Alfred M. Szmidt <ams@gnu.org>
;; Version: 20210928
;; Package-Version: 20210928.737
;; Package-Commit: 7815c30d739a01e1100961abb3f2b93e0ea9920f

;; vc-fossil.el free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; vc-fossil.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; For a copy of the license, please see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file contains a VC backend for the fossil version control
;; system.

;;; Todo:

;; 1) Implement the rest of the vc interface.  See the comment at the
;; beginning of vc.el. The current status is:

;; FUNCTION NAME				STATUS
;; BACKEND PROPERTIES
;; * revision-granularity			OK
;; - update-on-retrieve-tag			OK
;; STATE-QUERYING FUNCTIONS
;; * registered (file)				OK
;; * state (file)				OK
;; - dir-status-files (dir files update-function) OK
;; - dir-extra-headers (dir)			OK
;; - dir-printer (fileinfo)			??
;; - status-fileinfo-extra (file)		??
;; * working-revision (file)			OK
;; * checkout-model (files)			OK
;; - mode-line-string (file)			??
;; STATE-CHANGING FUNCTIONS
;; * create-repo ()				OK
;; * register (files &optional comment)		OK
;; - responsible-p (file)			OK
;; - receive-file (file rev)			??
;; - unregister (file)				OK
;; * checkin (files comment &optional rev)	OK
;; * find-revision (file rev buffer)		OK
;; * checkout (file &optional rev)		OK
;; * revert (file &optional contents-done)	OK
;; - merge-file (file &optional rev1 rev2)	??
;; - merge-branch ()				??
;; - merge-news (file)				??
;; - pull (prompt)				OK
;; ? push (prompt)				OK
;; - steal-lock (file &optional revision)	??
;; - modify-change-comment (files rev comment)	??
;; - mark-resolved (files)			??
;; - find-admin-dir (file)			??
;; HISTORY FUNCTIONS
;; * print-log (files buffer &optional shortlog start-revision limit) OK
;; * log-outgoing (buffer remote-location)	??
;; * log-incoming (buffer remote-location)	??
;; - log-search (buffer pattern)		??
;; - log-view-mode ()				OK
;; - show-log-entry (revision)			??
;; - comment-history (file)			??
;; - update-changelog (files)			??
;; * diff (files &optional rev1 rev2 buffer async) OK
;; - revision-completion-table (files)		??
;; - annotate-command (file buf &optional rev)	OK
;; - annotate-time ()				OK
;; - annotate-current-time ()			??
;; - annotate-extract-revision-at-line ()	OK
;; - region-history (file buffer lfrom lto)	??
;; - region-history-mode ()			??
;; - mergebase (rev1 &optional rev2)		??
;; TAG SYSTEM
;; - create-tag (dir name branchp)		OK
;; - retrieve-tag (dir name update)		OK
;; MISCELLANEOUS
;; - make-version-backups-p (file)		??
;; - root (file)				OK
;; - ignore (file &optional directory remove)	??
;; - ignore-completion-table (directory)	??
;; - find-ignore-file file			OK
;; - previous-revision (file rev)		OK
;; - next-revision (file rev)			OK
;; - log-edit-mode ()				??
;; - check-headers ()				??
;; - delete-file (file)				OK
;; - rename-file (old new)			OK
;; - find-file-hook ()				??
;; - extra-menu ()				??
;; - extra-dir-menu ()				??
;; - conflicted-files (dir)			??
;; - repository-url (file-or-dir &optional remote-name) OK

;;; Code:

(eval-when-compile
  (require 'vc))

(autoload 'vc-switches "vc")

(declare-function log-edit-extract-headers "log-edit" (headers string))

(autoload 'vc-setup-buffer "vc-dispatcher")
(declare-function vc-compilation-mode "vc-dispatcher" (backend))
(declare-function vc-exec-after "vc-dispatcher" (code))
(declare-function vc-set-async-update "vc-dispatcher" (process-buffer))

(declare-function vc-annotate-convert-time "vc-annotate" (time))

;; Internal Functions

(defun vc-fossil--call (buffer &rest args)
  (apply #'process-file "fossil" nil buffer nil args))

(defun vc-fossil--out-ok (&rest args)
  (zerop (apply #'vc-fossil--call '(t nil) args)))

(defun vc-fossil--run (&rest args)
  (catch 'bail
    (with-output-to-string
      (with-current-buffer standard-output
	(unless (apply #'vc-fossil--out-ok args)
	  (throw 'bail nil))))))

(defun vc-fossil--command (buffer okstatus file-or-list &rest flags)
  (apply #'vc-do-command (or buffer "*vc*") okstatus "fossil" file-or-list flags)
  (when (eql major-mode 'vc-dir-mode)	; Update header info.
    (revert-buffer (current-buffer))))

(defvar vc-fossil--history nil)

(defun vc-fossil--do-async-prompted-command (command &optional prompt hist-var)
  (let* ((root (vc-fossil-root default-directory))
	 (buffer (format "*vc-fossil : %s*" (expand-file-name root)))
	 (fossil-program "fossil")
	 (args '()))
    (when prompt
      (setq args (split-string
		  (read-shell-command "Run Fossil (like this): "
				      (concat fossil-program " " command)
				      (or hist-var 'vc-fossil--history))
		  " " t))
      (setq fossil-program (car args)
	    command (cadr args)
	    args (cddr args)))
    (apply 'vc-do-async-command buffer root fossil-program command args)
    (with-current-buffer buffer
      (vc-run-delayed (vc-compilation-mode 'Fossil)))
    (vc-set-async-update buffer)))

(defun vc-fossil--get-id (dir)
  (let* ((default-directory dir)
	 (info (vc-fossil--run "info"))
	 (pos (string-match "checkout: *\\([0-9a-fA-F]+\\)" info))
	 (uid (match-string 1 info)))
    (substring uid 0 10)))

(defun vc-fossil--state-code (code)
  (cond ((not code)                 'unregistered)
	((string= code "UNKNOWN")   'unregistered)
	((string= code "UNCHANGED") 'up-to-date)
	((string= code "CONFLICT")  'conflict)
	((string= code "ADDED")     'added)
	((string= code "ADD")       'needs-update)
	((string= code "EDITED")    'edited)
	((string= code "REMOVE")    'removed)
	((string= code "UPDATE")    'needs-update)
	((string= code "UPDATED_BY_MERGE") 'needs-merge)
	((string= code "EXTRA")     'unregistered)
	((string= code "MISSING")   'missing)
	((string= code "RENAMED")   'added)
	(t             nil)))

(defvar vc-fossil--file-classifications nil
  "An alist of (filename . classification) pairs.")

(defun vc-fossil--classify-all-files (dir)
  (setq vc-fossil--file-classifications nil)
  (let* ((default-directory dir)
	 (lines (split-string (vc-fossil--run "changes" "--classify" "--all" ".") "[\n\r]+" t)))
    (dolist (line lines)
      (let* ((state-and-file (split-string-and-unquote line))
	     (state (car state-and-file))
	     (file (cadr state-and-file))
	     (pair (cons file state)))
	(push pair vc-fossil--file-classifications)))))

(defun vc-fossil--propertize-header-line (name value)
  (concat (propertize name  'face 'font-lock-type-face)
	  (propertize value 'face 'font-lock-variable-name-face)))

(defun vc-fossil--remotes ()
  (let ((remotes '()))
    (dolist (l (split-string (vc-fossil--run "remote" "list") "\n" t))
      (push (split-string l) remotes))
    remotes))

;; Customization

(defgroup vc-fossil nil
  "VC Fossil backend."
  :group 'vc)

(defcustom vc-fossil-diff-switches t
  "String or list of strings specifying switches for Fossil diff under VC.
If nil, use the value of `vc-diff-switches'.  If t, use no switches."
  :type '(choice (const :tag "Unspecified" nil)
		 (const :tag "None" t)
		 (string :tag "Argument String")
		 (repeat :tag "Argument List" :value ("") string))
  :group 'vc-fossil)

(defcustom vc-fossil-extra-header-fields (list :repository :remote-url :checkout :tags)
  "A list of keywords denoting extra header fields to show in the vc-dir buffer."
  :type '(set (const :repository) (const :remote-url) (const :synchro)
	      (const :checkout) (const :comment) (const :tags))
  :group 'vc-fossil)

;; BACKEND PROPERTIES

(defun vc-fossil-revision-granularity () 'repository)

(defun vc-fossil-update-on-retrieve-tag () nil)

;; STATE-QUERYING FUNCTIONS

;;;###autoload
(defun vc-fossil-registered (file)
  (with-temp-buffer
    (let* ((str (ignore-errors
		  (vc-fossil--out-ok "finfo" "-s" (file-truename file))
		  (buffer-string))))
      (and str
	   (> (length str) 7)
	   (not (string= (substring str 0 7) "unknown"))))))

(defun vc-fossil-state (file)
  (let* ((line (vc-fossil--run "changes" "--classify" "--all" (file-truename file)))
	 (state (vc-fossil--state-code (car (split-string line)))))
    ;; ---!!! Does 'fossil update' and 'fossil changes' have different
    ;; ---!!!    semantics here?
    ;;;
    ;; If 'fossil update' says file is UNCHANGED check to see if it
    ;; has been RENAMED.
    (when (or (not state) (eql state 'up-to-date))
      (let ((line (vc-fossil--run "changes" "--classify" "--unchanged" "--renamed"
				  (file-truename file))))
	(setq state (and line (vc-fossil--state-code (car (split-string line)))))))
    state))

(defun vc-fossil-dir-status-files (dir files update-function)
  (vc-fossil--classify-all-files dir)
  (insert (apply 'vc-fossil--run "changes" "--classify" "--all"
		 (or files (list dir))))
  (let ((result '())
	(root (vc-fossil-root dir)))
    (goto-char (point-min))
    (while (not (eobp))
      (let* ((line (buffer-substring-no-properties (point) (line-end-position)))
	     (status-word (car (split-string line))))
	(if (string-match "-----" status-word)
	    (goto-char (point-max))
	  (let ((file (cadr (split-string line)))
		(state (vc-fossil--state-code status-word)))
	    ;; If 'fossil update' says file is UNCHANGED check to see
	    ;; if it has been RENAMED.
	    (when (or (not state) (eql state 'up-to-date))
	      (setq state (vc-fossil--state-code (cdr (assoc file vc-fossil--file-classifications)))))
	    (when (not (eq state 'up-to-date))
	      (push (list file state) result))))
	(forward-line)))
    ;; Now collect untracked files.
    (delete-region (point-min) (point-max))
    (insert (apply 'vc-fossil--run "extras" "--dotfiles" (list dir)))
    (goto-char (point-min))
    (while (not (eobp))
      (let ((file (buffer-substring-no-properties (point) (line-end-position))))
	(push (list file (vc-fossil--state-code nil)) result)
	(forward-line)))
    (funcall update-function result nil)))

(defun vc-fossil-dir-extra-headers (dir)
  (let ((info (vc-fossil--run "info"))
	(settings (vc-fossil--run "settings"))
	(lines nil))
    (dolist (field vc-fossil-extra-header-fields)
      (unless (null lines)
	(push "\n" lines))
      (cond ((eql field :repository)
	     (string-match "repository: *\\(.*\\)$" info)
	     (let ((repo (match-string 1 info)))
	       (push (vc-fossil--propertize-header-line "Repository : " repo) lines)))
	    ((eql field :remote-url)
	     (let ((remote-url (car (split-string (vc-fossil--run "remote-url")))))
	       (unless (string= "off" remote-url)
		 (push (vc-fossil--propertize-header-line "Remote     : " remote-url) lines))))
	    ((eql field :synchro)
	     (let* ((as-match (string-match "^autosync +.+ +\\([[:graph:]]+\\)$" settings))
		    (autosync (and as-match (match-string 1 settings)))
		    (dp-match (string-match "^dont-push +.+ +\\([[:graph:]]+\\)$" settings))
		    (dontpush (and dp-match (match-string 1 settings))))
	       (push (vc-fossil--propertize-header-line "Synchro    : "
							(concat (and autosync "autosync=") autosync
								(and dontpush " dont-push=") dontpush))
		     lines)))
	    ((eql field :checkout)
	     (let* ((posco (string-match "checkout: *\\([0-9a-fA-F]+\\) \\([-0-9: ]+ UTC\\)" info))
		    (coid (substring (match-string 1 info) 0 10))
		    (cots (format-time-string "%Y-%m-%d %H:%M:%S %Z"
					      (safe-date-to-time (match-string 2 info))))
		    (child-match (string-match "child: *\\(.*\\)$" info))
		    (leaf (if child-match "non-leaf" "leaf")))
	       (push (vc-fossil--propertize-header-line "Checkout   : "
							(concat coid " " cots
								(concat " (" leaf ")")))
		     lines)))
	    ((eql field :comment)
	     (string-match "comment: *\\(.*\\)$" info)
	     (let ((msg (match-string 1 info)))
	       (push (vc-fossil--propertize-header-line "Comment    : " msg) lines)))
	    ((eql field :tags)
	     (string-match "tags: *\\(.*\\)" info)
	     (let ((tags (match-string 1 info)))
	       (push (vc-fossil--propertize-header-line "Tags       : " tags) lines)))))
    (apply #'concat (nreverse lines))))

;; - dir-printer (fileinfo)

;; - status-fileinfo-extra (file)

(defun vc-fossil-working-revision (file)
  (let ((line (vc-fossil--run "finfo" "-s" (file-truename file))))
    (and line
	 (cadr (split-string line)))))

(defun vc-fossil-checkout-model (files) 'implicit)

;; - mode-line-string (file)

;; STATE-CHANGING FUNCTIONS

(defun vc-fossil-create-repo ()
  (vc-fossil--command nil 0 nil "new"))

(defun vc-fossil-register (files &optional rev comment)
  ;; We ignore the comment.  There's no comment on add.
  (vc-fossil--command nil 0 files "add"))

(defun vc-fossil-responsible-p (file)
  (vc-fossil-root file))

;; - receive-file (file rev)

(defun vc-fossil-unregister (file)
  (vc-fossil--command nil 0 file "rm"))

(defun vc-fossil-checkin (files comment &optional rev)
  (apply 'vc-fossil--command nil 0 files
	 (nconc (list "commit" "-m")
		(log-edit-extract-headers
		 `(("Author" . "--user-override")
		   ("Date" . "--date-override"))
		 comment)
		(vc-switches 'Fossil 'checkin))))

(defun vc-fossil-find-revision (file rev buffer)
  (apply #'vc-fossil--command buffer 0 file
	 "cat"
	 (nconc
	  (unless (zerop (length rev)) (list "-r" rev))
	  (vc-switches 'Fossil 'checkout))))

(defun vc-fossil-checkout (file &optional editable rev)
  (apply #'vc-fossil--command nil 0 file
	 "update"
	 (nconc
	  (cond
	   ((eq rev t) (list "current"))
	   ((equal rev "") (list "trunk"))
	   ((stringp rev) (list rev)))
	  (vc-switches 'Fossil 'checkout))))

(defun vc-fossil-revert (file &optional contents-done)
  (if contents-done
      t
    (vc-fossil--command nil 0 file "revert")))

;; - merge-file (file &optional rev1 rev2)

;; - merge-branch ()

;; - merge-news (file)

(defvar vc-fossil--pull-history nil)
(defvar vc-fossil--push-history nil)

(defun vc-fossil-pull (prompt)
  (interactive "P")
  (vc-fossil--do-async-prompted-command "update" prompt 'vc-fossil--pull-history))

(defun vc-fossil-push (prompt)
  (interactive "P")
  (vc-fossil--do-async-prompted-command "push" prompt 'vc-fossil-push-history))

;; - steal-lock (file &optional revision)

;; - modify-change-comment (files rev comment)

;; - mark-resolved (files)

;; - find-admin-dir (file)

;; HISTORY FUNCTIONS

(defun vc-fossil-print-log (files buffer &optional shortlog start-revision limit)
  ;; TODO: We actually already have short, start and limit, need to
  ;; add it into the code.
  (vc-setup-buffer buffer)
  (let ((inhibit-read-only t))
    (with-current-buffer buffer
      (dolist (file files)
	(apply #'vc-fossil--command buffer 0 nil "timeline"
	       (nconc
		(when start-revision (list "before" start-revision))
		(when limit (list "-n" (number-to-string limit)))
		(list "-p" (file-relative-name (expand-file-name file)))))))))

;; * log-outgoing (buffer remote-location)

;; * log-incoming (buffer remote-location)

;; - log-search (buffer pattern)

(defvar log-view-message-re)
(defvar log-view-file-re)
(defvar log-view-font-lock-keywords)
(defvar log-view-per-file-logs)

(define-derived-mode vc-fossil-log-view-mode log-view-mode "Fossil-Log-View"
  (setq word-wrap t)
  (set (make-local-variable 'wrap-prefix) "                      ")
  (set (make-local-variable 'log-view-file-re) "\\`a\\`")
  (set (make-local-variable 'log-view-per-file-logs) nil)
  (set (make-local-variable 'log-view-message-re)
       "^[0-9:]+ \\[\\([0-9a-fA-F]*\\)\\] \\(?:\\*[^*]*\\*\\)? ?\\(.*\\)")
  (set (make-local-variable 'log-view-font-lock-keywords)
       (append
	'(
	  ("^\\([0-9:]*\\) \\(\\[[[:alnum:]]*\\]\\) \\(\\(?:\\*[[:word:]]*\\*\\)?\\) ?\\(.*?\\) (user: \\([[:word:]]*\\) tags: \\(.*\\))"
	   (1 'change-log-date)
	   (2 'change-log-name)
	   (3 'highlight)
	   (4 'log-view-message)
	   (5 'change-log-name)
	   (6 'highlight))
	  ("^=== \\(.*\\) ==="
	   (1 'change-log-date))))))

;; - show-log-entry (revision)

;; - comment-history (file)

;; - update-changelog (files)

(defun vc-fossil-diff (files &optional rev1 rev2 buffer async)
  ;; TODO: Implement diff for directories.
  (let ((buf (or buffer "*vc-diff*"))
	(root (and files (expand-file-name (vc-fossil-root (car files))))))
    ;; If we diff the root directory, do not specify a file.
    (if (or (null files)
	    (and (null (cdr files))
		 (equal root (expand-file-name (car files)))))
	(setq files nil))
    (apply #'vc-fossil--command
	   buf 0 files "diff" "-i"
	   (nconc
	    (cond
	     (rev2 (list "--from" (or rev1 "current") "--to" rev2))
	     (rev1 (list "--from" rev1)))
	    (vc-switches 'Fossil 'diff)))))

;; - revision-completion-table (files)

(defconst vc-fossil-annotate-re
  "\\([[:word:]]+\\)\\s-+\\([-0-9]+\\)\\s-+[0-9]+: ")

(defun vc-fossil-annotate-command (file buffer &optional rev)
  (vc-fossil--command buffer 0 file "annotate"))

(defun vc-fossil-annotate-time ()
  ;; TODO: Currently only the date is used, not the time.
  (when (looking-at vc-fossil-annotate-re)
    (goto-char (match-end 0))
    (vc-annotate-convert-time
     (date-to-time (format "%s 00:00:00" (match-string-no-properties 2))))))

;; - annotate-current-time ()

(defun vc-fossil-annotate-extract-revision-at-line ()
  (save-excursion
    (beginning-of-line)
    (when (looking-at vc-fossil-annotate-re)
      (goto-char (match-end 0))
      (match-string-no-properties 1))))

;; - region-history (file buffer lfrom lto)

;; - region-history-mode ()

;; - mergebase (rev1 &optional rev2)

;; TAG SYSTEM

(defun vc-fossil-create-tag (file name branchp)
  (let* ((dir (if (file-directory-p file) file (file-name-directory file)))
	 (default-directory dir))
    (apply #'vc-fossil--command nil 0 nil `(,@(if branchp
						  '("branch" "new")
						'("tag" "add"))
					    ,name ,(vc-fossil--get-id dir)))))

(defun vc-fossil-retrieve-tag (dir name update)
  (let ((default-directory dir))
    (vc-fossil--command nil 0 nil "checkout" name)))

;; MISCELLANEOUS

;; - make-version-backups-p (file)

(defun vc-fossil-root (file)
  (or (vc-find-root file ".fslckout")
      (vc-find-root file "_FOSSIL_")))

;; - ignore (file &optional directory)

;; - ignore-completion-table

(defun vc-fossil-find-ignore-file (file)
  (expand-file-name ".fossil-settings/ignore-glob"
		    (vc-fossil-root file)))

(defun vc-fossil-previous-revision (file rev)
  (with-temp-buffer
    (cond
     (file
      (vc-fossil--command t 0 (file-truename file) "finfo" "-l" "-b")
      (goto-char (point-min))
      (and (re-search-forward (concat "^" (regexp-quote rev)) nil t)
	   (zerop (forward-line))
	   (looking-at "^\\([0-9a-zA-Z]+\\)")
	   (match-string 1)))
     (t
      (vc-fossil--command t 0 nil "info" rev)
      (goto-char (point-min))
      (and (re-search-forward "parent: *\\([0-9a-fA-F]+\\)" nil t)
	   (match-string 1))))))

(defun vc-fossil-next-revision (file rev)
  (with-temp-buffer
    (cond
     (file
      (vc-fossil--command t 0 (file-truename file) "finfo" "-l" "-b")
      (goto-char (point-min))
      (and (re-search-forward (concat "^" (regexp-quote rev)) nil t)
	   (zerop (forward-line -1))
	   (looking-at "^\\([0-9a-zA-Z]+\\)")
	   (match-string 1)))
     (t
      (vc-fossil--command t 0 nil "info" rev)
      (goto-char (point-min))
      (and (re-search-forward "child: *\\([0-9a-fA-F]+\\)" nil t)
	   (match-string 1))))))

;; - log-edit-mode ()

;; - check-headers ()

(defun vc-fossil-delete-file (file)
  (vc-fossil--command nil 0 (file-truename file) "rm" "--hard"))

(defun vc-fossil-rename-file (old new)
  (vc-fossil--command nil 0 (list (file-truename old) (file-truename new)) "mv" "--hard"))

;; - find-file-hook ()

;; - extra-menu ()

;; - extra-dir-menu ()

;; - conflicted-files (dir)

(defun vc-fossil-repository-url (file-or-dir &optional remote-name)
  (let ((default-directory (vc-fossil-root file-or-dir)))
    (cadr (assoc (or remote-name "default") (vc-fossil--remotes)))))

;; Useful functions for interacting with Fossil

(defun vc-fossil--url-without-authinfo (url)
  (let ((parsed (url-generic-parse-url url)))
    (setf (url-user parsed) nil)
    (setf (url-password parsed) nil)
    (url-recreate-url parsed)))

(defun vc-fossil--relative-file-name (file)
  (let ((l0 (car (split-string (vc-fossil--run "finfo" file) "\n" t))))
    (save-match-data
      (and (string-match "^History for \\(.*\\)$" l0)
	   (setq file (match-string 1 l0)))
      file)))

(defun vc-fossil-link (start end)
  "Puts the current URL to a file in the kill ring."
  (interactive "r")
  (let ((default-directory (file-name-directory (buffer-file-name (current-buffer)))))
    (unless (vc-fossil-registered (buffer-file-name))
      (error "%s: file is not registerd in vc" (buffer-file-name)))
    (let* ((repository-url (vc-fossil--url-without-authinfo
			    (vc-fossil-repository-url (buffer-file-name))))
   	   (file (vc-fossil--relative-file-name (buffer-file-name)))
	   (tag (vc-fossil-working-revision (buffer-file-name (current-buffer))))
   	   (start (line-number-at-pos (region-beginning)))
   	   (end (line-number-at-pos (region-end))))
      (if (= start end)
	  (setq link (format "%s/file?ci=%s&name=%s&ln=%s"
 			     repository-url tag file start))
	(setq link (format "%s/file?ci=%s&name=%s&ln=%s-%s"
 			   repository-url tag file start end)))
      (kill-new link)
      (message "%s" link))))

;;; This snippet enables the Fossil VC backend so it will work once
;;; this file is loaded.  By also marking it for inclusion in the
;;; autoloads file, installing packaged versions of this should work
;;; without users having to monkey with their init files.

;;;###autoload
(add-to-list 'vc-handled-backends 'Fossil t)

(provide 'vc-fossil)

;;; vc-fossil.el ends here
