;;; cobalt.el --- Easily use the Cobalt.rs static site generator   -*- lexical-binding: t -*-

;; Copyright (C) 2018 Juan Karlo Lidudine

;; Author: Juan Karlo Licudine <accidentalrebel@gmail.com>
;; URL: https://github.com/cobalt-org/cobalt.el
;; Package-Version: 20180304.1155
;; Package-Commit: 88ef936373a5493183d49ec69ca541bcc749a109
;; Version: 1.0.0
;; Keywords: convenience
;; Package-Requires: ((emacs "24"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Cobalt.el is an interface for Cobalt.rs, a static site
;; generator written in Rust

;; The package provides simple-to-use Emacs commands for easy site
;; generation and post management.

;;; License:

;; This program is free software; you can redistributfe it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Todo:
;;;; Bugs:

;; - Create function that checks if the current buffer is a valid post.
;; - If post is a draft, and cobalt-serve was not run with "--drafts", then don't allow previewing.
;; - cobalt-preview-post should get the path according to the post buffer.
;; - If start-process returns an error don't let it set cobalt--serve-process
;; - Fix error with cobalt-build when cobalt--current-site is nil.

;;;; Features:
;; - Create a cobalt-rename-post function.
;; - Create a cobalt-delete-post function.
;; - Create a cobalt-open-post function.

;;; Code:

(defgroup cobalt nil
  "Customization for cobalt.el"
  :group 'convenience)

(defcustom cobalt-site-paths nil
  "Variable that holds a list of cobalt sites."
  :group 'cobalt
  :type 'sexp)

(defcustom cobalt-log-buffer-name "*cobalt*"
  "Name of the log buffer for cobalt process output."
  :group 'cobalt
  :type 'string)

(defcustom cobalt-serve-port 3000
  "The port to serve the site on."
  :group 'cobalt
  :type 'number)

(defvar cobalt--serve-process nil
  "Use to save cobalt serve process is so it can be killed in the future.")

(defvar cobalt--current-site nil
  "The current site to run cobalt commands on.")

(defun cobalt-command (args)
  "Run specified cobalt command with ARGS at the current folder of the specified site."
  (interactive "scobalt ")
  (when (cobalt--executable-exists-p)
    (when (not cobalt--current-site)
      (cobalt-change-current-site))
    (let ((command-args (split-string args " ")))
      (apply 'call-process (executable-find "cobalt")
			   nil
			   cobalt-log-buffer-name
			   nil
			   command-args))
    (pop-to-buffer cobalt-log-buffer-name)))

(define-minor-mode cobalt-post-mode
  "Minor mode for cobalt posts."
  :lighter " CobaltPost")

;;;###autoload
(defun cobalt-init (args)
  "Create a new cobalt site at the given path indicated by ARGS."
  (interactive "DDirectory to create site: ")
  (cobalt--init args))

(defun cobalt--init (directory)
  "Create a new cobalt site at the given DIRECTORY."
  (apply 'call-process
	 (executable-find "cobalt")
	 nil
	 cobalt-log-buffer-name
	 nil
	 (list "init" directory)))

;;;###autoload
(defun cobalt-change-current-site ()
  "Show a selection to switch current site.
Kills an exiting server process.  User should run ‘cobalt-serve’ again for the newly switch site."
  (interactive)
  (when (cobalt--executable-exists-p)
    (when cobalt--serve-process
      (cobalt-serve-kill)
      (cobalt--log (concat "Server killed for " cobalt--current-site)))
    (if (not (and cobalt-site-paths (> (length cobalt-site-paths) 0) ))
	(cobalt--log "cobalt-site-paths is empty! Set it first." t)
      (setq cobalt--current-site (cobalt--check-fix-site-path (completing-read "Select site to use as current: " cobalt-site-paths nil t)))
      (cobalt--log (concat "Current cobalt site set to " cobalt--current-site)))))

(defun cobalt-serve (arg)
  "Build, serve, and watch the project at the source dir.
Specify a prefix argument (c-u) as ARG to include drafts."
  (interactive "P")
  (when (cobalt--executable-exists-p)
    (if cobalt--serve-process
	(cobalt--log "Serve process already running!" t)
      (when (not cobalt--current-site)
	(cobalt-change-current-site))
      (let* ((default-directory cobalt--current-site))
	(setq cobalt--serve-process (start-process "cobalt-serve"
						   cobalt-log-buffer-name
						   (executable-find "cobalt")
						   "serve"
						   (if (equal arg '(4))
						       "--drafts"
						     "--no-drafts")
						   "--port"
						   (number-to-string cobalt-serve-port)))
	(if (not cobalt--serve-process)
	    (cobalt--log "Problem running cobalt serve" t)
	  (cobalt--log (concat "Serve process is now running. "
			       (if (equal arg '(4))
				   "Drafts included."
				 "Drafts NOT included."))))))))

(defun cobalt-serve-kill ()
  "Kill the cobalt serve process, if existing."
  (interactive)
  (when (cobalt--executable-exists-p)
    (let ((serve-process cobalt--serve-process))
      (setq cobalt--serve-process nil)
      (when serve-process
	(kill-process serve-process)))))

(defun cobalt-preview-site ()
  "Preview the site."
  (interactive)
  (when (cobalt--executable-exists-p)
    (if (not cobalt--serve-process)
	(cobalt--log "No serve process is currently running! Call cobalt-serve first!" t)
      (browse-url "http://127.0.0.1:3000"))))

(defun cobalt-build (arg)
  "Builds the current site.
Specify a prefix argument (c-u) as ARG to include drafts."
  (interactive "P")
  (when (cobalt--executable-exists-p)
    (let ((default-directory cobalt--current-site))
      (call-process (executable-find "cobalt")
		    nil
		    cobalt-log-buffer-name
		    nil
		    "build"
		    (if (equal arg '(4))
			"--drafts"
		      "--no-drafts")))
    (cobalt--log (concat "Site built successfully. "
			(if (equal arg '(4))
			    "Drafts included."
			  "Drafts NOT included.")))))

(defun cobalt-new-post (post-title)
  "Ask for POST-TITLE and create a new post."
  (interactive "sWhat is the title of the post? ")
  (cobalt--new-post-with-title post-title t))

(defun cobalt--new-post-with-title (post-title open-file-on-success)
  "Create a new post with POST-TITLE.
Specify OPEN-FILE-ON-SUCCESS if you want to open the file in a buffer if successful."
  (when (cobalt--executable-exists-p)
    (when (not cobalt--current-site)
      (cobalt-change-current-site))
    (let ((default-directory cobalt--current-site)
	  (post-file-name (cobalt--convert-title-to-file-name post-title)))
      (apply 'call-process
	     (executable-find "cobalt")
	     nil
	     cobalt-log-buffer-name
	     nil
	     (list "new" "-f" (cobalt--get-posts-directory) post-title))
      (when open-file-on-success
	(if (not (file-exists-p (concat default-directory (cobalt--get-posts-directory) "/" post-file-name ".md")))
	    (cobalt--log (concat "Could not find file: " default-directory (cobalt--get-posts-directory) "/" post-file-name ".md") t)
	  (find-file (concat default-directory (cobalt--get-posts-directory) "/" post-file-name ".md"))
	  (cobalt-post-mode))))))

(defun cobalt-preview-current-post ()
  "Opens the current post buffer."
  (interactive)
  (when (not (bound-and-true-p cobalt-post-mode))
    (error "Command should only be called inside a CobaltPost buffer"))
  (when (cobalt--executable-exists-p)
    (if (not cobalt--serve-process)
	(cobalt--log "No serve process is currently running! Call cobalt-serve first!" t)
      (let* ((post-path (concat (car (butlast (split-string (buffer-name) "\\."))) ".html"))
	     (full-url (concat "http://127.0.0.1:3000/" (cobalt--get-posts-directory) "/" post-path)))
	(cobalt--log (concat "Previewing post: " full-url))
	(browse-url full-url)))))

(defun cobalt-publish ()
  "Publishes the current post buffer."
  (interactive)
  (when (cobalt--executable-exists-p)
    (apply 'call-process
	   (executable-find "cobalt")
	   nil
	   cobalt-log-buffer-name
	   nil
	   (list "publish" (buffer-name)))
    (cobalt--log (concat "Successfully published the post:" (buffer-name)))
    ))
  

(defun cobalt--executable-exists-p ()
  "Check if cobalt is installed.  Otherwise it prints a message."
  (if (executable-find "cobalt")
      t
    (cobalt--log "Cobalt cannot be found in the system." t)
    nil))

(defun cobalt--get-posts-directory ()
  "Get the posts dir configuration from the current site's _cobalt.yml file.
Returns \"posts\" if nothing is specified."
  (with-temp-buffer
    (insert-file-contents (concat cobalt--current-site "_cobalt.yml"))
    (goto-char (point-min))
    (if (not (search-forward "dir:" nil t))
	"posts"
      (let* ((start-pos (point))
	     (end-pos (progn (move-end-of-line 1)
			     (point))))
	(replace-regexp-in-string " " "" (buffer-substring-no-properties start-pos end-pos))))))

(defun cobalt--check-fix-site-path (site-path)
  "Add a trailing slash \"\\\" to the given SITE-PATH, if needed."
  (if (not site-path)
      nil
    (if (string= (substring site-path (- (length site-path) 1)) "/")
	site-path
      (concat site-path "/"))))

(defun cobalt--convert-title-to-file-name (post-title)
  "Convert the given POST-TITLE to a file name."
  (downcase (replace-regexp-in-string "^-\\|-$"
				      ""
				      (replace-regexp-in-string "--+"
							       "-"
							       (replace-regexp-in-string "[^A-Za-z0-9]"
											 "-"
											 post-title)))))

(defun cobalt--log (str &optional is-error)
  "Internal logger that logs STR to messages and the cobalt log buffer.
If &OPTIONAL IS-ERROR is non-nil then it will add a \"Error!\" before the error string."
  (let ((log-buffer (get-buffer-create cobalt-log-buffer-name)))
    (if is-error
	(message "Error! %s" str)
      (message "%s" str))

    (with-current-buffer log-buffer
      (goto-char (point-max))
      (open-line 1)
      (forward-line 1)
      (if is-error
	  (insert (concat "[cobalt.el] Error! " str))
	(insert (concat "[cobalt.el] " str))))))

(provide 'cobalt)
;;; cobalt.el ends here
