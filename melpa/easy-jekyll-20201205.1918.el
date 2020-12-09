;;; easy-jekyll.el --- Major mode managing jekyll blogs -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2020 by Masashi Miyaura

;; Author: Masashi Miyaura
;; URL: https://github.com/masasam/emacs-easy-jekyll
;; Package-Version: 20201205.1918
;; Package-Commit: b79176c6c4a8d5914e2c6e2bb53f61633ff5e023
;; Version: 2.4.30
;; Package-Requires: ((emacs "25.1") (request "0.3.0"))

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

;; Emacs major mode for writing blogs made with jekyll
;; You can publish your blog to the server or Github Pages
;; or Amazon S3 or Google Cloud Storage.

;;; Code:

(require 'cl-lib)
(require 'url)
(require 'request)

(defgroup easy-jekyll nil
  "Major mode managing jekyll blogs."
  :group 'tools)

(defgroup easy-jekyll-faces nil
  "Faces used in `easy-jekyll'"
  :group 'easy-jekyll :group 'faces)

(defcustom easy-jekyll-basedir nil
  "Directory where jekyll html source code is placed."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-preview-url "http://localhost:4000/"
  "Preview url of `easy-jekyll'."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-serve-flags ""
  "Additional flags to pass to jekyll serve."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-serve-flags2 ""
  "Additional flags to pass to jekyll serve."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-serve-value ""
  "Additional value to pass to jekyll serve."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-serve-value2 ""
  "Additional value to pass to jekyll serve."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-url nil
  "Url of the site operated by jekyll."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-sshdomain nil
  "Domain of jekyll at your ~/.ssh/config."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-root nil
  "Root directory of jekyll at your server."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-previewtime 300
  "Preview display time."
  :group 'easy-jekyll
  :type 'integer)

(defcustom easy-jekyll-image-directory "images"
  "Image file directory under 'static' directory."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-default-picture-directory "~"
  "Default directory for selecting images with `easy-jekyll-put-image'."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-amazon-s3-bucket-name nil
  "Amazon S3 bucket name."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-google-cloud-storage-bucket-name nil
  "Google Cloud Storage bucket name."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-default-ext ".md"
  "Default extension when posting new articles."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-helm-ag nil
  "Helm-ag use flg."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-no-help nil
  "No help flg of `easy-jekyll'."
  :group 'easy-jekyll
  :type 'integer)

(defcustom easy-jekyll-emacspeak nil
  "Emacspeak flg of `easy-jekyll'."
  :group 'easy-jekyll
  :type 'integer)

(defcustom easy-jekyll-additional-help nil
  "Additional help flg of `easy-jekyll'."
  :group 'easy-jekyll
  :type 'integer)

(defcustom easy-jekyll-sort-default-char t
  "Default setting to sort with charactor."
  :group 'easy-jekyll
  :type 'integer)

(defcustom easy-jekyll-publish-chmod "Du=rwx,Dgo=rx,Fu=rw,Fog=r"
  "Permission when publish.
The default is drwxr-xr-x."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-github-deploy-script "deploy.sh"
  "Github-deploy-script file name."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-markdown-extension "md"
  "Markdown extension."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-textile-extension "textile"
  "Textile extension."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-postdir "_posts"
  "Directory where stores its posts."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-rsync-delete-directory "_site/"
  "Disappear directory when synchronizing with rsync."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-rsync-flags "-rtpl"
  "Additional flags for rsync."
  :group 'easy-jekyll
  :type 'string)

(defcustom easy-jekyll-post-layout "post"
  "Default layout for a new post."
  :group 'easy-jekyll
  :type 'string
  )

(defcustom easy-jekyll-help-line 7
  "Number of lines of `easy-jekyll-help'."
  :group 'easy-jekyll
  :type 'integer)

(defcustom easy-jekyll-add-help-line 6
  "Number of lines of `easy-jekyll-add-help'."
  :group 'easy-jekyll
  :type 'integer)

(defvar easy-jekyll--current-postdir 0
  "Easy-jekyll current postdir.")

(defvar easy-jekyll--postdir-list nil
  "Easy-jekyll postdir list.")

(defvar easy-jekyll--preview-loop t
  "Preview loop flg.")

(defvar easy-jekyll--server-process nil
  "Jekyll process.")

(if easy-jekyll-no-help
    (defvar easy-jekyll--unmovable-line 3
      "Impossible to move below this line.")
  (defvar easy-jekyll--unmovable-line (+ easy-jekyll-help-line 4)
    "Impossible to move below this line."))

(defvar easy-jekyll--draft-list nil
  "Draft list flg.")

(defvar easy-jekyll--draft-mode nil
  "Display draft-mode.")

(defconst easy-jekyll--unmovable-line-default (+ easy-jekyll-help-line 4)
  "Default value of impossible to move below this line.")

(defconst easy-jekyll--buffer-name "*Jekyll Serve*"
  "Easy-jekyll buffer name.")

(defconst easy-jekyll--preview-buffer "*Jekyll Preview*"
  "Easy-jekyll preview buffer name.")

(defconst easy-jekyll--formats `(,easy-jekyll-markdown-extension
				 ,easy-jekyll-textile-extension))

(defface easy-jekyll-help-face
  `((((class color) (background light))
     ,@(and (>= emacs-major-version 27) '(:extend t))
     :inherit font-lock-function-name-face
     :background "#f0f8ff")
    (((class color) (background dark))
     ,@(and (>= emacs-major-version 27) '(:extend t))
     :inherit font-lock-function-name-face
     :background "#2f4f4f"))
  "Definition of help color."
  :group 'easy-jekyll-faces)

(defvar easy-jekyll--mode-buffer nil
  "Main buffer of `easy-jekyll'.")

(defvar easy-jekyll--cursor nil
  "Cursor of `easy-jekyll'.")

(defvar easy-jekyll--line nil
  "Line of `easy-jekyll'.")

(defvar easy-jekyll--sort-time-flg nil
  "Sort time flg of `easy-jekyll'.")

(defvar easy-jekyll--sort-char-flg 2
  "Sort char flg of `easy-jekyll'.")

(defvar easy-jekyll--refresh nil
  "Refresh flg of `easy-jekyll'.")

(defvar easy-jekyll--current-blog 0
  "Current blog number.")

(defcustom easy-jekyll-bloglist nil
  "Multiple blog setting."
  :group 'easy-jekyll
  :type 'string)

(push `((easy-jekyll-basedir . ,easy-jekyll-basedir)
	(easy-jekyll-url . ,easy-jekyll-url)
	(easy-jekyll-root . ,easy-jekyll-root)
	(easy-jekyll-sshdomain . ,easy-jekyll-sshdomain)
	(easy-jekyll-amazon-s3-bucket-name . ,easy-jekyll-amazon-s3-bucket-name)
	(easy-jekyll-google-cloud-storage-bucket-name . ,easy-jekyll-google-cloud-storage-bucket-name)
	(easy-jekyll-github-deploy-script . ,easy-jekyll-github-deploy-script)
	(easy-jekyll-image-directory . ,easy-jekyll-image-directory)
	(easy-jekyll-default-picture-directory . ,easy-jekyll-default-picture-directory)
	(easy-jekyll-publish-chmod . ,easy-jekyll-publish-chmod)
	(easy-jekyll-previewtime . ,easy-jekyll-previewtime)
	(easy-jekyll-preview-url . ,easy-jekyll-preview-url)
	(easy-jekyll-sort-default-char . ,easy-jekyll-sort-default-char)
	(easy-jekyll-textile-extension . ,easy-jekyll-textile-extension)
	(easy-jekyll-markdown-extension . ,easy-jekyll-markdown-extension)
	(easy-jekyll-default-ext . ,easy-jekyll-default-ext)
	(easy-jekyll-postdir . ,easy-jekyll-postdir))
      easy-jekyll-bloglist)

(defvar easy-jekyll--publish-timer-list
  (make-list (length easy-jekyll-bloglist) 'nil)
  "Timer list for cancel publish timer.")

(defvar easy-jekyll--firebase-deploy-timer-list
  (make-list (length easy-jekyll-bloglist) 'nil)
  "Timer list for cancel firebase deploy timer.")

(defvar easy-jekyll--github-deploy-timer-list
  (make-list (length easy-jekyll-bloglist) 'nil)
  "Timer list for cancel github deploy timer.")

(defvar easy-jekyll--amazon-s3-deploy-timer-list
  (make-list (length easy-jekyll-bloglist) 'nil)
  "Timer list for cancel amazon s3 deploy timer.")

(defvar easy-jekyll--google-cloud-storage-deploy-timer-list
  (make-list (length easy-jekyll-bloglist) 'nil)
  "Timer list for cancel google cloud storage deploy timer.")

(defconst easy-jekyll--default-github-deploy-script
  "deploy.sh"
  "Default `easy-jekyll' github-deploy-script.")

(defconst easy-jekyll--default-image-directory
  "images"
  "Default `easy-jekyll' image-directory.")

(defconst easy-jekyll--default-picture-directory
  "~"
  "Default `easy-jekyll' picture-directory.")

(defconst easy-jekyll--default-publish-chmod
  "Du=rwx,Dgo=rx,Fu=rw,Fog=r"
  "Default `easy-jekyll' publish-chmod.")

(defconst easy-jekyll--default-previewtime
  300
  "Default `easy-jekyll' previewtime.")

(defconst easy-jekyll--default-preview-url
  "http://localhost:4000/"
  "Default `easy-jekyll' preview-url.")

(defconst easy-jekyll--default-sort-default-char
  t
  "Default `easy-jekyll' sort-default-char.")

(defconst easy-jekyll--default-textile-extension
  "textile"
  "Default `easy-jekyll' textile-extension.")

(defconst easy-jekyll--default-markdown-extension
  "md"
  "Default `easy-jekyll' markdown-extension.")

(defconst easy-jekyll--default-postdir
  "_posts"
  "Default easy-jekyll-postdir.")

(defconst easy-jekyll--default-ext
  easy-jekyll-default-ext
  "Default `easy-jekyll' default-ext.")

(defconst easy-jekyll--buffer-name "*Easy-jekyll*"
  "Buffer name of `easy-jekyll'.")

(defconst easy-jekyll--forward-char 20
  "Forward-char of `easy-jekyll'.")

(defmacro easy-jekyll-with-env (&rest body)
  "Evaluate BODY with `default-directory' set to `easy-jekyll-basedir'.
Report an error if jekyll is not installed, or if `easy-jekyll-basedir' is unset."
  `(progn
     (unless easy-jekyll-basedir
       (error "Please set easy-jekyll-basedir variable"))
     (unless (executable-find "jekyll")
       (error "'jekyll' is not installed"))
     (let ((default-directory easy-jekyll-basedir))
       ,@body)))

(defmacro easy-jekyll-set-bloglist (body)
  "Macros to set variables to `easy-jekyll-bloglist' as BODY."
  `(setq ,body
	 (cdr (assoc ',body
		     (nth easy-jekyll--current-blog easy-jekyll-bloglist)))))

(defmacro easy-jekyll-eval-bloglist (body)
  "Macros to eval variables of BODY from `easy-jekyll-bloglist'."
  `(cdr (assoc ',body
	       (nth easy-jekyll--current-blog easy-jekyll-bloglist))))

(defmacro easy-jekyll-nth-eval-bloglist (body blog)
  "Macros to eval variables of BODY from `easy-jekyll-bloglist' at BLOG."
  `(cdr (assoc ',body
	       (nth ,blog easy-jekyll-bloglist))))

(defmacro easy-jekyll-ignore-error (condition &rest body)
  "Execute BODY; if the error CONDITION occurs, return nil.
Otherwise, return result of last form in BODY.

CONDITION can also be a list of error conditions."
  (declare (debug t) (indent 1))
  `(condition-case nil (progn ,@body) (,condition nil)))

;;;###autoload
(defun easy-jekyll-article ()
  "Open a list of articles written in jekyll with dired."
  (interactive)
  (unless easy-jekyll-basedir
    (error "Please set easy-jekyll-basedir variable"))
  (find-file (expand-file-name easy-jekyll-postdir easy-jekyll-basedir)))

;;;###autoload
(defun easy-jekyll-magit ()
  "Open magit at current blog."
  (interactive)
  (unless easy-jekyll-basedir
    (error "Please set easy-jekyll-basedir variable"))
  (if (require 'magit nil t)
      (magit-status-internal easy-jekyll-basedir)
    (error "'magit' is not installed")))

(defun easy-jekyll-emacspeak-filename ()
  "Read filename with emacspeak."
  (cl-declare (special emacspeak-speak-last-spoken-word-position))
  (let ((filename (substring (thing-at-point 'line) easy-jekyll--forward-char -1))
        (personality (dtk-get-style)))
    (cond
     (filename
      (dtk-speak (propertize filename 'personality personality))
      (setq emacspeak-speak-last-spoken-word-position (point)))
     (t (emacspeak-speak-line)))))

;;;###autoload
(defun easy-jekyll-image ()
  "Generate image link."
  (interactive
   (easy-jekyll-with-env
    (unless (file-directory-p (expand-file-name
			       easy-jekyll-image-directory
			       easy-jekyll-basedir))
      (error "%s does not exist" (expand-file-name
				  easy-jekyll-image-directory
				  easy-jekyll-basedir)))
    (let ((insert-default-directory nil))
      (let ((file (read-file-name "Image file: " nil
				  (expand-file-name
				   easy-jekyll-image-directory easy-jekyll-basedir)
				  t
				  (expand-file-name
				   easy-jekyll-image-directory easy-jekyll-basedir))))
	(insert (concat (format "<img src=\"%s%s\""
				easy-jekyll-url
				(concat
				 "/"
				 easy-jekyll-image-directory
				 "/"
				 (file-name-nondirectory file)))
			" alt=\"\" width=\"100%\"/>")))))))

;;;###autoload
(defun easy-jekyll-put-image ()
  "Move image to image directory and generate image link."
  (interactive
   (easy-jekyll-with-env
    (unless (file-directory-p (expand-file-name
			       easy-jekyll-image-directory
			       easy-jekyll-basedir))
      (error "%s does not exist" (expand-file-name
				  easy-jekyll-image-directory
				  easy-jekyll-basedir)))
    (let ((insert-default-directory nil))
      (let* ((file (read-file-name "Image file: " nil
				   (expand-file-name easy-jekyll-default-picture-directory)
				   t
				   (expand-file-name easy-jekyll-default-picture-directory)))
	     (putfile (expand-file-name
		       (file-name-nondirectory file)
		       easy-jekyll-image-directory)))
	(when (file-exists-p putfile)
	  (error "%s already exists!" putfile))
	(copy-file file putfile)
	(insert (concat (format "<img src=\"%s%s\""
				easy-jekyll-url
				(concat
				 "/"
				 easy-jekyll-image-directory
				 "/"
				 (file-name-nondirectory file)))
			" alt=\"\" width=\"100%\"/>")))))))

(defun easy-jekyll--request-image (url file)
  "Resuest image from URL and save file at the location of FILE."
  (request
   url
   :parser 'buffer-string
   :success
   (cl-function (lambda (&key data &allow-other-keys)
		  (when data
		    (with-current-buffer (get-buffer-create "*request image*")
		      (erase-buffer)
		      (insert data)
		      (write-file file)))))
   :error
   (cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
		  (message "Got error: %S" error-thrown)))))

;;;###autoload
(defun easy-jekyll-pull-image ()
  "Pull image from internet to image directory and generate image link."
  (interactive
   (easy-jekyll-with-env
    (unless (file-directory-p (expand-file-name
			       easy-jekyll-image-directory
			       easy-jekyll-basedir))
      (error "%s does not exist" (expand-file-name
				  easy-jekyll-image-directory
				  easy-jekyll-basedir)))
    (let ((url (read-string "URL: " (if (fboundp 'gui-get-selection)
					(gui-get-selection))))
	  (file (read-file-name "Save as: "
				(expand-file-name
				 easy-jekyll-image-directory
				 easy-jekyll-basedir)
				(car (last (split-string
					    (substring-no-properties (gui-get-selection))
					    "/")))
				nil)))
      (when (file-exists-p (file-truename file))
	(error "%s already exists!" (file-truename file)))
      (easy-jekyll--request-image url file)
      (insert (concat (format "<img src=\"%s%s\""
			      easy-jekyll-url
			      (concat
			       "/"
			       easy-jekyll-image-directory
			       "/"
			       (file-name-nondirectory file)))
		      " alt=\"\" width=\"100%\"/>"))))))

;;;###autoload
(defun easy-jekyll-publish-clever ()
  "Clever publish command.
Automatically select the deployment destination from init.el."
  (interactive)
  (easy-jekyll-with-env
   (cond ((easy-jekyll-eval-bloglist easy-jekyll-root)
	  (easy-jekyll-publish))
	 ((easy-jekyll-eval-bloglist easy-jekyll-amazon-s3-bucket-name)
	  (easy-jekyll-amazon-s3-deploy))
	 ((easy-jekyll-eval-bloglist easy-jekyll-google-cloud-storage-bucket-name)
	  (easy-jekyll-google-cloud-storage-deploy))
	 ((executable-find (expand-file-name
			    (if (easy-jekyll-eval-bloglist easy-jekyll-github-deploy-script)
				(easy-jekyll-eval-bloglist easy-jekyll-github-deploy-script)
			      easy-jekyll-github-deploy-script)
			    easy-jekyll-basedir))
	  (easy-jekyll-github-deploy))
	 ((executable-find "firebase")
	  (easy-jekyll-firebase-deploy))
	 (t (error "Nothing is found to publish at %s" easy-jekyll-basedir)))))

;;;###autoload
(defun easy-jekyll-publish ()
  "Adapt local change to the server with jekyll."
  (interactive)
  (unless easy-jekyll-sshdomain
    (error "Please set easy-jekyll-sshdomain variable"))
  (unless easy-jekyll-root
    (error "Please set easy-jekyll-root variable"))
  (unless (executable-find "rsync")
    (error "'rsync' is not installed"))
  (unless (file-exists-p "~/.ssh/config")
    (error "There is no ~/.ssh/config"))
  (easy-jekyll-with-env
   (when (file-directory-p "_site")
     (delete-directory "_site" t nil))
   (let ((ret (call-process "bundle" nil "*jekyll-publish*" t
			    "exec" "jekyll" "build" "--destination" "_site")))
     (unless (zerop ret)
       (switch-to-buffer (get-buffer "*jekyll-publish*"))
       (error "'bundle exec jekyll build' command does not end normally")))
   (when (get-buffer "*jekyll-publish*")
     (kill-buffer "*jekyll-publish*"))
   (let ((ret (call-process "rsync"
			    nil
			    "*jekyll-rsync*"
			    t
			    easy-jekyll-rsync-flags
			    (concat "--chmod=" easy-jekyll-publish-chmod)
			    "--delete"
			    easy-jekyll-rsync-delete-directory
			    (concat easy-jekyll-sshdomain ":" (shell-quote-argument easy-jekyll-root)))))
     (unless (zerop ret)
       (switch-to-buffer (get-buffer "*jekyll-rsync*"))
       (error "'rsync' command does not end normally")))
   (when (get-buffer "*jekyll-rsync*")
     (kill-buffer "*jekyll-rsync*"))
   (message "Blog published")
   (when easy-jekyll-url
     (browse-url easy-jekyll-url))))

;;;###autoload
(defun easy-jekyll-publish-timer (n)
  "A timer that publish after the specified number as N of minutes has elapsed."
  (interactive "nMinute:")
  (unless easy-jekyll-basedir
    (error "Please set easy-jekyll-basedir variable"))
  (unless (executable-find "jekyll")
    (error "'jekyll' is not installed"))
  (unless easy-jekyll-sshdomain
    (error "Please set easy-jekyll-sshdomain variable"))
  (unless easy-jekyll-root
    (error "Please set easy-jekyll-root variable"))
  (unless (executable-find "rsync")
    (error "'rsync' is not installed"))
  (unless (file-exists-p "~/.ssh/config")
    (error "There is no ~/.ssh/config"))
  (let ((blognum easy-jekyll--current-blog))
    (if (nth blognum easy-jekyll--publish-timer-list)
	(message "There is already reserved publish-timer on %s" easy-jekyll-url)
      (setf (nth easy-jekyll--current-blog easy-jekyll--publish-timer-list)
	    (run-at-time (* n 60) nil
			 #'(lambda () (easy-jekyll-publish-on-timer blognum)))))))

;;;###autoload
(defun easy-jekyll-cancel-publish-timer ()
  "Cancel timer that publish after the specified number of minutes has elapsed."
  (interactive)
  (if (nth easy-jekyll--current-blog easy-jekyll--publish-timer-list)
      (progn
	(cancel-timer (nth easy-jekyll--current-blog easy-jekyll--publish-timer-list))
	(setf (nth easy-jekyll--current-blog easy-jekyll--publish-timer-list) nil)
	(message "Publish-timer canceled on %s" easy-jekyll-url))
    (message "There is no reserved publish-timer on %s" easy-jekyll-url)))

(defun easy-jekyll-publish-on-timer (n)
  "Adapt local change to the server with jekyll on timer at N."
  (let ((default-directory (easy-jekyll-nth-eval-bloglist easy-jekyll-basedir n)))
    (when (file-directory-p "_site")
      (delete-directory "_site" t nil))
    (let ((ret (call-process "bundle" nil "*jekyll-publish*" t
			     "exec" "jekyll" "build" "--destination" "_site")))
      (unless (zerop ret)
	(switch-to-buffer (get-buffer "*jekyll-publish*"))
	(setf (nth n easy-jekyll--publish-timer-list) nil)
	(error "'bundle exec jekyll build' command does not end normally")))
    (when (get-buffer "*jekyll-publish*")
      (kill-buffer "*jekyll-publish*"))
    (let ((ret (call-process "rsync"
			     nil
			     "*jekyll-rsync*"
			     t
			     easy-jekyll-rsync-flags
			     (concat "--chmod=" easy-jekyll-publish-chmod)
			     "--delete"
			     easy-jekyll-rsync-delete-directory
			     (concat
			      (easy-jekyll-nth-eval-bloglist easy-jekyll-sshdomain n)
			      ":"
			      (shell-quote-argument
			       (easy-jekyll-nth-eval-bloglist easy-jekyll-root n))))))
      (unless (zerop ret)
	(switch-to-buffer (get-buffer "*jekyll-rsync*"))
	(error "'rsync' command does not end normally")))
    (when (get-buffer "*jekyll-rsync*")
      (kill-buffer "*jekyll-rsync*"))
    (message "Blog published")
    (when (easy-jekyll-nth-eval-bloglist easy-jekyll-url n)
      (browse-url (easy-jekyll-nth-eval-bloglist easy-jekyll-url n)))
    (setf (nth n easy-jekyll--publish-timer-list) nil)))

;;;###autoload
(defun easy-jekyll-firebase-deploy ()
  "Deploy jekyll source at firebase hosting."
  (interactive)
  (unless (executable-find "firebase")
    (error "'firebase-tools' is not installed"))
  (easy-jekyll-with-env
   (when (file-directory-p "public")
     (delete-directory "public" t nil))
   (let ((ret (call-process "bundle" nil "*jekyll-publish*" t
			    "exec" "jekyll" "build" "--destination" "public")))
     (unless (zerop ret)
       (switch-to-buffer (get-buffer "*jekyll-firebase*"))
       (error "'bundle exec jekyll build' command does not end normally")))
   (when (get-buffer "*jekyll-firebase*")
     (kill-buffer "*jekyll-firebase*"))
   (let ((ret (call-process "firebase"
			    nil
			    "*jekyll-firebase*"
			    t
			    "deploy")))
     (unless (zerop ret)
       (switch-to-buffer (get-buffer "*jekyll-firebase*"))
       (error "'firebase deploy' command does not end normally")))
   (when (get-buffer "*jekyll-firebase*")
     (kill-buffer "*jekyll-firebase*"))
   (message "Blog published")
   (when easy-jekyll-url
     (browse-url easy-jekyll-url))))

;;;###autoload
(defun easy-jekyll-firebase-deploy-timer (n)
  "A timer that firebase deploy after the specified number as N of minutes has elapsed."
  (interactive "nMinute:")
  (unless easy-jekyll-basedir
    (error "Please set easy-jekyll-basedir variable"))
  (unless (executable-find "jekyll")
    (error "'jekyll' is not installed"))
  (unless (executable-find "firebase")
    (error "'firebase-tools' is not installed"))
  (let ((blognum easy-jekyll--current-blog))
    (if (nth blognum easy-jekyll--firebase-deploy-timer-list)
	(message "There is already reserved firebase-deploy-timer on %s" easy-jekyll-url)
      (setf (nth easy-jekyll--current-blog easy-jekyll--firebase-deploy-timer-list)
	    (run-at-time (* n 60) nil
			 #'(lambda () (easy-jekyll-firebase-deploy-on-timer blognum)))))))

;;;###autoload
(defun easy-jekyll-cancel-firebase-deploy-timer ()
  "Cancel timer that firebase deploy after the specified number of minutes has elapsed."
  (interactive)
  (if (nth easy-jekyll--current-blog easy-jekyll--firebase-deploy-timer-list)
      (progn
	(cancel-timer (nth easy-jekyll--current-blog easy-jekyll--firebase-deploy-timer-list))
	(setf (nth easy-jekyll--current-blog easy-jekyll--firebase-deploy-timer-list) nil)
	(message "Firebase-deploy-timer canceled on %s" easy-jekyll-url))
    (message "There is no reserved firebase-deploy-timer on %s" easy-jekyll-url)))

(defun easy-jekyll-firebase-deploy-on-timer (n)
  "Deploy jekyll at firebase hosting on timer at N."
  (let ((default-directory (easy-jekyll-nth-eval-bloglist easy-jekyll-basedir n)))
    (when (file-directory-p "public")
      (delete-directory "public" t nil))
    (let ((ret (call-process "bundle" nil "*jekyll-firebase*" t
			     "exec" "jekyll" "build" "--destination" "public")))
      (unless (zerop ret)
	(switch-to-buffer (get-buffer "*jekyll-firebase*"))
	(setf (nth n easy-jekyll--firebase-deploy-timer-list) nil)
	(error "'bundle exec jekyll build' command does not end normally")))
    (when (get-buffer "*jekyll-firebase*")
      (kill-buffer "*jekyll-firebase*"))
    (let ((ret (call-process "firebase"
			     nil
			     "*jekyll-firebase*"
			     t
			     "deploy")))
      (unless (zerop ret)
	(switch-to-buffer (get-buffer "*jekyll-firebase*"))
	(error "'firebase deploy' command does not end normally")))
    (when (get-buffer "*jekyll-firebase*")
      (kill-buffer "*jekyll-firebase*"))
    (message "Blog published")
    (when (easy-jekyll-nth-eval-bloglist easy-jekyll-url n)
      (browse-url (easy-jekyll-nth-eval-bloglist easy-jekyll-url n)))
    (setf (nth n easy-jekyll--publish-timer-list) nil)))

(defun easy-jekyll--headers (file)
  "Return a draft header string for a new article as FILE."
  (let ((datetimezone
         (concat
          (format-time-string "%Y-%m-%d %T ")
          (format-time-string "%z"))))
    (concat
     "---"
     "\nlayout: " easy-jekyll-post-layout
     "\ntitle:  " file
     "\ndate:   " datetimezone
     "\n---\n")))

;;;###autoload
(defun easy-jekyll-newpost (post-file)
  "Create a new post with jekyll.
POST-FILE needs to have and extension '.md' or '.textile'."
  (interactive (list (read-from-minibuffer "Filename: " `(,easy-jekyll-default-ext . 1) nil nil nil)))
  (easy-jekyll-with-env
   (let ((filename (if easy-jekyll--draft-list
		       (expand-file-name post-file "_drafts")
		     (expand-file-name
		      (concat (format-time-string "%Y-%m-%d-" (current-time)) post-file)
		      easy-jekyll-postdir)))
	 (file-ext (file-name-extension post-file)))
     (when (not (member file-ext easy-jekyll--formats))
       (error "Please enter .%s file name or .%s file name"
	      easy-jekyll-markdown-extension easy-jekyll-textile-extension))
     (when (file-exists-p (file-truename filename))
       (error "%s already exists!" filename))
     (find-file filename)
     (insert (easy-jekyll--headers (file-name-base post-file)))
     (goto-char (point-max))
     (save-buffer))))

(defun easy-jekyll--version ()
  "Return the version of jekyll."
  (let ((source (split-string
		 (with-temp-buffer
		   (shell-command-to-string "bundle exec jekyll --version"))
		 " ")))
    (string-to-number (nth 1 source))))

;;;###autoload
(defun easy-jekyll-preview ()
  "Preview jekyll at localhost."
  (interactive)
  (easy-jekyll-with-env
   (if (process-live-p easy-jekyll--server-process)
       (browse-url easy-jekyll-preview-url)
     (progn
       (setq easy-jekyll--server-process
	     (start-process "jekyll-serve" easy-jekyll--preview-buffer
			    "bundle" "exec" "jekyll" "serve" easy-jekyll-serve-flags easy-jekyll-serve-value easy-jekyll-serve-flags2 easy-jekyll-serve-value2))
       (while easy-jekyll--preview-loop
	 (if (equal (easy-jekyll--preview-status) "200")
	     (progn
	       (setq easy-jekyll--preview-loop nil)
	       (browse-url easy-jekyll-preview-url)))
	 (sleep-for 0 100)
	 (if (and (eq (process-status easy-jekyll--server-process) 'exit)
		  (not (equal (process-exit-status easy-jekyll--server-process) 0)))
	     (progn
	       (switch-to-buffer easy-jekyll--preview-buffer)
	       (error "Jekyll error look at %s buffer" easy-jekyll--preview-buffer))))
       (setq easy-jekyll--preview-loop t)
       (run-at-time easy-jekyll-previewtime nil 'easy-jekyll--preview-end)))))

(defun easy-jekyll--preview-status ()
  "Return the http status code of the preview."
  (nth 1
       (split-string
	(nth 0
	     (split-string
	      (with-current-buffer
		  (easy-jekyll--url-retrieve-synchronously "http://127.0.0.1:4000/")
		(prog1
		    (buffer-string)
		  (kill-buffer)))
	      "\n"))
	" ")))

(defun easy-jekyll--url-retrieve-synchronously (url &optional silent inhibit-cookies)
  "Retrieve URL synchronously.
Return the buffer containing the data, or nil if there are no data
associated with it (the case for dired, info, or mailto URLs that need
no further processing).  URL is either a string or a parsed URL.
If SILENT is non-nil, don't display progress reports and similar messages.
If INHIBIT-COOKIES is non-nil, cookies will neither be stored nor sent
to the server."
  (url-do-setup)

  (let ((retrieval-done nil)
        (asynch-buffer nil))
    (setq asynch-buffer
	  (url-retrieve url (lambda (&rest ignored)
			      (url-debug 'retrieval "Synchronous fetching done (%S)" (current-buffer))
			      (setq retrieval-done t
				    asynch-buffer (current-buffer)))
			nil silent inhibit-cookies))
    (if (null asynch-buffer)
        ;; We do not need to do anything, it was a mailto or something
        ;; similar that takes processing completely outside of the URL
        ;; package.
        nil
      (let ((proc (get-buffer-process asynch-buffer)))
	;; If the access method was synchronous, `retrieval-done' should
	;; hopefully already be set to t.  If it is nil, and `proc' is also
	;; nil, it implies that the async process is not running in
	;; asynch-buffer.  This happens e.g. for FTP files.  In such a case
	;; url-file.el should probably set something like a `url-process'
	;; buffer-local variable so we can find the exact process that we
	;; should be waiting for.  In the mean time, we'll just wait for any
	;; process output.
	(while (not retrieval-done)
	  (url-debug 'retrieval
		     "Spinning in url-retrieve-synchronously: %S (%S)"
		     retrieval-done asynch-buffer)
          (if (buffer-local-value 'url-redirect-buffer asynch-buffer)
              (setq proc (get-buffer-process
                          (setq asynch-buffer
                                (buffer-local-value 'url-redirect-buffer
                                                    asynch-buffer))))
            (if (and proc (memq (process-status proc)
                                '(closed exit signal failed))
                     ;; Make sure another process hasn't been started.
                     (eq proc (or (get-buffer-process asynch-buffer) proc)))
                ;; FIXME: It's not clear whether url-retrieve's callback is
                ;; guaranteed to be called or not.  It seems that url-http
                ;; decides sometimes consciously not to call it, so it's not
                ;; clear that it's a bug, but even then we need to decide how
                ;; url-http can then warn us that the download has completed.
                ;; In the mean time, we use this here workaround.
		;; XXX: The callback must always be called.  Any
		;; exception is a bug that should be fixed, not worked
		;; around.
		(progn ;; Call delete-process so we run any sentinel now.
		  (delete-process proc)
		  (setq retrieval-done t)))
            ;; We used to use `sit-for' here, but in some cases it wouldn't
            ;; work because apparently pending keyboard input would always
            ;; interrupt it before it got a chance to handle process input.
            ;; `sleep-for' was tried but it lead to other forms of
            ;; hanging.  --Stef
            (unless (or (with-local-quit
			  (accept-process-output proc))
			(null proc))
              ;; accept-process-output returned nil, maybe because the process
              ;; exited (and may have been replaced with another).  If we got
	      ;; a quit, just stop.
	      (when quit-flag
		(delete-process proc))
              (setq proc (and (not quit-flag)
			      (get-buffer-process asynch-buffer)))))))
      asynch-buffer)))

(defun easy-jekyll--preview-end ()
  "Finish previewing jekyll at localhost."
  (unless (null easy-jekyll--server-process)
    (delete-process easy-jekyll--server-process))
  (when (get-buffer easy-jekyll--preview-buffer)
    (kill-buffer easy-jekyll--preview-buffer)))

;;;###autoload
(defun easy-jekyll-github-deploy ()
  "Execute `easy-jekyll-github-deploy-script' script locate at `easy-jekyll-basedir'."
  (interactive)
  (easy-jekyll-with-env
   (let ((deployscript (file-truename (expand-file-name
				       easy-jekyll-github-deploy-script
				       easy-jekyll-basedir))))
     (unless (executable-find deployscript)
       (error "%s do not execute" deployscript))
     (let ((ret (call-process
		 deployscript nil "*jekyll-github-deploy*" t)))
       (unless (zerop ret)
	 (switch-to-buffer (get-buffer "*jekyll-github-deploy*"))
	 (error "%s command does not end normally" deployscript)))
     (when (get-buffer "*jekyll-github-deploy*")
       (kill-buffer "*jekyll-github-deploy*"))
     (message "Blog deployed")
     (when easy-jekyll-url
       (browse-url easy-jekyll-url)))))

;;;###autoload
(defun easy-jekyll-github-deploy-timer (n)
  "A timer that github-deploy after the specified number as N of minutes has elapsed."
  (interactive "nMinute:")
  (unless easy-jekyll-basedir
    (error "Please set easy-jekyll-basedir variable"))
  (unless (executable-find "jekyll")
    (error "'jekyll' is not installed"))
  (let ((deployscript (file-truename (expand-file-name
				      easy-jekyll-github-deploy-script
				      easy-jekyll-basedir)))
	(blognum easy-jekyll--current-blog))
    (unless (executable-find deployscript)
      (error "%s do not execute" deployscript))
    (if (nth blognum easy-jekyll--github-deploy-timer-list)
	(message "There is already reserved github-deloy-timer on %s" easy-jekyll-url)
      (setf (nth easy-jekyll--current-blog easy-jekyll--github-deploy-timer-list)
	    (run-at-time (* n 60) nil
			 #'(lambda () (easy-jekyll-github-deploy-on-timer blognum)))))))

;;;###autoload
(defun easy-jekyll-cancel-github-deploy-timer ()
  "Cancel timer that github-deploy after the specified number of minutes has elapsed."
  (interactive)
  (if (nth easy-jekyll--current-blog easy-jekyll--github-deploy-timer-list)
      (progn
	(cancel-timer (nth easy-jekyll--current-blog easy-jekyll--github-deploy-timer-list))
	(setf (nth easy-jekyll--current-blog easy-jekyll--github-deploy-timer-list) nil)
	(message "Github-deploy-timer canceled on %s" easy-jekyll-url))
    (message "There is no reserved github-deploy-timer on %s" easy-jekyll-url)))

(defun easy-jekyll-github-deploy-on-timer (n)
  "Execute `easy-jekyll-github-deploy-script' script on timer locate at `easy-jekyll-basedir' at N."
  (let* ((deployscript (file-truename
			(expand-file-name
			 (if (easy-jekyll-nth-eval-bloglist easy-jekyll-github-deploy-script n)
			     (easy-jekyll-nth-eval-bloglist easy-jekyll-github-deploy-script n)
			   easy-jekyll--default-github-deploy-script)
			 (easy-jekyll-nth-eval-bloglist easy-jekyll-basedir n))))
	 (default-directory (easy-jekyll-nth-eval-bloglist easy-jekyll-basedir n))
	 (ret (call-process
	       deployscript nil "*jekyll-github-deploy*" t))
	 (default-directory easy-jekyll-basedir))
    (unless (zerop ret)
      (switch-to-buffer (get-buffer "*jekyll-github-deploy*"))
      (setf (nth n easy-jekyll--github-deploy-timer-list) nil)
      (error "%s command does not end normally" deployscript)))
  (when (get-buffer "*jekyll-github-deploy*")
    (kill-buffer "*jekyll-github-deploy*"))
  (message "Blog deployed")
  (when (easy-jekyll-nth-eval-bloglist easy-jekyll-url n)
    (browse-url (easy-jekyll-nth-eval-bloglist  easy-jekyll-url n)))
  (setf (nth n easy-jekyll--github-deploy-timer-list) nil))

;;;###autoload
(defun easy-jekyll-amazon-s3-deploy ()
  "Deploy jekyll source at Amazon S3."
  (interactive)
  (easy-jekyll-with-env
   (unless (executable-find "aws")
     (error "'aws' is not installed"))
   (unless easy-jekyll-amazon-s3-bucket-name
     (error "Please set 'easy-jekyll-amazon-s3-bucket-name' variable"))
   (when (file-directory-p "_site")
     (delete-directory "_site" t nil))
   (let ((ret (call-process "bundle" nil "*jekyll-amazon-s3-deploy*" t
			    "exec" "jekyll" "build" "--destination" "_site")))
     (unless (zerop ret)
       (switch-to-buffer (get-buffer "*jekyll-amazon-s3-deploy*"))
       (error "'bundle exec jekyll build' command does not end normally")))
   (when (get-buffer "*jekyll-amazon-s3-deploy*")
     (kill-buffer "*jekyll-amazon-s3-deploy*"))
   (shell-command-to-string
    (concat "aws s3 sync --delete _site s3://" easy-jekyll-amazon-s3-bucket-name "/"))
   (message "Blog deployed")
   (when easy-jekyll-url
     (browse-url easy-jekyll-url))))

;;;###autoload
(defun easy-jekyll-amazon-s3-deploy-timer (n)
  "A timer that amazon-s3-deploy after the specified number as N of minutes has elapsed."
  (interactive "nMinute:")
  (unless easy-jekyll-basedir
    (error "Please set easy-jekyll-basedir variable"))
  (unless (executable-find "jekyll")
    (error "'jekyll' is not installed"))
  (unless (executable-find "aws")
    (error "'aws' is not installed"))
  (unless easy-jekyll-amazon-s3-bucket-name
    (error "Please set 'easy-jekyll-amazon-s3-bucket-name' variable"))
  (let ((blognum easy-jekyll--current-blog))
    (if (nth blognum easy-jekyll--amazon-s3-deploy-timer-list)
	(message "There is already reserved AWS-s3-deploy-timer on %s" easy-jekyll-url)
      (setf (nth easy-jekyll--current-blog easy-jekyll--amazon-s3-deploy-timer-list)
	    (run-at-time (* n 60) nil
			 #'(lambda () (easy-jekyll-amazon-s3-deploy-on-timer blognum)))))))

;;;###autoload
(defun easy-jekyll-cancel-amazon-s3-deploy-timer ()
  "Cancel timer that amazon-s3-deploy after the specified number of minutes has elapsed."
  (interactive)
  (if (nth easy-jekyll--current-blog easy-jekyll--amazon-s3-deploy-timer-list)
      (progn
	(cancel-timer (nth easy-jekyll--current-blog easy-jekyll--amazon-s3-deploy-timer-list))
	(setf (nth easy-jekyll--current-blog easy-jekyll--amazon-s3-deploy-timer-list) nil)
	(message "AWS-s3-deploy-timer canceled on %s" easy-jekyll-url))
    (message "There is no reserved AWS-s3-deploy-timer on %s" easy-jekyll-url)))

(defun easy-jekyll-amazon-s3-deploy-on-timer (n)
  "Deploy jekyll source at Amazon S3 on timer at N."
  (let* ((default-directory (easy-jekyll-nth-eval-bloglist easy-jekyll-basedir n))
	 (ret (call-process "bundle" nil "*jekyll-amazon-s3-deploy*" t
			    "exec" "jekyll" "build" "--destination" "_site"))
	 (default-directory easy-jekyll-basedir))
    (unless (zerop ret)
      (switch-to-buffer (get-buffer "*jekyll-amazon-s3-deploy*"))
      (setf (nth n easy-jekyll--amazon-s3-deploy-timer-list) nil)
      (error "'bundle exec jekyll build' command does not end normally")))
  (when (get-buffer "*jekyll-amazon-s3-deploy*")
    (kill-buffer "*jekyll-amazon-s3-deploy*"))
  (setq default-directory
	(easy-jekyll-nth-eval-bloglist easy-jekyll-basedir n))
  (shell-command-to-string
   (concat "aws s3 sync --delete _site s3://" easy-jekyll-amazon-s3-bucket-name "/"))
  (setq default-directory easy-jekyll-basedir)
  (message "Blog deployed")
  (when (easy-jekyll-nth-eval-bloglist easy-jekyll-url n)
    (browse-url (easy-jekyll-nth-eval-bloglist easy-jekyll-url n)))
  (setf (nth n easy-jekyll--amazon-s3-deploy-timer-list) nil))

;;;###autoload
(defun easy-jekyll-google-cloud-storage-deploy ()
  "Deploy jekyll source at Google Cloud Storage."
  (interactive)
  (easy-jekyll-with-env
   (unless (executable-find "gsutil")
     (error "'Google Cloud SDK' is not installed"))
   (unless easy-jekyll-google-cloud-storage-bucket-name
     (error "Please set 'easy-jekyll-google-cloud-storage-bucket-name' variable"))
   (when (file-directory-p "_site")
     (delete-directory "_site" t nil))
   (let ((ret (call-process "bundle" nil "*jekyll-google-cloud-storage-deploy*" t
			    "exec" "jekyll" "build" "--destination" "_site")))
     (unless (zerop ret)
       (switch-to-buffer (get-buffer "*jekyll-google-cloud-storage-deploy*"))
       (error "'bundle exec jekyll build' command does not end normally")))
   (when (get-buffer "*jekyll-google-cloud-storage-deploy*")
     (kill-buffer "*jekyll-google-cloud-storage-deploy*"))
   (shell-command-to-string
    (concat "gsutil -m rsync -d -r _site gs://" easy-jekyll-google-cloud-storage-bucket-name "/"))
   (message "Blog deployed")
   (when easy-jekyll-url
     (browse-url easy-jekyll-url))))

;;;###autoload
(defun easy-jekyll-google-cloud-storage-deploy-timer (n)
  "A timer that google-cloud-storage-deploy after the specified number as N of minutes has elapsed."
  (interactive "nMinute:")
  (unless easy-jekyll-basedir
    (error "Please set easy-jekyll-basedir variable"))
  (unless (executable-find "jekyll")
    (error "'jekyll' is not installed"))
  (unless (executable-find "gsutil")
    (error "'Google Cloud SDK' is not installed"))
  (unless easy-jekyll-google-cloud-storage-bucket-name
    (error "Please set 'easy-jekyll-google-cloud-storage-bucket-name' variable"))
  (let ((blognum easy-jekyll--current-blog))
    (if (nth blognum easy-jekyll--google-cloud-storage-deploy-timer-list)
	(message "There is already reserved google-cloud-storage-deploy-timer on %s" easy-jekyll-url)
      (setf (nth easy-jekyll--current-blog easy-jekyll--google-cloud-storage-deploy-timer-list)
	    (run-at-time (* n 60) nil
			 #'(lambda () (easy-jekyll-google-cloud-storage-deploy-on-timer blognum)))))))

;;;###autoload
(defun easy-jekyll-cancel-google-cloud-storage-deploy-timer ()
  "Cancel timer that google-cloud-storage-deploy after the specified number of minutes has elapsed."
  (interactive)
  (if (nth easy-jekyll--current-blog easy-jekyll--google-cloud-storage-deploy-timer-list)
      (progn
	(cancel-timer (nth easy-jekyll--current-blog easy-jekyll--google-cloud-storage-deploy-timer-list))
	(setf (nth easy-jekyll--current-blog easy-jekyll--google-cloud-storage-deploy-timer-list) nil)
	(message "GCS-timer canceled on %s" easy-jekyll-url))
    (message "There is no reserved GCS-timer on %s" easy-jekyll-url)))

(defun easy-jekyll-google-cloud-storage-deploy-on-timer (n)
  "Deploy jekyll source at Google Cloud Storage on timer at N."
  (let* ((default-directory (easy-jekyll-nth-eval-bloglist easy-jekyll-basedir n))
	 (ret (call-process "bundle" nil "*jekyll-google-cloud-storage-deploy*" t
			    "exec" "jekyll" "build" "--destination" "_site"))
	 (default-directory easy-jekyll-basedir))
    (unless (zerop ret)
      (switch-to-buffer (get-buffer "*jekyll-google-cloud-storage-deploy*"))
      (setf (nth n easy-jekyll--google-cloud-storage-deploy-timer-list) nil)
      (error "'bundle exec jekyll build' command does not end normally")))
  (when (get-buffer "*jekyll-google-cloud-storage-deploy*")
    (kill-buffer "*jekyll-google-cloud-storage-deploy*"))
  (setq default-directory (easy-jekyll-nth-eval-bloglist easy-jekyll-basedir n))
  (shell-command-to-string
   (concat "gsutil -m rsync -d -r _site gs://"
	   (easy-jekyll-nth-eval-bloglist easy-jekyll-google-cloud-storage-bucket-name n)
	   "/"))
  (setq default-directory easy-jekyll-basedir)
  (message "Blog deployed")
  (when (easy-jekyll-nth-eval-bloglist easy-jekyll-url n)
    (browse-url (easy-jekyll-nth-eval-bloglist easy-jekyll-url n)))
  (setf (nth n easy-jekyll--google-cloud-storage-deploy-timer-list) nil))

;;;###autoload
(defun easy-jekyll-ag ()
  "Search for blog article with `counsel-ag' or `helm-ag'."
  (interactive)
  (easy-jekyll-with-env
   (if (and (require 'counsel nil t) (not easy-jekyll-helm-ag))
       (counsel-ag nil (expand-file-name easy-jekyll-postdir easy-jekyll-basedir))
     (if (require 'helm-ag nil t)
	 (helm-ag (expand-file-name easy-jekyll-postdir easy-jekyll-basedir))
       (error "'counsel' or 'helm-ag' is not installed")))))

;;;###autoload
(defun easy-jekyll-open-config ()
  "Open Jekyll's config file."
  (interactive)
  (easy-jekyll-with-env
   (cond ((file-exists-p (expand-file-name "_config.yml" easy-jekyll-basedir))
	  (find-file (expand-file-name "_config.yml" easy-jekyll-basedir)))
	 (t (error "Jekyll config file not found at %s" easy-jekyll-basedir)))))

(defcustom easy-jekyll-help
  (if (null easy-jekyll-sort-default-char)
      (progn
	"n .. New blog post    R .. Rename file   G .. Deploy GitHub    ? .. Help easy-jekyll
p .. Preview          g .. Refresh       A .. Deploy AWS S3    u .. Undraft file
v .. Open view-mode   s .. Sort time     T .. Publish timer    W .. AWS S3 timer
d .. Delete post      c .. Open config   D .. Draft list       f .. Select filename
P .. Publish clever   C .. Deploy GCS    a .. Search with ag   H .. GitHub timer
< .. Previous blog    > .. Next blog     , .. Pre postdir      . .. Next postdir
F .. Full help [tab]  ; .. Select blog   / .. Select postdir   q .. Quit easy-jekyll
")
    (progn
      "n .. New blog post    R .. Rename file   G .. Deploy GitHub    N .. No help-mode
p .. Preview          g .. Refresh       A .. Deploy AWS S3    s .. Sort character
v .. Open view-mode   D .. Draft list    T .. Publish timer    W .. AWS S3 timer
d .. Delete post      c .. Open config   u .. Undraft file     f .. Select filename
P .. Publish clever   C .. Deploy GCS    a .. Search with ag   H .. GitHub timer
< .. Previous blog    > .. Next blog     , .. Pre postdir      . .. Next postdir
F .. Full help [tab]  ; .. Select blog   / .. Select postdir   q .. Quit easy-jekyll
"))
  "Help of `easy-jekyll'."
  :group 'easy-jekyll
  :type 'string)

(defconst easy-jekyll--first-help
  "Welcome to Easy-jekyll

Let's post an article first.
Press n on this screen or M-x easy-jekyll-newpost.
Enter a article file name in the minibuffer.
Then M-x easy-jekyll again or refresh the screen with r or g key in this buffer,
article which you wrote should appear here.
Enjoy!

"
  "Help of `easy-jekyll' first time.")

(defcustom easy-jekyll-add-help
  (if (null easy-jekyll-sort-default-char)
      (progn
	"O .. Open basedir     r .. Refresh       b .. X github timer   t .. X publish-timer
k .. Previous-line    j .. Next line     h .. backward-char    l .. forward-char
m .. X s3-timer       i .. X GCS timer   I .. GCS timer        V .. View other window
- .. Pre postdir      + .. Next postdir  w .. Write post       o .. Open other window
J .. Jump blog        e .. Edit file     B .. Firebase deploy  ! .. X firebase timer
L .. Firebase timer   S .. Sort char     M .. Magit status     ? .. Describe-mode
")
    (progn
      "O .. Open basedir     r .. Refresh       b .. X github timer   t .. X publish-timer
k .. Previous-line    j .. Next line     h .. backward-char    l .. forward-char
m .. X s3-timer       i .. X GCS timer   I .. GCS timer        V .. View other window
- .. Pre postdir      + .. Next postdir  w .. Write post       o .. Open other window
J .. Jump blog        e .. Edit file     B .. Firebase deploy  ! .. X firebase timer
L .. Firebase timer   S .. Sort time     M .. Magit status     ? .. Describe-mode
"))
  "Add help of `easy-jekyll'."
  :group 'easy-jekyll
  :type 'string)

(defvar easy-jekyll-mode-map
  (let ((map (make-keymap)))
    (define-key map "." 'easy-jekyll-next-postdir)
    (define-key map "," 'easy-jekyll-previous-postdir)
    (define-key map "+" 'easy-jekyll-next-postdir)
    (define-key map "-" 'easy-jekyll-previous-postdir)
    (define-key map "n" 'easy-jekyll-newpost)
    (define-key map "w" 'easy-jekyll-newpost)
    (define-key map "a" 'easy-jekyll-ag)
    (define-key map "M" 'easy-jekyll-magit)
    (define-key map "c" 'easy-jekyll-open-config)
    (define-key map "p" 'easy-jekyll-preview)
    (define-key map "P" 'easy-jekyll-publish-clever)
    (define-key map "T" 'easy-jekyll-publish-timer)
    (define-key map "W" 'easy-jekyll-amazon-s3-deploy-timer)
    (define-key map "t" 'easy-jekyll-cancel-publish-timer)
    (define-key map "o" 'easy-jekyll-open-other-window)
    (define-key map "O" 'easy-jekyll-open-basedir)
    (define-key map "R" 'easy-jekyll-rename)
    (define-key map "\C-m" 'easy-jekyll-open)
    (put 'easy-jekyll-open :advertised-binding "\C-m")
    (define-key map "d" 'easy-jekyll-delete)
    (define-key map "e" 'easy-jekyll-open)
    (define-key map "f" 'easy-jekyll-select-filename)
    (define-key map "F" 'easy-jekyll-full-help)
    (define-key map [tab] 'easy-jekyll-full-help)
    (define-key map [backtab] 'easy-jekyll-no-help)
    (define-key map "N" 'easy-jekyll-no-help)
    (define-key map "J" 'easy-jekyll-nth-blog)
    (define-key map "j" 'easy-jekyll-next-line)
    (define-key map "k" 'easy-jekyll-previous-line)
    (define-key map "h" 'easy-jekyll-backward-char)
    (define-key map "l" 'easy-jekyll-forward-char)
    (define-key map " " 'easy-jekyll-next-line)
    (define-key map [?\S-\ ] 'easy-jekyll-previous-line)
    (define-key map [remap next-line] 'easy-jekyll-next-line)
    (define-key map [remap previous-line] 'easy-jekyll-previous-line)
    (define-key map [remap forward-char] 'easy-jekyll-forward-char)
    (define-key map [remap backward-char] 'easy-jekyll-backward-char)
    (define-key map [remap beginning-of-buffer] 'easy-jekyll-beginning-of-buffer)
    (define-key map [remap backward-word] 'easy-jekyll-backward-word)
    (define-key map [right] 'easy-jekyll-forward-char)
    (define-key map [left] 'easy-jekyll-backward-char)
    (define-key map "v" 'easy-jekyll-view)
    (define-key map "V" 'easy-jekyll-view-other-window)
    (define-key map "r" 'easy-jekyll-refresh)
    (define-key map "g" 'easy-jekyll-refresh)
    (if (null easy-jekyll-sort-default-char)
	(progn
	  (define-key map "s" 'easy-jekyll-sort-time)
	  (define-key map "S" 'easy-jekyll-sort-char))
      (progn
	(define-key map "S" 'easy-jekyll-sort-time)
	(define-key map "s" 'easy-jekyll-sort-char)))
    (define-key map "B" 'easy-jekyll-firebase-deploy)
    (define-key map "L" 'easy-jekyll-firebase-deploy-timer)
    (define-key map "!" 'easy-jekyll-cancel-firebase-deploy-timer)
    (define-key map "G" 'easy-jekyll-github-deploy)
    (define-key map "H" 'easy-jekyll-github-deploy-timer)
    (define-key map "b" 'easy-jekyll-cancel-github-deploy-timer)
    (define-key map "A" 'easy-jekyll-amazon-s3-deploy)
    (define-key map "m" 'easy-jekyll-cancel-amazon-s3-deploy-timer)
    (define-key map "C" 'easy-jekyll-google-cloud-storage-deploy)
    (define-key map "I" 'easy-jekyll-google-cloud-storage-deploy-timer)
    (define-key map "i" 'easy-jekyll-cancel-google-cloud-storage-deploy-timer)
    (define-key map "D" 'easy-jekyll-list-draft)
    (define-key map "u" 'easy-jekyll-undraft)
    (define-key map "q" 'easy-jekyll-quit)
    (define-key map "/" 'easy-jekyll-select-postdir)
    (define-key map ";" 'easy-jekyll-select-blog)
    (define-key map "<" 'easy-jekyll-previous-blog)
    (define-key map ">" 'easy-jekyll-next-blog)
    map)
  "Keymap for `easy-jekyll' major mode.")

(define-derived-mode easy-jekyll-mode special-mode "Easy-jekyll"
  "Major mode for easy jekyll.")

(defun easy-jekyll-quit ()
  "Quit easy jekyll."
  (interactive)
  (setq easy-jekyll--sort-time-flg nil)
  (setq easy-jekyll--sort-char-flg 2)
  (easy-jekyll--preview-end)
  (when (buffer-live-p easy-jekyll--mode-buffer)
    (kill-buffer easy-jekyll--mode-buffer)))

(defun easy-jekyll-no-help ()
  "No help easy jekyll."
  (interactive)
  (if easy-jekyll-no-help
      (progn
	(setq easy-jekyll-no-help nil)
	(setq easy-jekyll--unmovable-line easy-jekyll--unmovable-line-default))
    (progn
      (setq easy-jekyll-no-help 1)
      (setq easy-jekyll-additional-help nil)
      (setq easy-jekyll--unmovable-line 3)))
  (if easy-jekyll--draft-list
      (easy-jekyll-draft-list)
    (easy-jekyll)))

(defun easy-jekyll-full-help ()
  "Full help mode of easy jekyll."
  (interactive)
  (if easy-jekyll-additional-help
      (progn
	(setq easy-jekyll-additional-help nil)
	(setq easy-jekyll--unmovable-line easy-jekyll--unmovable-line-default))
    (progn
      (setq easy-jekyll-additional-help 1)
      (setq easy-jekyll-no-help nil)
      (setq easy-jekyll--unmovable-line
	    (+ easy-jekyll-help-line easy-jekyll-add-help-line 4))))
  (if easy-jekyll--draft-list
      (easy-jekyll-draft-list)
    (easy-jekyll)))

(defun easy-jekyll-list-draft ()
  "List drafts."
  (interactive)
  (if easy-jekyll--draft-list
      (progn
	(setq easy-jekyll--draft-list nil)
	(setq easy-jekyll--draft-mode nil)
	(easy-jekyll))
    (progn
      (setq easy-jekyll--draft-list 1)
      (setq easy-jekyll--draft-mode "  Draft")
      (easy-jekyll-draft-list))))

(defun easy-jekyll-refresh ()
  "Refresh easy-jekyll-mode."
  (interactive)
  (setq easy-jekyll--cursor (point))
  (setq easy-jekyll--refresh 1)
  (if easy-jekyll--draft-list
      (easy-jekyll-draft-list)
    (easy-jekyll))
  (setq easy-jekyll--refresh nil))

(defun easy-jekyll-sort-time ()
  "Sort article by time on easy-jekyll-mode."
  (interactive)
  (if easy-jekyll--draft-list
      (progn
	(setq easy-jekyll--sort-char-flg nil)
	(if (eq 1 easy-jekyll--sort-time-flg)
	    (setq easy-jekyll--sort-time-flg 2)
	  (setq easy-jekyll--sort-time-flg 1))
	(easy-jekyll-draft-list))
    (progn
      (setq easy-jekyll--sort-char-flg nil)
      (if (eq 1 easy-jekyll--sort-time-flg)
	  (setq easy-jekyll--sort-time-flg 2)
	(setq easy-jekyll--sort-time-flg 1))
      (easy-jekyll))))

(defun easy-jekyll-sort-char ()
  "Sort article by characters on easy-jekyll-mode."
  (interactive)
  (if easy-jekyll--draft-list
      (progn
	(setq easy-jekyll--sort-time-flg nil)
	(if (eq 1 easy-jekyll--sort-char-flg)
	    (setq easy-jekyll--sort-char-flg 2)
	  (setq easy-jekyll--sort-char-flg 1))
	(easy-jekyll-draft-list))
    (progn
      (setq easy-jekyll--sort-time-flg nil)
      (if (eq 1 easy-jekyll--sort-char-flg)
	  (setq easy-jekyll--sort-char-flg 2)
	(setq easy-jekyll--sort-char-flg 1))
      (easy-jekyll))))

(defun easy-jekyll-forward-char (arg)
  "Forward-char on easy-jekyll-mode.
Optional prefix ARG says how many lines to move.
default is one line."
  (interactive "^p")
  (when (not (eolp))
    (forward-char (or arg 1))))

(defun easy-jekyll-backward-char (arg)
  "Backward-char on easy-jekyll-mode.
Optional prefix ARG says how many lines to move.
default is one line."
  (interactive "^p")
  (when (not (bolp))
    (backward-char (or arg 1))))

(defun easy-jekyll-beginning-of-buffer ()
  "Easy-jekyll beginning-of-buffer."
  (interactive)
  (goto-char (point-min))
  (forward-line (- easy-jekyll--unmovable-line 1))
  (forward-char easy-jekyll--forward-char)
  (when easy-jekyll-emacspeak
    (easy-jekyll-emacspeak-filename)))

(defun easy-jekyll-backward-word (&optional arg)
  "Easy-jekyll backward-word.
Optional prefix ARG says how many lines to move.
default is one line."
  (interactive "^p")
  (forward-word (- (or arg 1)))
  (if (< (line-number-at-pos) easy-jekyll--unmovable-line)
      (progn
	(goto-char (point-min))
	(forward-line (- easy-jekyll--unmovable-line 1)))))

(defun easy-jekyll-next-line (arg)
  "Move down lines then position at filename.
Optional prefix ARG says how many lines to move; default is one line."
  (interactive "^p")
  (let ((line-move-visual)
	(goal-column))
    (line-move arg t))
  (while (and (invisible-p (point))
	      (not (if (and arg (< arg 0)) (bobp) (eobp))))
    (forward-char (if (and arg (< arg 0)) -1 1)))
  (beginning-of-line)
  (forward-char easy-jekyll--forward-char)
  (when easy-jekyll-emacspeak
    (easy-jekyll-emacspeak-filename)))

(defun easy-jekyll-previous-line (arg)
  "Move up lines then position at filename.
Optional prefix ARG says how many lines to move; default is one line."
  (interactive "^p")
  (when (>= (- (line-number-at-pos) arg) easy-jekyll--unmovable-line)
    (easy-jekyll-next-line (- (or arg 1)))))

(defun easy-jekyll-rename (post-file)
  "Renames file on the pointer to POST-FILE."
  (interactive (list (read-from-minibuffer "Rename: " `(,easy-jekyll-default-ext . 1) nil nil nil)))
  (easy-jekyll-with-env
   (let ((newname (if easy-jekyll--draft-list
		      (expand-file-name post-file "_drafts")
		    (expand-file-name post-file easy-jekyll-postdir)))
	 (file-ext (file-name-extension post-file)))
     (when (not (member file-ext easy-jekyll--formats))
       (error "Please enter .%s file name or .%s file name"
	      easy-jekyll-markdown-extension easy-jekyll-textile-extension))
     (when (equal (buffer-name (current-buffer)) easy-jekyll--buffer-name)
       (when (file-exists-p (file-truename newname))
	 (error "%s already exists!" newname))
       (unless (or (string-match "^$" (thing-at-point 'line))
		   (eq (point) (point-max))
		   (> (+ 1 easy-jekyll--forward-char) (length (thing-at-point 'line))))
	 (let ((oldname (if easy-jekyll--draft-list
			    (expand-file-name
			     (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
			     "_drafts")
			  (expand-file-name
			   (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
			   easy-jekyll-postdir))))
	   (rename-file oldname newname 1)
	   (easy-jekyll-refresh)))))))

(defun easy-jekyll-undraft ()
  "Undraft file on the pointer."
  (interactive)
  (when (equal (buffer-name (current-buffer)) easy-jekyll--buffer-name)
    (easy-jekyll-with-env
     (unless (or (string-match "^$" (thing-at-point 'line))
		 (eq (point) (point-max))
		 (> (+ 1 easy-jekyll--forward-char) (length (thing-at-point 'line))))
       (let ((file (expand-file-name
		    (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
		    (expand-file-name "_drafts" easy-jekyll-basedir))))
	 (when (and (file-exists-p file)
		    (not (file-directory-p file)))
	   (unless (file-directory-p (expand-file-name "_drafts" easy-jekyll-basedir))
	     (make-directory (expand-file-name "_drafts" easy-jekyll-basedir) t))
	   (setq easy-jekyll--postdir-list
		 (easy-jekyll--directory-list
		  (easy-jekyll--directory-files-recursively
		   (expand-file-name "_posts" easy-jekyll-basedir) "" t)))
	   (add-to-list 'easy-jekyll--postdir-list
			(expand-file-name easy-jekyll-basedir))
	   (add-to-list 'easy-jekyll--postdir-list
			(expand-file-name "_posts" easy-jekyll-basedir))
	   (setq easy-jekyll-postdir
		 (file-relative-name
		  (completing-read
		   "Complete easy-jekyll-postdir: "
		   easy-jekyll--postdir-list
		   nil t)))
	   (rename-file file
			(expand-file-name
			 (concat (format-time-string "%Y-%m-%d-" (current-time))
				 (file-name-nondirectory file))
			 easy-jekyll-postdir)
			1)
	   (easy-jekyll-refresh)))))))

(defun easy-jekyll-open ()
  "Open the file on the pointer."
  (interactive)
  (when (equal (buffer-name (current-buffer)) easy-jekyll--buffer-name)
    (easy-jekyll-with-env
     (unless (or (string-match "^$" (thing-at-point 'line))
		 (eq (point) (point-max))
		 (> (+ 1 easy-jekyll--forward-char) (length (thing-at-point 'line))))
       (let ((file (expand-file-name
		    (if easy-jekyll--draft-list
			(expand-file-name
			 (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
			 "_drafts")
		      (expand-file-name
		       (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
		       easy-jekyll-postdir))
		    easy-jekyll-basedir)))
	 (when (and (file-exists-p file)
		    (not (file-directory-p file)))
	   (find-file file)))))))

(defun easy-jekyll-open-other-window ()
  "Open the file on the pointer at other window."
  (interactive)
  (when (equal (buffer-name (current-buffer)) easy-jekyll--buffer-name)
    (easy-jekyll-with-env
     (unless (or (string-match "^$" (thing-at-point 'line))
		 (eq (point) (point-max))
		 (> (+ 1 easy-jekyll--forward-char) (length (thing-at-point 'line))))
       (let ((file (expand-file-name
		    (if easy-jekyll--draft-list
			(expand-file-name
			 (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
			 "_drafts")
		      (expand-file-name
		       (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
		       easy-jekyll-postdir))
		    easy-jekyll-basedir)))
	 (when (and (file-exists-p file)
		    (not (file-directory-p file)))
	   (find-file-other-window file)))))))

(defun easy-jekyll-open-basedir ()
  "Open `easy-jekyll-basedir' with dired."
  (interactive)
  (easy-jekyll-with-env
   (switch-to-buffer (find-file-noselect easy-jekyll-basedir))))

(defun easy-jekyll-view ()
  "Open the file on the pointer with 'view-mode'."
  (interactive)
  (easy-jekyll-with-env
   (if (equal (buffer-name (current-buffer)) easy-jekyll--buffer-name)
       (progn
	 (unless (or (string-match "^$" (thing-at-point 'line))
		     (eq (point) (point-max))
		     (> (+ 1 easy-jekyll--forward-char) (length (thing-at-point 'line))))
	   (let ((file (expand-file-name
			(if easy-jekyll--draft-list
			    (expand-file-name
			     (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
			     "_drafts")
			  (expand-file-name
			   (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
			   easy-jekyll-postdir))
			easy-jekyll-basedir)))
	     (when (and (file-exists-p file)
			(not (file-directory-p file)))
	       (view-file file)))))
     (view-file buffer-file-name))))

(defun easy-jekyll-view-other-window ()
  "Open the file on the pointer with 'view-mode' at other window."
  (interactive)
  (easy-jekyll-with-env
   (if (equal (buffer-name (current-buffer)) easy-jekyll--buffer-name)
       (progn
	 (unless (or (string-match "^$" (thing-at-point 'line))
		     (eq (point) (point-max))
		     (> (+ 1 easy-jekyll--forward-char) (length (thing-at-point 'line))))
	   (let ((file (expand-file-name
			(if easy-jekyll--draft-list
			    (expand-file-name
			     (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
			     "_drafts")
			  (expand-file-name
			   (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
			   easy-jekyll-postdir))
			easy-jekyll-basedir)))
	     (when (and (file-exists-p file)
			(not (file-directory-p file)))
	       (view-file-other-window file)))))
     (view-file-other-window buffer-file-name))))

(defun easy-jekyll-delete ()
  "Delete the file on the pointer."
  (interactive)
  (when (equal (buffer-name (current-buffer)) easy-jekyll--buffer-name)
    (easy-jekyll-with-env
     (unless (or (string-match "^$" (thing-at-point 'line))
		 (eq (point) (point-max))
		 (> (+ 1 easy-jekyll--forward-char) (length (thing-at-point 'line))))
       (let ((file (expand-file-name
		    (if easy-jekyll--draft-list
			(expand-file-name
			 (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
			 "_drafts")
		      (expand-file-name
		       (substring (thing-at-point 'line) easy-jekyll--forward-char -1)
		       easy-jekyll-postdir))
		    easy-jekyll-basedir)))
	 (when (and (file-exists-p file)
		    (not (file-directory-p file)))
	   (when (yes-or-no-p (concat "Delete " file))
	     (if easy-jekyll-no-help
		 (setq easy-jekyll--line (- (line-number-at-pos) 4))
	       (setq easy-jekyll--line (- (line-number-at-pos) (+ easy-jekyll--unmovable-line 1))))
	     (delete-file file)
	     (if easy-jekyll--draft-list
		 (easy-jekyll-draft-list)
	       (easy-jekyll))
	     (when (> easy-jekyll--line 0)
	       (forward-line easy-jekyll--line)
	       (forward-char easy-jekyll--forward-char)))))))))

(defun easy-jekyll-next-blog ()
  "Go to next blog."
  (interactive)
  (when (< 1 (length easy-jekyll-bloglist))
    (if (eq (- (length easy-jekyll-bloglist) 1) easy-jekyll--current-blog)
	(setq easy-jekyll--current-blog 0)
      (setq easy-jekyll--current-blog (+ easy-jekyll--current-blog 1)))
    (setq easy-jekyll--postdir-list nil)
    (setq easy-jekyll--current-postdir 0)
    (easy-jekyll-set-bloglist easy-jekyll-basedir)
    (easy-jekyll-set-bloglist easy-jekyll-url)
    (easy-jekyll-set-bloglist easy-jekyll-root)
    (easy-jekyll-set-bloglist easy-jekyll-sshdomain)
    (easy-jekyll-set-bloglist easy-jekyll-amazon-s3-bucket-name)
    (easy-jekyll-set-bloglist easy-jekyll-google-cloud-storage-bucket-name)
    (if (easy-jekyll-eval-bloglist easy-jekyll-github-deploy-script)
	(easy-jekyll-set-bloglist easy-jekyll-github-deploy-script)
      (setq easy-jekyll-github-deploy-script easy-jekyll--default-github-deploy-script))
    (if (easy-jekyll-eval-bloglist easy-jekyll-image-directory)
	(easy-jekyll-set-bloglist easy-jekyll-image-directory)
      (setq easy-jekyll-image-directory easy-jekyll--default-image-directory))
    (if (easy-jekyll-eval-bloglist easy-jekyll-default-picture-directory)
	(easy-jekyll-set-bloglist easy-jekyll-default-picture-directory)
      (setq easy-jekyll-default-picture-directory easy-jekyll--default-picture-directory))
    (if (easy-jekyll-eval-bloglist easy-jekyll-publish-chmod)
	(easy-jekyll-set-bloglist easy-jekyll-publish-chmod)
      (setq easy-jekyll-publish-chmod easy-jekyll--default-publish-chmod))
    (if (easy-jekyll-eval-bloglist easy-jekyll-previewtime)
	(easy-jekyll-set-bloglist easy-jekyll-previewtime)
      (setq easy-jekyll-previewtime easy-jekyll--default-previewtime))
    (if (easy-jekyll-eval-bloglist easy-jekyll-preview-url)
	(easy-jekyll-set-bloglist easy-jekyll-preview-url)
      (setq easy-jekyll-preview-url easy-jekyll--default-preview-url))
    (if (easy-jekyll-eval-bloglist easy-jekyll-sort-default-char)
	(easy-jekyll-set-bloglist easy-jekyll-sort-default-char)
      (setq easy-jekyll-sort-default-char easy-jekyll--default-sort-default-char))
    (if (easy-jekyll-eval-bloglist easy-jekyll-textile-extension)
	(easy-jekyll-set-bloglist easy-jekyll-textile-extension)
      (setq easy-jekyll-textile-extension easy-jekyll--default-textile-extension))
    (if (easy-jekyll-eval-bloglist easy-jekyll-markdown-extension)
	(easy-jekyll-set-bloglist easy-jekyll-markdown-extension)
      (setq easy-jekyll-markdown-extension easy-jekyll--default-markdown-extension))
    (if (easy-jekyll-eval-bloglist easy-jekyll-default-ext)
	(easy-jekyll-set-bloglist easy-jekyll-default-ext)
      (setq easy-jekyll-default-ext easy-jekyll--default-ext))
    (if (easy-jekyll-eval-bloglist easy-jekyll-postdir)
	(easy-jekyll-set-bloglist easy-jekyll-postdir)
      (setq easy-jekyll-postdir easy-jekyll--default-postdir))
    (easy-jekyll--preview-end)
    (easy-jekyll)))

(defun easy-jekyll-previous-blog ()
  "Go to previous blog."
  (interactive)
  (when (< 1 (length easy-jekyll-bloglist))
    (if (= 0 easy-jekyll--current-blog)
	(setq easy-jekyll--current-blog (- (length easy-jekyll-bloglist) 1))
      (setq easy-jekyll--current-blog (- easy-jekyll--current-blog 1)))
    (setq easy-jekyll--postdir-list nil)
    (setq easy-jekyll--current-postdir 0)
    (easy-jekyll-set-bloglist easy-jekyll-basedir)
    (easy-jekyll-set-bloglist easy-jekyll-url)
    (easy-jekyll-set-bloglist easy-jekyll-root)
    (easy-jekyll-set-bloglist easy-jekyll-sshdomain)
    (easy-jekyll-set-bloglist easy-jekyll-amazon-s3-bucket-name)
    (easy-jekyll-set-bloglist easy-jekyll-google-cloud-storage-bucket-name)
    (if (easy-jekyll-eval-bloglist easy-jekyll-github-deploy-script)
	(easy-jekyll-set-bloglist easy-jekyll-github-deploy-script)
      (setq easy-jekyll-github-deploy-script easy-jekyll--default-github-deploy-script))
    (if (easy-jekyll-eval-bloglist easy-jekyll-image-directory)
	(easy-jekyll-set-bloglist easy-jekyll-image-directory)
      (setq easy-jekyll-image-directory easy-jekyll--default-image-directory))
    (if (easy-jekyll-eval-bloglist easy-jekyll-default-picture-directory)
	(easy-jekyll-set-bloglist easy-jekyll-default-picture-directory)
      (setq easy-jekyll-default-picture-directory easy-jekyll--default-picture-directory))
    (if (easy-jekyll-eval-bloglist easy-jekyll-publish-chmod)
	(easy-jekyll-set-bloglist easy-jekyll-publish-chmod)
      (setq easy-jekyll-publish-chmod easy-jekyll--default-publish-chmod))
    (if (easy-jekyll-eval-bloglist easy-jekyll-previewtime)
	(easy-jekyll-set-bloglist easy-jekyll-previewtime)
      (setq easy-jekyll-previewtime easy-jekyll--default-previewtime))
    (if (easy-jekyll-eval-bloglist easy-jekyll-preview-url)
	(easy-jekyll-set-bloglist easy-jekyll-preview-url)
      (setq easy-jekyll-preview-url easy-jekyll--default-preview-url))
    (if (easy-jekyll-eval-bloglist easy-jekyll-sort-default-char)
	(easy-jekyll-set-bloglist easy-jekyll-sort-default-char)
      (setq easy-jekyll-sort-default-char easy-jekyll--default-sort-default-char))
    (if (easy-jekyll-eval-bloglist easy-jekyll-textile-extension)
	(easy-jekyll-set-bloglist easy-jekyll-textile-extension)
      (setq easy-jekyll-textile-extension easy-jekyll--default-textile-extension))
    (if (easy-jekyll-eval-bloglist easy-jekyll-markdown-extension)
	(easy-jekyll-set-bloglist easy-jekyll-markdown-extension)
      (setq easy-jekyll-markdown-extension easy-jekyll--default-markdown-extension))
    (if (easy-jekyll-eval-bloglist easy-jekyll-default-ext)
	(easy-jekyll-set-bloglist easy-jekyll-default-ext)
      (setq easy-jekyll-default-ext easy-jekyll--default-ext))
    (if (easy-jekyll-eval-bloglist easy-jekyll-postdir)
	(easy-jekyll-set-bloglist easy-jekyll-postdir)
      (setq easy-jekyll-postdir easy-jekyll--default-postdir))
    (easy-jekyll--preview-end)
    (easy-jekyll)))

(defun easy-jekyll-nth-blog (n)
  "Go to blog of number N."
  (interactive "nBlog number:")
  (when (or (< n 0)
	    (>= n (length easy-jekyll-bloglist)))
    (error "Blog %s does not exist" n))
  (when (and (< 1 (length easy-jekyll-bloglist))
	     (< n (length easy-jekyll-bloglist)))
    (setq easy-jekyll--current-blog n)
    (setq easy-jekyll--postdir-list nil)
    (setq easy-jekyll--current-postdir 0)
    (easy-jekyll-set-bloglist easy-jekyll-basedir)
    (easy-jekyll-set-bloglist easy-jekyll-url)
    (easy-jekyll-set-bloglist easy-jekyll-root)
    (easy-jekyll-set-bloglist easy-jekyll-sshdomain)
    (easy-jekyll-set-bloglist easy-jekyll-amazon-s3-bucket-name)
    (easy-jekyll-set-bloglist easy-jekyll-google-cloud-storage-bucket-name)
    (if (easy-jekyll-eval-bloglist easy-jekyll-github-deploy-script)
	(easy-jekyll-set-bloglist easy-jekyll-github-deploy-script)
      (setq easy-jekyll-github-deploy-script easy-jekyll--default-github-deploy-script))
    (if (easy-jekyll-eval-bloglist easy-jekyll-image-directory)
	(easy-jekyll-set-bloglist easy-jekyll-image-directory)
      (setq easy-jekyll-image-directory easy-jekyll--default-image-directory))
    (if (easy-jekyll-eval-bloglist easy-jekyll-default-picture-directory)
	(easy-jekyll-set-bloglist easy-jekyll-default-picture-directory)
      (setq easy-jekyll-default-picture-directory easy-jekyll--default-picture-directory))
    (if (easy-jekyll-eval-bloglist easy-jekyll-publish-chmod)
	(easy-jekyll-set-bloglist easy-jekyll-publish-chmod)
      (setq easy-jekyll-publish-chmod easy-jekyll--default-publish-chmod))
    (if (easy-jekyll-eval-bloglist easy-jekyll-previewtime)
	(easy-jekyll-set-bloglist easy-jekyll-previewtime)
      (setq easy-jekyll-previewtime easy-jekyll--default-previewtime))
    (if (easy-jekyll-eval-bloglist easy-jekyll-preview-url)
	(easy-jekyll-set-bloglist easy-jekyll-preview-url)
      (setq easy-jekyll-preview-url easy-jekyll--default-preview-url))
    (if (easy-jekyll-eval-bloglist easy-jekyll-sort-default-char)
	(easy-jekyll-set-bloglist easy-jekyll-sort-default-char)
      (setq easy-jekyll-sort-default-char easy-jekyll--default-sort-default-char))
    (if (easy-jekyll-eval-bloglist easy-jekyll-textile-extension)
	(easy-jekyll-set-bloglist easy-jekyll-textile-extension)
      (setq easy-jekyll-textile-extension easy-jekyll--default-textile-extension))
    (if (easy-jekyll-eval-bloglist easy-jekyll-markdown-extension)
	(easy-jekyll-set-bloglist easy-jekyll-markdown-extension)
      (setq easy-jekyll-markdown-extension easy-jekyll--default-markdown-extension))
    (if (easy-jekyll-eval-bloglist easy-jekyll-default-ext)
	(easy-jekyll-set-bloglist easy-jekyll-default-ext)
      (setq easy-jekyll-default-ext easy-jekyll--default-ext))
    (if (easy-jekyll-eval-bloglist easy-jekyll-postdir)
	(easy-jekyll-set-bloglist easy-jekyll-postdir)
      (setq easy-jekyll-postdir easy-jekyll--default-postdir))
    (easy-jekyll--preview-end)
    (easy-jekyll)))

(defun easy-jekyll-url-list (a)
  "Return url list from blog max number A."
  (if (>= a 0)
      (cons
       (list (cdr (rassoc (easy-jekyll-nth-eval-bloglist easy-jekyll-url a)
			  (nth a easy-jekyll-bloglist)))
	     a)
       (easy-jekyll-url-list (- a 1)))))

;;;###autoload
(defun easy-jekyll-select-postdir ()
  "Select postdir you want to go."
  (interactive)
  (setq easy-jekyll--postdir-list
	(easy-jekyll--directory-list
	 (easy-jekyll--directory-files-recursively
	  (expand-file-name "_posts" easy-jekyll-basedir) "" t)))
  (add-to-list 'easy-jekyll--postdir-list
	       (expand-file-name easy-jekyll-basedir))
  (add-to-list 'easy-jekyll--postdir-list
  	       (expand-file-name "_posts" easy-jekyll-basedir))
  (setq easy-jekyll-postdir
	(file-relative-name
	 (completing-read
	  "Complete easy-jekyll-postdir: "
	  easy-jekyll--postdir-list
	  nil t)))
  (easy-jekyll))

;;;###autoload
(defun easy-jekyll-select-filename ()
  "Select filename you want to open."
  (interactive)
  (find-file
   (concat (expand-file-name easy-jekyll-postdir easy-jekyll-basedir)
	   "/"
	   (completing-read
	    "Complete filename: "
	    (easy-jekyll--directory-files-nondirectory
	     (expand-file-name easy-jekyll-postdir easy-jekyll-basedir)
	     "\\.\\(textile\\|md\\)\\'")
	    nil t))))

(defsubst easy-jekyll--directory-name-p (name)
  "Return non-nil if NAME ends with a directory separator character."
  (let ((len (length name))
        (lastc ?.))
    (if (> len 0)
        (setq lastc (aref name (1- len))))
    (or (= lastc ?/)
        (and (memq system-type '(windows-nt ms-dos))
             (= lastc ?\\)))))

(defun easy-jekyll--directory-files-nondirectory (dir regexp)
  "Return list of all files nondirectory under DIR that have file names matching REGEXP."
  (let ((result nil)
	(files nil)
	(tramp-mode (and tramp-mode (file-remote-p (expand-file-name dir)))))
    (dolist (file (sort (file-name-all-completions "" dir)
			'string<))
      (unless (member file '("./" "../"))
	(if (not (easy-jekyll--directory-name-p file))
	    (when (string-match regexp file)
	      (push (file-name-nondirectory  file) files)))))
    (nconc result (nreverse files))))

;;;###autoload
(defun easy-jekyll-select-blog ()
  "Select blog url you want to go."
  (interactive)
  (let ((completions (easy-jekyll-url-list (- (length easy-jekyll-bloglist) 1))))
    (easy-jekyll-nth-blog
     (cadr (assoc
	    (completing-read "Complete easy-jekyll-url: " completions nil t)
	    completions)))))

(defun easy-jekyll--directory-list (list)
  "Return only directories in LIST."
  (if list
      (if (file-directory-p (car list))
	  (cons (car list)
		(easy-jekyll--directory-list (cdr list)))
	(easy-jekyll--directory-list (cdr list)))))

(defun easy-jekyll--directory-files-recursively (dir regexp &optional include-directories)
  "Return list of all files under DIR that have file names matching REGEXP.
This function works recursively.  Files are returned in \"depth first\"
order, and files from each directory are sorted in alphabetical order.
Each file name appears in the returned list in its absolute form.
Optional argument INCLUDE-DIRECTORIES non-nil means also include in the
output directories whose names match REGEXP."
  (let ((result nil)
	(files nil)
	(tramp-mode (and tramp-mode (file-remote-p (expand-file-name dir)))))
    (dolist (file (sort (file-name-all-completions "" dir)
			'string<))
      (unless (member file '("./" "../"))
	(if (easy-jekyll--directory-name-p file)
	    (let* ((leaf (substring file 0 (1- (length file))))
		   (full-file (expand-file-name leaf dir)))
	      (unless (file-symlink-p full-file)
		(setq result
		      (nconc result (easy-jekyll--directory-files-recursively
				     full-file regexp include-directories))))
	      (when (and include-directories
			 (string-match regexp leaf))
		(setq result (nconc result (list full-file)))))
	  (when (string-match regexp file)
	    (push (expand-file-name file dir) files)))))
    (nconc result (nreverse files))))

(defun easy-jekyll-next-postdir ()
  "Go to next postdir."
  (interactive)
  (setq easy-jekyll--postdir-list
	(easy-jekyll--directory-list
	 (easy-jekyll--directory-files-recursively
	  (expand-file-name "_posts" easy-jekyll-basedir) "" t)))
  (add-to-list 'easy-jekyll--postdir-list
	       (expand-file-name easy-jekyll-basedir))
  (add-to-list 'easy-jekyll--postdir-list
  	       (expand-file-name "_posts" easy-jekyll-basedir))
  (if (eq (- (length easy-jekyll--postdir-list) 1) easy-jekyll--current-postdir)
      (setq easy-jekyll--current-postdir 0)
    (setq easy-jekyll--current-postdir (+ easy-jekyll--current-postdir 1)))
  (setq easy-jekyll-postdir
	(file-relative-name
	 (nth easy-jekyll--current-postdir easy-jekyll--postdir-list)
	 easy-jekyll-basedir))
  (easy-jekyll))

(defun easy-jekyll-previous-postdir ()
  "Go to previous postdir."
  (interactive)
  (setq easy-jekyll--postdir-list
	(easy-jekyll--directory-list
	 (easy-jekyll--directory-files-recursively
	  (expand-file-name "_posts" easy-jekyll-basedir) "" t)))
  (add-to-list 'easy-jekyll--postdir-list
	       (expand-file-name easy-jekyll-basedir))
  (add-to-list 'easy-jekyll--postdir-list
	       (expand-file-name "_posts" easy-jekyll-basedir))
  (setq easy-jekyll--current-postdir (- easy-jekyll--current-postdir 1))
  (when (> 0 easy-jekyll--current-postdir)
    (setq easy-jekyll--current-postdir (- (length easy-jekyll--postdir-list) 1)))
  (setq easy-jekyll-postdir
	(file-relative-name
	 (nth easy-jekyll--current-postdir easy-jekyll--postdir-list)
	 easy-jekyll-basedir))
  (easy-jekyll))

(defun easy-jekyll-draft-list ()
  "Drafts list mode of `easy-jekyll'."
  (easy-jekyll-with-env
   (unless (file-directory-p (expand-file-name "_drafts" easy-jekyll-basedir))
     (make-directory (expand-file-name "_drafts" easy-jekyll-basedir) t))
   (setq easy-jekyll--mode-buffer (get-buffer-create easy-jekyll--buffer-name))
   (setq easy-jekyll--draft-list 1)
   (switch-to-buffer easy-jekyll--mode-buffer)
   (setq-local default-directory easy-jekyll-basedir)
   (setq buffer-read-only nil)
   (erase-buffer)
   (insert (propertize
	    (concat "Easy-jekyll  " easy-jekyll-url easy-jekyll--draft-mode "\n\n")
	    'face 'easy-jekyll-help-face))
   (unless easy-jekyll-no-help
     (insert (propertize easy-jekyll-help 'face 'easy-jekyll-help-face))
     (when easy-jekyll-additional-help
       (insert (propertize easy-jekyll-add-help 'face 'easy-jekyll-help-face)))
     (insert (propertize (concat "\n")'face 'easy-jekyll-help-face)))
   (unless easy-jekyll--refresh
     (setq easy-jekyll--cursor (point)))
   (let ((files (directory-files (expand-file-name "_drafts" easy-jekyll-basedir)))
	 (lists (list)))
     (if (eq 2 (length files))
	 (progn
	   (easy-jekyll-mode)
	   (goto-char easy-jekyll--cursor))
       (progn
	 (cond ((eq 1 easy-jekyll--sort-char-flg)
		(setq files (reverse (sort files 'string<))))
	       ((eq 2 easy-jekyll--sort-char-flg)
		(setq files (sort files 'string<))))
	 (while files
	   (unless (or (string= (car files) ".")
		       (string= (car files) "..")
		       (not (member (file-name-extension (car files)) easy-jekyll--formats)))
	     (push
	      (concat
	       (format-time-string "%Y-%m-%d %H:%M:%S " (nth 5 (file-attributes
								(expand-file-name
								 (car files)
								 easy-jekyll-postdir))))
	       (car files))
	      lists))
	   (pop files))
	 (cond ((eq 1 easy-jekyll--sort-time-flg)
		(setq lists (reverse (sort lists 'string<))))
	       ((eq 2 easy-jekyll--sort-time-flg)
		(setq lists (sort lists 'string<))))
	 (while lists
	   (insert (concat (car lists) "\n"))
	   (pop lists))
	 (goto-char easy-jekyll--cursor)
	 (easy-jekyll-ignore-error
	  (if easy-jekyll--refresh
	     (progn
	       (when (< (line-number-at-pos) easy-jekyll--unmovable-line)
		 (goto-char (point-min))
		 (forward-line (- easy-jekyll--unmovable-line 1)))
	       (beginning-of-line)
	       (forward-char easy-jekyll--forward-char))
	   (forward-char easy-jekyll--forward-char)))
	 (easy-jekyll-mode)
	 (when easy-jekyll-emacspeak
	   (easy-jekyll-emacspeak-filename)))))))

;;;###autoload
(defun easy-jekyll ()
  "Easy jekyll mode."
  (interactive)
  (easy-jekyll-with-env
   (unless (file-directory-p (expand-file-name
			      easy-jekyll-postdir
			      easy-jekyll-basedir))
     (error "%s%s does not exist!" easy-jekyll-basedir easy-jekyll-postdir))
   (setq easy-jekyll--mode-buffer (get-buffer-create easy-jekyll--buffer-name))
   (setq easy-jekyll--draft-list nil)
   (switch-to-buffer easy-jekyll--mode-buffer)
   (setq-local default-directory easy-jekyll-basedir)
   (setq buffer-read-only nil)
   (erase-buffer)
   (if (equal easy-jekyll-postdir "./")
       (insert (propertize
		(concat "Easy-jekyll  " easy-jekyll-url "\n\n")
		'face 'easy-jekyll-help-face))
     (insert (propertize
	      (concat "Easy-jekyll  " easy-jekyll-url "/" easy-jekyll-postdir "\n\n")
	      'face 'easy-jekyll-help-face)))
   (unless easy-jekyll-no-help
     (insert (propertize easy-jekyll-help 'face 'easy-jekyll-help-face))
     (when easy-jekyll-additional-help
       (insert (propertize easy-jekyll-add-help 'face 'easy-jekyll-help-face)))
     (insert (propertize (concat "\n")'face 'easy-jekyll-help-face)))
   (unless easy-jekyll--refresh
     (setq easy-jekyll--cursor (point)))
   (let ((files (directory-files (expand-file-name
				  easy-jekyll-postdir
				  easy-jekyll-basedir)))
	 (lists (list)))
     (if (eq 2 (length files))
	 (progn
	   (insert easy-jekyll--first-help)
	   (easy-jekyll-mode)
	   (goto-char easy-jekyll--cursor))
       (progn
	 (cond ((eq 1 easy-jekyll--sort-char-flg)
		(setq files (reverse (sort files 'string<))))
	       ((eq 2 easy-jekyll--sort-char-flg)
		(setq files (sort files 'string<))))
	 (while files
	   (unless (or (string= (car files) ".")
		       (string= (car files) "..")
		       (not (member (file-name-extension (car files)) easy-jekyll--formats)))
	     (push
	      (concat
	       (format-time-string "%Y-%m-%d %H:%M:%S " (nth 5 (file-attributes
								(expand-file-name
								 (car files)
								 easy-jekyll-postdir))))
	       (car files))
	      lists))
	   (pop files))
	 (cond ((eq 1 easy-jekyll--sort-time-flg)
		(setq lists (reverse (sort lists 'string<))))
	       ((eq 2 easy-jekyll--sort-time-flg)
		(setq lists (sort lists 'string<))))
	 (while lists
	   (insert (concat (car lists) "\n"))
	   (pop lists))
	 (goto-char easy-jekyll--cursor)
	 (easy-jekyll-ignore-error
	  (if easy-jekyll--refresh
	     (progn
	       (when (< (line-number-at-pos) easy-jekyll--unmovable-line)
		 (goto-char (point-min))
		 (forward-line (- easy-jekyll--unmovable-line 1)))
	       (beginning-of-line)
	       (forward-char easy-jekyll--forward-char))
	   (forward-char easy-jekyll--forward-char)))
	 (easy-jekyll-mode)
	 (when easy-jekyll-emacspeak
	   (easy-jekyll-emacspeak-filename)))))))

(provide 'easy-jekyll)

;;; easy-jekyll.el ends here
