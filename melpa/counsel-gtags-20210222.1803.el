;;; counsel-gtags.el --- ivy for GNU global -*- lexical-binding: t; -*-

;; Copyright (C) 2016 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;;         Felipe Lema <felipelema@mortemale.org>
;;         Jimmy Aguilar Mena <spacibba@aol.com>
;; URL: https://github.com/FelipeLema/emacs-counsel-gtags
;; Package-Version: 20210222.1803
;; Package-Commit: 1d52eaeffeb60266434d4f7416a108ca058fde91
;; Version: 0.10
;; Package-Requires: ((emacs "25.1") (counsel "0.8.0") (seq "1.0"))

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

;; `counsel-gtags.el' provides `ivy' interface of GNU GLOBAL.

;;; Code:

(require 'counsel)
(require 'cl-lib)
(require 'rx)
(require 'seq)

(declare-function cygwin-convert-file-name-from-windows "cygw32.c")
(declare-function cygwin-convert-file-name-to-windows "cygw32.c")
(declare-function tramp-file-name-localname "tramp")
(declare-function tramp-dissect-file-name "tramp")

(defgroup counsel-gtags nil
  "`counsel' for GNU Global"
  :group 'counsel)

(defconst counsel-gtags-path-styles-list '(through relative absolute abslib))

(defcustom counsel-gtags-path-style 'through
  "Path style of candidates.
The following values are supported:
- `through'     Show path from root of current project.
- `relative' Show path from current directory.
- `absolute' Show absolute path.
- `abslib' Show absolute path for libraries (GTAGSLIBPATH) and relative path for the rest."
  :type '(choice (const :tag "Root of the current project" through)
                 (const :tag "Relative from the current directory" relative)
                 (const :tag "Absolute path" absolute)
                 (const :tag "Absolute path for libraries (GTAGSLIBPATH) and relative path for the rest" abslib)))

(defcustom counsel-gtags-auto-update nil
  "Whether to update the tag database when a buffer is saved to file."
  :type 'boolean)

(defcustom counsel-gtags-update-interval-second 60
  "Update tag database after this many seconds have passed.
If nil, the tags are updated every time a buffer is saved to file."
  :type '(choice (integer :tag "Update after this many seconds")
                 (boolean :tag "Update every time" nil)))

(defcustom counsel-gtags-use-input-at-point t
  "Whether to use input at point.
If non-nil, the symbol at point is used as default value when
searching for a tag."
  :type 'boolean)

(defcustom counsel-gtags-global-extra-update-options-list nil
  "List of extra arguments passed to global when updating database."
  :type 'list)

(defcustom counsel-gtags-gtags-extra-update-options-list nil
  "List of extra arguments passed to gtags when updating database."
  :type 'list)

(defcustom counsel-gtags-debug-mode nil
  "Enable debug mode like print some commands in *Messages*.
The general user shouldn't use this variable."
  :type 'boolean)

(defcustom counsel-gtags-use-dynamic-list t
  "Enable use external grep to filter candidates list before
arriving to Emacs.  This option is useful specially when using
tramp and the candidates list is not huge."
  :type 'boolean)


(defconst counsel-gtags--prompts-alist
  '((definition . "Find Definition: ")
    (file      . " Find File: ")
    (pattern    . "Find Pattern: ")
    (reference  . "Find Reference: ")
    (symbol     . "Find Symbol: ")))

(defconst counsel-gtags--complete-options-alist
  '((definition . "-d")
    (file      . "-P")
    (pattern   . "-g")
    (reference . "-r")
    (symbol    . "-s")))


(defvar counsel-gtags--last-update-time 0)
(defvar counsel-gtags--context nil)
(defvar counsel-gtags--other-window nil
  "Helper global variable to implement other-window functions.

This variable is supposed to be used only as a forward
declaration.  It's global value must be always null and set it
with `let' otherwise.  When `non-nil' `counsel-gtags--jump-to'
uses `find-file-other-window' instead of `find-file.'")
(defvar counsel-gtags--original-default-directory nil
  "Last `default-directory' where command is invoked.")

(defvar-local counsel-gtags--context-position 0)
(defvar-local counsel-gtags--get-grep-command nil
  "Grep command to use found in the system.

This is cached to avoid repeat search in the system and improve
performance.  The value is initialized in
counsel-gtags--get-grep-command-find.")

(defconst counsel-gtags--grep-commands-list '("rg" "ag" "grep")
  "List of grep-like commands to filter candidates.

The first command available is used to do the filtering.  `grep-command', if
non-nil and available, has a higher priority than any entries in this list.
Use `counsel-gtags--grep-options' to specify the options
to suppress colored output.")

(defconst counsel-gtags--grep-options-alist
  '(("rg" . "--color never")
    ("ag" . "--nocolor")
    ("grep" . "--color=never"))
  "List of grep-like commands with their options to suppress colored output.")

(defconst counsel-gtags--labels
  '("default" "native" "ctags" "pygments")
  "List of valid values for gtags labels.")

(defconst counsel-gtags--include-regexp
  "\\`\\s-*#\\(?:include\\|import\\)\\s-*[\"<]\\(?:[./]*\\)?\\(.*?\\)[\">]")

(defsubst counsel-gtags--debug-message (format-string &rest args)
  "Print messages only when `counsel-gtags-debug-mode' is `non-nil'.

The arguments FORMAT-STRING and ARGS are the same than in the
`message' function."
  (if counsel-gtags-debug-mode
      (let ((inhibit-message t))
	(apply #'message format-string args))))

(defun counsel-gtags--command-options (type tagname extra-options)
  "Get list with options for global command according to TYPE.

Prepend EXTRA-OPTIONS.  If \"--result=.\" is in EXTRA-OPTIONS, it will have
precedence over default \"--result=grep\"."
  (let* ((extra (or (and (stringp extra-options) extra-options)
		    " "))
	 (options (concat
		   (and (getenv "GTAGSLIBPATH") "-T ")
		   (and current-prefix-arg "-l ")
		   (and tagname (ivy--case-fold-p tagname) "-i ") ;; -M is already default
		   (and (memq counsel-gtags-path-style counsel-gtags-path-styles-list)
			(format "--path-style=%s " (symbol-name counsel-gtags-path-style)))
		   (assoc-default type counsel-gtags--complete-options-alist) " "
		   (unless (string-match-p "--result=" extra)
		     "--result=grep ")
		   extra)))
    (counsel-gtags--debug-message "Options: %s" options)
    options))

(defun counsel-gtags--get-grep-command-find ()
  "Get a grep command to be used to filter candidates.

Returns a command without arguments.
Otherwise, returns nil if couldn't find any.

Use `counsel-gtags--grep-commands-list' to specify a list of commands to be
checked for availability."
  (or counsel-gtags--get-grep-command        ;; Search only the first time
      (setq-local counsel-gtags--get-grep-command
		  (catch 'path
		    (mapc (lambda (exec)
			    (let ((path
                                   (if (file-remote-p default-directory)
                                       (if (version< "27.1" emacs-version)
                                           (error "Tried to search for remote path for %s, but need at least Emacs 27.1" exec)
                                         (executable-find exec t))
                                     ;; not remote, search locally for executable
                                     (executable-find exec))))
			      (when path
				(throw 'path
				       (concat path " "
					       (cdr (assoc-string exec counsel-gtags--grep-options-alist)))))))
			  counsel-gtags--grep-commands-list)
		    nil))))

(defun counsel-gtags--build-command-to-collect-candidates (query)
  "Build command to collect condidates filtering by QUERY.

Used in `counsel-gtags--[a]sync-tag-query'.  Call global \"list all
 tags\" and if QUERY is non-nil then forward to grep command (provided by
 `counsel-gtags--get-grep-command-find') to filter.  We use grep
 command because using ivy's default filter
 `counsel--async-filter' is too slow with lots of tags."
  (concat "global -c "
	  (counsel-gtags--command-options 'definition query nil)
	  (and query  ;; Conditionally filter the list with grep.
	       (concat " | "
		       (counsel-gtags--get-grep-command-find)
		       " "
		       (shell-quote-argument (counsel--elisp-to-pcre (ivy--regex query)))))))


(defun counsel-gtags--async-tag-query (query)
  "Gather the object names asynchronously for `ivy-read'.

Use global flags according to TYPE.

Forward QUERY to global command to be treated as regex.

Because «global -c» only accepts letters-and-numbers, we actually search for
tags matching QUERY, but filter the list.

Inspired on ivy.org's `counsel-locate-function'."
  (or (ivy-more-chars)
      (let ((command (counsel-gtags--build-command-to-collect-candidates query)))
	(counsel-gtags--debug-message "Async Command: %s" command)
	(counsel--async-command command)
	'("" "Filtering …"))))

(defun counsel-gtags--sync-tag-query ()
  "Gather the object names for `ivy-read'."
  (let ((command (counsel-gtags--build-command-to-collect-candidates nil)))
    (counsel-gtags--debug-message "Sync Command: %s" command)
    (counsel-gtags--process-lines command)))

(defun counsel-gtags--file-and-line (candidate)
  "Return list with file and position per CANDIDATE.

Candidates are supposed to be strings of the form \"file:line\" as returned by
global. Line number is returned as number (and not string)."
  (if (and (memq system-type '(windows-nt ms-dos))  ;; in MS windows
           (string-match-p "\\`[a-zA-Z]:" candidate)) ;; Windows Driver letter
      (when (string-match "\\`\\([^:]+:[^:]+:\\):\\([^:]+\\)" candidate)
        (list (match-string-no-properties 1)
              (string-to-number (match-string-no-properties 2))))
    (let ((fields (split-string candidate ":")))
      (list (car fields) (string-to-number (or (cadr fields) "1"))))))

(defun counsel-gtags--resolve-actual-file-from (file-candidate)
  "Resolve actual file path from CANDIDATE taken from a global cmd query.

Note: candidates are handled as ⎡file:location⎦ and ⎡(file . location)⎦.
FILE-CANDIDATE is supposed to be *only* the file part of a candidate."
  (let ((file-path-per-style
	 (concat
	  (pcase counsel-gtags-path-style
	    ((or 'relative 'absolute 'abslib) "")
	    ('through (file-name-as-directory
		       (counsel-gtags--default-directory)))
	    (_ (error
		"Unexpected counsel-gtags-path-style: %s"
		(symbol-name counsel-gtags-path-style))))
	  file-candidate)))
    (file-truename file-path-per-style)))

(defun counsel-gtags--jump-to (candidate &optional push)
  "Call `find-file' and `forward-line' on file location from CANDIDATE .

Calls `counsel-gtags--push' at the end if PUSH is non-nil.
Returns (buffer line)"
  (cl-multiple-value-bind (file-path line)
      (counsel-gtags--file-and-line candidate)
    (let* ((default-directory (file-name-as-directory
			       (or counsel-gtags--original-default-directory
				   default-directory)))
	   (file (counsel-gtags--resolve-actual-file-from file-path))
	   (opened-buffer (if counsel-gtags--other-window
			      (find-file-other-window file)
			    (find-file file))))
      ;; position correctly within the file
      (goto-char (point-min))
      (forward-line (1- line))
      (back-to-indentation)
      (if (and push
	       (not counsel-gtags--other-window))
	  (counsel-gtags--push 'to))
      `(,opened-buffer ,line))))

(defun counsel-gtags--find-file (candidate)
  "Open file-at-position per CANDIDATE using `find-file'.
This is the `:action' callback for `ivy-read' calls."
  (with-ivy-window
    (swiper--cleanup)
    (counsel-gtags--push 'from))
  (counsel-gtags--jump-to candidate 'push))

(defun counsel-gtags--find-file-other-window (candidate)
  "Open file-at-position per CANDIDATE using `find-file-other-window'.
This is the alternative `:action' callback for `ivy-read' calls."
  (let ((counsel-gtags--other-window t))
    (counsel-gtags--find-file candidate)))

(defmacro counsel-gtags--read-tag (type)
  "Prompt the user for selecting a tag using `ivy-read'.

Returns selected tag
Use TYPE ∈ '(definition reference symbol) for defining global parameters.
If `counsel-gtags-use-input-at-point' is non-nil, will use symbol at point as
initial input for `ivy-read'.

See `counsel-gtags--async-tag-query' for more info."
  `(ivy-read ,(alist-get type counsel-gtags--prompts-alist)
	     (if counsel-gtags-use-dynamic-list
		 #'counsel-gtags--async-tag-query
	       (counsel-gtags--sync-tag-query))
	     :initial-input (and counsel-gtags-use-input-at-point
				 (ivy-thing-at-point))
	     :unwind (lambda ()
		       (counsel-delete-process)
		       (swiper--cleanup))
	     :dynamic-collection counsel-gtags-use-dynamic-list
	     :caller 'counsel-gtags--read-tag))

(defun counsel-gtags--process-lines (command)
  "Like `process-lines' on COMMAND and ARGS, but using `process-file'.

`process-lines' does not support Tramp because it uses `call-process'.  Using
`process-file' makes Tramp support auto-magical."
  ;; Space before buffer name to make it "invisible"
  (let* ((global-run-buffer (get-buffer-create (format " *global @ %s*" default-directory)))
	 (lines (progn
		  (with-current-buffer global-run-buffer
		    (erase-buffer))
		  (process-file-shell-command command nil global-run-buffer nil)
		  (with-current-buffer global-run-buffer
		    (split-string (buffer-string) "\n" t)))))
    (counsel-gtags--debug-message "process-lines command: %s" command)
    lines))

(defun counsel-gtags--collect-candidates (type tagname extra-options)
  "Collect lines for ⎡global …⎦ using TAGNAME as query.

TAGNAME may be nil, suggesting a match-any query.
Use TYPE to specify query type (tag, file).
Use ENCODING to specify encoding.
Use EXTRA-OPTIONS to specify encoding.

This is for internal use and not for final user."
  (let* ((query-quoted (and tagname
			    (stringp tagname)
			    (shell-quote-argument tagname)))
	 (options (counsel-gtags--command-options type tagname extra-options))
         (default-directory default-directory)
         (coding-system-for-read buffer-file-coding-system)
         (coding-system-for-write buffer-file-coding-system))

    (counsel-gtags--process-lines (concat "global " options query-quoted))))


(defun counsel-gtags--select-file (type tagname
					&optional extra-options auto-select-only-candidate)
  "Prompt the user to select a file_path:position according to query.

Use TYPE ∈ '(definition reference symbol) for defining global parameters.
Use TAGNAME for global query.
Use AUTO-SELECT-ONLY-CANDIDATE to skip `ivy-read' if have a single candidate.
Extra command line parameters to global are forwarded through EXTRA-OPTIONS."
  (let* ((default-directory (counsel-gtags--default-directory))
	 (collection (counsel-gtags--collect-candidates type tagname extra-options))
	 (ivy-auto-select-single-candidate t)
	 (first (cadr collection)))
    (cond
     ((null collection) ;; No candidates in collection.
      (message "No candidate available for %s" tagname)
      nil)
     ((and auto-select-only-candidate (= (length collection) 1))
      (counsel-gtags--find-file (car first)))
     (t
      (ivy-read "Pattern: "
		collection
		:action #'counsel-gtags--find-file
		:caller 'counsel-gtags--select-file)))))
(ivy-set-actions
 'counsel-gtags--select-file
 '(("j" counsel-gtags--find-file-other-window "other window")))

;;;###autoload
(defun counsel-gtags-find-definition (tagname)
  "Search for TAGNAME definition in tag database.
Prompt for TAGNAME if not given."
  (interactive
   (list (counsel-gtags--read-tag definition)))
  (counsel-gtags--select-file 'definition tagname))

;;;###autoload
(defun counsel-gtags-find-reference (tagname)
  "Search for TAGNAME reference in tag database.
Prompt for TAGNAME if not given."
  (interactive
   (list (counsel-gtags--read-tag reference)))
  (counsel-gtags--select-file 'reference tagname))

;;;###autoload
(defun counsel-gtags-find-symbol (tagname)
  "Search for TAGNAME symbol in tag database.
Prompt for TAGNAME if not given."
  (interactive
   (list (counsel-gtags--read-tag symbol)))
  (counsel-gtags--select-file 'symbol tagname))

;; Other window Commands

(defun counsel-gtags-find-definition-other-window (tagname)
  "Search for TAGNAME definition in tag database in other window.
Prompt for TAGNAME if not given."
  (interactive
   (list (counsel-gtags--read-tag definition)))
  (let ((counsel-gtags--other-window t))
    (counsel-gtags--select-file 'definition tagname)))

;;;###autoload
(defun counsel-gtags-find-reference-other-window (tagname)
  "Search for TAGNAME reference in tag database in other window.
Prompt for TAGNAME if not given."
  (interactive
   (list (counsel-gtags--read-tag reference)))
  (let ((counsel-gtags--other-window t))
    (counsel-gtags--select-file 'reference tagname)))

;;;###autoload
(defun counsel-gtags-find-symbol-other-window (tagname)
  "Search for TAGNAME symbol in tag database in other window.
Prompt for TAGNAME if not given."
  (interactive
   (list (counsel-gtags--read-tag symbol)))
  (let ((counsel-gtags--other-window t))
    (counsel-gtags--select-file 'symbol tagname)))

(defun counsel-gtags--include-file ()
  "Get ⎡#include …⎦ from first line."
  (let ((line (buffer-substring-no-properties
               (line-beginning-position) (line-end-position))))
    (when (string-match counsel-gtags--include-regexp line)
      (match-string-no-properties 1 line))))

(defun counsel-gtags--default-directory ()
  "Return default directory per `counsel-gtags-path-style'.

Useful for jumping from a location when using global commands (like with
\"--from-here\")."
  (setq counsel-gtags--original-default-directory
        (cl-case counsel-gtags-path-style
          ((relative absolute) default-directory)
          (through (or (getenv "GTAGSROOT")
		       (locate-dominating-file default-directory "GTAGS")
		       ;; If file doesn't exist create it?
		       (if (yes-or-no-p "File GTAGS not found. Run 'gtags'? ")
			   (call-interactively 'counsel-gtags-create-tags)
			 (error "Abort generating tag files")))))))

;;;###autoload
(defun counsel-gtags-find-file (&optional filename)
  "Search/narrow for FILENAME among tagged files."
  (interactive)
  (let* ((initial-input (or filename (counsel-gtags--include-file)))
         (collection (counsel-gtags--collect-candidates 'file nil "--result=path ")))
    (ivy-read "Find File: " collection
	      :initial-input initial-input
	      :action #'counsel-gtags--find-file
	      :caller 'counsel-gtags-find-file)))

(defun counsel-gtags-find-file-other-window (&optional filename)
  (interactive)
  "Search/narrow for FILENAME among tagged files in other window."
  (let ((counsel-gtags--other-window t))
    (call-interactively #'counsel-gtags-find-file filename)))

(ivy-set-actions
 'counsel-gtags-find-file
 '(("j" counsel-gtags--find-file-other-window "other window")))

(defun counsel-gtags--goto (position)
  "Go to POSITION in context stack.
Return t on success, nil otherwise."
  (let ((context (nth position counsel-gtags--context)))
    (when (and context
               (cond
                ((plist-get context :file)
                 (find-file (plist-get context :file)))
                ((and (plist-get context :buffer)
                      (buffer-live-p (plist-get context :buffer)))
                 (switch-to-buffer (plist-get context :buffer)))
                (t nil)))
      (goto-char (point-min))
      (forward-line (1- (plist-get context :line)))
      t)))

;;;###autoload
(defun counsel-gtags-go-backward ()
  "Go to previous position in context stack."
  (interactive)
  (unless counsel-gtags--context
    (user-error "Context stack is empty"))
  (catch 'exit
    (let ((position counsel-gtags--context-position)
          (num-entries (length counsel-gtags--context)))
      (while (< (cl-incf position) num-entries)
        (when (counsel-gtags--goto position)
          (setq counsel-gtags--context-position position)
          (throw 'exit t))))))

;;;###autoload
(defun counsel-gtags-go-forward ()
  "Go to next position in context stack."
  (interactive)
  (unless counsel-gtags--context
    (user-error "Context stack is empty"))
  (catch 'exit
    (let ((position counsel-gtags--context-position))
      (while (>= (cl-decf position) 0)
        (when (counsel-gtags--goto position)
          (setq counsel-gtags--context-position position)
          (throw 'exit t))))))

(defun counsel-gtags--push (direction)
  "Add new entry to context stack.

  DIRECTION ∈ '(from, to)."
  (let ((new-context (list :file (and (buffer-file-name)
                                      (file-truename (buffer-file-name)))
                           :buffer (current-buffer)
                           :line (line-number-at-pos)
                           :direction direction)))
    (setq counsel-gtags--context
          (nthcdr counsel-gtags--context-position counsel-gtags--context))
    ;; We do not want successive entries with from-direction,
    ;; so we remove the old one.
    (let ((prev-context (car counsel-gtags--context)))
      (if (and (eq direction 'from)
               (eq (plist-get prev-context :direction) 'from))
          (pop counsel-gtags--context)))
    (push new-context counsel-gtags--context)
    (setq counsel-gtags--context-position 0)))

(defmacro counsel-gtags--make-gtags-sentinel (action)
  "Return default sentinel that messages success/failed exit.

  Message printed has ACTION as detail."
  `(lambda (process _event)
     (when (eq (process-status process) 'exit)
       (if (zerop (process-exit-status process))
	   (progn
             (message "Success: %s TAGS" ,action)
	     (setq counsel-gtags--last-update-time (current-time)))
         (message "Failed: %s TAGS(%d)" ,action (process-exit-status process))))))


(defun counsel-gtags--remote-truename (&optional file-path)
  "Return real file name for file path FILE-PATH in remote machine.

  If file is local, return its `file-truename'

  FILE-PATH defaults to current buffer's file if it was not provided."
  (let ((filename (or file-path
                      (buffer-file-name)
                      (error "This buffer is not related to any file")))
	(default-directory (file-name-as-directory default-directory)))
    (if (file-remote-p filename)
        (tramp-file-name-localname (tramp-dissect-file-name filename))
      (expand-file-name filename))))

(defsubst counsel-gtags--read-tag-directory ()
  "Get directory for tag generation from user."
  (directory-file-name
   (expand-file-name
    ;; On Windows, "gtags d:/tmp" work, but "gtags d:/tmp/" doesn't
    (read-directory-name "Directory tag generated: " nil nil t))))

;;;###autoload
(defun counsel-gtags-create-tags (rootdir label)
  "Create tag database in ROOTDIR.
LABEL is passed as the value for the environment variable GTAGSLABEL.
Prompt for ROOTDIR and LABEL if not given.  This command is asynchronous."
  (interactive
   (list (read-directory-name "Root Directory: " nil nil t)
         (ivy-read "GTAGSLABEL: " counsel-gtags--labels)))
  (let ((default-directory rootdir))
    (counsel--async-command-1 (concat "gtags -q --gtagslabel=" label)
			      (counsel-gtags--make-gtags-sentinel 'create)
			      #'internal-default-process-filter
			      " *counsel-gtags-tag-create*")))

(defun counsel-gtags--update-tags-command (how-to)
  "Build global command line to update commands.
HOW-TO ∈ '(entire-update generate-other-directory single-update)
per (user prefix)."
  (pcase how-to
    ('entire-update
     (concat "global -u " counsel-gtags-global-extra-update-options-list))
    ('generate-other-directory
     (concat "gtags "
	     counsel-gtags-global-extra-update-options-list
	     (counsel-gtags--read-tag-directory)))
    ('single-update
     (concat "global --single-update "
	     counsel-gtags-global-extra-update-options-list
	     (counsel-gtags--remote-truename)))))

(defsubst counsel-gtags--update-tags-p (how-to interactive-p)
  "Should we update tags now?.

  Will update if being called interactively per INTERACTIVE-P.
  If HOW-TO equals 'single-update, will update only if
  `counsel-gtags-update-interval-second' seconds have passed up to CURRENT-TIME."
  (or interactive-p
      (and (eq how-to 'single-update)
           (buffer-file-name)
           (or (not counsel-gtags-update-interval-second)
               (>= (- (float-time (current-time)) counsel-gtags--last-update-time)
                   counsel-gtags-update-interval-second)))))

;;;###autoload
(defun counsel-gtags-update-tags ()
  "Update tag database for current file.
Changes in other files are ignored.  With a prefix argument, update
tags for all files.  With two prefix arguments, generate new tag
database in prompted directory."
  (interactive)
  (let ((how-to (pcase (prefix-numeric-value current-prefix-arg)
		  (4 'entire-update)
		  (16 'generate-other-directory)
		  (otherwise 'single-update))))
    (when (counsel-gtags--update-tags-p how-to
					(called-interactively-p 'interactive))
      (counsel--async-command-1 (counsel-gtags--update-tags-command how-to)
				(counsel-gtags--make-gtags-sentinel 'update)
				#'internal-default-process-filter
				" *counsel-gtags-update-tag*"))))

(defun counsel-gtags--from-here (tagname)
  "Try to open file by querying TAGNAME and \"--from-here\"."
  (let* ((line (line-number-at-pos))
         (root (counsel-gtags--remote-truename (counsel-gtags--default-directory)))
         (file (counsel-gtags--remote-truename))
         (from-here-opt (format "--from-here=%d:%s " line (file-relative-name file root))))
    (counsel-gtags--select-file 'from-here tagname from-here-opt t)))

(defun counsel-gtags-dwim ()
  "Find definition or reference of thing at point (Do What I Mean).
If point is at a definition, find its references, otherwise, find
its definition."
  (interactive)
  (let ((cursor-symbol (thing-at-point 'symbol t)))
    (if (and (buffer-file-name) cursor-symbol)
        (counsel-gtags--from-here cursor-symbol)
      (call-interactively 'counsel-gtags-find-definition))))

(defvar counsel-gtags-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "g") #'counsel-gtags-dwim)
    (define-key map (kbd "d") #'counsel-gtags-find-definition)
    (define-key map (kbd "r") #'counsel-gtags-find-reference)
    (define-key map (kbd "s") #'counsel-gtags-find-symbol)
    (define-key map (kbd "n") #'counsel-gtags-go-forward)
    (define-key map (kbd "p") #'counsel-gtags-go-backward)
    (define-key map (kbd "c") #'counsel-gtags-create-tags)
    (define-key map (kbd "u") #'counsel-gtags-update-tags)
    (define-key map (kbd "f") #'counsel-gtags-find-file)
    (define-key map (kbd "4 d") #'counsel-gtags-find-definition-other-window)
    (define-key map (kbd "4 r") #'counsel-gtags-find-reference-other-window)
    (define-key map (kbd "4 s") #'counsel-gtags-find-symbol-other-window)
    (define-key map (kbd "4 f") #'counsel-gtags-find-file-other-window)
    map)
  "Keymap for counsel-gtags commands after prefix.")

(defvar counsel-gtags-mode-map (make-sparse-keymap)
  "Keymap for  counsel-gtags-mode.")

;;;###autoload
(define-minor-mode counsel-gtags-mode
  "Minor mode of counsel-gtags.
  If `counsel-gtags-update-tags' is non-nil, the tag files are updated
  after saving buffer."
  :keymap     counsel-gtags-mode-map
  (if counsel-gtags-mode
      (when counsel-gtags-auto-update
        (add-hook 'after-save-hook 'counsel-gtags-update-tags nil t))
    (when counsel-gtags-auto-update
      (remove-hook 'after-save-hook 'counsel-gtags-update-tags t))))

(provide 'counsel-gtags)

;;; counsel-gtags.el ends here
