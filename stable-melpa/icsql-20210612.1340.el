;;; icsql.el --- Interactive iSQL iteraface to ciSQL  -*- lexical-binding: t; -*-

;; Copyright (C) 2018 - 2021 Paul Landes

;; Version: 0.4
;; Package-Version: 20210612.1340
;; Package-Commit: 4521e9d2debef7687bfd26a664479f0c46688a36
;; Author: Paul Landes
;; Maintainer: Paul Landes
;; Keywords: isql sql rdbms data
;; URL: https://github.com/plandes/icsql
;; Package-Requires: ((emacs "26") (choice-program "0.13") (buffer-manage "0.12"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Interface to ciSQL for interacting with relational database managements
;; systems (RDMBs).

;;; Code:

(require 'eieio)
(require 'sql)
(require 'dash)
(require 'json)
(require 'choice-program-complete)
(require 'buffer-manage)

(defgroup icsql nil
  "Running a Java/Clojure SQL command line interpreter in Java."
  :group 'SQL)

(defcustom icsql-connections nil
  "*The method of connecting.

Each entry has the following fields:
  * Name: the human readable name (i.e. `payroll-db').

  * Product: the JDBC driver name (i.e. `mysql', `sqlite').  Available drivers
    are given by the `listdrv' in `cisql'.

  * Host: the host with which to connect (i.e. `db1.example.com').

  * Port: the port with which to connect (i.e. `3306')

  * Database: the name of the database (file name if SQLite) (i.e. `payroll').

  * User: the user name with which to connect.

  * Password: the user password.

  * Configuration: key/values given as the `--config' parameter to `cisql'.

If the field does not apply, leave it empty, which are not given to the `cisql'
inferior program."
  :type '(repeat
	  (list (string :tag "Name")
		(symbol :tag "Product")
		(string :tag "Host")
		(string :tag "Port")
		(string :tag "Database")
		(string :tag "User")
		(string :tag "Password")
		(repeat :tag "Configuration"
			(cons :tag "Variable Settings" string string ))))
  :group 'icsql)

(defconst icsql-fields
  '(name
    product
    host
    port
    database
    user
    password
    configuration)
  "Fields (keys) in `icsql-connections'.
See `icsql-connections' for more information).")

(defcustom icsql-connections-supplemental nil
  "A file of additional connections in addition to `icsql-connections'.
When the file exists at the time of prompting the user for input, it is read
and new connections.  The file must contain an array of dict entries, each of
which are the same key/values as `icsql-connections'.

Providing a means of using a separate file is useful when you want to store
secure logins with passwords on an encrpyted drive.  This is the reason the
file is accessed for each new `icsql' connection."
  :type '(choice :tag "Additional connections"
		 (const :tag "None" nil)
		 (file :tag "File"))
  :group 'icsql)

(defconst icsql-none-connection "none"
  "The string used when prompting for no predefined connection.")

(defcustom icsql-separator-char ";"
  "*The deliminator for SQL statements."
  :type 'string
  :group 'icsql)

(defcustom icsql-results-gui nil
  "*Whether or not a GUI frame for the displaying results."
  :type '(choice :tag "Use GUI for new sessions"
		 (const :tag "Don't set" nil)
		 (const :tag "Use GUI" "true")
		 (const :tag "Don't use GUI" "false"))
  :group 'icsql)

(defcustom icsql-java-home nil
  "*The Java Home directory."
  :type '(choice :tag "Java Home directory"
		 (const :tag "Auto generated" nil)
		 (directory :tag "Directory"))
  :group 'icsql)

(defcustom icsql-path
  (expand-file-name "icsql" user-emacs-directory)
  "*The location of the cisql directory where the jars are stored.

See `icsql-download-jar'."
  :type 'directory
  :group 'icsql)

(defcustom icsql-sql-cisql-version "0.0.22"
  "*The version of the cisql uberjar to use."
  :type 'string
  :group 'icsql)

(defvar icsql-read-connection-history nil
  "History for which connection to start ciSQL.")

(defvar icsql-last-read nil
  "Used for completing read on user input for the connection.")

(defvar icsql-login-params nil
  "Parameters for icSQL login.")

(defvar icsql-repopulated-list nil
  "List of products that have been populated.
This is updated by `icsql-repopulate-sql-product-alist'.")

(defvar icsql-send-input-history nil
  "History variable for `icsql-send-input.")

(defun icsql-jar-release-url ()
  "Return the URL to download the ciSQL uber jar."
  (format "https://github.com/plandes/cisql/releases/download/v%s/cisql.jar"
	  icsql-sql-cisql-version))

(defun icsql-jar-path ()
  "Return the jar file name.

This also downloads the ciSQL jar if not found and creates any containing
directories when storing the file."
  (let* ((jar-fname (->> (format "%s/cisql-%s.jar"
				 icsql-path icsql-sql-cisql-version)
			 expand-file-name))
	 (jar-dir (file-name-directory jar-fname)))
    (unless (file-exists-p icsql-path)
      (make-directory jar-dir t))
    (unless (file-exists-p jar-fname)
      (let* ((url (icsql-jar-release-url))
	     (dl-buf-name "*icSQL Download*")
	     ;; url-retrieve (and all derivatives) don't handle redirects
	     ;; and github stores releases on AWS
	     (wget-bin (executable-find "wget"))
	     (curl-bin (executable-find "curl"))
	     (cmd (cond (wget-bin "wget --no-check-certificate -O %s %s")
			(curl-bin "curl -k -L -o %s %s"))))
	(with-current-buffer (set-buffer (get-buffer-create dl-buf-name))
	  (save-excursion
	    (read-only-mode 0)
	    (erase-buffer)
	    (insert (->> (-map #'shell-quote-argument `(,jar-fname ,url))
			 (apply #'format cmd)
			 (shell-command-to-string)))
	    (if (file-exists-p jar-fname)
		(insert "\nSuccessfully downloaded jar file\n")
	      (-> (concat "Could not find a program to use for downloading.\n"
			  "You must manually download\n    %s\nto:\n    %s.\n"
			  "Attemping to download now (see Download folder).\n")
		  (format  url jar-fname)
		  insert)
	      (browse-url url))
	    (read-only-mode 1)
	    (pop-to-buffer (current-buffer)))))
      (message "Downloaded ciSQL jar to %s" jar-fname))
    jar-fname))

(defun icsql-jvm ()
  "Return the path of the JVM or nil if there isn't one."
  (let ((java-home (or icsql-java-home (getenv "JAVA_HOME")))
	jvm)
    (unless java-home
      (error "Can't determine Java home: customize `icsql-java-home'"))
    (let ((exec-path (list (expand-file-name "bin" java-home))))
      (setq jvm (executable-find "java")))
    jvm))

(defun icsql-conn-field (name conn)
  "Get field NAME for connection CONN."
  (let ((idx (cl-position name icsql-fields)))
    (cdr (nth idx conn))))

(defun icsql-connections-compile ()
  "Return all icsql connections."
  (if (and icsql-connections-supplemental
	   (file-exists-p icsql-connections-supplemental))
      (->> (json-read-file icsql-connections-supplemental)
	   (funcall (lambda (elt)
		      (if (vectorp elt)
			  (list (aref elt 0))
			(list elt))))
	   (-map (lambda (kvs)
		   (-map (lambda (kv)
			   (let ((pos (cl-position (car kv) icsql-fields)))
			     (cons pos (cdr kv))))
			 kvs)))
	   (-map (lambda (kvs)
		   (-map (lambda (i)
			   (let ((val (cdr (assq i kvs))))
			     (if (= 1 i)
				 (intern val)
			       val)))
			 (number-sequence 0 (1- (length icsql-fields))))))
	   (append icsql-connections))
        icsql-connections))

(defun icsql-connection (name)
  "Get connection by NAME."
  (->> (icsql-connections-compile)
       (-some #'(lambda (conn)
		  (let ((cname (nth (cl-position 'name icsql-fields) conn)))
		    (and (equal cname name) conn))))
       (-zip icsql-fields)))

(defun icsql-compose-command (conn leinp)
  "Compose the cisql command line to start interactively.
CONN is the connection settings.
LEINP if non-nil start using a lein run command."
  (cl-flet ((fl (param field)
		(let ((val (icsql-conn-field field conn)))
		  (if (and val (< 0 (length val))) (list param val)))))
    (let* ((config (->> (mapconcat
			 (lambda (elt)
			   (format "%s=%s" (car elt) (cdr elt)))
			 (append (if icsql-results-gui
				     `(("gui" . ,icsql-results-gui)))
				 (icsql-conn-field 'configuration conn))
			 ",")
			(format (if leinp "'%s'" "%s"))))
	   (prod-name (icsql-conn-field 'product conn))
	   (name (if prod-name
		     (->> prod-name symbol-name (list "--name"))))
	   (options (append name
			    (fl "--host" 'host)
			    (fl "--port" 'port)
			    (fl "--database" 'database)
			    (fl "--user" 'user)
			    (fl "--password" 'password)
			    (if (> (length config) 0)
				(list "--config" config)))))
      (-> (if leinp
	      (split-string (concat "lein with-profile +dev "
				    "run --repl 12345"))
	    (list (icsql-jvm)))
	  (append (list "-jar" (expand-file-name (icsql-jar-path))))
	  (append options)))))

(defun icsql-help-command-line ()
  "Provide the ciSQL command line help."
  (interactive)
  (let ((cmd (mapconcat 'identity
			(append (icsql-compose-command nil nil) '("--help"))
			" "))
	(buf (get-buffer-create "*ciSQL Command Line Help*")))
    (message "Creating command line help, this might take a minute...")
    (with-current-buffer buf
      (save-excursion
	(read-only-mode 0)
	(erase-buffer)
	(insert (shell-command-to-string cmd))
	(read-only-mode 1)
	(set-buffer-modified-p nil)))
    (display-buffer buf)
    (message "Command line help for version %s" icsql-sql-cisql-version)))


;;;###autoload
(defun icsql-command (name &optional leinp)
  "Create a command used to start the Clojure REPL for connection NAME.
If LEINP is non-nil create the command as a Leinnigen development
REPL session."
  (interactive (list (icsql-read-connection)
		     (not current-prefix-arg)))
  (let* ((conn (icsql-connection name))
	 (cmd (icsql-compose-command conn leinp)))
    (when (called-interactively-p 'interactive)
      (let ((cmdline (mapconcat #'identity cmd " ")))
	(kill-new cmdline)
	(message "Killed `%s'" cmdline)))
    cmd))

(defun icsql-connect-icsql (&rest _)
  "Start an icSQL session."
  (unless (file-exists-p (icsql-jar-path))
      (error "Jar library does not exist: %s" (icsql-jar-path)))
  (let ((cmd (icsql-command icsql-last-read)))
    (set-buffer (apply #'make-comint "SQL" (car cmd) nil (cdr cmd)))))

(defun icsql-repopulate-sql-product-alist (product)
  "Munge the `sql-product-alist' variable to include ciSQL as a product.
Model the ciSQL product after PRODUCT (ex: 'mysql)."
  (unless (memq product icsql-repopulated-list)
    (let ((product-def (copy-tree (cdr (assq product sql-product-alist)) t))
	  (prompt-regexp "^ \\([0-9]+\\) > "))
      (setq product-def
	    (plist-put product-def :sqli-login 'icsql-login-params))
      (setq product-def
	    (plist-put product-def :sqli-comint-func 'icsql-connect-icsql))
      (setq product-def
	    (plist-put product-def :prompt-regexp prompt-regexp))
      (setq product-def
	    (plist-put product-def :prompt-cont-regexp prompt-regexp))
      (setq product-def
	    (plist-put product-def :prompt-length 5))
      (setq product-def
	    (plist-put product-def :terminator icsql-separator-char))
      (setq product-def
	    (plist-put product-def :list-table "shtab"))
      (assq-delete-all 'icsql sql-product-alist)
      (setq sql-product-alist
	    (append sql-product-alist
		    `((icsql . ,product-def)))))
    (add-to-list 'icsql-repopulated-list product)))

(defun icsql-read-connection ()
  "Interactively read an SQL connection profile from the user."
  (let* ((default (or (car icsql-read-connection-history)
		      icsql-none-connection))
	 (prompt (choice-program-complete-default-prompt "DB Connection" default))
	 (cons (icsql-connections-compile))
	 (ui (choice-program-complete
	      prompt (cons icsql-none-connection
			   (mapcar 'car cons))
	      t t nil 'icsql-read-connection-history
	      default)))
    (setq icsql-last-read ui)))


(defclass icsql-entry (buffer-entry)
  ((conn-name :initarg :conn-name
	      :initform nil
	      :type (or null string)
	      :documentation "Name of the connection"))
  :documentation "\
An icSQL entry class that represents each SQL interactive buffer.")

(cl-defmethod buffer-entry-create-buffer ((this icsql-entry))
  "Create an SQL buffer for THIS isql entry."
  (with-slots (object-name conn-name) this
    (let* ((conn-none-p (equal conn-name icsql-none-connection))
	   (conn (if conn-none-p
		     "ansi"
		   (icsql-connection conn-name)))
	   (product (if conn-none-p
			'ansi
		      (icsql-conn-field 'product conn)))
	   (sql-buf-name "icsql-buf"))
      (if (null product)
	  (error "No product defined for %s" object-name)
	(icsql-repopulate-sql-product-alist product)
	;; the sql library seems to get confused when already in an SQL buffer
	;; when `sql-product-interactive' is called
	(with-temp-buffer
	  (sql-product-interactive 'icsql sql-buf-name)))
      (let ((buf (get-buffer "*SQL*")))
	(with-current-buffer buf
	  (setq sql-product 'icsql sql-buffer buf)
	  buf)))))

(cl-defmethod buffer-entry-set-sqli-buffer ((this icsql-entry))
  "Set the Emacs SQL library SQLi buffer to THIS icSQL entry."
  (let ((buf (buffer-entry-buffer this)))
    (setq sql-buffer buf)))



(defclass icsql-manager (buffer-manager)
  ((last-conn-name :initarg :last-conn-name
		   :initform nil
		   :type (or null string)
		   :documentation "Name of the connection")))

(cl-defmethod config-manager-entry-default-name ((this icsql-manager))
  "Return the default name for THIS entry."
  (ignore this)
  "icsql")

(cl-defmethod config-manager-new-entry ((this icsql-manager) &optional slots)
  "Create a new SQL buffer for THIS entry using SLOTS data."
  (with-slots (last-conn-name) this
    (apply #'icsql-entry
	   (append slots (list :conn-name last-conn-name)))))

(cl-defmethod config-manager-read-new-name ((this icsql-manager) &rest _)
  "Read a new SQL buffer name from the user for THIS manager."
  (let ((name (icsql-read-connection)))
    (oset this :last-conn-name name)
    (if (equal name icsql-none-connection)
	"icsql"
      (format "icsql-%s" name))))


(defcustom icsql-manager-singleton
  (icsql-manager :object-name "icsql")
  "The singleton icsql manager."
  :group 'icsql
  :type 'object)

;;;###autoload
(defun icsql-set-sqli-buffer (&optional entry)
  "Set a SQLi buffer to the to ciSQL ENTRY provided by the user interactively.
See `sql-set-sqli-buffer'."
  (interactive
   (list (let* ((this icsql-manager-singleton)
		(name (buffer-manager-read-name icsql-manager-singleton)))
	   (config-manager-entry this name))))
  (setq entry (or entry
		  (config-manager-entry icsql-manager-singleton 'first)))
  (when entry
    (buffer-entry-set-sqli-buffer entry)))

;;;###autoload
(defun icsql ()
  "Create and start a new icSQL entry."
  (interactive)
  (call-interactively 'icsql-new))

;;;###autoload
(defun icsql-send-line ()
  "Send the current line to the SQL process."
  (interactive)
  (let ((start (line-beginning-position))
	(end (line-end-position)))
    (sql-send-region start end)))

;;;###autoload
(defun icsql-send-input (sql)
  "Send SQL to the last visited icSQL buffer."
  (interactive
   (let ((inp (read-string "SQL (default last statement): " nil
			   'icsql-send-input-history
			   (car icsql-send-input-history))))
     (when (= (length inp) 0)
       (error "Invalid SQL"))
     (list inp)))
  (let ((entry (config-manager-entry icsql-manager-singleton 'first)))
    (buffer-entry-insert entry sql t t)))


;; creates interactive function `icsql-new' etc
(buffer-manager-create-interactive-functions
 icsql-manager-singleton 'icsql-manager-singleton)

(define-minor-mode icsql-mode
  "Toggle icSQL mode."
  :keymap '(("\C-x\C-e" . icsql-send-line)
	    ("\C-x\C-w" . icsql-send-inpu))
  :group 'icsql)

(add-hook 'sql-mode-hook 'icsql-mode)

(provide 'icsql)

;;; icsql.el ends here
