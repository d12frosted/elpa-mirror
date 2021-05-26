;;; tramp-hdfs.el --- Tramp extension to access hadoop/hdfs file system in Emacs

;; Copyright (C) 2015  The Tramp HDFS Developers
;;
;; Version: 0.3.0
;; Package-Version: 20210526.339
;; Package-Commit: aa93bdbb3d5619c262ce53af1981edcd2a0705e5
;; Author: Raghav Kumar Gautam <raghav@apache.org>
;; Keywords: tramp, emacs, hdfs, hadoop, webhdfs, rest
;; Package-Requires: ((emacs "24.4"))
;; Acknowledgements: Thanks to tramp-smb.el, tramp-sh.el for inspiration & code.
;;
;; Contains code from GNU Emacs <https://www.gnu.org/software/emacs/>,
;; released under the GNU General Public License version 3 or later.
;; You should have received a copy of the GNU General Public License
;; along with tramp-hdfs.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;; Access hadoop/hdfs over Tramp.
;; This program uses rest api/webhdfs to access hadoop server.
;;
;; Configuration:
;;   Add the following lines to your .emacs:
;;
;;   (add-to-list 'load-path "<<directory containing tramp-hdfs.el>>")
;;   (require 'tramp-hdfs);;; Code:
;;
;; Usage:
;;   open /hdfs:root@node-1:/tmp/ in Emacs
;;   where root   is the user that you want to use
;;         node-1 is the name of the hadoop server
;;
;;; Code:

(require 'tramp)
(require 'tramp-sh)
(require 'time-date)
(require 'json)
(require 'subr-x)
(require 'url)

;; Pacify byte-compiler.
(eval-when-compile
  (require 'cl))

(defconst tramp-hdfs-method "hdfs"
  "Method to connect HDFS2 servers.")

(defconst hdfs-status-op "GETFILESTATUS"
  "Rest operation for getting status of one file.")

(defconst hdfs-open-op "OPEN"
  "Rest operation for getting content of a file.")

(defconst hdfs-list-op "LISTSTATUS"
  "Rest operation for listing a dir.")

(defconst hdfs-delete-op "DELETE"
  "Rest operation for deleting a file/dir.")


(defcustom tramp-hdfs-curl-program "curl"
  "Command to invoke curl.

Set to nil to use the built-in 'url package."
  :group 'tramp-hdfs
  :type 'file)

(defcustom tramp-hdfs-curl-options
  '("-k" "-s" "-S" "-L")
  "List of options for `tramp-hdfs-curl-program'.

To use Kerberos SPNEGO authentication, add the following: \"--negotiate\" \"-u\" \":\"."
  :group 'tramp-hdfs
  :type '(repeat string))

(defcustom hdfs-default-dir "/"
  "HDFS default directory."
  :group 'tramp-hdfs
  :type 'string)

(defcustom hdfs-bigfile-threshold (* 1024 1024)
  "HDFS list command to list one file/dir."
  :group 'tramp-hdfs
  :type 'integer)

(defcustom webhdfs-port 50070
  "Port number of WebHDFS server."
  :group 'tramp-hdfs
  :type 'integer)

(defcustom webhdfs-protocol "http"
  "Port number of WebHDFS server."
  :group 'tramp-hdfs
  :type 'string)

(defcustom webhdfs-endpoint "/webhdfs/v1"
  "Port number of WebHDFS server."
  :group 'tramp-hdfs
  :type 'string)

(add-to-list 'tramp-default-user-alist
	     `(,(concat
		 "\\`"
		 (regexp-opt '("hdfs"))
		 "\\'")
	       nil ,(user-login-name)))

;; ... and add it to the method list.
;;;###tramp-autoload
(add-to-list 'tramp-methods
	     `(,tramp-hdfs-method))

;;;###autoload
(eval-after-load 'tramp
  '(tramp-set-completion-function "hdfs" tramp-completion-function-alist-ssh))

;; New handlers should be added here.
(defconst tramp-hdfs-file-name-handler-alist
  '(;; `access-file' performed by default handler.
    (add-name-to-file . ignore)
    ;; `byte-compiler-base-file-name' performed by default handler.
    (copy-directory . ignore)
    (copy-file . tramp-sh-handle-copy-file)
    (delete-directory . tramp-hdfs-handle-delete-directory)
    (delete-file . tramp-hdfs-handle-delete-file)
    ;; `diff-latest-backup-file' performed by default handler.
    (directory-file-name . tramp-handle-directory-file-name)
    (directory-files . tramp-handle-directory-files)
    (directory-files-and-attributes . tramp-handle-directory-files-and-attributes)
    (dired-call-process . ignore)
    (dired-compress-file . ignore)
    ;;(dired-recursive-delete-directory .
    (dired-uncache . tramp-handle-dired-uncache)
    (expand-file-name . tramp-hdfs-handle-expand-file-name)
    (file-accessible-directory-p . tramp-hdfs-handle-file-directory-p)
    (file-acl . ignore)
    (file-attributes . tramp-hdfs-handle-file-attributes)
    (file-directory-p . tramp-hdfs-handle-file-directory-p)
    (file-executable-p . tramp-handle-file-exists-p)
    (file-exists-p . tramp-handle-file-exists-p)
    ;; `file-in-directory-p' performed by default handler.
    (file-local-copy . tramp-hdfs-handle-file-local-copy)
    (file-modes . tramp-handle-file-modes)
    (file-name-all-completions . tramp-hdfs-handle-file-name-all-completions)
    (file-name-as-directory . tramp-handle-file-name-as-directory)
    (file-name-completion . tramp-handle-file-name-completion)
    (file-name-directory . tramp-handle-file-name-directory)
    (file-name-nondirectory . tramp-handle-file-name-nondirectory)
    (file-newer-than-file-p . tramp-handle-file-newer-than-file-p)
    (file-notify-add-watch . tramp-handle-file-notify-add-watch)
    (file-notify-rm-watch . tramp-handle-file-notify-rm-watch)
    (file-ownership-preserved-p . ignore)
    (file-readable-p . tramp-handle-file-exists-p)
    (file-regular-p . tramp-handle-file-regular-p)
    (file-remote-p . tramp-handle-file-remote-p)
    ;; `file-selinux-context' performed by default handler.
    ;; `file-truename' performed by default handler.
    (file-writable-p . ignore)
    ;; `find-file-noselect' performed by default handler.
    ;; `get-file-buffer' performed by default handler.
    (insert-directory . tramp-hdfs-handle-insert-directory)
    (insert-file-contents . tramp-handle-insert-file-contents)
    (insert-file-contents-literally . ignore)
    (load . tramp-handle-load)
    (make-auto-save-file-name . ignore)
    (make-directory . ignore)
    (make-symbolic-link . ignore)
    (process-file . ignore)
    (rename-file . ignore)
    (set-file-acl . ignore)
    (set-file-modes . ignore)
    (set-file-selinux-context . ignore)
    (set-file-times . ignore)
    (set-visited-file-modtime . tramp-handle-set-visited-file-modtime)
    (shell-command . ignore)
    (start-file-process . ignore)
    (unhandled-file-name-directory . ignore)
    (vc-registered . ignore)
    (verify-visited-file-modtime . tramp-handle-verify-visited-file-modtime)
    (write-region . ignore))
  "Alist of handler functions.
Operations not mentioned here will be handled by the default Emacs primitives.")

;; It must be a `defsubst' in order to push the whole code into
;; tramp-loaddefs.el.  Otherwise, there would be recursive autoloading.
;;;###tramp-autoload
(defsubst tramp-hdfs-file-name-p (filename)
  "Check if it's a FILENAME for hdfs servers."
  (string= (tramp-file-name-method (tramp-dissect-file-name filename))
	   tramp-hdfs-method))


;;;###tramp-autoload
(defun tramp-hdfs-file-name-handler (operation &rest args)
  "Invoke the hdfs related OPERATION.
First arg specifies the OPERATION, second arg is a list of arguments to
pass to the OPERATION.
Optional argument ARGS is a list of arguments to pass to the OPERATION."
  (if (not (boundp 'tramp-locked))
      (tramp-hdfs-file-name-handler-nolock operation args)
    ;; This is compatibility code for Emacs versions before 26, in
    ;; which specific Tramp modules did locking.  In Emacs 26 (see
    ;; commit 138447c3abd749d1c27d99d7089b1b0903352ade) locking was
    ;; moved to tramp-file-name-handler, so this code can be removed
    ;; when support for these older Emacsen is dropped.
    ;;
    ;; The global lock was implemented via two variables:
    ;; `tramp-locked' (non-nil if global lock taken by someone) and
    ;; `tramp-locker' (actual locker let-bounds it to non-nil so that
    ;; it may call tramp recursively).
    (when (and tramp-locked (not tramp-locker))
      (setq tramp-locked nil)
      (tramp-error
       (car-safe tramp-current-connection) 'file-error
       "Forbidden reentrant call of Tramp"))
    (let ((tl tramp-locked))
      (setq tramp-locked t)
      (unwind-protect
	  (let ((tramp-locker t))
            (tramp-hdfs-file-name-handler-nolock operation args))
        (setq tramp-locked tl)))))

(defun tramp-hdfs-file-name-handler-nolock (operation args)
  (save-match-data
    (let ((fn (assoc operation tramp-hdfs-file-name-handler-alist)))
      (if fn
	  (apply (cdr fn) args)
	(tramp-run-real-handler operation args)))))

;;;###tramp-autoload
(add-to-list 'tramp-foreign-file-name-handler-alist
	     (cons 'tramp-hdfs-file-name-p 'tramp-hdfs-file-name-handler))

;;hadoop rest api https://hadoop.apache.org/docs/r1.0.4/webhdfs.html
(defun tramp-hdfs-get-url-content (url vec)
  "Run a get request for the URL and get the content."
  (tramp-hdfs-do-rest-call "GET" url vec))

(defun tramp-hdfs-delete-url (url vec)
  "Run a http delete request at the URL and get the content returned."
  (tramp-hdfs-do-rest-call "DELETE" url vec))

(defun tramp-hdfs-put-url-get-redirect (url vec)
  "Run a put request at the URL and get the redirected url."
  (tramp-hdfs-do-rest-call "PUT" url vec))
;;(tramp-hdfs-put-url-get-redirect "http://node-1:50070/webhdfs/v1/tmp/test2.txt?user.name=rgautam&op=CREATE")

;;(tramp-hdfs-do-rest-call "GET" "http://node-1:50070/webhdfs/v1/?user.name=root&op=LISTSTATUS" nil)
;;(tramp-hdfs-do-rest-call "GET" "http://node-1:50070/webhdfs/v1/?user.name=hdfs&op=GETFILESTATUS" nil)
;;(tramp-hdfs-do-rest-call "GET" "http://node-1:50070/webhdfs/v1/?user.name=hdfs&op=LISTSTATUS" nil)
;;(let ((tramp-hdfs-curl-program nil))(tramp-hdfs-do-rest-call "GET" "http://google.com" nil))

(defun tramp-hdfs-do-rest-call (method url vec)
  "Do a rest call using method METHOD to the url & return the results."
  (tramp-message vec 10 "Method: %s Url: %s" method url)
  (let ((response
	 (if tramp-hdfs-curl-program
             (let ((args (append tramp-hdfs-curl-options (list "-X" method url))))
	       (tramp-message vec 10 "Command: %s %s" tramp-hdfs-curl-program args)
	       (string-trim (with-output-to-string
			      (with-current-buffer
				  standard-output
                                (apply #'call-process tramp-hdfs-curl-program nil t nil args)))))
	   (let* ((url-request-method method)
		  (url-http-attempt-keepalives nil)
		  (buff (url-retrieve-synchronously url))
		  (response-headers '()))
	     (with-current-buffer (url-retrieve-synchronously url)
	       (tramp-hdfs-delete-http-header* (current-buffer))
	       (buffer-string))))))
    (tramp-message vec 10 "Method: %s Url: %s Response: %s" method url response)
    response))

(defconst http-header-regexp "^\\([^ :]+\\): \\(.*\\)$")

(defun tramp-hdfs-delete-http-header* (buffer)
  "Given a BUFFER with HTTP response, delete the headers.  Return parsed status and headers as list."
  (when (buffer-live-p buffer)
      (with-current-buffer buffer
	(goto-char (point-min))
	(let ((response-headers '())
	      (response-status (buffer-substring-no-properties (point) (point-at-eol))))
	  (forward-line)
	  (while (looking-at http-header-regexp)
	    (setq response-headers
		  (cons
		   (cons
		    (buffer-substring-no-properties (match-beginning 1) (match-end 1))
		    (buffer-substring-no-properties (match-beginning 2) (match-end 2)))
		   response-headers))
	    (forward-line))
	  (forward-line)
	  (delete-region (point-min) (point))
	  (list response-status response-headers)))))

(defun tramp-hdfs-handle-expand-file-name (name &optional dir)
  "Like `expand-file-name' for Tramp files.
If the localname part of the given file starts with \"/../\" then
the result will be a local, non-Tramp, filename.
Argument NAME The name that needs to be expanded.
Optional argument DIR The directory to use for expansion. If nil use present working directory."
  ;; If DIR is not given, use `default-directory' or "/".
  (setq dir (or dir default-directory "/"))
  ;; Unless NAME is absolute, concat DIR and NAME.
  (unless (file-name-absolute-p name)
    (setq name (concat (file-name-as-directory dir) name)))
  ;; If NAME is not a Tramp file, run the real handler.
  (if (not (tramp-connectable-p name))
      (tramp-run-real-handler 'expand-file-name (list name nil))
    ;; Dissect NAME.
    (with-parsed-tramp-file-name name nil
      (unless (tramp-run-real-handler 'file-name-absolute-p (list localname))
	(setq localname (concat "/" localname)))
      ;; There might be a double slash, for example when "~/"
      ;; expands to "/".  Remove this.
      (while (string-match "//" localname)
	(setq localname (replace-match "/" t t localname)))
      ;; No tilde characters in file name, do normal
      ;; `expand-file-name' (this does "/./" and "/../").  We bind
      ;; `directory-sep-char' here for XEmacs on Windows, which would
      ;; otherwise use backslash.  `default-directory' is bound,
      ;; because on Windows there would be problems with UNC shares or
      ;; Cygwin mounts.
      (let ((directory-sep-char ?/)
	    (default-directory (tramp-compat-temporary-file-directory)))
	(tramp-make-tramp-file-name
         v
	 (tramp-drop-volume-letter
	  (tramp-run-real-handler
	   'expand-file-name (list localname))))))))

(defun tramp-hdfs-handle-file-attributes (filename &optional id-format)
  "Like `file-attributes' for Tramp files.
Argument FILENAME the file.
Optional argument ID-FORMAT ignored."
  (unless id-format (setq id-format 'integer))
  (ignore-errors
    (with-parsed-tramp-file-name (expand-file-name filename) nil
      (with-tramp-file-property
	  v localname (format "file-attributes-%s" id-format)
	(let* ((url (tramp-hdfs-create-url localname hdfs-status-op v))
	       (file-status (cdar (tramp-hdfs-json-to-lisp (tramp-hdfs-get-url-content url v) v))))
	  (tramp-hdfs-decode-file-status file-status v))))))

(defun file-modes-number-to-string (mode-num)
  "Convert permission like 766 to rwx-wx-wx.
Argument MODE-NUM is the file mode as numbers."
  (when (string-match "[0-7]?\\([0-7]\\{3\\}\\)" mode-num)
    (let ((perm (match-string 1 mode-num)))
      (let ((res ""))
	(dolist (p (delete "" (split-string perm "")) res)
	  (setq res
		(concat res
			(let ((one-digit (string-to-number p)))
			  (concat (if (= 4 (logand 4 one-digit)) "r" "-")
				  (if (= 2 (logand 2 one-digit)) "w" "-")
				  (if (= 1 (logand 1 one-digit)) "x" "-"))))))))))

(defun tramp-hdfs-create-url (path op v &optional suffix)
  "Create url.
Argument PATH the file/dir path.
Argument OP operation to be performed on the path.
Argument V vector.
Optional argument SUFFIX extra arguments to be appended to url."
  (unless (string-match-p "^/" path)
    (setq path (concat "/" path)))
  (let ((url (concat
	      ;;http://node-1:57000/webhdfs/v1
	      (format "%s://%s:%s%s" webhdfs-protocol
                      (tramp-file-name-host v)
                      (or (tramp-file-name-port v) (number-to-string webhdfs-port))
                      webhdfs-endpoint)
	      ;;/tmp?user.name=root&op=OPEN
	      (format "%s?user.name=%s&op=%s"  path (tramp-file-name-user v) op)
	      (when suffix "&") suffix)))
    ;;(tramp-debug-message v "Constructed url: %s" url)
    url))

(defun tramp-hdfs-json-to-lisp (string vec)
  "Convert supplied JSON to Lisp notation.
Argument STRING the json string.
Argument VEC specifies the connection."
  (let* ((lisp-data (json-read-from-string string))
	 (exception (assoc 'RemoteException lisp-data)))
    (if exception
	(let ((error-message (cdr (assoc 'message exception))))
	  (tramp-error vec 'file-error "%s" error-message))
      lisp-data)))

(defun tramp-hdfs-decode-file-status (file-status vec)
  "Decode association list to normal list.
Argument FILE-STATUS is the file status as association list.
Argument VEC specifies the connection."
  (let* ((dir? (string= (cdr (assoc 'type file-status)) "DIRECTORY"))
	 (replication (cdr (assoc 'replication file-status)))
	 (uid         (cdr (assoc 'owner       file-status)))
	 (gid         (cdr (assoc 'group       file-status)))
	 (access-time '(0 0))
	 (modification-time (seconds-to-time (/ (cdr (assoc 'modificationTime file-status)) 1000.0)))
	 (status-change-time '(0 0))
	 (size        (cdr (assoc 'length      file-status)))
	 (mode        (concat
		       (if dir? "d" "-")
		       (file-modes-number-to-string (cdr (assoc 'permission  file-status)))))
	 (ignore nil)
	 (inode nil)
	 (device (tramp-get-device vec)))
    ;;(pp file-status)
    (list dir? replication uid gid access-time modification-time status-change-time size mode ignore inode device)))

(defun tramp-hdfs-handle-file-directory-p (filename)
  "Like `file-directory-p' for Tramp files.
FILENAME the filename to check."
  (and (file-exists-p filename)
       (eq ?d (aref (nth 8 (file-attributes filename)) 0))))

(defun tramp-hdfs-get-size-params (size)
  "Get url parameters needed for this file SIZE."
  (when (> size hdfs-bigfile-threshold)
    (let ((start-offset (read-number (format "The requested file is %s bytes (=%s) long. Recommending fetching part of the file. Please enter start offset(starting at zero): "
					     size
					     (file-size-human-readable size))))
	  (length (read-number "Length of the part that you wish to fetch:")))
      (format "offset=%s&length=%s" start-offset length))))

(defun tramp-hdfs-handle-file-local-copy (filename)
  "Like `file-local-copy' for Tramp files.
FILENAME the filename to be copied locally."
  (with-parsed-tramp-file-name filename nil
    (unless (file-exists-p filename)
      (tramp-error
       v 'file-error
       "Cannot make local copy of non-existing file `%s'" filename))
    (let* ((size (nth 7 (file-attributes (file-truename filename))))
	   (url-size-params (tramp-hdfs-get-size-params size))
	   (url (tramp-hdfs-create-url localname hdfs-open-op v url-size-params))
	   (content (tramp-hdfs-get-url-content url v))
	   (tmpfile (tramp-compat-make-temp-file filename)))
      (let ((coding-system-for-write 'no-conversion)) (write-region content nil tmpfile))
      ;; Set proper permissions.
      (set-file-modes tmpfile (tramp-default-file-modes filename))
      ;; Set local user ownership.
      (tramp-set-file-uid-gid tmpfile)
      (message "Written content to: %s %s %s" tmpfile (md5 content) (md5 tmpfile))
      (run-hooks 'tramp-handle-file-local-copy-hook)
      tmpfile)))

(defun tramp-hdfs-handle-file-name-all-completions (file directory)
  "Like `file-name-all-completions' for Tramp files.
Return a list of all completions of file name FILE in directory DIRECTORY.
These are all file names in directory DIRECTORY which begin with FILE."
  (all-completions
   file
   (with-parsed-tramp-file-name directory nil
     (with-tramp-file-property v localname "file-name-all-completions"
       (let ((file-list (tramp-hdfs-list-directory v)))
	 (mapcar
	  (lambda (one-status)
	    (let* ((dir? (string= (cdr (assoc 'type one-status)) "DIRECTORY")))
	      (concat (cdr (assoc 'pathSuffix one-status)) (when dir? "/"))))
	  file-list))))))

(defun tramp-hdfs-create-one-line (file-status vec)
  "Decode assoc list to a line that can be inserted in the tramp buffer."
  (let* ((decoded-status (tramp-hdfs-decode-file-status file-status vec))
	 (dir?         (first  decoded-status))
	 (replication  (second decoded-status))
	 (uid          (third  decoded-status))
	 (gid          (fourth decoded-status))
	 ;;access time is not required
	 (mtime        (sixth decoded-status))
	 ;;status change time is not needed
	 (size         (eighth decoded-status))
	 (mode         (ninth  decoded-status))
	 ;;ninth element is always nil
	 ;;tenth element is always nil
	 (device       (nth 12 decoded-status))
	 (filename (concat (cdr (assoc 'pathSuffix file-status)) (when dir? "/"))))
    (format
     "%10s %3s %-10s %-10s %8s %s %s\n"
     (or mode "----------") ; mode
     (or replication "-") ; inode
     (or uid "nobody") ; uid
     (or gid "nogroup") ; gid
     (or size "0") ; size
     (format-time-string
      (if (time-less-p
           ;; Half a year
	   (time-since mtime) (days-to-time 183))
	  "%b %e %R"
	"%b %e %Y")
      mtime)
     filename)))

(defun tramp-hdfs-list-directory (v)
  "List files of a hdfs dir."
  (let* ((url (tramp-hdfs-create-url (tramp-file-name-localname v) hdfs-list-op v))
	 (retval (tramp-hdfs-json-to-lisp (tramp-hdfs-get-url-content url v) v)))
    (cdadar retval)))

(defun tramp-hdfs-handle-insert-directory
    (filename switches &optional wildcard full-directory-p)
  "Like `insert-directory' for Tramp files."
  (setq filename (expand-file-name filename))
  (unless switches (setq switches ""))
  (if full-directory-p
      ;; Called from `dired-add-entry'.
      (setq filename (file-name-as-directory filename))
    (setq filename (directory-file-name filename)))
  (with-parsed-tramp-file-name filename nil
    (save-match-data
      (with-current-buffer (current-buffer)
	(insert
	 (let* ((file-list (tramp-hdfs-list-directory v)))
	   (mapconcat (lambda (one-status) (tramp-hdfs-create-one-line one-status v)) file-list "")))))))

(defun tramp-hdfs-handle-delete-directory (directory &optional recursive)
  "Like `delete-directory' for Tramp files."
  (setq directory (directory-file-name (expand-file-name directory)))
  (with-parsed-tramp-file-name directory nil
    ;; We must also flush the cache of the directory, because
    ;; `file-attributes' reads the values from there.
    (tramp-flush-file-properties v (file-name-directory localname))
    (tramp-flush-directory-properties v localname)
    (let ((url (tramp-hdfs-create-url
		localname
		hdfs-delete-op
		v
		(if recursive "recursive=true" "recursive=false"))))
      (tramp-hdfs-json-to-lisp (tramp-hdfs-delete-url url v) v))))

(defun tramp-hdfs-handle-delete-file (filename &optional _trash)
  "Like `delete-file' for Tramp files."
  (setq filename (expand-file-name filename))
  (when (file-exists-p filename)
    (with-parsed-tramp-file-name filename nil
      ;; We must also flush the cache of the directory, because
      ;; `file-attributes' reads the values from there.
      (tramp-flush-file-properties v (file-name-directory localname))
      (tramp-flush-file-properties v localname)
      (let ((url (tramp-hdfs-create-url
		localname
		hdfs-delete-op
		v
		"recursive=false")))
	(tramp-hdfs-json-to-lisp (tramp-hdfs-delete-url url v) v)))))

(add-hook 'tramp-unload-hook
	  (lambda ()
	    (unload-feature 'tramp-hdfs 'force)))

(provide 'tramp-hdfs)

;;; tramp-hdfs.el ends here
