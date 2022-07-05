;;; dropbox.el --- Emacs backend for dropbox

;; Copyright (C) 2011 Pavel Panchekha <me@pavpanchekha.com>
;;           (C) 2013 Drew Haven      <ahaven@alum.mit.edu>

;; Author: Pavel Panchekha <me@pavpanchekha.com>
;; Version: 0.9.1
;; Package-Requires: ((request "0.3.0") (json "1.2") (oauth "1.0.3"))
;; Keywords: dropbox
;; Contributors:
;;     Drew Haven      <ahaven@alum.mit.edu>
;;     Max Satula      <maksym.satula@gmail.com>

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package allows one to access files stored in Dropbox,
;; effectively acting as an Emacs Dropbox client and SDK.

(provide 'dropbox)

;;; TODO
;; - Return permissions other than -rwx------ if folder has shares
;; - dropbox-handle-set-visited-file-modtime might need actual implementation
;; - Switching to deleted buffer on file open
;; - Implement `replace` on insert-file-contents
;; - Implement `lockname` and `mustbenew` on write-region
;; - Implement perma-trashing files
;; - Make RECURSIVE on DELETE-DIRECTORY work lock-free using /sync/batch
;; - Figure out why TRASH is not passed to DELETE-DIRECTORY
;; - Use locale on authenticating the app (oauth library has issues)
;; - Request confirmation properly for OK-IF-ALREADY-EXISTS in move and copy
;; - DIRED-COMPRESS-FILE is not atomic.  Use /sync/batch
;; - Pop open help page on first use of a /db: path

;; Suggestion to developers: M-x occur ";;;"

(require 'request)
(require 'json)
(require 'cl-lib)

;;; Customization Options

(defgroup dropbox nil
  "The Dropbox Emacs Client and SDK"
  :prefix "dropbox-"
  :group 'file)

(defcustom dropbox-access-token ""
  "Access Token to access Dropbox"
  :group 'dropbox
  :type 'string)

(defcustom dropbox-cache-timeout 60
  "The duration of time, in seconds, for which dropbox.el will
cache metadata for files.  Setting it longer makes dropbox.el
faster, but means that you will have old data if multiple clients
concurrently modify your dropbox."
  :group 'dropbox
  :type 'integer)

(defcustom dropbox-verbose nil
  "Whether dropbox.el should `message` debug messages.  Helpful for
debugging but otherwise very intrusive."
  :group 'dropbox
  :type 'boolean)

; Do not edit the prefix -- lots of hard-coded regexes everywhere
(defvar dropbox-prefix "/db:")
(defvar dropbox-cache '())

;;; Utilities

(defun dropbox-message (fmt-string &rest args)
  (when dropbox-verbose (apply 'message fmt-string args)))

(defun dropbox-strip-final-slash (path)
  (cond
   ((null path)
    path)
   ((string= path "")
    path)
   ((= (aref path (- (length path) 1)) 47)
    (substring path 0 -1))
   (t path)))

(defmacro with-default-directory (dir &rest body)
  (declare (indent 1))
  `(let ((default-directory ,dir))
       ,@body))

;;; Caching for the Dropbox API

(defun dropbox-cached (name path &optional no-expire)
  (when (string-prefix-p "/db:" path)
    (setf path (dropbox-strip-prefix path)))
  (let ((cached (assoc (cons name (dropbox-strip-final-slash path))
                       dropbox-cache)))
    (if (and cached
             (or no-expire
                 (time-less-p (time-subtract (current-time) (cadr cached))
                              `(0 ,dropbox-cache-timeout 0))))
        (cddr cached)
      nil)))

(defun dropbox-cache (name path value)
  (when (string-prefix-p "/db:" path)
    (setf path (dropbox-strip-prefix path)))
  (setf path (dropbox-strip-final-slash path))
  (let ((cached (assoc (cons name path) dropbox-cache)))
    (if cached
        (setf (cdr cached) (cons (current-time) value))
      (setf dropbox-cache (cons `((,name . ,path) . (,(current-time) . ,value))
				dropbox-cache)))
    value))

(defun dropbox-un-cache (name path)
  (when (string-prefix-p "/db:" path)
    (setf path (dropbox-strip-prefix path)))
  (setf dropbox-cache (cl-remove-if '(lambda (x) (equal (car x) (cons name path)))
                                 dropbox-cache)))

(defun dropbox-uncache ()
  (interactive)

  (setf dropbox-cache '()))

;;; Requesting URLs

(defconst dropbox--functions
  '((list     . ("https://api.dropboxapi.com/2/files/list_folder"      "POST" json-read "application/json"))
    (metadata . ("https://api.dropboxapi.com/2/files/get_metadata"     "POST" json-read "application/json"))
    (download . ("https://content.dropboxapi.com/2/files/download"     "GET"  buffer-string))
    (upload   . ("https://content.dropboxapi.com/2/files/upload"       "POST" json-read "application/octet-stream"))
    (usage    . ("https://api.dropboxapi.com/2/users/get_space_usage"  "POST" json-read))
    (mkdir    . ("https://api.dropboxapi.com/2/files/create_folder_v2" "POST" json-read "application/json"))
    (rm       . ("https://api.dropboxapi.com/2/files/delete_v2"        "POST" json-read "application/json"))
    (copy     . ("https://api.dropboxapi.com/2/files/copy_v2"          "POST" json-read "application/json"))
    (move     . ("https://api.dropboxapi.com/2/files/move_v2"          "POST" json-read "application/json"))))

(defun dropbox-request (func &optional data api-arg)
  (let* ((func-params (alist-get func dropbox--functions))
	 (url (car func-params))
	 (method (cadr func-params))
	 (parser (nth 2 func-params))
	 (content-type (nth 3 func-params))
	 (headers (list (cons "Authorization" (concat "Bearer " dropbox-access-token))))
	 (headers (if content-type (cons (cons "Content-Type" content-type) headers) headers))
	 (headers (if api-arg (cons (cons "Dropbox-API-Arg" (if api-arg (encode-coding-string api-arg 'utf-8) api-arg)) headers) headers))
	 (response (with-default-directory "~/" (request url
	     :sync t
	     :type method
	     :data (if data (encode-coding-string data 'utf-8) data)
             :error (cl-function (lambda (&rest rest) 'ok))
	     :headers headers
	     :parser parser))))
    (or (request-response-error-thrown response)
	(request-response-data response))))

(defun dropbox--sanitize-path (path)
  (cond
   ((string= path "/") "")
   (t (dropbox-strip-final-slash (if (string-prefix-p "/" path) path (concat "/" path))))))

(defun dropbox--metadata (path)
  (dropbox-message "Getting metadata for >%s<" path)
  (let ((path (dropbox--sanitize-path path)))
  (or (and (string= path "")
	   '((\.tag . "folder") (name . "") (path_lower . "") (path_display . "")))
      (dropbox-cached 'metadata path)
      (dropbox-cache
       'metadata path
       (dropbox-request
	'metadata
	(json-encode `(("path" . ,(encode-coding-string path 'utf-8))
		       ("include_media_info" . :json-false)
		       ("include_deleted" . :json-false)
		       ("include_has_explicit_shared_members" . :json-false))))))))

(defun dropbox--list (path)
  (dropbox-message "LIST >%s<" path)
  (let ((path (dropbox--sanitize-path path)))
  (or (dropbox-cached 'list path)
      (dropbox-cache
       'list path
       (apply #'vector
       (mapcar
	(lambda (f) (substring (alist-get 'path_display f) 1))
	(alist-get
	 'entries
	 (dropbox-request
	  'list
	  (json-encode `(("path" . ,(encode-coding-string path 'utf-8))
			 ("recursive" . :json-false)
			 ("include_media_info" . :json-false)
			 ("include_deleted" . :json-false)
			 ("include_has_explicit_shared_members" . :json-false)
			 ("include_mounted_folders" . t)))))))))))

(defun dropbox--space-usage ()
  (or (dropbox-cached 'usage nil)
      (dropbox-cache
       'usage nil
	 (dropbox-request
	  'usage))))

(defun dropbox-error-p (response)
  (eq 'error (car response)))

;;; Hooking into Dropbox

(defun dropbox-connect ()
  "Connect to Dropbox, hacking the \"/db:\" syntax into `find-file`."
  (interactive)

  (setf file-name-handler-alist
        (cons '("\\`/db:" . dropbox-handler) file-name-handler-alist)))

(defun dropbox-handler (operation &rest args)
  "Handles IO operations to Dropbox files"

  (if (not (eq operation 'file-remote-p))
      (dropbox-message "Dropbox'ing operation %s for %s" operation args))

  (let ((handler (cdr (assoc operation dropbox-handler-alist))))
    (if handler
        (let ((retval (apply handler args)))
          (if (not (eq operation 'file-remote-p)) (dropbox-message "... returning %s" retval))
          retval)
      (let* ((inhibit-file-name-handlers
              `(dropbox-handler
                tramp-file-name-handler
                tramp-vc-file-name-handler
                tramp-completion-file-name-handler
                . ,inhibit-file-name-handlers))
             (inhibit-file-name-operation operation)
             (retval (apply operation args)))
        (dropbox-message "... fall-through returning %s" retval)
        retval))))

(defconst dropbox-handler-alist
  '(; Path parsing
    (file-name-directory . dropbox-handle-file-name-directory)
    (file-name-nondirectory . dropbox-handle-file-name-nondirectory)
    (expand-file-name . dropbox-handle-expand-file-name)
    (file-truename . dropbox-handle-file-truename)
    (substitute-in-file-name . dropbox-handle-substitute-in-file-name)

    (directory-file-name . dropbox-handle-directory-file-name)
    (file-name-as-directory . dropbox-handle-file-name-as-directory)
    (unhandled-file-name-directory . dropbox-handle-unhandled-file-name-directory)
    (find-backup-file-name . dropbox-handle-find-backup-file-name)
    (make-auto-save-file-name . dropbox-handle-make-auto-save-file-name)

    ; Predicates
    (file-directory-p . dropbox-handle-file-directory-p)
    (file-executable-p . dropbox-handle-file-executable-p)
    (file-exists-p . dropbox-handle-file-exists-p)
    (file-newer-than-file-p . dropbox-handle-file-newer-than-file-p)
    (file-ownership-preserved-p . dropbox-handle-file-ownership-preserved-p)
    (file-readable-p . dropbox-handle-file-readable-p)
    (file-regular-p . dropbox-handle-file-regular-p)
    (file-remote-p . dropbox-handle-file-remote-p)
    (file-symlink-p . dropbox-handle-file-symlink-p)
    (file-writable-p . dropbox-handle-file-writable-p)
    (vc-registered . dropbox-handle-vc-registered)

    ; Attributes
    (file-attributes . dropbox-handle-file-attributes)
    (file-modes . dropbox-handle-file-modes)
    (set-file-modes . dropbox-handle-set-file-modes)
    (file-selinux-context . dropbox-handle-file-selinux-context)
    (set-file-selinux-context . dropbox-handle-set-file-selinux-context)

    (set-visited-file-modtime . dropbox-handle-set-visited-file-modtime)
    (verify-visited-file-modtime . dropbox-handle-verify-visited-file-modtime)
    (set-file-times . dropbox-handle-set-file-times)

    ; Directory Contents
    (directory-files . dropbox-handle-directory-files)
    (directory-files-and-attributes
     . dropbox-handle-directory-files-and-attributes)
    (file-name-all-completions . dropbox-handle-file-name-all-completions)
    (file-name-completion . dropbox-handle-file-name-completion)
    (executable-find . dropbox-handle-executable-find)

    (make-directory . dropbox-handle-make-directory)
    (delete-file . dropbox-handle-delete-file)
    (delete-directory . dropbox-handle-delete-directory)
    (copy-file . dropbox-handle-copy-file)
    (copy-directory . dropbox-handle-copy-directory)
    (rename-file . dropbox-handle-rename-file)
    (make-symbolic-link . dropbox-handle-make-symbolic-link)
    (add-name-to-file . dropbox-handle-add-name-to-file)

    (insert-directory . dropbox-handle-insert-directory)
    (dired-insert-directory . dropbox-handle-dired-insert-directory)
    (dired-uncache . dropbox-handle-dired-uncache)

    ; File Contents
    (insert-file-contents . dropbox-handle-insert-file-contents)
    (file-local-copy . dropbox-handle-file-local-copy)
    (dired-compress-file . dropbox-handle-dired-compress-file)
    (write-region . dropbox-handle-write-region)

    ; Misc
    (load . dropbox-handle-load)

    (process-file . dropbox-handle-process-file)
    (start-file-process . dropbox-handle-start-file-process)
    (shell-command . dropbox-handle-shell-command)))

;;; Path Parsing

(defun dropbox-handle-file-name-directory (filename)
  "Return the directory component in file name FILENAME"

  (if (string-match "^\\(/db:.*/\\).*$" filename)
      (match-string 1 filename)
    dropbox-prefix))

(defun dropbox-strip-prefix (filename)
  (substring filename 4))

(defun dropbox-handle-file-name-nondirectory (filename)
  "Return the filename component in file name FILENAME"

  (cond
   ((string-match "^/db:.*/\\(.*\\)$" filename)
    (match-string 1 filename))
   (t (substring filename 4))))

(defun dropbox-remove-slash (filename)
  "Transform /db:/notes into /db:notes."
  (if (dropbox-file-p filename)
      (if (string-match "^/db:/\\(.*\\)$" filename)
          (concat dropbox-prefix (match-string 1 filename))
        filename)
    filename))

(defun dropbox-run-real-handler (operation args)
  "Invoke normal file name handler for OPERATION.
First arg specifies the OPERATION, second arg is a list of arguments to
pass to the OPERATION."
  (let* ((inhibit-file-name-handlers
          `(dropbox-handler
            .
            ,(and (eq inhibit-file-name-operation operation)
                  inhibit-file-name-handlers)))
         (inhibit-file-name-operation operation))
    (apply operation args)))

(defun dropbox-handle-expand-file-name (filename &optional dir)
  "Like the normal operation, except that slashes are removed from
dropbox-like files (/db:/something is transformed into /db:something)."
  (dropbox-run-real-handler 'expand-file-name
                            (list (dropbox-remove-slash filename)
                                  (dropbox-remove-slash dir))))

(defun dropbox-handle-file-truename (filename)
  filename)

(defun dropbox-handle-substitute-in-file-name (filename)
  "Replace slashes with one slash"

  (replace-regexp-in-string ".*//+" "/" filename))

(defun dropbox-handle-directory-file-name (directory)
  "Remove the final slash from a directory name"
  (concat "/db:" (dropbox-run-real-handler
                  'directory-file-name
                  (list (dropbox-strip-prefix directory)))))

(defun dropbox-handle-file-name-as-directory (directory)
  "Remove the final slash from a directory name"

  (if (and
       (not (eq (aref directory (1- (length directory))) ?/))
       (not (string= directory dropbox-prefix)))
      (concat directory "/")
    directory))

(defun dropbox-handle-find-backup-file-name (fn)
  nil)

(defun dropbox-handle-make-auto-save-file-name ()
  (make-temp-name (concat "/tmp/dropbox-el-" (file-name-nondirectory buffer-file-name))))

(defun dropbox-handle-unhandled-file-name-directory (filename)
  "Files like /db:something are not usable without the intervention of a file
handler, thus return `nil'."
  nil)

;;; Predicates

(defun dropbox-file-p (filename)
  "Return t if file FILENAME is a Dropbox file (i.e. starts with `dropbox-prefix')"

  (string-prefix-p dropbox-prefix filename))

(defun dropbox-handle-file-directory-p (filename)
  "Return t if file FILENAME is a directory, too"
  (if (or (string= filename dropbox-prefix)
          (string= filename (concat dropbox-prefix "/")))
      t
    (string= "folder"
	     (alist-get '.tag (dropbox--metadata (concat "/" (dropbox-strip-prefix filename)))))))

(defun dropbox-parent (filename)
  "Get the name of the directory containing FILENAME, even if
FILENAME names a directory"

  (file-name-directory (directory-file-name filename)))

(defun dropbox-handle-file-executable-p (filename)
  (file-directory-p filename))

(defun dropbox-handle-file-exists-p (filename)
  "Return t if file FILENAME exists"
  (not (dropbox-error-p (dropbox--metadata (concat "/" (dropbox-strip-prefix filename))))))

(defun dropbox-handle-file-newer-than-file-p (file1 file2)
  ; these files might not both be dropbox files
  (let ((file1attr (file-attributes file1))
	(file2attr (file-attributes file2)))
    (let ((time1 (if file1attr (elt file1attr 4) nil))
	  (time2 (if file2attr (elt file2attr 4) nil)))
      (if time1
	  (if time2
	      (time-less-p time2 time1)
	    t)
	nil))))

(defun dropbox-handle-file-owner-preserved-p (file)
  "Files have only one owner in Dropbox, so ownership is always preserved"
  t)

(defun dropbox-handle-file-readable-p (filename)
  "Files in Dropbox are always readable"
  t)

(defun dropbox-handle-file-regular-p (file)
  "Files in Dropbox are always regular; directories are not"
  (not (file-directory-p file)))

(defun dropbox-handle-file-remote-p (file &optional identification connected)
  "Test whether FILE is a remote file"

  (dropbox-message file)

  (if (and connected (not dropbox-access-token))
      nil
    (cl-case identification
      ((method) dropbox-prefix)
      ((user) "")
      ((host) "")
      ((localname) (dropbox-strip-prefix file))
      (t dropbox-prefix))))

(defun dropbox-handle-file-symlink-p (filename)
  nil)

(defun dropbox-handle-file-writable-p (filename)
  t)

(defun dropbox-handle-vc-registered (file)
  nil)

;;; Attributes

(defun dropbox-handle-file-attributes (filename &optional id-format)
  (let ((resp
         (dropbox--metadata (dropbox-strip-prefix filename))))
    ;; (if (dropbox-error-p resp)
    ;;     nil
    (let ((date (date-to-time (or (alist-get 'client_modified resp) "Mon, 01 Jan 0000 00:00:00 +0000")))
	  (folder (string= "folder" (alist-get '.tag resp)))) ;; Is dir?
      (list folder
            1 ; Number of links
            0 ; UID
            0 ; GID
            date ; atime
            date ; mtime
            date ; ctime
            (or (alist-get 'size resp) 0) ; size in bytes
            ; TODO figure out if folder has any shares
            (concat (if folder "d" "-") "rwx------") ; perms
            nil
            0
            0))))

(defun dropbox-handle-file-modes (filename)
  448) ; 448 = 0b111000000 is rwx------

(defun dropbox-handle-set-file-modes (filename mode)
  nil)

(defun dropbox-handle-set-file-times (filename &optional timestamp)
  nil)

(defun dropbox-handle-set-visited-file-modtime (&optional time-list)
  ; TODO: this might need to be implemented
  nil)

(defun dropbox-handle-file-selinux-context (filename)
  "Report that files in Dropbox have no SELinux context"
  '(nil nil nil nil))

(defun dropbox-handle-file-selinux-context (filename)
  "Fail to set FILENAME's SELinux context"
  nil)

(defun dropbox-handle-verify-visited-file-modtile (&optional buf)
  "Check that the file BUF is visiting hasn't changed since BUF was opened."

  (let* (metadata new-metadata)
    (setf metadata (dropbox-cached 'metadata (buffer-file-name buf)))
    (dropbox-un-cache 'metadata (buffer-file-name buf))
    (setf newmetadata (dropbox--metadata (buffer-file-name buf)))

    (or (dropbox-error-p newmetadata)
        (string= (alist-get 'rev metadata) (alist-get 'rev newmetadata)))))

;;; Directory Contents

(defun string-strip-prefix (prefix str)
  (if (string-prefix-p prefix str)
      (substring str (length prefix))
      str))

(defun dropbox-extract-fname (file path &optional full)
  (let ((fname (string-strip-prefix "/" (alist-get 'path_display file))))
    (if (string= "folder" (alist-get '.tag file)) (setf fname (concat fname "/")))
    (if full (concat dropbox-prefix fname)
      (string-strip-prefix "/" (string-strip-prefix path fname)))))

(defun dropbox-handle-directory-files (directory &optional full match nosort &rest args)
  "Return a list of names of files in DIRECTORY.
There are three optional arguments:
If FULL is non-nil, return absolute file names.  Otherwise return names
 that are relative to the specified directory.
If MATCH is non-nil, mention only file names that match the regexp MATCH.
If NOSORT is non-nil, the list is not sorted--its order is unpredictable.
Otherwise, the list returned is sorted with `string-lessp'.
NOSORT is useful if you plan to sort the result yourself."

  (let* ((path (dropbox-strip-prefix directory))
	 (metadata (dropbox--metadata path))
	 (unsorted
	  (if (string= "folder" (alist-get '.tag metadata))
	      (cl-loop for file across (dropbox--list path)
		    for fname = (dropbox-extract-fname (dropbox--metadata file) path full)
		    if (or (null match) (string-match match fname))
		    collect fname)
	    nil)))
    (if nosort unsorted (sort unsorted 'string-lessp))))

(defun dropbox-handle-directory-files-and-attributes (directory &optional full match nosort id-format)
  (let ((files (directory-files directory full match nosort)))
    (list*
     (cons "." (file-attributes directory))
     (cons ".." (file-attributes (dropbox-parent directory)))
     (cl-loop for file in files
           for attrs = (file-attributes (concat (file-name-as-directory directory)
                                                file) id-format)
           collect (cons file attrs)))))

(defun dropbox-handle-file-name-all-completions (file directory &optional predicate)
  "Complete file name FILE in directory DIRECTORY.
   Returns string if that string is the longest common prefix to files that start with FILE;
           t if only one such file, and it is named FILE;
           nil if no such files"

  (let* ((files (directory-files directory)))
    (all-completions file files predicate)))

(defun dropbox-handle-file-name-completion (file directory &optional predicate)
  "Complete file name FILE in directory DIRECTORY.
   Returns string if that string is the longest common prefix to files that start with FILE;
           t if only one such file, and it is named FILE;
           nil if no such files"

  (let ((files (directory-files directory))
        (predicate (if (eq predicate 'file-exists-p) nil predicate)))
    (try-completion file files predicate)))

(defun dropbox-handle-make-directory (dir &optional parents)
  "Create the directory DIR and, if PARENT is non-nil, all parents"

  (let ((path (dropbox--sanitize-path (dropbox-strip-prefix dir))))
    (if (or parents
            (let ((parent (dropbox-parent dir)))
              (and (file-exists-p parent) (file-directory-p parent))))
	(dropbox-cache
	 'metadata dir
	 (cons '(\.tag . "folder")
	       (alist-get
		'metadata
		(dropbox-request 'mkdir
				 (json-encode `(("path" . ,(encode-coding-string path 'utf-8))
						("autorename" . :json-false))))))))))

(defun dropbox-handle-delete-file (filename &optional trash)
  "Delete file name FILENAME.  If TRASH is nil, permanently delete it."

  (if trash
      (let ((path (dropbox--sanitize-path (dropbox-strip-prefix filename))))
      (dropbox-un-cache 'metadata path)
      (dropbox-request 'rm
		       (json-encode `(("path" . ,(encode-coding-string path 'utf-8))))))
    (error "Perma-trashing files not yet implemented")))

(defun dropbox-handle-delete-directory (directory &optional recursive trash)
  "Delete the directory DIRECTORY.  If TRASH is nil, permanently delete it.
   If RECURSIVE is nil, throw an error if the directory has contents"

  (if (not recursive)
      (error "Non-recursive directory delete not yet implemented")
    (if nil ;(not trash) ; Emacs passes only one argument from delete-directory
        (error "Perma-trashing directories not yet implemented")
      (dropbox-handle-delete-file directory trash))))

(defun dropbox-handle-dired-uncache (dir)
  "Remove DIR from the dropbox.el metadata cache"

  (dropbox-un-cache 'metadata dir)
  (dropbox-un-cache 'list dir))

(defun dropbox-handle-insert-directory
  (filename switches &optional wildcard full-directory-p)
  "Like `insert-directory' for Dropbox files. Code adapted from
`tramp-sh-handle-insert-directory'."

  (setq filename (expand-file-name filename))
  (let ((localname (dropbox-strip-prefix filename)))
    (when (stringp switches)
      (setq switches (split-string switches)))
    (unless full-directory-p
      (setq switches (add-to-list 'switches "-d" 'append)))
    (setq switches (mapconcat 'shell-quote-argument switches " "))
    (dropbox-message
     "Inserting directory `ls %s %s', wildcard %s, fulldir %s"
     switches filename wildcard full-directory-p)

    ; TODO: look into uids, gids, and reformatting the date
    ; example directory listing:
    ; -rw-r--r--   1 ahaven  staff   1476 Jan  7 12:48 tramp.py
    (dropbox-message "FILENAME %s ATTR %s" filename (file-attributes filename))
    (if (not full-directory-p)
        (let ((attributes (file-attributes filename)))
	  (dropbox-message "NOT FULL DIR")
          (insert (format "  %s %2d %8s %8s %8d %s "
                          (elt attributes 8)
                          (elt attributes 1)
                          (elt attributes 2)
                          (elt attributes 3)
                          (elt attributes 7)
                          (format-time-string "%X" (elt attributes 4))))
          (let ((fname (file-name-nondirectory (directory-file-name filename)))
                (start (point))
                (isdir (elt attributes 0)))
            (insert fname "\n")
            (put-text-property start (- (point) 1) 'dired-filename t)))
      (let ((usage (dropbox--space-usage)))
	(dropbox-message "FULL DIR")
        (unless (null usage)
          (let ((used (alist-get 'used usage))
		(allocated (alist-get 'allocated (alist-get 'allocation usage))))
            (insert (format "  used %d available %d (%.0f%% total used)"
                            used (- allocated used)
                            (/ (* used 100.0) allocated)))
            (newline))))
      (cl-loop for file in (if wildcard
                            (directory-files (file-name-directory filename) t filename)
                          (directory-files filename t))
            do (insert-directory file switches)))))

(defun dropbox-handle-dired-insert-directory (dir switches &optional file-list
                                                  wildcard hdr)
  (dropbox-message "Dired insert dir %s switches %s file-list %s wildcard %s hdr %s" dir switches file-list wildcard hdr)
  (if file-list
      (cl-loop for file in file-list
            do (dropbox-handle-insert-directory (concat dir file) switches))
    (dropbox-handle-insert-directory dir switches wildcard t)))

(defun dropbox-handle-copy-file (file newname &optional ok-if-already-exists
                                      keep-time preserve-uid-gid preserve-selinux-context)
  ; TODO: implement ok-if-already-exists parameter
  (cond
   ((and (dropbox-file-p file) (dropbox-file-p newname))
    (dropbox-cache 'metadata newname (dropbox-cached 'metadata file))
    (dropbox-un-cache 'metadata (file-name-directory newname))
    (let ((from-path (dropbox--sanitize-path (dropbox-strip-prefix file)))
          (to-path (dropbox--sanitize-path (dropbox-strip-prefix newname))))
      (dropbox-cache 'metadata newname
                     (dropbox-request
                      'copy
                      (json-encode
                       `(("from_path" . ,(encode-coding-string from-path 'utf-8))
                         ("to_path" . ,(encode-coding-string to-path 'utf-8))))))))
   ((and (dropbox-file-p file) (not (dropbox-file-p newname)))
    (move-file (file-local-copy file) newname))
   ((and (not (dropbox-file-p file)) (dropbox-file-p newname))
    (dropbox-upload file newname))))

(defun dropbox-handle-copy-directory (directory newname &optional keep-time
                                                parents copy-contents)
  (cond
   ((and (dropbox-file-p file) (dropbox-file-p newname))
    (if parents (make-directory (dropbox-parent newname) parents))
    (copy-file directory newname nil keep-time parents copy-contents))
   (t
    (error "Copying directories between the local storage and Dropbox is not supported"))))

(defun dropbox-handle-rename-file (file newname &optional ok-if-already-exists)
  "Renames FILE to NEWNAME.  If OK-IF-ALREADY-EXISTS is nil, signal an error if
NEWNAME already exists.  Note that the move is atomic if both FILE and NEWNAME
are /db: files, but otherwise is not necessarily atomic."

  (cond
   ((and (dropbox-file-p file) (dropbox-file-p newname))
    (dropbox-cache 'metadata newname (dropbox-cached 'metadata file))
    (dropbox-un-cache 'metadata file)
    (dropbox-un-cache 'metadata (file-name-directory file))
    (dropbox-un-cache 'metadata (file-name-directory newname))
    (let ((from-path (dropbox--sanitize-path (dropbox-strip-prefix file)))
          (to-path (dropbox--sanitize-path (dropbox-strip-prefix newname))))
      (dropbox-cache 'metadata newname
                     (dropbox-request
                      'move
                      (json-encode
                       `(("from_path" . ,(encode-coding-string from-path 'utf-8))
                         ("to_path" . ,(encode-coding-string to-path 'utf-8))))))))
   ((and (dropbox-file-p file) (not (dropbox-file-p newname)))
    (copy-file file newname ok-if-already-exists)
    (delete-file file t))
   ((and (not (dropbox-file-p file)) (dropbox-file-p newname))
    (copy-file file newname ok-if-already-exists)
    (delete-file file t))))

(defun dropbox-handle-make-symbolic-link (filename linkname
                                                   &optional ok-if-already-exists)
  (error "Dropbox cannot hold symbolic links"))

(defun dropbox-handle-add-name-to-file (file newname
                                             &optional ok-if-already-exists)
  (error "Dropbox cannot handle hard links"))

(defun dropbox-handle-executable-find (command)
  "Fail to find any commands"
  nil)

;;; File contents

(defun dropbox-handle-insert-file-contents (filename &optional visit beg end replace)
  (barf-if-buffer-read-only)
  (when (or beg end)
    (error "Dropbox cannot handle beginning and end bytes on insert-file"))
  (if (file-exists-p filename)
      (save-excursion
        (when replace
          ;; TODO: retain point and mark when erasing
          (erase-buffer))
        (let* ((path (encode-coding-string (dropbox--sanitize-path (dropbox-strip-prefix filename)) 'utf-8))
               (contents (dropbox-request 'download nil (json-encode `(("path" . ,path))))))
          (insert (decode-coding-string contents 'utf-8))))
    (set-buffer-modified-p nil))
  (when visit
    (setf buffer-file-name filename)
    (setf buffer-read-only (not (file-writable-p filename)))))

(defun dropbox-upload (local-path remote-path &optional overwrite)
  (let ((remote (dropbox--sanitize-path (dropbox-strip-prefix remote-path))))
    (dropbox-cache 'metadata remote-path
		   (dropbox-request 'upload (with-temp-buffer
					      (insert-file-contents local-path)
					      (buffer-string))
				    (json-encode `(("path" . ,(encode-coding-string
							       remote
							       'utf-8))
						   ("mode" . ,(if overwrite "overwrite" "add"))
                                                   ("autorename" . t)
						   ("mute" . :json-false)("strict_conflict" . :json-false)))))))

(defun dropbox-handle-file-local-copy (filename)
  "Downloads a copy of a Dropbox file to a temporary file."
  (let ((file (dropbox--sanitize-path (dropbox-strip-prefix filename))))
  (save-excursion
    (let* ((newname (make-temp-file (file-name-nondirectory filename))))
      (if (not (file-exists-p filename))
          (error "File to copy doesn't exist")
        (with-temp-file newname
          (set-buffer-file-coding-system 'utf-8)
          (dropbox-handle-insert-file-contents filename)))
      newname))))

(defun dropbox-handle-dired-compress-file (file)
  "Compress a file in Dropbox.  Super-inefficient."
  (let* ((temp (file-local-copy file))
         (temp.z (dired-compress-file temp))
         (suffix (if (string-prefix-p temp temp.z)
                     (string-strip-prefix temp temp.z)
                   ".gz")))
    (message "compressing %s %s %s %s" file temp temp.z suffix)
    (unless temp.z
      (error "Invalid zipped file %s" temp.z))
    (dropbox-upload temp.z (concat file suffix) t)
    (delete-file file t)))

(defun dropbox-handle-write-region (start end filename &optional
					  append visit lockname mustbenew)
  "Write current region into specified file.
When called from a program, requires three arguments:
START, END and FILENAME.  START and END are normally buffer positions
specifying the part of the buffer to write.
If START is nil, that means to use the entire buffer contents.
If START is a string, then output that string to the file
instead of any buffer contents; END is ignored.

Optional fourth argument APPEND if non-nil means
  append to existing file contents (if any).  If it is an integer,
  seek to that offset in the file before writing.
Optional fifth argument VISIT, if t or a string, means
  set the last-save-file-modtime of buffer to this file's modtime
  and mark buffer not modified.
If VISIT is a string, it is a second file name;
  the output goes to FILENAME, but the buffer is marked as visiting VISIT.
  VISIT is also the file name to lock and unlock for clash detection.
If VISIT is neither t nor nil nor a string,
  that means do not display the \"Wrote file\" message.
The optional sixth arg LOCKNAME, if non-nil, specifies the name to
  use for locking and unlocking, overriding FILENAME and VISIT.
The optional seventh arg MUSTBENEW, if non-nil, insists on a check
  for an existing file with the same name.  If MUSTBENEW is `excl',
  that means to get an error if the file already exists; never overwrite.
  If MUSTBENEW is neither nil nor `excl', that means ask for
  confirmation before overwriting, but do go ahead and overwrite the file
  if the user confirms."

  ; TODO: implement lockname and mustbenew
  (cl-assert (not append)) ; TODO: implement append

  (let ((localfile (make-auto-save-file-name)))
    (write-region start end localfile nil 1)
    ;; TODO: Store old rev and use new rev to ensure we are updating
    (let ((resp (dropbox-upload localfile filename t)))
      (if (dropbox-error-p resp)
          nil
        (when (stringp visit)
          (set-visited-file-name visit))
        (when (or (eq t visit) (stringp visit))
          (set-buffer-modified-p nil))
        (when (or (eq t visit) (eq nil visit) (stringp visit))
          (message "Wrote %s" filename))))))

;;; Misc

(defun dropbox-handle-process-file (program &optional infile buffer display &rest args)
  nil)

(defun dropbox-handle-start-file-process (name buffer program &rest program-args)
  nil)

(defun dropbox-handle-shell-command (command &optional output-buffer error-buffer)
  nil)

(defun dropbox-handle-load (file &optional noerror nomessage nosuffix must-suffix)
  "Loads a Lisp file from Dropbox, by copying it to a temporary"

  (load (file-local-copy file) noerror nomessage nosuffix must-suffix))

;;; dropbox.el ends here
