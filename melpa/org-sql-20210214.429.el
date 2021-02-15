;;; org-sql.el --- Org-Mode SQL converter -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Nathan Dwarshuis

;; Author: Nathan Dwarshuis <natedwarshuis@gmail.com>
;; Keywords: org-mode, data
;; Package-Version: 20210214.429
;; Package-Commit: 9fba239443daafe8ccba40d93dfb3ea6f0341e37
;; Homepage: https://github.com/ndwarshuis/org-sql
;; Package-Requires: ((emacs "27.1") (s "1.12") (f "0.20.0") (dash "2.17") (org-ml "5.4.3"))
;; Version: 2.0.0

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

;; This code stores org buffers in a variety of SQL databases for use in
;; processing org-mode data outside of Emacs where SQL operations might be more
;; appropriate. Org files are stored according to the perspective of unique
;; org outline; any outline might reside in multiple identical files.

;; The rough process by which this occurs is:
;;  1) query state of org files on disk and in db (if any) and classify
;;     files as 'updates', 'deletes', or 'inserts'
;;    - updates: a file on disk is also in the database but the path on disk has
;;      changed; this is the part that will be updated
;;    - deletes: a file in the db is not on disk; therefore delete from db
;;    - inserts: a file is on disk but not in the db, therefore insert into db
;;    - NOTE: file equality will be assessed using a hash algorithm (eg md5)
;;    - NOTE: in the case that a file on disk has changed and its path is also
;;      in the db, this file will be deleted and reinserted
;;  2) convert the updates/deletes/inserts into database-specific SQL statements
;;    - inserts will be constructed using `org-element'/`org-ml' from target
;;      files on disk
;;  3) send SQL statements to the configured database

;; The code is arranged as follows:
;; - constants
;; - customization variables
;; - stateless functions
;; - stateful IO functions

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'dash)
(require 's)
(require 'f)
(require 'sql)
(require 'org)
(require 'org-clock)
(require 'org-ml)

;;;
;;; CONSTANTS
;;;

(defconst org-sql--log-note-keys
  '((:user .  "%u")
    (:user-full . "%U")
    (:ts . "%t")
    (:ts-active . "%T")
    (:short-ts . "%d")
    (:short-ts-active . "%D")
    (:old-state . "%S")
    (:new-state . "%s"))
  "Keywords for placeholders used in `org-log-note-headings'.")

(defconst org-sql--log-note-replacements
  (->> (-map #'cdr org-sql--log-note-keys) (--map (cons it it)))
  "A list to simplify placeholders in `org-log-note-headings'.
This is only used in combination with `org-replace-escapes'")

(defconst org-sql--entry-keys
  (append
   (-map #'car org-sql--log-note-keys)
   '(:outline-hash :note-text :header-text :old-ts :new-ts))
  "Valid keys that may be used in logbook entry lists.")

(defconst org-sql--ignored-properties-default
  '("ARCHIVE_ITAGS" "Effort")
  "Property keys to be ignored when inserting in properties table.
It is assumed these are used elsewhere and thus it would be redundant
to store them. This is in addition to any properties specifified by
`org-sql-excluded-properties'.")

(defconst org-sql--content-timestamp-types
  '(active active-range inactive inactive-range)
  "Types of timestamps to include in the database.")

(eval-and-compile
  (let ((outline_hash-char-length 32)
        ;; ASSUME all filesystems we would ever want to use have a path limit of
        ;; 255 chars (which is almost always true)
        (file_path-varchar-length 255)
        (tag-varchar-length 32)
        (tag-col '(:tag :desc "the text value of this tag"
                        :type varchar
                        :length 32))
        (property-id-col '(:property_id :desc "id of this property"
                                        :type integer))
        (modifier-allowed-units '(hour day week month year)))
    (cl-flet*
        ((mk-col
          (default-desc fmt name other object notnull)
          (let* ((d (if object (format fmt object) default-desc))
                 (k `(,name :desc ,d ,@other)))
            (if notnull `(,@k :constraints (notnull)) k)))
         (outline-hash-col
          (&optional object notnull)
          (mk-col "hash (MD5) of this org outline"
                  "hash (MD5) of the org outline with this %s"
                  :outline_hash `(:type char :length ,outline_hash-char-length)
                  object notnull))
         (headline-id-col
          (&optional object notnull)
          (mk-col "id of this headline"
                  "id of the headline for this %s"
                  :headline_id '(:type integer) object notnull))
         (timestamp-id-col
          (&optional object notnull)
          (mk-col "id of this timestamp"
                  "id of the timestamp for this %s"
                  :timestamp_id '(:type integer) object notnull))
         (entry-id-col
          (&optional object notnull)
          (mk-col "id of this entry"
                  "id of the entry for this %s"
                  :entry_id '(:type integer) object notnull)))
      ;; NOTE double backticks to get the blocky rendering in Github
      (defconst org-sql--table-alist
        `((outlines
           (desc "Each row stores the hash and size for the contents of one org"
                 "file (here called an `outline`). Note that if there are"
                 "identical org files, only one `outline` will be stored in the"
                 "database (as determined by the unique hash) and the paths"
                 "shared the outline will be reflected in the `file_metadata`"
                 "table.")
           (columns
            ,(outline-hash-col)
            (:outline_size :desc "number of characters of the org outline"
                           :type integer
                           :constraints (notnull))
            (:outline_lines :desc "number of lines in the org file"
                            :type integer
                            :constraints (notnull)))
           (constraints
            (primary :keys (:outline_hash))))

          (file_metadata
           (desc "Each row stores filesystem metadata for one tracked org file.")
           (columns
            (:file_path :desc "path to org file"
                        :type varchar
                        :length ,file_path-varchar-length)
            ,(outline-hash-col "path" t)
            (:file_uid :desc "UID of the file"
                       :type integer
                       :constraints (notnull))
            (:file_gid :desc "GID of the file"
                       :type integer
                       :constraints (notnull))
            (:file_modification_time :desc "time of the file's last modification"
                                     :type integer
                                     :constraints (notnull))
            (:file_attr_change_time :desc "time of the file's last attribute change"
                                    :type integer
                                    :constraints (notnull))
            (:file_modes :desc "permission mode bits for the file"
                         :type varchar
                         :length 10
                         :constraints (notnull)))
           (constraints
            (primary :keys (:file_path))
            (foreign :ref outlines
                     :keys (:outline_hash)
                     :parent-keys (:outline_hash)
                     :on-delete cascade
                     :cardinality many-to-one)))

          (headlines
           (desc "Each row stores one headline in a given org outline.")
           (columns
            ,(headline-id-col)
            ,(outline-hash-col "headline" t)
            (:headline_text :desc ("raw text of the headline"
                                   "without leading stars or tags")
                            :properties (:raw-value)
                            :type text
                            :constraints (notnull))
            (:keyword :desc "the TODO state keyword"
                      :properties (:todo-keyword)
                      :type text)
            (:effort :desc "the value of the `Effort` property in minutes"
                     :type integer)
            (:priority :desc "character value of the priority"
                       :properties (:priority)
                       :type text)
            (:stats_cookie_type :desc ("type of the statistics cookie (the"
                                       "`[n/d]` or `[p%]` at the end of some"
                                       "headlines)")
                                :type enum
                                :allowed (fraction percent))
            (:stats_cookie_value :desc "value of the statistics cookie (between 0 and 1)"
                                 :type real)
            (:is_archived :desc "TRUE if the headline has an ARCHIVE tag"
                          :properties (:archivedp)
                          :type boolean
                          :constraints (notnull))
            (:is_commented :desc "TRUE if the headline has a COMMENT keyword"
                           :properties (:commentedp)
                           :type boolean
                           :constraints (notnull))
            (:content :desc "the headline contents (everything after the planning entries, property-drawer, and/or logbook)"
                      :type text))
           (constraints
            (primary :keys (:headline_id))
            (foreign :ref outlines
                     :keys (:outline_hash)
                     :parent-keys (:outline_hash)
                     :on-delete cascade
                     :cardinality many-or-none-to-one)))

          (headline_closures
           (desc "Each row stores the ancestor and depth of a headline"
                 "relationship. All headlines will have a 0-depth entry in which"
                 "`parent_id` and `headline_id` are equal.")
           (columns
            ,(headline-id-col)
            (:parent_id :desc "id of this headline's parent"
                        :type integer)
            (:depth :desc "levels between this headline and the referred parent"
                    :type integer))
           (constraints
            (primary :keys (:headline_id :parent_id))
            (foreign :ref headlines
                     :keys (:headline_id)
                     :parent-keys (:headline_id)
                     :on-delete cascade
                     :cardinality many-to-one)
            (foreign :ref headlines
                     :keys (:parent_id)
                     :parent-keys (:headline_id)
                     :cardinality many-to-one)))

          (timestamps
           (desc "Each row stores one timestamp. Any timestamps in this"
                 "table that are not referenced in other tables are part of the"
                 "headlines's contents (the part after the logbook).")
           (columns
            ,(timestamp-id-col)
            ,(headline-id-col "timestamp" t)
            (:raw_value :desc "text representation of this timestamp"
                        :properties (:raw-value)
                        :type text
                        :constraints (notnull))
            (:is_active :desc "true if the timestamp is active"
                        :properties (:type)
                        :type boolean
                        :constraints (notnull))
            (:time_start :desc "the start time (or only time) of this timestamp"
                         :properties (:year-start :month-start :day-start
                                                  :hour-start :minute-start)
                         :type integer
                         :constraints (notnull))
            (:time_end :desc "the end time of this timestamp"
                       :properties (:year-end :month-end :day-end :hour-end
                                              :minute-end)
                       :type integer)
            (:start_is_long :desc ("true if the start time is in long format"
                                   "(eg `[YYYY-MM-DD DOW HH:MM]` vs"
                                   "`[YYYY-MM-DD DOW]`)")
                            :type boolean
                            :constraints (notnull))
            (:end_is_long :desc ("true if the end time is in long format"
                                 "(see `start_is_long`)")
                          :type boolean))
           (constraints
            (primary :keys (:timestamp_id))
            (foreign :ref headlines
                     :keys (:headline_id)
                     :parent-keys (:headline_id)
                     :on-delete cascade
                     :cardinality many-or-none-to-one)))

          (timestamp_warnings
           (desc "Each row stores the warning component for a timestamp.")
           (columns
            ,(timestamp-id-col "warning")
            (:warning_value :desc "shift of this warning"
                            :properties (:warning-value)
                            :type integer)
            (:warning_unit :desc "unit of this warning"
                           :properties (:warning-unit)
                           :type enum
                           :allowed ,modifier-allowed-units)
            (:warning_type :desc "type of this warning"
                           :properties (:warning-type)
                           :type enum
                           :allowed (all first)))
           (constraints
            (primary :keys (:timestamp_id))
            (foreign :ref timestamps
                     :keys (:timestamp_id)
                     :parent-keys (:timestamp_id)
                     :on-delete cascade
                     :cardinality one-or-none-to-one)))
          
          (timestamp_repeaters
           (desc "Each row stores the repeater component for a timestamp.")
           (columns
            ,(timestamp-id-col "repeater")
            (:repeater_value :desc "shift of this repeater"
                             :properties (:repeater-value)
                             :type integer)
            (:repeater_unit :desc "unit of this repeater"
                            :properties (:repeater-unit)
                            :type enum
                            :allowed ,modifier-allowed-units)
            (:repeater_type :desc "type of this repeater"
                            :type enum
                            :properties (:repeater-type)
                            :allowed (catch-up restart cumulate)))
           (constraints
            (primary :keys (:timestamp_id))
            (foreign :ref timestamps
                     :keys (:timestamp_id)
                     :parent-keys (:timestamp_id)
                     :on-delete cascade
                     :cardinality one-or-none-to-one)))

          (planning_entries
           (desc "Each row denotes a timestamp which is a planning entry"
                 "(eg `DEADLINE`, `SCHEDULED`, or `CLOSED`).")
           (columns
            ,(timestamp-id-col "planning entry" t)
            (:planning_type :desc "the type of this planning entry"
                            :type enum
                            :length 9
                            :allowed (closed scheduled deadline)))
           (constraints
            (primary :keys (:timestamp_id))
            (foreign :ref timestamps
                     :keys (:timestamp_id)
                     :parent-keys (:timestamp_id)
                     :on-delete cascade
                     :cardinality one-or-none-to-one)))

          (file_tags
           (desc "Each row stores one tag denoted by the `#+FILETAGS` keyword")
           (columns
            ,(outline-hash-col "tag" t)
            ,tag-col)
           (constraints
            (primary :keys (:outline_hash :tag))
            (foreign :ref outlines
                     :keys (:outline_hash)
                     :parent-keys (:outline_hash)
                     :on-delete cascade
                     :cardinality many-or-none-to-one)))

          (headline_tags
           (desc "Each row stores one tag attached to a headline. This includes"
                 "tags actively attached to a headlines as well as those in the"
                 "`ARCHIVE_ITAGS` property within archive files. The"
                 "`is_inherited` field will only be TRUE for the latter.")
           (columns
            ,(headline-id-col "tag")
            ,tag-col
            (:is_inherited :desc "TRUE if this tag is from the `ARCHIVE_ITAGS` property"
                           :type boolean
                           :constraints (notnull)))
           (constraints
            (primary :keys (:headline_id :tag :is_inherited))
            (foreign :ref headlines
                     :keys (:headline_id)
                     :parent-keys (:headline_id)
                     :on-delete cascade
                     :cardinality many-or-none-to-one)))

          (properties
           (desc "Each row stores one property. Note this includes properties"
                 "under headlines as well as properties defined at the"
                 "file-level using `#+PROPERTY`.")
           (columns
            ,(outline-hash-col "property" t)
            ,property-id-col
            (:key_text :desc "this property's key"
                       :properties (:key)
                       :type text
                       :constraints (notnull))
            (:val_text :desc "this property's value"
                       :properties (:value)
                       :type text
                       :constraints (notnull)))
           (constraints
            (primary :keys (:property_id))
            (foreign :ref outlines
                     :keys (:outline_hash)
                     :parent-keys (:outline_hash)
                     :on-delete cascade
                     :cardinality many-or-none-to-one)))

          (headline_properties
           (desc "Each row stores a property under a headline.")
           (columns
            ,(headline-id-col "property" t)
            ,property-id-col)
           (constraints
            (primary :keys (:property_id))
            (foreign :ref properties
                     :keys (:property_id)
                     :parent-keys (:property_id)
                     :cardinality one-or-none-to-one)
                     ;; :on-delete cascade)
            (foreign :ref headlines
                     :keys (:headline_id)
                     :parent-keys (:headline_id)
                     :on-delete cascade
                     :cardinality many-or-none-to-one)))
          
          (clocks
           (desc "Each row stores one clock entry.")
           (columns
            (:clock_id :desc "id of this clock"
                       :type integer)
            ,(headline-id-col "clock" t)
            (:time_start :desc "timestamp for the start of this clock"
                         :type integer)
            (:time_end :desc "timestamp for the end of this clock"
                       :type integer)
            (:clock_note :desc "the note entry beneath this clock"
                         :type text))
           (constraints
            (primary :keys (:clock_id))
            (foreign :ref headlines
                     :keys (:headline_id)
                     :parent-keys (:headline_id)
                     :on-delete cascade
                     :cardinality many-or-none-to-one)))

          (logbook_entries
           (desc "Each row stores one logbook entry (except for clocks). Note"
                 "that the possible values of `entry_type` depend on"
                 "`org-log-note-headlines`. By default, the possible types are:"
                 "`reschedule`, `delschedule`, `redeadline`, `deldeadline`,"
                 "`state`, `done`, `note`, and `refile`. Note that while `clock-out`"
                 "is also a default type in `org-log-note-headings` but this"
                 "is already covered by the `clock_note` column in the `clocks`"
                 "table and thus won't be stored in this table.")
           (columns
            ,(entry-id-col)
            ,(headline-id-col "logbook entry" t)
            (:entry_type :desc "type of this entry"
                         :type text)
            (:time_logged :desc "timestamp for when this entry was taken"
                          :type integer)
            (:header :desc "the first line of this entry (usually standardized)"
                     :type text)
            (:note :desc "the text underneath the header of this entry "
                   :type text))
           (constraints
            (primary :keys (:entry_id))
            (foreign :ref headlines
                     :keys (:headline_id)
                     :parent-keys (:headline_id)
                     :on-delete cascade
                     :cardinality many-or-none-to-one)))

          (state_changes
           (desc "Each row stores the new and old states for logbook entries"
                 "of type `state`.")
           (columns
            ,(entry-id-col "state change")
            (:state_old :desc "former todo state keyword"
                        :type text
                        :constraints (notnull))
            (:state_new :desc "updated todo state keyword"
                        :type text
                        :constraints (notnull)))
           (constraints
            (primary :keys (:entry_id))
            (foreign :ref logbook_entries
                     :keys (:entry_id)
                     :parent-keys (:entry_id)
                     :on-delete cascade
                     :cardinality one-or-none-to-one)))

          (planning_changes
           (desc "Each row stores the former timestamp for logbook entries with"
                 "type `reschedule`, `delschedule`, `redeadline`, and"
                 "`deldeadline`.")
           (columns
            ,(entry-id-col "planning change")
            (:timestamp_id :desc "id of the former timestamp"
                           :type integer
                           :constraints (notnull)))
           (constraints
            (primary :keys (:entry_id))
            (foreign :ref timestamps
                     :keys (:timestamp_id)
                     :parent-keys (:timestamp_id)
                     :cardinality one-or-none-to-one)
                     ;; :on-delete cascade)
            (foreign :ref logbook_entries
                     :keys (:entry_id)
                     :parent-keys (:entry_id)
                     :on-delete cascade
                     :cardinality one-or-none-to-one)))

          (links
           (desc "Each row stores one link.")
           (columns
            (:link_id :desc "id of this link"
                      :type integer)
            ,(headline-id-col "link" t)
            (:link_path :desc "target of this link (eg url, file path, etc)"
                        :properties (:path)
                        :type text
                        :constraints (notnull))
            (:link_text :desc "text of this link that isn't part of the path"
                        :type text)
            (:link_type :desc "type of this link (eg http, mu4e, file, etc)"
                        :properties (:type)
                        :type text
                        :constraints (notnull)))
           (constraints
            (primary :keys (:link_id))
            (foreign :ref headlines
                     :keys (:headline_id)
                     :parent-keys (:headline_id)
                     :on-delete cascade
                     :cardinality many-or-none-to-one))))
        "Org-SQL database tables represented as an alist"))))

(eval-and-compile
  (defconst org-sql-table-names
    (--map (symbol-name (car it)) org-sql--table-alist)
    "The names of all tables in the org-sql database."))

;; TODO what about the windows users?
(defconst org-sql--mysql-exe "mysql"
  "The mysql client command.")

(defconst org-sql--psql-exe "psql"
  "The postgres client command.")

(defconst org-sql--sqlite-exe "sqlite3"
  "The sqlite client command.")

(defconst org-sql--sqlserver-exe "sqlcmd"
  "The sqlserver client command.")

;;;
;;; CUSTOMIZATION OPTIONS
;;;

(defgroup org-sql nil
  "Org mode SQL backend options."
  :tag "Org SQL"
  :group 'org)

;; TODO add sqlite pragma (synchronous and journalmode)

;; I could use `define-widget' here but it doesn't seem to work with a type this
;; complex (it lets me configure the type properly but then says MISCONFIGURED
;; when I come back, which makes no sense). On the bright side, this is much
;; more transparent; just make the repetitive bits of the type using a bunch of
;; functions
(eval-and-compile
  (cl-flet*
      ((mk-option
        (tag key value-type &optional default)
        (let ((value (if default `(,value-type :value ,default) value-type)))
          `(list :inline t :tag ,tag (const ,key) ,value)))
       (mk-port
        (n)
        (mk-option "Port number" :port 'integer n))
       (mk-db-choice
        (tag sym required-keys &optional optional-keys)
        `(cons :tag ,tag (const ,sym)
               ,(if optional-keys
                    `(list :tag "Required keys" :offset 2 ,@required-keys
                           (set :tag "Optional keys" :inline t ,@optional-keys))
                  `(list :tag "Required keys" :offset 2 ,@required-keys)))))
    (let* ((database (mk-option "Database name" :database 'string "org_sql"))
           (hostname (mk-option "Hostname/IP" :hostname 'string))
           (username (mk-option "Username" :username 'string "org_sql"))
           (password (mk-option "Password" :password 'string "org_sql@13243546"))
           (schema (mk-option "Namespace (aka schema)" :schema 'string "org_sql"))
           (args (mk-option "Additional args" :args '(repeat string)))
           (env (mk-option "Environmental Vars" :env '(repeat (list string string))))
           (def (mk-option "Defaults File" :defaults-file '(file :value "~/my.ini")))
           (defx (mk-option "Defaults Extra File" :defaults-extra-file
                            '(file :value "~/my-extra.ini")))
           (sfile (mk-option "Service File" :service-file
                             '(file :value "~/.pg_service.conf")))
           (pfile (mk-option "Pass File" :pass-file '(file :value "~/.pgpass")))
           (path (mk-option "Database path" :path '(string :value "~/org-sql.db")))
           (unlogged (mk-option "Unlogged Tables" :unlogged 'boolean))
           (server (mk-option "Server instance" :server
                              '(string :value "tcp:server\\instance_name,1433"))))
      (defcustom org-sql-db-config
        (list 'sqlite :path (expand-file-name "org-sql.db" org-directory))
        "Configuration for the org-sql database.

This is a list like (DB-TYPE [KEY VAL] [[KEY VAL] ...]).

DB-TYPE is a symbol for the database to use and one of:
- `mysql': MySQL/MariaDB (requires the 'mysql' executable)
- `postgres': PostgresSQL (requires the 'psql' executable)
- `sqlite': SQLite (requires the 'sqlite3' executable)
- `sqlserver': SQL-Server (requires the 'sqlcmd' executable)

KEY and VAL form a plist and allowed combinations depend on
DB-TYPE.

Each database type requires one key to specify which database to
use. For SQLite, this key is `:path' and its value is a path to
the SQLite database file to use (or create if it doesn't exist).
For all others, this key is `:database' and specifies the name of
the database on the server (perhaps local) to which to connect.

All other keys are optional.

The following additional keys are database-specific:

SQLite
- none

Postgres
- `:hostname': (string) the hostname with which to connect
  (corresponds to the `-h' flag)
- `:port': (integer) connection port (corresponds to the
  `-p' flag)
- `:username': (string) the username to use (corresponds to the
  `-U' flag)
- `:password': (string) the password to use (corresponds to the
  `PGPASSWORD' environmental variable) NOTE use the `:pass-file'
  or `:service-file' if you don't want to hardcode your password
- `:pass-file': (string) value to be supplied to the `PGPASSFILE'
  environment variable
- `:service-file': (string) to be supplied to the `PGSERVICEFILE'
  environment variable
- `:schema' (string) the schema to use
- `:args': (list of strings) arbitrary command line arguments
  sent to `psql'
- `:env': (list of lists with strings like (ENV VAR))
  environmental variables with which `psql' will run
- `:unlogged' (boolean) set to t to use unlogged tables and
   potentially gain a huge speed improvement.

MySQL/MariaDB
- `:hostname': (string) the hostname with which to connect
  (corresponds to the `-h' flag)
- `:port': (integer) connection port (corresponds to the
  `-P' flag)
- `:username': (string) the username to use (corresponds to the
  `-U' flag)
- `:password': (string) the password to use (corresponds to the
  `-p' flag) NOTE use the `:defaults-file' or
  `:defaults-extra-file' if you don't want to hardcode your
  password
- `:defaults-file' (string) path to the be supplied to the
  `--defaults-file' flag
- `:defaults-extra-file' (string): path to be supplied to the
  `--defaults-extra-file' flag
- `:args': (list of strings) arbitrary command line arguments
  sent to `mysql'
- `:env': (list of lists with strings like (ENV VAR))
  environmental variables with which `mysql' will run

SQL-Server
- `:server': (string) the server instance (corresponds to the
  `-S' flag)
- `:username': (string) the username to use (corresponds to the
  `-U' flag)
- `:password': (string) the password to use (corresponds to the
  `-P' flag) NOTE use the `:env' key to specify `SQLCMDINI'
  which in turn can set the `SQLCMDPASSWORD' variable outside
  emacs if you don't wish to hardcode this
- `:schema' (string) the schema to use
- `:args': (list of strings) arbitrary command line arguments
   sent to `sqlcmd'
- `:env': (list of lists with strings like (ENV VAR))
  environmental variables with which `sqlcmd' will run"
        :type `(choice
                ,(mk-db-choice "MySQL/MariaDB" 'mysql `(,database)
                               `(,hostname
                                 ,(mk-port 3306)
                                 ,username
                                 ,password
                                 ,def
                                 ,defx
                                 ,args
                                 ,env))
                ,(mk-db-choice "PostgreSQL" 'postgres `(,database)
                               `(,hostname
                                 ,(mk-port 5432)
                                 ,username
                                 ,password
                                 ,schema
                                 ,pfile
                                 ,sfile
                                 ,unlogged
                                 ,args
                                 ,env))
                ,(mk-db-choice "SQLite" 'sqlite `(,path))
                ,(mk-db-choice "MS SQL-Server" 'sqlserver `(,database)
                               `(,server
                                 ,username
                                 ,password
                                 ,schema
                                 ,args
                                 ,env)))
        :group 'org-sql))))

;; (defcustom org-sql-log-note-headings-overrides nil
;;   "Alist of `org-log-note-headings' for specific files.
;; The car of each cell is the file path, and the cdr is another
;; alist like `org-log-note-headings' that will be used when
;; processing that file. This is useful if some files were created
;; with different patterns for their logbooks as Org-mode itself
;; does not provide any options to control this besides the global
;; `org-log-note-headings'."
;;   :type '(alist :key-type string
;;                 :value-type (alist :key-type symbol
;;                                    :value-type string))
;;   :group 'org-sql)

(defcustom org-sql-async nil
  "When t database updates will be asynchronous.
All admin operations will still be synchronous. Note that this
only spawns a process for the database client command; all
processing the needs to be performed on org files (parsing to
make the INSERT statements) will still be synchronous."
  :type 'boolean
  :group 'org-sql)

(defcustom org-sql-files nil
  "A list of org files or directories to put into sql database.
Any directories in this list imply that all files within the
directly are added. Only files ending in .org or .org_archive are
considered. See function `org-sql-files'."
  :type '(repeat :tag "List of files and directories" file)
  :group 'org-sql)

(eval-and-compile
  (let ((hook '(repeat
                (choice
                 (cons :tag "SQL command" (const sql) string)
                 (cons :tag "SQL command (appended)" (const sql+) string)
                 (cons :tag "SQL file" (const file) file)
                 (cons :tag "SQL file (appended)" (const file+) file)))))
    (defcustom org-sql-post-init-hooks nil
      "Hooks to run after `org-sql-init-db'.

This is a list of 2-membered lists like (SYM STRING) called
'hooks'. The SYM of each hook is a symbol like `sql', `file',
`sql+', or `file+'. If `sql', the second member is a string
representing a SQL statement which will be executed. If 'file',
the second member is a path to a SQL file that will be executed.
The `+' suffix signifies that the SQL string or file of the hook
will be appended to the transaction sent by `org-sql-db-init' (eg
inside the \"BEGIN;...COMMIT;\" block).

These hooks are generally useful for running arbitrary SQL
statements after `org-sql' database operations. This could
include setting up additional indexes on tables, adding triggers,
defining and executing procedures, etc. See also
`org-sql-post-push-hooks', `org-sql-post-clear-hooks', and
`org-sql-pre-reset-hooks'."
      :type hook
      :group 'org-sql)

    (defcustom org-sql-post-push-hooks nil
      "Hooks to run after `org-sql-push-to-db'.

This works analogously to `org-sql-post-init-hooks'."
      :type hook
      :group 'org-sql)

    (defcustom org-sql-post-clear-hooks nil
      "Hooks to run after `org-sql-clear-db'.

This works analogously to `org-sql-post-init-hooks'."
      :type hook
      :group 'org-sql)

    (defcustom org-sql-pre-reset-hooks nil
      "Hooks to run before `org-sql-reset-db'.

This works analogously to `org-sql-post-init-hooks'."
      :type hook
      :group 'org-sql)))

(defcustom org-sql-excluded-properties nil
  "List of properties to exclude from the database.
To exclude all set to 'all' instead of a list of strings."
  :type '(choice
          (const "Ignore All" all)
          (repeat :tag "List of properties to ignore" string))
  :group 'org-sql)

(defcustom org-sql-exclude-inherited-tags nil
  "If t don't include tags in the ARCHIVE_ITAGS property in the database."
  :type 'boolean
  :group 'org-sql)

(defcustom org-sql-excluded-tags nil
  "List of tags to exclude when building the tags table.
To exclude all set to 'all' instead of a list of strings."
  :type '(choice
          (const "Ignore All" all)
          (repeat :tag "List of tags to ignore" string))
  :group 'org-sql)

(defcustom org-sql-excluded-link-types nil
  "List of link types to exclude when building the links table.
Each member should be a string and one of `org-link-types' or
\"file\", \"coderef\", \"custom-id\", \"fuzzy\", or \"id\". See org-element
API documentation or`org-element-link-parser' for details.
To exclude all set to 'all' instead of a list of strings."
  :type '(choice
          (set :tag "List of types to ignore"
               (const :tag "File paths" "file")
               (const :tag "Source code references" "coderef")
               (const :tag "Headline custom IDs" "custom-id")
               (const :tag "Fuzzy target in parse trees" "fuzzy")
               (const :tag "Headline IDs" "id")
               (repeat :tag "Other types to ignore" string))
          (const "Ignore all" all))
  :group 'org-sql)

(defcustom org-sql-excluded-headline-planning-types nil
  "List of headline planning timestamps to exclude in the database.
List members can be ':deadline', ':scheduled', or ':closed'. To
exclude none set to nil."
  :type '(set :tag "List of types to include"
              (const :tag "Deadline Timestamps" :deadline)
              (const :tag "Scheduled Timestamps" :scheduled)
              (const :tag "Closed Timestamps" :closed))
  :group 'org-sql)

(defcustom org-sql-excluded-contents-timestamp-types nil
  "List of timestamp types to exclude from headline content sections.
List members can be the symbols 'active', 'active-range', 'inactive',
or 'inactive-range'. To exclude none set to nil."
  :type '(set :tag "List of types to include"
              (const :tag "Active Timestamps" active)
              (const :tag "Active Timestamp Ranges" active-range)
              (const :tag "Inactive Timestamps" inactive)
              (const :tag "Inactive Timestamp Ranges" inactive-range))
  :group 'org-sql)

;; TODO what if they customize these keys?
(defcustom org-sql-excluded-logbook-types nil
  "List of logbook entry types to exclude from the database.
List members are any of the keys from `org-log-note-headings' with the
exception of 'clock-out' as these are treated as clock-notes (see
`org-sql-exclude-clock-notes'). To include none set to nil."
  :type '(set :tag "List of types to include"
              (const :tag "Clocks" clock)
              (const :tag "Closing notes" done)
              (const :tag "State changes" state)
              (const :tag "Notes taken" note)
              (const :tag "Rescheduled tasks" reschedule)
              (const :tag "Unscheduled tasks" delschedule)
              (const :tag "Redeadlined tasks" redeadline)
              (const :tag "Undeadlined tasks" deldeadline)
              (const :tag "Refiled tasks" refile))
  :group 'org-sql)

(defcustom org-sql-exclude-clock-notes nil
  "Set to t to store clock notes in the database.
Setting `org-sql-store-clocks' to nil will cause this variable to be
ignored."
  :type 'boolean
  :group 'org-sql)

(defcustom org-sql-exclude-headline-predicate nil
  "A function that is called for each headline.
If it returns t, the current headline is to be excluded. Note
that excluding a headline will also exclude its children."
  :type 'function
  :group 'org-sql)

(defcustom org-sql-debug nil
  "Set to t to enable high-level debugging of SQL transactions."
  :type 'boolean
  :group 'org-sql)

;;;
;;; STATELESS FUNCTIONS
;;;

;;; compile/macro checking

;; case selection statements for sql mode and type

(defun org-sql--sets-equal (list1 list2 &rest args)
  "Return t if LIST1 and LIST2 are equal via set logic.
Either list may contain repeats, in which case nil is returned.
ARGS is a list of additional arguments to pass to `cl-subsetp'."
  (and (equal (length list1) (length list2))
       (apply #'cl-subsetp list1 list2 args)
       (apply #'cl-subsetp list2 list1 args)))

(defmacro org-sql--case-type (type &rest alist-forms)
  "Execute one of ALIST-FORMS depending on TYPE.
A compile error will be triggered if TYPE is invalid."
  (declare (indent 1))
  (-let (((&alist 'boolean 'char 'enum 'integer 'real 'text 'varchar)
          (--splice (listp (car it))
                    (-let (((keys . form) it))
                      (--map (cons it form) keys))
                    alist-forms)))
    (when (-any? #'null (list boolean char enum real integer text varchar))
      (error "Must provide form for all types"))
    `(cl-case ,type
       (boolean ,@boolean)
       (char ,@char)
       (enum ,@enum)
       (integer ,@integer)
       (real ,@real)
       (text ,@text)
       (varchar ,@varchar)
       (t (error "Invalid type: %s" ,type)))))

(defmacro org-sql--case-mode (config &rest alist-forms)
  "Execute one of ALIST-FORMS depending on CONFIG.
A compile error will be triggered if the car of CONFIG (eg the
database to be used) is invalid."
  (declare (indent 1))
  (-let (((keys &as &alist 'mysql 'postgres 'sqlserver 'sqlite)
          (--splice (listp (car it))
                    (-let (((keys . form) it))
                      (--map (cons it form) keys))
                    alist-forms)))
    (when (-any? #'null (list mysql postgres sqlserver sqlite))
      (error "Must provide form for all modes"))
    (-some->> (-difference (-map #'car keys) '(mysql postgres sqlserver sqlite))
      (-map #'symbol-name)
      (s-join ",")
      (format "Unknown forms: %s")
      (error))
    `(cl-case (car ,config)
       (mysql ,@mysql)
       (postgres ,@postgres)
       (sqlite ,@sqlite)
       (sqlserver ,@sqlserver)
       (t (error "Invalid mode: %s" (car ,config))))))

;; ensure integrity of the table alist

(eval-when-compile
  (defun org-sql--table-alist-has-valid-keys (table)
    "Verify that TABLE has valid keys in its table constraints."
    (-let* (((tbl-name . (&alist 'constraints 'columns)) table)
            (column-names (-map #'car columns)))
      (cl-flet
          ((get-keys
            (constraint)
            (-let (((type . (&plist :keys)) constraint))
              (cons type keys)))
           (test-keys
            (type keys)
            (-some->> (-difference keys column-names)
              (-map #'symbol-name)
              (s-join ", ")
              (error "Mismatched %s keys in table '%s': %s" type tbl-name))))
        (--> (--filter (memq (car it) '(primary foreign)) constraints)
             (-map #'get-keys it)
             (--each it (test-keys (car it) (cdr it)))))))

  (defun org-sql--table-alist-has-valid-parent-keys (table)
    "Verify that TABLE has valid keys in its table foreign constraints."
    (cl-flet
        ((is-valid
          (foreign-meta tbl-name)
          (-let* (((&plist :parent-keys :ref) foreign-meta)
                  (parent-meta (alist-get ref org-sql--table-alist))
                  (parent-columns (-map #'car (alist-get 'columns parent-meta)))
                  (parent-primary (--> (alist-get 'constraints parent-meta)
                                       (alist-get 'primary it)
                                       (plist-get it :keys))))
            ;; any parent keys must have corresponding columns in the referred
            ;; table
            (-some->> (-difference parent-keys parent-columns)
              (-map #'symbol-name)
              (s-join ", ")
              (error "Mismatched foreign keys between %s and %s: %s" tbl-name ref)))))
      (-let* (((tbl-name . meta) table)
              (foreign (->> (alist-get 'constraints meta)
                            (--filter (eq (car it) 'foreign))
                            (-map #'cdr))))
        (--each foreign (is-valid it tbl-name)))))

  (-each org-sql--table-alist #'org-sql--table-alist-has-valid-keys)
  (-each org-sql--table-alist #'org-sql--table-alist-has-valid-parent-keys))

;; ensure table-alist functions are given the right input

(eval-when-compile
  (defun org-sql--table-get-column-names (tbl-name)
    "Return a list of columns for TBL-NAME.
The columns are retrieved from `org-sql--table-alist'."
    (-if-let (columns (->> org-sql--table-alist
                           (alist-get tbl-name)
                           (alist-get 'columns)))
        (-map #'car columns)
      (error "Invalid table name: %s" tbl-name)))

  (defun org-sql--table-check-columns (tbl-name columns)
    (let ((valid-columns (org-sql--table-get-column-names tbl-name)))
      (-some->> (-difference valid-columns columns)
        (error "Keys not given for table %s: %s" tbl-name))
      (-some->> (-difference columns valid-columns)
        (error "Keys not valid for table %s: %s" tbl-name))))

  (defun org-sql--table-check-columns-all (tbl-name plist)
    "Test if keys in PLIST are valid column names for TBL-NAME.
All column keys must be in PLIST."
    (org-sql--table-check-columns tbl-name (-slice plist 0 nil 2)))

  (defun org-sql--table-order-columns (tbl-name plist)
    "Order the keys in PLIST according to the columns in TBL-NAME."
    (org-sql--table-check-columns-all tbl-name plist)
    (let ((order (->> (alist-get tbl-name org-sql--table-alist)
                      (alist-get 'columns)
                      (--map-indexed (cons (car it) it-index)))))
      (->> (-partition 2 plist)
           (--map (cons (alist-get (car it) order) (cadr it)))
           (--sort (< (car it) (car other)))
           (-map #'cdr)))))

;;; data structure functions

;; `org-sql-db-config' helper functions

(defmacro org-sql--with-config-keys (keys config &rest body)
  "Execute BODY with keys bound to KEYS from CONFIG.
CONFIG is the `org-sql-db-config' list and KEYS are a list of
keys/symbols like those from the &plist switch from `-let'."
  (declare (indent 2))
  `(-let (((&plist ,@keys) (cdr ,config)))
     ,@body))

(defun org-sql--get-config-key (key config)
  "Return the value of KEY from CONFIG.
CONFIG is a list like `org-sql-db-list'."
  (plist-get (cdr config) key))

;; bulk insert alist constructors

(defconst org-sql--empty-insert-alist
  (--map (list (car it)) org-sql--table-alist)
  "Empty bulk insert alist to initialize accumulator.")

(defmacro org-sql--insert-alist-add (acc tbl-name &rest plist)
  "Add a new row list for TBL-NAME to ACC.
PLIST is a property list of the columns and values to insert.
WARNING: this function looks like a pure function but it
intentionally has side effects for performance reasons."
  (declare (indent 2))
  (let ((ordered-values (org-sql--table-order-columns tbl-name plist)))
    `(let ((tbl (assq ',tbl-name (plist-get ,acc :inserts))))
       (setcdr tbl (cons (list ,@ordered-values) (cdr tbl)))
       ,acc)))

;; external state data structures

(defmacro org-sql--map-plist (key form plist)
  "Return PLIST modified with FORM applied to KEY's value.
WARNING: this function will modify PLIST in place."
  (declare (indent 1))
  `(let ((it (plist-get ,plist ,key)))
     (plist-put ,plist ,key ,form)))

(defun org-sql--replace-in-plist (key rep plist)
  "Return PLIST with value of KEY replaced by REP."
  (->> (-partition 2 plist)
       (--map-when (eq (car it) key) (list (car it) rep))
       (-flatten-n 1)))

(defun org-sql--top-section-get-binary-startup (positive negative init top-section)
  "Return startup configuration from TOP-SECTION.
Only keyword nodes with a key of \"STARTUP\" will be considered.
POSITIVE and NEGATIVE are values that represent the states of the
keyword; if it's value is POSITIVE t will be returned, and if it
is NEGATIVE nil will be returned. If no startup keywords are
found, return INIT. If multiple keywords are present, use the
last one."
  (->> top-section
       (--filter (and (org-ml-is-type 'keyword it)
                      (equal "STARTUP" (org-ml-get-property :key it))))
       (--reduce-from (let ((v (org-ml-get-property :value it)))
                        (cond
                         ((equal v positive) t)
                         ((equal v negative) nil)
                         (t acc)))
                      init)))

(defun org-sql--top-section-get-log-into-drawer (top-section log-into-drawer)
  "Return the log-note-headines startup configuration for TOP-SECTION.
If not present, return the current value of LOG-INTO-DRAWER."
  (org-sql--top-section-get-binary-startup
   "logdrawer" "nologdrawer" log-into-drawer top-section))

(defun org-sql--top-section-get-clock-out-notes (top-section clock-out-notes)
  "Return the clock-out-notes startup configuration for TOP-SECTION.
If not present, return the current value of CLOCK-OUT-NOTES."
  (org-sql--top-section-get-binary-startup
   "lognoteclock-out" "nolognoteclock-out" clock-out-notes top-section))

(defun org-sql--to-outline-config (outline-hash paths-with-attributes
                                                log-note-headings todo-keywords
                                                lb-config size lines tree)
  "Return a plist representing the state of an org buffer.
The plist will include:
- `:outline-hash': the hash of this org file (given by OUTLINE-HASH)
- `:paths-with-attributes': a list of lists where the car is a
  file path and the cdr is a list of attributes given by
  `file-attributes' (given by PATHS-WITH-ATTRIBUTES)
- `:size': the size of the org tree (given by SIZE)
- `:length': the number of lines of the org tree (given by
  LENGTH)
- `:top-section': the org-element TREE representation of this
  org-file's top section before the first headline
- `:headlines': a list of org-element TREE headlines in this org
  file
- `:lb-config' the same list as that supplied to
  `org-ml-headline-get-supercontents' (based on LB-CONFIG)
- `:log-note-matcher': a list of log-note-matchers for this org
  file as returned by `org-sql--build-log-note-heading-matchers'
  (which depends on TODO-KEYWORDS and LOG-NOTE-HEADINGS)"
  (let* ((children (org-ml-get-children tree))
         (top-section (-some-> (assq 'section children) (org-ml-get-children))))
    (list :outline-hash outline-hash
          :paths-with-attributes paths-with-attributes
          :size size
          :lines lines
          :top-section top-section
          :headlines (if top-section (cdr children) children)
          :lb-config (->> lb-config
                          (org-sql--map-plist :log-into-drawer
                            (org-sql--top-section-get-log-into-drawer top-section it))
                          (org-sql--map-plist :clock-out-notes
                            (org-sql--top-section-get-clock-out-notes top-section it)))
          :log-note-matcher (org-sql--build-log-note-heading-matchers
                             log-note-headings todo-keywords))))

(defun org-sql--headline-get-log-into-drawer (log-into-drawer headline)
  "Return the log-into-drawer configuration for HEADLINE.
If not present, return the current value of LOG-INTO-DRAWER."
  (-if-let (v (org-ml-headline-get-node-property "LOG_INTO_DRAWER" headline))
    (cond
     ((equal v "t") t)
     ((equal v "nil") nil)
     (t v))
    log-into-drawer))

(defun org-sql--headline-get-clock-into-drawer (clock-into-drawer headline)
  "Return the clock-into-drawer configuration for HEADLINE.
If not present, return the current value of CLOCK-INTO-DRAWER."
  (-if-let (v (org-ml-headline-get-node-property "CLOCK_INTO_DRAWER" headline))
    (cond
     ((equal v "t") t)
     ((equal v "nil") nil)
     ((s-matches-p "[0-9]+" v) (string-to-number v))
     (t v))
    clock-into-drawer))

(defun org-sql--headline-update-supercontents-config (config headline)
  "Return supercontents CONFIG updated according to HEADLINE."
  (->> config
       (org-sql--map-plist :log-into-drawer
         (org-sql--headline-get-log-into-drawer it headline))
       (org-sql--map-plist :clock-into-drawer
         (org-sql--headline-get-clock-into-drawer it headline))))

(defun org-sql--to-hstate (headline-id outline-config headline)
  "Return new hstate set from OUTLINE-CONFIG and HEADLINE.

An HSTATE represents the current headline being processed and
will include the follwing keys/values:
- `:outline-hash' the path to the current file being processed
- `:lb-config' the supercontents config plist
- `:log-note-matcher': a list of log-note-matchers for this org
  file as returned by `org-sql--build-log-note-heading-matchers'
- `:headline' the current headline node.
- `:parent-ids': the ids of this headline's parents (to which
  HEADLINE-ID will be set as the sole member)."
  (-let (((&plist :outline-hash h :lb-config c :log-note-matcher m) outline-config))
    (list :outline-hash h
          :lb-config (org-sql--headline-update-supercontents-config c headline)
          :log-note-matcher m
          :headline headline
          :parent-ids (list headline-id))))

(defun org-sql--update-hstate (headline-id hstate headline)
  "Return a new HSTATE updated with information from HEADLINE.
Only the :lb-config, :headline, and :parent-ids keys will be
changed (the latter will be appended to the front of the current
:parent-ids with HEADLINE-ID)."
  ;; TODO plist-put won't work here
  (->> (org-sql--replace-in-plist :headline headline hstate)
       (org-sql--map-plist :lb-config
         (org-sql--headline-update-supercontents-config it headline))
       (org-sql--map-plist :parent-ids (cons headline-id it))))

;;; SQL string parsing functions

(defun org-sql--parse-output-to-list (config out)
  "Return OUT as a LIST.
OUT is assumed to be tabular output from one of the SQL client
command line utilities. CONFIG is a list like `org-sql-db-config'
and contains the information for how to parse the output. The
returned list will be a list of lists, with each list being the
values of one row from OUT."
  (unless (equal out "")
    (let ((sep (org-sql--case-mode config
                 (mysql "\t")
                 ((postgres sqlite sqlserver) "|"))))
      (->> (s-trim out)
           (s-split "\n")
           (--map (-map #'s-trim (s-split sep it)))))))

(defun org-sql--parse-output-to-plist (config cols out)
  "Parse OUT to a plist.
This will perform `org-sql--parse-output-to-list' on OUT using
CONFIG and intersperse COLS (a list of keywords representing the
column names) in each row of the returned list, effectively
turning the return value from a list of lists to a list of
plists (where the keys are the column names for the rows)."
  (-some->> (org-sql--parse-output-to-list config out)
    (--map (-interleave cols it))))

;;; org-element/org-ml wrapper functions

(defun org-sql--headline-get-archive-itags (headline)
  "Return archive itags from HEADLINE or nil if none."
  (unless org-sql-exclude-inherited-tags
    (-some-> (org-ml-headline-get-node-property "ARCHIVE_ITAGS" headline)
      (split-string))))

(defun org-sql--headline-get-tags (headline)
  "Return list of tags from HEADLINE."
  (->> (org-ml-get-property :tags headline)
       (-map #'substring-no-properties)))

(defun org-sql--split-paragraph (paragraph)
  "Split PARAGRAPH by first line-break node."
  (let ((children (org-ml-get-children paragraph)))
    (-if-let (lb-index (--find-index (org-ml-is-type 'line-break it) children))
        (-let* (((head rest*) (-split-at lb-index children))
                ((break . rest) rest*)
                ;; assume begin/end should be the same as contents-begin/end
                (parent (org-ml-get-property :parent (-first-item head)))
                (b1 (org-ml-get-property :begin parent))
                (e1 (org-ml-get-property :begin break))
                (b2 (org-ml-get-property :end break))
                (e2 (org-ml-get-property :end parent))
                (head* (->> (apply #'org-ml-build-paragraph head)
                            (org-ml--set-properties-nocheck
                             (list :begin b1
                                   :contents-begin b1
                                   :end e1
                                   :contents-end e1))))
                (rest* (-some->> rest
                         (apply #'org-ml-build-paragraph)
                         (org-ml--set-properties-nocheck
                          (list :begin b2
                                :contents-begin b2
                                :end e2
                                :contents-end e2)))))
          (if (not rest*) `(nil . ,head*) `(,head* . ,rest*)))
      `(nil . ,paragraph))))

(defun org-sql--item-get-contents (item)
  "Return the children of ITEM that are not items."
  (->> (org-ml-get-children item)
       (--take-while (not (org-ml-is-type 'plain-list it)))))

(defun org-sql--split-item (item)
  "Split the contents of ITEM by the first line break."
  (-let (((first . rest) (org-sql--item-get-contents item)))
    (when first
      (if (not (org-ml-is-type 'paragraph first)) (cons nil rest)
        (-let (((p0 . p1) (org-sql--split-paragraph first)))
          (if (not p0) `(,p1 . ,rest) `(,p0 . (,p1 . ,rest))))))))

;; org-element tree -> logbook entry (see `org-sql--to-entry')

(defun org-sql--build-log-note-regexp-alist (todo-keywords)
  "Return a list of regexps that match placeholders in `org-log-note-headings'.
Each member of list will be like (PLACEHOLDER . REGEXP).
TODO-KEYWORDS is the list of valid todo state keywords for the buffer, and will
be used when evaluating the regexp for the \"%S\" and \"%s\" matchers."
  (cl-flet
      ((format-capture
        (regexp)
        (->> (s-replace-all '(("\\(" . "") ("\\)" . "")) regexp)
             (format "\\(%s\\)"))))
    (let* ((ts-or-todo-regexp (->> (-map #'regexp-quote todo-keywords)
                                   (cons org-ts-regexp-inactive)
                                   (s-join "\\|")
                                   (format-capture)
                                   (format "\"%s\"")))
           (ts-regexp (format-capture org-ts-regexp))
           (ts-ia-regexp (format-capture org-ts-regexp-inactive))
           (keys (-map #'cdr org-sql--log-note-keys)))
      ;; TODO the user/user-full variables have nothing stopping them from
      ;; constraining spaces, in which case this will fail
      (->> (list "\\(.*\\)"
                 "\\(.*\\)"
                 ts-ia-regexp
                 ts-regexp
                 ts-ia-regexp
                 ts-regexp
                 ts-or-todo-regexp
                 ts-or-todo-regexp)
           (--map (format "[[:space:]]*%s[[:space:]]*" it))
           (-zip-pair keys)))))

(defun org-sql--build-log-note-heading-matchers (log-note-headings todo-keywords)
  "Return a list of matchers for LOG-NOTE-HEADINGS.

LOG-NOTE-HEADINGS is an alist like
`org-log-note-headines' (identical if the user has not changed
it). TODO-KEYWORDS is a list of todo state keywords for the current buffer.

Return a list like (TYPE REGEXP (KEYS ...)) where TYPE is the type of the note,
REGEXP is a regular expression matching the header of the note, and KEYS is an
ordered list of keywords from `org-sql--log-note-keys' that correspond to each
capture in REGEXP."
  (cl-labels
      ((reverse-lookup
        (value alist)
        (car (--find (equal (cdr it) value) alist)))
       ;; TODO this will fail if the pattern is in the front; a more direct way
       ;; would be to match the pattern directly; see `org-replace-escapes' for
       ;; the regexp that is used when replacing
       (unpad-headings
        (heading)
        (org-replace-escapes heading org-sql--log-note-replacements))
       (replace-escapes
        (heading replace-alist)
        (-> (s-replace-regexp "\s+" " " heading)
            (org-replace-escapes replace-alist)))
       (match-keys
        (heading)
        (->> (s-match-strings-all "%[[:alpha:]]" heading)
             (-flatten-n 1)
             (--map (reverse-lookup it org-sql--log-note-keys)))))
    (let* ((log-note-headings* (--remove (equal (car it) "") log-note-headings))
           (regexp-alist (org-sql--build-log-note-regexp-alist todo-keywords))
           (types (-map #'car log-note-headings*))
           (unpadded (--map (unpad-headings (cdr it)) log-note-headings*))
           (regexps (--map (replace-escapes it regexp-alist) unpadded))
           (keys (-map #'match-keys unpadded)))
      (-zip-lists types regexps keys))))

(defun org-sql--match-item-header (hstate header-text)
  "Return a plist with the matched captures for HEADER-TEXT.

HSTATE is a list given by `org-sql--to-hstate'.

The returned list will be a list like (TYPE PLIST) where TYPE is
the matched type of the note based on HEADER-TEXT and PLIST is a
list of captures corresponding to `org-sql--log-note-keys'."
  (-let (((&plist :log-note-matcher) hstate))
    (cl-labels
        ((match-sum
          (regexp i)
          (s-matched-positions-all regexp header-text i))
         (match-header
          (acc cell)
          (if acc acc
            (-let (((type regexp keys) cell))
              (-some->> keys
                (--map-indexed (cons it (match-sum regexp (1+ it-index))))
                (--filter (cdr it))
                (apply #'append)
                (cons type))))))
      (or (-reduce-from #'match-header nil log-note-matcher) '(none)))))

(defmacro org-sql--to-entry (type &rest plist)
  "Return a list representing a logbook entry.
TYPE is the type of the entry and PLIST is data for the entry
whose keys are a subset of `org-sql--entry-keys'."
  (declare (indent 1))
  (let ((input-keys (-slice plist 0 nil 2)))
    (-some->> (-difference input-keys org-sql--entry-keys)
      (--map (format "%S" it))
      (s-join ", ")
      (error "Keys not valid for entry: %s"))
    `(list ,type ,@plist)))

(defun org-sql--item-to-entry (hstate item)
  "Return entry list from ITEM.
See `org-sql--to-entry' for the meaning of the returned list.
HSTATE is a list given by `org-sql--to-hstate'."
  (-let* (((&plist :outline-hash :headline) hstate)
          ((header-node . rest) (org-sql--split-item item))
          (header-offset (org-ml-get-property :begin header-node))
          (header-text (org-ml-to-trimmed-string header-node))
          (note-text (-some->> (-map #'org-ml-to-string rest)
                       (s-join "")
                       (s-trim)))
          ((type . (&plist :user
                           :user-full
                           :ts
                           :ts-active
                           :short-ts
                           :short-ts-active
                           :old-state
                           :new-state))
           (org-sql--match-item-header hstate header-text)))
    (cl-flet
        ((get-timestamp-node
          (match-bounds)
          (when match-bounds
            (let ((ts-offset (+ header-offset (car match-bounds))))
              (->> (org-ml-get-children header-node)
                   (--find (and (org-ml-is-type 'timestamp it)
                                (eq (org-ml-get-property :begin it) ts-offset)))))))
         (get-substring
          (match-bounds)
          (when match-bounds
            (-let (((begin . end) match-bounds))
              (substring header-text begin end)))))
      (let ((old-ts (get-timestamp-node old-state))
            (new-ts (get-timestamp-node new-state)))
        (org-sql--to-entry type
          :outline-hash outline-hash
          :header-text header-text
          :note-text note-text
          :user (get-substring user)
          :user-full (get-substring user-full)
          :ts (get-timestamp-node ts)
          :ts-active (get-timestamp-node ts-active)
          :short-ts (get-timestamp-node short-ts)
          :short-ts-active (get-timestamp-node short-ts-active)
          :old-ts old-ts
          :new-ts new-ts
          :old-state (unless old-ts (get-substring old-state))
          :new-state (unless new-ts (get-substring new-state)))))))

(defun org-sql--clocks-append-notes (hstate clocks)
  "Return list of cells like (CLOCK . NOTE-TEXT).
CLOCKS is a list of clocks which may contain items (the clock
notes). If a clock has a note after it and HSTATE has the
appropriate configuration, said clock will be returned as (CLOCK
. NOTE-TEXT) where the item will be converted to a string and set
to NOTE-TEXT; otherwise just as (CLOCK)."
  (-let (((&plist :lb-config (&plist :clock-out-notes)) hstate))
    (if (not clock-out-notes) (-map #'list clocks)
      (->> clocks
           (--reduce-from
            (if (org-ml-is-type 'item it)
                (let ((note-text (->> (org-ml-get-children it)
                                      (-map #'org-ml-to-string)
                                      (s-join "")
                                      (s-trim))))
                  (cons (cons (car (car acc)) note-text) (cdr acc)))
              (cons (list it) acc))
            nil)
           (reverse)))))

;; org-element tree -> bulk insert-alist

;; these functions take a specific element of the org tree and "add" a "row"
;; (which is just a list of values representing that row) to accumulator `ACC'
;; (representing the bulk insert SQL statement). `ACC' is an alist of table
;; names whose cdr's hold the rows to be inserted to that table

(defun org-sql--insert-alist-add-headline-logbook-item (acc entry)
  "Add row for item ENTRY to ACC."
  (-let (((entry-type . (&plist :header-text :note-text :outline-hash :ts)) entry))
    (org-sql--insert-alist-add acc logbook_entries
      :entry_id (org-sql--acc-get :entry-id acc)
      :headline_id (org-sql--acc-get :headline-id acc)
      :entry_type (symbol-name entry-type)
      :time_logged (-some->> ts
                     (org-ml-timestamp-get-start-time)
                     (org-ml-time-to-unixtime))
      :header header-text
      :note note-text)))

(defun org-sql--insert-alist-add-state-change (acc entry)
  "Add rows for state change ENTRY to ACC."
  (-let (((&plist :old-state :new-state) (cdr entry)))
    (--> (org-sql--insert-alist-add-headline-logbook-item acc entry)
         (org-sql--insert-alist-add it state_changes
           :entry_id (org-sql--acc-get :entry-id acc)
           :state_old old-state
           :state_new new-state))))

(defun org-sql--insert-alist-add-planning-change (acc hstate entry)
  "Add rows for planning change ENTRY to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (-let (((&plist :old-ts) (cdr entry)))
    (--> (org-sql--insert-alist-add-headline-logbook-item acc entry)
         (org-sql--insert-alist-add-timestamp it hstate old-ts)
         (org-sql--insert-alist-add it planning_changes
           :entry_id (org-sql--acc-get :entry-id acc)
           :timestamp_id (org-sql--acc-get :timestamp-id acc))
         (org-sql--acc-incr :timestamp-id it))))

(defun org-sql--insert-alist-add-headline-logbook-items (acc hstate logbook)
  "Add rows for LOGBOOK to ACC.
LOGBOOK is the logbook value of the supercontents list returned
by `org-ml-headline-get-supercontents'. HSTATE is a plist as
returned by `org-sql--to-hstate'."
  ;; TODO what about unknown stuff?
  (-let (((&plist :headline) hstate))
    (cl-flet
        ((add-entry
          (acc entry)
          (let ((entry-type (car entry)))
            (cond
             ((memq entry-type org-sql-excluded-logbook-types)
              acc)
             ((memq entry-type '(redeadline deldeadline reschedule delschedule))
              (org-sql--insert-alist-add-planning-change acc hstate entry))
             ((eq entry-type 'state)
              (org-sql--insert-alist-add-state-change acc entry))
             (t
              (org-sql--insert-alist-add-headline-logbook-item acc entry))))))
      (->> (org-ml-logbook-get-items logbook)
           (--map (org-sql--item-to-entry hstate it))
           (--reduce-from (org-sql--acc-incr :entry-id (add-entry acc it)) acc)))))

(defun org-sql--insert-alist-add-clock (acc hstate clock note-text)
  "Add rows for CLOCK to ACC.
NOTE-TEXT is either a string or nil representing the clock-note.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (-let (((&plist :headline) hstate)
         (value (org-ml-get-property :value clock)))
    (--> (org-sql--insert-alist-add acc clocks
           :clock_id (org-sql--acc-get :clock-id acc)
           :headline_id (org-sql--acc-get :headline-id acc)
           :time_start (-some-> value
                         (org-ml-timestamp-get-start-time)
                         (org-ml-time-to-unixtime))
           :time_end (-some-> value
                       (org-ml-timestamp-get-end-time)
                       (org-ml-time-to-unixtime))
           :clock_note (unless org-sql-exclude-clock-notes note-text))
      (org-sql--acc-incr :clock-id it))))

(defun org-sql--insert-alist-add-headline-logbook-clocks (acc hstate logbook)
  "Add rows for LOGBOOK to ACC.
LOGBOOK is the logbook value of the supercontents list returned
by `org-ml-headline-get-supercontents'. HSTATE is a plist as
returned by `org-sql--to-hstate'."
  (->> (org-ml-logbook-get-clocks logbook)
       (org-sql--clocks-append-notes hstate)
       (--reduce-from
        (org-sql--insert-alist-add-clock acc hstate (car it) (cdr it))
        acc)))

(defun org-sql--insert-alist-add-headline-properties (acc hstate)
  "Add row for each property in the current headline to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (if (eq 'all org-sql-excluded-properties) acc
    (-let* ((ignore-list (append org-sql--ignored-properties-default
                                 org-sql-excluded-properties))
            ((&plist :headline :outline-hash) hstate))
      (cl-flet
          ((is-ignored
            (node-property)
            (member (org-ml-get-property :key node-property) ignore-list))
           (add-property
            (acc np)
            (--> (org-sql--insert-alist-add acc properties
                   :outline_hash outline-hash
                   :property_id (org-sql--acc-get :property-id acc)
                   :key_text (org-ml-get-property :key np)
                   :val_text (org-ml-get-property :value np))
              (org-sql--insert-alist-add it headline_properties
                :headline_id (org-sql--acc-get :headline-id acc)
                :property_id (org-sql--acc-get :property-id acc))
              (org-sql--acc-incr :property-id it))))
        (->> (org-ml-headline-get-node-properties headline)
             (-remove #'is-ignored)
             (-reduce-from #'add-property acc))))))

(defun org-sql--insert-alist-add-headline-tags (acc hstate)
  "Add row for each tag in the current headline to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (if (eq 'all org-sql-excluded-tags) acc
    (-let (((&plist :headline) hstate))
      (cl-flet
          ((add-tag
            (acc tag inherited)
            (org-sql--insert-alist-add acc headline_tags
              :headline_id (org-sql--acc-get :headline-id acc)
              :tag tag
              :is_inherited (if inherited 1 0)))
           (filter-ignored
            (tags)
            (-difference tags org-sql-excluded-tags)))
        (let ((tags (filter-ignored (org-sql--headline-get-tags headline)))
              (i-tags (->> (org-sql--headline-get-archive-itags headline)
                           (filter-ignored))))
          (--> acc
               (--reduce-from (add-tag acc it nil) it tags)
               (--reduce-from (add-tag acc it t) it i-tags)))))))

(defun org-sql--insert-alist-add-headline-links (acc hstate contents)
  "Add row for each link in the current headline to ACC.
CONTENTS is a list corresponding to that returned by
`org-ml-headline-get-supercontents'. HSTATE is a plist as
returned by `org-sql--to-hstate'."
  (if (eq 'all org-sql-excluded-link-types) acc
    (-let* (((&plist :headline) hstate)
            (links (->> (--mapcat (org-ml-match '(:any * link) it) contents)
                        (--remove (member (org-ml-get-property :type it)
                                          org-sql-excluded-link-types)))))
      (cl-flet
          ((add-link
            (acc link)
            (--> (org-sql--insert-alist-add acc links
                   :link_id (org-sql--acc-get :link-id acc)
                   :headline_id (org-sql--acc-get :headline-id acc)
                   :link_path (org-ml-get-property :path link)
                   :link_text (->> (org-ml-get-children link)
                                   (-map #'org-ml-to-string)
                                   (s-join ""))
                   :link_type (org-ml-get-property :type link))
              (org-sql--acc-incr :link-id it))))
        (-reduce-from #'add-link acc links)))))

(defmacro org-sql--insert-alist-add-timestamp-mod (acc modifier-type timestamp)
  "Add row for timestamp modifier of TIMESTAMP to ACC.
MODIFIER-TYPE is one of 'warning' or 'repeater'."
  (declare (indent 2))
  (-let (((tbl-name value-col unit-col type-col type-prop value-prop unit-prop)
          (cl-case modifier-type
            (warning (list 'timestamp_warnings
                           :warning_value
                           :warning_unit
                           :warning_type
                           :warning-type
                           :warning-value
                           :warning-unit))
            (repeater (list 'timestamp_repeaters
                            :repeater_value
                            :repeater_unit
                            :repeater_type
                            :repeater-type
                            :repeater-value
                            :repeater-unit))
            (t (error "Unknown modifier type: %s" modifier-type)))))
    `(-if-let (type (org-ml-get-property ,type-prop ,timestamp))
         (org-sql--insert-alist-add ,acc ,tbl-name
           :timestamp_id (org-sql--acc-get :timestamp-id acc)
           ,value-col (org-ml-get-property ,value-prop ,timestamp)
           ,unit-col (org-ml-get-property ,unit-prop ,timestamp)
           ,type-col type)
       ,acc)))

(defun org-sql--insert-alist-add-timestamp (acc hstate timestamp)
  "Add row for TIMESTAMP to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (cl-flet
      ((get-resolution
        (time)
        (when time (if (org-ml-time-is-long time) 1 0))))
    (-let* ((start (org-ml-timestamp-get-start-time timestamp))
            (end (org-ml-timestamp-get-end-time timestamp))
            ((&plist :headline) hstate))
      (--> acc
        (org-sql--insert-alist-add it timestamps
          :timestamp_id (org-sql--acc-get :timestamp-id acc)
          :headline_id (org-sql--acc-get :headline-id acc)
          :is_active (if (org-ml-timestamp-is-active timestamp) 1 0)
          :time_start (org-ml-time-to-unixtime start)
          :start_is_long (get-resolution start)
          :time_end (-some-> end (org-ml-time-to-unixtime))
          :end_is_long (get-resolution end)
          :raw_value (org-ml-get-property :raw-value timestamp))
        (org-sql--insert-alist-add-timestamp-mod it warning timestamp)
        (org-sql--insert-alist-add-timestamp-mod it repeater timestamp)))))

(defun org-sql--insert-alist-add-headline-timestamps (acc hstate contents)
  "Add row for each timestamp in the current headline to ACC.
CONTENTS is a list corresponding to that returned by
`org-ml-headline-get-supercontents'. HSTATE is a plist as
returned by `org-sql--to-hstate'."
  (if (eq org-sql-excluded-contents-timestamp-types 'all) acc
    (-if-let (pattern (-some--> org-sql--content-timestamp-types
                        (-difference it org-sql-excluded-contents-timestamp-types)
                        (--map `(:type ',it) it)
                        `(:any * (:and timestamp (:or ,@it)))))
        (-let* (((&plist :headline) hstate)
                (timestamps (--mapcat (org-ml-match pattern it) contents)))
          (--reduce-from (->> (org-sql--insert-alist-add-timestamp acc hstate it)
                              (org-sql--acc-incr :timestamp-id))
                         acc timestamps))
      acc)))

(defun org-sql--insert-alist-add-headline-planning (acc hstate)
  "Add row for each planning timestamp in the current headline to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (-let (((&plist :headline) hstate))
    (-if-let (planning (org-ml-headline-get-planning headline))
        (cl-flet
            ((add-planning-maybe
              (acc type)
              (-if-let (ts (org-ml-get-property type planning))
                  (--> (org-sql--insert-alist-add-timestamp acc hstate ts)
                    (org-sql--insert-alist-add it planning_entries
                      :timestamp_id (org-sql--acc-get :timestamp-id acc)
                      :planning_type (->> (symbol-name type)
                                          (s-chop-prefix ":")
                                          (intern)))
                    (org-sql--acc-incr :timestamp-id it))
                acc)))
          (--> '(:closed :deadline :scheduled)
            (-difference it org-sql-excluded-headline-planning-types)
            (-reduce-from #'add-planning-maybe acc it)))
      acc)))

(defun org-sql--insert-alist-add-headline-closures (acc hstate)
  "Add row for parent closures from the current headline to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (-let* (((&plist :headline :parent-ids) hstate)
          (headline-id (org-sql--acc-get :headline-id acc)))
    (cl-flet
        ((add-closure
          (acc parent-id depth)
          (org-sql--insert-alist-add acc headline_closures
            :headline_id headline-id
            :parent_id parent-id
            :depth depth)))
      (->> (--map-indexed (list it it-index) parent-ids)
           (reverse)
           (--reduce-from (apply #'add-closure acc it) acc)))))

(defun org-sql--insert-alist-add-headline (acc hstate)
  "Add row the current headline's metadata to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (cl-flet
      ((effort-to-int
        (s)
        (when (org-duration-p s)
          (round (org-duration-to-minutes s)))))
    (-let* (((&plist :outline-hash :lb-config :headline) hstate)
            (supercontents (org-ml-headline-get-supercontents lb-config headline))
            (logbook (org-ml-supercontents-get-logbook supercontents))
            (sc (-some->> (org-ml-headline-get-statistics-cookie headline)
                  (org-ml-get-property :value)))
            ((sc-value sc-type) (pcase sc
                                  ;; divide-by-zero -> NULL
                                  (`(,n 0) '(nil fraction))
                                  (`(,n ,d) `(,(/ (* 1.0 n) d) fraction))
                                  (`(,p) `(,p percent))))
            (contents (org-ml-supercontents-get-contents supercontents)))
      (--> (org-sql--insert-alist-add acc headlines
             :headline_id (org-sql--acc-get :headline-id acc)
             :outline_hash outline-hash
             :headline_text (org-ml-get-property :raw-value headline)
             :keyword (org-ml-get-property :todo-keyword headline)
             :effort (-> (org-ml-headline-get-node-property "Effort" headline)
                         (effort-to-int))
             :priority (-some->> (org-ml-get-property :priority headline)
                         (byte-to-string))
             :stats_cookie_type sc-type
             :stats_cookie_value sc-value
             :is_archived (if (org-ml-get-property :archivedp headline) 1 0)
             :is_commented (if (org-ml-get-property :commentedp headline) 1 0)
             :content (-some->> (-map #'org-ml-to-string contents)
                        (s-join "")))
        (org-sql--insert-alist-add-headline-planning it hstate)
        (org-sql--insert-alist-add-headline-tags it hstate)
        (org-sql--insert-alist-add-headline-properties it hstate)
        (org-sql--insert-alist-add-headline-timestamps it hstate contents)
        (org-sql--insert-alist-add-headline-links it hstate contents)
        (org-sql--insert-alist-add-headline-logbook-clocks it hstate logbook)
        (org-sql--insert-alist-add-headline-logbook-items it hstate logbook)
        (org-sql--insert-alist-add-headline-closures it hstate)
        (org-sql--acc-incr :headline-id it)))))

(defun org-sql--insert-alist-add-headlines (acc outline-config)
  "Add row headlines in OUTLINE-CONFIG to ACC.
OUTLINE-CONFIG is a list given by `org-sql--to-outline-config'."
  (-let (((&plist :headlines) outline-config))
    (cl-labels
        ((add-headline
          (acc hstate hl)
          (let* ((sub (org-ml-headline-get-subheadlines hl))
                 (headline-id (org-sql--acc-get :headline-id acc))
                 (hstate* (if hstate (org-sql--update-hstate headline-id hstate hl)
                            (org-sql--to-hstate headline-id outline-config hl))))
            (if (and org-sql-exclude-headline-predicate
                     (funcall org-sql-exclude-headline-predicate hl))
                acc
              (--> (org-sql--insert-alist-add-headline acc hstate*)
                (--reduce-from (add-headline acc hstate* it) it sub))))))
      (--reduce-from (add-headline acc nil it) acc headlines))))

(defun org-sql--insert-alist-add-file-tags (acc outline-config)
  "Add row for each file tag in file to ACC.
OUTLINE-CONFIG is a list given by `org-sql--to-outline-config'."
  (-let (((&plist :outline-hash :top-section) outline-config))
    (cl-flet
        ((add-tag
          (acc tag)
          (org-sql--insert-alist-add acc file_tags
            :outline_hash outline-hash
            :tag tag)))
      (->> (--filter (org-ml-is-type 'keyword it) top-section)
           (--filter (equal (org-ml-get-property :key it) "FILETAGS"))
           (--mapcat (s-split " " (org-ml-get-property :value it)))
           (-uniq)
           (-reduce-from #'add-tag acc)))))

(defun org-sql--insert-alist-add-file-properties (acc outline-config)
  "Add row for each file property in file to ACC.
OUTLINE-CONFIG is a list given by `org-sql--to-outline-config'."
  (-let (((&plist :outline-hash :top-section) outline-config))
    (cl-flet
        ((add-property
          (acc keyword)
          (-let (((key value) (--> (org-ml-get-property :value keyword)
                                   (s-split-up-to " " it 1))))
            (--> (org-sql--insert-alist-add acc properties
                   :outline_hash outline-hash
                   :property_id (org-sql--acc-get :property-id acc)
                   :key_text key
                   :val_text value)
                 (org-sql--acc-incr :property-id it)))))
      (->> (--filter (org-ml-is-type 'keyword it) top-section)
           (--filter (equal (org-ml-get-property :key it) "PROPERTY"))
           (-reduce-from #'add-property acc)))))

(defun org-sql--insert-alist-add-outline-hash (acc outline-config)
  "Add row for OUTLINE-CONFIG to ACC.
OUTLINE-CONFIG is a list given by `org-sql--to-outline-config'."
  (-let (((&plist :outline-hash :size :lines) outline-config))
    (org-sql--insert-alist-add acc outlines
      :outline_hash outline-hash
      :outline_size size
      :outline_lines lines)))

(defun org-sql--insert-alist-add-file-metadata* (acc path hash attrs)
  "Add row for a file and its metadata to ACC.
PATH is a path to the file to insert, HASH is the MD5 of the
file, and ATTRS is the list of attributes returned by
`file-attributes' for the file."
  (org-sql--insert-alist-add acc file_metadata
    :outline_hash hash
    :file_path path
    :file_uid (file-attribute-user-id attrs)
    :file_gid (file-attribute-group-id attrs)
    :file_modification_time (->> (file-attribute-modification-time attrs)
                                 (float-time)
                                 (round))
    :file_attr_change_time (->> (file-attribute-status-change-time attrs)
                                 (float-time)
                                 (round))
    :file_modes (file-attribute-modes attrs)))

(defun org-sql--insert-alist-add-file-metadata (acc outline-config)
  "Add row for file in OUTLINE-CONFIG to ACC.
OUTLINE-CONFIG is a list given by `org-sql--to-outline-config'."
  (-let (((&plist :paths-with-attributes :outline-hash) outline-config))
    (--reduce-from (org-sql--insert-alist-add-file-metadata* acc (car it) outline-hash (cdr it))
                   acc paths-with-attributes)))

(defun org-sql--outline-config-to-insert-alist (acc outline-config)
  "Add all rows to be inserted from OUTLINE-CONFIG to ACC.
OUTLINE-CONFIG is a list given by `org-sql--to-outline-config'."
  (-> acc
      (org-sql--insert-alist-add-outline-hash outline-config)
      (org-sql--insert-alist-add-file-metadata outline-config)
      (org-sql--insert-alist-add-file-properties outline-config)
      (org-sql--insert-alist-add-file-tags outline-config)
      (org-sql--insert-alist-add-headlines outline-config)))

;; hashpathpair function

(defun org-sql--partition-hashpathpairs (disk-hashpathpairs db-hashpathpairs)
  "Group hashpathpairs according to operations to be performed.

DISK-HASHPATHPAIRS and DB-HASHPATHPAIRS are lists of cons cells
like (FILE-HASH . FILE-PATH) located on the disk and in the
database respectively. Return a list with these cons cells
grouped like (FILES-TO-INSERT PATHS-TO-INSERT PATHS-TO-DELETE
FILES-TO-DELETE); these represent the operations that are to
be taken on these particular files.

Criteria for grouping each pair is as follows.
- any pairs that are on disk and in the db are ignored (eg don't
  go into any of the four buckets above)
- a pair from disk that has a matching hash in the db will be
  grouped with PATHS-TO-INSERT
- a pair from the db that has a matching hash on disk will be
  grouped with PATHS-TO-DELETE
- a hash that exists on disk but not the db will be added to
  FILES-TO-INSERT
- a hash that exists in the db but not on disk will be added to
  FILES-TO-DELETE

Note that in terms of common file manipulations one might do,
PATHS-TO-INSERT and PATHS-TO-DELETE represent when a file is
renamed (the contents of the file don't change, so the hash
doesn't change). FILES-TO-INSERT and FILES-TO-DELETE are
self-explanatory, but note that if a file is \"modified\" (eg the
contents change but the path does not) it will be delete from the
database and reinserted (so the new file will be in
FILES-TO-INSERT and the old will be in FILES-TO-DELETE). There is
no efficient way to \"update\" a file in place in the database."
  (let (hash-in-db paths-dont-match files-to-insert paths-to-insert
                   paths-to-delete cur-disk cur-db n)
    (while disk-hashpathpairs
      (setq hash-in-db nil
            paths-dont-match nil
            n (length db-hashpathpairs)
            cur-disk (car disk-hashpathpairs))
      (while (< 0 n)
        (setq cur-db (nth (1- n) db-hashpathpairs))
        ;; first test if hashes are equal in the two pairs
        (when (equal (car cur-disk) (car cur-db))
          ;; if yes, test if the paths are equal
          (when (not (equal (cdr cur-disk) (cdr cur-db)))
            (setq paths-dont-match t
                  paths-to-delete (cons cur-db paths-to-delete)))
          (setq hash-in-db t
                db-hashpathpairs (-remove-at (1- n) db-hashpathpairs)))
        (setq n (1- n)))
      (if hash-in-db
          (when paths-dont-match
            (setq paths-to-insert (cons cur-disk paths-to-insert)))
        (setq files-to-insert (cons cur-disk files-to-insert)))
      (setq disk-hashpathpairs (cdr disk-hashpathpairs)))
    `((files-to-insert ,@files-to-insert)
      (paths-to-insert ,@paths-to-insert)
      (paths-to-delete ,@paths-to-delete)
      (files-to-delete ,@db-hashpathpairs))))

(defun org-sql--group-hashpathpairs-by-hash (hashpathpairs)
  "Return a list of HASHPATHPAIRS grouped by hash.
The returned list will be like ((HASH1 PATH1a PATH1b ...) (HASH2
PATH2a PATH2a ...))."
  (--map (cons (car it) (-map #'cdr (cdr it))) (-group-by #'car hashpathpairs)))

(defun org-sql--hashpathpairs-to-hashes (hashpathpairs)
  "Return a list of just the hashes from HASHPATHPAIRS."
  (-map #'car hashpathpairs))

;;; SQL formatting functions

;; value formatters

(defun org-sql--compile-value-format-function (config type)
  "Return SQL value formatting function for TYPE.
The function will be compiled according to CONFIG, a list like
`org-sql-db-config'."
  (let ((formatter-form
         (org-sql--case-type type
           (boolean
            (org-sql--case-mode config
              ((mysql postgres)
               '(if (= it 1) "TRUE" "FALSE"))
              ((sqlite sqlserver)
               '(if (= it 1) "1" "0"))))
           (enum
            '(format "'%s'" (symbol-name it)))
           ((integer real)
            '(number-to-string it))
           ((char text varchar)
            (let ((escaped-chars
                   (org-sql--case-mode config
                     (mysql '(("'" . "\\\\'")
                              ("\n" . "\\\\n")))
                     ;; TODO not sure if these also needs Char(13) in front of
                     ;; Char(10) for the carriage return if using on windows
                     ;; (alas...newline war)
                     (postgres '(("'" . "''")
                              ("\n" . "'||chr(10)||'")))
                     (sqlite '(("'" . "''")
                               ("\n" . "'||char(10)||'")))
                     (sqlserver '(("'" . "''")
                                  ("\n" . "+Char(10)+"))))))
              `(->> ',escaped-chars
                    (--reduce-from (s-replace (car it) (cdr it) acc) it)
                    (format "'%s'")))))))
    `(lambda (it) (if it ,formatter-form "NULL"))))

(defun org-sql--get-column-formatter (config tbl-name column-name)
  "Return the formatter for COLUMN-NAME in TBL-NAME.
The formatter will be compiled according to
`org-sql--compile-value-format-function' where CONFIG has the
same meaning as it has here."
  (let ((column (->> org-sql--table-alist
                     (alist-get tbl-name)
                     (alist-get 'columns)
                     (alist-get column-name))))
    (org-sql--compile-value-format-function config (plist-get column :type))))

(defun org-sql--get-column-formatters (config tbl-name)
  "Return the formatters for all columns (in order) in TBL-NAME.
The formatters will be compiled according to
`org-sql--compile-value-format-function' where CONFIG has the
same meaning as it has here."
  (->> org-sql--table-alist
       (alist-get tbl-name)
       (alist-get 'columns)
       (--map (org-sql--compile-value-format-function config (plist-get (cdr it) :type)))))

;; identifier formatters

(defun org-sql--format-column-name (column-name)
  "Return SQL string representation of COLUMN-NAME."
  (if (not (keywordp column-name)) (error "Not a keyword: %s" column-name)
    (s-chop-prefix ":" (symbol-name column-name))))

(defun org-sql--format-table-name (config tbl-name)
  "Return TBL-NAME as a formatted string according to CONFIG."
  (org-sql--case-mode config
    ;; these are straightforward since they don't use namespaces
    ((mysql sqlite)
     (symbol-name tbl-name))
    ;; these require a custom namespace (aka schema) prefix if available
    ((postgres sqlserver)
     (-let (((&plist :schema) (cdr config)))
       (if (not schema) (symbol-name tbl-name)
         (format "%s.%s" schema tbl-name))))))

(defun org-sql--format-enum-name (config enum-name)
  "Return ENUM-NAME as a formatted string according to CONFIG."
  ;; ASSUME only modes that support ENUM will call this
  (-let (((&plist :schema) (cdr config)))
    (if (not schema) enum-name (format "%s.%s" schema enum-name))))

;; create table

(defun org-sql--get-enum-type-names (config table-alist)
  "Return the names of the enum types for TABLE-ALIST.
CONFIG is a list like `org-sql-db-config'. Note that these are
the type names that will be used in \"CREATE TYPE\" statements."
  (cl-flet
      ((flatten
        (tbl)
        (let ((tbl-name (car tbl)))
          (--map (cons tbl-name it) (alist-get 'columns (cdr tbl)))))
       (format-column
        (grouped)
        (-let (((tbl-name . (col-name . (&plist :type :type-id :allowed))) grouped))
          (when (and (eq type 'enum) allowed)
            (cons (->> (or type-id
                           (->> (org-sql--format-column-name col-name)
                                (format "enum_%s_%s" tbl-name)))
                       (org-sql--format-enum-name config))
                  (--map (format "'%s'" it) allowed))))))
    (->> (-mapcat #'flatten table-alist)
         (-map #'format-column)
         (-non-nil)
         (-uniq))))

(defun org-sql--format-create-enum-types (config table-alist)
  "Return string of CREATE TYPE statements for TABLE-ALIST.
CONFIG is a list like `org-sql-db-config'."
  (->> (org-sql--get-enum-type-names config table-alist)
       (--map (format "CREATE TYPE %s AS ENUM (%s);"
                      (car it)
                      (s-join "," (cdr it))))))

(defun org-sql--format-column-constraints (column-constraints)
  "Return formatted column constraints for COLUMN-CONSTRAINTS."
  (cl-flet
      ((format-constraint
        (constraint)
        (pcase constraint
          ('notnull "NOT NULL")
          ('unique "UNIQUE")
          (e (error "Unknown constraint %s" e)))))
    (s-join " " (-map #'format-constraint column-constraints))))

(defun org-sql--format-create-tables-type (config tbl-name column)
  "Return SQL string for the type of COLUMN.
CONFIG is the `org-sql-db-config' list and TBL-NAME is the name
of the table."
  (cl-flet
      ((fmt-varchar
        (column len-fmt max-str)
        (-let (((&plist :length) (cdr column)))
          (if length (format len-fmt length) max-str))))
    (-let (((column-name . (&plist :type :type-id)) column))
      (org-sql--case-type type
        (boolean
         (org-sql--case-mode config
           ((mysql postgres) "BOOLEAN")
           (sqlite "INTEGER")
           (sqlserver "BIT")))
        (char
         (org-sql--case-mode config
           ((mysql sqlserver)
            (-let (((&plist :length) (cdr column)))
              (if length (format "CHAR(%s)" length) "CHAR")))
           ;; postgres should use TEXT here because (according to the docs) "there
           ;; is no performance difference among char/varchar/text except for
           ;; the length-checking"
           ((postgres sqlite) "TEXT")))
        (enum
         (org-sql--case-mode config
           (mysql (->> (plist-get (cdr column) :allowed)
                       (--map (format "'%s'" it))
                       (s-join ",")
                       (format "ENUM(%s)")))
           (postgres (if type-id type-id
                    (->> (org-sql--format-column-name column-name)
                         (format "enum_%s_%s" tbl-name)
                         (org-sql--format-enum-name config))))
           (sqlite "TEXT")
           (sqlserver (-if-let (length (plist-get (cdr column) :length))
                          (format "NVARCHAR(%s)" length)
                        "NVARCHAR(MAX)"))))
        (integer
         "INTEGER")
        (real
         (org-sql--case-mode config
           (mysql "FLOAT")
           ((postgres sqlite sqlserver) "REAL")))
        (text
         (org-sql--case-mode config
           ((mysql postgres sqlite) "TEXT")
           (sqlserver "NVARCHAR(MAX)")))
        (varchar
         (org-sql--case-mode config
           (mysql (fmt-varchar column "VARCHAR(%s)" "VARCHAR"))
           ;; see above why postgres uses TEXT here
           ((postgres sqlite) "TEXT")
           (sqlserver (fmt-varchar column "NVARCHAR(%s)" "NVARCHAR(MAX)"))))))))

(defun org-sql--format-create-table-columns (config tbl-name columns)
  "Return SQL string for COLUMNS.
CONFIG is the `org-sql-db-config' list and TBL-NAME is the name
of the table."
  (cl-flet
      ((format-column
        (column)
        (-let* (((name . (&plist :constraints)) column)
                (name* (org-sql--format-column-name name))
                (type* (org-sql--format-create-tables-type config tbl-name column))
                (column-str (format "%s %s" name* type*)))
          (if (not constraints) column-str
            (->> (org-sql--format-column-constraints constraints)
                 (format "%s %s" column-str))))))
    (-map #'format-column columns)))

(defun org-sql--format-create-table-constraints (config column-constraints defer)
  "Return SQL string for COLUMN-CONSTRAINTS.
If DEFER is t, add 'INITIALLY DEFERRED' to the end of each
foreign key constraint. CONFIG is the `org-sql-db-config' list."
  (cl-labels
      ((format-primary
        (keyvals)
        (-let* (((&plist :keys) keyvals))
          (->> (-map #'org-sql--format-column-name keys)
               (s-join ",")
               (format "PRIMARY KEY (%s)"))))
       (format-foreign
        (keyvals)
        (-let* (((&plist :ref :keys :parent-keys :on-delete) keyvals)
                (ref* (org-sql--format-table-name config ref))
                (keys* (->> keys (-map #'org-sql--format-column-name) (s-join ",")))
                (parent-keys* (->> parent-keys
                                   (-map #'org-sql--format-column-name)
                                   (s-join ",")))
                (foreign-str (format "FOREIGN KEY (%s) REFERENCES %s (%s)"
                                     keys* ref* parent-keys*))
                (on-delete* (-some--> on-delete
                              (cl-case it
                                (no-action "NO ACTION")
                                (cascade "CASCADE"))
                              (format "ON DELETE %s" it)))
                (deferrable (when defer "DEFERRABLE INITIALLY DEFERRED")))
          (->> (list foreign-str on-delete* deferrable)
               (-non-nil)
               (s-join " "))))
       (format-constraint
        (constraint)
        (pcase constraint
          (`(primary . ,keyvals) (format-primary keyvals))
          (`(foreign . ,keyvals) (format-foreign keyvals)))))
    (-map #'format-constraint column-constraints)))

(defun org-sql--format-create-table (config table)
  "Return CREATE TABLE (...) SQL string for TABLE.
CONFIG is the `org-sql-db-config' list."
  (-let* (((tbl-name . (&alist 'columns 'constraints)) table)
          (tbl-name* (org-sql--format-table-name config tbl-name))
          (defer (org-sql--case-mode config
                   ((mysql sqlserver) nil)
                   ((postgres sqlite) t)))
          (fmt (org-sql--case-mode config
                 ((mysql sqlite)
                  "CREATE TABLE IF NOT EXISTS %s (%s);")
                 (postgres
                  (org-sql--with-config-keys (:unlogged) config
                    (s-join " " (list "CREATE"
                                      (if unlogged "UNLOGGED TABLE" "TABLE")
                                      "IF NOT EXISTS %s (%s);"))))
                 (sqlserver
                  (org-sql--with-config-keys (:database) config
                    (format "IF NOT EXISTS (SELECT * FROM sys.tables where name = '%%1$s') CREATE TABLE %%1$s (%%2$s);" database))))))
    (->> (org-sql--format-create-table-constraints config constraints defer)
         (append (org-sql--format-create-table-columns config tbl-name columns))
         (s-join ",")
         (format fmt tbl-name*))))

(defun org-sql--format-create-tables (config tables)
  "Return schema SQL string for TABLES.
CONFIG is the `org-sql-db-config' list."
  (let ((create-tbl-stmts (--map (org-sql--format-create-table config it) tables)))
    (org-sql--case-mode config
      (postgres
       (-> (org-sql--format-create-enum-types config tables)
           (append create-tbl-stmts)))
      ((mysql sqlite sqlserver)
       create-tbl-stmts))))

;; insert

(defun org-sql--format-bulk-insert-for-table (config table-bulk-insert)
  "Return a multi-row INSERT statement for a table.
TABLE-BULK-INSERT is a list like one cell of
`org-sql--empty-insert-alist' that has been populated with rows
to insert. CONFIG is a list like `org-sql-db-config'."
  (cl-flet
      ((format-row
        (formatters row)
        (->> (--zip-with (funcall other it) row formatters)
             (s-join ",")
             (format "(%s)"))))
    (-let* (((tbl-name . rows) table-bulk-insert)
            (tbl-name* (org-sql--format-table-name config tbl-name))
            (columns (->> (alist-get tbl-name org-sql--table-alist)
                          (alist-get 'columns)
                          (--map (org-sql--format-column-name (car it)))
                          (s-join ",")))
            ;; ASSUME these will be in the right order
            (formatters (org-sql--get-column-formatters config tbl-name)))
      (->> (--map (format-row formatters it) rows)
           (s-join ",")
           (format "INSERT INTO %s (%s) VALUES %s;" tbl-name* columns)))))

(defun org-sql--format-bulk-inserts (config insert-alist)
  "Return multi-row INSERT statements.
INSERT-ALIST is an alist like `org-sql--empty-insert-alist' that
has been populated with rows to insert. CONFIG is a list like
`org-sql-db-config'."
  (->> (-filter #'cdr insert-alist)
       (--map (org-sql--format-bulk-insert-for-table config it))
       (s-join "")))

;; select

(defun org-sql--format-select-statement (config columns tbl-name)
  "Return a simple SELECT statement.
TBL-NAME is the table name to select from and COLUMNS are the
columns to return (nil will \"SELECT *\"). CONFIG is a list like
`org-sql-db-config'."
  (let ((tbl-name* (org-sql--format-table-name config tbl-name))
        (columns* (or (-some->> (-map #'org-sql--format-column-name columns)
                        (s-join ","))
                      "*")))
    (format "SELECT %s FROM %s;" columns* tbl-name*)))

;; bulk deletes

(defun org-sql--format-path-delete-statement (config hashpathpairs)
  "Return a DELETE statement for file paths.
HASHPATHPAIRS are a list of cons cells like (FILE-HASH .
FILE-PATH) which are to be deleted. CONFIG is a list like
`org-sql-db-config'."
  (when hashpathpairs
    (cl-flet
        ((format-where-clause
          (path-fmtr hash-fmtr grouped)
          (-let* (((hash . paths) grouped)
                  (hash* (funcall hash-fmtr hash)))
            (->> (--map (format "file_path = %s" (funcall path-fmtr it)) paths)
                 (s-join " OR ")
                 (format "(outline_hash = %s AND (%s))" hash*)))))
      (let ((tbl-name* (org-sql--format-table-name config 'file_metadata))
            (hash-fmtr (org-sql--get-column-formatter config 'file_metadata :outline_hash))
            (path-fmtr (org-sql--get-column-formatter config 'file_metadata :file_path)))
        (->> (org-sql--group-hashpathpairs-by-hash hashpathpairs)
             (--map (format-where-clause path-fmtr hash-fmtr it))
             (s-join " OR ")
             (format "DELETE FROM %s WHERE %s;" tbl-name*))))))

(defun org-sql--format-outline-delete-statement (config hashpathpairs)
  "Return a DELETE statement for an org outline.
HASHPATHPAIRS are a list of cons cells like (FILE-HASH .
FILE-PATH) which are to be deleted. CONFIG is a list like
`org-sql-db-config'."
  (when hashpathpairs
    (let ((tbl-name* (org-sql--format-table-name config 'outlines))
          (fmtr (org-sql--get-column-formatter config 'outlines :outline_hash)))
        (->> (org-sql--hashpathpairs-to-hashes hashpathpairs)
             (--map (funcall fmtr it))
             (s-join ",")
             (format "DELETE FROM %s WHERE outline_hash IN (%s);" tbl-name*)))))

;; bulk inserts

(defun org-sql--init-acc (init-ids)
  "Return an initialized accumulator for bulk insertion.
The accumulator will be a plist. The :inserts key will hold the
alist (initialized with `org-sql--empty-insert-alist') which will
hold the rows to be inserted. The remaining keys will hold the ID
surrogate key values for corresponding columns in their
respective tables (which are :headline-id, :timestamp-id,
:entry-id, :link-id, :property-id, and :clock-id). INIT-IDS
is a plist with the id's to use for initialization."
  (append (list :inserts (-clone org-sql--empty-insert-alist)) init-ids))

(defun org-sql--acc-get (key acc)
  "Return KEY from ACC."
  (plist-get acc key))

(defun org-sql--acc-incr (key acc)
  "Return ACC with 1 added to KEY."
  (plist-put acc key (1+ (plist-get acc key))))

(defun org-sql--acc-reset (key acc)
  "Return ACC with KEY set to 1."
  (plist-put acc key 0))

(defun org-sql--format-insert-statements (config max-ids paths-to-insert files-to-insert)
  "Return list of multi-row INSERT statements for paths and outlines.
CONFIG is a list like `org-sql-db-config'. PATHS-TO-INSERT is a
plist like (:hash FILE-HASH :path FILE-HASH :attrs
FILE-ATTRIBUTES) and FILES-TO-INSERT is a list of OUTLINE-CONFIG
lists. MAX-IDS is plist of the max id's currently in the database."
  (let* ((acc (->> (-partition 2 max-ids)
                   (--map (list (car it) (1+ (cadr it))))
                   (-flatten-n 1)
                   (org-sql--init-acc)))
         (acc* (--reduce-from (org-sql--outline-config-to-insert-alist acc it) acc files-to-insert)))
    (--> paths-to-insert
      (--reduce-from (-let (((&plist :hash :path :attrs) it))
                       (org-sql--insert-alist-add-file-metadata* acc path hash attrs))
                     acc* it)
         (plist-get it :inserts)
         (org-sql--format-bulk-inserts config it))))

;; transactions

(defun org-sql--format-sql-transaction (config sql-statements)
  "Return formatted SQL transaction.
SQL-STATEMENTS is a list of SQL statements to be included in the
transaction. CONFIG is a list like `org-sql-db-config'."
  (let ((fmt (org-sql--case-mode config
               (sqlite "PRAGMA foreign_keys = ON;BEGIN;%sCOMMIT;")
               ((mysql postgres) "BEGIN;%sCOMMIT;")
               (sqlserver "BEGIN TRANSACTION;%sCOMMIT;"))))
    (-some->> sql-statements
      (s-join "")
      (format fmt))))

;; IO helper functions

(defmacro org-sql--on-success (first-form success-form error-form)
  "Run form depending exit code.
FIRST-FORM must return a cons cell like (RC . OUT) where RC is
the return code and OUT is the output string (stdout and/or
stderr). SUCCESS-FORM will be run if RC is 0 and ERROR-FORM will
be run otherwise. In either case, OUT will be bound to the symbol
'it-out'."
  (declare (indent 1))
  (let ((r (make-symbol "rc")))
    `(-let (((,r . it-out) ,first-form))
       (if (= 0 ,r) ,success-form ,error-form))))

(defmacro org-sql--on-success* (first-form &rest success-forms)
  "Run SUCCESS-FORMS on successful exit code.
This is like `org-sql--on-success' but with '(error it-out)'
supplied for ERROR-FORM. FIRST-FORM has the same meaning."
  (declare (indent 1))
  `(org-sql--on-success ,first-form (progn ,@success-forms) (error it-out)))

(defmacro org-sql--fmap (io-return form)
  "Apply FORM to OUT field of IO-RETURN.
Do nothing if the return code is non-zero. OUT is bound to
`it-out`"
  (declare (indent 1))
  (let ((r (make-symbol "rc")))
    `(-let (((,r . it-out) ,io-return))
       (if (= 0 ,r) (cons ,r ,form) ,io-return))))

(defmacro org-sql--do (let-forms &rest success-forms)
  "Execute LET-FORMS in order.

LET-FORMS is a series of let-like forms (eg (SYM FORM)) where
FORM is a form to be executed which returns a list like (RC .
OUT) where RC is the return code and OUT is the output from
stdout and/or stderr. If RC is 0, OUT will be bound to SYM. If
the return code is non-zero, all other forms in LET-FORMS will
not be executed and instead the error message from OUT will be
printed. When all LET-FORM are complete, execute SUCCESS-FORMS
\(which may use the values bound in LET-FORMS.

To those who have experienced the glory of Haskell, this is
basically a hacky Lisp version of a do-block with an Either type
\(or IO + ExceptT, which I don't feel like writing):

lameExample :: Either a b
lameExample x = do
  a <- f1 x
  b <- f2 x
  c <- f3 x
  return $ youWin a b c"
  (declare (indent 1))
  (car (--reduce-from `((org-sql--on-success* ,(cadr it)
                          (let ((,(car it) it-out))
                            ,@acc)))
                      success-forms
                      (nreverse let-forms))))

(defun org-sql--get-drop-table-statements (config)
  "Return a list of DROP TABLE statements.
These statements will drop all tables required for org-sql.
CONFIG is a list like `org-sql-db-config'."
  (org-sql--case-mode config
    (mysql
     (list "SET FOREIGN_KEY_CHECKS = 0;"
           (format "DROP TABLE IF EXISTS %s;" (s-join "," org-sql-table-names))
           "SET FOREIGN_KEY_CHECKS = 1;"))
    (postgres
     (org-sql--with-config-keys (:schema) org-sql-db-config
       (let ((drop-tables (->> (if schema
                                   (--map (format "%s.%s" schema it)
                                          org-sql-table-names)
                                 org-sql-table-names)
                               (s-join ",")
                               (format "DROP TABLE IF EXISTS %s CASCADE;")))
             (drop-types (->> (org-sql--get-enum-type-names config org-sql--table-alist)
                              (-map #'car)
                              (s-join ",")
                              (format "DROP TYPE IF EXISTS %s CASCADE;"))))
         (list drop-tables drop-types))))
    (sqlite
     (reverse (--map (format "DROP TABLE IF EXISTS %s;" it) org-sql-table-names)))
    (sqlserver
     (org-sql--with-config-keys (:schema) config
       (let ((tbl-names (--> org-sql-table-names
                          (if schema (--map (format "%s.%s" schema it) it) it)
                          (reverse it)))
             (alter-fmt (->> (list
                              "IF EXISTS"
                              "(SELECT * FROM sys.tables where name = '%1$s')"
                              "ALTER TABLE %1$s NOCHECK CONSTRAINT ALL;")
                             (s-join " "))))
         (-snoc (--map (format alter-fmt it) tbl-names)
                (format "DROP TABLE IF EXISTS %s;" (s-join "," tbl-names))))))))

;;;
;;; STATEFUL FUNCTIONS
;;;

;;; low-level IO

(defun org-sql--run-command (path args async)
  "Execute PATH with ARGS.
Return a cons cell like (RETURNCODE . OUTPUT). IF ASYNC is t, run
the command at PATH in an asynchronous process."
  (if (not async) (org-sql--run-command* path nil args)
      (make-process :command (cons path args)
                    :buffer "*Org-SQL*"
                    :connection-type 'pipe
                    :name "org-sql-async")))

(defun org-sql--run-command* (path file args)
  "Execute PATH with ARGS and FILE routed to stdin.
Return a cons cell like (RETURNCODE . OUTPUT)."
  (with-temp-buffer
    (let ((rc (apply #'call-process path file (current-buffer) nil args)))
      (cons rc (buffer-string)))))
    
;;; hashpathpair -> outline-config

(defun org-sql--hashpathpair-get-outline-config (outline-hash file-paths)
  "Return outline-config for OUTLINE-HASH and FILE-PATHS.
Returned list will be constructed using
`org-sql--to-outline-config'."
  (let ((paths-with-attributes (--map (cons it (file-attributes it 'integer))
                                      file-paths)))
    ;; just pick the first file path to open
    (with-current-buffer (find-file-noselect (car file-paths) t)
      (let ((tree (org-element-parse-buffer))
            (todo-keywords (-map #'substring-no-properties org-todo-keywords-1))
            (lb-config (list :log-into-drawer org-log-into-drawer
                             :clock-into-drawer org-clock-into-drawer
                             :clock-out-notes org-log-note-clock-out))
            (size (buffer-size))
            (lines (save-excursion
                     (goto-char (point-max))
                     (line-number-at-pos))))
        (org-sql--to-outline-config outline-hash paths-with-attributes
                                    org-log-note-headings todo-keywords
                                    lb-config size lines tree)))))

;;; reading hashpathpair from external state

(defun org-sql--disk-get-hashpathpairs ()
  "Get a list of hashpathpair for org files on disk.
Each hashpathpair will have it's :db-path set to nil. Only files in
`org-sql-files' will be considered."
  (cl-flet
      ((get-md5
        (fp)
        (org-sql--on-success (org-sql--run-command "md5sum" `(,fp) nil)
          (car (s-split-up-to " " it-out 1))
          (error "Could not get md5")))
       (expand-if-dir
        (fp)
        (if (not (file-directory-p fp)) `(,fp)
          (directory-files fp t "\\`.*\\.org\\(_archive\\)?\\'"))))
    (if (stringp org-sql-files)
        (error "`org-sql-files' must be a list of paths")
      (->> (-mapcat #'expand-if-dir org-sql-files)
           (-map #'expand-file-name)
           (-filter #'file-exists-p)
           (-uniq)
           (--map (cons (get-md5 it) it))))))

(defun org-sql--db-get-hashpathpairs ()
  "Get a list of hashpathpair for the database.
Each hashpathpair will have it's :disk-path set to nil."
  (let* ((tbl-name 'file_metadata)
         (cols '(:file_path :outline_hash))
         (cmd (org-sql--format-select-statement org-sql-db-config cols tbl-name)))
    (org-sql--on-success* (org-sql-send-sql cmd)
      (->> (s-trim it-out)
           (org-sql--parse-output-to-plist org-sql-db-config cols)
           (--map (-let (((&plist :outline_hash h :file_path p) it))
                    (cons h p)))))))

(defun org-sql--get-max-ids ()
  "Return the max ids for all surrogate keys."
  (cl-flet
      ((get-maxid
        (table-names col name)
        (if (not (member (symbol-name name) table-names))
            ;; TODO this is just 'return bla' from Haskell
            (0 . 0)
          (--> (org-sql--format-table-name org-sql-db-config name)
            (format "SELECT MAX(%s) FROM %s;" col it)
            ;; NOTE this will never be asynchronous
            (org-sql-send-sql it nil)
            (org-sql--fmap it
              (let ((s (s-trim it-out)))
                (if (s-matches-p "[[:digit:]]+" s) (string-to-number s) 0)))))))
    (let ((table-names (org-sql-list-tables)))
      (org-sql--do ((hid (get-maxid table-names "headline_id" 'headlines))
                    (tid (get-maxid table-names "timestamp_id" 'timestamps))
                    (eid (get-maxid table-names "entry_id" 'logbook_entries))
                    (lid (get-maxid table-names "link_id" 'links))
                    (pid (get-maxid table-names "property_id" 'properties))
                    (cid (get-maxid table-names "clock_id" 'clocks)))
        (list :headline-id hid
              :timestamp-id tid
              :entry-id eid
              :link-id lid
              :property-id pid
              :clock-id cid)))))

(defun org-sql--get-transactions ()
  "Return SQL string of the update transaction.
This transaction will bring the database to represent the same
state as the orgfiles on disk."
  (-let* ((disk-hashpathpairs (org-sql--disk-get-hashpathpairs))
          (db-hashpathpairs (org-sql--db-get-hashpathpairs))
          (max-ids (org-sql--get-max-ids))
          ((&alist 'files-to-insert fi
                   'files-to-delete fd
                   'paths-to-insert pi
                   'paths-to-delete pd)
           (org-sql--partition-hashpathpairs disk-hashpathpairs db-hashpathpairs))
          (pi* (--map (list :hash (car it)
                            :path (cdr it)
                            :attrs (file-attributes (cdr it)))
                      pi)))
    (list (org-sql--format-path-delete-statement org-sql-db-config pd)
          (org-sql--format-outline-delete-statement org-sql-db-config fd)
          (->> (org-sql--group-hashpathpairs-by-hash fi)
               (--map (org-sql--hashpathpair-get-outline-config (car it) (cdr it)))
               (org-sql--format-insert-statements org-sql-db-config max-ids pi*)))))

(defun org-sql-dump-push-transaction ()
  "Dump the push transaction to a separate buffer."
  (let ((out (->> (org-sql--get-transactions)
                  (org-sql--format-sql-transaction org-sql-db-config))))
    (switch-to-buffer "SQL: Org-update-dump")
    (insert (s-replace ";" ";\n" out))))

;;; SQL command wrappers

(defun org-sql--append-process-environment (env &rest pairs)
  "Append ENV and PAIRS to the current environment.
ENV is a list like ((VAR VAL) ...) and PAIRS is a list like (VAR1
VAL1 VAR2 VAL2) where VAR is an env var name and VAL is the value
to assign it. Return these appended to the current value of
`process-environment'."
  (declare (indent 1))
  (let ((env* (--map (format (format "%s=%s" (car it) (cadr it))) env)))
    (->> (-partition 2 pairs)
         (--map (and (cadr it) (format "%s=%s" (car it) (cadr it))))
         (-non-nil)
         (append process-environment env*))))

(defun org-sql--exec-mysql-command-nodb (fargs async)
  "Run the mysql client with FARGS.
If ASYNC is t, the client will be run in an asynchronous
process."
  (org-sql--with-config-keys (:hostname :port :username :password :args :env
                                        :defaults-file :defaults-extra-file)
      org-sql-db-config
    (let ((all-args (append
                     ;; either of these must be the first option if given
                     (or (-some->> defaults-file
                           (format "--defaults-file=%s")
                           (list))
                         (-some->> defaults-extra-file
                           (format "--defaults-extra-file=%s")
                           (list)))
                     (-some->> hostname (list "-h"))
                     (-some->> port (number-to-string) (list "-P"))
                     (-some->> username (list "-u"))
                     ;; this makes the output tidy (no headers or extra output)
                     '("-Ns")
                     args
                     fargs))
          (process-environment (org-sql--append-process-environment env
                                 "MYSQL_PWD" password)))
      (org-sql--run-command org-sql--mysql-exe all-args async))))

(defun org-sql--exec-postgres-command-nodb (fargs async)
  "Run the postgres client with FARGS.
If ASYNC is t, the client will be run in an asynchronous
process."
  (org-sql--with-config-keys (:hostname :port :username :password :args :env
                                        :service-file :pass-file)
      org-sql-db-config
    (let ((all-args (append
                     (-some->> hostname (list "-h"))
                     (-some->> port (number-to-string) (list "-p"))
                     (-some->> username (list "-U"))
                     ;; don't prompt for password
                     '("-w")
                     ;; make output tidy (tabular, quiet, and no alignment)
                     '("-qAt")
                     args
                     fargs))
          (process-environment (org-sql--append-process-environment env
                                 "PGPASSWORD" password
                                 "PGSERVICEFILE" service-file
                                 "PGPASSFILE" pass-file
                                 ;; suppress warning messages
                                 "PGOPTIONS" "-c client_min_messages=WARNING")))
      (org-sql--run-command org-sql--psql-exe all-args async))))

(defun org-sql--exec-sqlserver-command-nodb (fargs async)
  "Run the sql-server client with FARGS.
If ASYNC is t, the client will be run in an asynchronous
process."
  (org-sql--with-config-keys (:server :username :password :args :env)
      org-sql-db-config
    (let ((all-args (append
                     (-some->> server (list "-S"))
                     (-some->> username (list "-U"))
                     ;; use pipe char as the separator
                     '("-s" "|")
                     ;; don't use headers
                     '("-h" "-1")
                     args
                     fargs))
          (process-environment (org-sql--append-process-environment env
                                 "SQLCMDPASSWORD" password)))
      (org-sql--run-command org-sql--sqlserver-exe all-args async))))

(defun org-sql--exec-sqlite-command (args async)
  "Run the sqlite client with ARGS.
If ASYNC is t, the client will be run in an asynchronous
process."
  (org-sql--with-config-keys (:path) org-sql-db-config
    (if (not path) (error "No path specified")
      (org-sql--run-command org-sql--sqlite-exe (cons path args) async))))

;; TODO this is the only db that requires a command like this?
(defun org-sql--exec-sqlserver-command (args async)
  "Run the sql-server client with ARGS in the configured database.
If ASYNC is t, the client will be run in an asynchronous
process."
  (org-sql--with-config-keys (:database) org-sql-db-config
    (if (not database) (error "No database specified")
      (org-sql--exec-sqlserver-command-nodb `("-d" ,database ,@args) async))))

(defun org-sql--exec-command-in-db (args async)
  "Run the configured client in the configured database.
ARGS is a list of arguments to be sent to the client. If ASYNC is
t, the client will be run in an asynchronous process."
  (cl-flet
      ((send
        (fun flag key args async)
        (-if-let (target (org-sql--get-config-key key org-sql-db-config))
            (funcall fun (if flag `(,flag ,target ,@args) (cons target args)) async)
          (error (format "%s not specified" key)))))
  (org-sql--case-mode org-sql-db-config
    (mysql
     (send #'org-sql--exec-mysql-command-nodb "-D" :database args async))
    (postgres
     (send #'org-sql--exec-postgres-command-nodb "-d" :database args async))
    (sqlite
     (org-sql--exec-sqlite-command args async))
    (sqlserver
     (send #'org-sql--exec-sqlserver-command-nodb "-d" :database args async)))))

(defun org-sql--send-sql-file (sql-cmd async)
  "Send SQL-CMD to the configured client.
SQL-CMD will be saved in a temporary file and sent to client from
there. If ASYNC is t, the client will be run in an asynchronous
process."
  (-let ((tmp-path (->> (round (float-time))
                        (format "%sorg-sql-cmd-%s" (temporary-file-directory))))
         (sql-cmd (org-sql--case-mode org-sql-db-config
                    ((mysql postgres sqlite) sql-cmd)
                    (sqlserver (format "set nocount on; %s" sql-cmd)))))
    (f-write sql-cmd 'utf-8 tmp-path)
    (let ((res (org-sql--case-mode org-sql-db-config
                 (mysql
                  (org-sql-send-sql (format "source %s" tmp-path) async))
                 (postgres
                  (org-sql-send-sql (format "\\i %s" tmp-path) async))
                 (sqlite
                  (org-sql-send-sql (format ".read %s" tmp-path) async))
                 (sqlserver
                  ;; I think ":r tmp-path" should work here to make this
                  ;; analogous with the others
                  (org-sql--exec-sqlserver-command `("-i" ,tmp-path) async)))))
      (if (not async)
          (f-delete tmp-path)
        (if (process-live-p res)
            (set-process-sentinel res (lambda (p e) (f-delete tmp-path)))
          (f-delete tmp-path)))
      res)))

(defun org-sql--send-transaction (statements)
  "Send STATEMENTS to the configured database client.
STATEMENTS will be formated to a single transaction (eg with
\"BEGIN; ... COMMIT;\")."
  (->> (org-sql--format-sql-transaction org-sql-db-config statements)
       (org-sql-send-sql)))

(defun org-sql--group-hooks (hooks)
  "Return HOOKS with statements grouped.
Returned list will be like (INSIDE-TRANS OUTSIDE-TRANS)."
  (-some->> hooks
    ;; t = INSIDE
    (--map (pcase it
             (`(file ,path) (cons nil (f-read-text path)))
             (`(file+ ,path) (cons t (f-read-text path)))
             (`(sql ,cmd) (cons nil cmd))
             (`(sql+ ,cmd) (cons t cmd))
             (e (error "Unknown hook definition: %s" e))))
    (-separate #'car)
    ;; (INSIDE AFTER)
    (--map (-map #'cdr it))))

(defun org-sql--send-transaction-with-hook (pre-hooks post-hooks trans-stmts)
  "Send TRANS-STMTS to the configured database client.
STATEMENTS will be formated to a single transaction (eg with
\"BEGIN; ... COMMIT;\"). Additionally, any hook statements in
using PRE-HOOKS and POST-HOOKS will be appended before or after
TRANS-STATEMENTS (either inside or outside the transaction
boundaries depending on the hook)."
  (-let* (((pre-in-trans before-trans) (org-sql--group-hooks pre-hooks))
          ((post-in-trans after-trans) (org-sql--group-hooks post-hooks))
          (ts (->> (append pre-in-trans trans-stmts post-in-trans)
                   (org-sql--format-sql-transaction org-sql-db-config)))
          (bs (-some->> before-trans (s-join "")))
          (as (-some->> after-trans (s-join ""))))
    (org-sql--send-sql-file (concat bs ts as) org-sql-async)))

;;;
;;; Public API
;;;

(defun org-sql-send-sql (sql-cmd &optional async)
  "Execute SQL-CMD in the configured database.
See `org-sql-db-config' for how to chose and configure the
database connection. If ASYNC is t, the client command will be
spawned in an asynchronous process."
  (let ((args (org-sql--case-mode org-sql-db-config
                (mysql `("-e" ,sql-cmd))
                (postgres `("-c" ,sql-cmd))
                (sqlite `(,sql-cmd))
                (sqlserver `("-Q" ,(format "SET NOCOUNT ON; %s" sql-cmd))))))
    (org-sql--exec-command-in-db args async)))

;;; database admin

;; table layer

(defun org-sql-create-tables ()
  "Create required tables in the database.
See `org-sql-db-config' for how to configure the database
connection."
  (->> (org-sql--format-create-tables org-sql-db-config org-sql--table-alist)
       (org-sql--send-transaction)))

(defun org-sql-drop-tables ()
  "Drop all tables in the database pertinent to org-sql.
See `org-sql-db-config' for how to configure the database
connection."
  (->> (org-sql--get-drop-table-statements org-sql-db-config)
       (org-sql--send-transaction)))

(defun org-sql-list-tables ()
  "List all tables in the database.
See `org-sql-db-config' for how to configure the database
connection. Note this will return all tables in the database, not
just those necessarily dedicated to org-sql. If the case of
postgres and sql-server, only return tables in the default
schema (or the schema defined by the :schema keyword)."
  (-let (((sql-cmd parse-fun)
          (org-sql--case-mode org-sql-db-config
            (mysql
             (list "SHOW TABLES;"
                   (lambda (s)
                     (let ((s* (s-trim s)))
                       (unless (equal s* "") (s-lines s*))))))
            (postgres
             (org-sql--with-config-keys (:schema) org-sql-db-config
               (let ((schema* (or schema "public")))
                 (list (format "\\dt %s.*" schema*)
                       (lambda (s)
                         (->> (s-trim s)
                              (s-lines)
                              (--map (s-split "|" it))
                              (--filter (equal schema* (car it)))
                              (--map (cadr it))))))))
            (sqlite
             (list ".tables"
                   (lambda (s)
                     (--mapcat (s-split " " it t) (s-lines s)))))
            (sqlserver
             (org-sql--with-config-keys (:schema) org-sql-db-config
               (let* ((schema* (or schema "dbo")))
                 (list (format "SELECT schema_name(schema_id), name FROM sys.tables;" schema*)
                       (lambda (s)
                         (let ((s* (s-trim s)))
                           (unless (equal "" s*)
                             (->> (s-lines s*)
                                  (--map (-let (((s-name t-name) (s-split "|" it)))
                                           (cons (s-trim s-name) (s-trim t-name))))
                                  (--filter (equal schema* (car it)))
                                  (--map (cdr it)))))))))))))
    (org-sql--on-success* (org-sql-send-sql sql-cmd)
      (funcall parse-fun it-out))))

;; database layer

;; NOTE for any server database it doesn't make any sense to "create" it here
;; (way too many variables) so error and inform the user to do it themselves

(defun org-sql-create-db ()
  "Create the org-sql database.
See `org-sql-db-config' for how to configure the database
connection. Note that this will error on all by SQLite since
org-sql does not assume you have full root privileges on the
server implementations."
  (org-sql--case-mode org-sql-db-config
    ((mysql postgres sqlserver)
     (error "Must manually create database using admin privileges"))
    (sqlite
     ;; this is a silly command that should work on all platforms (eg doesn't
     ;; require `touch' to make an empty file)
     (org-sql--on-success* (org-sql--exec-sqlite-command '(".schema") nil)
       ;; return a dummy return-code and stdout message
       '(0 . "")))))

(defun org-sql-drop-db ()
  "Drop the org-sql database.
See `org-sql-db-config' for how to configure the database
connection. Note that this will error on all by SQLite since
org-sql does not assume you have full root privileges on the
server implementations."
  (org-sql--case-mode org-sql-db-config
    ((mysql postgres sqlserver)
     (error "Must manually drop database using admin privileges"))
    (sqlite
     (org-sql--with-config-keys (:path) org-sql-db-config
       (delete-file path)
       ;; return a dummy return-code and stdout message
       '(0 . "")))))

(defun org-sql-db-exists ()
  "Return t if the configured database exists.
See `org-sql-db-config' for how to configure the database
connection."
  (org-sql--case-mode org-sql-db-config
    (mysql
     (org-sql--with-config-keys (:database) org-sql-db-config
       (let ((cmd (format "SHOW DATABASES LIKE '%s';" database)))
         (org-sql--on-success* (org-sql--exec-mysql-command-nodb `("-e" ,cmd) nil)
           (equal database (car (s-lines it-out)))))))
    (postgres
     (org-sql--with-config-keys (:database) org-sql-db-config
       (let ((cmd (format "SELECT 1 FROM pg_database WHERE datname='%s';" database)))
         (org-sql--on-success* (org-sql--exec-postgres-command-nodb `("-c" ,cmd) nil)
           (equal "1" (s-trim it-out))))))
    (sqlite
     (org-sql--with-config-keys (:path) org-sql-db-config
       (file-exists-p path)))
    (sqlserver
     (org-sql--with-config-keys (:database) org-sql-db-config
       (let ((cmd (format "SET NOCOUNT ON;SELECT 1 FROM sys.databases WHERE name = '%s';" database)))
         (org-sql--on-success* (org-sql--exec-sqlserver-command-nodb `("-Q" ,cmd) nil)
           (equal "1" (s-trim it-out))))))))

;; composite admin functions

(defun org-sql-init-db ()
  "Initialize the org-sql database.
This means the database will be created (in the case of SQLite if
it does not already exist) and the required tables will be
created.

Note that in the case of all but SQLite, additional steps outside
this package is required to set up the database itself, the
schema (in the case of Postgres and SQL-Server), and
permissions/access. In the case of SQLite, the only permission
required is the filesystem permissions to create the database
file.

Permissions required: CREATE TABLE (and CREATE TYPE in the case
of Postgres)

See `org-sql-db-config' for how to set up the database
connection. Set `org-sql-post-init-hooks' to run SQL commands for
additional setup after the core initialization this function
provides (eg setting up indexes, triggers, etc as desired).

Setting `org-sql-async' to t will allow this function's client
process to run asynchronously."
  (org-sql--case-mode org-sql-db-config
    ((mysql postgres sqlserver)
     nil)
    (sqlite
     (org-sql-create-db)))
  (->> (org-sql--format-create-tables org-sql-db-config org-sql--table-alist)
       (org-sql--send-transaction-with-hook nil org-sql-post-init-hooks)))

(defun org-sql-reset-db ()
  "Initialize the org-sql database.
In the case of SQLite, this will delete the database file, create
a new database, and populate it with the required tables. In all
other cases, this function will drop all tables pertinent to
org-sql and create them again.

Permissions required: DROP TABLE, CREATE TABLE (also ALTER TABLE
in the case of SQL-Server to drop the foreign key constraints)

See `org-sql-db-config' for how to set up the database
connection. Set `org-sql-pre-reset-hooks' to run SQL commands to
teardown any other customized database features as
required (presumably those created with
`org-sql-post-init-hooks') before this function's core reset SQL
commands are run. Note that all the DROP TABLE statements are run
with CASCADE where appropriate, so any triggers or indexes
attached to the org-sql tables will be dropped assuming the
database implementation allows this and setting additional
explicit DROP for this key might not be necessary.

Setting `org-sql-async' to t will allow this function's client
process to run asynchronously."
  (org-sql--case-mode org-sql-db-config
    ((mysql postgres sqlserver)
     nil)
    (sqlite
     (org-sql-drop-db)))
  (let ((drop-tbl-stmts
         (org-sql--case-mode org-sql-db-config
           ((mysql postgres sqlserver)
            (org-sql--get-drop-table-statements org-sql-db-config))
           (sqlite nil))))
    (org-sql--send-transaction-with-hook org-sql-pre-reset-hooks
                                         org-sql-post-init-hooks
                                         drop-tbl-stmts)))

;;; CRUD functions
;;
;; These functions don't require admin access to set up the tables (and as such
;; assume they are either set up by the admin functions above or by some other
;; mechanism); all that they need is permission to INSERT/DELETE/SELECT rows in
;; tables

(defun org-sql-dump-table (tbl-name &optional as-plist)
  "Return contents of table TBL-NAME.

The returned contents will be a list of lists where each list is
a row in the table and each value in the list is the value in
each column of that row in the order it appears in the database.
If AS-PLIST is t, each row list will be a plist where the keys
are the columns names like :column-name.

Permissions required: SELECT

See `org-sql-db-config' for how to configure the database
connection."
  (let ((cmd (org-sql--format-select-statement org-sql-db-config nil tbl-name)))
    (org-sql--on-success* (org-sql-send-sql cmd)
      (if as-plist
          (let ((col-names (->> (alist-get tbl-name org-sql--table-alist)
                                (alist-get 'columns)
                                (-map #'car))))
            (org-sql--parse-output-to-plist org-sql-db-config col-names it-out))
        (org-sql--parse-output-to-list org-sql-db-config it-out)))))

(defun org-sql-push-to-db ()
  "Push current org-file state to the org-sql database.

The database will be updated to reflect the current state of
all org-file on disk for which there is an entry in `org-sql-files'.

See `org-sql-db-config' for how to set up the database
connection. Set `org-sql-post-push-hooks' to run additional SQL
commands after the update finishes (for example, running a
procedure based on the new data).

Permissions required: INSERT, DELETE

Setting `org-sql-async' to t will allow this function's client
process to run asynchronously."
  (let ((inhibit-message t))
    (org-save-all-org-buffers))
  (->> (org-sql--get-transactions)
       (org-sql--send-transaction-with-hook nil org-sql-post-push-hooks)))

(defun org-sql-clear-db ()
  "Clear the org-sql database.

All data will be deleted from the tables, but the tables
themselves will not be deleted.

See `org-sql-db-config' for how to set up the database
connection. Set `org-sql-post-clear-hooks' to run additional SQL
commands after the update finishes (for example, running a
procedure based on the new data).

Permissions required: DELETE

Setting `org-sql-async' to t will allow this function's client
process to run asynchronously."
  (->> (org-sql--format-table-name org-sql-db-config 'outlines)
       (format "DELETE FROM %s;")
       (list)
       (org-sql--send-transaction-with-hook nil org-sql-post-clear-hooks)))

;;; interactive functions
;;
;; these are wrappers around the more useful functions above

(defmacro org-sql--on-user-success (form name)
  "Execute FORM with optional messaging for failure and success.
NAME is an identifier used in the success/error messages if
printed."
  `(org-sql--on-success ,form
    (progn
      (when org-sql-debug
        (message "Debug output for %s" ,name)
        (message (if (equal it-out "") "Run Successfully" it-out)))
      (message "%s completed" ,name))
    (progn
      (message "%s failed" ,name)
      (when org-sql-debug
        (message it-out)))))

(defun org-sql-user-init ()
  "Init the database with default table layout.
Calls `org-sql-init-db'."
  (interactive)
  (message "Initializing the Org SQL database")
  (org-sql--on-user-success (org-sql-init-db) "org-sql-init-db"))

(defun org-sql-user-push ()
  "Push current org-file state to the database.
Calls `org-sql-push-to-db'."
  (interactive)
  (message "Pushing data to Org SQL database")
  (org-sql--on-user-success (org-sql-push-to-db) "org-sql-push-to-db"))

(defun org-sql-user-clear-all ()
  "Remove all entries in the database.
Calls `org-sql-clear-db'."
  (interactive)
  (if (y-or-n-p "Really clear all? ")
      (progn
        (message "Clearing the Org SQL database")
        (org-sql--on-user-success (org-sql-clear-db) "org-sql-clear-db"))
    (message "Aborted")))

(defun org-sql-user-reset ()
  "Reset the database with default table layout.
Calls `org-sql-reset-db'."
  (interactive)
  (if (y-or-n-p "Really reset database? ")
      (progn
        (message "Resetting the Org SQL database")
        (org-sql--on-user-success (org-sql-reset-db) "org-sql-reset-db"))
    (message "Aborted")))

(provide 'org-sql)
;;; org-sql.el ends here
