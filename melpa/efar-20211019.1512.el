;;; efar.el --- FAR-like file manager -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Vladimir Suntsov

;; Author: "Vladimir Suntsov" <vladimir@suntsov.online>
;; Maintainer: vladimir@suntsov.online
;; Version: 1.28
;; Package-Version: 20211019.1512
;; Package-Commit: ff82fa01dd350d662cdef1fbf3db57425abc3649
;; Package-Requires: ((emacs "26.1"))
;; Keywords: files
;; URL: https://github.com/suntsov/efar

;; This package is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This package is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides FAR-like file manager with some extended
;; functionality, like file search, directory comparison, etc.

;; To start eFar just type M-x efar.
;; When Efar is called with universal argument (C-u M-x efar),
;; default-directory of actual buffer is automatically opened in left panel.

;; Press <C-e ?> to show buffer with all available key bindings.

;; Use M-x customize to configure numerous eFar parameters.

;;; Code:

(require 'subr-x)
(require 'filenotify)
(require 'dired)
(require 'eshell)
(require 'esh-mode)
(require 'em-dirs)

(defconst efar-version 1.28 "Current eFar version number.")

(defvar efar-state nil)
(defvar efar-mouse-down-p nil)
(defvar efar-rename-map nil)
;; general variables for subprocessing
(defvar efar-subprocess-processes '())
(defvar efar-subprocess-manager nil)
(defvar efar-subprocess-server nil)
(defvar efar-subprocess-server-port nil)
(defvar efar-subprocess-clients '())
(defvar efar-subprocess-pending-messages '())
;; variables for file search
(defvar efar-search-results '())
(defvar efar-search-update-results-timer nil)
(defvar efar-search-running-p nil)
(defvar efar-search-last-command-params nil)
(defvar efar-search-history nil)

;; variables for directory compare
(defvar efar-dir-diff-results (make-hash-table :test 'equal))
(defvar efar-dir-diff-last-command-params nil)
(defvar efar-dir-diff-running-p nil)
(defvar efar-dir-diff-update-results-timer nil)
(defvar efar-dir-diff-current-dir nil)
(defvar efar-dir-diff-show-changed-only-p nil)
(defconst efar-dir-diff-comp-params '(:size :hash :owner :group :modes))
(defvar efar-dir-diff-actual-comp-params '(:size :hash :owner :group :modes))

(defvar efar-valid-keys-for-modes)
(defvar efar-mode-map)

;;--------------------------------------------------------------------------------
;; eFar customization variables
;;--------------------------------------------------------------------------------
;; GROUPS
(defgroup efar nil
  "FAR-like file manager"
  :group 'applications)

(defgroup efar-parameters nil
  "eFar main customization parameters"
  :group 'efar)

(defgroup efar-search-parameters nil
  "eFar file search parameters"
  :group 'efar-parameters)

(defgroup efar-faces nil
  "eFar faces"
  :group 'efar)

;; FACES
(defface efar-search-file-link-face
  '((t :foreground "black"
       :background "snow2"
       :bold t
       :underline t))
  "The face used for representing the link to the file"
  :group 'efar-faces)

(defface efar-search-line-link-face
  '((t :foreground "black"
       :background "ivory"))
  "The face used for representing the link to the source code line"
  :group 'efar-faces)


;; MAIN PARAMETERS
(eval-and-compile
  (defcustom efar-buffer-name "*eFAR*"
    "Name for the Efar buffer."
    :group 'efar-parameters
    :type 'string))

(eval-and-compile
  (defcustom efar-shell-buffer-name "*eFAR shell*"
    "Name for the Efar shell buffer."
    :group 'efar-parameters
    :type 'string))

(eval-and-compile
  (defcustom efar-batch-buffer-name "*eFAR batch operation*"
    "Name for the buffer to perform batch operations."
    :group 'efar-parameters
    :type 'string))

(defcustom efar-dir-diff-results-buffer-name "*eFar directory comparison results*"
  "Name of the buffer to display search results in."
  :group 'efar-parameters
  :type 'string)

(defcustom efar-state-file-name (expand-file-name ".efar-state" user-emacs-directory)
  "Path to the eFar state save file."
  :group 'efar-parameters
  :type 'string)

(defcustom efar-default-startup-dirs (cons user-emacs-directory user-emacs-directory)
  "Default directories shown at startup."
  :group 'efar-parameters
  :type 'cons)

(defcustom efar-save-state-p t
  "Save eFar state when eFar buffer is killed to restore it at next open."
  :group 'efar-parameters
  :type 'boolean)

(defcustom efar-filter-directories-p nil
  "Apply filter to the directories and files (t) or to files only (nil)."
  :group 'efar-parameters
  :type 'boolean)

(defcustom efar-add-slash-to-directories t
  "Add ending / to directories."
  :group 'efar-parameters
  :type 'boolean)

(defcustom efar-auto-read-directories nil
  "Automatically show content of the directory under cursor in other buffer."
  :group 'efar-parameters
  :type 'boolean)

(defcustom efar-auto-read-files t
  "Automatically show content of the file under cursor in other buffer."
  :group 'efar-parameters
  :type 'boolean)

(defcustom efar-auto-read-file-extensions (list "el" "py" "magik" "txt")
  "List of file types (extensions) to be automatically read."
  :group 'efar-parameters
  :type 'list)

(defcustom efar-auto-read-max-file-size 1048576
  "Maximum size in bytes for files which will be automatically read."
  :group 'efar-parameters
  :type 'integer)

(defcustom efar-max-items-in-directory-history 100
  "Maximum number of directories to be stored in directory history."
  :group 'efar-parameters
  :type 'integer)

(defcustom efar-fast-search-filter-enabled-p t
  "Filter out not matching files in fast search mode."
  :group 'efar-parameters
  :type 'boolean)

(defcustom efar-subprocess-max-processes 8
  "Number of subprocesses to use for file search."
  :group 'efar-search-parameters
  :type 'integer)

(defcustom efar-search-results-buffer-name "*eFar search results*"
  "Name of the buffer to display search results in."
  :group 'efar-search-parameters
  :type 'string)

(defcustom efar-search-default-file-mask "*.el"
  "Default file name mask to use for file search."
  :group 'efar-search-parameters
  :type 'string)

(defcustom efar-subprocess-coding 'iso-latin-1
  "Coding system to use for background operations (file search, directory compare)."
  :group 'efar-search-parameters
  :type 'symbol)

(defcustom efar-search-follow-symlinks-p t
  "Follow directory symlinks when searching?"
  :group 'efar-search-parameters
  :type 'boolean)

;; macros
(defmacro efar-with-notification-disabled(&rest body)
  "Execute BODY with efar-notifications disabled."
  `(let ((file-notifier-left (efar-get :panels :left :file-notifier))
	 (file-notifier-right (efar-get :panels :right :file-notifier)))
     
     (when (file-notify-valid-p (cdr file-notifier-left))
       (efar-remove-notifier :left))
     
     (when (file-notify-valid-p (cdr file-notifier-right))
       (efar-remove-notifier :right))
     
     ,@body
     
     (efar-setup-notifier (efar-get :panels :left :dir) :left)
     (efar-setup-notifier (efar-get :panels :right :dir) :right)))

(defmacro efar-write-enable (&rest body)
  "Make eFar buffer writable, execute BODY and then make it back read-only."
  `(with-current-buffer ,efar-buffer-name
     (read-only-mode -1)
     ,@body
     (read-only-mode 1)))

(defmacro efar-retry-when-error (&rest body)
  "Retry BODY until success or user answers 'No'."
  `(while
       (string=
	"error"
	(condition-case err
	    ,@body
	  (error (when
		     (string= "Yes"
			      (efar-completing-read
			       (concat "Error: \"" (error-message-string err) "\". Try again? ")
			       (list "Yes" "No")))
		   "error"))))))

(defmacro efar-when-can-execute(&rest body)
  "Execute BODY only if command is allowed in current panel mode."
  `(progn
     (efar nil)
     (let ((mode (efar-get :panels (efar-get :current-panel) :mode))
	   (def (assoc this-command efar-valid-keys-for-modes)))
       
       (if (and def
		(not (cl-member mode (cdr def))))
	   (progn
	     (efar-set-status (format "Function '%s' is not allowed in mode '%s'" this-command (symbol-name mode)) nil t t)	   )
	 ,@body))))

;;--------------------------------------------------------------------------------
;; eFar main functions
;;--------------------------------------------------------------------------------
;;;###autoload
(defun efar (arg &optional reinit? no-switch?)
  "Main function to run eFar commander.
When ARG is t open default directory of current buffer.
When REINIT? is t then current eFar state is discarded and it is reinitialized.
When NO-SWITCH? is t then don't switch to eFar buffer."
  (interactive "P")
  (let
      ;; if eFar buffer doesn't exist, we need to do initialisation
      ((need-init? (or reinit? (not (get-buffer efar-buffer-name))))
       ;; get existing or create new eFar buffer
       (efar-buffer (get-buffer-create efar-buffer-name))
       ;; if eFar is called with prefix argument, then go to default-directory of current buffer
       (go-to-dir (when arg default-directory)))
    
    (with-current-buffer efar-buffer
      
      (unless (equal major-mode 'efar-mode)
	(efar-mode))
      ;; do initialisation if necessary and redraw the content of the buffer
      (when need-init?
	(efar-init)

	(efar-set-theme)
	
	;; make search processes
	;; we do this in advance to speed up search process
	(make-thread 'efar-subprocess-run-processes)
	
	(efar-calculate-window-size)
	(efar-calculate-widths)
	(efar-go-to-dir (efar-get :panels :left :dir) :left)
	(efar-go-to-dir (efar-get :panels :right :dir) :right)
	(efar-write-enable
	 (efar-redraw)))
      
      ;; go to default-directory of current buffer if function is called with prefix argument
      (when go-to-dir
	(efar-go-to-dir go-to-dir :left)
	(efar-write-enable (efar-redraw)))
      
      (unless no-switch? (efar-do-suggest-hint)))
    
    (unless (or no-switch?
		(equal efar-buffer (current-buffer)))
      (switch-to-buffer-other-window efar-buffer))
    (efar-write-enable (efar-redraw))))


(defun efar-init (&optional reinit?)
  "Set up main eFAR configuration.
This function is executed only once when eFAR buffer is created.

REINIT? is a boolean indicating that configuration should be generated enew."
  
  ;; disable cursor
  (setq cursor-type nil)
  
  ;; if saving/restoring of state is allowed then read state from file
  (when (and
	 efar-save-state-p
	 (file-exists-p efar-state-file-name))
    (efar-read-state))
  
  ;; if eFAR state cannot be restored from file (missing or broken file) or saving/restoring of state is disabled
  ;; then initialize state storage with default values
  (when (or reinit?
	    (null efar-state))
    (setf efar-state nil)
    (efar-init-state)))

(defun efar-init-state ()
  "Initialize state with default values."
  (setf efar-state (make-hash-table :test `equal))
  
  ;; set directories for both panels
  (efar-set (car efar-default-startup-dirs) :panels :left :dir)
  (efar-set (cdr efar-default-startup-dirs) :panels :right :dir)
  
  ;; make left panel active
  (efar-set :left :current-panel)
  
  ;; set cursor to the first file for both panels
  (efar-set 0 :panels :left :current-pos)
  (efar-set 0 :panels :right :current-pos)
  
  (efar-set '() :panels :left :selected)
  (efar-set '() :panels :right :selected)
  
  (efar-set 0 :panels :left :start-file-number)
  (efar-set 0 :panels :right :start-file-number)
  
  (efar-set nil :fast-search-string)
  (efar-set 0 :fast-search-occur)
  
  (efar-set nil :notification-timer)
  
  (efar-set "" :panels :left :file-filter)
  (efar-set "" :panels :right :file-filter)
  
  (efar-set nil :panels :left :file-notifier)
  (efar-set nil :panels :right :file-notifier)
  
  (efar-set :files :panels :left :mode)
  (efar-set :files :panels :right :mode)
  
  (efar-set '() :pending-notifications)
  
  (efar-set nil :panels :left :sort-order)
  (efar-set nil :panels :right :sort-order)
  
  (efar-set "Name" :panels :left :sort-function-name)
  (efar-set "Name" :panels :right :sort-function-name)
  
  (efar-set :both :mode)
  
  (efar-set nil :column-widths)
  
  (efar-set "Ready" :status)
  (efar-set nil :reset-status?)
  
  (efar-set 1 :panels :left :view :files :column-number)
  (efar-set '(:short :long :detailed :full) :panels :left :view :files :file-disp-mode)
  (efar-set 1 :panels :left :view :dir-hist :column-number)
  (efar-set '(:long) :panels :left :view :dir-hist :file-disp-mode)
  (efar-set 1 :panels :left :view :file-hist :column-number)
  (efar-set '(:long) :panels :left :view :file-hist :file-disp-mode)
  (efar-set 1 :panels :left :view :bookmark :column-number)
  (efar-set '(:long) :panels :left :view :bookmark :file-disp-mode)
  (efar-set 1 :panels :left :view :disks :column-number)
  (efar-set '(:long) :panels :left :view :disks :file-disp-mode)
  (efar-set 1 :panels :left :view :search :column-number)
  (efar-set '(:long) :panels :left :view :search :file-disp-mode)
  (efar-set 1 :panels :left :view :dir-diff :column-number)
  (efar-set '(:short) :panels :left :view :dir-diff :file-disp-mode)
  (efar-set 1 :panels :left :view :search-hist :column-number)
  (efar-set '(:short) :panels :left :view :search-hist :file-disp-mode)
  
  (efar-set 1 :panels :right :view :files :column-number)
  (efar-set '(:short :long :detailed :full) :panels :right :view :files :file-disp-mode)
  (efar-set 1 :panels :right :view :dir-hist :column-number)
  (efar-set '(:long) :panels :right :view :dir-hist :file-disp-mode)
  (efar-set 1 :panels :right :view :file-hist :column-number)
  (efar-set '(:long) :panels :right :view :file-hist :file-disp-mode)
  (efar-set 1 :panels :right :view :bookmark :column-number)
  (efar-set '(:long) :panels :right :view :bookmark :file-disp-mode)
  (efar-set 1 :panels :right :view :disks :column-number)
  (efar-set '(:long) :panels :right :view :disks :file-disp-mode)
  (efar-set 1 :panels :right :view :search :column-number)
  (efar-set '(:long) :panels :right :view :search :file-disp-mode)
  (efar-set 1 :panels :right :view :dir-diff :column-number)
  (efar-set '(:short) :panels :right :view :dir-diff :file-disp-mode)
  (efar-set 1 :panels :right :view :search-hist :column-number)
  (efar-set '(:short) :panels :right :view :search-hist :file-disp-mode)
  
  (efar-set nil :last-auto-read-buffer)
  
  (efar-set '() :directory-history)
  (efar-set '() :bookmarks)
  (efar-set '() :file-history)
  
  (efar-set 0 :splitter-shift)
  
  (efar-set 0 :next-hint-number))

(defun efar-get (&rest keys)
  "Get value stored by KEYS."
  (let ((value nil))
    (mapc
     (lambda(key)
       (if value
	   (setf value (gethash key value))
	 (setf value (gethash key efar-state))))
     keys)
    value))

(defun efar-set (value &rest keys)
  "Store VALUE by KEYS."
  (let ((place nil))
    (mapc
     (lambda(key)
       (if place
	   (setf place (puthash key (gethash key place (make-hash-table :test `equal)) place))
	 (setf place (puthash key (gethash key efar-state (make-hash-table :test `equal)) efar-state))))
     
     (cl-subseq keys 0 -1))
    
    (puthash (car (cl-subseq keys -1)) value (or place efar-state))))

;;--------------------------------------------------------------------------------
;; file sort functions
;;--------------------------------------------------------------------------------
(defconst efar-sort-functions '(("Name" . efar-sort-files-by-name)
				("Date" . efar-sort-files-by-modification-date)
				("Extension" . efar-sort-files-by-extension)
				("Size" . efar-sort-files-by-size)
				("Unsorted" . nil)))

(defun efar-get-sort-function (name)
  "Return sort function by NAME."
  (cdr (assoc name efar-sort-functions)))


(defun efar-sort-function-names (side)
  "Return a list of sort function names.
The name of a function which is currently used for the panel SIDE (or current panel) becomes a first entry in the list."
  (let ((current-function-name (efar-get :panels side :sort-function-name)))
    (append (list current-function-name)
	    (cl-remove current-function-name
		       (mapcar
			(lambda(e)
			  (car e))
			efar-sort-functions)
		       :test 'equal))))

(defun efar-sort-files-by-name (a b)
  "Function to sort files A and B by name.
Directories always go before normal files.
Function string< is used for comparing file names.
Case is ignored."
  (cond
   ;; directories go first
   ((and (cadr a) (not (cadr b)))
    t)
   ((and (not (cadr a)) (cadr b))
    nil)
   ;; entries of same type (directory or usual files) sorted in lexicographic order
   (t (string<
       (downcase (car a))
       (downcase (car b))))))

(defun efar-sort-files-by-modification-date (a b)
  "Function to sort files A and B by modification date.
Directories always go before normal files."
  (cond
   ;; directories go first
   ((and (cadr a) (not (cadr b)))
    t)
   ((and (not (cadr a)) (cadr b))
    nil)
   ;; entries of same type (directory or usual files) sorted by comparing modification date
   (t (<
       (time-to-seconds (nth 6 a))
       (time-to-seconds (nth 6 b))))))

(defun efar-sort-files-by-size (a b)
  "Function to sort files A and B by file size.
Directories always go before normal files."
  (cond
   ;; directories go first
   ((and (cadr a) (not (cadr b)))
    t)
   ((and (not (cadr a)) (cadr b))
    nil)
   ;; entries of same type (directory or usual files) sorted by comparing file size
   (t (<
       (nth 8 a)
       (nth 8 b)))))

(defun efar-sort-files-by-extension (a b)
  "Function to sort files A and B by type (extension).
Directories always go before normal files.
Function string< is used for comparing file extensions.
Case is ignored."
  (cond
   ;; directories go first
   ((and (cadr a) (not (cadr b)))
    t)
   ((and (not (cadr a)) (cadr b))
    nil)
   ;; files sorted by extension (if any) in lexicographic order
   (t (string<
       (downcase (or (file-name-extension (car a)) ""))
       (downcase (or (file-name-extension (car b)) ""))))))

(defun efar-do-change-sorting ()
  "Change sorting function and sorting order."
  (interactive)
  (efar-when-can-execute
   (let ((side (efar-get :current-panel)))
     (efar-set (efar-completing-read "Sort files by" (efar-sort-function-names side))
	       :panels side :sort-function-name)
     
     (efar-set (string= (char-to-string 9660) (efar-completing-read "Sort order" (list (char-to-string 9650) (char-to-string 9660) )))
	       :panels side :sort-order)
     (efar-refresh-panel side nil (efar-get-short-file-name (efar-current-file))))))

;;--------------------------------------------------------------------------------
;; file notification functions
;;--------------------------------------------------------------------------------

(defun efar-setup-notifier (dir side)
  "Set up file-notify-watch for the directory DIR and register it for panel SIDE."
  ;; first remove existing file-notify-watch
  (efar-remove-notifier side)
  
  (let* ((other-side-notifier (efar-get :panels (efar-other-side side) :file-notifier))
	 (descriptor
	  ;; if file-notify-watch for given DIR is already registered for other panel and it is valid, use it
	  (if (and
	       (string= (car other-side-notifier) dir)
	       (file-notify-valid-p (cdr other-side-notifier)))
	      (cdr other-side-notifier)
	    ;; otherwise create new one
	    (file-notify-add-watch dir '(change attribute-change) 'efar-notification))))
    
    (efar-set (cons dir descriptor) :panels side :file-notifier)))


(defun efar-remove-notifier (side &optional dont-check-other)
  "Remove file-notify-watch registered for panel SIDE.
If same watch is registered for other panel, then don't remove the watch, but just unregister it for panel SIDE, unless DONT-CHECK-OTHER is t"
  (let ((descriptor (cdr (efar-get :panels side :file-notifier)))
	(other-descriptor (cdr (efar-get :panels (efar-other-side side) :file-notifier))))
    (when (or dont-check-other (not (equal descriptor other-descriptor)))
      (file-notify-rm-watch descriptor))
    (efar-set nil :panels side :file-notifier)))

(defun efar-notification (event)
  "Callback function triggered when a file EVENT occurs.
It stores notification in the queue and runs timer for 1 second.
Notifications in the queue will be processed only if there are no new notifications within 1 second."
  (let ((descriptor (car event))
	(event-type (nth 1 event)))
    
    ;; for any event except 'stopped
    (unless (equal event-type 'stopped)
      ;; if eFAR buffer exists
      (when (get-buffer efar-buffer-name)
	
	;; if there is yet no notifications in the queue for given descriptor
	;; add descriptor to the queue
	(let ((pending-notifications (efar-get :pending-notifications)))
	  (unless (member descriptor pending-notifications)
	    (push descriptor pending-notifications)
	    (efar-set pending-notifications :pending-notifications)))
	
	;; if there is a running timer, cancel it
	(let ((timer (efar-get :notification-timer)))
	  (when timer (cancel-timer timer))
	  ;; create new timer
	  (efar-set (run-at-time "1 sec" nil
				 (lambda()
				   (efar-process-pending-notifications)))
		    :notification-timer))))))

(defun efar-process-pending-notifications ()
  "Process all pending file notifications."
  ;; while there are notifications in a queue
  (while
      ;; pop next notification
      (let* ((pending-notifications (efar-get :pending-notifications))
	     (descriptor (prog1
			     (pop pending-notifications)
			   (efar-set pending-notifications :pending-notifications))))
	(when descriptor
	  ;; if event comes from the watcher registered for left panel directory, refersh left panel
	  (when (equal descriptor (cdr (efar-get :panels :left :file-notifier)))
	    (efar-refresh-panel :left))
	  ;; if event comes from the watcher registered for right panel directory, refersh right panel
	  (when (equal descriptor (cdr (efar-get :panels :right :file-notifier)))
	    (efar-refresh-panel :right))))))

;;--------------------------------------------------------------------------------
;; save/resore state functions
;;--------------------------------------------------------------------------------

(defun efar-remove-file-state ()
  "Remove eFar state file.  Could be helpful in case of errors during startup."
  (interactive)
  (delete-file efar-state-file-name))

(defun efar-save-state ()
  "Save eFar state to the state file.  Data from this file is used during startup to restore last state."
  (efar-do-abort)
  (with-temp-file efar-state-file-name
    (let ((copy (copy-hash-table efar-state)))
      
      ;; clear up data not relevant for saving
      (puthash :file-notifier nil (gethash :left (gethash :panels copy)))
      (puthash :file-notifier nil (gethash :right (gethash :panels copy)))
      (puthash :notification-timer nil copy)
      (puthash :pending-notifications () copy)
      (puthash :files () (gethash :left (gethash :panels copy)))
      (puthash :files () (gethash :right (gethash :panels copy)))
      (puthash :selected () (gethash :left (gethash :panels copy)))
      (puthash :selected () (gethash :right (gethash :panels copy)))
      
      (puthash :last-auto-read-buffer nil copy)
      
      ;; add eFar version tag
      (puthash :version efar-version copy)
      
      (print copy (current-buffer)))))

(defun efar-read-state ()
  "Read eFar state from the file."
  (setf efar-state
	(efar-check-state-file-version
	 (with-temp-buffer
	   (insert-file-contents efar-state-file-name)
	   (cl-assert (bobp))
	   (read (current-buffer))))))

(defun efar-check-state-file-version (state)
  "Check version of STATE file and upgrade it if necessary."
  (let ((state-version (or (gethash :version state) 0.0)))
    (cond
     ;; if current eFar version matches version stored in state file
     ;; then we have nothing to do - we use loaded state
     ((equal efar-version state-version)
      (message "eFar state loaded from file %s" efar-state-file-name)
      state)
     
     ;; else if curent version of eFar is lower then version stored in state file
     ;; we have to skip loading state
     ((< efar-version state-version)
      (message "Version of state file is greater then eFar version. State file loading skipped...")
      nil)
     
     ;; else if current eFar version is greater then version stored in state file
     ;; we do "upgrade" of state file
     (t
      (copy-file efar-state-file-name (concat efar-state-file-name "_" (int-to-string state-version)) 1)
      (efar-upgrade-state-file state state-version)))))

(defun efar-upgrade-state-file (state from-version)
  "Upgrade state file.
Do necessary changes in STATE in order to switch
from version FROM-VERSION to actual version."
  (let ((copy (copy-hash-table state)))
    (setq efar-state copy)
    (condition-case err
	(progn
	  ;; 0.9 -> 1.0
	  (when (< from-version 1.0)
	    ;; transform :directory-history to keep date
	    (let ((dir-history (mapcar (lambda(e) (cons (car e) (list (cons :side (cdr e)) (cons :time nil))))
				       (gethash :directory-history efar-state))))
	      (puthash :directory-history dir-history efar-state))
	    
	    ;; add file-history
	    (puthash :file-history '() efar-state)
	    (efar-set 1 :panels :left :view :file-hist :column-number)
	    (efar-set '(:long) :panels :left :view :file-hist :file-disp-mode)
	    (efar-set 1 :panels :right :view :file-hist :column-number)
	    (efar-set '(:long) :panels :right :view :file-hist :file-disp-mode)
	    (message "eFar state file upgraded to version 1.0"))
	  
	  ;; 1.12 -> 1.13
	  (when (< from-version 1.13)
	    (efar-set '(:short :long :detailed :full) :panels :right :view :files :file-disp-mode)
	    (efar-set '(:short :long :detailed :full) :panels :left :view :files :file-disp-mode)
	    (message "eFar state file upgraded to version 1.13"))
	  
	  ;; 1.17 -> 1.18
	  (when (< from-version 1.18)
	    (efar-set '() :panels :left :selected)
	    (efar-set '() :panels :left :selected)
	    (message "eFar state file upgraded to version 1.17"))
	  
	  ;; 1.20 -> 1.21
	  (when (< from-version 1.21)
	    (efar-set 1 :panels :left :view :dir-diff :column-number)
	    (efar-set '(:short) :panels :left :view :dir-diff :file-disp-mode)
	    (efar-set 1 :panels :right :view :dir-diff :column-number)
	    (efar-set '(:short) :panels :right :view :dir-diff :file-disp-mode)
	    (message "eFar state file upgraded to version 1.21"))

	  ;; 1.23 -> 1.24
	  (when (< from-version 1.24)
	    (efar-set 1 :panels :left :view :search-hist :column-number)
	    (efar-set '(:short) :panels :left :view :search-hist :file-disp-mode)
	    (efar-set 1 :panels :right :view :search-hist :column-number)
	    (efar-set '(:short) :panels :right :view :search-hist :file-disp-mode)
	    (message "eFar state file upgraded to version 1.24"))
	  ;; 1.25 -> 1.26
	  (when (< from-version 1.26)
	    (let ((b (get-buffer-create "Efar 1.26")))
	      (with-current-buffer b
		(insert (propertize
			 "Starting from version 1.26 default eFar key bindings changed according to the Emacs Key Binding Conventions.\nCheck actual key bindings by <C-e ?>.\nSee also Readme at https://github.com/suntsov/efar"
			 'face '(:foreground "red"))))
	      (switch-to-buffer-other-window b))))
      
      (error
       (message "Error occured during upgrading state file: %s. State file skipped." (error-message-string err))
       (setf efar-state nil)))
    
    efar-state))

;;------------------------------------------------------------------
;; efar file operations
;;------------------------------------------------------------------
(defun efar-do-make-dir ()
  "Create new directory."
  (interactive)
  (efar-when-can-execute
   (efar-with-notification-disabled
    (let ((new-dir-name (read-string "Input name for new directory: "))
	  (side (efar-get :current-panel)))
      
      ;; try to create a directory
      (efar-retry-when-error
       (make-directory new-dir-name nil))
      
      ;; refresh panel and move selection
      (efar-refresh-panel side nil new-dir-name)
      
      ;; if other panel displays same directory as current one, refresh it as well
      (when (string= (efar-get :panels side :dir) (efar-get :panels (efar-other-side) :dir))
	(efar-refresh-panel (efar-other-side)))))))

(defun efar-do-copy ()
  "Copy files."
  (interactive)
  (efar-when-can-execute
   (efar-copy-or-move-files :copy)))

(defun efar-do-rename ()
  "Rename/move files."
  (interactive)
  (efar-when-can-execute
   (efar-copy-or-move-files :move)))

(defun efar-copy-or-move-files (operation &optional dest)
  "Copy or move selected files depending on OPERATION.
When DEST is given then use this path as destination path.
Otherwise ask user where to copy/move files to."
  (unwind-protect
      (progn
	(let ((use-dialog-box nil))
	  (efar-with-notification-disabled
	   (let* ((side (efar-get :current-panel))
		  (todir  (let ((todir (efar-get :panels (efar-other-side) :dir)))
			    (if (file-exists-p todir)
				todir
			      (efar-get :panels side :dir))))
		  (files (efar-selected-files side nil)))
	     
	     (when files
	       
	       (let ((destination (or dest
				      (read-file-name (if (equal operation :copy)
							  "Copy selected file(s) to "
							"Move selected file(s) to ")
						      (file-name-as-directory todir)
						      nil
						      nil
						      ;;when only one file is selected we add file name to proposed path
						      (when (equal (length files) 1) (efar-get-short-file-name (car files)))))))
		 
		 (efar-set-status (if (equal operation :copy)
				      "Copying files..."
				    "Moving files..."))
		 
		 (efar-copy-or-move-files-int (pcase operation
						(:copy :copy)
						(:move :move)
						(:rename :move))
					      files destination)))
	     
	     (efar-refresh-panel :left)
	     (efar-refresh-panel :right))))
	
	(efar-set-status "Ready"))))

(defun efar-copy-or-move-files-int (operation files todir &optional fromdir overwrite?)
  "Copy or move (depending on OPERATION) FILES into TODIR.
When FROMDIR is not defined then `default-directory' is used.
OVERWRITE? is a boolean indicating that existing files have to be overwritten.
Existing files can be skipped or overwritten depending on user's choice.
User also can select an option to overwrite all remaining files to not be asked multiple times."
  (cl-labels ;; make local recursive function (needed to share variable overwrite? in recursion)
      ((do-operation (operation files todir fromdir)
		     ;; if FROMDIR is not set, we use default-directory as source directory
		     (let ((default-directory (if fromdir fromdir default-directory)))
		       
		       (mapc ;; for each file in FILES
			(lambda (f)
			  ;; skip files "." and ".."
			  (unless (or (string= (car f) ".") (string= (car f) ".."))
			    ;; get new file name in destination folder
			    (let ((newfile
				   (if (file-directory-p todir)
				       (expand-file-name (efar-get-short-file-name f) todir)
				     todir)))
			      (cond
			       ;; if file is a real file and doesn't exist in destination folder
			       ((and (not (equal (cadr f) t)) (not (file-exists-p newfile)))
				;; we just copy it using elisp function
				(if (equal operation :copy)
				      (efar-retry-when-error (copy-file (car f) newfile))
				  (efar-retry-when-error (rename-file (car f) newfile nil))))
			       			       
			       ;; if file is a directory and doesn't exist in destination folder
			       ((and (equal (cadr f) t) (not (file-exists-p newfile)))
				;; we just copy directory using elisp function
				(if (equal operation :copy)
				    (efar-retry-when-error (copy-directory (car f) newfile nil nil nil))
				  (efar-retry-when-error (rename-file (car f) newfile))))
			       
			       ;; if file is a real file and does exist in destination folder
			       ((and (not (equal (cadr f) t)) (file-exists-p newfile))
				(progn
				  ;; we ask user what to do (overwrite, not overwrite, overwrite all remaining)
				  ;; if user was already asked before and the answer was "All", we don't ask again
				  (setf overwrite? (cond
						    ((or (null overwrite?) (string= overwrite? "No") (string= overwrite? "Yes"))
						     (efar-completing-read (concat "File " newfile " already exists. Overwrite? ") (list "Yes" "No" "All")))
						    (t overwrite?)))
				  ;; we copy file (overwrite) using elisp function if user approved it
				  (unless (string= overwrite? "No")
				    (if (equal operation :copy)
					(efar-retry-when-error (copy-file (car f) newfile t nil nil nil))
				      (efar-retry-when-error (rename-file (car f) newfile t))))))
			       
			       ;; if file is a directory and does exist in destination folder
			       ((and (equal (cadr f) t) (file-exists-p newfile))
				;; we call local function recursively
				(do-operation operation (directory-files-and-attributes (car f) nil nil t 'string) newfile (expand-file-name (efar-get-short-file-name f) default-directory) )
				(when (equal operation :move)
				  (delete-directory (car f))))))))
			
			files))))
    ;; call local function first time
    (do-operation operation files todir fromdir)) )

(defun efar-completing-read (prompt &optional options)
  "Read a string in the minibuffer, with completion.
PROMPT is a string to prompt with.
OPTIONS is a collection with possible answers."
  (let* ((completion-ignore-case t)
	 (options (or options '("Yes" "No")))
	 (prompt (format "%s (%s)"
			 prompt
			 (mapconcat #'identity options " | "))))
    (completing-read prompt options nil t nil nil (car options))))

(defun efar-do-delete ()
  "Delete files."
  (interactive)
  (efar-when-can-execute
   (let ((mode (efar-get :panels (efar-get :current-panel) :mode)))
     (pcase mode
       (:files (efar-delete-selected))
       (:bookmark (efar-delete-bookmark))))))

(defun efar-delete-selected ()
  "Delete selected file(s)."
  (unwind-protect
      (efar-with-notification-disabled
       (let* ((side (efar-get :current-panel))
	      (selected-files (efar-selected-files side nil)))
	 ;; ask user for confirmation
	 (when (and selected-files (string= "Yes" (efar-completing-read "Delete selected files?")))
	   ;; do the deletion of selected files
	   (efar-set-status "Deleting files...")
	   (mapc(lambda (f)
		  (if (equal (cadr f) t)
		      (efar-retry-when-error (delete-directory (car f) t))
		    (efar-retry-when-error (delete-file (car f)))))
		selected-files)
	   
	   (efar-refresh-panel side)
	   
	   (when (string= (efar-get :panels side :dir) (efar-get :panels (efar-other-side) :dir))
	     (efar-refresh-panel (efar-other-side)))))))
  
  (efar-set-status "Ready"))

(defun efar-do-set-file-modes ()
  "Change file permissions."
  (interactive)
  (efar-when-can-execute
   (unwind-protect
       (efar-with-notification-disabled
	(let* ((side (efar-get :current-panel))
	       (selected-files (efar-selected-files side nil)))
	  (when selected-files
	    (let ((modes (read-file-modes)))
	      (efar-set-status "Setting mode for selected files...")
	      (mapc (lambda (f)
		      (efar-retry-when-error (set-file-modes (car f) modes)))
		    selected-files))
	    
	    (efar-refresh-panel side nil nil)
	    
	    (when (string= (efar-get :panels side :dir) (efar-get :panels (efar-other-side) :dir))
	      (efar-refresh-panel (efar-other-side)))))))
   
   (efar-set-status "Ready")))

;;------------------------------------------------------------------
;; efar displaying status
;;------------------------------------------------------------------

(defun efar-reset-status ()
  "Reset eFar status to default one."
  (when (efar-get :reset-status?)
    (efar-set-status "Ready")))

(defun efar-set-status (&optional status seconds reset? notify-with-color?)
  "Set eFar status to STATUS.
When STATUS is nil use default 'Ready' status.
When SECONDS is defined then status is displayed given time.
When RESET? is t then status will be automatically changed to default
on any next cursor movement.
When NOTIFY-WITH-COLOR? is t then blink red."
  (with-current-buffer efar-buffer-name
    
    (when reset?
      (efar-set t :reset-status?))
    
    (let ((prev-status (efar-get :status))
	  (status (or status "Ready")))
      
      (efar-set status :status)

      (let ((status-string (if notify-with-color?
			       (propertize status 'face '(:background "red"))
			     status)))
	(setq mode-line-format (list " " mode-line-modes status-string)))

      (when notify-with-color?
	(run-at-time 0.6 nil
		     #'(lambda()
			(setq mode-line-format (list " " mode-line-modes (efar-get :status)))
			(force-mode-line-update))))

      (force-mode-line-update)
      
      (when seconds
	(run-at-time seconds nil
		     `(lambda()
			(efar-set-status ',prev-status)))))))

(defun efar-do-show-help ()
  "Display a buffer with all eFar keybindings description.."
  (interactive)
  (efar-when-can-execute
   (let ((buffer (get-buffer-create "*Efar key bindings*")))
     (with-current-buffer buffer
       (read-only-mode -1)
       (erase-buffer)

       (insert (propertize "How to customize eFar key bindings?\n\n" 'face 'bold))
       (insert (format "Suppose you want to replace default binding %s by %s for command %s.\n"
		       (propertize "<up>" 'face 'bold)
		       (propertize "C-p" 'face 'bold)
		       (propertize "efar-do-move-down" 'face 'bold)))
       (insert "Then add following code to your init file:\n\n")
       
       (insert (propertize "(eval-after-load 'efar\n  '(progn\n    (define-key efar-mode-map (kbd \"<up>\") nil)\n    (define-key efar-mode-map (kbd \"C-p\") 'efar-do-move-up)))\n\n" 'face 'italic))
       (insert "If you like to just add an additional binding and keep default one then the first 'define-key' is not needed.\n\n\n")
       (insert "Bellow is a list of currently configured bindings:\n\n")
       
       (cl-loop for func in (let ((funcs '()))
			      (cl--map-keymap-recursively (lambda (e d) (when (and e d (symbolp d)) (cl-pushnew  d funcs))) efar-mode-map)
			      funcs) do
			      (let* ((keys (where-is-internal func efar-mode-map))
				     (keys (mapconcat #'key-description keys ", ")))
				(insert (format "%s\t\t%s\nM-x %s\n\n"
						(propertize keys 'face '(:foreground "dark blue") )
						(documentation func)
						(propertize (symbol-name func) 'face '(:underline t))))))
       
       (align-regexp (point-min) (point-max) "\\(\\s-*\\)\t" nil 2)
       (goto-char 0)
       (read-only-mode 1)
       (setq-local mode-line-format nil)
       (local-set-key (kbd "q") 'delete-frame))
     
     (display-buffer buffer))))

(defun efar-process-mouse-event (event)
  "Process mouse event EVENT."
  (select-window (get-buffer-window efar-buffer-name))
  
  (let ((click-type (car event)))
    
    (cond
     ;; BUTTON DOWN
     ((or (equal "down-mouse-1" (symbol-name click-type))
	  (equal "C-down-mouse-1" (symbol-name click-type))
	  (equal "S-down-mouse-1" (symbol-name click-type)))
      (efar-process-mouse-down event))
     
     ;; MOUSE DRAG HAPPENED
     ((or (equal "drag-mouse-1" (symbol-name click-type))
	  (equal "C-drag-mouse-1" (symbol-name click-type)))
      (efar-process-mouse-drag event))
     
     ;; MOUSE WHEEL SCROLLED
     ((string-match-p "wheel-" (symbol-name click-type))
      (efar-process-mouse-wheel event))
     
     ;; BUTTON CLICKED
     ((or (equal "mouse-1" (symbol-name click-type))
	  (equal "double-mouse-1" (symbol-name click-type))
	  (equal "C-mouse-1" (symbol-name click-type))
	  (equal "S-mouse-1" (symbol-name click-type)))
      (efar-process-mouse-click event))))
  
  ;; finally redraw if necessary
  (efar-write-enable (efar-redraw)))

(defun efar-process-mouse-down (event)
  "Do actions when mouse button is pressed.
The point where mouse click occurred determined out of EVENT parameters."
  (let* ((pos (nth 1 (nth 1 event)))
	 (props (plist-get (text-properties-at pos) :control))
	 (side (cdr (assoc :side props)))
	 (control (cdr (assoc :control props))))
    
    (setf efar-mouse-down-p t)
    
    ;; when clicked on file entry select it
    (when (equal control :file-pos)
      (let ((position (cdr (assoc :file-number props))))
	(efar-set position :panels side :current-pos)
	;; in dir-compare mode select corresponding file in other panel as well
	(when (equal :dir-diff (efar-get :panels :left :mode))
	  (efar-set position :panels (efar-other-side side) :current-pos))))
    ;; switch to panel if necessarry
    (when (and side
	       (cdr (assoc :switch-to-panel props))
	       (not (equal (efar-get :current-panel) side)))
      (efar-do-switch-to-other-panel))))

(defun efar-process-mouse-drag (event)
  "Do actions when drag&drop action occurrs.
The start and end points of drag&drop action determined out of EVENT parameters."
  (let* ((click-type (car event))
	 (source (nth 1 (nth 1 event)))
	 (source-props (plist-get (text-properties-at source) :control))
	 (source-side (cdr (assoc :side source-props)))
	 (source-control (cdr (assoc :control source-props)))
	 (operation (if (equal "C-drag-mouse-1" (symbol-name click-type))
			:copy :move)))
    
    (setf efar-mouse-down-p nil)
    
    (let ((destination (nth 0 (nth 2 event))))
      
      (pcase (type-of destination)
	
	;; DRAG&DROP WITHIN EMACS frame
	('window
	 (let ((dest-props (plist-get (text-properties-at (nth 1 (nth 2 event))
							  (window-buffer destination)) :control)))
	   ;; if dragged to eFar
	   (if (equal destination (get-buffer-window efar-buffer-name))
	       
	       (cond
		;; when panel splitter is dragged
		((equal source-control :splitter)
		 ;; calulate the distance and move the splitter
		 (let* ((shift (- (car (nth 6 (nth 1 event)))
				  (car (nth 6 (nth 2 event)))))
			(percentage (/ (* (abs shift) 100) (floor (efar-get :window-width) 2))))
		   (efar-move-splitter (if (< shift 0) (* percentage -1) percentage))))
		
		;; else we process dragging in :files mode only
		(t (when (equal (efar-get :panels source-side :mode) :files)
		     (let* ((dest-side (cdr (assoc :side dest-props)))
			    (dest-control (cdr (assoc :control dest-props)))
			    (dest-file (cdr (assoc :file-name dest-props))))
		       
		       (when (equal (efar-get :panels dest-side :mode) :files)
			 (cond
			  ;; dragged to the same panel
			  ((equal source-side dest-side)
			   
			   (cond
			    ;; if button released over file entry
			    ((equal dest-control :file-pos)
			     (when (file-directory-p dest-file)
			       (efar-copy-or-move-files operation dest-file)))
			    
			    ;; else if button released over any other panel area
			    (t
			     (let ((files (efar-selected-files source-side nil nil t)))
			       (when (equal source-control :file-pos)
				 ;; we make a copy of selected files by new names
				 (cl-loop for file in files do
					  (efar-copy-or-move-files-int :copy (list file) (expand-file-name (concat "copy_" (efar-get-short-file-name file)) (efar-get :panels dest-side :dir))))
				 (efar-get-file-list dest-side))))))
			  
			  ;; dragged to the other panel
			  (t
			   (efar-copy-or-move-files operation
						    ;; when dropped on empty area or on a file
						    (if (or (string-empty-p dest-file)
							    (not (file-directory-p dest-file)))
							;; then copy/move files to the directory of other panel
							(efar-get :panels dest-side :dir)
						      ;; else if dropped on an directory item then copy/move to that directory
						      dest-file)))))))))
	     
	     ;; else if dragged to another buffer
	     ;; then we just open file in another buffer
	     (let ((file (caar (efar-selected-files source-side t nil t))))
	       (when (and (equal source-control :file-pos)
			  file)
		 (set-window-buffer destination (find-file-noselect file)))))))
	
	
	;; DRAG&DROP OUTSIDE EMACS (not suported)
	('frame (message-box "Drag&drop to outside world is not supported."))))))


(defun efar-process-mouse-click (event)
  "Do actions when mouse button released.
The point where mouse click occurred determined out of EVENT parameters."
  
  (setf efar-mouse-down-p nil)
  
  (let* ((click-type (car event))
	 (pos (nth 1 (nth 1 event)))
	 (props (plist-get (text-properties-at pos) :control))
	 (side (cdr (assoc :side props)))
	 (files (efar-get :panels side :files))
	 (control (cdr (assoc :control props))))
    
    ;; when single click on a file entry - auto read file
    (when (and (equal control :file-pos)
	       (equal click-type 'mouse-1))
      (efar-auto-read-file))
    
    ;; when clicked with ctrl we mark single item
    (when (equal click-type 'C-mouse-1)
      (efar-mark-file t))
    
    ;; when clicked with shift we mark all items between clicked item and item marked last time
    (when (and (equal click-type 'S-mouse-1)
	       (equal control :file-pos))
      (let ((last-marked (cl-position-if
			  (lambda(e) (equal (car e) (caar (efar-get :panels side :selected))))
			  files))
	    (selected-file-number (+ (cdr (assoc :file-number props)) (efar-get :panels side :start-file-number)))
	    (selected '()))
	(if (not last-marked)
	    (efar-mark-file t)
	  
	  (cl-loop for n in (number-sequence last-marked
					     selected-file-number
					     (if (< last-marked selected-file-number) 1 -1))
		   do (push (nth n files) selected))
	  (efar-set selected :panels side :selected))))
    
    ;;when double clicked
    (when (equal click-type 'double-mouse-1)
      (if (equal control :splitter)
	  (efar-move-splitter :center))
      (when (and (equal side (efar-get :current-panel))
		 (equal control :file-pos))
	(efar-do-enter-directory)))

    ;; when clicked on :dir-diff-display-changed-only control
    (when (equal control :dir-diff-display-changed-only)
      (efar-show-dir-diff-toggle-changed-only))

    ;; when clicked on directory comparison option controls
    (when (equal control :dir-diff-comp-param-switcher)
      (let ((par (cdr (assoc :param props))))
	(efar-dir-diff-toggle-comparison-display-options par)))
    
    ;; when clicked on sorting controls
    (when (or (equal control :sort-func)
	      (equal control :sort-order))
      ;; if clicked on sort func control then change sort function to the next one
      (and (equal control :sort-func)
	   (efar-set (let ((p (cl-position (efar-get :panels side :sort-function-name) efar-sort-functions :test (lambda(a b) (equal (car b) a)))))
		       (cond ((equal p (- (length efar-sort-functions) 1))
			      (caar efar-sort-functions))
			     (t (car (nth (+ p 1) efar-sort-functions)))))
		     :panels side :sort-function-name))
      ;; if clicked on sort order control then switch sort order
      (and (equal control :sort-order)
	   (efar-set (not (efar-get :panels side :sort-order)) :panels side :sort-order))
      (efar-get-file-list side))
    
    ;; when clicked on col number control
    (when (equal control :col-number)
      (pcase (char-to-string (char-after pos))
	("+" (efar-change-column-number t side))
	("-" (efar-change-column-number nil side))))
    
    ;;when clicked maximize
    (when (equal control :maximize)
      (efar-change-mode side))
    
    ;; when clicked on file display mode switcher
    (when (equal control :file-disp-mode)
      (efar-change-file-disp-mode side))
    
    ;; when clicked on a directory name header
    ;; we show disks/mount points selector
    (when (equal control :directory-name)
      (efar-change-panel-mode :disks side))))

(defun efar-process-mouse-wheel (event)
  "Do actions when mouse wheel is scrolled.
The point where mouse scroll occurred determined out of EVENT parameters."
  (efar-move-cursor (if (string-match-p "down$" (symbol-name (car event)))
			:right
		      :left)
		    'no-auto-read))

(defun efar-do-change-directory ()
  "Go to specific directory."
  (interactive)
  (efar-when-can-execute
   (efar-go-to-dir (read-directory-name "Go to directory: " default-directory))
   (efar-write-enable (efar-redraw))))

(defun efar-do-increase-column-number ()
  "Increase number of columns in current panel."
  (interactive)
  (efar-when-can-execute
   (efar-change-column-number t)))

(defun efar-do-decrease-column-number ()
  "Decrease number of columns in current panel."
  (interactive)
  (efar-when-can-execute
   (efar-change-column-number nil)))

(defun efar-change-column-number (&optional increase side)
  "Change the number of columns in panel SIDE if given or in current panel.
Increase by 1 when INCREASE is t, decrease by 1 otherwise."
  (let* ((side (or side (efar-get :current-panel)))
	 (panel-mode (efar-get :panels side :mode))
	 (increase (or increase nil)))
    
    (if increase
	(when (< (efar-get :panels side :view panel-mode :column-number) 5)
	  (efar-set (+ (efar-get :panels side :view panel-mode :column-number) 1) :panels side :view panel-mode :column-number))
      (when (> (efar-get :panels side :view panel-mode :column-number) 1)
	(efar-set (- (efar-get :panels side :view panel-mode :column-number) 1) :panels side :view panel-mode :column-number)
	(let ((file (car (efar-current-file side))))
	  (unless (string= file "..") (efar-go-to-file file side))))))
  
  (efar-calculate-widths)
  (efar-write-enable (efar-redraw)))

(defun efar-do-change-mode ()
  "Change mode: single panel<->double panel."
  (interactive)
  (efar-when-can-execute
   (efar-change-mode)))

(defun efar-change-mode (&optional side)
  "Switch mode from double to single-panel or vice versa.
If a double mode is active then panel SIDE (or active one if not given)
becomes fullscreen."
  (let ((current-mode (efar-get :mode))
	(side (or side (efar-get :current-panel))))
    (efar-set (cond
	       ((equal current-mode :both) side)
	       (t :both))
	      :mode)
    (when (equal current-mode :both)
      (efar-set side :current-panel))
    
    (efar-calculate-widths)
    (efar-write-enable (efar-redraw))))

(defun efar-do-open-dir-other-panel ()
  "Open current directory in other panel."
  (interactive)
  (efar-when-can-execute
   (efar-go-to-dir default-directory (efar-other-side))
   (efar-write-enable (efar-redraw))))

(defun efar-do-copy-file-path ()
  "Copies to the clipboard the full path to the current file or directory."
  (interactive)
  (efar-when-can-execute
   (kill-new
    (caar
     (efar-selected-files (efar-get :current-panel) t t)))))

(defun efar-do-open-file-in-external-app ()
  "Open file under cursor in the external application."
  (interactive)
  (efar-when-can-execute
   (let* ((side (efar-get :current-panel))
	  (fnum (+ (efar-get :panels side :start-file-number) (efar-get :panels side :current-pos) ))
	  (file (nth fnum (efar-get :panels side :files)))
	  (@fname (expand-file-name (car file) (efar-get :panels side :dir))))
     
     (let* (
	    ($file-list
	     (if @fname
		 (progn (list @fname))
	       (if (eq major-mode 'dired-mode)
		   (dired-get-marked-files)
		 (list (buffer-file-name)))))
	    ($do-it-p (if (<= (length $file-list) 5)
			  t
			(y-or-n-p "Open more than 5 files? "))))
       (when $do-it-p
	 (cond
	  ((string-equal system-type "windows-nt")
	   (mapc
	    (lambda ($fpath)
	      (let ((f 'w32-shell-execute))
		(funcall f nil $fpath))) $file-list))
	  ((string-equal system-type "darwin")
	   (mapc
	    (lambda ($fpath)
	      (shell-command
	       (concat "open " (shell-quote-argument $fpath))))  $file-list))
	  ((string-equal system-type "gnu/linux")
	   (mapc
	    (lambda ($fpath) (let ((process-connection-type nil))
			       (start-process "" nil "xdg-open" $fpath))) $file-list))))))))

(defun efar-do-filter-files ()
  "Set file filtering in current panel."
  (interactive)
  (efar-when-can-execute
   (let ((side (efar-get :current-panel)))
     
     (efar-set (read-string "String to filter file names: " (efar-get :panels side :file-filter))
	       :panels side :file-filter)
     
     (efar-get-file-list side)
     (efar-set 0 :panels side :start-file-number)
     (efar-set 0 :panels side :current-pos)
     (efar-write-enable (efar-redraw)))))

(defun efar-fast-search (k)
  "Activate and/or perform incremental search.
K is a character typed by the user."
  (let ((str (efar-get :fast-search-string)))
    
    ;; if a printable character was pressed
    ;; add it to the end of search string
    (unless (member k '(:next :prev :back :clear))
      (setf str (format "%s%c" (or str "") k)))
    
    ;; if user entered at least one character
    ;; we can navigate to file(s) with matching name
    (when (and str
	       (not (string-empty-p  str)))
      
      ;; if user pressed DEL
      ;; then remove last character of the search string
      (when (equal k :back)
	(setf str (substring str 0 (- (length str) 1))))
      
      ;; get the list of files in current directory with names matching the search string
      (let* ((side (efar-get :current-panel))
	     (filtered-list (mapcan (lambda (e)
				      (when (string-match str (if (equal (efar-get :panels side :mode) :files)
								  (efar-get-short-file-name e)
								(car e)))
					(list (car e))))
				    (efar-get :panels side :files))))
	
	;; if user pressed key binding to go to next or previous occurence
	;; shift selector accordingly
	(cond ((equal k :next)
	       (if (= (+ (efar-get :fast-search-occur) 1) (length filtered-list))
		   (efar-set 0 :fast-search-occur)
		 (efar-set (+ 1 (efar-get :fast-search-occur)) :fast-search-occur)))
	      
	      ((equal k :prev)
	       (if (= (efar-get :fast-search-occur) 0)
		   (efar-set (- (length filtered-list) 1) :fast-search-occur)
		 (efar-set (- (efar-get :fast-search-occur) 1) :fast-search-occur))))
	
	;; store search string
	(efar-set str :fast-search-string)
	(efar-get-file-list side)
	
	;; navigate to matched file
	(let ((file-name (or (nth (efar-get :fast-search-occur) filtered-list) "")))
	  (efar-go-to-file file-name nil 0))
	
	(efar-write-enable (efar-redraw))))))

(defun efar-quit-fast-search (&optional no-refresh?)
  "Quite fast search mode.
When NO-REFRESH? is t the no eFar redraw occurs."
  (when efar-state
    (efar-set nil :fast-search-string)
    (efar-set 0 :fast-search-occur)
    (unless no-refresh?
      (let ((file (caar (efar-selected-files (efar-get :current-panel) t t))))
	(efar-get-file-list (efar-get :current-panel))
	(efar-go-to-file (or file "") nil 0)
	(efar-write-enable (efar-redraw))))))

(defun efar-get-accessible-directory-in-path (path)
  "Return first accessible directory in the PATH going from bottom to up.
If there are no accessible directories, return `user-emacs-directory'."
  
  ;; if directory PATH exists or is accessible
  (if (and (file-exists-p path)
	   (file-accessible-directory-p path))
      ;; return this directory
      (if (equal path "/")
	  path
	(string-trim-right path "[/]"))
    ;; else get parent directory
    (let ((parent-dir
	   (file-name-directory
	    (directory-file-name path))))
      ;; if we are in root directory already
      (if (string= parent-dir path)
	  ;; that means there are no accessible directories in the path and we return user-emacs-directory
	  user-emacs-directory
	;; otherwise check parent directory
	(efar-get-accessible-directory-in-path parent-dir )))))

(defun efar-refresh-panel (&optional side move-to-first? move-to-file-name)
  "Refresh given panel (or a current one when SIDE is not given).
When MOVE-TO-FIRST? is t move cursot to the first file.
When MOVE-TO-FILE-NAME is given then move cursor to the file with that name.
When DONT-UNMARK is t then marked items remains marked."
  (let* ((side (or side (efar-get :current-panel)))
	 (mode (efar-get :panels side :mode)))
    
    (when (equal mode :files)
      (efar-set (efar-get-accessible-directory-in-path (efar-get :panels side :dir))
		:panels side :dir))
    
    (efar-set nil :panels side :fast-search-string)
    
    (let ((current-file-name (cond
			      (move-to-first? "")
			      (move-to-file-name move-to-file-name)
			      (t (efar-current-file-name side))))
	  (current-file-number (if move-to-first? 0 (efar-current-file-number side))))
      
      (efar-get-file-list side)
      
      ;; keep selection of still existing files
      (let ((selected (efar-get :panels side :selected))
	    (files (efar-get :panels side :files)))
	(efar-set (cl-remove-if (lambda(e1)
				  (not (cl-member-if (lambda(e2)
						       (equal (car e1) (car e2)))
						     files)))
				selected)
		  :panels side :selected))
      
      (when (> (length (efar-get :panels side :files)) 0)
	(efar-go-to-file current-file-name side current-file-number)))
    
    (efar-write-enable (efar-redraw))))

(defun efar-go-to-dir (dir &optional side no-hist?)
  "Go to given DIR.
When SIDE is given show directory in this panel, otherwise in current one.
When NO-HIST? is t then DIR is not saved in the history list."
  (let* ((dir (when dir (efar-get-accessible-directory-in-path (expand-file-name dir))))
	 (side (or side (efar-get :current-panel)))
	 (current-dir (efar-get :panels side :dir))
	 (parent-dir (when (equal (efar-get :panels side :mode) :files) (efar-get-parent-dir current-dir)))
	 (go-to-parent? (string= dir parent-dir)))
    
    (when (eq side (efar-get :current-panel))
      (setf default-directory dir))
    
    (efar-set () :panels side :selected)
    (efar-set dir :panels side :dir)
    
    (efar-set nil :fast-search-string)
    
    (efar-set :files :panels side :mode)
    
    (efar-get-file-list side)
    
    ;; if we go to the directory which is a parent of current one
    ;; then we move cursor to the current directory in the list
    (if go-to-parent?
	(progn
	  (efar-go-to-file current-dir side 0))
      ;; otherwise go to the first item
      (progn
	(efar-set 0 :panels side :start-file-number)
	(efar-set 0 :panels side :current-pos)))
    
    ;; add directory in the list of last visited directories
    (unless no-hist?
      (let* ((current-hist (efar-get :directory-history))
	     (new-hist (cl-subseq (cl-remove-if (lambda(e) (equal dir (car e))) current-hist)
				  0 (when (> (length current-hist) efar-max-items-in-directory-history)
				      (- efar-max-items-in-directory-history 1)))))
	(push (cons (if (equal dir "/") dir (string-trim-right dir "[/]")) (list (cons :side side)  (cons :time (current-time)))) new-hist)
	
	(efar-set new-hist :directory-history)))
    
    ;; set up file change notification for the directory
    (efar-setup-notifier dir side)
    (efar-calculate-widths)
    (efar-write-enable (efar-redraw))))


(defun efar-get-parent-dir (dir)
  "Return parent directory of given DIR."
  (let ((parent (file-name-directory (directory-file-name dir))))
    (cond ((null parent)
	   nil)
	  ((equal parent "/")
           parent)
	  (t
	   (string-trim-right parent "[/]")))))

(defun efar-go-to-file (file &optional side prev-file-number)
  "Move cursor to the given FILE or to PREV-FILE-NUMBER if file cannot be found.
Do this in current panel, unless SIDE is given."
  (let* ((side (or side (efar-get :current-panel)))
	 (file (if (equal (efar-get :panels side :mode) :files)
		   (directory-file-name (expand-file-name file (efar-get :panels side :dir)))
		 file))
	 (number-of-files (length (efar-get :panels side :files)))
	 (panel-mode (efar-get :panels side :mode))
	 (column-number (efar-get :panels side :view panel-mode :column-number))
	 (new-file-number
	  (or
	   (cl-position file
			(mapcar (lambda (e) (car e)) (efar-get :panels side :files))
			:test 'string=)
	   (if (>= prev-file-number number-of-files)
	       (- number-of-files 1)
	     prev-file-number))))
    (cond
     
     ((and
       (>= new-file-number (efar-get :panels side :start-file-number))
       (< new-file-number (+ (efar-get :panels side :start-file-number) (* column-number (efar-get :panel-height)))))
      
      (progn
	(efar-set (- new-file-number (efar-get :panels side :start-file-number)) :panels side :current-pos)))
     
     ((< new-file-number (* column-number (efar-get :panel-height)))
      (progn
	(efar-set 0 :panels side :start-file-number)
	(efar-set new-file-number :panels side :current-pos)))
     
     (t
      (progn
	(efar-set new-file-number :panels side :start-file-number)
	(efar-set 0 :panels side :current-pos))))))

(defun efar-current-file-number (&optional side)
  "Return the number of file under cursor.
Do that for current panel or for panel SIDE if it's given."
  (let* ((side (or side (efar-get :current-panel)))
	 (start-file-number (efar-get :panels side :start-file-number)))
    
    (+ start-file-number (efar-get :panels side :current-pos))))

(defun efar-current-file-name (&optional side)
  "Return the full name of file under cursor.
Do that for current panel or for panel SIDE if it's given."
  (car (efar-current-file side)))

(defun efar-current-file (&optional side)
  "Return the file under cursor with it's attributes.
Do that for current panel or for panel SIDE if it's given."
  (let ((side (or side (efar-get :current-panel))))
    (nth (efar-current-file-number side) (efar-get :panels side :files))))

(defun efar-other-side (&optional side)
  "Return opposite panel to current panel or to panel SIDE if one is given.
:left <-> :right"
  (let ((side (if side side (efar-get :current-panel))))
    (if (equal side :left) :right :left)))

(defun efar-select-all (&optional deselect)
  "Mark (unmark when DESELECT is t) all files in current panel."
  (efar-write-enable
   (let ((side (efar-get :current-panel)))
     (efar-set (unless deselect
		 (cl-remove-if (lambda(e) (equal (car e) ".."))
			       (efar-get :panels side :files)))
	       :panels side :selected)
     (efar-redraw))))

(defun efar-do-mark-file ()
  "Mark file under cursor."
  (interactive)
  (efar-when-can-execute
   (efar-mark-file)))

(defun efar-do-mark-all ()
  "Mark all files in current directory."
  (interactive)
  (efar-when-can-execute
   (efar-select-all nil)))

(defun efar-do-unmark-all ()
  "Unmark all files in current directory."
  (interactive)
  (efar-when-can-execute
   (efar-select-all t)))

(defun efar-mark-file (&optional no-move?)
  "Mark file under cursor in current panel.
Unless NO-MOVE? move curosr one item down."
  (let* ((side (efar-get :current-panel))
	 (current-item (car (efar-selected-files side t nil)))
	 (selected-items (efar-get :panels side :selected)))
    
    (when current-item
      (if (cl-member-if (lambda(e) (equal (car e) (car current-item))) selected-items)
	  (efar-set (cl-delete-if  (lambda(e) (equal (car e) (car current-item))) selected-items) :panels side :selected)
	(efar-set (push current-item selected-items) :panels side :selected)))
    
    (unless no-move? (efar-move-cursor  :down))))

(defun efar-edit-file (&optional for-read?)
  "Visit file under cursor.
When FOR-READ? is t switch back to eFar buffer."
  (let* ((side (efar-get :current-panel))
	 (file (caar (efar-selected-files side t)))
	 (mode (efar-get :panels side :mode)))

    ;; open file in other window
    (when file

      (when (not (file-exists-p file))
	(error "File doesn't exist!"))
      
      (let ((buffer (find-file-other-window file)))
	
	;; if file is opened from search result list then enable isearch mode
	(when (and (equal mode :search)
		   (not (string-empty-p (or (cdr(assoc :text efar-search-last-command-params)) ""))))
	  (goto-char 0)
	  (setq case-fold-search (cdr (assoc :ignore-case? efar-search-last-command-params)))
	  
	  (isearch-mode t (cdr (assoc :regexp? efar-search-last-command-params)))
	  
	  (let ((string (cdr (assoc :text efar-search-last-command-params))))
	    (if case-fold-search
		(setq string (downcase string)))
	    (isearch-process-search-string string
					   (mapconcat #'isearch-text-char-description string "")))
	  (when for-read? (isearch-exit)))
	
	;; if file opened for editing unmark its buffer to prevent auto kill of the buffer
	(when (and (equal buffer (efar-get :last-auto-read-buffer))
		   (not for-read?))
	  (efar-set nil :last-auto-read-buffer))
	
	;; if file opened for reading only then goto back to eFar
	(when for-read?
	  (select-window (get-buffer-window (get-buffer efar-buffer-name))))
	
	;; add file to the list of last opned files
	(unless for-read?
	  (let* ((current-hist (efar-get :file-history))
		 (new-hist (cl-subseq (cl-remove-if (lambda(e) (equal file (car e))) current-hist)
				      0 (when (> (length current-hist) efar-max-items-in-directory-history)
					  (- efar-max-items-in-directory-history 1)))))
	    (push (cons file (list (cons :side side)  (cons :time (current-time)))) new-hist)
	    
	    (efar-set new-hist :file-history)))
	
	buffer))))

(defun efar-do-show-file-history ()
  "Show file history."
  (interactive)
  (efar-when-can-execute
   (efar-change-panel-mode :file-hist)))

(defun efar-do-edit-file ()
  "Edit file under cursor."
  (interactive)
  (efar-when-can-execute
   (efar-edit-file)))

(defun efar-do-read-file ()
  "Show content of the file under cursor in other buffer."
  (interactive)
  (efar-when-can-execute
   (efar-edit-file t)))

(defun efar-set-files-order (files side)
  "Change sort direction of FILES in panel SIDE."
  (if (efar-get :panels side :sort-order)
      (reverse files)
    files))

(defun efar-is-root-directory (dir)
  "Return t if DIR is a root directory, nil otherwise."
  (string= (file-name-as-directory dir)
	   (file-name-directory (directory-file-name dir))))

(defun efar-get-file-list (side)
  "Read file list for the directory showed in panel SIDE."
  (let* ((filter (efar-get :panels side :file-filter))
	 (fast-search-string (efar-get :fast-search-string))
	 (mode (efar-get :panels side :mode))
	 (root? (cond ((equal mode :dir-diff)
		       (null efar-dir-diff-current-dir))
		      ((not (equal mode :files))
		       t)
		      (t
		       (efar-is-root-directory (efar-get :panels side :dir))))))
    (efar-set
     ;; if we are not in the root directory, we add entry to go up
     (append (unless root? (list (list ".." t)))
	     ;; change order of files according to selected mode (ASC or DESC)
	     (efar-set-files-order
	      
	      ;; build file list
	      (let ((files
		     ;; remove entries "." and ".." and filter file list according to selected wildcard
		     (cl-remove-if
		      (lambda (f)  (or
				    (string-suffix-p "/." (car f))
				    (string-suffix-p "/.." (car f))
				    (and (or (not (cadr f))
					     efar-filter-directories-p)
					 (not (string-suffix-p "/.." (car f)))
					 (> (length filter) 0 )
					 (not (string-match (wildcard-to-regexp filter) (car f))))
				    (and efar-fast-search-filter-enabled-p
					 fast-search-string
					 (not (string-match (if (cl-position ?* fast-search-string) (wildcard-to-regexp fast-search-string) fast-search-string)
							    (if (equal (car (efar-get :panels side :view (efar-get :panels side :mode) :file-disp-mode)) :long)
								(car f)
							      (efar-get-short-file-name f)))))))
		      
		      ;; get files and attributes
		      (efar-get-file-list-int side mode)))
		    
		    
		    ;; get selected sort function
		    ;; we do sorting only in modes :files and :search
		    (sort-function (cond ((or (equal mode :files)
					      (and (equal mode :search)
						   (not efar-search-running-p)))
					  (efar-get-sort-function (efar-get :panels side :sort-function-name)))
					 ((equal mode :dir-diff)
					  'efar-sort-files-by-name-dir-diff))))
		
	 	;;sort file list according to selected sort function
		(if sort-function
		    (sort files sort-function)
		  files))
	      
	      side))
     :panels side :files)))

(defun efar-get-file-list-int (side mode)
  "Prepare file list in panel SIDE.
The way to build a list depends on MODE."
  (pcase mode
    
    ;; panel is in mode :files
    (:files
     (directory-files-and-attributes (efar-get :panels side :dir) t nil t 'string))
    
    ;; entries to be displayed in directory history
    (:dir-hist
     (mapcar (lambda(d) (let ((attrs (file-attributes (car d) 'string)))
			  (append (push (car d) attrs) (list (cdr (assoc :time (cdr d)))))))
	     (efar-get :directory-history)))
    ;; entries to be displayed in file history
    (:file-hist
     (mapcar (lambda(d) (let ((attrs (file-attributes (car d) 'string)))
			  (append (push (car d) attrs) (list (cdr (assoc :time (cdr d)))))))
	     (efar-get :file-history)))
    ;; entries to be displayed in bookmark mode
    (:bookmark
     (mapcar (lambda(d) (let ((attrs (file-attributes d 'string)))
			  (push d attrs)))
	     (efar-get :bookmarks)))
    
    (:disks
     (let ((default-directory user-emacs-directory))
       (mapcar (lambda(d) (list d (file-directory-p d)))
	       (nconc (if (eq window-system 'w32)
			  (mapcar (lambda(e) (car (split-string e " " t)))
				  (cdr (split-string  (downcase (shell-command-to-string "wmic LogicalDisk get Caption"))
						      "\r\n" t)))
			(split-string (shell-command-to-string "df -h --output=target | tail -n +2") "\n" t))))))
    
    
    (:search
     (cl-copy-list (reverse efar-search-results)))

    (:search-hist
     (mapcar (lambda(e) (let ((text (cdr (assoc :text (car e))))
			      (dir (cdr (assoc :dir (car e))))
			      (wildcards (cdr (assoc :wildcards (car e)))))


			  (list (concat "Search"
					(when text (format " '%s'" text))
					(format " in %s (%s)"
						dir (string-join wildcards ","))
					(concat " -> "
						(when text
						  (let ((hits 0))
						    (cl-loop for file in (cdr e) do
							     (setq hits (+ hits (length (nth 13 file)))))
						    (format "%d hit(s) in" hits)))

						
						(format " %d file(s)" (length (cdr e)))))
				t)))
	     (reverse efar-search-history)))
    
    (:dir-diff
     (mapcar (lambda(e)
	       (append (list (expand-file-name (car (last e 3))
					       (if (equal side :left)
						   (cdr (assoc :left efar-dir-diff-last-command-params))
						 (cdr (assoc :right efar-dir-diff-last-command-params)))))
		       (cdr (car (last e 4)))
		       (list (car (last e 3)) (cl-subseq e 0 -4))))
	     (cl-remove-if (lambda(e)
			     (or (not (equal (car (last e))
					     efar-dir-diff-current-dir))
				 (and efar-dir-diff-show-changed-only-p
				      (efar-dir-diff-equal e))))
			   (hash-table-values efar-dir-diff-results))))))

(defun efar-move-cursor (direction &optional no-auto-read?)
  "Move cursor in direction DIRECTION.
When NO-AUTO-READ? is t then no auto file read happens."
  (let* ((side (efar-get :current-panel))
	 (panel-mode (efar-get :panels side :mode)))
    (unless (= 0 (length (efar-get :panels side :files)))
      
      (unless efar-fast-search-filter-enabled-p
	(efar-quit-fast-search))
      
      (cl-labels
	  ((move-for-side (side)
			  (efar-write-enable
			   (let* ((curr-pos (efar-get :panels side :current-pos))
				  (max-files-in-column (efar-get :panel-height))
				  (max-file-number (length (efar-get :panels side :files)))
				  (start-file-number (efar-get :panels side :start-file-number))
				  (col-number (efar-get :panels side :view panel-mode :column-number))
				  (affected-item-numbers ()))
			     (cond
			      ;; if UP key pressed
			      ((equal direction :up)
			       (cond
				;; if we are on the first file in the list - do nothing
				((and (= start-file-number 0) (= curr-pos 0)) nil)
				;; if we are on first item
				((= curr-pos 0)
				 (progn (let ((rest (- start-file-number (* col-number max-files-in-column))))
					  (efar-set (if (< rest 0) 0 rest)
						    :panels side :start-file-number)
					  (efar-set (if (< rest 0) (- start-file-number 1) (- (* col-number max-files-in-column) 1))
						    :panels side :current-pos))))
				;; else move up by one
				(t (progn
				     (push  curr-pos affected-item-numbers)
				     (cl-decf curr-pos)
				     (push  curr-pos affected-item-numbers)
				     (efar-set curr-pos :panels side :current-pos)))))
			      
			      ;; if DOWN key is pressed
			      ((equal direction :down)
			       (cond
				;; if we are on the last file in the list - do nohing
				((= (+ start-file-number curr-pos) (- max-file-number 1)) nil)
				;; else if we are on last item
				((= curr-pos (- (* max-files-in-column col-number) 1))
				 (progn (efar-set (+ start-file-number curr-pos 1)
						  :panels side :start-file-number)
					(efar-set 0
						  :panels side :current-pos) ))
				;; else move down by one
				(t (progn
				     (push  curr-pos affected-item-numbers)
				     (cl-incf curr-pos)
				     (push  curr-pos affected-item-numbers)
				     (efar-set curr-pos :panels side :current-pos)))))
			      
			      ;; if LEFT key is pressed
			      ((equal direction :left)
			       (cond
				;; if we are on the first file in the list - do nothing
				((and (= start-file-number 0) (= curr-pos 0)) nil)
				
				;; we are in right column - move left by max-files-in-column
				((>= curr-pos max-files-in-column) (efar-set (- curr-pos max-files-in-column)
									     :panels side :current-pos))
				
				;; we are in left column
				((< curr-pos max-files-in-column)
				 (cond
				  ((= start-file-number 0) (efar-set 0
								     :panels side :current-pos))
				  ((> start-file-number (* col-number max-files-in-column)) (efar-set (- start-file-number max-files-in-column)
												      :panels side :start-file-number))
				  ((<= start-file-number (* col-number max-files-in-column)) (and
											      (efar-set 0
													:panels side :start-file-number)
											      (efar-set 0
													:panels side :current-pos)))))))
			      
			      ;; if HOME key is pressed
			      ((equal direction :home)
			       (and
				(efar-set 0
					  :panels side :start-file-number)
				(efar-set 0
					  :panels side :current-pos)))
			      
			      
			      ;; if END key is pressed
			      ((equal direction :end)
			       (and
				(efar-set (if (< max-file-number (* col-number max-files-in-column)) 0 (- max-file-number (* col-number max-files-in-column)))
					  :panels side :start-file-number)
				(efar-set (- (if (< max-file-number (* col-number max-files-in-column))  max-file-number (* col-number max-files-in-column)) 1)
					  :panels side :current-pos)))
			      
			      
			      ;; if RIGHT key is pressed
			      ((equal direction :right)
			       (cond
				;; if we are on the last file in the list - do nohing
				((= (+ start-file-number curr-pos) (- max-file-number 1)) nil)
				
				;; if there is more than max-files-in-column left then "scroll-down" column
				((> (- max-file-number start-file-number curr-pos) max-files-in-column)
				 (if (< curr-pos (* (- col-number 1) max-files-in-column))
				     (efar-set (+ curr-pos max-files-in-column)
					       :panels side :current-pos)
				   (efar-set (+ start-file-number max-files-in-column)
					     :panels side :start-file-number)))
				;; else go to the last file in the list
				(t (progn
				     (if (or (< max-file-number max-files-in-column)
					     (< (- max-file-number start-file-number) max-files-in-column))
					 (progn
					   (efar-set (- max-file-number start-file-number 1) :panels side :current-pos))

				       (efar-set (- max-file-number max-files-in-column) :panels side :start-file-number)
				       (efar-set (- max-file-number (- max-file-number max-files-in-column) 1) :panels side :current-pos)))))))
			     
			     (efar-output-files side affected-item-numbers)
			     
			     (efar-output-file-details side)
			     
			     (efar-set-status)
			     
			     (condition-case err
				 (unless no-auto-read? (efar-auto-read-file))
			       (error (efar-set-status (format "Error: %s"(error-message-string err)) nil t t)))))))
	
	(move-for-side side)
	(when (equal panel-mode :dir-diff)
	  (move-for-side (efar-other-side side)))))))

(defun efar-do-move-down ()
  "Move cursor down."
  (interactive)
  (efar-move-cursor :down))
  
(defun efar-do-move-up ()
  "Move cursor up."
  (interactive)
  (efar-move-cursor :up))

(defun efar-do-move-left ()
  "Move cursor one page up."
  (interactive)
  (efar-move-cursor :left))

(defun efar-do-move-right ()
  "Move cursor one page down."
  (interactive)
  (efar-move-cursor :right))

(defun efar-do-move-home ()
  "Move cursor to the beginning of the file list."
  (interactive)
  (efar-move-cursor :home))

(defun efar-do-move-end ()
  "Move cursor to the end of the file list."
  (interactive)
  (efar-move-cursor :end))

(defun efar-auto-read-file ()
  "Automatically show content of the directory or file under cursor."
  
  (let* ((file (caar (efar-selected-files (efar-get :current-panel) t nil t)))
	 (file-ext (file-name-extension (downcase (or file "")))))
    (when (and file
	       (not (one-window-p)) ;; don't show when eFar occupies whole frame
	       (or  (and efar-auto-read-files ;; if file auto read is enabled
			 (< (file-attribute-size (file-attributes file)) efar-auto-read-max-file-size) ;; if file size is less than maximum allowed size
			 (or (and (equal (length efar-auto-read-file-extensions) 1) (string= "*" (car efar-auto-read-file-extensions))) ;; if any file type is configured to be auto read
			     (and file-ext (cl-member file-ext efar-auto-read-file-extensions :test 'equal)))) ;; or if files type is configured to be ato read
		    
		    (and efar-auto-read-directories ;; if directory auto read is enabled
			 (file-directory-p file)))) ;; current item under cursor is a directory
      
      (let ((last-auto-read-buffer (efar-get :last-auto-read-buffer))) ;; get the last auto read buffer
	;; we don't want to keep buffers for auto-opened files/dirs
	;; so we kill last auto read buffer if:
	;; - now we open different file
	;; - last auto read buffer is not modified
	(when (and
	       last-auto-read-buffer
	       (not (string= file (buffer-file-name last-auto-read-buffer)))
	       (not (buffer-modified-p last-auto-read-buffer)))
	  (kill-buffer last-auto-read-buffer))
	
	(let ((last-auto-read-buffer-exists? (get-file-buffer file)) ;; check if buffer for last auto read file exists
	      (buffer (efar-edit-file t))) ;; open current file for read
	  
	  ;; if buffer for last auto read file does not exists
	  ;; remember current buffer as last read one
	  (unless last-auto-read-buffer-exists?
 	    (efar-set buffer :last-auto-read-buffer)))))))

(defun efar-handle-enter (&optional copy-to-shell?)
  "Handle enter key pressing.
Do action depending on the type of item under cursor:
when directory - enter this directory
when executable file - open shell and execute it in the shell
when normal file - open it in external application.
When COPY-TO-SHELL? is t file name is copied to the shell."
  (let* ((side (efar-get :current-panel))
	 (file (car (efar-selected-files side t t))))
    
    (cond ((and (not copy-to-shell?)
		(or
		 ;; file is a normal directory
		 (equal (cadr file) t)
		 ;; file is a symlink pointing to the directory
		 (and (stringp (cadr file))
		      (file-directory-p (cadr file)))))
	   
	   (efar-enter-directory))
	  
	  ((or copy-to-shell?
	       (file-executable-p (car file)))
	   (efar-execute-file copy-to-shell?))
	  
	  (t (efar-do-open-file-in-external-app)))))

(defun efar-do-enter-directory ()
  "Enter element under cursor."
  (interactive)
  (efar-when-can-execute
   (let ((mode (efar-get :panels (efar-get :current-panel) :mode)))
     (pcase mode
       (:files (efar-handle-enter))
       (:dir-hist (efar-navigate-to-file))
       (:file-hist (efar-navigate-to-file))
       (:bookmark (efar-navigate-to-file))
       (:disks (efar-switch-to-disk))
       (:search (efar-navigate-to-file))
       (:search-hist (efar-search-open-from-history))
       (:dir-diff (efar-dir-diff-enter-directory))))))
 
(defun efar-do-enter-parent ()
  "Go to the parent directory."
  (interactive)
  (efar-when-can-execute
   (let ((mode (efar-get :panels (efar-get :current-panel) :mode)))
     (pcase mode
       (:files (efar-enter-directory t))
       (:dir-diff (efar-dir-diff-enter-directory t))))))

(defun efar-do-send-to-shell ()
  "Insert name of the file under the cursor to the shell."
  (interactive)
  (efar-when-can-execute
   (efar-handle-enter t)))

(defun efar-do-open-shell ()
  "Open shell buffer."
  (interactive)
  (efar-when-can-execute
   (efar-display-shell)))

(defun efar-display-shell (&optional go-to-dir?)
  "Open eshell buffer.
CD to `default-directory' when GO-TO-DIR? is t."
  (save-window-excursion
    (let* ((dir default-directory)
	   (eshell-buffer-name efar-shell-buffer-name))
      (eshell)
      (when (and (null eshell-current-command)
		 go-to-dir?)
	(with-current-buffer eshell-buffer-name
	  (goto-char (point-max))
	  (let ((old-input (eshell-get-old-input)))
	    (eshell-kill-input)
	    (eshell/cd dir)
	    (eshell-send-input)
	    (insert old-input))))))
  (switch-to-buffer-other-window efar-shell-buffer-name)
  (goto-char (point-max)))

(defun efar-execute-file (&optional dont-run?)
  "Insert file name under cursor to shell buffer.
Execute it unless DONT-RUN? is t."
  (efar-display-shell nil)
  (sit-for 0.1)
  (select-window (get-buffer-window (get-buffer efar-buffer-name)))
  
  (let* ((subtask-running? (with-current-buffer efar-shell-buffer-name
			     eshell-current-command ))
	 (ready? (or (null (get-buffer efar-shell-buffer-name))
		     (null subtask-running?)
		     (equal "Yes" (efar-completing-read (concat "Operation is in progress '"
								(with-current-buffer efar-shell-buffer-name
								  (concat eshell-last-command-name
									  (when eshell-last-arguments
									    (concat " "
										    (string-join eshell-last-arguments " ")))))
								"'. Abort? "))))))
    
    (when ready?
      (let* ((side (efar-get :current-panel))
	     (file (caar (efar-selected-files side t t))))
	
	(when subtask-running?
	  (with-current-buffer efar-shell-buffer-name
	    (eshell-kill-process)))
	(sit-for 0.1)
	(efar-display-shell nil)
	(goto-char (point-max))
	(unless dont-run?
	  (eshell-kill-input))
	(insert "\"" file "\" ")
	(unless dont-run?
	  (eshell-send-input))))))

(defun efar-enter-directory (&optional go-to-parent?)
  "Enter directory under cursor or parent directory when GO-TO-PARENT? is t."
  (let* ((side (efar-get :current-panel))
	 (current-dir-path (efar-get :panels side :dir))
	 (selected-file (car (efar-selected-files side t t)))
	 (file (if (or go-to-parent?
		       (equal (car selected-file) ".."))
		   ;; get parent directory
		   (list (efar-get-accessible-directory-in-path (efar-get-parent-dir current-dir-path)) t)
		 ;; get directory under cursor
		 selected-file)))
    (efar-quit-fast-search 'no-refresh)
    (when (or
	   ;; file is a normal directory
	   (equal (cadr file) t)
	   ;; file is a symlink pointing to the directory
	   (and (stringp (cadr file))
		(file-directory-p (cadr file))))
      (let ((newdir (expand-file-name (car file) current-dir-path)))
	(cond
	 ((not (file-accessible-directory-p  newdir))
	  (efar-set-status (concat "Directory "  newdir " is not accessible") 3 nil t))
	 
	 (t
	  (efar-go-to-dir newdir side)))))))

(defun efar-do-show-directory-history ()
  "Show directory history."
  (interactive)
  (efar-when-can-execute
   (efar-change-panel-mode :dir-hist)))

(defun efar-do-directory-history-previous ()
  "Go to the previous directory in the directory history."
  (interactive)
  (efar-when-can-execute
   (efar-go-directory-history-cycle :backward)))

(defun efar-do-directory-history-next ()
  "Go to the next directory in the directory history."
  (interactive)
  (efar-when-can-execute
   (efar-go-directory-history-cycle :forward)))

(defun efar-go-directory-history-cycle (direction)
  "Loop over directory history entries in direction DIRECTION."
  (let ((dir-hist (efar-get :directory-history)))
    (if (or (not dir-hist)
	    (zerop (length dir-hist)))
	
	(efar-set-status "Directory history is empty" 2 t t)
      
      (let* ((side (efar-get :current-panel))
	     (index (cl-position (efar-get :panels side :dir) dir-hist :test (lambda(a b) (equal a (car b)))))
	     (new-index (if (equal direction :forward) (+ 1 index) (- index 1))))
	(when (< new-index 0) (setf new-index (- (length dir-hist) 1)))
	(when (> new-index (- (length dir-hist) 1)) (setf new-index 0))
	(efar-go-to-dir (car (nth new-index dir-hist)) side t)
	(efar-write-enable (efar-redraw))))))

(defun efar-scroll-other-window (direction)
  "Scroll content of other window in direction DIRECTION."
  (scroll-other-window (if (eq direction :down) 1 -1)))

(defun efar-do-scroll-other-window-up ()
  "Scroll other window up."
  (interactive)
  (efar-when-can-execute
   (efar-scroll-other-window :up)))

(defun efar-do-scroll-other-window-down ()
  "Scroll other window down."
  (interactive)
  (efar-when-can-execute
   (efar-scroll-other-window :down)))

(defun efar-do-switch-to-other-panel ()
  "Switch to other panel."
  (interactive)
  (efar-when-can-execute
   (efar-quit-fast-search)
   (when (equal (efar-get :mode) :both)
     (let ((side (efar-get :current-panel)))
       
       (if (equal side  :left)
	   (progn
	     (efar-set :right :current-panel)
	     (setf default-directory (if (equal :dir-diff (efar-get :panels :right :mode))
					 (cdr (assoc :right efar-dir-diff-last-command-params))
				       (efar-get :panels :right :dir))))
	 (progn
	   (efar-set :left :current-panel)
	   (setf default-directory (if (equal :dir-diff (efar-get :panels :right :mode))
				       (cdr (assoc :left efar-dir-diff-last-command-params))
				     (efar-get :panels :left :dir))))))
     (efar-write-enable (efar-redraw)))))

(defun efar-calculate-window-size ()
  "Calculate and set windows sizes."
  ;; fix for the issue https://github.com/suntsov/efar/issues/17
  ;; request window-width and window-height of eFar buffer window explicitelly
  (let ((efar-window (get-buffer-window efar-buffer-name)))
    (efar-set (- (window-width efar-window) 1) :window-width)
    (efar-set (window-height efar-window) :window-height)
    (efar-set (- (window-height efar-window) 6) :panel-height)))

(defun efar-redraw (&optional reread-files?)
  "The main function to output content of eFar buffer.
When REREAD-FILES? is t then reread file list for both panels."
  (interactive)
  (with-current-buffer efar-buffer-name
    (efar-calculate-window-size)
    (erase-buffer)
    
    (if (< (efar-get :window-width) 30)
	(insert "eFar buffer is too narrow")
      ;; draw all border lines
      (efar-draw-border )
      ;; apply default face
      (put-text-property (point-min) (point-max) 'face 'efar-border-line-face)
      ;; output directory names above each panel
      (efar-output-dir-names :left)
      (efar-output-dir-names :right)
      ;; output panel headers with panel controls
      (efar-output-controls :left)
      (efar-output-controls :right)
      ;; output file lists
      (when reread-files?
	(efar-get-file-list :left)
	(efar-get-file-list :right))
      (efar-output-files :left)
      (efar-output-files :right)
      ;; output details about files under cursor
      (efar-output-file-details :left)
      (efar-output-file-details :right)
      ;; during drag we show hand pointer
      (when efar-mouse-down-p
	(put-text-property (point-min) (point-max) 'pointer 'hand)))))

(defun efar-do-reinit ()
  "Reinitialize eFar state."
  (interactive)
  (efar nil t))

(defun efar-get-short-file-name (file)
  "Return short name of a given FILE."
  (if (nth 1 file)
      (file-name-nondirectory (directory-file-name (nth 0 file)))
    (file-name-nondirectory (nth 0 file))))

(defun efar-output-file-details (side)
  "Output details of the file under cursor in panel SIDE."
  (let* ((mode (efar-get :mode))
	 (panel-mode (efar-get :panels side :mode))
	 (selected-file (car (efar-selected-files side t t
						  (not (equal :search-hist panel-mode)))))
	 (file (if (and (not (equal (car selected-file) ".."))
			(equal :dir-diff (efar-get :panels side :mode)))
		   (when selected-file
		     (append (list (car selected-file)) (file-attributes (car selected-file))))
		 selected-file))
	 (width (efar-panel-width side))
	 (status-string))
    
    (when (or (equal mode :both) (equal mode side))
      
      (cond
       ;; in search history mode we show some details about selected search request
       ((equal panel-mode :search-hist)
	(if efar-search-history
	    (let* ((search-rec (nth (efar-current-file-number side) (reverse efar-search-history)))
		   (started (cdr (assoc :start-time (car search-rec))))
		   (finished (cdr (assoc :end-time (car search-rec))))
		   (ignore-case? (cdr (assoc :ignore-case? (car search-rec))))
		   (regexp? (cdr (assoc :regexp? (car search-rec)))))
	      (setf status-string (format "Started: %s Took: %ds Regexp?: %S Ignore case?: %S"
					  (format-time-string "%D %T" started)
					  (- finished started)
					  regexp?
					  ignore-case?)))
	  (setf status-string "")))
       ;; in all other modes we show details about selected file/directory
       (t
	(if (and file
		 (efar-get :panels side :files)
		 (or (equal mode :both) (equal mode side)))
	    
	    (setf status-string (concat  (efar-get-short-file-name file)
					 "  "
					 (format-time-string "%x %X" (nth 6 file))
					 "  "
					 (if (equal (nth 1 file) t)
					     "Directory"
					   (when (numberp (nth 8 file))
					     (format "%d bytes (%s)" (nth 8 file) (efar-file-size-as-string (nth 8 file)))))))
	  (setf status-string (if (efar-get :panels side :files) "Non-existing or not-accessible file!" "")))))
      
      (efar-place-item nil (+ 3 (efar-get :panel-height))
		       status-string
		       'efar-border-line-face
		       width nil side :left t))))

(defun efar-panel-width (side)
  "Calculate and return the width of panel SIDE."
  (let ((widths (if (equal side :left)
		    (car (efar-get :column-widths))
		  (cdr (efar-get :column-widths)))))
    (if (null widths)
	0
      (+ (apply #'+ widths)
	 (- (length widths) 1)))))

(defun efar-output-files (side &optional affected-item-numbers)
  "Output the list of files in panel SIDE.
Redraw files with numbers in AFFECTED-ITEM-NUMBERS if given,
otherwise redraw all."
  (let ((mode (efar-get :mode)))
    (when (and
	   ;; when there are files to output
	   (not (zerop (length (efar-get :panels side :files))))
	   ;; and panel is displayed
	   (or (equal mode :both) (equal mode side)))
      
      (let ;; get column widths for given panel
	  ((widths (if (equal side :left)
		       (car (efar-get :column-widths))
		     (cdr (efar-get :column-widths))))
	   ;; get display mode for current panel
	   (disp-mode (car (efar-get :panels side :view (efar-get :panels side :mode) :file-disp-mode)))
	   (panel-mode (efar-get :panels side :mode)))
	
	(goto-char 0)
	(forward-line 1)
	
	(let*
	    ;; calculate start column for printing file names
	    ((start-column (cond ((equal side :left) 1) ;; left panel always starts at 1
				 ((and (equal side :right) (equal mode :right)) 1) ;; right panel when it's alone also starts at 1
				 (t (+ (efar-panel-width :left) 2)))) ;; otherwise start at position where left panel ends
	     ;; maximum number in one column
	     (max-files-in-column (efar-get :panel-height))
	     ;; file counter
	     (cnt 0)
	     ;; number of columns in the panel
	     (col-number (length widths))
	     ;; get subset of file which that should be displayed and will fit to the panel
	     (files (append (cl-subseq  (efar-get :panels side :files)
					(efar-get :panels side :start-file-number)
					(+ (efar-get :panels side :start-file-number)
					   (if (> (- (length (efar-get :panels side :files)) (efar-get :panels side :start-file-number)) (* max-files-in-column col-number))
					       (* max-files-in-column col-number)
					     (- (length (efar-get :panels side :files)) (efar-get :panels side :start-file-number)))))
			    
			    ;; append empty items if number of files to display is less then max files in panel
			    ;; in order to overwrite old entries
			    (make-list (let ((rest (- (length (efar-get :panels side :files)) (efar-get :panels side :start-file-number))))
					 (if (> rest (* max-files-in-column col-number))
					     0 (- (* max-files-in-column col-number) rest)))
				       (list "")))))
	  
	  ;; loop over column numbers
	  (cl-loop for col from 0 upto (- col-number 1) do
		   
		   (let* ;; get subset of files which fit in column
		       ((files-in-column (cl-subseq files
						    (* col max-files-in-column)
						    (* (+ col 1) max-files-in-column)))
			;; width of current column
			(column-width (nth col widths))
			;; calculate max widths of uid/gid if panel is in full mode
			(uid-gid-max-widths (when (equal disp-mode :full)
					      (let ((uid-width 0)
						    (gid-width 0))
						(cl-loop for f in files-in-column do
							 (setf uid-width (max uid-width (length (nth 3 f))))
							 (setf gid-width (max gid-width (length (nth 4 f)))))
						(cons uid-width gid-width)))))
		     
		     ;; loop over this subset
		     (cl-loop repeat (length files-in-column)  do
			      ;; move one line down
			      (forward-line)
			      
			      ;; we skip output if file number is not in the list of file numbers to be redrawed
			      (when (or (null affected-item-numbers) (member cnt affected-item-numbers))
				
				(let*
				    ;; current file to output
				    ((file (nth cnt files))
				     ;; is current file marked?
				     (marked? (cl-member-if (lambda(e) (equal (car file) (car e)))
							    (efar-get :panels side :selected)))
				     ;; is it an existing file?
				     (exists? (file-exists-p (car file)))
				     ;; get real file (for symlinks)
				     (real-file (if (not (stringp (cadr file)))
						    (cdr file)
						  (file-attributes (cadr file) 'string)))
				     ;; is it a directory?
				     (dir? (car real-file))
				     ;; is it a normal file?
				     (file? (not (car real-file)))
				     ;; file is executable?
				     (executable? (and file? (file-executable-p (car file))))
				     ;; is it a file under cursor?
				     (current? (and
						(= cnt (efar-get :panels side :current-pos))
						(or (equal side (efar-get :current-panel))
						    (equal :dir-diff (efar-get :panels :left :mode)))))
				     
				     ;; prepare string representing the file
				     (str (pcase disp-mode
					    ;; in short mode we just output short file name with optional ending "/"
					    (:short
					     (cond
					      ;; search history mode
					      ((equal :search-hist panel-mode)
					       (car file))
					      ;; in dir-compare mode we add shortcuts of comparison results
					      ((equal :dir-diff panel-mode)
					       (concat (file-name-nondirectory (car file))
						       (when (car real-file) "/")
						       (when (and file
								  (not (equal ".." (car file)))
								  (not (string-empty-p (car file))))

							 (let* ((results (cl-intersection efar-dir-diff-actual-comp-params
										       (cl-remove-if (lambda(e) (or (equal e :left)
														    (equal e :right)
														    (equal e :both)))
												     (car (last file)))))
								(result-shortcuts (cond
										   ((or (and (member :left (car (last file)))
											     (equal side :left))
											(and (member :right (car (last file)))
											     (equal side :right)))
										    "+")
										   ((or (and (member :left (car (last file)))
											     (equal side :right))
											(and (member :right (car (last file)))
											     (equal side :left)))
										    "-")
																				   
										   (t (mapconcat (lambda(e)
												   (substring (symbol-name e) 1 2))
												 results
												 ",")))))
							   (when (not (string-empty-p result-shortcuts))
							     (format " [%s]" result-shortcuts))))))
					      
					      (t (concat (file-name-nondirectory (car file))
							 (when (and efar-add-slash-to-directories
								    (car real-file)
								    (not (equal (car file) "/")))
							   "/")))))
					    
					    ;; in long mode we output full file path + some additional info depending on current mode
					    (:long
					     (let ((file-name (concat (car file)
								      (when (and efar-add-slash-to-directories (car real-file) (not (equal (car file) "/"))) "/"))))
					       (cond ((equal panel-mode :search)
						      (concat file-name
							      (when (nth 13 file) (format " (%s)" (length (nth 13 file))))))
						     ((or (equal panel-mode :dir-hist) (equal panel-mode :file-hist))
						      (concat (when (nth 13 file) (format-time-string "%Y-%m-%d   " (nth 13 file))) file-name))
						     (t file-name))))
					    ;; in deteiled mode we output detailed info about file
					    (:detailed (efar-prepare-detailed-file-info file column-width))
					    ;; in full mode we output all possible info about file
					    (:full (efar-prepare-detailed-file-info file column-width 'full uid-gid-max-widths))))
				     ;; get corresponding face
				     (face
				      (cond
				       ;; directory comparator mode
				       ((equal panel-mode :dir-diff)
					(let* ((comp-values (nth 14 file))
					       (new? (member side comp-values))
					       (removed? (member (efar-other-side side) comp-values))
					       (changed? (or (member :children-changed comp-values)
							     (cl-intersection efar-dir-diff-actual-comp-params
									      comp-values))))
					  (cond
					   ((and removed? current?) 'efar-dir-diff-removed-current-face)
					   ((and removed? (not current?)) 'efar-dir-diff-removed-face)
					   
					   ((and new? current?) 'efar-dir-diff-new-current-face)
					   ((and new? (not current?)) 'efar-dir-diff-new-face)
					   
					   ((and changed? current?)  'efar-dir-diff-changed-current-face)
					   ((and changed? (not current?))  'efar-dir-diff-changed-face)
					   
					   (current? 'efar-dir-diff-equal-current-face)
					   (t  'efar-dir-diff-equal-face))))

				       ;; search history mode
				       ((equal panel-mode :search-hist)
					(cond (current? 'efar-dir-current-face)
					      ((not current?) 'efar-dir-face)))
					
				       ((and (not exists?) current?) 'efar-non-existing-current-file-face)
				       ((not exists?) 'efar-non-existing-file-face)
				       
				       ((and current? marked?) 'efar-marked-current-face)
				       ((and (not current?) marked?) 'efar-marked-face)
				       
				       ((and current? executable?) 'efar-file-current-executable-face)
				       ((and (not current?) executable?) 'efar-file-executable-face)
				       
				       ((and dir? current?) 'efar-dir-current-face)
				       ((and file? current?) 'efar-file-current-face)
				       ((and dir? (not current?)) 'efar-dir-face)
				       ((and file? (not current?)) 'efar-file-face))))
				  
				  (efar-place-item
				   ;; calculate start output position for column
				   (+ start-column
				      (apply #'+ (cl-subseq widths 0 col))
				      col)
				   nil  str face column-width (and (eq :long disp-mode)
								   (not (cl-member panel-mode '(:dir-hist :file-hist))))
				   nil nil t
				   (list (cons :side side)
					 (cons :control (unless (string-empty-p str) :file-pos))
					 (cons :file-name (car file))
					 (cons :file-number cnt)
					 (cons :switch-to-panel t)))))
			      
			      ;; go to next file
			      (cl-incf cnt))
		     
		     (goto-char 0)
		     (forward-line 1))))))))

(defun efar-output-controls (side)
  "Output eFar header with controls in panel SIDE."
  (let ((mode (efar-get :mode)))
    
    (when (or (equal mode :both) (equal mode side))
      
      (goto-char 0)
      (forward-line)
      
      (let* ((col (cond
		   ((or (equal side :left) (not (equal mode :both))) 1)
		   (t (+ (efar-panel-width :left) 2))))
	     
	     (filter (efar-get :panels side :file-filter))
	     (fast-search-string (efar-get :fast-search-string))
	     (panel-mode (efar-get :panels side :mode))
	     (column-number (efar-get :panels side :view panel-mode :column-number))
	     (str))
	
	;; output controls to change sort function and sort order
	(let ((panel-mode (efar-get :panels side :mode)))
	  
	  (when (or (equal panel-mode :files)
		    (and (equal panel-mode :search)
			 (not efar-search-running-p)))
	    
	    (setf str (substring (efar-get :panels side :sort-function-name) 0 1))
	    (efar-place-item col 1 str 'efar-controls-face nil nil nil nil nil
			     (list (cons :side side) (cons :control :sort-func))
			     'hand)
	    
	    (setf str (if (efar-get :panels side :sort-order) (char-to-string 9660) (char-to-string 9650)))
	    (efar-place-item (+ col 1) 1 str 'efar-controls-face nil nil nil nil nil
			     (list (cons :side side) (cons :control :sort-order))
			     'hand)))

	;; output controls in dir compare mode
	(when (equal :dir-diff (efar-get :panels side :mode))
	  (setf str (if efar-dir-diff-show-changed-only-p
			"[a]"
		      "[A]"))
	  (efar-place-item col 1 str 'efar-controls-face nil nil nil nil nil
			   (list (cons :control :dir-diff-display-changed-only))
			   'hand)
	 
	  (efar-place-item (+ col 4) 1 "[" 'efar-controls-face)
	  (let ((cnt 5))
	    (cl-loop for par in efar-dir-diff-comp-params do
		     (efar-place-item (+ col cnt) 1
				      (if (member par efar-dir-diff-actual-comp-params)
					  (capitalize (substring (symbol-name par) 1 2))
					(substring (symbol-name par) 1 2))
				      'efar-controls-face
				      nil nil nil nil nil
				      (list (cons :param par) (cons :control :dir-diff-comp-param-switcher))
				      'hand)
		     (cl-incf cnt))
	    (efar-place-item (+ col cnt) 1 "]" 'efar-controls-face)))
	
	;; output filter string
	(unless (and (string-empty-p filter)
	 	     (null fast-search-string))
	  (setf str (if (and fast-search-string
	 		     (equal side (efar-get :current-panel)))
	 		(concat "Fast search: " fast-search-string)
	 	      (if (string-empty-p filter) "" (concat "Filter: " filter))))
	  (efar-place-item (+ col 4) 1 str 'efar-border-line-face))
	
	;; output control for changing column number and panel mode
	(setf str (concat "- " (int-to-string column-number) " +"))
	(efar-place-item nil 1 str 'efar-controls-face nil nil side :center nil
			 (list (cons :side side) (cons :control :col-number))
			 'hand)
	
	;; output panel mode switcher
	(when (equal (efar-get :panels side :mode) :files)
	  (setf str (pcase (car (efar-get :panels side :view (efar-get :panels side :mode) :file-disp-mode))
	 	      (:short "S")
	 	      (:long "L")
	 	      (:detailed "D")
		      (:full "F")))
	  (efar-place-item (+ col (- (efar-panel-width side) 3)) 1 str 'efar-controls-face nil nil nil nil nil
			   (list (cons :side side) (cons :control :file-disp-mode))
			   'hand))
	
	;; output maximize/minimize control
	(setf str (if (equal (efar-get :mode) :both)
	 	      (char-to-string 9633)
	 	    (char-to-string 8213)))
	(efar-place-item (+ col (- (efar-panel-width side) 1)) 1 str 'efar-controls-face nil nil nil nil nil
			 (list (cons :side side) (cons :control :maximize))
			 'hand)))))

(defun efar-prepare-string (str len &optional cut-from-beginn? dont-fill?)
  "Prepare file name STR.
String is truncated to be not more than LEN characters long.
When CUT-FROM-BEGINN? is t then string is truncated from the beginn,
otherwise from the end.
Unless DONT-FILL? fill string with spaces if it shorter than LEN."
  (let ((cut-from-beginn? (or cut-from-beginn?))
	(dont-fill? (or dont-fill?)))
    
    (cond ((> (length str) len)
	   (if cut-from-beginn?
	       (concat "<" (cl-subseq str (+ (- (length str) len) 1)))
	     (concat (cl-subseq str 0 (- len 1)) ">")))
	  
	  ((and (not dont-fill?)
		(< (length str) len))
	   (concat str (make-string (- len (length str)) ?\s)))
	  
	  (t
	   str))))

(defun efar-place-item (column line text face &optional max-length cut-from-beginn? side start-pos fill? control-params pointer)
  "Outputs an UI item.
Start output from COLUMN in LINE.
TEXT is a string representing item.
FACE is a face applied to the text.

When MAX-LENGTH is given then truncate or extand (when FILL? is t) text
to be MAX-LENGTH characters long.
When CUT-FROM-BEGIN? is t then string is truncated from beginning,
otherwise from end.

If COLUMN is not given then following optional parameters move into action:
SIDE - place in given panel
START-POS (:left or :center) - defines how to align item within the panel.

CONTROL-PARAMS - item is considered as control with given parameters"
  
  ;; when line number is given goto this line
  ;; otherwise we place item in current line
  (when line
    (goto-char 0)
    (forward-line line))
  
  (let* ((mode (efar-get :mode))
	 (text (if max-length
		   (efar-prepare-string text max-length cut-from-beginn? (not fill?))
		 text))
	 (length (length text))
	 (col (if column column
		(pcase start-pos
		  (:left
		   (if (equal side :right)
		       (+ (if (equal mode :both) 2 1) (efar-panel-width :left))
		     1))
		  
		  (:center
		   
		   (if (equal side :right)
		       (+ (if (equal mode :both) 1 0) (efar-panel-width :left) (- (ceiling (efar-panel-width :right) 2) (floor length 2)))
		     (- (ceiling (efar-panel-width :left) 2) (floor length 2)))))))
	 (pointer (or pointer 'arrow)))
    
    (move-to-column col)
    (let ((p (point)))
      (delete-region p (+ p length))
      (insert text)
      (put-text-property p (+ p length) 'face face)
      (put-text-property p (+ p length) 'pointer pointer)
      (when control-params
	(put-text-property p (+ p length) :control control-params)))))

(defun efar-output-dir-names (side)
  "Output current directory name for panel SIDE."
  (let ((mode (efar-get :mode)))
    
    (when (or (equal mode :both) (equal mode side))
      
      (let* ((dir (efar-get :panels side :dir))
	     (face (if (equal side (efar-get :current-panel))
		       'efar-dir-name-current-face
		     'efar-dir-name-face)))
	
	(efar-place-item nil 0 dir face (efar-panel-width side) t side :center nil
			 (list (cons :side side) (cons :switch-to-panel t) (cons :control :directory-name))
			 'hand)))))

(defun efar-draw-border ()
  "Draw eFar border using pseudo graphic characters."
  (goto-char 0)
  
  (let ((panel-height (efar-get :panel-height)))
    
    ;; header area
    (efar-draw-border-line 9556 ;; ╔
			   9574 ;; ╦
			   9559 ;; ╗
			   9552 ;; ═
			   9552 ;; ═
			   'newline)
    
    (efar-draw-border-line 9553 ;; ║
			   9553 ;; ║
			   9553 ;; ║
			   32 ;; space
			   nil
			   'newline)
    
    ;; files area
    (cl-loop repeat panel-height do
	     (efar-draw-border-line 9553 ;; ║
				    9553 ;; ║
				    9553 ;; ║
				    32 ;; space
				    9474 ;; │
				    'newline))
    ;; file details area
    (efar-draw-border-line 9568 ;; ╠
			   9580 ;; ╬
			   9571 ;; ╣
			   9552 ;; ═
			   9575 ;; ╧
			   'newline)
    
    (efar-draw-border-line 9553 ;; ║
			   9553 ;; ║
			   9553 ;; ║
			   32 ;; space
			   nil
			   'newline)
    
    (efar-draw-border-line 9562 ;; ╚
			   9577 ;; ╩
			   9565 ;; ╝
			   9552 ;; ═
			   nil)))

(defun efar-draw-border-line (left center right filler splitter &optional newline)
  "Draw the line according to given arguments.
LEFT is a character to be used to draw left border.
CENTER is a character to be used to draw vertical splitter between panels.
RIGHT is a character to be used to draw right border.
FILLER is a character to be used as a filler between borders
when SPLITTER is not given, otherwise use SPLITTER.
NEWLINE - if t the insert newline character."
  (let ((mode (efar-get :mode)))
    (cl-loop for side
	     from (if (or (equal mode :left) (equal mode :both)) 1 2)
	     upto (if (or (equal mode :right) (equal mode :both)) 2 1)
	     initially do (insert-char left 1)
	     finally do (insert-char right 1)
	     do
	     (let* ((s (if (= side 1) :left :right))
		    (panel-mode (efar-get :panels s :mode))
		    (column-number (efar-get :panels s :view panel-mode :column-number)))
	       
	       (let ((p (point)))
		 (cl-loop for col from 0 upto (- column-number 1)	do
			  
			  (let ((col-number column-number))
			    
			    (insert-char filler (nth col (if (= side 1)
							     (car (efar-get :column-widths))
							   (cdr (efar-get :column-widths)))))
			    
			    (if (not (= (+ col 1) col-number))
				(insert-char (or splitter filler) 1)))
			  
			  (put-text-property p (point) 'pointer 'arrow)))
	       
	       (when (and (equal mode :both) (equal s :left))
		 (insert-char center 1)
		 (put-text-property (- (point) 1) (point) :control (list (cons :control :splitter)))
		 (put-text-property (- (point) 1) (point) 'pointer 'hdrag))))
    (when newline
      (newline)
      (forward-line))))

(defun efar-calculate-widths ()
  "Calculate widths of all columns in the panels."
  (let* ((splitter-shift (or (efar-get :splitter-shift) 0))
	 (shift (cond ((equal splitter-shift 0) 0)
		      (t (floor (* (floor (efar-get :window-width) 2) (/ splitter-shift 100.0))))))
	 (widths ())
	 (left-widths ())
	 (right-widths ())
	 
	 (window-width (efar-get :window-width))
	 (mode (efar-get :mode))
	 (cols-left (efar-get :panels :left :view (efar-get :panels :left :mode) :column-number))
	 (cols-right (efar-get :panels :right :view (efar-get :panels :right :mode) :column-number))
	 
	 
	 (left-width (cond
		      ((equal mode :both) (- (floor (- window-width 3) 2) shift))
		      ((equal mode :left) (- window-width 2))
		      ((equal mode :right) 0)))
	 
	 (right-width (cond
		       ((equal mode :both) (+ (ceiling (- window-width 3) 2) shift))
		       ((equal mode :left) 0)
		       ((equal mode :right) (- window-width 2)))))
    
    (unless (zerop left-width)
      (let* ((left-min-col-width (floor (/ (- left-width (- cols-left 1)) cols-left)))
	     (left-leftover (- left-width (- cols-left 1) (* left-min-col-width cols-left))))
	
	(setf left-widths (make-list cols-left left-min-col-width))
	
	(let ((cnt 0))
	  (while (not (zerop left-leftover))
	    (cl-incf (nth cnt left-widths))
	    (cl-decf left-leftover)
	    (cl-incf cnt)
	    (when (= cnt (length left-widths))
	      (setf cnt 0))))))
    
    (unless (zerop right-width)
      (let* ((right-min-col-width (floor (/ (- right-width (- cols-right 1))  cols-right)))
	     (right-leftover (- right-width (- cols-right 1) (* right-min-col-width cols-right))))
	
	(setf right-widths (make-list cols-right right-min-col-width))
	
	(let ((cnt 0))
	  (while (not (zerop right-leftover))
	    (cl-incf (nth cnt right-widths))
	    (cl-decf right-leftover)
	    (cl-incf cnt)
	    (when (= cnt (length right-widths))
	      (setf cnt 0))))))
    
    (setf widths (cons left-widths right-widths))
    
    (efar-set widths :column-widths)))

(defun efar-window-conf-changed ()
  "Function called when window configuration is changed.
Redraws entire eFar buffer."
  (let ((window (get-buffer-window efar-buffer-name)))
    (when window
      (efar-calculate-window-size)
      (efar-calculate-widths)
      (efar-write-enable
       (efar-redraw)))))

(defun efar-frame-size-changed (frame)
  "Function called when FRAME size is changed.
Redraws entire eFar buffer."
  
  (let ((window (get-buffer-window efar-buffer-name)))
    (when (and window
	       (equal (window-frame window) frame))
      (efar-calculate-window-size)
      (efar-calculate-widths)
      (efar-write-enable
       (efar-redraw)))))

(defun efar-buffer-killed ()
  "Function is called when eFar buffer is killed.
Saves eFar state and kills all subprocesses."
  (when (string= (buffer-name) efar-buffer-name)
    (efar-subprocess-killall-processes)
    (when (and
	   efar-save-state-p
	   
	   (ignore-errors
	     (efar-save-state))
	   (efar-remove-notifier :left)
	   (efar-remove-notifier :right)))
    (setf efar-state nil)))

(defun efar-emacs-killed ()
  "Function is called when Emacs is killed.
Saves eFar state and kills all subprocesses."
  (efar-subprocess-killall-processes)
  (when (and
	 efar-save-state-p
	 (get-buffer efar-buffer-name))
    (ignore-errors
      (efar-save-state))))

(defun efar-get-root-directory (path)
  "Return a root directory for given PATH."
  ;; get parent directory
  (let ((parent-dir
	 (file-name-directory
	  (directory-file-name path))))
    ;; if we are in root directory already
    (if (string= parent-dir path)
	path
      ;; otherwise check parent directory
      (efar-get-root-directory parent-dir))))

(defun efar-selected-files (side current? &optional up-included? skip-non-existing?)
  "Return a list of selected files in panel SIDE.
When CURRENT? is t return file under cursor only even if some more files marked.
When UP-INCLUDED? is t include '..' directory in the list.
When SKIP-NON-EXISTING? is t then non-existing files removed from the list."
  (let* ((marked-files (efar-get :panels side :selected))
	 (start-file-number (efar-get :panels side :start-file-number))
	 (current-file-number (+ start-file-number (efar-get :panels side :current-pos)))
	 (files (efar-get :panels side :files)))
    
    (when (> (length files) 0)
      (cl-remove-if (lambda(f) (and skip-non-existing? (not (file-exists-p (car f)))))
		    (remove (unless up-included? (list ".." t))
			    (if (or current? (not marked-files))
				(list (nth current-file-number files))
			      marked-files))))))

(defun efar-do-abort ()
  "Quit fast search mode when it's active.
Switch current panel to :files mode otherwise."
  (interactive)
  (efar-when-can-execute
   (unless (efar-get :fast-search-string)
     (let ((side (efar-get :current-panel)))
       (when (cl-member (efar-get :panels side :mode) '(:search :bookmark :dir-hist :file-hist :disks :dir-diff :search-hist))
	 (efar-go-to-dir (efar-last-visited-dir side) side)
	 (when (equal (efar-get :panels (efar-other-side side) :mode) :dir-diff)
	   (efar-go-to-dir (efar-last-visited-dir (efar-other-side side)) (efar-other-side side))))))
   (efar-quit-fast-search)))

(defun efar-last-visited-dir (&optional thing)
  "Return last visited directory for the THING.
THING could be :left or :right.  In this case it indicates corresponding panel.
Or it could be a string representing Windows drive letter."
  (let ((thing (or thing (efar-get :current-panel))))
    (or (catch 'dir
	  (cl-loop for d in (efar-get :directory-history) do
		   (when (or (and (symbolp thing)
				  (equal (cdr (assoc :side d)) thing))
			     (and (stringp thing)
				  (equal (efar-get-root-directory (expand-file-name (car d))) (file-name-as-directory thing))))
		     (throw 'dir (car d)))))
	(if (symbolp thing)
	    user-emacs-directory
	  thing))))

(defun efar-do-change-file-display-mode ()
  "Change file display mode."
  (interactive)
  (efar-when-can-execute
   (efar-change-file-disp-mode)))

(defun efar-change-file-disp-mode (&optional side)
  "Change file display mode in panel SIDE.
Mode is changed in the loop :short -> :detail -> :long."
  (let* ((side (or side (efar-get :current-panel)))
	 (modes (efar-get :panels side :view (efar-get :panels side :mode) :file-disp-mode))
	 (new-modes (reverse (cons (car modes) (reverse (cdr modes))))))
    (efar-set new-modes
	      :panels side :view (efar-get :panels side :mode) :file-disp-mode)
    
    (when (member (car new-modes) '(:full :detailed))
      (efar-set 1 :panels side :view (efar-get :panels side :mode) :column-number)))
  
  (efar-calculate-widths)
  (efar-write-enable (efar-redraw)))

(defun efar-prepare-detailed-file-info (file width &optional full? max-uid-gid-widths)
  "Prepare string with detailed info for FILE (size and date).
Truncate string to WIDTH characters.
When FULL? t, then include also file modes, uid and gid.
MAX-UID-GID-WIDTHS is relevant when FULL?.  It contains precalculated maximal
widths for uid and gid columns."
  (if (or (equal (car file) "..") (string-empty-p (car file)))
      (car file)
    (let* ((size (if (cadr file)
		     "DIR"
		   (efar-file-size-as-string (nth 8 file))))
	   (name (file-name-nondirectory  (car file)))
	   (time (format-time-string "%D %T" (nth 6 file)))
	   (file-modes (when full? (nth 9 file)))
	   (uid (when full? (nth 3 file)))
	   (gid (when full? (nth 4 file)))
	   (file-details-format (concat "%s   %s"
					(when full?
					  (concat
					   "   %s   "
					   "%-" (int-to-string (car max-uid-gid-widths)) "s   "
					   "%-" (int-to-string (cdr max-uid-gid-widths)) "s"))))
	   (file-details (format file-details-format size time file-modes uid gid)))
      
      (cond ((>= width (+ (length file-details)
			  (length name)
			  3))
	     (concat (efar-prepare-string name (- width (length file-details) 3)) "   " file-details))
	    
	    ((>= width (+ (length file-details)
			  5))
	     (concat (efar-prepare-string name (- width (length file-details) 3)) "   " file-details))
	    
	    (t
	     (concat (efar-prepare-string name 2) "   " (efar-prepare-string file-details (- width 5))))))))

(defun efar-file-size-as-string (size)
  "Prepare human readable string representing file SIZE."
  (cond ((< size 1024)
	 (concat (int-to-string size) " B"))
	((< size 1048576)
	 (concat (int-to-string (/ size 1024)) " KB"))
	((< size 1073741824)
	 (concat (int-to-string (/ size 1024 1024)) " MB"))
	(t
	 (concat (int-to-string (/ size 1024 1024 1024)) " GB"))))

(defun efar-do-ediff-files ()
  "Run ediff to compare files under cursor in both panels."
  (interactive)
  (efar-when-can-execute
   (let* ((selected-left (car (efar-selected-files :left t nil t)))
	  (selected-right (car (efar-selected-files :right t nil t)))
	  (file-name-left (if (equal :dir-diff (efar-get :panels :left :mode))
			      (expand-file-name (car (last selected-left 2)) (cdr (assoc :left efar-dir-diff-last-command-params)))
			    (car selected-left)))
	  (file-name-right (if (equal :dir-diff (efar-get :panels :right :mode))
			       (expand-file-name (car (last selected-right 2)) (cdr (assoc :right efar-dir-diff-last-command-params)))
			     (car selected-right))))
     (ediff file-name-left file-name-right))))

;;--------------------------------------------------------------------------------
;; Batch file renaming
;;--------------------------------------------------------------------------------
(defun efar-do-run-batch-rename ()
  "Very simple batch file renamer."
  ;; It's allowed to use following tags in the format string:
  ;;   <name>  -  replaced by whole file name with extension
  ;;   <basename>  -  replaced by file name without extension
  ;;   <ext>  -  replaced by extension with leading '.'
  ;;   <number>  -  replaced by running number.
  
  ;; Tags also can be written in different form:
  ;;   <name>, <NAME>, <Name>
  
  ;; Depending on the form corresponding part will be written in
  ;; lower case, upper case or will be capitalized.
  (interactive)
  (efar-when-can-execute
   (let* ((side (efar-get :current-panel))
	  (selected-files (efar-get :panels side :selected))
	  ;;gather files to rename
	  ;; get marked files if any
	  ;; get all files shown in the directory otherwise
	  (files (cl-remove-if (lambda(e)
				 (or (equal (car e) "..")
				     (and selected-files
					  (not (cl-member-if (lambda(e1) (equal (car e) (car e1)))
							     selected-files)))))
			       (efar-get :panels side :files)))
	  ;; format string to use for renaming
	  (format-string (read-string "Input format string: " "<basename>-<number><ext>"))
	  (cnt 0)
	  (rename-map '()))
     
     ;; fill the renaming map
     (cl-loop for f in files do
	      (cl-incf cnt)
	      (let* ((name (efar-get-short-file-name f))
		     (base-name (file-name-base (car f)))
		     (ext (file-name-extension (car f)))
		     (new-name format-string))
		
		(cl-labels
		    ((change-case (tag string value)
				  (let ((case-fold-search nil))
				    (cond ((string-match (upcase tag) string)
					   (upcase value))
					  ((string-match (downcase tag) string)
					   (downcase value))
					  ((string-match (capitalize tag) string)
					   (capitalize value))
					  (t value)))))
		  
		  (setf new-name (replace-regexp-in-string "<name>" (change-case "<name>" format-string name) new-name))
		  (setf new-name (replace-regexp-in-string "<basename>" (change-case "<basename>" format-string base-name) new-name))
		  (setf new-name (replace-regexp-in-string "<ext>" (if ext
								       (concat "." (change-case "<ext>" format-string ext)))
							   new-name)))
		(setf new-name (replace-regexp-in-string "<number>" (int-to-string cnt) new-name))
		(push (cons (car f) new-name) rename-map)))
     
     ;; show renaming map in the separate buffer
     (and (get-buffer efar-batch-buffer-name) (kill-buffer efar-batch-buffer-name))
     (let ((buffer (get-buffer-create efar-batch-buffer-name))
	   (duplicates? nil))
       
       (with-current-buffer buffer
	 (read-only-mode 0)
	 (erase-buffer)
	 (setq-local efar-rename-map rename-map)
	 (cl-loop for f in (reverse rename-map) do
		  (let ((p (point)))
		    (insert (car f) "\t->\t" (cdr f))
		    ;; when the result list contains duplicated file names
		    (when (or (> (cl-count-if (lambda(e) (equal (cdr f) (cdr e))) efar-rename-map) 1))
		      ;; highlight these duplicates
		      (setf duplicates? t)
		      (add-text-properties p (point)
					   '(face efar-non-existing-current-file-face))))
		  (newline))
	 
	 (align-regexp (point-min) (point-max) "\\(\\s-*\\)\t")
	 (goto-char 0)
	 
	 ;; insert header
	 (insert "Check the preliminary renaming results  bellow.")
	 (newline)
	 (if duplicates?
	     (progn
	       (insert "There are duplicates in the result list or files with resulting names already exist. Renaming is not possible.")
	       (newline)
	       (insert "Press 'C-g' to quit"))
	   (insert "Press 'r' to confirm and run batch renaming or 'C-g' to cancel it."))
	 (newline)
	 (newline)
	 (read-only-mode 1)
	 
	 ;; activate key binding to run actual renaming
	 (unless duplicates?
	   (local-set-key (kbd "r") (lambda()
				      (interactive)
				      ;; do the renaming
				      (cl-loop for f in efar-rename-map do
					       (efar-retry-when-error (rename-file (car f) (cdr f))))
				      (kill-buffer efar-batch-buffer-name)
				      (efar-write-enable (efar-redraw 'reread-files))
				      (efar nil))))
	 ;; activate key binding to quit
	 (local-set-key (kbd "C-g") (lambda()
				      (interactive)
				      (kill-buffer efar-batch-buffer-name)
				      (efar nil)))
	 (switch-to-buffer-other-window buffer))))))

;;--------------------------------------------------------------------------------
;; Batch replace in files
;;--------------------------------------------------------------------------------
(define-button-type 'efar-batch-replace-line-button
  'face 'efar-search-line-link-face )

(define-button-type 'efar-batch-replace-file-button
  'face 'efar-search-file-link-face )

(defun efar-do-run-batch-replace ()
  "Replace text in selected files interactively."
  (interactive)
  (efar-when-can-execute
   (let* ((side (efar-get :current-panel))
	  (selected-files (efar-get :panels side :selected))
	  ;;gather files
	  ;; get marked files if any
	  ;; get all files shown in the directory otherwise
	  (files (cl-remove-if (lambda(e)
				 (or (equal (car e) "..")
				     (and selected-files
					  (not (cl-member-if (lambda(e1) (equal (car e) (car e1)))
							     selected-files)))))
			       (efar-get :panels side :files)))
	  (regexp (read-string "String to replace (regexp): " ))
	  (replacement (read-string "Replace by: ")))
     
     ;; search string in selected files
     (let ((hits (make-hash-table)))
       (cl-loop for f in files do
		(with-temp-buffer
		  (insert-file-contents (car f))
		  (goto-char 0)
		  (while (re-search-forward regexp nil 'noerror)
		    (let ((h (or (gethash (car f) hits)
				 (puthash (car f) '() hits))))
		      
		      (push (cons (line-number-at-pos)
				  (replace-regexp-in-string "\n" "" (thing-at-point 'line t)))
			    h)
		      (puthash (car f) h hits))
		    (forward-line))))
       
       ;; prepare buffer to output preliminary results
       (and (get-buffer efar-batch-buffer-name) (kill-buffer efar-batch-buffer-name))
       (let ((buffer (get-buffer-create efar-batch-buffer-name))
	     (files 0)
	     (matches 0))
	 
	 (with-current-buffer buffer
	   (read-only-mode 0)
	   (erase-buffer)
	   ;; output file names and matches found in these files
	   (cl-loop for f being the hash-key of hits do
		    (insert-button f
				   :type 'efar-batch-replace-file-button
				   :file f)
		    (newline)
		    (cl-incf files)
		    (cl-loop for hit in (reverse (gethash f hits)) do
			     
			     (insert-button (concat (int-to-string (car hit)) ":\t" (cdr hit))
					    :type 'efar-batch-replace-line-button
					    :file f
					    :line-number (car hit))
			     (newline)
			     (cl-incf matches))
		    (newline))
	   
	   ;; output header
	   (goto-char 0)
	   (highlight-regexp regexp 'hi-yellow)
	   (goto-char 0)
	   ;; insert header
	   (insert "Replace '" regexp "' by '" replacement "'\n\n")
	   (insert "Press 'R' to replace all matches in all files\n\n")
	   (insert "Press 'r' to:\n")
	   (insert "  - replace all matches in particular file when point is over the line with file name\n")
	   (insert "  - replace matches in a single line when point is over the sorce line\n\n")
	   (insert "Press 'd' to remove from the list the item at point\n\n")
	   (insert "Press 'q' to close this buffer.\n\n")
	   (insert (int-to-string matches) " hit(s) in " (int-to-string files) " file(s)\n\n")
	   (read-only-mode 1)
	   
	   ;; setup keys
	   ;; key to close buffer
	   (local-set-key (kbd "q") (lambda ()
				      (interactive)
				      (kill-buffer efar-batch-buffer-name)
				      (efar nil)))
	   ;; function to process single line from the buffer
	   (cl-labels ((process-single (&optional replace)
				       ;; look for button at current position
				       (let* ((button (button-at (point)))
					      (file (when button (button-get button :file)))
					      (line-number (when button (button-get button :line-number))))
					 ;; if buton exists at point
					 (if button
					     (progn
					       ;; do replacement in the corresponding file
					       (when replace
						 (efar-retry-when-error (efar-batch-replace-in-file file regexp replacement line-number)))
					       (read-only-mode 0)
					       ;; delete processed line from the buffer
					       (delete-region (line-beginning-position) (1+ (line-end-position)))
					       ;; if that was a line representing file name
					       ;; delete all source lines belonging to that file
					       (unless line-number
						 (while (and (button-at (point))
							     (button-get (button-at (point)) :line-number))
						   (delete-region (line-beginning-position) (1+ (line-end-position)))
						   (when (equal (length (thing-at-point 'line t)) 1)
						     (delete-region (line-beginning-position) (1+ (line-end-position))))))
					       (read-only-mode 1))
					   (forward-line)))))
	     
	     ;; key to process all lines in the buffer
	     (local-set-key (kbd "R") (lambda ()
					(interactive)
					(goto-char 0)
					(while (not (eobp))
					  (process-single t))))
	     ;; to process single line
	     (local-set-key (kbd "r") (lambda ()
					(interactive)
					(process-single t)))
	     
	     ;; to remove single line without processing
	     (local-set-key (kbd "d") (lambda ()
					(interactive)
					(process-single)))))
	 
	 (switch-to-buffer-other-window buffer))))))

(defun efar-batch-replace-in-file (file regexp replacement &optional line-number)
  "Replace in FILE text matching REGEXP by REPLACEMENT.
When optional LINE-NUMBER is given then do replacement on corresponding line only."
  (let ((visited (get-file-buffer file))
	(buffer (find-file-noselect file))
	(modified nil))
    
    (with-current-buffer buffer
      (setf modified (buffer-modified-p))
      (goto-char 0)
      (when line-number (forward-line (- line-number 1)))
      (while (search-forward regexp (when line-number (line-end-position)) t)
	(replace-match replacement))
      (when (or (not modified)
		(equal "Yes" (efar-completing-read (concat "File " file " has unsaved changes. Save?"))))
	(save-buffer))
      (unless visited
	(kill-buffer buffer)))))

;;--------------------------------------------------------------------------------
;; Calculate file/directory stat
;;--------------------------------------------------------------------------------
(defun efar-do-file-stat ()
  "Display statisctics for selected file/directory."
  (interactive)
  (efar-when-can-execute
   (let ((ok? nil)
	 (current-file-entry (caar (efar-selected-files (efar-get :current-panel) t))))
     
     (unwind-protect
	 (let ((size 0)
	       (files 0)
	       (dirs 0)
	       (skipped 0))
	   
	   (efar-set-status (format "Calculating size of '%s'..." current-file-entry))
	   (sit-for 0.001)
	   (cl-labels
	       ((int-file-size(file)
			      ;; if item is a directory
			      (if (file-directory-p file)
	        		  ;; if directory is not accessible
				  (if (not (file-accessible-directory-p file))
				      ;; increment number of skipped directories
				      (cl-incf skipped)
				    
				    ;; get all items in the directory and call function recursively for each item
				    (mapc (lambda(f)
					    (unless (member f '(".." "."))
					      (int-file-size (expand-file-name f file))))
					  (directory-files file nil nil t))
				    (cl-incf dirs))
				
				;; otherwise if item is a file
				(cl-incf size (nth 7 (file-attributes file 'string)))
				(cl-incf files))))
	     
	     ;; run calculation for the current item in current panel
	     (int-file-size current-file-entry))
	   
	   ;; output stat in the status line
	   (let ((format-str (concat "%d bytes (%s) in %d directories and %d files."
				     (unless (zerop skipped) " %d directories skipped (no access)." ))))
	     (efar-set-status (format format-str
				      size (efar-file-size-as-string size) dirs files skipped)
			      nil t))
	   (setf ok? t))
       
       (unless ok?
	 (efar-set-status "Size calculation failed" nil t t))))))

(defconst efar-panel-modes
  '((:files . "Files")
    (:bookmark . "Bookmarks")
    (:dir-hist . "Directory history")
    (:file-hist . "File history")
    (:disks . "Disks/mount points")
    (:search . "Search results")
    (:search-hist . "Search history")
    (:dir-diff . "DC")))

(defun efar-do-move-splitter-left ()
  "Move panel splitter to the left."
  (interactive)
  (efar-when-can-execute
   (efar-move-splitter :left)))

(defun efar-do-move-splitter-right ()
  "Move panel splitter to the right."
  (interactive)
  (efar-when-can-execute
   (efar-move-splitter :right)))

(defun efar-do-move-splitter-center ()
  "Center panel splitter."
  (interactive)
  (efar-when-can-execute
   (efar-move-splitter :center)))

(defun efar-move-splitter (&optional shift)
  "Shift splitter between panels by SHIFT percantages."
  (let ((shift (cond ((equal shift :left)
		      (+ (or (efar-get :splitter-shift) 0) 2))
		     ((equal shift :right)
		      (- (or (efar-get :splitter-shift) 0) 2))
		     ((equal shift :center)
		      0)
		     ((numberp shift)
		      (+ (or (efar-get :splitter-shift) 0) shift)))))
    ;; we don't want to make panels too narrow
    (when (> shift 80) (setf shift 80))
    (when (< shift -80) (setf shift -80))
    (efar-set shift :splitter-shift)
    (efar-calculate-widths)
    (efar-write-enable (efar-redraw))))

(defun efar-change-panel-mode (mode &optional side)
  "Change mode of panel SIDE to MODE."
  (let ((side (or side (efar-get :current-panel)))
	(mode-name (cdr (assoc mode efar-panel-modes))))
    (efar-quit-fast-search 'no-refresh)
    
    (unless (equal mode (efar-get :panels side :mode))
      (efar-set 0 :panels side :current-pos)
      (efar-set 0 :panels side :start-file-number)
      (when (equal mode :dir-diff)
	(efar-set 0 :panels (efar-other-side side) :current-pos)))
    (efar-set mode :panels side :mode)
    (efar-get-file-list side)
    
    (cond
     ((equal mode :search)
      (efar-show-search-results side))
     
     ((equal mode :dir-diff)
      (efar-set mode :panels (efar-other-side side) :mode)
      (efar-get-file-list (efar-other-side side))
      (efar-dir-diff-show-results))
     
     (t
      (efar-set mode-name :panels side :dir)
      
      (efar-remove-notifier side)
      
      (efar-calculate-widths)
      (efar-write-enable (efar-redraw))))))

(defun efar-do-show-mode-selector ()
  "Show panel mode selector."
  (interactive)
  (efar-when-can-execute
   (let* ((side (efar-get :current-panel))
	  (current-mode (efar-get :panels side :mode))
	  (new-mode (car (rassoc (efar-completing-read "Switch to mode: "
						       (mapcar (lambda(m) (cdr m))
							       (append (list (cons current-mode (cdr (assoc current-mode efar-panel-modes))))
								       (cl-remove-if (lambda(m) (equal current-mode (car m))) efar-panel-modes))))
				 efar-panel-modes))))
     
     (pcase new-mode
       (:files (efar-go-to-dir (efar-last-visited-dir side) side))
       (:dir-hist (efar-change-panel-mode :dir-hist))
       (:file-hist (efar-change-panel-mode :file-hist))
       (:bookmark (efar-change-panel-mode :bookmark))
       (:disks (efar-change-panel-mode :disks))
       (:search (efar-change-panel-mode :search)))
     
     (efar-write-enable (efar-redraw)))))

(defun efar-do-show-bookmarks ()
  "Show bookmarks."
  (interactive)
  (efar-when-can-execute
   (efar-change-panel-mode :bookmark)))

(defun efar-do-add-bookmark ()
  "Add file to bookmarks."
  (interactive)
  (efar-when-can-execute
   (let ((current-file-entry (caar (efar-selected-files (efar-get :current-panel) t)))
	 (bookmarks (efar-get :bookmarks)))
     (push current-file-entry bookmarks)
     (efar-set bookmarks :bookmarks))
   (when (equal (efar-get :panels :left :mode) :bookmark)
     (efar-change-panel-mode :bookmark :left))
   (when (equal (efar-get :panels :right :mode) :bookmark)
     (efar-change-panel-mode :bookmark :right))))

(defun efar-delete-bookmark ()
  "Delete file from the bookmark list."
  (let* ((side (efar-get :current-panel))
	 (bookmarks (efar-get :bookmarks))
	 (entry (caar (efar-selected-files side t))))
    (when (and bookmarks
	       (string= "Yes" (efar-completing-read "Delete bookmark?")))
      (setq bookmarks (cl-remove entry bookmarks :test 'equal))
      (efar-set bookmarks :bookmarks)
      (when (equal (efar-get :panels :left :mode) :bookmark)
	(efar-change-panel-mode :bookmark :left))
      (when (equal (efar-get :panels :right :mode) :bookmark)
	(efar-change-panel-mode :bookmark :right)))))

(defun efar-navigate-to-file ()
  "Go to the file under cursor."
  (let ((entry (caar (efar-selected-files (efar-get :current-panel) t nil t))))
    (efar-quit-fast-search)
    (when entry
      (efar-go-to-dir (file-name-directory entry))
      (when (and (file-name-nondirectory entry) (not (string-empty-p (file-name-nondirectory entry))))
	(efar-go-to-file (file-name-nondirectory entry)))
      (efar-calculate-widths)
      (efar-write-enable (efar-redraw)))))

(defun efar-do-show-disk-selector ()
  "Show disks/mount points."
  (interactive)
  (efar-when-can-execute
   (efar-change-panel-mode :disks)))

(defun efar-switch-to-disk ()
  "Change to the selected Windows drive or Unix mount point."
  (let ((entry (caar (efar-selected-files (efar-get :current-panel) t nil t))))
    (efar-quit-fast-search)
    (when entry
      (efar-go-to-dir (efar-last-visited-dir entry))
      (efar-calculate-widths)
      (efar-write-enable (efar-redraw)))))

(defun efar-do-suggest-hint ()
  "Display in the statusbar the next tip for key bindings."
  (interactive)
  (let* ;; get functions
      ((funcs (let ((funcs '()))
		(map-keymap (lambda (e d) (when (and e d (symbolp d)) (cl-pushnew  d funcs))) efar-mode-map)
		funcs))
       ;; get next tip number to show
       (hint-number (if (> (efar-get :next-hint-number) (length funcs))
			0
		      (efar-get :next-hint-number)))
       ;; key binding to show this time
       (func (nth hint-number funcs)))
    
    ;; display tip in the statusbar
    (let* ((keys (with-current-buffer efar-buffer-name (where-is-internal func)))
	   (keys (mapconcat #'key-description keys ", ")))
      (efar-set-status (format "Hint: use '%s' to %s" keys (downcase (documentation func)))))
    
    ;; calculate and store next tip number
    (if (= (length funcs) (+ hint-number 1))
	(setq hint-number 0)
      (cl-incf hint-number))
    (efar-set hint-number :next-hint-number)))

;;--------------------------------------------------------------------------------
;; Subprocess long-running tasks (file search, directory comparison)
;;--------------------------------------------------------------------------------
;; Main functions
(defun efar-subprocess-command ()
  "Prepare the list with command line arguments for the long-taks subprocesses."
  (list (expand-file-name invocation-name invocation-directory)
	"--batch"
	"-l" (symbol-file 'efar)
	"-eval" "(efar-subprocess-main-loop)"))

(defun efar-subprocess-run-processes ()
  "Run log-tasks subprocesses."
  (efar-subprocess-killall-processes)
  (sleep-for 1)
  ;; start network server that will listen for the messages from subprocesses
  (efar-subprocess-start-server)
  (setq efar-subprocess-clients '())
  ;; start subprocess that acts as a subprocess manager:
  ;; - it creates and manages subprocesses
  ;; - it receives and exeutes commands from eFar
  (setq efar-subprocess-manager (efar-subprocess-make-process))
  ;; ask subprocess manager to create subprocesses
  (efar-subprocess-send-command efar-subprocess-manager
			    :run-subprocesses
			    '()))

(defun efar-subprocess-killall-processes ()
  "Kill all subprocesses (for long-tasks)."
  (when (and efar-subprocess-manager (process-live-p efar-subprocess-manager))
    (kill-process efar-subprocess-manager))
  (setq efar-subprocess-manager nil)
  
  (cl-loop for proc in efar-subprocess-processes do
	   (kill-process proc))
  
  (when (and efar-subprocess-server
	     (process-live-p efar-subprocess-server))
    (delete-process efar-subprocess-server))
  (setq efar-subprocess-server nil)
  (efar-dir-diff-clearup)
  (efar-search-clearup))

(defun efar-subprocess-start-server ()
  "Start server which will consume messages from subprocesses."
  (when (and efar-subprocess-server
	     (process-live-p efar-subprocess-server))
    (delete-process efar-subprocess-server))
  
  (setq efar-subprocess-server
	(make-network-process :server t
			      :service t
			      :name "efar-subprocess-server"
			      :filter #'efar-subprocess-filter
			      :sentinel #'efar-subprocess-server-sentinel
			      :noquery t))
  (set-process-query-on-exit-flag efar-subprocess-server nil)
  (setq efar-subprocess-server-port (cadr (process-contact efar-subprocess-server))))

(defun efar-subprocess-server-sentinel (proc message)
  "Set up sentinel for the subprocess server.
When a connection from subprocess PROC is opened (MESSAGE 'open'),
this subprocess is registered in the list of clients."
  (unless (equal proc efar-subprocess-server)
    (when (and (process-live-p proc)
	       (equal message "open from 127.0.0.1\n"))
      (set-process-query-on-exit-flag proc nil)
      (push (process-name proc) efar-subprocess-clients))))

(defun efar-subprocess-process-message (proc message-type data)
  "Process a message from a subprocess PROC.
Message consists of MESSAGE-TYPE and DATA."
  (when (or efar-search-running-p
	    efar-dir-diff-running-p)
    (pcase message-type
      ;; message from subprocess about found files
      ;; we just push this file to the search result list
      (:found-file (let* ((file (cdr (assoc :name data)))
			  (attrs (file-attributes file 'string)))
		     (push (append (push file attrs) (list (cdr (assoc :lines data)))) efar-search-results)))
      
      (:file-comp-result (let* ((key (cdr (assoc :key data)))
				(comp-result (cdr (assoc :result data)))
				(checksum-differs (cdr (assoc :checksum-differs data))))
			   
			   (let ((result (gethash key efar-dir-diff-results)))
			     (when checksum-differs
			       (push :hash result)
			       (puthash key result efar-dir-diff-results))
			     
			     (when comp-result
			       (puthash key (append result comp-result) efar-dir-diff-results)))
			   
			   (efar-dir-diff-update-parents key)))
      
      ;; message from the subprocess indicating that it finished his work
      ;; once all subprocesses send this message we assume that subprocess task is finished
      (:finished (setq efar-subprocess-clients (cl-remove (process-name proc) efar-subprocess-clients :test 'equal))
		 (unless efar-subprocess-clients
		   (efar-subprocess-work-finished)))
      ;; message from subprocess indicating that file was skipped due to inaccessibility
      ;; we just add ths file to the list of skipped ones
      (:file-error (let* ((last-command-params (cond
						(efar-search-running-p 'efar-search-last-command-params)
						(efar-dir-diff-running-p 'efar-dir-diff-last-command-params)))
			  (errors (cdr (assoc :errors (symbol-value last-command-params)))))
		     (push data errors)
		     (push (cons :errors errors) (symbol-value last-command-params))))
      ;; message from the subprocess about unhandled error
      ;; we show error message and abort the subprocess work
      (:common-error (push (cons :errors data) (cond
						(efar-search-running-p efar-search-last-command-params)
						(efar-dir-diff-running-p efar-dir-diff-last-command-params)))
		     (efar-subprocess-killall-processes)
		     (make-thread 'efar-subprocess-run-processes)
		     (efar-subprocess-work-finished)
		     (efar-set-status (concat "Error occurred during background operation: " data) nil nil t)))))

(defun efar-subprocess-make-process ()
  "Make subprocess."
  (let ((proc (make-process
	       :name "efar-subprocess"
	       :stderr (get-buffer-create "*eFar subprocess error*")
	       :command (efar-subprocess-command)
	       :filter #'efar-subprocess-filter
	       :coding efar-subprocess-coding
	       :noquery t)))
    
    (set-process-query-on-exit-flag proc nil)
    ;; send command to setup network connection to the server
    (efar-subprocess-send-command proc :setup-server-connection efar-subprocess-server-port)
    
    proc))

(defun efar-subprocess-main-loop ()
  "Main entry point for subprocesses.
Waits for commands in standard input."
  (let ((coding-system-for-write efar-subprocess-coding))
    (condition-case err
	(catch :exit
	  ;; subprocess main loop
	  (while t
	    ;; get command and arguments from the request arriving to standard input
	    (let* ((request-string (read-from-minibuffer ""))
		   (request (car (read-from-string request-string)))
		   (command (car request))
		   (args (cdr request)))
	      
	      (pcase command
		;; command to set up connection to the main process
		(:setup-server-connection
		 (setq efar-subprocess-server (make-network-process :name "efar-server"
								:host "localhost"
								:service args
								:noquery t
								:nowait t))
		 (set-process-query-on-exit-flag efar-subprocess-server nil)
		 (setq efar-subprocess-server-port args))
		
		;; command to start subprocesses (relevant for subprocess manager only)
		(:run-subprocesses
		 (cl-loop repeat efar-subprocess-max-processes  do
			  (push (efar-subprocess-make-process) efar-subprocess-processes)))
		
		;; command to inform main process that subprocess workd is finished
		(:finished
		 (process-send-string efar-subprocess-server (concat (prin1-to-string (cons :finished '())) "\n")))

		;; command to subprocess to finish work (process "dies")
		(:exit
		 (cl-loop for proc in efar-subprocess-processes do
			  (process-send-string proc (concat (prin1-to-string (cons :exit '())) "\n")))
		 (throw :exit t))

		;; FILE SEARCH COMMANDS
		;; command to start the search (relevant for search manager only)
		(:start-search
		 (progn
		   (efar-search-int-start-search args)
		   (cl-loop for proc in efar-subprocess-processes do
			    (while (accept-process-output proc 1)))
		   (while (accept-process-output nil 1))))
		
		;; command to subprocess to search text in the file
		(:search-in-file
		 (efar-search-process-file args))

		;; DIRECTORY COMPARE COMMANDS
		(:start-dir-compare
		 (progn
		   (efar-dir-diff-int-start-compare args)
		   (cl-loop for proc in efar-subprocess-processes do
			    (while (accept-process-output proc 1)))
		   (while (accept-process-output nil 1))))

		(:compare-checksums
		 (efar-dir-diff-compare-checksums args))))))
      
      (error
       (process-send-string  efar-subprocess-server (concat (prin1-to-string (cons :common-error (error-message-string err))) "\n"))))))

(defun efar-subprocess-send-command (proc command args)
  "Send COMMAND and ARGS to the subprocess PROC."
  (let ((cmd (concat (prin1-to-string (cons command args)) "\n"))
	(cnt 3))
    (if (catch :ready
	  (while (> cnt 0)
	    (when (process-live-p proc)
	      (throw :ready t))
	    (sleep-for 1)
	    (cl-decf cnt)))
	(process-send-string proc cmd)
      (message "Process is not active!"))))

(defun efar-subprocess-filter (proc string)
  "Filter function for the subprocess server.
Processes message STRING arriving from subprocess PROC."
  (let ((pending (assoc proc efar-subprocess-pending-messages))
	message
	index)
    (unless pending
      (setq efar-subprocess-pending-messages (cons (cons proc "") efar-subprocess-pending-messages))
      (setq pending  (assoc proc efar-subprocess-pending-messages)))
    
    (setq message (concat (cdr pending) string))
    
    (while (setq index (string-match "\n" message))
      (setq index (1+ index))
      
      (let* ((res (car (read-from-string (substring message 0 index))))
	     (message-type (car res))
	     (data (cdr res)))
	;; process message once we get full one (messages are separated by \n)
	(efar-subprocess-process-message proc message-type data))
      
      (setq message (substring message index)))
    
    (setcdr pending message)))

(defun efar-subprocess-get-next-process ()
  "Get next subprocess from the pool.
We do subprocess tasks sending commands one by one to all subprocesses by turns."
  (let* ((processes efar-subprocess-processes)
	 (last (car (last processes))))
    (setq efar-subprocess-processes (cons last (remove last processes)))
    (car efar-subprocess-processes)))

(defun efar-subprocess-work-finished ()
  "Execute actions when subprocess work is finished.
Restart subprocesses finally."
  (cond (efar-search-running-p (efar-search-finished))
	(efar-dir-diff-running-p (efar-dir-diff-finished)))
  (make-thread 'efar-subprocess-run-processes))

;;--------------------------------------------------------------------------------
;; File search
;;--------------------------------------------------------------------------------
(define-button-type 'efar-search-find-file-button
  'follow-link t
  'action #'efar-search-find-file-button
  'face 'efar-search-file-link-face)

(define-button-type 'efar-search-find-line-button
  'follow-link t
  'action #'efar-search-find-file-button
  'face 'efar-search-line-link-face )

(defun efar-do-start-search ()
  "Start file search."
  (interactive)
  (efar-when-can-execute
   ;; if directory comparison or search is running, ask user whether to stop them
   (when (or (and efar-search-running-p
		  (string= "Yes" (efar-completing-read "Search is running. Kill it?")))
	     (and efar-dir-diff-running-p
		  (string= "Yes" (efar-completing-read "Directory comparison is running. Kill it?"))))
     ;; restart search processes
     (efar-subprocess-run-processes)
     (setq efar-search-running-p nil)
     (setq efar-dir-diff-running-p nil))
   
   ;; init efar if needed
   (efar nil nil t)
   
   (unless (or efar-search-running-p
	       efar-dir-diff-running-p)
     ;; gather search parameters
     (let* ((proposed-dir (if (called-interactively-p "interactive")
			      default-directory
			    (let ((selected-item (caar (efar-selected-files (efar-get :current-panel) t))))
			      (cond ((null  selected-item)
				     default-directory)
				    ((file-directory-p selected-item)
				     selected-item)
				    (t
				     (efar-get-parent-dir selected-item))))))
	    (dir (read-directory-name "Search in: " proposed-dir proposed-dir))
	    (wildcards (split-string (read-string "File name mask(s): "
						  (let ((wildcards (cdr (assoc :wildcards efar-search-last-command-params))))
						    (if wildcards (string-join wildcards ",")
						      efar-search-default-file-mask)))
				     "[, ]+"))
	    (text (read-string "Text to search: " (cdr (assoc :text efar-search-last-command-params))))
	    (ignore-case? (and (not (string-empty-p text)) (string=  "Yes" (efar-completing-read "Ignore case? " (list "Yes" "No")))))
	    (regexp? (and (not (string-empty-p text)) (string=  "Yes" (efar-completing-read "Use regexp? " (list "No" "Yes"))))))
       
       (setq efar-search-last-command-params nil)
       (setq efar-search-last-command-params (list (cons :dir dir)
						   (cons :wildcards wildcards)
						   (cons :text (if (string-empty-p text) nil text))
						   (cons :ignore-case? ignore-case?)
						   (cons :regexp? regexp?)
						   (cons :start-time (time-to-seconds (current-time)))))
       
       ;; set up timer that will update search list result during search
       (setq efar-search-update-results-timer
	     (run-at-time nil 2
			  (lambda()
			    (when (equal :search (efar-get :panels :left :mode))
			      (efar-change-panel-mode :search :left))
			    
			    (when (equal :search (efar-get :panels :right :mode))
			      (efar-change-panel-mode :search :right)))))
       (setq efar-search-results '())
       (setq efar-search-running-p t)
       (efar-set 0 :panels :left :current-pos)
       (efar-change-panel-mode :search)
       ;; send command to the manager to start the search with given parameters
       (efar-subprocess-send-command efar-subprocess-manager
				     :start-search
				     efar-search-last-command-params)
       
       (when (called-interactively-p "interactive") (efar nil))))))

(defun efar-do-show-search-results ()
  "Show search results."
  (interactive)
  (efar-when-can-execute
   (efar-change-panel-mode :search)))

(defun efar-do-show-search-history ()
  "Show search history."
  (interactive)
  (efar-when-can-execute
   (efar-change-panel-mode :search-hist)))

(defun efar-search-finished ()
  "Function is called when search is finished."
  (while (accept-process-output))
  ;; cancel update timer
  (when (timerp efar-search-update-results-timer)
    (cancel-timer efar-search-update-results-timer))
  (setq efar-search-update-results-timer nil)
  ;; fix end time
  (push (cons :end-time (time-to-seconds (current-time))) efar-search-last-command-params)
  
  (setq efar-search-running-p nil)

  (push (cons efar-search-last-command-params efar-search-results) efar-search-history)
  
  (efar-change-panel-mode :search))

(defun efar-search-int-start-search (args)
  "Start file search with parameters defined in ARGS in the subprocess.
Executed in search manager process."
  (let ((dir (cdr (assoc :dir args)))
	(wildcards (cdr (assoc :wildcards args)))
	(text (cdr (assoc :text args)))
	(regexp? (or (cdr (assoc :regexp? args)) nil))
	(ignore-case? (or (cdr (assoc :ignore-case? args)) nil)))
    ;; do the search with given parameters
    (efar-search-files-recursively dir wildcards text regexp? ignore-case?)
    ;; once all files in the directory are processed, send command to subprocesses to finish work
    (cl-loop for proc in efar-subprocess-processes do
	     (efar-subprocess-send-command proc :finished '()))
    ;; inform main process that manager finished the search
    (process-send-string efar-subprocess-server (concat (prin1-to-string (cons :finished '())) "\n"))))

(defun efar-search-files-recursively (dir wildcards &optional text regexp? ignore-case?)
  "Main search function.
Does the search for files in directory DIR.
Files should match file mask(s) WILDCARDS.
When TEXT is not nil given string is searched in the files.
When REGEXP? is t text is treated as regular expression.
Case is ignored when IGNORE-CASE? is t."
  ;; loop over all entries in the DIR
  (cl-loop for entry in (cl-remove-if (lambda(e) (or (string= (car e) ".") (string= (car e) ".."))) (directory-files-and-attributes dir nil nil t 'string)) do
	   
	   (let* ((symlink? (stringp (cadr entry)))
		  (dir? (or (equal (cadr entry) t)
			    (and symlink?
				 (file-directory-p (cadr entry)))))
		  (real-file-name (expand-file-name (if symlink?
							(cadr entry)
						      (car entry))
						    dir)))
	     
	     ;; we process directory only if it is accessible
	     ;; otherwise we skip it and report an error
	     (if (and dir?
		      (not (file-accessible-directory-p real-file-name)))
		 (process-send-string  efar-subprocess-server (concat (prin1-to-string (cons :file-error (cons real-file-name "directory is inaccessible"))) "\n"))
	       
	       ;; when entry is a directory or a symlink pointing to the directory call function recursivelly for it
	       (when (and dir?
			  (or (not symlink?)
			      efar-search-follow-symlinks-p))
		 (efar-search-files-recursively real-file-name wildcards text regexp? ignore-case?))
	       
	       ;; when entry is a file or text for search inside files is not given
	       (when (or (not dir?)
			 (not text))
		 
		 ;; if file name matches any of given WILDCARDS
		 (when (catch :matched
			 (cl-loop for wildcard in wildcards do
				  (when (string-match-p (wildcard-to-regexp wildcard) (car entry))
				    (throw :matched t)))
			 nil)
		   ;; if text to search is given
		   (if text
		       ;; if file is readable then send file to subprocess to search the text inside
		       (if (file-readable-p real-file-name)
			   (progn
			     ;; we do text search parallel sending files one by one to all subprocesses by turns
			     (let* ((proc (efar-subprocess-get-next-process))
				    (request (cons :search-in-file (list (cons :file real-file-name) (cons :text text) (cons :regexp? regexp?) (cons :ignore-case? ignore-case?)))))
			       (when real-file-name
				 (process-send-string proc (concat
							    (prin1-to-string
							     request)
							    "\n")))))
			 ;; otherwise skip it and report a file error
			 (process-send-string  efar-subprocess-server (concat (prin1-to-string (cons :file-error (cons real-file-name "file is not readable"))) "\n")))
		     
		     ;; otherwise report about found file
		     (process-send-string  efar-subprocess-server (concat (prin1-to-string (cons :found-file (list (cons :name real-file-name) (cons :lines '())))) "\n")))))))))

(defun efar-search-clearup ()
  "."
  ;;(setq efar-search-results nil)
  (setq efar-search-running-p nil)
  ;;(setq efar-search-last-command-params nil)
  ;; cancel update timer
  (when (and efar-search-update-results-timer
	     (timerp efar-search-update-results-timer))
    (cancel-timer efar-search-update-results-timer))
  (setq efar-search-update-results-timer nil))

(defun efar-search-process-file (args)
  "Search text in the file according to the parameters defined in ARGS."
  (let ((file (cdr (assoc :file args)))
	(text (cdr (assoc :text args)))
	(regexp? (or (cdr (assoc :regexp? args)) nil))
	(ignore-case? (or (cdr (assoc :ignore-case? args)) nil)))
    (when (and file text)
      
      (condition-case error
	  (let ((hits (let ((hits '())
			    (case-fold-search ignore-case?) ;; case insensitive search when ignore-case? is t
			    (search-func (if regexp? 're-search-forward 'search-forward))) ;; use regular expression for search when regexp? is t
			;; open file in temp buffer
			(with-temp-buffer
			  (insert-file-contents file)
			  (goto-char 0)
			  ;; do search the text
			  (while (funcall search-func text nil t)
			    ;; store line number and whole line where searched text occurs
			    (push (cons (line-number-at-pos)
					(replace-regexp-in-string "\n" "" (thing-at-point 'line t)))
				  hits)
			    (forward-line)))
			
			(reverse hits))))
	    ;; if text is found in the file send information to main process
	    (when hits
	      (process-send-string  efar-subprocess-server (concat (prin1-to-string (cons :found-file (list (cons :name file) (cons :lines hits)))) "\n"))))
	;; if any error occur skip file and report an error
	(error
	 (process-send-string efar-subprocess-server (concat (prin1-to-string (cons :file-error (cons file (error-message-string error)))) "\n")))))))

(defun efar-show-search-results (&optional side)
  "Show search results in panel SIDE."
  
  (let* ((side (or side (efar-get :current-panel)))
	 (errors (cdr (assoc :errors efar-search-last-command-params)))
	 (result-string nil)
	 (status-string nil))
    
    ;; if unexpected/unhandled error occurred during search we report failure
    (if (stringp errors)
	(progn
	  (setf result-string "Search results [failed]")
	  (setf status-string (concat "Search failed with erorr: " errors)))
      
      (setf result-string (concat "Search results"
				  (when efar-search-last-command-params
				    (concat " - " (int-to-string (length (efar-get :panels side :files)))
					    (if (cdr (assoc :end-time efar-search-last-command-params))
						" [finished]" " [in progress]" )
					    
					    (when errors
					      (concat " (" (int-to-string (length errors)) " skipped)"))))))
      
      
      
      (setf status-string (concat (cond (efar-search-running-p
					 "Search running for files ")
					((cdr (assoc :end-time efar-search-last-command-params))
					 (concat "Search finished in " (int-to-string (round (- (cdr (assoc :end-time efar-search-last-command-params)) (cdr (assoc :start-time efar-search-last-command-params))))) " second(s) for files "))
					(t
					 "No search has been executed yet"))
				  
				  (when (cdr (assoc :start-time efar-search-last-command-params))
				    (setq status-string (concat status-string
								"in " (cdr (assoc :dir efar-search-last-command-params))
								" matching mask(s) '" (string-join (cdr (assoc :wildcards efar-search-last-command-params)) ",") "'"
								(when (cdr (assoc :text efar-search-last-command-params))
								  (concat " and containing text '" (cdr (assoc :text efar-search-last-command-params)) "'"
									  " (" (if (cdr (assoc :ignore-case? efar-search-last-command-params)) "CI" "CS") ")"))))))))
    
    (efar-set result-string :panels side :dir)
    
    (efar-remove-notifier side)
    
    (efar-set-status status-string nil t)
    (efar-calculate-widths)
    (efar-write-enable (efar-redraw))))

(defun efar-do-show-search-results-in-buffer ()
  "Show detailed search results in other buffer."
  (interactive)
  (efar-when-can-execute
   (if efar-search-running-p
       
       (efar-set-status "Search is still running" nil t t)
     
     (efar-set-status "Generating report with search results...")
     
     (and (get-buffer efar-search-results-buffer-name) (kill-buffer efar-search-results-buffer-name))
     
     (let ((buffer (get-buffer-create efar-search-results-buffer-name))
	   (dir (cdr (assoc :dir efar-search-last-command-params)))
	   (wildcards (cdr (assoc :wildcards efar-search-last-command-params)))
	   (text (cdr (assoc :text efar-search-last-command-params)))
	   (ignore-case? (cdr (assoc :ignore-case? efar-search-last-command-params)))
	   (regexp? (cdr (assoc :regexp? efar-search-last-command-params)))
	   (errors (cdr (assoc :errors efar-search-last-command-params))))
       
       (with-current-buffer buffer
	 (read-only-mode 0)
	 (erase-buffer)
	 
	 ;; insert header with description of search parameters
	 (insert "Found " (int-to-string (length (efar-get :panels (efar-get :current-panel) :files)))
		 " files in " (int-to-string (round (- (cdr (assoc :end-time efar-search-last-command-params)) (cdr (assoc :start-time efar-search-last-command-params))))) " second(s).\n")
	 
	 ;; in case if some file were skipped uring search we add corresponding hint to the header
	 (when errors
	   (let ((p (point)))
	     (insert (int-to-string (length errors)) " file(s) skipped. See list at the bottom.")
	     (add-text-properties p (point)
				  '(face efar-non-existing-current-file-face))
	     (insert "\n")))
	 
	 (insert "Directory: " dir "\n"
		 "File name mask(s): " (string-join wildcards ",") "\n"
		 (or (when text
		       (concat "Text '" text "' found in "
			       (let ((hits 0))
				 (cl-loop for file in (efar-get :panels (efar-get :current-panel) :files) do
					  (setq hits (+ hits (length (nth 13 file)))))
				 (int-to-string hits)) " line(s)\n"
			       "Ignore case: " (if ignore-case? "yes" "no") "\n"
			       "Use regexp: " (if regexp? "yes" "no") "\n"))
		     "")
		 "\n")
	 
	 ;; output list of found files (and source lines when searching for text)
	 (let ((cnt 0))
	   (cl-loop for file in (efar-get :panels (efar-get :current-panel) :files) do
		    (cl-incf cnt)
		    ;; create a link to the file
		    (insert-button (concat (int-to-string cnt) ". " (car file))
				   :type 'efar-search-find-file-button
				   :file (car file))
		    (insert "\n")
		    
		    ;; create links to source lines
		    (cl-loop for line in (nth 13 file) do
			     
			     (let ((line-number (car line))
				   (line-text (cdr line)))
			       (insert-button (concat (int-to-string line-number) ":\t" line-text)
					      :type 'efar-search-find-line-button
					      :file (car file)
					      :line-number line-number
					      :text text
					      :ignore-case? ignore-case?
					      :regexp? regexp?))
			     (insert "\n"))
		    (insert "\n")))
	 
	 
	 ;; output skipped files
	 (when errors
	   (insert "\nFollowing files/directries are inaccessible and therefore were skipped:\n")
	   (cl-loop for file in errors do
		    (insert (car file) " (" (cdr file) ")")
		    (insert "\n")))
	 
	 ;; highlight searched text
	 (goto-char (point-min))
	 (when text
	   (if (cdr (assoc :regexp? efar-search-last-command-params))
	       (highlight-regexp text 'hi-yellow)
	     (highlight-phrase text 'hi-yellow)))
	 
	 (read-only-mode 1))
       
       (switch-to-buffer-other-window buffer)
       (efar-set-status "Ready")))))

(defun efar-search-find-file-button (button)
  "Open file from search results buffer and navigate to searched text.
BUTTON is a button clicked."
  (let ((file (button-get button :file))
	(line-number (button-get button :line-number))
	(text (button-get button :text))
	(ignore-case? (button-get button :ignore-case?))
	(regexp? (button-get button :regexp?)))
    
    ;; open file in other window
    (find-file-other-window file)
    (goto-char 0)
    
    ;; navigate to the line containing searched text
    ;; and activate isearch for the searched text
    (when line-number
      (forward-line (- line-number 1))
      (isearch-mode t regexp?)
      (if ignore-case?
	  (setq text (downcase text)))
      (isearch-process-search-string text
				     (mapconcat #'isearch-text-char-description text "")))))

  
(defun efar-search-open-from-history ()
  "Open selected search result."
  (if efar-search-running-p
      (efar-set-status (format "Wait until current search ends. Press %S to show current search results"  (symbol-value 'efar-show-search-results-key))
		       5 t t)
    
    (let* ((number (efar-current-file-number))
	   (result (nth number (reverse efar-search-history))))
      (setf efar-search-results (cdr result))
      (setf efar-search-last-command-params (car result)))
    (efar-change-panel-mode :search)))

;;--------------------------------------------------------------------------------
;; Directory comparator
;;--------------------------------------------------------------------------------

(defun efar-sort-files-by-name-dir-diff (a b)
  "Function to sort files A and B by name.
Directories always go before normal files.
Function string< is used for comparing file names.
Case is ignored."
  (cond
   ;; directories go first
   ((and (cadr a) (not (cadr b)))
    t)
   ((and (not (cadr a)) (cadr b))
    nil)
   ;; entries of same type (directory or usual files) sorted in lexicographic order
   (t (string<
       (downcase (nth 13 a))
       (downcase (nth 13 b))))))

(defun efar-dir-diff-equal (item &optional dont-check-children)
  "Check if files defined in ITEM have any difference.
Child items are not taken into account if DONT-CHECK-CHILDREN is not nil."
  (and (or dont-check-children
	   (not (member :children-changed item)))
       (not (member :size item))
       (not (member :hash item))
       (not (member :left item))
       (not (member :owner item))
       (not (member :group item))
       (not (member :modes item))
       (not (member :right item))))
       
(defun efar-dir-diff-build-file-list (dir)
  "Build and return file list in directory DIR."
  (let ((list (make-hash-table :test 'equal))
	(dir (file-name-as-directory dir)))
	
    (cl-labels
	((rec-func (d)
		   (cl-loop for entry in (cl-remove-if (lambda(e) (or (string= (car e) ".") (string= (car e) "..")))
						       (directory-files-and-attributes d nil nil t 'string))
			    do
			    
			    (let ((name (cl-subseq (expand-file-name (car entry) d) (length dir))))
			      (puthash name
				       (nconc (list entry
						    name
						    (expand-file-name (car entry) d)
						    (efar-get-parent-dir name)))
				       list))
			    
			    (when (equal (cadr entry) t)
			      (setf list (append (rec-func (expand-file-name (car entry) d))))))
		   list))
      
      (rec-func dir))
  
    list))

(defun efar-do-start-directory-comparison ()
  "Start comparison of directries selected in both panels."
  (interactive)
  (efar-when-can-execute
   ;; if directory comparison or search is running, ask user whether to stop them
   (when (or (and efar-search-running-p
		  (string= "Yes" (efar-completing-read "Search is running. Kill it?")))
	     (and efar-dir-diff-running-p
		  (string= "Yes" (efar-completing-read "Directory comparison is running. Kill it?"))))
     ;; restart search processes
     (efar-subprocess-run-processes)
     (setq efar-search-running-p nil)
     (setq efar-dir-diff-running-p nil))
   
   (unless (or efar-search-running-p
	       efar-dir-diff-running-p)

     
     (if (or (not (equal (efar-get :panels :left :mode) :files))
	     (not (equal (efar-get :panels :right :mode) :files)))
	 (error "Both panels should be in :files mode!")
       (when (equal "Yes" (efar-completing-read (concat "Compare '"
							(efar-get :panels :left :dir)
							"' and '"
							(efar-get :panels :right :dir)
							"'?")))
	 (let ((include-masks (split-string (read-string "Include files matching file masks: " "*") "[, ]+"))
	       (exclude-masks (split-string (read-string "Exclude files matching file masks: " "") "[, ]+")))
	   
	   (setq efar-dir-diff-last-command-params nil)
	   (setq efar-dir-diff-last-command-params (list (cons :left (efar-get :panels :left :dir))
							 (cons :right (efar-get :panels :right :dir))
							 (cons :include include-masks)
							 (cons :exclude exclude-masks)
							 (cons :start-time (time-to-seconds (current-time)))))
	   
	   (setq efar-dir-diff-results (make-hash-table :test 'equal))
	   (setq efar-dir-diff-running-p t)
	   (efar-set 0 :panels :left :current-pos)
	   (efar-change-panel-mode :dir-diff)
	   
	   ;; set up timer that will update result during search
	   (setq efar-dir-diff-update-results-timer
		 (run-at-time nil 2
			      (lambda()
				(when (equal :dir-diff (efar-get :panels :left :mode))
				  (efar-change-panel-mode :dir-diff)))))
	   
	   ;; send command to the manager to start the search with given parameters
	   (efar-subprocess-send-command efar-subprocess-manager
					 :start-dir-compare
					 efar-dir-diff-last-command-params)))))))
  
  (defun efar-dir-diff-clearup ()
  ""
  (setq efar-dir-diff-running-p nil)
  ;; cancel update timer
  (when (and efar-dir-diff-update-results-timer
	     (timerp efar-dir-diff-update-results-timer))
    (cancel-timer efar-dir-diff-update-results-timer))
  (setq efar-dir-diff-update-results-timer nil))


(defun efar-dir-diff-finished ()
  "Function is called when directory comparison is finished."
  (while (accept-process-output))
  ;; cancel update timer
  (when (timerp efar-dir-diff-update-results-timer)
    (cancel-timer efar-dir-diff-update-results-timer))
  (setq efar-dir-diff-update-results-timer nil)
  
  ;; fix end time
  (push (cons :end-time (time-to-seconds (current-time)))
	efar-dir-diff-last-command-params)
  
  (setq efar-dir-diff-running-p nil)
  
  (efar-change-panel-mode :dir-diff))

(defun efar-dir-diff-int-start-compare (params)
  "Do directory comparison.
Directories and comparison parameters are passed in PARAMS."
  (let* ((dir-left (cdr (assoc :left params)))
	 (dir-right (cdr (assoc :right params)))
	 (include-masks (mapcar (lambda(e)
				  (wildcard-to-regexp e))
				(cdr (assoc :include params))))
	 (exclude-masks (mapcar (lambda(e)
				  (wildcard-to-regexp e))
				(cdr (assoc :exclude params))))

	 (comp-params '(:size :hash :owner :group :modes))

	 (list1 (efar-dir-diff-build-file-list dir-left))
	 (list2 (efar-dir-diff-build-file-list dir-right))
	 
	 (keys1 (sort (hash-table-keys list1) (lambda(a b) (string< a b)))))
    
    (cl-loop for k in keys1
	     do
	     (let* ((exists-in (if (gethash k list2)
				   :both
				 :left))
		    (e (gethash k list1))
		    ;; ignore case when applying wildcard
		    (case-fold-search t)
		    
		    (included? (catch :included
				 (cl-loop for mask in include-masks do
					  (when (string-match-p mask k)
					    (throw :included t)))))
		    (excluded? (catch :excluded
				 (cl-loop for mask in exclude-masks do
					  (when (string-match-p mask k)
					    (throw :excluded t))))))

	       (when (and included?
			  (not excluded?))
	
		 (if (equal exists-in :both)
		     (let* ((other (gethash k list2))
			    (attrs (cdr (car (cl-subseq e -4 -3))))
			    (attrs-other (cdr (car (cl-subseq other -4 -3))))
			    (size-changed? nil))
		       
		       ;; compare type (dir/file/link)
		       (when (not (equal (file-attribute-type attrs)
					 (file-attribute-type attrs-other)))
			 (push :type e))
		       
		       ;; compare owner
		       (when (and (member :owner comp-params)
				  (not (equal (file-attribute-user-id attrs)
					      (file-attribute-user-id attrs-other))))
			 (push :owner e))
		       
		       ;; compare group
		       (when (and (member :group comp-params)
				  (not (equal (file-attribute-group-id attrs)
					      (file-attribute-group-id attrs-other))))
			 (push :group e))
		       
		       ;; compare permissions
		       (when (and (member :modes comp-params)
				  (not (equal (file-attribute-modes attrs)
					      (file-attribute-modes attrs-other))))
			 (push :modes e))
		       
		       ;; compare size
		       (when (and (member :size comp-params)
				  (not (car attrs))
				  (not (equal (file-attribute-size attrs)
					      (file-attribute-size attrs-other))))
			 (setf size-changed? t)
			 (push :size e))
		       
		       ;; compare checksum
		       (when (and (not size-changed?) ;; we compare checksums only if file size is the same
				  (member :hash comp-params)
				  (not (car attrs)) ;; don't compare checksums for directories
				  (not (car attrs-other)))
			 ;; we do checksum comparison in subprocesses
			 (let* ((proc (efar-subprocess-get-next-process))
				(request (cons :compare-checksums (list (cons :key k)
									(cons :file1 (car (last e 2)))
									(cons :file2 (car (last other 2)))))))
			   
			   (process-send-string proc (concat
						      (prin1-to-string
						       request)
						      "\n"))))))

		 (push exists-in e))
	       	     
	       (remhash k list2)
	       
	       (process-send-string  efar-subprocess-server (concat (prin1-to-string (cons :file-comp-result (list (cons :key k) (cons :result e)))) "\n"))))
    
    (let ((keys2 (sort (hash-table-keys list2) (lambda(a b) (string< a b)))))
      (cl-loop for k in keys2
	       do
	       (let ((e (gethash k list2))
		     (included? (catch :included
				  (cl-loop for mask in include-masks do
					   (when (string-match-p mask k)
					     (throw :included t)))))
		     (excluded? (catch :excluded
				  (cl-loop for mask in exclude-masks do
					   (when (string-match-p mask k)
					     (throw :excluded t))))))
		 		 
		 (when (and included?
			    (not excluded?))
		   (push :right e))
		 
		 (process-send-string  efar-subprocess-server (concat (prin1-to-string (cons :file-comp-result (list (cons :key k) (cons :result e)))) "\n")))))

    ;; once all files are processed, send command to subprocesses to finish work
    (cl-loop for proc in efar-subprocess-processes do
	     (efar-subprocess-send-command proc :finished '()))
    ;; inform main process that manager finished the search
    (process-send-string efar-subprocess-server (concat (prin1-to-string (cons :finished '())) "\n"))))

(defun efar-dir-diff-compare-checksums (args)
  "Compare checksums of two files defined in ARGS."
  (let* ((key (cdr (assoc :key args)))
	 (file1 (cdr (assoc :file1 args)))
	 (file2 (cdr (assoc :file2 args)))
	 (changed?  (not (equal (efar-get-file-checksum file1)
				(efar-get-file-checksum file2)))))
    (when changed?
      (process-send-string efar-subprocess-server (concat (prin1-to-string (cons :file-comp-result (list (cons :key key) (cons :checksum-differs t)))) "\n")))))

(defun efar-dir-diff-update-parents (key)
  "Update all parent directories as updated if item with KEY has differences."
  ;;if differences detected
  ;;mark parent directories as :children-changed
  (when (cl-intersection (append efar-dir-diff-actual-comp-params '(:left :right))
			 (gethash key efar-dir-diff-results))
    (let ((parent-key (efar-get-parent-dir key)))
      (catch :exit
	(while parent-key
	  (let ((parent (gethash parent-key efar-dir-diff-results)))
	    (if (member :children-changed parent)
		(throw :exit t)
	      (cl-pushnew :children-changed  parent))
	    (puthash parent-key parent efar-dir-diff-results))
	  (setf parent-key (efar-get-parent-dir parent-key)))))))

(defun efar-dir-diff-show-results ()
  "Show directory comparison results."
  (let* ((errors (cdr (assoc :errors efar-dir-diff-last-command-params)))
	 (result-string nil)
	 (status-string nil))
    
    ;; if unexpected/unhandled error occurred during search we report failure
    (if (stringp errors)
	(progn
	  (setf result-string "DC results [failed]")
	  (setf status-string (concat "Directory compare failed with erorr: " errors)))
      
      (setf result-string (concat "DC - " (or efar-dir-diff-current-dir "/")
				  (when efar-dir-diff-last-command-params
				    (concat " - "
					    (if (cdr (assoc :end-time efar-dir-diff-last-command-params))
						" [finished]" " [in progress]" )
					    
					    (when errors
					      (concat " (" (int-to-string (length errors)) " skipped)"))))))
      
      (setf status-string (concat (cond (efar-dir-diff-running-p
					 "Directory comparison running ")
					((cdr (assoc :end-time efar-dir-diff-last-command-params))
					 (concat "Directory comparison finished in "
						 (int-to-string (round (- (cdr (assoc :end-time efar-dir-diff-last-command-params)) (cdr (assoc :start-time efar-dir-diff-last-command-params)))))
						 " second(s)"))
					(t
					 "No directory comparison has been executed yet"))))
      
    (efar-set-status status-string nil t)
      
    (efar-set result-string :panels :left :dir)
    (efar-set result-string :panels :right :dir)
    
    (unless (equal (efar-get :mode) :both)
      (efar-change-mode))
    
    (efar-remove-notifier (efar-get :current-panel))
    (efar-calculate-widths)
    (efar-write-enable (efar-redraw)))))


(defun efar-get-file-checksum (file)
  "Calculate checksum for the FILE."
  (let ((coding-system-for-write efar-subprocess-coding))
    (with-temp-buffer
      (insert-file-contents-literally file)
      (secure-hash 'md5 (buffer-string)))))

(defun efar-show-dir-diff-toggle-changed-only ()
  "Toggle display of unchanged items."
  (setf efar-dir-diff-show-changed-only-p (not efar-dir-diff-show-changed-only-p))
  (efar-write-enable (efar-redraw 'reread-files)))

(defun efar-dir-diff-enter-directory (&optional go-to-parent?)
  "Enter directory under cursor.
Go to parent directory when GO-TO-PARENT? is not nil."
  (unless (and go-to-parent?
	       (null efar-dir-diff-current-dir))
    (let* ((entry (car (efar-selected-files (efar-get :current-panel) t t nil)))
	   (go-to-parent? (or (and go-to-parent?
				   efar-dir-diff-current-dir)
			      (equal ".." (car entry))))
	   (current-dir efar-dir-diff-current-dir))
      
      (efar-quit-fast-search)
      
      (when (or go-to-parent?
		(and entry
		     (cadr entry)))
	
	(if go-to-parent?
	    (setf efar-dir-diff-current-dir (efar-get-parent-dir efar-dir-diff-current-dir))
	  (setf efar-dir-diff-current-dir (nth 13 entry)))
	
	(efar-change-panel-mode :dir-diff :left)
	(efar-change-panel-mode :dir-diff :right)
	
	(if go-to-parent?
	    (progn
	      (efar-go-to-file (expand-file-name current-dir
						 (cdr (assoc :left efar-dir-diff-last-command-params)))
			       :left 0)
	      (efar-go-to-file (expand-file-name current-dir
						 (cdr (assoc :right efar-dir-diff-last-command-params)))
			       :right 0))
	  (progn (efar-go-to-file "" :left 0)
		 (efar-go-to-file "" :right 0)))
	(efar-write-enable (efar-redraw))))))

(defun efar-do-show-directory-comparison-results ()
  "Show directory comparison results."
  (interactive)
  (efar-when-can-execute
   (efar-change-panel-mode :dir-diff)))

(defun efar-do-directory-comparison-toggle-changed-only ()
  "Show only changed files in directory comparison results."
  (interactive)
  (efar-show-dir-diff-toggle-changed-only))

(defun efar-do-directory-comparison-toggle-size ()
  "Toggle displaying difference in file size in directory comparison results."
  (interactive)
  (efar-when-can-execute
   (efar-dir-diff-toggle-comparison-display-options :size)))

(defun efar-do-directory-comparison-toggle-checksum ()
  "Toggle displaying difference in file checksum in directory comparison results."
  (interactive)
  (efar-when-can-execute
   (efar-dir-diff-toggle-comparison-display-options :hash)))

(defun efar-do-directory-comparison-toggle-owner ()
  "Toggle displaying difference in file owner in directory comparison results."
  (interactive)
  (efar-when-can-execute
   (efar-dir-diff-toggle-comparison-display-options :owner)))

(defun efar-do-directory-comparison-toggle-group ()
  "Toggle displaying difference in file group in directory comparison results."
  (interactive)
  (efar-when-can-execute
   (efar-dir-diff-toggle-comparison-display-options :group)))

(defun efar-do-directory-comparison-toggle-modes ()
  "Toggle displaying difference in file modes in directory comparison results."
  (interactive)
  (efar-when-can-execute
   (efar-dir-diff-toggle-comparison-display-options :modes)))

(defun efar-dir-diff-toggle-comparison-display-options (par)
  "Toggle displaying differences of type PAR."
  (if (member par efar-dir-diff-actual-comp-params)
      (setf efar-dir-diff-actual-comp-params (delete par efar-dir-diff-actual-comp-params))
    (push par efar-dir-diff-actual-comp-params))
  
  (cl-loop for k in (hash-table-keys efar-dir-diff-results) do
	   (let ((e (gethash k efar-dir-diff-results)))
	     (setf e (delete :children-changed e))
	     (puthash k e efar-dir-diff-results)))
  (cl-loop for k in (hash-table-keys efar-dir-diff-results) do
	   (efar-dir-diff-update-parents k))
  (efar-write-enable (efar-redraw 'reread-files)))

(defun efar-do-show-directory-comparison-results-in-buffer ()
  "Show list of changed items together with comparison details."
  (interactive)
  (efar-when-can-execute
   (if efar-dir-diff-running-p
       
       (efar-set-status "Directory comparison is still running" nil t t)
     
     (efar-set-status "Generating report for directory comparison results...")
     
     (and (get-buffer efar-dir-diff-results-buffer-name) (kill-buffer efar-dir-diff-results-buffer-name))
     
     (let ((buffer (get-buffer-create efar-dir-diff-results-buffer-name))
	   (dir-left (cdr (assoc :left efar-dir-diff-last-command-params)))
	   (dir-right (cdr (assoc :right efar-dir-diff-last-command-params)))
	   (errors (cdr (assoc :errors efar-dir-diff-last-command-params)))
	   (differences (sort (cl-remove-if (lambda(e)
					      (efar-dir-diff-equal e t))
					    (hash-table-values efar-dir-diff-results))
			      (lambda(a b) (string< (car (last a 3)) (car (last b 3)))))))
       
       (with-current-buffer buffer
	 (read-only-mode 0)
	 (erase-buffer)
	 
	 ;; insert header with description of search parameters
	 (insert "Found " (int-to-string (length differences))
      		 " differences in " (int-to-string (round (- (cdr (assoc :end-time efar-dir-diff-last-command-params))
							     (cdr (assoc :start-time efar-dir-diff-last-command-params))))) " second(s).\n")
	 
	 ;; in case if some file were skipped uring search we add corresponding hint to the header
	 (when errors
	   (let ((p (point)))
	     (insert (int-to-string (length errors)) " file(s) skipped. See list at the bottom.")
	     (add-text-properties p (point)
				  '(face efar-non-existing-current-file-face))
	     (insert "\n")))

	 (insert "Directory 1: " dir-left "\n")
	 (insert "Directory 2: " dir-right "\n")
	 (insert "Compare files matching: "
		 (string-join (cdr (assoc :include efar-dir-diff-last-command-params)) " ") "\n")
	 (insert "Skip files matching: "
		 (string-join (cdr (assoc :exclude efar-dir-diff-last-command-params)) " ") "\n")
	 
	 (newline)

	 ;; output list of found files (and source lines when searching for text)
	 (let ((cnt 0))
	   (cl-loop for file in differences do
		    (cl-incf cnt)
		    ;; insert relative file name
		    (insert (int-to-string cnt) ". " (car (last file 3)))

		    (insert "\t")
		    
		    (if (or (member :left file)
			    (member :both file))
			(progn (insert " ")
			       (insert-button "file1"
					      :type 'efar-dir-diff-button
					      :file (expand-file-name (car (last file 3)) (cdr (assoc :left efar-dir-diff-last-command-params)))))
		      (insert "      "))

		    (if (or (member :right file)
			    (member :both file))
			(progn (insert " ")
			       (insert-button "file2"
					      :type 'efar-dir-diff-button
					      :file (expand-file-name (car (last file 3)) (cdr (assoc :right efar-dir-diff-last-command-params)))))
		      (insert "      "))
		    
 		    (if (member :both file)
			(progn
			  (insert " ")
			  (let* ((file-name1 (expand-file-name (car (last file 3)) (cdr (assoc :left efar-dir-diff-last-command-params))))
				 (file-name2 (expand-file-name (car (last file 3)) (cdr (assoc :right efar-dir-diff-last-command-params))))
				 (results (cl-remove-if (lambda(e) (or (equal e :left)
								       (equal e :right)
								       (equal e :both)))
							(cl-subseq file 0 -4)))
				 (result-shortcuts (mapconcat (lambda(e)
								(capitalize (substring (symbol-name e) 1 2)))
							      results
							      ",")))

			    (insert-button (format "[%s]" result-shortcuts)
					   :type 'efar-dir-diff-button
					   :ediff t
					   :file1 file-name1
					   :file2 file-name2)
			    
			    (newline)
			    
			    (when (member :size results)
			      (insert "Size: "
				      (int-to-string (file-attribute-size (file-attributes file-name1)))
				      " -> "
				      (int-to-string (file-attribute-size (file-attributes file-name2))))
			      (newline))
			    (when (member :modes results)
			      (insert "Modes: "
				      (file-attribute-modes (file-attributes file-name1))
				      " -> "
				      (file-attribute-modes (file-attributes file-name2)))
			      (newline))))

	      	      (newline))
		    (newline)))
	 (align-regexp (point-min) (point-max) "\\(\\s-*\\)\t")
	 
	 ;; output skipped files
	 (when errors
	   (insert "\nFollowing files/directries are inaccessible and therefore were skipped:\n")
	   (cl-loop for file in errors do
		    (insert (car file) " (" (cdr file) ")")
		    (insert "\n")))

	 (goto-char (point-min))
	 (read-only-mode 1))
       
       (switch-to-buffer-other-window buffer)
       (efar-set-status "Ready")))))

(define-button-type 'efar-dir-diff-button
  'follow-link t
  'action #'efar-dir-diff-button
  'face 'efar-search-file-link-face)

(defun efar-dir-diff-button (button)
  "Execute actions when BUTTON is clicked."
  (let ((file (button-get button :file))
	(ediff (button-get button :ediff))
	(file1 (button-get button :file1))
	(file2 (button-get button :file2)))
    
    ;; open file in other window
    (when file (find-file-other-window file))

    (when ediff
      (ediff file1 file2))))

;;--------------------------------------------------------------------------------
;; eFar major mode
;;--------------------------------------------------------------------------------

(defvar efar-mode-map
  (let ((keymap (make-sparse-keymap)))
    ;; define keys for interactive functions    
    (define-key keymap (kbd "<up>") 'efar-do-move-up)
    (define-key keymap (kbd "<down>") 'efar-do-move-down)
    (define-key keymap (kbd "<left>") 'efar-do-move-left)
    (define-key keymap (kbd "<prior>") 'efar-do-move-left)
    (define-key keymap (kbd "<right>") 'efar-do-move-right)
    (define-key keymap (kbd "<next>") 'efar-do-move-right)
    (define-key keymap (kbd "<home>") 'efar-do-move-home)
    (define-key keymap (kbd "<end>") 'efar-do-move-end)
    (define-key keymap (kbd "<C-left>") 'efar-do-move-home)
    (define-key keymap (kbd "<C-right>") 'efar-do-move-end)
    (define-key keymap (kbd "RET") 'efar-do-enter-directory)
    (define-key keymap (kbd "C-<up>") 'efar-do-enter-parent)
    (define-key keymap (kbd "C-e c d") 'efar-do-change-directory)
    (define-key keymap (kbd "TAB") 'efar-do-switch-to-other-panel)
    (define-key keymap (kbd "C-c TAB") 'efar-do-open-dir-other-panel)
    (define-key keymap (kbd "<f4>") 'efar-do-edit-file)
    (define-key keymap (kbd "<M-f4>") 'efar-do-open-file-in-external-app)
    (define-key keymap (kbd "<f3>") 'efar-do-read-file)
    (define-key keymap (kbd "<insert>") 'efar-do-mark-file)
    (define-key keymap (kbd "<C-insert>") 'efar-do-unmark-all)
    (define-key keymap (kbd "<C-M-insert>") 'efar-do-mark-all)
    (define-key keymap (kbd "C-e <f5><f5>") 'efar-do-copy)
    (define-key keymap (kbd "C-e <f6><f6>") 'efar-do-rename)
    (define-key keymap (kbd "C-e <f7><f7>") 'efar-do-make-dir)
    (define-key keymap (kbd "C-e <f8><f8>") 'efar-do-delete)
    (define-key keymap (kbd "<M-up>") 'efar-do-scroll-other-window-up)
    (define-key keymap (kbd "<M-down>") 'efar-do-scroll-other-window-down)
    (define-key keymap (kbd "S-C-<left>") 'efar-do-move-splitter-left)
    (define-key keymap (kbd "S-C-<right>") 'efar-do-move-splitter-right)
    (define-key keymap (kbd "S-C-<down>") 'efar-do-move-splitter-center)
    (define-key keymap (kbd "C-e f m") 'efar-do-set-file-modes)
    (define-key keymap (kbd "C-e f d") 'efar-do-show-disk-selector)
    (define-key keymap (kbd "C-e f s") 'efar-do-change-sorting)
    (define-key keymap (kbd "C-e f f") 'efar-do-filter-files)
    (define-key keymap (kbd "C-e v M") 'efar-do-change-mode)
    (define-key keymap (kbd "C-e v +") 'efar-do-increase-column-number)
    (define-key keymap (kbd "C-e v -") 'efar-do-decrease-column-number)
    (define-key keymap (kbd "C-e v m") 'efar-do-change-file-display-mode)
    (define-key keymap (kbd "C-e c p") 'efar-do-copy-file-path)
    (define-key keymap (kbd "C-e c e") 'efar-do-ediff-files)
    (define-key keymap (kbd "C-e c s") 'efar-do-file-stat)
    (define-key keymap (kbd "C-e c o") 'efar-do-open-shell)
    (define-key keymap (kbd "M-RET") 'efar-do-send-to-shell)
    (define-key keymap (kbd "C-e c b") 'efar-do-show-bookmarks)
    (define-key keymap (kbd "C-e c B") 'efar-do-add-bookmark)
    (define-key keymap (kbd "C-e c h") 'efar-do-show-directory-history)
    (define-key keymap (kbd "<C-M-up>") 'efar-do-directory-history-previous)
    (define-key keymap (kbd "<C-M-down>") 'efar-do-directory-history-next)
    (define-key keymap (kbd "C-e c f") 'efar-do-show-file-history)
    (define-key keymap (kbd "C-e c n") 'efar-do-run-batch-rename)
    (define-key keymap (kbd "C-e c r") 'efar-do-run-batch-replace)
    (define-key keymap (kbd "C-e <M-f7>") 'efar-do-start-search)
    (define-key keymap (kbd "C-e <S-f7>") 'efar-do-show-search-results)
    (define-key keymap (kbd "C-e <C-f7>") 'efar-do-show-search-history)
    (define-key keymap (kbd "C-e <C-M-f7>") 'efar-do-show-search-results-in-buffer)
    (define-key keymap (kbd "C-e <M-f6>") 'efar-do-start-directory-comparison)
    (define-key keymap (kbd "C-e <S-f6>") 'efar-do-show-directory-comparison-results)
    (define-key keymap (kbd "C-e <C-M-f6>") 'efar-do-show-directory-comparison-results-in-buffer)
    (define-key keymap (kbd "C-e <f6> a") 'efar-do-directory-comparison-toggle-changed-only)
    (define-key keymap (kbd "C-e <f6> s") 'efar-do-directory-comparison-toggle-size)
    (define-key keymap (kbd "C-e <f6> h") 'efar-do-directory-comparison-toggle-checksum)
    (define-key keymap (kbd "C-e <f6> o") 'efar-do-directory-comparison-toggle-owner)
    (define-key keymap (kbd "C-e <f6> g") 'efar-do-directory-comparison-toggle-group)
    (define-key keymap (kbd "C-e <f6> m") 'efar-do-directory-comparison-toggle-modes)
    (define-key keymap (kbd "C-e c m") 'efar-do-show-mode-selector)
    (define-key keymap (kbd "C-e ?") 'efar-do-show-help)
    (define-key keymap (kbd "C-t") 'efar-do-change-theme)
    (define-key keymap (kbd "C-g") 'efar-do-abort)
    (define-key keymap (kbd "C-e <f12> <f12>") 'efar-do-reinit)
    (define-key keymap (kbd "C-n") 'efar-do-suggest-hint)

    ;; define keys for live filtering 
    (cl-loop for char in
	     (list ?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k ?l ?m ?n ?o ?p ?q ?r ?s ?t ?u ?v ?w ?x ?y ?z
		   ?A ?B ?C ?D ?E ?F ?G ?H ?I ?J ?K ?L ?M ?N ?O ?P ?Q ?R ?S ?T ?U ?V ?W ?X ?Y ?Z
		   ?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9 ?0
		   ?\( ?\) ?. ?? ?*
		   ?- ?_
		   32) do
	       (define-key keymap (kbd (char-to-string char)) `(lambda() (interactive) (efar-fast-search ,char))))
    (define-key keymap (kbd "DEL") (lambda() (interactive) (efar-fast-search :back)))
    (define-key keymap (kbd "C-s") (lambda() (interactive) (efar-fast-search :next)))
    (define-key keymap (kbd "C-r") (lambda() (interactive) (efar-fast-search :prev)))

    ;; define actions for mouse events
    (cl-loop for k in '("<double-mouse-1>"
			"<mouse-1>"
			"<wheel-down>"
			"<wheel-up>"
			"<C-mouse-1>"
			"<C-down-mouse-1>"
			"<S-mouse-1>"
			"<S-down-mouse-1>"
			"<drag-mouse-1>"
			"<down-mouse-1>")
	     do
	     (define-key keymap (kbd k) (lambda (event)
					  (interactive "e")
					  (efar-process-mouse-event event))))
    keymap)
  "Keymap for eFar buffer.")

(defvar efar-valid-keys-for-modes
  (list (cons 'efar-do-enter-parent  (list :files :dir-diff))
	(cons 'efar-do-send-to-shell (list :files))
	(cons 'efar-do-mark-file (list :files))
	(cons 'efar-do-mark-all (list :files))
	(cons 'efar-do-unmark-all (list :files))
	(cons 'efar-do-edit-file (list :files :search :bookmark :dir-hist :file-hist :disks :dir-diff))
	(cons 'efar-do-open-file-in-external-app (list :files :search :bookmark :dir-hist :file-hist :disks :dir-diff))
	(cons 'efar-do-read-file (list :files :search :bookmark :dir-hist :file-hist :disks :dir-diff))
	(cons 'efar-do-copy (list :files))
	(cons 'efar-do-rename (list :files))
	(cons 'efar-do-make-dir (list :files))
	(cons 'efar-do-delete (list :files :bookmark))
	(cons 'efar-do-change-sorting (list :files :search))
	(cons 'efar-do-filter-files (list :files))
	(cons 'efar-do-ediff-files (list :files :dir-diff))
	(cons 'efar-do-run-batch-rename (list :files :search))
	(cons 'efar-do-run-batch-replace (list :files :search))
	(cons 'efar-do-show-search-results-in-buffer (list :search))
	(cons 'efar-do-show-directory-comparison-results-in-buffer (list :dir-diff))
	(cons 'efar-do-directory-comparison-toggle-changed-only (list :dir-diff))
	(cons 'efar-do-directory-comparison-toggle-size (list :dir-diff))
	(cons 'efar-do-directory-comparison-toggle-checksum (list :dir-diff))
	(cons 'efar-do-directory-comparison-toggle-owner (list :dir-diff))
	(cons 'efar-do-directory-comparison-toggle-group (list :dir-diff))
	(cons 'efar-do-directory-comparison-toggle-modes (list :dir-diff))))

(defvar efar-menu  "Keymap for the eFar buffer menu bar.")

(defun efar-customize ()
  "Open customization buffer for eFar."
  (interactive)
  (customize-group 'efar))

(easy-menu-define efar-menu efar-mode-map
  "Menu for eFar mode."
  `(,"eFar"
    [,"Describe keys" efar-do-show-help :active t :keys "C-c ?"]
    [,"Customize" efar-customize t]))

(define-derived-mode
  efar-mode fundamental-mode "eFar"
  "Major mode for the eFar buffer."
  :group 'efar
  
  (if (not (equal (buffer-name (current-buffer)) efar-buffer-name))
      (error "Mode is intended be used for eFar buffer only")
    
    (easy-menu-add efar-menu)
    ;; hooks
    (add-hook 'window-configuration-change-hook #'efar-window-conf-changed)
    (add-hook 'kill-buffer-hook #'efar-buffer-killed nil 'local)
    (add-hook 'kill-emacs-hook #'efar-emacs-killed)))

;;--------------------------------------------------------------------------------
;; eFar color themes
;;--------------------------------------------------------------------------------

(defvar efar-themes (list (cons :blue
				(list (cons :background-color "navy")
				      (cons :current-background-color "cadet blue")
				      (cons :border-color "white")
				      (cons :current-executable-color "green")
				      (cons :executable-color "green")
				      (cons :marked-color "gold")
				      (cons :marked-current-color "gold")
				      (cons :controls-color "orange")
				      (cons :current-header-background-color "bisque")
				      (cons :current-header-foreground-color "navy")
				      (cons :non-existing-color "red")
				      (cons :non-existing-current-color "red")
				      (cons :file-color "deep sky blue")
				      (cons :current-file-color "blue")
				      (cons :dir-color "white")
				      (cons :current-dir-color "white")))
			  (cons :black
				(list (cons :background-color "black")
				      (cons :current-background-color "grey")
				      (cons :border-color "white")
				      (cons :current-executable-color "dark green")
				      (cons :executable-color "green")
				      (cons :marked-color "gold")
				      (cons :marked-current-color "gold")
				      (cons :controls-color "orange")
				      (cons :current-header-background-color "bisque")
				      (cons :current-header-foreground-color "navy")
				      (cons :non-existing-color "red")
				      (cons :non-existing-current-color "red")
				      (cons :file-color "dodger blue")
				      (cons :current-file-color "blue")
				      (cons :dir-color "ivory")
				      (cons :current-dir-color "black")))
			  (cons :white
				(list (cons :background-color "seashell1")
				      (cons :current-background-color "light grey")
				      (cons :border-color "black")
				      (cons :current-executable-color "sea green")
				      (cons :executable-color "sea green")
				      (cons :marked-color "gold")
				      (cons :marked-current-color "gold")
				      (cons :controls-color "orange")
				      (cons :current-header-background-color "bisque")
				      (cons :current-header-foreground-color "navy")
				      (cons :non-existing-color "red")
				      (cons :non-existing-current-color "red")
				      (cons :file-color "blue")
				      (cons :current-file-color "blue")
				      (cons :dir-color "black")
				      (cons :current-dir-color "black")))
			  (cons :sand
				(list (cons :background-color "#fcf6bd")
				      (cons :current-background-color "LightGoldenrod2")
				      (cons :border-color "black")
				      (cons :current-executable-color "sea green")
				      (cons :executable-color "sea green")
				      (cons :marked-color "gold")
				      (cons :marked-current-color "gold")
				      (cons :controls-color "orange3")
				      (cons :current-header-background-color "LightGoldenrod3")
				      (cons :current-header-foreground-color "navy")
				      (cons :non-existing-color "red")
				      (cons :non-existing-current-color "red")
				      (cons :file-color "blue")
				      (cons :current-file-color "blue")
				      (cons :dir-color "black")
				      (cons :current-dir-color "black")))))

(defun efar-do-change-theme ()
  "Change color theme."
  (interactive)
  (efar-when-can-execute
   (let* ((theme-names (mapcar (lambda(e) (car e)) efar-themes))
	  (current-theme-name (or (efar-get :theme) (car (mapcar (lambda(e) (car e)) efar-themes))))
	  (next-theme-name (nth (+ 1 (or (cl-position current-theme-name theme-names) -1)) theme-names))
	  (theme (assoc (or next-theme-name (car theme-names)) efar-themes)))
     (efar-set-theme (car theme)))))
    
(defun efar-set-theme (&optional theme-name)
  "Set color theme to THEME-NAME."
  (let* ((theme-names (mapcar (lambda(e) (car e)) efar-themes))
	 (theme-name (or theme-name
			 (or (efar-get :theme)
			     (car (mapcar (lambda(e) (car e)) efar-themes)))))
	 (theme (or (assoc (or theme-name (car theme-names)) efar-themes)
		    (cdr (car efar-themes )))))

    ;; main faces
    (efar-set (car theme) :theme)
    (set-face-background 'efar-border-line-face (cdr (assoc :background-color (cdr theme))))
    (set-face-foreground 'efar-border-line-face (cdr (assoc :border-color (cdr theme))))
    (set-face-background 'efar-file-face (cdr (assoc :background-color (cdr theme))))
    (set-face-foreground 'efar-file-face (cdr (assoc :file-color (cdr theme))))
    (set-face-background 'efar-file-current-face (cdr (assoc :current-background-color (cdr theme))))
    (set-face-foreground 'efar-file-current-face (cdr (assoc :current-file-color (cdr theme))))
    (set-face-background 'efar-file-executable-face (cdr (assoc :background-color (cdr theme))))
    (set-face-foreground 'efar-file-executable-face (cdr (assoc :executable-color (cdr theme))))
    (set-face-background 'efar-file-current-executable-face (cdr (assoc :current-background-color (cdr theme))))
    (set-face-foreground 'efar-file-current-executable-face (cdr (assoc :current-executable-color (cdr theme))))
    (set-face-background 'efar-marked-face (cdr (assoc :background-color (cdr theme))))
    (set-face-foreground 'efar-marked-face (cdr (assoc :marked-color (cdr theme))))
    (set-face-background 'efar-marked-current-face (cdr (assoc :current-background-color (cdr theme))))
    (set-face-foreground 'efar-marked-current-face (cdr (assoc :marked-current-color (cdr theme))))
    (set-face-background 'efar-dir-face (cdr (assoc :background-color (cdr theme))))
    (set-face-foreground 'efar-dir-face (cdr (assoc :dir-color (cdr theme))))
    (set-face-background 'efar-dir-current-face (cdr (assoc :current-background-color (cdr theme))))
    (set-face-foreground 'efar-dir-current-face (cdr (assoc :current-dir-color (cdr theme))))
    (set-face-background 'efar-dir-name-face (cdr (assoc :background-color (cdr theme))))
    (set-face-foreground 'efar-dir-name-face (cdr (assoc :border-color (cdr theme))))
    (set-face-background 'efar-dir-name-current-face (cdr (assoc :current-header-background-color (cdr theme))))
    (set-face-foreground 'efar-dir-name-current-face (cdr (assoc :current-header-foreground-color (cdr theme))))
    (set-face-background 'efar-non-existing-file-face (cdr (assoc :background-color (cdr theme))))
    (set-face-foreground 'efar-non-existing-file-face (cdr (assoc :non-existing-color (cdr theme))))
    (set-face-background 'efar-non-existing-current-file-face (cdr (assoc :current-background-color (cdr theme))))
    (set-face-foreground 'efar-non-existing-current-file-face (cdr (assoc :non-existing-current-color (cdr theme))))
    (set-face-background 'efar-controls-face (cdr (assoc :background-color (cdr theme))))
    (set-face-foreground 'efar-controls-face (cdr (assoc :controls-color (cdr theme))))
    ;; directory comparison faces
    (set-face-background 'efar-dir-diff-equal-face (cdr (assoc :background-color (cdr theme ))))
    (set-face-foreground 'efar-dir-diff-equal-face (cdr (assoc :dir-color (cdr theme ))))
    (set-face-background 'efar-dir-diff-equal-current-face (cdr (assoc :current-background-color (cdr theme ))))
    (set-face-foreground 'efar-dir-diff-equal-current-face (cdr (assoc :current-dir-color (cdr theme ))))
    (set-face-background 'efar-dir-diff-removed-face (cdr (assoc :background-color (cdr theme ))))
    (set-face-foreground 'efar-dir-diff-removed-face (cdr (assoc :non-existing-color (cdr theme ))))
    (set-face-background 'efar-dir-diff-removed-current-face (cdr (assoc :current-background-color (cdr theme ))))
    (set-face-foreground 'efar-dir-diff-removed-current-face (cdr (assoc :non-existing-current-color (cdr theme ))))
    (set-face-background 'efar-dir-diff-new-face (cdr (assoc :background-color (cdr theme ))))
    (set-face-foreground 'efar-dir-diff-new-face (cdr (assoc :executable-color (cdr theme ))))
    (set-face-background 'efar-dir-diff-new-current-face (cdr (assoc :current-background-color (cdr theme ))))
    (set-face-foreground 'efar-dir-diff-new-current-face (cdr (assoc :current-executable-color (cdr theme ))))
    (set-face-background 'efar-dir-diff-changed-face (cdr (assoc :background-color (cdr theme ))))
    (set-face-foreground 'efar-dir-diff-changed-face (cdr (assoc :file-color (cdr theme ))))
    (set-face-background 'efar-dir-diff-changed-current-face (cdr (assoc :current-background-color (cdr theme ))))
    (set-face-foreground 'efar-dir-diff-changed-current-face (cdr (assoc :current-file-color (cdr theme ))))))

;; FACES
(defface efar-border-line-face
  '((t :foreground "white"
       :background "navy"
       :underline nil))
  "Border line face")

(defface efar-file-face
  '((t :foreground "deep sky blue"
       :background "navy"
       :underline nil))
  "File item style (default)")

(defface efar-file-executable-face
  '((t :foreground "green"
       :background "navy"
       :underline nil))
  "File item style (executable file)")

(defface efar-file-current-executable-face
  '((t :foreground "green"
       :background "cadet blue"
       :underline nil))
  "Current file item style (executable file)")

(defface efar-marked-current-face
  '((t :foreground "gold"
       :background "cadet blue"
       :underline nil))
  "Current marked item style")

(defface efar-dir-face
  '((t :foreground "white"
       :background "navy"
       :underline nil))
  "Directory item style")

(defface efar-file-current-face
  '((t :foreground "black"
       :background "cadet blue"
       :underline nil))
  "Current file item style")

(defface efar-dir-current-face
  '((t :foreground "black"
       :background "cadet blue"
       :underline nil))
  "Current directory item style")

(defface efar-marked-face
  '((t :foreground "gold"
       :background "navy"
       :underline nil))
  "Marked item style")

(defface efar-marked-current-face
  '((t :foreground "gold"
       :background "cadet blue"
       :underline nil))
  "Current marked item style")

(defface efar-dir-name-face
  '((t :foreground "white"
       :background "navy"
       :underline nil))
  "Directory name header style")

(defface efar-controls-face
  '((t :foreground "orange"
       :background "navy"
       :underline nil))
  "Header style")

(defface efar-dir-name-current-face
  '((t :foreground "navy"
       :background "bisque"
       :underline nil))
  "Current directory name header style")

(defface efar-non-existing-file-face
  '((t :foreground "red"
       :background "navy"
       :underline nil))
  "Style for non-existing files (in bookmarks and directory history")

(defface efar-non-existing-current-file-face
  '((t :foreground "red"
       :background "bisque"
       :underline nil))
  "Style for non-existing current files (in bookmarks and directory history")

;; faces for directory comparator
(defface efar-dir-diff-equal-face
  '((t :foreground "white"
       :background "navy"
       :underline nil))
  ""
  :group 'efar-faces)

(defface efar-dir-diff-equal-current-face
  '((t :foreground "black"
       :background "cadet blue"
       :underline nil))
  ""
  :group 'efar-faces)

(defface efar-dir-diff-removed-face
  '((t :foreground "red"
       :background "navy"
       :underline nil))
  ""
  :group 'efar-faces)

(defface efar-dir-diff-removed-current-face
  '((t :foreground "red"
       :background "cadet blue"
       :underline nil))
  ""
  :group 'efar-faces)

(defface efar-dir-diff-new-face
  '((t :foreground "green"
       :background "navy"
       :underline nil))
  ""
  :group 'efar-faces)

(defface efar-dir-diff-new-current-face
  '((t :foreground "dark green"
       :background "cadet blue"
       :underline nil))
  ""
  :group 'efar-faces)

(defface efar-dir-diff-changed-face
  '((t :foreground "deep sky blue"
       :background "navy"
       :underline nil))
  ""
  :group 'efar-faces)

(defface efar-dir-diff-changed-current-face
  '((t :foreground "dark blue"
       :background "cadet blue"
       :underline nil))
  ""
  :group 'efar-faces)

(provide 'efar)

;;; efar.el ends here
