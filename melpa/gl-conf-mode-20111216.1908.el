;; gitolite-conf-mode.el --- major-mode for editing gitolite config files
;; Package-Version: 20111216.1908
;; Package-Commit: 1a53e548277eb9c669bbeda4bee9be32be7a82ec
;;
;; Provides navigation utilities, syntax highlighting and indentation for
;; gitolite configuration files (gitolite.conf)
;;
;; Add this code to your .emacs file to use the mode (and automatically
;; open gitolite.conf files in this mode)
;;
;; (setq load-path (cons (expand-file-name "/directory/path/to/gitolite-conf-mode.el/") load-path))
;; (require 'gl-conf-mode)
;; (add-to-list 'auto-mode-alist '("gitolite\\.conf\\'" . gl-conf-mode))
;;
;; If the file you want to edit is not named gitolite.conf, use
;; M-x gl-conf-mode, after opening the file
;;
;; Automatic indentation for this mode is disabled by default.
;; If you want to enable it, go to Customization menu in emacs,
;; then "Files", "Gitolite Config Files", and select the appropiate option.
;;
;; The interesting things you can do are:
;; - move to next repository definition: C-c C-n
;; - move to previous repository definition: C-c C-p
;; - go to the include file on the line where the cursor is: C-c C-v
;; - open a navigation window with all the repositories (hyperlink enabled): C-c C-l
;; - mark the current repository and body: C-c C-m
;; - open a navigation window with all the defined groups (hyperlink enabled): C-c C-g
;; - offer context sentitive help linking to the original web documentation: C-c C-h
;;
;; For the context sensitive help it can detect different positions, and will offer
;; help on that topic:
;;    - repo line
;;    - include line 
;;    - permissions (R/RW/RWC/...)
;;    - refexes (branches, ...)
;;    - user or group permissions
;;    - groups
;;    - anything else (offer generic gitolite.conf help)

;; The help uses the main gitolite web documentation, linking directly into it 
;; with a browser.
;; If the emacs w3m module is available in the system, it will be used to open 
;; the help inside emacs, otherwise, the emacs configured external browser will 
;; be launched (emacs variable "browse-url-browser-function")
;;
;;
;; Please note, that while it is not required by the license, I would
;; sincerely appreciate if you sent me enhancements / bugfixes you make
;; to integrate them in the master repo and make those changes accessible
;; to more people
;;
;; Now the MIT license block (this enables you to use this code in a
;; very liberal manner)
;;
;;
;; Copyright (c) 2011 Luis Lloret
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
;; OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;; OTHER DEALINGS IN THE SOFTWARE.

(defconst gl-conf-regex-repo "^[ \t]*repo[ \t]+")
(defconst gl-conf-regex-include "^[ \t]*include[ \t]+\"\\(.*\\)\"")

;;
;; Indentation logic
;;
(defun gl-conf-indent ()
  "Indent current line as a gitolite configuration file."
  (interactive)
  (when gl-conf-auto-indent-enable
	(if (bobp)
		(gl-conf-indent-line-to 0)
	  (let (cur-indent)
		(save-excursion
		  (beginning-of-line)
		  (let ((point-start (point))
				token)

			;; Search backwards (if there is a repo definition, we indent, otherwise, we don't)
			(if (re-search-backward gl-conf-regex-repo (point-min) t)
				(setq cur-indent tab-width) (setq cur-indent 0))

			(goto-char point-start)

			;; Set indentation to zero if this is a repo block
			(if (looking-at gl-conf-regex-repo)
				(setq cur-indent 0))))

		(gl-conf-indent-line-to cur-indent))))
  (unless gl-conf-auto-indent-enable
	(insert-tab))
  )

(defun gl-conf-point-in-indendation ()
  (string-match "^[ \\t]*$" (buffer-substring (point-at-bol) (point))))

(defun gl-conf-indent-line-to (column)
  "Indent the current line to COLUMN."
  (if (gl-conf-point-in-indendation)
      (indent-line-to column)
    (save-excursion (indent-line-to column))))



(defun occur-clean ()
  "Format the initial line so it does not show the regex and number of matches, but only the buffer name."
  (interactive)
  ;; Get the *Occur* buffer and clean the status headers so they are not so distracting
  (if (get-buffer "*Occur*")
      (save-excursion
		(set-buffer (get-buffer "*Occur*"))
		(goto-char (point-min))
		(toggle-read-only 0)
		(while (re-search-forward ".*in \\(buffer.*\\)"
								  (point-max)
								  t)
		  (replace-match (match-string 1))
		  (forward-line 1)))
    (message "There is no buffer named \"*Occur*\"."))
  )


(defun gl-conf-find-next-repo ()
  "Moves the cursor to the next repo definition in the current file. Returns t if next repo, nil otherwise."
  (interactive)
  (push-mark)
  (let ((cur-point (point)))
	(end-of-line nil)
	(if (re-search-forward gl-conf-regex-repo nil t)
		(progn (beginning-of-line nil) t)
	  (message "No more repos")
	  (goto-char cur-point)
	  nil))
  )

(defun gl-conf-find-prev-repo ()
  "Moves the cursor to the previous repo definition on the current file. Returns t if previous repo, nil otherwise."
  (interactive)
  (push-mark)
  (let ((cur-point (point)))
	(if (re-search-backward gl-conf-regex-repo nil t)
		t
      (message "No previous repo")
	  (goto-char cur-point)
	  nil))
  )


;; This function opens all the include files referenced in the current buffer
(defun gl-conf-visit-all-includes ()
  "Visits all the include files referenced in this file. It will follow wildcard filenames."
  (interactive)
  (save-excursion
    ;; scan the file for include directives
    (beginning-of-buffer)
    (while (re-search-forward gl-conf-regex-include (point-max) t)
      (find-file-noselect (match-string 1) t nil t)))
  )


(defun gl-conf-visit-include ()
  "Visit the include file that is on the current line. It follows wildcards. Opens the include(s) in gl-conf major mode."
  (interactive)
  (let (curpoint (point)
				 buffers)
    (beginning-of-line nil)
    (if (not (re-search-forward gl-conf-regex-include (point-at-eol) t))
		(message "Not a include line")
	  (setq buffers (find-file (match-string 1) t))
	  (if (listp buffers)
		  (dolist (buf buffers)
			(switch-to-buffer buf)
			(gl-conf-mode))
		(gl-conf-mode))))
  )

;; conditional predicate that tells whether a buffer name starts with a *
(defun buffer-starts-with-star (buf)
  (not (string-match "^*" (buffer-name buf)))
  )

;; returns a buffer list without the buffers that start with *
(defun filter-star-buffers (lst)
  (delq nil
		(mapcar (lambda (x) (and (funcall 'buffer-starts-with-star x) x)) lst))
  )

(defun gl-conf-list-common (regex)
  (interactive)
  (save-excursion
    ;; open the included files
    (gl-conf-visit-all-includes)
	(let ((buflist (buffer-list)))
	  ;; Before calling multi-occur, filter out special buffers starting with *
	  ;; If multi-occur is not found fallback to occur
	(if (fboundp 'multi-occur)
		(multi-occur (filter-star-buffers buflist) regex)
	  (occur regex)))
	;; Clean the navigation buffer that occur created
    (occur-clean)
    )
  )


(defun gl-conf-list-repos ()
  "Opens another window with a list of the repos that were found. It supports hyperlinking, so hitting RET on there will
take you to the occurrence.

In recent emacs versions, it will use 'multi-occur', so it navigates through the includes to find references in them as well;
Otherwise it will use 'occur', which searches only in the current file."
  (interactive)
  (gl-conf-list-common "^[ \t]*repo[ \t]+.*")
  )


(defun gl-conf-list-groups ()
  "Opens another window with a list of the group definitions that were found. It supports hyperlinking, so hitting RET on there will
take you to the occurrence.

In recent emacs versions, it will use 'multi-occur', so it navigates through the includes to find references in them as well;
Otherwise it will use 'occur', which searches only in the current file."
  (interactive)
  (gl-conf-list-common "^[ \t]*@[A-Za-z0-9][A-Za-z0-9-_.]+")
  )

(defun gl-conf-mark-repo ()
  "Mark (select) the repo where the cursor is."
  (interactive)
  (let ((cur-point (point)))
	;; go to previous repo definition line, which is the one that contains the cursor and mark the position
	(beginning-of-line nil)
	(when (or (looking-at gl-conf-regex-repo) (gl-conf-find-prev-repo))
		  (set-mark (point))
		  ;; Now look for the next repo or end of buffer
		  (if (not (gl-conf-find-next-repo))
			(goto-char (point-max)))
		  ;; and move back while the line is empty
		  (if (not (eobp))
			  (forward-line -1))
		  (while (looking-at "^$")
			(forward-line -1))
		  ;; and then go to the end of line to select it
		  (end-of-line)))
)

(defun open-url (url)
  (interactive)
  (let ((cur-buffer (get-buffer (buffer-name))))
	(if (fboundp 'w3m-goto-url)
		(progn
		  (when (one-window-p t)
			(split-window)
			(set-window-buffer nil cur-buffer))
		  (w3m-goto-url url))

	  (browse-url url)))

  )

(defun gl-conf-context-help ()
  "Offer context-sensitive help. Currently it needs w3m emacs installed. It would be nice if it could fall back to another mechanism, if this is not available"
  (interactive)
  ;; we want to make this section case-sensitive
  (setq old-case-fold-search case-fold-search)
  (setq case-fold-search nil)
  (setq cur-point (point)) ;; make a let
  (save-excursion
	;; are we in a group?
	(if (and (word-at-point) (string-match "^@" (word-at-point)))
		(progn (open-url "http://sitaramc.github.com/gitolite/bac.html#groups")
			   (message "Opened help for group definition"))
	  (beginning-of-line)

	  ;; are we on the right side of an assignment with a permission at the beginning (this means that we are in the users / groups part)?
	  (cond
	   ((re-search-forward "^[ \t]*\\(-\\|R\\|RW\\+?C?D?\\)[ \t]*=" (+ cur-point 1) t)
		(open-url "http://sitaramc.github.com/gitolite/bac.html")
		(message "Opened help for user / group assignment"))

	   ;; are we on a refex or right after it? (if there is a permission before and we are looking at some word)
	   ((re-search-forward "^[ \t]*\\(-\\|R\\|RW\\+?C?D?\\)[ \t]+\\w+" (+ cur-point 1)  t)
		(open-url "http://sitaramc.github.com/gitolite/bac.html#refex")
		(message "Opened help for refex definition"))

		  ;; are we in a permission code or right after it?
	   ((re-search-forward "^[ \t]*\\(-\\|R\\|RW\\+?C?D?\\)" (+ cur-point 1) t)
		(open-url "http://sitaramc.github.com/gitolite/progit.html#progit_article_Config_File_and_Access_Control_Rules__")
		(message "Opened help for permission values"))

	   ;; look for other things...
	   ;; are we in a repo line?
	   ((looking-at "[ \t]*repo" )
		(open-url "http://sitaramc.github.com/gitolite/pictures.html#1000_words_adding_repos_to_gitolite_")
		(message "Opened help for repo"))

	   ;; are we in an include line?
	   ((looking-at "[ \t]*include")
		(open-url "http://sitaramc.github.com/gitolite/syntax.html#gitolite_conf_include_files_")
		(message "Opened help for includes"))
		 ;; not found anything? Open generic help
	   (t
		(open-url "http://sitaramc.github.com/gitolite/conf.html#confrecap")
		(message "Not in any known context. Opened general help for gitolite.conf")))))

  (setq case-fold-search old-case-fold-search)
  )



;; Definition of constants for the font-lock functionality
(defconst gl-conf-font-lock-buffer
  (list '("^[ \t]*\\(repo[ \t]+[A-Za-z0-9][A-Za-z0-9-/_.]*\\)[ \t\n]" 1 font-lock-keyword-face) ;; repository definition
		'("^[ \t]*\\(include[ \t]+\\)" 1 font-lock-keyword-face) ;; include definition
		'("^[ \t]*\\(-\\|R\\|RW\\+?C?D?\\)[ \t].*=" 1 font-lock-type-face) ;; permissions
		'("^[ \t]*\\(config\\).*=" 1 font-lock-reference-face) ;; config
		'("^[ \t]*\\(config.*\\)" 1 font-lock-warning-face) ;; config partial definition (warning)
		'("^[ \t]*\\(@[A-Za-z0-9][A-Za-z0-9-_.]+\\)[ \t]*=" 1 font-lock-variable-name-face) ;; group definition
		'("^[ \t]*\\(@[A-Za-z0-9][A-Za-z0-9-_.]+.*\\)" 1 font-lock-warning-face) ;; group wrong definition (warning)
		'("[= \t][ \t]*\\(@[A-Za-z0-9][A-Za-z0-9-_.]+\\)" 1 font-lock-variable-name-face) ;; group usage
		'("^[ \t]*\\(?:-\\|R\\|RW\\+?C?D?\\)[ \t]+\\(\\(?:\\w\\|/\\|\\[\\|\\]\\|-\\)+\\)[ \t]*=" 1 font-lock-type-face)) ;; refexes

  "gl-conf mode syntax highlighting."
  )

;;
;; Syntax table
;;
(defvar gl-conf-mode-syntax-table nil "Syntax table for gl-conf-mode.")
(setq gl-conf-mode-syntax-table nil)

;;
;; User hook entry point.
;;
(defvar gl-conf-mode-hook nil)

;;
;; Customization to enable or disable automatic indentation
;;
(defgroup gl-conf nil "Gitolite configuration editing." :tag "Gitolite config files" :prefix "gl-conf" :group 'files)
(defcustom gl-conf-auto-indent-enable nil "Enable automatic indentation for gl-conf mode." :type 'boolean :group 'gl-conf)

;;
;; gl-conf mode init function.
;;
(defun gl-conf-mode ()
  "Major mode for editing gitolite config files.
Provides basic syntax highlighting (including detecting some malformed constructs) and some navigation functions
Commands:
key          binding                       description
---          -------                       -----------
\\[gl-conf-find-next-repo]      gl-conf-find-next-repo        move to next repository definition.
\\[gl-conf-find-prev-repo]      gl-conf-find-prev-repo        move to previous repository definition.
\\[gl-conf-visit-include]      gl-conf-visit-include         go to the include file on the line where the cursor is.
\\[gl-conf-list-repos]      gl-conf-list-repo             open a navigation window with all the repositories (hyperlink enabled).
\\[gl-conf-mark-repo]      gl-conf-mark-repo             mark (select) the current repository and body.
\\[gl-conf-list-groups]      gl-conf-list-groups           open a navigation window with all the repositories (hyperlink enabled).
\\[gl-conf-context-help]      gl-conf-mark-repo             open gitolite help (context sensitive)."

  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'gl-conf-mode)
  (setq mode-name "gitolite-conf")

  (require 'thingatpt)

  ;; Create the syntax table
  (setq gl-conf-mode-syntax-table (make-syntax-table))
  (set-syntax-table gl-conf-mode-syntax-table)
  (modify-syntax-entry ?_  "w" gl-conf-mode-syntax-table)
  (modify-syntax-entry ?@  "w" gl-conf-mode-syntax-table)
  (modify-syntax-entry ?# "<" gl-conf-mode-syntax-table)
  (modify-syntax-entry ?\n ">" gl-conf-mode-syntax-table)

  ;; Setup font-lock mode, indentation and comment highlighting
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(gl-conf-font-lock-buffer))

  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'gl-conf-indent)

  (make-local-variable 'comment-start)
  (setq comment-start "#")

  ;; to make searches case sensitive in some points in the code
  (make-local-variable 'case-fold-search)


  ;; setup key bindings (C-c followed by control character are reserved for major modes by the conventions)
  (local-set-key (kbd "C-c C-n") 'gl-conf-find-next-repo)
  (local-set-key (kbd "C-c C-p") 'gl-conf-find-prev-repo)
  (local-set-key (kbd "C-c C-v") 'gl-conf-visit-include)
  (local-set-key (kbd "C-c C-l") 'gl-conf-list-repos)
  (local-set-key (kbd "C-c C-m") 'gl-conf-mark-repo)
  (local-set-key (kbd "C-c C-g") 'gl-conf-list-groups)
  (local-set-key (kbd "C-c C-h") 'gl-conf-context-help)


  ;; Run user hooks.
  (run-hooks 'gl-conf-mode-hook))


;; Show the world what we have
(provide 'gl-conf-mode)
(provide 'gl-conf-find-next-repo)
(provide 'gl-conf-find-prev-repo)
(provide 'gl-conf-visit-include)
(provide 'gl-conf-list-repos)
(provide 'gl-conf-mark-repo)

;;; gl-conf-mode.el ends here
