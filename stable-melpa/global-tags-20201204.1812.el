;;; global-tags.el --- Elisp API and editor integration for GNU global  -*- lexical-binding: t; -*-

;; Copyright © 2019  Felipe Lema

;; Author: Felipe Lema <felipelema@mortemale.org>
;; Keywords: convenience, matching, tools
;; Package-Version: 20201204.1812
;; Package-Commit: 5e7738524789d5b95498e3b88621a3877eef5c50
;; Package-Requires: ((emacs "26.1") (async "1.9.4"))
;; URL: https://launchpad.net/global-tags.el
;; Version: 0.3

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU Lesser General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Lesser General Public License for more details.

;; You should have received a copy of the GNU Lesser General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; Testeable elisp API that wraps GNU global calls and integration to editor
;; using this API with project.el and xref.el
;; You can setup using GNU global as backend with any of the following two
;; lines:
;;
;; ;; to use GNU Global automagically, regardless of Emacs default configuration
;; (add-hook 'ruby-mode-hook #'global-tags-exclusive-backend-mode)
;; ;; to use GNU Global automagically, respecting other backends
;; (add-hook 'ruby-mode-hook #'global-tags-shared-backend-mode)
;;
;; Alternatively, you can manually configure project.el and xref.el, add their
;; "recognize this global handled project" to the proper places like so:
;;
;; ;; xref (finding definitions, references)
;; (add-to-list 'xref-backend-functions 'global-tags-xref-backend)
;; ;; project.el (finding files)
;; (add-to-list 'project-find-functions 'global-tags-try-project-root)
;; ;; to update database after save
;; (add-hook 'c++-mode-hook (lambda ()
;;                            (add-hook 'after-save-hook
;;                                      #'global-tags-update-database-with-buffer
;;                                      nil
;;                                      t)))

;;; Code:

;;; Static definitions
(defgroup global-tags nil "GNU global integration"
  :group 'tools)

(require 'async)
(require 'cl-lib)
(require 'generator)
(require 'project)
(require 'rx)
(require 'subr-x)
(require 'xref)

;;;; variables

(defcustom global-tags-global-command
  "global"
  "Name/path to Global executable."
  :type 'string
  :group 'global-tags)

(defcustom global-tags-tags-generation-command
  "gtags"
  "Name/path to executable to generate tags"
  :type 'string
  :group 'global-tags)

(defcustom global-tags-generate-tags-command
  "gtags"
  "Name/path to executable to generate tags"
  :type 'string
  :group 'global-tags)

(defcustom global-tags-generate-tags-flags
  '()
  "command-line flags to `global-tags-tags-generation-command'"
  :type '(repeat string)
  :group 'global-tags)

;;;; utility functions:

(defun global-tags--command-flag (command)
  "Get command line flag for COMMAND as string-or-nil.

Flags are not contracted.  Returned as list to compose command."
  (pcase command
    (`tag nil)
    ((or `completion `file `grep `idutils `path `print-dbpath `reference `update)
     (list (format "--%s" (symbol-name command))))
    (_ (error "Unknown command: %s" (symbol-name command)))))

;;; API

(defun global-tags--option-flags (flags)
  "Support several formats of to-cli-ize FLAGS.

Will recurse on lists."
  (if (not (null flags))
      (let ((head-flag (car flags))
	    (rest-flags (cdr flags)))
	(pcase head-flag
	  ((pred listp)
	   ;; received a list of list
	   ;; if you know elisp and know how to handle ⎡&rest⎦, then you can
	   ;; help remove this section
	   (let ((l head-flag))
	     (cl-assert (= 1 (length flags)))
	     (append (global-tags--option-flags l))))
	  ((pred null)
	   (global-tags--option-flags rest-flags))
	  ('nearness
	   (let ((next-flag (cadr flags))
		 (rest-flags (cddr flags))) ;; diferent "rest"
	     (append
	      `(,(format "--nearness=%s" next-flag))
	      (global-tags--option-flags rest-flags))))
	  ((pred symbolp)
	   (append `(,(format "--%s" (symbol-name head-flag)))
		   (global-tags--option-flags rest-flags)))
	  ((pred stringp)
	   (append `(,head-flag)
		   (global-tags--option-flags rest-flags)))))))



(defun global-tags--get-arguments (command &rest flags)
  "Get arguments to global as list per COMMAND and flags.

FLAGS must be plist like
\(global-tags--get-arguments … :absolute :color \"always\"\)."
  (append
   (global-tags--command-flag command)
   (global-tags--option-flags flags)))

;;; Convenience functions (for developers of this package)

(defun global-tags--get-as-string (command &rest flags)
  "Execute global COMMAND with FLAGS.

FLAGS is a plist.  See `global-tags--get-arguments'.

If inner global command returns non-0, then this function returns nil."
  (let* ((program-and-args (append `(,global-tags-global-command)
				   (global-tags--get-arguments
				    command flags)))
	 (program (car program-and-args))
	 (program-args (cdr program-and-args))
	 (command-return-code)
	 (command-output-str
	  (with-output-to-string
	    (setq command-return-code
		  ;; `call-process', but forwarding program-args
		  ;; 🙄
		  (apply (apply-partially
			  #'process-file
			  program
			  nil ;; infile
			  `(,standard-output nil) ;; dest, ???
			  nil) ;; display
			 program-args)))))
    (if (= command-return-code 0)
	command-output-str)))

(defun global-tags--get-lines (command &rest flags)
  "Break global COMMAND FLAGS output into lines.

Adds (print0) to flags.

If COMMAND is completion, no print0 is added (global ignores it underneath)."
  (pcase-let ((`(,separator . ,command-flags)
	       (pcase command
		 (`completion
		  (cons "\n" (delete 'print0 flags)))
		 (_
		  (cons "\0" (append '(print0) flags))))))
    (when-let* ((output (global-tags--get-as-string command command-flags)))
      (split-string output separator t))))

(defun global-tags--get-location (line)
  "Parse location from LINE.

Assumes (:result \"grep\").
Column is always 0."
  (save-match-data
    (when (string-match (rx line-start
			    (group (+ (any print))) ;; file
			    ?: ;; separator
			    (group (+ (any digit))) ;; line
			    ?: ;; separator
			    (group (* (any print blank))) ;; function or line with code
			    line-end)
			line)
      `((file . ,(match-string 1 line))
	(line . ,(string-to-number (match-string 2 line)))
	(description . ,(match-string 3 line))
	(column . 0)))))

(defun global-tags--as-xref-location (location-description)
  "Map LOCATION-DESCRIPTION from `global-tags--get-locations' to xref's repr."
  (let-alist location-description
    (xref-make .description
	       (xref-make-file-location .file
					.line
					.column))))

(defun global-tags--get-locations (symbol &optional kind)
  "Get locations according to SYMBOL and KIND.

If KIND is omitted, will do \"tag\" search."
  (let ((lines (global-tags--get-lines kind
                                       ;; ↓ see `global-tags--get-location'
                                       'result "grep"
                                       symbol)))
    (cl-mapcar #'global-tags--get-location lines)))

(defun global-tags--get-xref-locations (symbol kind)
  "Get xref locations according to KIND using SYMBOL as query.

See `global-tags--get-locations'."
  (cl-mapcar #'global-tags--as-xref-location
             (global-tags--get-locations symbol kind)))

(defun global-tags--get-dbpath (dir)
  "Filepath for database from DIR or nil."
  (when-let* ((maybe-dbpath (let ((default-directory dir))
                              (global-tags--get-as-string 'print-dbpath)))
              ;; db path is *always* printed with trailing newline
              (trimmed-dbpath (substring maybe-dbpath 0
                                         (- (length maybe-dbpath) 1)))
              (dbpath (concat
                       (file-remote-p dir) ;; add remote file prefix when dir is remote
                       trimmed-dbpath)))
    (if (file-exists-p dbpath)
        dbpath)))

;;; project.el integration

(defun global-tags-try-project-root (dir)
  "Project root for DIR if it exists."
  (if-let* ((dbpath (global-tags--get-dbpath dir)))
      (cons 'global dbpath)))

(cl-defmethod project-roots ((project (head global)))
  "Default implementation.

See `project-roots' for 'transient."
  (list (cdr project)))

(cl-defmethod project-file-completion-table ((project (head global)) dirs)
  "See documentation for `project-file-completion-table'."
  (ignore project)
  (lambda (string pred action)
    (cond
     ((eq action 'metadata)
      '(metadata . ((category . project-file))))
     (t
      (let ((all-files
             (cl-mapcan
              (lambda (dir)
                (let* ((default-directory dir))
                  (global-tags--get-lines 'path
                                          ;; ↓ project.el deals w/long names
                                          'absolute
                                          pred)))
              dirs)))
        (complete-with-action action
                              (project--remote-file-names all-files)
                              string
                              pred))))))

;; No need to implement unless necessary
;;(cl-defmethod project-external-roots ((project (head global)))
;;  )
(cl-defmethod project-files ((project (head global)) &optional dirs)
  "Based off `vc' backend method."
  (let ((files-reported
         (cl-mapcan
          (lambda (dir)
            (let* ((default-directory dir))
              (global-tags--get-lines 'path
                                      ;; ↓ project.el deals w/long names
                                      'absolute)))
          (or dirs (project-roots project)))))
    (project--remote-file-names
     files-reported)))

;;(cl-defgeneric project-ignores (_project _dir)

;;; xref.el integration

(defun global-tags-xref-backend ()
  "Xref backend for using global."
  (if (global-tags--get-dbpath default-directory)
      'global))

(cl-defmethod xref-backend-definitions ((_backend (eql global)) symbol)
  "See `global-tags--get-locations'."
  (global-tags--get-xref-locations (substring-no-properties symbol) 'tag))

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql global)))
  (if-let ((symbol-str (thing-at-point 'symbol)))
      symbol-str))

(cl-defmethod xref-backend-identifier-completion-table ((_backend (eql global)))
  (global-tags--get-lines 'completion))

(cl-defmethod xref-backend-references ((_backend (eql global)) symbol)
  (global-tags--get-xref-locations (substring-no-properties symbol) 'reference))

(cl-defmethod xref-backend-apropos ((_backend (eql global)) symbol)
  (global-tags--get-xref-locations (substring-no-properties symbol) 'grep))

;;;; TODO
;;;; cache calls (see `tags-completion-table' @ etags.el)

;;; update database
(cl-defun global-tags-update-database-with-buffer (&optional
                                                   (buffer (current-buffer)))
  "Update BUFFER entry in database.

Requires BUFFER to have a file name (path to file exists)."
  (with-current-buffer buffer
    (unless (buffer-file-name)
      ;; don't update a buffer that doesn't exist
      (error "Cannot update %s (no filename)"
             buffer))
    (global-tags--get-as-string 'update
                                `(single-update
                                  ,(file-local-name
                                    (expand-file-name
                                     (buffer-file-name)))))))

;;; creating database
(defun global-tags-create-database (directory)
  "Create tags database at DIRECTORY."
  (interactive "DCreate database at: ")
  (let ((default-directory directory))
    (apply 'process-file
           (append
            (list
             global-tags-generate-tags-command
             nil nil nil)
            global-tags-generate-tags-flags))))

(defun global-tags-ensure-database ()
  "Calls `global-tags-create-database' if one db does not exist."
  (unless (global-tags--get-dbpath default-directory)
    (call-interactively #'global-tags-create-database)))

(cl-defun global-tags-update-database (&optional
                                       (async t))
  "Calls «global --update».
When ASYNC is non-nil, call using `async-start'."
  (interactive)
  (if (not async)
      (global-tags--get-as-string 'update)
    ;; else, run async
    (async-start
     `(let ((default-directory ,default-directory)
            (tramp-use-ssh-controlmaster-options nil) ;; avoid race conditions
            )
        (process-file
         ,global-tags-global-command
         nil
         nil
         nil
         ,@(global-tags--get-arguments
            'update))))))

(define-minor-mode global-tags-exclusive-backend-mode
  "Use GNU Global as exclusive backend for several Emacs features."
  nil nil nil
  (cond
   (global-tags-exclusive-backend-mode
    (setq-local 'xref-backend-functions '(global-tags-xref-backend))
    (setq-local 'project-find-functions '(global-tags-try-project-root))
    (add-hook 'after-save-hook
              #'global-tags-update-database-with-buffer
              nil
              t))
   (t
    (setq-local 'xref-backend-functions (default-value 'xref-backend-functions))
    (setq-local 'project-find-functions (default-value 'project-find-functions))
    (remove-hook 'after-save-hook
                 #'global-tags-update-database-with-buffer))))

(define-minor-mode global-tags-shared-backend-mode
  "Use GNU Global as backend for several Emacs features in this buffer."
  nil nil nil
  (cond
   (global-tags-shared-backend-mode
    (add-hook 'xref-backend-functions 'global-tags-xref-backend 80)
    (add-hook 'project-find-functions 'global-tags-try-project-root 80)
    (add-hook 'after-save-hook
              #'global-tags-update-database-with-buffer
              nil
              t))
   (t
    (remove-hook 'xref-backend-functions 'xref-backend-functions)
    (remove-hook 'project-find-functions 'project-find-functions)
    (remove-hook 'after-save-hook
                 #'global-tags-update-database-with-buffer))))

(provide 'global-tags)
;;; global-tags.el ends here
