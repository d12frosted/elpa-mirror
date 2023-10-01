Overview
--------

This module lets you access the PostgreSQL object-relational DBMS from
Emacs, using its socket-level frontend/backend protocol. The module is
capable of automatic type coercions from a range of SQL types to the
equivalent Emacs Lisp type. This is a low level API, and won't be
useful to end users.

Supported features:
 - SCRAM-SHA-256 authentication (the default method since PostgreSQL version 14)
 - MD5 authentication
 - Encrypted (TLS) connections
 - Support for the SQL COPY protocol to copy preformatted data to PostgreSQL from an Emacs buffer
 - Asynchronous handling of LISTEN/NOTIFY notification messages from PostgreSQL, allowing the
   implementation of publish-subscribe type architectures (PostgreSQL as an "event broker" or
   "message bus" and Emacs as event publisher and consumer.


Entry points
------------

(with-pg-connection con (dbname user [password host port]) &body body)
    A macro which opens a connection to database DBNAME over a TCP socket,
    executes the BODY forms then disconnects. See function `pg-connect' for
    details of the connection arguments.

(with-pg-connection-local con (path dbname user [password]) &body body)
    A macro which opens a connection to database DBNAME over a local Unix
    socket at PATH, executes the BODY forms then disconnects. See function
    `pg-connect-local' for details of the connection arguments.

(with-pg-transaction con &body body)
    A macro which executes the BODY forms wrapped in an SQL transaction.
    CON is a connection to the database. If an error occurs during the
    execution of the forms, a ROLLBACK instruction is executed.

(pg-connect dbname user [password host port tls]) -> connection
    Connect to the database DBNAME on HOST (defaults to localhost) at PORT
    (defaults to 5432) via TCP/IP and log in as USER. PASSWORD is used for
    authentication with the backend (defaults to the empty string). If TLS is
    non-NIL, attempt to upgrade the connection to TLS. Set the output date
    type to 'ISO', and initialize our type parser tables.

(pg-connect-local path dbname user [password]) -> connection
    Connect to the database DBNAME over local Unix socket at PATH and log in
    as USER. PASSWORD is used for authentication with the backend (defaults
    to the empty string). Set the output date type to 'ISO', and initialize
    our type parser tables.

(pg-exec connection &rest sql) -> pgresult
    Concatenate the SQL strings and send to the backend. Retrieve
    all the information returned by the database and return it in
    an opaque record PGRESULT.

(pg-result pgresult what &rest args) -> info
    Extract information from the PGRESULT. The WHAT keyword can be
    one of
         * :connection
         * :status
         * :attributes
         * :tuples
         * :tuple tupleNumber
         * :oid
    `:connection' allows you to retrieve the database connection.
    `:status' is a string returned by the backend to indicate the
    status of the command; it is something like "SELECT" for a
    select command, "DELETE 1" if the deletion affected a single
    row, etc. `:attributes' is a list of tuples providing metadata:
    the first component of each tuple is the attribute's name as a
    string, the second an integer representing its PostgreSQL type,
    and the third an integer representing the size of that type.
    `:tuples' returns all the data retrieved from the database, as a
    list of lists, each list corresponding to one row of data
    returned by the backend. `:tuple num' can be used to extract a
    specific tuple (numbering starts at 0). `:oid' allows you to
    retrieve the OID returned by the backend if the command was an
    insertion; the OID is a unique identifier for that row in the
    database (this is PostgreSQL-specific, please refer to the
    documentation for more details).

(pg-cancel connection) -> nil
    Ask the server to cancel the command being processed by the backend.
    The cancellation request concerns the command requested over
    database connection CONNECTION.

(pg-disconnect connection) -> nil
    Close the database connection.

(pg-for-each connection select-form callback)
    Calls CALLBACK on each tuple returned by SELECT-FORM. Declares
    a cursor for SELECT-FORM, then fetches tuples using repeated
    executions of FETCH 1, until no results are left. The cursor is
    then closed. The work is performed within a transaction. When
    you have a large amount of data to handle, this usage is more
    efficient than fetching all the tuples in one go.

    If you wish to browse the results, each one in a separate
    buffer, you could have the callback insert each tuple into a
    buffer created with (generate-new-buffer "myprefix"), then use
    ibuffer's "/ n" to list/visit/delete all buffers whose names
    match myprefix.

(pg-databases connection) -> list of strings
    Return a list of the databases available at this site (a
    database is a set of tables; in a fresh PostgreSQL
    installation there is a single database named "template1").

(pg-tables connection) -> list of strings
    Return a list of the tables present in the database to which we
    are currently connected. Only include user tables: system
    tables are excluded.

(pg-columns connection table) -> list of strings
    Return a list of the columns (or attributes) in TABLE, which
    must be a table in the database to which we are currently
    connected. We only include the column names; if you want more
    detailed information (attribute types, for example), it can be
    obtained from `pg-result' on a SELECT statement for that table.

(pg-hstore-setup conn)
    Prepare for the use of HSTORE datatypes. This function must be called
    before using the HSTORE extension. It loads the extension if necessary,
    and sets up the parsing support for HSTORE datatypes.

(pg-lo-create conn . args) -> oid
    Create a new large object (BLOB, or binary large object in
    other DBMSes parlance) in the database to which we are
    connected via CONN. Returns an OID (which is represented as an
    elisp integer) which will allow you to use the large object.
    Optional ARGS are a Unix-style mode string which determines the
    permissions of the newly created large object, one of "r" for
    read-only permission, "w" for write-only, "rw" for read+write.
    Default is "r".

    Large-object functions MUST be used within a transaction (see
    the macro `with-pg-transaction').

(pg-lo-open conn oid . args) -> fd
    Open a large object whose unique identifier is OID (an elisp
    integer) in the database to which we are connected via CONN.
    Optional ARGS is a Unix-style mode string as for pg-lo-create;
    which defaults to "r" read-only permissions. Returns a file
    descriptor (an elisp integer) which can be used in other
    large-object functions.

(pg-lo-close conn fd)
    Close the file descriptor FD which was associated with a large
    object. Note that this does not delete the large object; use
    `pg-lo-unlink' for that.

(pg-lo-read conn fd bytes) -> string
    Read BYTES from the file descriptor FD which is associated with
    a large object. Return an elisp string which should be BYTES
    characters long.

(pg-lo-write connection fd buf)
    Write the bytes contained in the elisp string BUF to the
    large object associated with the file descriptor FD.

(pg-lo-lseek conn fd offset whence)
    Do the equivalent of a lseek(2) on the file descriptor FD which
    is associated with a large object; ie reposition the read/write
    file offset for that large object to OFFSET (an elisp
    integer). WHENCE has the same significance as in lseek(); it
    should be one of SEEK_SET (set the offset to the absolute
    position), SEEK_CUR (set the offset relative to the current
    offset) or SEEK_END (set the offset relative to the end of the
    file). WHENCE should be an elisp integer whose values can be
    obtained from the header file <unistd.h> (probably 0, 1 and 2
    respectively).

(pg-lo-tell conn oid) -> integer
    Do the equivalent of an ftell(3) on the file associated with
    the large object whose unique identifier is OID. Returns the
    current position of the file offset for the object's associated
    file descriptor, as an elisp integer.

(pg-lo-unlink conn oid)
    Remove the large object whose unique identifier is OID from the
    system (in the current implementation of large objects in
    PostgreSQL, each large object is associated with an object in
    the filesystem).

(pg-lo-import conn filename) -> oid
    Create a new large object and initialize it to the data
    contained in the file whose name is FILENAME. Returns an OID
    (as an elisp integer). Note that is operation is only syntactic
    sugar around the basic large-object operations listed above.

(pg-lo-export conn oid filename)
    Create a new file named FILENAME and fill it with the contents
    of the large object whose unique identifier is OID. This
    operation is also syntactic sugar.


Variable `pg-parameter-change-functions' is a list of handlers to be called
when the backend informs us of a parameter change, for example a change to
the session time zone. Each handler is called with three arguments: the
connection to the backend, the parameter name and the parameter value.

Variable `pg-handle-notice-functions' is a list of handlers to be called when
the backend sends us a `NOTICE' message. Each handler is called with one
argument, the notice, as a pgerror struct.

Boolean variable `pg-disable-type-coercion' can be set to non-nil (before
initiating a connection) to disable the library's type coercion facility.
Default is t.


For more information about PostgreSQL see <https://www.PostgreSQL.org/>.

Thanks to Eric Ludlam for discovering a bug in the date parsing routines, to
Hartmut Pilch and Yoshio Katayama for adding multibyte support, and to Doug
McNaught and Pavel Janik for bug fixes.


; INSTALL

Place this file in a directory somewhere in the load-path, then
byte-compile it (do a `B' on it in Dired, for example). Place a
line such as `(require 'pg)' in your Emacs initialization file.


; TODO

* Provide support for client-side certificates to authenticate network
  connections over TLS.

* Implement the SASLPREP algorithm for usernames and passwords that contain
  unprintable characters (used for SCRAM-SHA-256 authentication).

* Add a mechanism for parsing user-defined types. The user should
  be able to define a parse function and a type-name; we query
  pg_type to get the type's OID and add the information to
  pg-parsers.
