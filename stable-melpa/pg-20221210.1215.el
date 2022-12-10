;;; pg.el --- Emacs Lisp socket-level interface to the PostgreSQL RDBMS  -*- lexical-binding: t -*-

;; Copyright: (C) 1999-2002, 2022  Eric Marsden

;; Author: Eric Marsden <eric.marsden@risk-engineering.org>
;; Version: 0.20
;; Package-Version: 20221210.1215
;; Package-Commit: f91d546a35ed3479cdb656b17525285e11565892
;; Keywords: data comm database postgresql
;; URL: https://github.com/emarsden/pg-el
;; Package-Requires: ((emacs "26.1"))
;; SPDX-License-Identifier: GPL-2.0-or-later
;;
;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 2 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Overview
;; --------
;;
;; This module lets you access the PostgreSQL object-relational DBMS from
;; Emacs, using its socket-level frontend/backend protocol. The module is
;; capable of automatic type coercions from a range of SQL types to the
;; equivalent Emacs Lisp type. This is a low level API, and won't be
;; useful to end users.
;;
;; Authentication methods: SCRAM-SHA-256 (the default authentication
;; method since PostgreSQL version 14) and MD5 authentication are
;; implemented. Encrypted (TLS) connections are supported.


;; Entry points
;; ------------
;;
;; (with-pg-connection con (dbname user [password host port]) &body body)
;;     A macro which opens a connection to database DBNAME over a TCP socket,
;;     executes the BODY forms then disconnects. See function `pg-connect' for
;;     details of the connection arguments.
;;
;; (with-pg-connection-local con (path dbname user [password]) &body body)
;;     A macro which opens a connection to database DBNAME over a local Unix
;;     socket at PATH, executes the BODY forms then disconnects. See function
;;     `pg-connect-local' for details of the connection arguments.
;;
;; (with-pg-transaction con &body body)
;;     A macro which executes the BODY forms wrapped in an SQL transaction.
;;     CON is a connection to the database. If an error occurs during the
;;     execution of the forms, a ROLLBACK instruction is executed.
;;
;; (pg-connect dbname user [password host port tls]) -> connection
;;     Connect to the database DBNAME on HOST (defaults to localhost) at PORT
;;     (defaults to 5432) via TCP/IP and log in as USER. PASSWORD is used for
;;     authentication with the backend (defaults to the empty string). If TLS is
;;     non-NIL, attempt to upgrade the connection to TLS. Set the output date
;;     type to 'ISO', and initialize our type parser tables.
;;
;; (pg-connect-local path dbname user [password]) -> connection
;;     Connect to the database DBNAME over local Unix socket at PATH and log in
;;     as USER. PASSWORD is used for authentication with the backend (defaults
;;     to the empty string). Set the output date type to 'ISO', and initialize
;;     our type parser tables.
;;
;; (pg-exec connection &rest sql) -> pgresult
;;     Concatenate the SQL strings and send to the backend. Retrieve
;;     all the information returned by the database and return it in
;;     an opaque record PGRESULT.
;;
;; (pg-result pgresult what &rest args) -> info
;;     Extract information from the PGRESULT. The WHAT keyword can be
;;     one of
;;          * :connection
;;          * :status
;;          * :attributes
;;          * :tuples
;;          * :tuple tupleNumber
;;          * :oid
;;     `:connection' allows you to retrieve the database connection.
;;     `:status' is a string returned by the backend to indicate the
;;     status of the command; it is something like "SELECT" for a
;;     select command, "DELETE 1" if the deletion affected a single
;;     row, etc. `:attributes' is a list of tuples providing metadata:
;;     the first component of each tuple is the attribute's name as a
;;     string, the second an integer representing its PostgreSQL type,
;;     and the third an integer representing the size of that type.
;;     `:tuples' returns all the data retrieved from the database, as a
;;     list of lists, each list corresponding to one row of data
;;     returned by the backend. `:tuple num' can be used to extract a
;;     specific tuple (numbering starts at 0). `:oid' allows you to
;;     retrieve the OID returned by the backend if the command was an
;;     insertion; the OID is a unique identifier for that row in the
;;     database (this is PostgreSQL-specific, please refer to the
;;     documentation for more details).
;;
;; (pg-cancel connection) -> nil
;;     Ask the server to cancel the command being processed by the backend.
;;     The cancellation request concerns the command requested over
;;     database connection CONNECTION.
;;
;; (pg-disconnect connection) -> nil
;;     Close the database connection.
;;
;; (pg-for-each connection select-form callback)
;;     Calls CALLBACK on each tuple returned by SELECT-FORM. Declares
;;     a cursor for SELECT-FORM, then fetches tuples using repeated
;;     executions of FETCH 1, until no results are left. The cursor is
;;     then closed. The work is performed within a transaction. When
;;     you have a large amount of data to handle, this usage is more
;;     efficient than fetching all the tuples in one go.
;;
;;     If you wish to browse the results, each one in a separate
;;     buffer, you could have the callback insert each tuple into a
;;     buffer created with (generate-new-buffer "myprefix"), then use
;;     ibuffer's "/ n" to list/visit/delete all buffers whose names
;;     match myprefix.
;;
;; (pg-databases connection) -> list of strings
;;     Return a list of the databases available at this site (a
;;     database is a set of tables; in a fresh PostgreSQL
;;     installation there is a single database named "template1").
;;
;; (pg-tables connection) -> list of strings
;;     Return a list of the tables present in the database to which we
;;     are currently connected. Only include user tables: system
;;     tables are excluded.
;;
;; (pg-columns connection table) -> list of strings
;;     Return a list of the columns (or attributes) in TABLE, which
;;     must be a table in the database to which we are currently
;;     connected. We only include the column names; if you want more
;;     detailed information (attribute types, for example), it can be
;;     obtained from `pg-result' on a SELECT statement for that table.
;;
;; (pg-hstore-setup conn)
;;     Prepare for the use of HSTORE datatypes. This function must be called
;;     before using the HSTORE extension. It loads the extension if necessary,
;;     and sets up the parsing support for HSTORE datatypes.
;;
;; (pg-lo-create conn . args) -> oid
;;     Create a new large object (BLOB, or binary large object in
;;     other DBMSes parlance) in the database to which we are
;;     connected via CONN. Returns an OID (which is represented as an
;;     elisp integer) which will allow you to use the large object.
;;     Optional ARGS are a Unix-style mode string which determines the
;;     permissions of the newly created large object, one of "r" for
;;     read-only permission, "w" for write-only, "rw" for read+write.
;;     Default is "r".
;;
;;     Large-object functions MUST be used within a transaction (see
;;     the macro `with-pg-transaction').
;;
;; (pg-lo-open conn oid . args) -> fd
;;     Open a large object whose unique identifier is OID (an elisp
;;     integer) in the database to which we are connected via CONN.
;;     Optional ARGS is a Unix-style mode string as for pg-lo-create;
;;     which defaults to "r" read-only permissions. Returns a file
;;     descriptor (an elisp integer) which can be used in other
;;     large-object functions.
;;
;; (pg-lo-close conn fd)
;;     Close the file descriptor FD which was associated with a large
;;     object. Note that this does not delete the large object; use
;;     `pg-lo-unlink' for that.
;;
;; (pg-lo-read conn fd bytes) -> string
;;     Read BYTES from the file descriptor FD which is associated with
;;     a large object. Return an elisp string which should be BYTES
;;     characters long.
;;
;; (pg-lo-write connection fd buf)
;;     Write the bytes contained in the elisp string BUF to the
;;     large object associated with the file descriptor FD.
;;
;; (pg-lo-lseek conn fd offset whence)
;;     Do the equivalent of a lseek(2) on the file descriptor FD which
;;     is associated with a large object; ie reposition the read/write
;;     file offset for that large object to OFFSET (an elisp
;;     integer). WHENCE has the same significance as in lseek(); it
;;     should be one of SEEK_SET (set the offset to the absolute
;;     position), SEEK_CUR (set the offset relative to the current
;;     offset) or SEEK_END (set the offset relative to the end of the
;;     file). WHENCE should be an elisp integer whose values can be
;;     obtained from the header file <unistd.h> (probably 0, 1 and 2
;;     respectively).
;;
;; (pg-lo-tell conn oid) -> integer
;;     Do the equivalent of an ftell(3) on the file associated with
;;     the large object whose unique identifier is OID. Returns the
;;     current position of the file offset for the object's associated
;;     file descriptor, as an elisp integer.
;;
;; (pg-lo-unlink conn oid)
;;     Remove the large object whose unique identifier is OID from the
;;     system (in the current implementation of large objects in
;;     PostgreSQL, each large object is associated with an object in
;;     the filesystem).
;;
;; (pg-lo-import conn filename) -> oid
;;     Create a new large object and initialize it to the data
;;     contained in the file whose name is FILENAME. Returns an OID
;;     (as an elisp integer). Note that is operation is only syntactic
;;     sugar around the basic large-object operations listed above.
;;
;; (pg-lo-export conn oid filename)
;;     Create a new file named FILENAME and fill it with the contents
;;     of the large object whose unique identifier is OID. This
;;     operation is also syntactic sugar.
;;
;;
;; Variable `pg-parameter-change-functions' is a list of handlers to be called
;; when the backend informs us of a parameter change, for example a change to
;; the session time zone. Each handler is called with three arguments: the
;; connection to the backend, the parameter name and the parameter value.
;;
;; Variable `pg-handle-notice-functions' is a list of handlers to be called when
;; the backend sends us a `NOTICE' message. Each handler is called with one
;; argument, the notice, as a pgerror struct.
;;
;; Boolean variable `pg-disable-type-coercion' can be set to non-nil (before
;; initiating a connection) to disable the library's type coercion facility.
;; Default is t.
;;
;;
;; For more information about PostgreSQL see <https://www.PostgreSQL.org/>.
;;
;; Thanks to Eric Ludlam for discovering a bug in the date parsing routines, to
;; Hartmut Pilch and Yoshio Katayama for adding multibyte support, and to Doug
;; McNaught and Pavel Janik for bug fixes.


;;; INSTALL
;;
;; Place this file in a directory somewhere in the load-path, then
;; byte-compile it (do a `B' on it in Dired, for example). Place a
;; line such as `(require 'pg)' in your Emacs initialization file.


;;; TODO
;;
;; * Provide support for client-side certificates to authenticate network
;;   connections over TLS.
;;
;; * Implement the SASLPREP algorithm for usernames and passwords that contain
;;   unprintable characters (used for SCRAM-SHA-256 authentication).
;;
;; * Add a mechanism for parsing user-defined types. The user should
;;   be able to define a parse function and a type-name; we query
;;   pg_type to get the type's OID and add the information to
;;   pg-parsers.


;;; Code:

(require 'cl-lib)
(require 'hex-util)

(defvar pg-application-name "pg.el"
  "The application_name sent to the PostgreSQL backend.
This information appears in queries to the `pg_stat_activity' table
and (depending on server configuration) in the connection log.")


(defvar pg-disable-type-coercion nil
  "*Non-nil disables the type coercion mechanism.
The default is nil, which means that data recovered from the database
is coerced to the corresponding Emacs Lisp type before being returned;
for example numeric data is transformed to Emacs Lisp numbers, and
booleans to booleans.

The coercion mechanism requires an initialization query to the
database, in order to build a table mapping type names to OIDs. This
option is provided mainly in case you wish to avoid the overhead of
this initial query. The overhead is only incurred once per Emacs
session (not per connection to the backend).")

(defvar pg-parameter-change-functions (list 'pg-handle-parameter-client-encoding)
  "List of handlers called when the backend informs us of a parameter change.
Each handler is called with three arguments: the connection to
the backend, the parameter name and the parameter value.")

(defvar pg-handle-notice-functions (list 'pg-log-notice)
  "List of handlers called when the backend sends us a NOTICE message.
Each handler is called with one argument, the notice, as a pgerror
struct.")

(define-error 'pg-error "PostgreSQL error" 'error)
(define-error 'pg-protocol-error "PostgreSQL protocol error" 'pg-error)


(defconst pg-PG_PROTOCOL_MAJOR 3)
(defconst pg-PG_PROTOCOL_MINOR 0)

(defconst pg-AUTH_REQ_OK       0)
(defconst pg-AUTH_REQ_KRB4     1)
(defconst pg-AUTH_REQ_KRB5     2)
(defconst pg-AUTH_REQ_PASSWORD 3)   ; AuthenticationCleartextPassword
(defconst pg-AUTH_REQ_CRYPT    4)

(defconst pg-STARTUP_MSG            7)
(defconst pg-STARTUP_KRB4_MSG      10)
(defconst pg-STARTUP_KRB5_MSG      11)
(defconst pg-STARTUP_PASSWORD_MSG  14)

(defconst pg-MAX_MESSAGE_LEN    8192)   ; libpq-fe.h

(defconst pg-INV_ARCHIVE 65536)         ; fe-lobj.c
(defconst pg-INV_WRITE   131072)
(defconst pg-INV_READ    262144)
(defconst pg-LO_BUFIZE   1024)

;; alist of (oid . parser) pairs. This is built dynamically at
;; initialization of the connection with the database (once generated,
;; the information is shared between connections).
(defvar pg-parsers '())


(cl-defstruct pgcon
  process pid secret position (client-encoding 'utf-8) (binaryp nil) connect-info)

(cl-defstruct pgresult
  connection status attributes tuples portal)

(defsubst pg-flush (connection)
  (accept-process-output (pgcon-process connection) 1))

;; this is ugly because lambda lists don't do destructuring
(defmacro with-pg-connection (con connect-args &rest body)
  "Execute BODY forms in a scope with connection CON created by CONNECT-ARGS.
The database connection is bound to the variable CON. If the
connection is unsuccessful, the forms are not evaluated.
Otherwise, the BODY forms are executed, and upon termination,
normal or otherwise, the database connection is closed."
  `(let ((,con (pg-connect ,@connect-args)))
     (unwind-protect
         (progn ,@body)
       (when ,con (pg-disconnect ,con)))))

(defmacro with-pg-connection-local (con connect-args &rest body)
  "Execute BODY forms in a scope with local Unix connection CON created by CONNECT-ARGS.
The database connection is bound to the variable CON. If the
connection is unsuccessful, the forms are not evaluated.
Otherwise, the BODY forms are executed, and upon termination,
normal or otherwise, the database connection is closed."
  `(let ((,con (pg-connect-local ,@connect-args)))
     (unwind-protect
         (progn ,@body)
       (when ,con (pg-disconnect ,con)))))


(defmacro with-pg-transaction (con &rest body)
  "Execute BODY forms in a BEGIN..END block with pre-established connection CON.
If a PostgreSQL error occurs during execution of the forms, execute
a ROLLBACK command.
Large-object manipulations _must_ occur within a transaction, since
the large object descriptors are only valid within the context of a
transaction."
  (let ((exc-sym (gensym)))
    `(progn
       (pg-exec ,con "BEGIN")
       (condition-case ,exc-sym
           (prog1 (progn ,@body)
             (pg-exec ,con "COMMIT"))
         (error
          (message "PostgreSQL error %s" ,exc-sym)
          (pg-exec ,con "ROLLBACK"))))))

(defun pg-for-each (con select-form callback)
  "Create a cursor for SELECT-FORM and call CALLBACK for each result.
Uses the PostgreSQL database connection CON. SELECT-FORM must be an
SQL SELECT statement. The cursor is created using an SQL DECLARE
CURSOR command, then results are fetched successively until no results
are left. The cursor is then closed.

The work is performed within a transaction. The work can be
interrupted before all tuples have been handled by THROWing to a
tag called pg-finished."
  (let ((cursor (symbol-name (gensym "pgelcursor"))))
    (catch 'pg-finished
      (with-pg-transaction con
         (pg-exec con "DECLARE " cursor " CURSOR FOR " select-form)
         (unwind-protect
             (cl-loop for res = (pg-result (pg-exec con "FETCH 1 FROM " cursor) :tuples)
                   until (zerop (length res))
                   do (funcall callback res))
           (pg-exec con "CLOSE " cursor))))))

;; Run the startup interaction with the PostgreSQL database. Authenticate and read the connection
;; parameters. This function allows us to share code common to TCP and Unix socket connections to
;; the backend.
(cl-defun pg-do-startup (connection dbname user password)
  "Handle the startup sequence to authenticate with PostgreSQL over CONNECTION."
  ;; send the StartupMessage, as per https://www.postgresql.org/docs/current/protocol-message-formats.html
  (let ((packet-octets (+ 4 2 2
                          (1+ (length "user"))
                          (1+ (length user))
                          (1+ (length "database"))
                          (1+ (length dbname))
                          (1+ (length "application_name"))
                          (1+ (length pg-application-name))
                          1)))
    (pg-send-int connection packet-octets 4)
    (pg-send-int connection pg-PG_PROTOCOL_MAJOR 2)
    (pg-send-int connection pg-PG_PROTOCOL_MINOR 2)
    (pg-send-string connection "user")
    (pg-send-string connection user)
    (pg-send-string connection "database")
    (pg-send-string connection dbname)
    (pg-send-string connection "application_name")
    (pg-send-string connection pg-application-name)
    ;; A zero byte is required as a terminator after the last name/value pair.
    (pg-send-int connection 0 1)
    (pg-flush connection))
  (cl-loop for c = (pg-read-char connection) do
           (cond ((eq ?E c)
                  ;; an ErrorResponse message
                  (pg-handle-error-response connection "after StartupMessage"))

                 ;; NegotiateProtocolVersion
                 ((eq ?v c)
                  (let ((_msglen (pg-read-net-int connection 4))
                        (protocol-supported (pg-read-net-int connection 4))
                        (unrec-options (pg-read-net-int connection 4))
                        (unrec (list)))
                    ;; read the list of protocol options not supported by the server
                    (dotimes (_i unrec-options)
                      (push (pg-read-string connection 4096) unrec))
                    (let ((msg (format "Server only supports protocol minor version <= %s" protocol-supported)))
                      (signal 'pg-protocol-error (list msg)))))

                 ;; BackendKeyData
                 ((eq ?K c)
                  (let ((_msglen (pg-read-net-int connection 4)))
                    (setf (pgcon-pid connection) (pg-read-net-int connection 4))
                    (setf (pgcon-secret connection) (pg-read-net-int connection 4))))

                 ;; ReadyForQuery message
                 ((eq ?Z c)
                  (let ((_msglen (pg-read-net-int connection 4))
                        (_status (pg-read-char connection)))
                    ;; status is 'I' or 'T' or 'E'
                    (and (not pg-disable-type-coercion)
                         (null pg-parsers)
                         (pg-initialize-parsers connection))
                    (pg-exec connection "SET datestyle = 'ISO'")
                    (cl-return-from pg-do-startup connection)))

                 ;; an authentication request
                 ((eq ?R c)
                  (let ((_msglen (pg-read-net-int connection 4))
                        (areq (pg-read-net-int connection 4)))
                    (cond
                     ;; AuthenticationOK message
                     ((= areq pg-AUTH_REQ_OK)
                      ;; Continue processing server messages and wait for the ReadyForQuery
                      ;; message
                      nil)

                     ((= areq pg-AUTH_REQ_PASSWORD)
                      ;; send a PasswordMessage
                      (pg-send-char connection ?p)
                      (pg-send-int connection (+ 5 (length password)) 4)
                      (pg-send-string connection password)
                      (pg-flush connection))
                     ;; AuthenticationSASL request
                     ((= areq 10)
                      (pg-do-sasl-authentication connection user password))
                     ((= areq 5)
                      (pg-do-md5-authentication connection user password))
                     ((= areq pg-AUTH_REQ_CRYPT)
                      (signal 'pg-protocol-error '("Crypt authentication not supported")))
                     ((= areq pg-AUTH_REQ_KRB4)
                      (signal 'pg-protocol-error '("Kerberos4 authentication not supported")))
                     ((= areq pg-AUTH_REQ_KRB5)
                      (signal 'pg-protocol-error '("Kerberos5 authentication not supported")))
                     (t
                      (let ((msg (format "Can't do that type of authentication: %s" areq)))
                        (signal 'pg-protocol-error (list msg)))))))

                 ;; ParameterStatus
                 ((eq ?S c)
                  (let* ((msglen (pg-read-net-int connection 4))
                         (msg (pg-read-chars connection (- msglen 4)))
                         (items (split-string msg (string 0))))
                    ;; ParameterStatus items sent by the backend include application_name,
                    ;; DateStyle, in_hot_standby, integer_datetimes
                    (when (> (length (cl-first items)) 0)
                      (dolist (handler pg-parameter-change-functions)
                        (funcall handler connection (cl-first items) (cl-second items))))))

                 (t
                  (let ((msg (format "Problem connecting: expected an authentication response, got %s" c)))
                    (signal 'pg-protocol-error (list msg)))))))

(cl-defun pg-connect (dbname user
                             &optional
                             (password "")
                             (host "localhost")
                             (port 5432)
                             (tls nil))
  "Initiate a connection with the PostgreSQL backend over TCP.
Connect to the database DBNAME with the username USER, on PORT of
HOST, providing PASSWORD if necessary. Return a connection to the
database (as an opaque type). PORT defaults to 5432, HOST to
\"localhost\", and PASSWORD to an empty string. If TLS is non-NIL,
attempt to establish an encrypted connection to PostgreSQL."
  (let* ((buf (generate-new-buffer " *PostgreSQL*"))
         (process (open-network-stream "postgres" buf host port :coding nil))
         (connection (make-pgcon :process process :position 1)))
    (with-current-buffer buf
      (set-process-coding-system process 'binary 'binary)
      (set-buffer-multibyte nil))
    ;; Save connection info in the pgcon object, for possible later use by pg-cancel
    (setf (pgcon-connect-info connection) (list :tcp host port dbname user password))
    ;; TLS connections to PostgreSQL are based on a custom STARTTLS-like connection upgrade
    ;; handshake. The frontend establishes an unencrypted network connection to the backend over the
    ;; standard port (normally 5432). It then sends an SSLRequest message, indicating the desire to
    ;; establish an encrypted connection. The backend responds with ?S to indicate that it is able
    ;; to support an encrypted connection. The frontend then runs TLS negociation to upgrade the
    ;; connection to an encrypted one.
    (when tls
      (require 'gnutls)
      (require 'network-stream)
      (unless (gnutls-available-p)
        (signal 'pg-error '("Connecting over TLS requires GnuTLS support in Emacs")))
      ;; send the SSLRequest message
      (pg-send-int connection 8 4)
      (pg-send-int connection 80877103 4)
      (pg-flush connection)
      (unless (eql ?S (pg-read-char connection))
        (signal 'pg-protocol-error (list "Couldn't establish TLS connection to PostgreSQL")))
      (let ((cert (network-stream-certificate host port nil)))
        (condition-case err
            ;; now do STARTTLS-like connection upgrade
            (gnutls-negotiate :process process
                              :hostname host
                              :keylist (and cert (list cert)))
          (gnutls-error
           (let ((msg (format "TLS error connecting to PostgreSQL: %s" (error-message-string err))))
             (signal 'pg-protocol-error (list msg)))))))
    ;; the remainder of the startup sequence is common to TCP and Unix socket connections
    (pg-do-startup connection dbname user password)))

(cl-defun pg-connect-local (path dbname user &optional (password ""))
  "Initiate a connection with the PostgreSQL backend over local Unix socket PATH.
Connect to the database DBNAME with the username USER, providing
PASSWORD if necessary. Return a connection to the database (as an
opaque type). PASSWORD defaults to an empty string."
  (let* ((buf (generate-new-buffer " *PostgreSQL*"))
         (process (make-network-process :name "postgres" :buffer buf :family 'local :service path :coding nil))
         (connection (make-pgcon :process process :position 1)))
    ;; Save connection info in the pgcon object, for possible later use by pg-cancel
    (setf (pgcon-connect-info connection) (list :local path dbname user password))
    (with-current-buffer buf
      (set-process-coding-system process 'binary 'binary)
      (set-buffer-multibyte nil))
    (pg-do-startup connection dbname user password)))


;; Called from pg-parameter-change-functions when we receive a ParameterStatus
;; message of type name=value from the backend. If the status message concerns
;; the client encoding, update the value recorded in the connection.
(defun pg-handle-parameter-client-encoding (connection name value)
  (when (string= "client_encoding" name)
    (let ((ce (pg-normalize-encoding-name value)))
      (if ce
          (setf (pgcon-client-encoding connection) ce)
        (let ((msg (format "Don't know the Emacs equivalent for client encoding %s" value)))
          (signal 'pg-error (list msg)))))))

(cl-defun pg-exec (connection &rest args)
  "Execute the SQL command given by concatenating ARGS on database CONNECTION.
Return a result structure which can be decoded using `pg-result'."
  (let* ((sql (apply #'concat args))
         (tuples '())
         (attributes '())
         (result (make-pgresult :connection connection))
         (ce (pgcon-client-encoding connection))
         (encoded (if ce (encode-coding-string sql ce t) sql)))
    ;; (message "pg-exec: %s" sql)
    (when (> (length encoded) pg-MAX_MESSAGE_LEN)
      (let ((msg (format "SQL statement too long: %s" sql)))
        (signal 'pg-error (list msg))))
    (pg-send-char connection ?Q)
    (pg-send-int connection (+ 4 (length encoded) 1) 4)
    (pg-send-string connection encoded)
    (pg-flush connection)
    (cl-loop for c = (pg-read-char connection) do
       ;; (message "pg-exec message-type = %c" c)
       (cl-case c
            ;; NoData
            (?n
             (let ((_msglen (pg-read-net-int connection 4)))
               nil))

            ;; NotificationResponse
            (?A
             (let ((_msglen (pg-read-net-int connection 4))
                   ;; PID of the notifying backend
                   (_pid (pg-read-int connection 4))
                   (channel (pg-read-string connection pg-MAX_MESSAGE_LEN))
                   (payload (pg-read-string connection pg-MAX_MESSAGE_LEN)))
               ;; FIXME decode channel and payload?
               (message "Asynchronous notify %s:%s" channel payload)))

            ;; Bind -- should not receive this
            (?B
             (setf (pgcon-binaryp connection) t)
             (unless attributes
               (signal 'pg-protocol-error (list "Tuple received before metadata")))
             (push (pg-read-tuple connection attributes) tuples))

            ;; CommandComplete -- one SQL command has completed
            (?C
             (let* ((msglen (pg-read-net-int connection 4))
                    (msg (pg-read-chars connection (- msglen 5)))
                    (_null (pg-read-char connection)))
               (setf (pgresult-status result) msg)))
               ;; now wait for the ReadyForQuery message

            ;; DataRow
            (?D
             (setf (pgcon-binaryp connection) nil)
             (let ((_msglen (pg-read-net-int connection 4)))
               (push (pg-read-tuple connection attributes) tuples)))

            ;; ErrorResponse
            (?E
             (pg-handle-error-response connection))

            ;; EmptyQueryResponse -- response to an empty query string
            (?I
             (let ((_msglen (pg-read-net-int connection 4)))
               nil))

            ;; BackendKeyData
            (?K
             (let ((_msglen (pg-read-net-int connection 4)))
               (setf (pgcon-pid connection) (pg-read-net-int connection 4))
               (setf (pgcon-secret connection) (pg-read-net-int connection 4))))


            ;; NoticeResponse
            (?N
             ;; a Notice response has the same structure and fields as an ErrorResponse
             (let ((notice (pg-read-error-response connection)))
               (dolist (handler pg-handle-notice-functions)
                 (funcall handler notice))))

            ;; CursorResponse
            (?P
             (let ((portal (pg-read-string connection pg-MAX_MESSAGE_LEN)))
               (setf (pgresult-portal result) portal)))

            ;; ParameterStatus sent in response to a user update over the connection
            (?S
             (let* ((msglen (pg-read-net-int connection 4))
                    (msg (pg-read-chars connection (- msglen 4)))
                    (items (split-string msg (string 0))))
               ;; ParameterStatus items sent by the backend include application_name,
               ;; DateStyle, TimeZone, in_hot_standby, integer_datetimes
               (when (> (length (cl-first items)) 0)
                 (dolist (handler pg-parameter-change-functions)
                   (funcall handler connection (cl-first items) (cl-second items))))))

            ;; RowDescription
            (?T
             (when attributes
               (signal 'pg-protocol-error (list "Cannot handle multiple result group")))
             (setq attributes (pg-read-attributes connection)))

            ;; CopyFail
            (?f
             (let* ((msglen (pg-read-net-int connection 4))
                    (msg (pg-read-chars connection (- msglen 4))))
               (message "Got CopyFail message %s" msg)))

            ;; BindComplete
            (?2
             (let ((_msglen (pg-read-net-int connection 4)))
               nil))

            ;; CloseComplete
            (?3
             (let ((_msglen (pg-read-net-int connection 4)))
               nil))

            ;; ReadyForQuery
            (?Z
             (let ((_msglen (pg-read-net-int connection 4))
                   (_status (pg-read-char connection)))
               ;; status is 'I' or 'T' or 'E'
               ;; (message "Got ReadyForQuery with status %c" status)
               (setf (pgresult-tuples result) (nreverse tuples))
               (setf (pgresult-attributes result) attributes)
               (cl-return-from pg-exec result)))

            (t
             (let ((msg (format "Unknown response type from backend: %s" c)))
               (signal 'pg-protocol-error (list msg))))))))

(defun pg-result (result what &rest arg)
  "Extract WHAT component of RESULT.
RESULT should be a structure obtained from a call to `pg-exec',
and the keyword WHAT should be one of
   :connection -> return the connection object
   :status -> return the status string provided by the database
   :attributes -> return the metadata, as a list of lists
   :tuples -> return the data, as a list of lists
   :tuple n -> return the nth component of the data
   :oid -> return the OID (a unique identifier generated by PostgreSQL
           for each row resulting from an insertion)"
  (cond ((eq :connection what) (pgresult-connection result))
        ((eq :status what)     (pgresult-status result))
        ((eq :attributes what) (pgresult-attributes result))
        ((eq :tuples what)     (pgresult-tuples result))
        ((eq :tuple what)
         (let ((which (if (integerp (car arg)) (car arg)
                        (let ((msg (format "%s is not an integer" arg)))
                          (signal 'pg-error (list msg)))))
               (tuples (pgresult-tuples result)))
           (nth which tuples)))
        ((eq :oid what)
         (let ((status (pgresult-status result)))
           (if (string= "INSERT" (substring status 0 6))
               (string-to-number (substring status 7 (cl-position ? status :start 7)))
             (let ((msg (format "Only INSERT commands generate an oid: %s" status)))
               (signal 'pg-error (list msg))))))
        (t
         (let ((msg (format "Unknown result request %s" what)))
           (signal 'pg-error (list msg))))))

(defun pg-cancel (con)
  "Cancel the command currently being processed by the backend.
The cancellation request concerns the command requested over connection CON."
  ;; Send a CancelRequest message. We open a new connection to the server and
  ;; send the CancelRequest message, rather than the StartupMessage message that
  ;; would ordinarily be sent across a new connection. The server will process
  ;; this request and then close the connection.
  (let* ((ci (pgcon-connect-info con))
         (ccon (cl-case (car ci)
                 ;; :tcp host port dbname user password
                 (:tcp
                  (let* ((buf (generate-new-buffer " *PostgreSQL-cancellation*"))
                         (host (nth 1 ci))
                         (port (nth 2 ci))
                         (process (open-network-stream "postgres-cancel" buf host port :coding nil))
                         (connection (make-pgcon :process process :position 1)))
                    (with-current-buffer buf
                      (set-process-coding-system process 'binary 'binary)
                      (set-buffer-multibyte nil))
                    connection))
                 ;; :local path dbname user password
                 (:local
                  (let* ((buf (generate-new-buffer " *PostgreSQL-cancellation*"))
                         (path (nth 1 ci))
                         (process (make-network-process :name "postgres"
                                                        :buffer buf
                                                        :family 'local
                                                        :service path
                                                        :coding nil))
                         (connection (make-pgcon :process process :position 1)))
                    (with-current-buffer buf
                      (set-process-coding-system process 'binary 'binary)
                      (set-buffer-multibyte nil))
                    connection)))))
    (pg-send-int ccon 16 4)
    (pg-send-int ccon 80877102 4)
    (pg-send-int ccon (pgcon-pid con) 4)
    (pg-send-int ccon (pgcon-secret con) 4)
    (pg-disconnect ccon)))

(defun pg-disconnect (con)
  "Close the database connection CON.
This command should be used when you have finished with the database.
It will release memory used to buffer the data transfered between
PostgreSQL and Emacs. CON should no longer be used."
  ;; send a Terminate message
  (pg-send-char con ?X)
  (pg-send-int con 4 4)
  (pg-flush con)
  (delete-process (pgcon-process con))
  (kill-buffer (process-buffer (pgcon-process con))))


;; type coercion support ==============================================
;;
;; When returning data from a SELECT statement, PostgreSQL starts by
;; sending some metadata describing the attributes. This information
;; is read by `pg-read-attributes', and consists of each attribute's
;; name (as a string), its size (in bytes), and its type (as an oid
;; which identifies a row in the PostgreSQL system table pg_type). Each
;; row in pg_type includes the type's name (as a string).
;;
;; We are able to parse a certain number of the PostgreSQL types (for
;; example, numeric data is converted to a numeric Emacs Lisp type,
;; dates are converted to the Emacs date representation, booleans to
;; Emacs Lisp booleans). However, there isn't a fixed mapping from a
;; type to its OID which is guaranteed to be stable across database
;; installations, so we need to build a table mapping OIDs to parser
;; functions.
;;
;; This is done by the procedure `pg-initialize-parsers', which is run
;; the first time a connection is initiated with the database from
;; this invocation of Emacs, and which issues a SELECT statement to
;; extract the required information from pg_type. This initialization
;; imposes a slight overhead on the first request, which you can avoid
;; by setting `pg-disable-type-coercion' to non-nil if it bothers you.
;; ====================================================================

;; This is a var not a const to allow user-defined types (a PostgreSQL
;; feature not present in ANSI SQL). The user can add a (type-name .
;; type-parser) pair and call `pg-initialize-parsers', after which the
;; user-defined type should be returned parsed from `pg-result'.
(defvar pg-type-parsers
  `(("bool"         . ,'pg-bool-parser)
    ("bit"          . ,'pg-bit-parser)
    ("varbit"       . ,'pg-bit-parser)
    ("char"         . ,'pg-text-parser)
    ("char2"        . ,'pg-text-parser)
    ("char4"        . ,'pg-text-parser)
    ("bpchar"       . ,'pg-text-parser)
    ("name"         . ,'pg-text-parser)
    ("char8"        . ,'pg-text-parser)
    ("char16"       . ,'pg-text-parser)
    ("text"         . ,'pg-text-parser)
    ("varchar"      . ,'pg-text-parser)
    ("bytea"        . ,'pg-bytea-parser)
    ("json"         . ,'pg-json-parser)
    ("jsonb"        . ,'pg-json-parser)
    ;; "xml" TODO
    ;; Note however that the hstore type is generally not present in the pg_types table
    ;; upon startup, so we need to call `pg-hstore-setup' before using HSTORE datatypes.
    ("hstore"       . ,'pg-hstore-parser)
    ("count"        . ,'pg-number-parser)
    ("int2"         . ,'pg-number-parser)
    ("int4"         . ,'pg-number-parser)
    ("int8"         . ,'pg-number-parser)
    ("oid"          . ,'pg-number-parser)
    ("numeric"      . ,'pg-float-parser)
    ("float4"       . ,'pg-float-parser)
    ("float8"       . ,'pg-float-parser)
    ("_int2"        . ,'pg-intarray-parser)
    ("_int2vector"  . ,'pg-intarray-parser)
    ("_int4"        . ,'pg-intarray-parser)
    ("_int8"        . ,'pg-intarray-parser)
    ("_float4"      . ,'pg-floatarray-parser)
    ("_float8"      . ,'pg-floatarray-parser)
    ("_numeric"     . ,'pg-floatarray-parser)
    ("_bool"        . ,'pg-boolarray-parser)
    ("_char"        . ,'pg-chararray-parser)
    ("_bpchar"      . ,'pg-chararray-parser)
    ("_text"        . ,'pg-textarray-parser)
    ("int4range"    . ,'pg-numrange-parser)
    ("int8range"    . ,'pg-numrange-parser)
    ("numrange"     . ,'pg-numrange-parser)
    ("money"        . ,'pg-text-parser)
    ("date"         . ,'pg-date-parser)
    ("timestamp"    . ,'pg-isodate-parser)
    ("timestamptz"  . ,'pg-isodate-parser)
    ("datetime"     . ,'pg-isodate-parser)
    ("time"         . ,'pg-text-parser)     ; preparsed "15:32:45"
    ("reltime"      . ,'pg-text-parser)     ; don't know how to parse these
    ("timespan"     . ,'pg-text-parser)
    ("tinterval"    . ,'pg-text-parser)))

;; see `man pgbuiltin' for details on PostgreSQL builtin types. Also see
;; https://www.npgsql.org/dev/types.html for useful information on the wire format for various
;; types.
(defun pg-number-parser (str _encoding)
  (string-to-number str))

;; We need to handle +Inf, -Inf, NaN specially because the Emacs Lisp reader uses a specific format
;; for them.
(defun pg-float-parser (str _encoding)
  (cond ((string= str "Infinity")
         1.0e+INF)
        ((string= str "-Infinity")
         -1.0e+INF)
        ((string= str "NaN")
         0.0e+NaN)
        (t
         (string-to-number str))))

(defun pg-bit-parser (str _encoding)
  (let* ((len (length str))
         (bv (make-bool-vector len t)))
    (dotimes (i len)
      (setf (aref bv i) (eql ?1 (aref str i))))
    bv))

(defun pg-intarray-parser (str _encoding)
  (let ((len (length str)))
    (unless (and (eql (aref str 0) ?{)
                 (eql (aref str (1- len)) ?}))
      (signal 'pg-protocol-error (list "Unexpected format for int array")))
    (let ((segments (split-string (cl-subseq str 1 (- len 1)) ",")))
      (apply #'vector (mapcar #'string-to-number segments)))))

(defun pg-floatarray-parser (str _encoding)
  (let ((len (length str)))
    (unless (and (eql (aref str 0) ?{)
                 (eql (aref str (1- len)) ?}))
      (signal 'pg-protocol-error (list "Unexpected format for float array")))
    (let ((segments (split-string (cl-subseq str 1 (- len 1)) ",")))
      (apply #'vector (mapcar (lambda (x) (pg-float-parser x nil)) segments)))))

(defun pg-boolarray-parser (str _encoding)
  (let ((len (length str)))
    (unless (and (eql (aref str 0) ?{)
                 (eql (aref str (1- len)) ?}))
      (signal 'pg-protocol-error (list "Unexpected format for bool array")))
    (let ((segments (split-string (cl-subseq str 1 (1- len)) ",")))
      (apply #'vector (mapcar (lambda (x) (pg-bool-parser x nil)) segments)))))

(defun pg-chararray-parser (str encoding)
  (let ((len (length str)))
    (unless (and (eql (aref str 0) ?{)
                 (eql (aref str (1- len)) ?}))
      (signal 'pg-protocol-error (list "Unexpected format for char array")))
    (let ((segments (split-string (cl-subseq str 1 (1- len)) ",")))
      (apply #'vector (mapcar (lambda (x) (pg-text-parser x encoding)) segments)))))

(defun pg-textarray-parser (str encoding)
  (let ((len (length str)))
    (unless (and (eql (aref str 0) ?{)
                 (eql (aref str (1- len)) ?}))
      (signal 'pg-protocol-error (list "Unexpected format for text array")))
    (let ((segments (split-string (cl-subseq str 1 (1- len)) ",")))
      (apply #'vector (mapcar (lambda (x) (pg-text-parser x encoding)) segments)))))

;; Something like "[10.4,20)". TODO: handle multirange types (from PostgreSQL v14)
(defun pg-numrange-parser (str _encoding)
  (if (string= "empty" str)
      (list :range)
    (let* ((len (length str))
           (lower-type (aref str 0))
           (upper-type (aref str (1- len))))
      (unless (and (cl-find lower-type "[(")
                   (cl-find upper-type ")]"))
        (signal 'pg-protocol-error '("Unexpected format for numerical range")))
      (let* ((segments (split-string (cl-subseq str 1 (1- len)) ","))
             (lower-str (nth 0 segments))
             (upper-str (nth 1 segments))
             ;; if the number is empty, that's a NULL lower or upper bound
             (lower (if (zerop (length lower-str)) nil (string-to-number lower-str)))
             (upper (if (zerop (length upper-str)) nil (string-to-number upper-str))))
        (unless (eql 2 (length segments))
          (signal 'pg-protocol-error '("Unexpected number of elements in numerical range")))
        (list :range lower-type lower upper-type upper)))))

(defsubst pg-text-parser (str encoding)
  (if encoding
      (decode-coding-string str encoding)
    str))

;; BYTEA binary strings (sequence of octets), that use hex escapes. Note
;; PostgreSQL setting variable bytea_output which selects between hex escape
;; format (the default in recent version) and traditional escape format. We
;; assume that hex format is selected.
;;
;; https://www.postgresql.org/docs/current/datatype-binary.html
(defun pg-bytea-parser (str _encoding)
  (unless (and (eql 92 (aref str 0))   ; \ character
               (eql ?x (aref str 1)))
    (signal 'pg-protocol-error
            (list "Unexpected format for BYTEA binary string")))
  (decode-hex-string (substring str 2)))

;; We use either the native libjansson support compiled into Emacs, or fall back to the routines
;; from the JSON library. Note however that these do not parse JSON in exactly the same way (in
;; particular, NULL, false and the empty array are handled differently).
(defun pg-json-parser (str _encoding)
  (if (and (fboundp 'json-parse-string)
           (fboundp 'json-available-p)
           (json-available-p))
      ;; Use the JSON support natively compiled into Emacs
      (json-parse-string str)
    ;; Use the parsing routines from the json library
    (require 'json)
    (json-read-from-string str)))

;; We receive something like "\"a\"=>\"1\", \"b\"=>\"2\""
(defun pg-hstore-parser (str encoding)
  (cl-flet ((parse (v)
              (if (string= "NULL" v)
                  nil
                (unless (and (eql ?\" (aref v 0))
                             (eql ?\" (aref v (1- (length v)))))
                  (signal 'pg-protocol-error '("Unexpected format for HSTORE content")))
                (pg-text-parser (substring v 1 (1- (length v))) encoding))))
    (let ((hstore (make-hash-table :test #'equal)))
      (dolist (segment (split-string str "," t "\s+"))
        (let* ((kv (split-string segment "=>" t "\s+")))
          (puthash (parse (car kv)) (parse (cadr kv)) hstore)))
      hstore)))

(defun pg-bool-parser (str _encoding)
  (cond ((string= "t" str) t)
        ((string= "f" str) nil)
        (t (let ((msg (format "Badly formed boolean from backend: %s" str)))
             (signal 'pg-protocol-error (list msg))))))

;; format for ISO dates is "1999-10-24"
(defun pg-date-parser (str _encoding)
  (let ((year  (string-to-number (substring str 0 4)))
        (month (string-to-number (substring str 5 7)))
        (day   (string-to-number (substring str 8 10))))
    (encode-time 0 0 0 day month year)))

(defconst pg-ISODATE_REGEX
  (concat "\\([0-9]+\\)-\\([0-9][0-9]\\)-\\([0-9][0-9]\\) " ; Y-M-D
          "\\([0-9][0-9]\\):\\([0-9][0-9]\\):\\([.0-9]+\\)" ; H:M:S.S
          "\\([-+][0-9]+\\)?")) ; TZ

;;  format for abstime/timestamp etc with ISO output syntax is
;;;    "1999-01-02 14:32:53+01"
;; which we convert to the internal Emacs date/time representation
;; (there may be a fractional seconds quantity as well, which the regex
;; handles)
(defun pg-isodate-parser (str _encoding)
  (if (string-match pg-ISODATE_REGEX str)  ; is non-null
      (let ((year    (string-to-number (match-string 1 str)))
            (month   (string-to-number (match-string 2 str)))
            (day     (string-to-number (match-string 3 str)))
            (hours   (string-to-number (match-string 4 str)))
            (minutes (string-to-number (match-string 5 str)))
            (seconds (round (string-to-number (match-string 6 str))))
            (tz      (string-to-number (or (match-string 7 str) "0"))))
        (encode-time seconds minutes hours day month year (* 3600 tz)))
    (let ((msg (format "Badly formed ISO timestamp from backend: %s" str)))
      (signal 'pg-protocol-error (list msg)))))


(defun pg-initialize-parsers (connection)
  (setq pg-parsers '())
  (let* ((pgtypes (pg-exec connection "SELECT typname,oid FROM pg_type"))
         (tuples (pg-result pgtypes :tuples)))
    (mapcar
     (lambda (tuple)
       (let* ((typname (cl-first tuple))
              (oid (string-to-number (cl-second tuple)))
              (type (cl-assoc typname pg-type-parsers :test #'string=)))
         (if (consp type)
             (push (cons oid (cdr type)) pg-parsers))))
     tuples)))

(defun pg-parse (str oid encoding)
  (let ((parser (cl-assoc oid pg-parsers :test #'eq)))
    (if (consp parser)
        (funcall (cdr parser) str encoding)
      str)))

;; This function must be called before using the HSTORE extension. It loads the extension if
;; necessary, and sets up the parsing support for HSTORE datatypes. This is necessary because
;; the hstore type is not defined on startup in the pg_type table.
(defun pg-hstore-setup (conn)
  "Prepare for using and parsing HSTORE datatypes on PostgreSQL connection CONN."
  (pg-exec conn "CREATE EXTENSION IF NOT EXISTS hstore")
  (let* ((res (pg-exec conn "SELECT oid FROM pg_type WHERE typname='hstore'"))
         (oid (car (pg-result res :tuple 0))))
    (push (cons oid #'pg-hstore-parser) pg-parsers)))


;; Map between PostgreSQL names for encodings and their Emacs name.
;; For Emacs, see coding-system-alist.
(defconst pg-encoding-names
  '(("UTF8"    . utf-8)
    ("UTF16"   . utf-16)
    ("LATIN1"  . latin-1)
    ("LATIN2"  . latin-2)
    ("LATIN3"  . latin-3)
    ("LATIN4"  . latin-4)
    ("LATIN5"  . latin-5)
    ("LATIN6"  . latin-6)
    ("LATIN7"  . latin-7)
    ("LATIN8"  . latin-8)
    ("LATIN9"  . latin-9)
    ("LATIN10" . latin-10)
    ("WIN1250" . windows-1250)
    ("WIN1251" . windows-1251)
    ("WIN1252" . windows-1252)
    ("WIN1253" . windows-1253)
    ("WIN1254" . windows-1254)
    ("WIN1255" . windows-1255)
    ("WIN1256" . windows-1256)
    ("WIN1257" . windows-1257)
    ("WIN1258" . windows-1258)
    ("SHIFT_JIS_2004" . shift_jis-2004)
    ("SJIS"    . shift_jis-2004)
    ("GB18030" . gb18030)
    ("EUC_TW"  . euc-taiwan)
    ("EUC_KR"  . euc-korea)
    ("EUC_JP"  . euc-japan)
    ("EUC_CN"  . euc-china)
    ("BIG5"    . big5)))

;; Convert from PostgreSQL to Emacs encoding names
(defun pg-normalize-encoding-name (name)
  (let ((m (assoc name pg-encoding-names #'string=)))
    (when m (cdr m))))


(defun pg-serialize-binary (_bytestring)
  )

(defun pg-serialize-json (_json)
  )

(defun pg-serialize-xml (_xml)
  )

(defun pg-serialize-array (_array)
  )

(defun pg-serialize-string (_string)
  ;; quoting/escaping characters as necessary (eg NULL)
  )




;; pwdhash = md5(password + username).hexdigest()
;; hash = ′md5′ + md5(pwdhash + salt).hexdigest()
(defun pg-do-md5-authentication (con user password)
  "Attempt MD5 authentication with PostgreSQL database over connection CON.
Authenticate as USER with PASSWORD."
  (let* ((salt (pg-read-chars con 4))
         (pwdhash (md5 (concat password user)))
         (hash (concat "md5" (md5 (concat pwdhash salt)))))
    (pg-send-char con ?p)
    (pg-send-int con (+ 5 (length hash)) 4)
    (pg-send-string con hash)
    (pg-flush con)))


;; TODO: implement stringprep for user names and passwords, as per RFC4013.
(defun pg-sasl-prep (string)
  string)


(defun pg-logxor-string (s1 s2)
  "Elementwise XOR of each character of strings S1 and S2."
  (let ((len (length s1)))
    (cl-assert (eql len (length s2)))
    (let ((out (make-string len 0)))
      (dotimes (i len)
        (setf (aref out i) (logxor (aref s1 i) (aref s2 i))))
      out)))

;; PBKDF2 is a key derivation function used to reduce vulnerability to brute-force password guessing
;; attempts <https://en.wikipedia.org/wiki/PBKDF2>.
(defun pg-pbkdf2-hash-sha256 (password salt iterations)
  (let* ((hash (gnutls-hash-mac 'SHA256 (cl-copy-seq password) (concat salt (string 0 0 0 1))))
         (result hash))
    (dotimes (_i (1- iterations))
      (setf hash (gnutls-hash-mac 'SHA256 (cl-copy-seq password) hash))
      (setf result (pg-logxor-string result hash)))
    result))

;; Implement PBKDF2 by calling out to the nettle-pbkdf2 application (typically available in the
;; "nettle-bin" package) as a subprocess.
(defun pg-pbkdf2-hash-sha256-nettle (password salt iterations)
  ;; ITERATIONS is a integer
  ;; the hash function in nettle-pbkdf2 is hard coded to HMAC-SHA256
  (require 'hex-util)
  (with-temp-buffer
    (insert (pg-sasl-prep password))
    (call-process-region
     (point-min) (point-max)
     "nettle-pbkdf2"
     t t
     "--raw" "-i" (format "%d" iterations) "-l" "32" salt)
    ;; delete trailing newline character
    (goto-char (point-max))
    (backward-char 1)
    (when (eql ?\n (char-after))
      (delete-char 1))
    ;; out is in the format 55234f50f7f54f13 9e7f13d4becff1d6 aee3ab80a08cc034 c75e8ba21e43e01b
    (let ((out (delete ?\s (buffer-string))))
      (decode-hex-string out))))


;; use NIL to generate a new client nonce on each authentication attempt (normal practice)
;; or specify a string here to force a particular value for test purposes (compare test vectors)
(defvar pg-*force-client-nonce* "rOprNGfwEbeRWgbNEkqO")


;; SCRAM authentication methods use a password as a shared secret, which can then be used for mutual
;; authentication in a way that doesn't expose the secret directly to an attacker who might be
;; sniffing the communication.
;;
;; https://www.postgresql.org/docs/15/sasl-authentication.html
;; https://www.rfc-editor.org/rfc/rfc7677
(defun pg-do-scram-sha256-authentication (con user password)
  "Attempt SCRAM-SHA-256 authentication with PostgreSQL over connection CON.
Authenticate as USER with PASSWORD."
  (let* ((mechanism "SCRAM-SHA-256")
         (client-nonce (or pg-*force-client-nonce*
                           (apply #'string (cl-loop for i below 32 collect (+ ?A (random 25))))))
         (client-first (format "n,,n=%s,r=%s" user client-nonce))
         (len-cf (length client-first))
         ;; packet length doesn't include the initial ?p message type indicator
         (len-packet (+ 4 (1+ (length mechanism)) 4 len-cf)))
    ;; send the SASLInitialResponse message
    (pg-send-char con ?p)
    (pg-send-int con len-packet 4)
    (pg-send-string con mechanism)
    (pg-send-int con len-cf 4)
    (pg-send-octets con client-first)
    (pg-flush con)
    (let ((c (pg-read-char con)))
      (cond ((eq ?E c)
             ;; an ErrorResponse message
             (pg-handle-error-response con "during SASL auth"))

            ;; AuthenticationSASLContinue message, what we are hoping for
            ((eq ?R c)
             (let* ((len (pg-read-net-int con 4))
                    (type (pg-read-net-int con 4))
                    (server-first-msg (pg-read-chars con (- len 8))))
               (unless (eql type 11)
                 (let ((msg (format "Unexpected AuthenticationSASLContinue type %d" type)))
                   (signal 'pg-protocol-error (list msg))))
               (let* ((components (split-string server-first-msg ","))
                      (r= (cl-find "r=" components :key (lambda (s) (substring s 0 2)) :test #'string=))
                      (r (substring r= 2))
                      (s= (cl-find "s=" components :key (lambda (s) (substring s 0 2)) :test #'string=))
                      (s (substring s= 2))
                      (salt (base64-decode-string s))
                      (i= (cl-find "i=" components :key (lambda (s) (substring s 0 2)) :test #'string=))
                      (iterations (string-to-number (substring i= 2)))
                      (salted-password (pg-pbkdf2-hash-sha256 password salt iterations))
                      ;; beware: gnutls-hash-mac will zero out its first argument (the "secret")!
                      (client-key (gnutls-hash-mac 'SHA256 (cl-copy-seq salted-password) "Client Key"))
                      (server-key (gnutls-hash-mac 'SHA256 (cl-copy-seq salted-password) "Server Key"))
                      (stored-key (secure-hash 'sha256 client-key nil nil t))
                      (client-first-bare (concat "n=" (pg-sasl-prep user) ",r=" client-nonce))
                      (client-final-bare (concat "c=biws,r=" r))
                      (auth-message (concat client-first-bare "," server-first-msg "," client-final-bare))
                      (client-sig (gnutls-hash-mac 'SHA256 stored-key auth-message))
                      (client-proof (pg-logxor-string client-key client-sig))
                      (server-sig (gnutls-hash-mac 'SHA256 server-key auth-message))
                      (client-final-msg (concat client-final-bare ",p=" (base64-encode-string client-proof t))))
                 (when (zerop iterations)
                   (let ((msg (format "SCRAM-SHA-256: server supplied invalid iteration count %s" i=)))
                     (signal 'pg-protocol-error (list msg))))
                 (unless (string= client-nonce (substring r 0 (length client-nonce)))
                   (signal 'pg-protocol-error
                           (list "SASL response doesn't include correct client nonce")))
                 ;; we send a SASLResponse message with SCRAM client-final-message as content
                 (pg-send-char con ?p)
                 (pg-send-int con (+ 4 (length client-final-msg)) 4)
                 (pg-send-octets con client-final-msg)
                 (pg-flush con)
                 (let ((c (pg-read-char con)))
                   (cond ((eq ?E c)
                          ;; an ErrorResponse message
                          (pg-handle-error-response con "after SASLResponse"))

                         ((eq ?R c)
                          ;; an AuthenticationSASLFinal message
                          (let* ((len (pg-read-net-int con 4))
                                 (type (pg-read-net-int con 4))
                                 (server-final-msg (pg-read-chars con (- len 8))))
                            (unless (eql type 12)
                              (let ((msg (format "Expecting AuthenticationSASLFinal, got type %d" type)))
                                (signal 'pg-protocol-error (list msg))))
                            (when (string= "e=" (substring server-final-msg 0 2))
                              (let ((msg (format "PostgreSQL server error during SASL authentication: %s"
                                                 (substring server-final-msg 2))))
                                (signal 'pg-protocol-error (list msg))))
                            (unless (string= "v=" (substring server-final-msg 0 2))
                              (signal 'pg-protocol-error '("Unable to verify PostgreSQL server during SASL auth")))
                            (unless (string= (substring server-final-msg 2)
                                             (base64-encode-string server-sig t))
                              (let ((msg (format "SASL server validation failure: v=%s / %s"
                                                 (substring server-final-msg 2)
                                                 (base64-encode-string server-sig t))))
                                (signal 'pg-protocol-error (list msg))))
                            ;; should be followed immediately by an AuthenticationOK message
                            )))))))
            (t
             (let ((msg (format "Unexpected response to SASLInitialResponse message: %s" c)))
               (signal 'pg-protocol-error (list msg))))))))

(defun pg-do-sasl-authentication (con user password)
  "Attempt SASL authentication with PostgreSQL database over connection CON.
Authenticate as USER with PASSWORD."
  (let ((mechanisms (list)))
    ;; read server's list of preferered authentication mechanisms
    (cl-loop for mech = (pg-read-string con 4096)
             while (not (zerop (length mech)))
             do (push mech mechanisms))
    (if (member "SCRAM-SHA-256" mechanisms)
        (pg-do-scram-sha256-authentication con user password)
      (let ((msg (format "Can't handle any of SASL mechanisms %s" mechanisms)))
        (signal 'pg-protocol-error (list msg))))))



;; large object support ================================================
;;
;; Humphrey: Who is Large and to what does he object?
;;
;; Large objects are the PostgreSQL way of doing what most databases
;; call BLOBs (binary large objects). In addition to being able to
;; stream data to and from large objects, PostgreSQL's
;; object-relational capabilities allow the user to provide functions
;; which act on the objects.
;;
;; For example, the user can define a new type called "circle", and
;; define a C or Tcl function called `circumference' which will act on
;; circles. There is also an inheritance mechanism in PostgreSQL.
;;
;;======================================================================
(defvar pg-lo-initialized nil)
(defvar pg-lo-functions '())

(defun pg-lo-init (connection)
  (let* ((res (pg-exec connection
                       "SELECT proname, oid from pg_proc WHERE "
                       "proname = 'lo_open' OR "
                       "proname = 'lo_close' OR "
                       "proname = 'lo_creat' OR "
                       "proname = 'lo_unlink' OR "
                       "proname = 'lo_lseek' OR "
                       "proname = 'lo_tell' OR "
                       "proname = 'loread' OR "
                       "proname = 'lowrite'")))
    (setq pg-lo-functions '())
    (mapc
     (lambda (tuple)
       (push (cons (car tuple) (cadr tuple)) pg-lo-functions))
     (pg-result res :tuples))
    (setq pg-lo-initialized t)))

;; fn is either an integer, in which case it is the OID of an element
;; in the pg_proc table, and otherwise it is a string which we look up
;; in the alist `pg-lo-functions' to find the corresponding OID.
(defun pg-fn (con fn integer-result &rest args)
  (unless pg-lo-initialized
    (pg-lo-init con))
  (let ((fnid (cond ((integerp fn) fn)
                    ((not (stringp fn))
                     (let ((msg (format "Expecting a string or an integer: %s" fn)))
                       (signal 'pg-protocol-error (list msg))))
                    ((assoc fn pg-lo-functions) ; blech
                     (cdr (assoc fn pg-lo-functions)))
                    (t
                     (error "Unknown builtin function %s" fn)))))
    (pg-send-char con ?F)
    (pg-send-char con 0)
    (pg-send-int con fnid 4)
    (pg-send-int con (length args) 4)
    (mapc (lambda (arg)
            (cond ((integerp arg)
                   (pg-send-int con 4 4)
                   (pg-send-int con arg 4))
                  ((stringp arg)
                   (pg-send-int con (length arg) 4)
                   (pg-send con arg))
                  (t
                   (error "Unknown fastpath type %s" arg))))
          args)
    (pg-flush con)
    (cl-loop with result = '()
          for c = (pg-read-char con) do
          (cl-case c
             ;; ErrorResponse
            (?E (pg-handle-error-response con "in pg-fn"))

            ;; FunctionResultResponse
            (?V (setq result t))

            ;; Nonempty response
            (?G
             (let* ((len (pg-read-net-int con 4))
                    (res (if integer-result
                             (pg-read-net-int con len)
                           (pg-read-chars con len))))
               (setq result res)))

            ;; NoticeResponse
            (?N
             (let ((notice (pg-read-string con pg-MAX_MESSAGE_LEN)))
               (message "NOTICE: %s" notice))
             (unix-sync))

            ;; ReadyForQuery
            (?Z
             ;; message length then status, discarded
             (pg-read-net-int con 4)
             (pg-read-char con))

            ;; end of FunctionResult
            (?0 (cl-return result))

            (t (error "Unexpected character in pg-fn: %s" c))))))

;; returns an OID
(defun pg-lo-create (connection &optional args)
  (let* ((modestr (or args "r"))
         (mode (cond ((integerp modestr) modestr)
                     ((string= "r" modestr) pg-INV_READ)
                     ((string= "w" modestr) pg-INV_WRITE)
                     ((string= "rw" modestr)
                      (logior pg-INV_READ pg-INV_WRITE))
                     (t (error "pg-lo-create: bad mode %s" modestr))))
         (oid (pg-fn connection "lo_creat" t mode)))
    (cond ((not (integerp oid))
           (error "Returned value not an OID: %s" oid))
          ((zerop oid)
           (error "Can't create large object"))
          (t oid))))

;; args = modestring (default "r", or "w" or "rw")
;; returns a file descriptor for use in later pg-lo-* procedures
(defun pg-lo-open (connection oid &optional args)
  (let* ((modestr (or args "r"))
         (mode (cond ((integerp modestr) modestr)
                     ((string= "r" modestr) pg-INV_READ)
                     ((string= "w" modestr) pg-INV_WRITE)
                     ((string= "rw" modestr)
                      (logior pg-INV_READ pg-INV_WRITE))
                     (t (error "pg-lo-open: bad mode %s" modestr))))
         (fd (pg-fn connection "lo_open" t oid mode)))
    (unless (integerp fd)
      (error "Couldn't open large object"))
    fd))

(defsubst pg-lo-close (connection fd)
  (pg-fn connection "lo_close" t fd))

(defsubst pg-lo-read (connection fd bytes)
  (pg-fn connection "loread" nil fd bytes))

(defsubst pg-lo-write (connection fd buf)
  (pg-fn connection "lowrite" t fd buf))

(defsubst pg-lo-lseek (connection fd offset whence)
  (pg-fn connection "lo_lseek" t fd offset whence))

(defsubst pg-lo-tell (connection oid)
  (pg-fn connection "lo_tell" t oid))

(defsubst pg-lo-unlink (connection oid)
  (pg-fn connection "lo_unlink" t oid))

;; returns an OID
;; FIXME should use unwind-protect here
(defun pg-lo-import (connection filename)
  (let* ((buf (get-buffer-create (format " *pg-%s" filename)))
         (oid (pg-lo-create connection "rw"))
         (fdout (pg-lo-open connection oid "w"))
         (pos (point-min)))
    (with-current-buffer buf
      (insert-file-contents-literally filename)
      (while (< pos (point-max))
        (pg-lo-write
         connection fdout
         (buffer-substring-no-properties pos (min (point-max) (cl-incf pos 1024)))))
      (pg-lo-close connection fdout))
    (kill-buffer buf)
    oid))

(defun pg-lo-export (connection oid filename)
  (let* ((buf (get-buffer-create (format " *pg-%d" oid)))
         (fdin (pg-lo-open connection oid "r")))
    (with-current-buffer buf
      (cl-do ((str (pg-lo-read connection fdin 1024)
                   (pg-lo-read connection fdin 1024)))
          ((or (not str)
               (zerop (length str))))
        (insert str))
      (pg-lo-close connection fdin)
      (write-file filename))
    (kill-buffer buf)))



;; DBMS metainformation ================================================
;;
;; Metainformation such as the list of databases present in the database management system, list of
;; tables, attributes per table. This information is not available directly, but can be obtained by
;; querying the system tables.
;;
;; Based on the queries issued by psql in response to user commands `\d' and `\d tablename'; see
;; file /usr/local/src/pgsql/src/bin/psql/psql.c
;; =====================================================================
(defun pg-databases (con)
  "List of the databases available in the instance we are connected to via CON."
  (let ((res (pg-exec con "SELECT datname FROM pg_database")))
    (apply #'append (pg-result res :tuples))))

(defun pg-tables (con)
  "List of the tables present in the database we are connected to via CON."
  (let ((res (pg-exec con "SELECT relname FROM pg_class, pg_user WHERE "
                      "(relkind = 'r' OR relkind = 'i' OR relkind = 'S') AND "
                      "relname !~ '^pg_' AND usesysid = relowner ORDER BY relname")))
    (apply #'append (pg-result res :tuples))))

(defun pg-columns (con table)
  "List of the columns present in TABLE over PostgreSQL connection CON."
  (let* ((sql (format "SELECT * FROM %s WHERE 0 = 1" table))
         (res (pg-exec con sql)))
    (mapcar #'car (pg-result res :attributes))))

(defun pg-backend-version (con)
  "Version and operating environment of backend that we are connected to by CON.
PostgreSQL returns the version as a string. CrateDB returns it as an integer."
  (let ((res (pg-exec con "SELECT version()")))
    (cl-first (pg-result res :tuple 0))))


;; support routines ============================================================

;; Called to handle a RowDescription message
;;
;; Attribute information is as follows
;;    attribute-name (string)
;;    attribute-type as an oid from table pg_type
;;    attribute-size (in bytes?)
(defun pg-read-attributes (connection)
  (let* ((_msglen (pg-read-net-int connection 4))
         (attribute-count (pg-read-net-int connection 2))
         (attributes (list))
         (ce (pgcon-client-encoding connection)))
    (cl-do ((i attribute-count (- i 1)))
        ((zerop i) (nreverse attributes))
      (let ((type-name  (pg-read-string connection pg-MAX_MESSAGE_LEN))
            (_table-oid (pg-read-net-int connection 4))
            (_col       (pg-read-net-int connection 2))
            (type-oid   (pg-read-net-int connection 4))
            (type-len   (pg-read-net-int connection 2))
            (_type-mod  (pg-read-net-int connection 4))
            (_format-code (pg-read-net-int connection 2)))
        (push (list (pg-text-parser type-name ce) type-oid type-len) attributes)))))

;; a bitmap is a string, which we interpret as a sequence of bytes
(defun pg-bitmap-ref (bitmap ref)
  (let ((int (aref bitmap (floor ref 8))))
    (logand 128 (ash int (mod ref 8)))))

;; Read data following a DataRow message
(defun pg-read-tuple (connection attributes)
  (let* ((num-attributes (length attributes))
         (col-count (pg-read-net-int connection 2))
         (tuples (list))
         (ce (pgcon-client-encoding connection)))
    (unless (eql col-count num-attributes)
      (signal 'pg-protocol-error '("Unexpected value for attribute count sent by backend")))
    (cl-do ((i 0 (+ i 1))
            (type-ids (mapcar #'cl-second attributes) (cdr type-ids)))
        ((= i num-attributes) (nreverse tuples))
      (let ((col-octets (pg-read-net-int connection 4)))
        (cl-case col-octets
          (4294967295
           ;; this is "-1" (pg-read-net-int doesn't handle integer overflow), which indicates a
           ;; NULL column
           (push nil tuples))
          (0
           (push "" tuples))
          (t
           (let* ((col-value (pg-read-chars connection col-octets))
                  (parsed (pg-parse col-value (car type-ids) ce)))
             (push parsed tuples))))))))

(defun pg-read-char (connection)
  (let ((process (pgcon-process connection))
        (position (pgcon-position connection)))
    (with-current-buffer (process-buffer process)
      (cl-incf (pgcon-position connection))
      (when (null (char-after position))
        (accept-process-output process 5))
      (char-after position))))

(defun pg-unread-char (connection)
  (cl-decf (pgcon-position connection)))

;; FIXME should be more careful here; the integer could overflow.
(defun pg-read-net-int (connection bytes)
  (cl-do ((i bytes (- i 1))
          (accum 0))
      ((zerop i) accum)
    (setq accum (+ (* 256 accum) (pg-read-char connection)))))

(defun pg-read-int (connection bytes)
  (cl-do ((i bytes (- i 1))
          (multiplier 1 (* multiplier 256))
          (accum 0))
      ((zerop i) accum)
    (cl-incf accum (* multiplier (pg-read-char connection)))))

(defun pg-read-chars-old (connection howmany)
  (cl-do ((i 0 (+ i 1))
          (chars (make-string howmany ?.)))
      ((= i howmany) chars)
    (aset chars i (pg-read-char connection))))

(defun pg-read-chars (connection count)
  (let* ((process (pgcon-process connection))
         (start (pgcon-position connection))
         (end (+ start count)))
    (accept-process-output)
    (prog1 (with-current-buffer (process-buffer process)
             ;; wait for new output, if necessary
             (when (> end (point-max))
               (accept-process-output process 5))
             (buffer-substring start end))
      (setf (pgcon-position connection) end))))

;; read a null-terminated string
(defun pg-read-string (connection maxbytes)
  (cl-loop for i below maxbytes
           for ch = (pg-read-char connection)
           until (= ch ?\0)
           concat (byte-to-string ch)))

(cl-defstruct pgerror
  severity sqlstate message detail hint table column dtype)

(defun pg-read-error-response (connection)
  (let* ((response-len (pg-read-net-int connection 4))
         (msglen (- response-len 4))
         (msg (pg-read-chars connection msglen))
         (msgpos 0)
         (err (make-pgerror))
         (ce (pgcon-client-encoding connection)))
    (cl-loop while (< msgpos (1- msglen))
             for field = (aref msg msgpos)
             for val = (let* ((start (cl-incf msgpos))
                              (end (cl-position #x0 msg :start start :end msglen)))
                         (prog1
                             (substring msg start end)
                           (setf msgpos (1+ end))))
             ;; these field types: https://www.postgresql.org/docs/current/protocol-error-fields.html
             do (cond ((eq field ?S)
                       (setf (pgerror-severity err) val))
                      ((eq field ?C)
                       (setf (pgerror-sqlstate err) val))
                      ((eq field ?M)
                       (setf (pgerror-message err)
                             (decode-coding-string val ce)))
                      ((eq field ?D)
                       (setf (pgerror-detail err)
                             (decode-coding-string val ce)))
                      ((eq field ?H)
                       (setf (pgerror-hint err)
                             (decode-coding-string val ce)))
                      ((eq field ?t)
                       (setf (pgerror-table err) val))
                      ((eq field ?c)
                       (setf (pgerror-column err) val))
                      ((eq field ?d)
                       (setf (pgerror-dtype err) val))))
    err))

(defun pg-handle-error-response (con &optional context)
  "Handle an ErrorMessage from the backend we are connected to over CON.
Additional information CONTEXT can be optionally included in the error message
presented to the user."
  (let ((e (pg-read-error-response con))
        (extra (list)))
    (when (pgerror-detail e)
      (push ", " extra)
      (push (pgerror-detail e) extra))
    (when (pgerror-hint e)
      (push ", " extra)
      (push (format "hint: %s" (pgerror-hint e)) extra))
    (when (pgerror-table e)
      (push ", " extra)
      (push (format "table: %s" (pgerror-table e)) extra))
    (when (pgerror-column e)
      (push ", " extra)
      (push (format "column: %s" (pgerror-column e)) extra))
    (setf extra (nreverse extra))
    (pop extra)
    (setf extra (butlast extra))
    (when extra
      (setf extra (append (list " (") extra (list ")"))))
    ;; now read the ReadyForQuery message. We don't always receive this immediately; for example if
    ;; an incorrect username is send during startup, PostgreSQL sends an ErrorMessage then an
    ;; AuthenticationSASL message. In that case, unread the message type octet so that it can
    ;; potentially be handled after the error is signaled.
    (let ((c (pg-read-char con)))
      (unless (eql c ?Z)
        (message "Unexpected message type after ErrorMsg: %s" c)
        (pg-unread-char con)))
    ;; message length then status, discarded
    (pg-read-net-int con 4)
    (pg-read-char con)
    (let ((msg (format "%s%s: %s%s"
                       (pgerror-severity e)
                       (or (concat " " context) "")
                       (pgerror-message e)
                       (apply #'concat extra))))
      (signal 'pg-error (list msg)))))

(defun pg-log-notice (notice)
  "Log a NOTICE to the *Messages* buffer."
  (let ((extra (list)))
    (when (pgerror-detail notice)
      (push ", " extra)
      (push (pgerror-detail notice) extra))
    (when (pgerror-hint notice)
      (push ", " extra)
      (push (format "hint: %s" (pgerror-hint notice)) extra))
    (when (pgerror-table notice)
      (push ", " extra)
      (push (format "table: %s" (pgerror-table notice)) extra))
    (when (pgerror-column notice)
      (push ", " extra)
      (push (format "column: %s" (pgerror-column notice)) extra))
    (setf extra (nreverse extra))
    (pop extra)
    (setf extra (butlast extra))
    (when extra
      (setf extra (append (list " (") extra (list ")"))))
    (message "PostgreSQL %s %s %s"
             (pgerror-severity notice)
             (pgerror-message notice)
             (apply #'concat extra))))

;; higher order bits first
(defun pg-send-int (connection num bytes)
  (let ((process (pgcon-process connection))
        (str (make-string bytes 0))
        (i (- bytes 1)))
    (while (>= i 0)
      (aset str i (% num 256))
      (setq num (floor num 256))
      (cl-decf i))
    (process-send-string process str)))

(defun pg-send-net-int (connection num bytes)
  (let ((process (pgcon-process connection))
        (str (make-string bytes 0)))
    (dotimes (i bytes)
      (aset str i (% num 256))
      (setq num (floor num 256)))
    (process-send-string process str)))

(defun pg-send-char (connection char)
  (let ((process (pgcon-process connection)))
    (process-send-string process (char-to-string char))))

(defun pg-send-string (connection str)
  (let ((process (pgcon-process connection)))
    ;; the string with the null-terminator octet
    (process-send-string process (concat str (string 0)))))

(defun pg-send-octets (connection octets)
  (let ((process (pgcon-process connection)))
    (process-send-string process octets)))

(defun pg-send (connection str &optional bytes)
  (let ((process (pgcon-process connection))
        (padding (if (and (numberp bytes) (> bytes (length str)))
                     (make-string (- bytes (length str)) 0)
                   (make-string 0 0))))
    (process-send-string process (concat str padding))))


;; Mostly for debugging use. Doesn't kill lo buffers.
(defun pg-kill-all-buffers ()
  "Kill all buffers used for network connections with PostgreSQL."
  (interactive)
  (cl-loop for buffer in (buffer-list)
           for name = (buffer-name buffer)
           when (and (> (length name) 12)
                     (string= " *PostgreSQL*" (substring (buffer-name buffer) 0 13)))
           do (let ((p (get-buffer-process buffer)))
                (when p
                  (kill-process p)))
           (kill-buffer buffer)))


(provide 'pg)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; pg.el ends here
