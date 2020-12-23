;;; org-sql.el --- Org-Mode SQL converter -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Nathan Dwarshuis

;; Author: Nathan Dwarshuis <natedwarshuis@gmail.com>
;; Keywords: org-mode, data
;; Package-Version: 20201222.206
;; Package-Commit: ddbab360a49d4c0cab964cd1fdb80d2135a10272
;; Homepage: https://github.com/ndwarshuis/org-sql
;; Package-Requires: ((emacs "27.1") (s "1.12") (dash "2.17") (org-ml "5.4.3"))
;; Version: 1.1.0

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
;; appropriate.

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
;;  2) convert the updates/deletes/inserts into meta query language (MQL, an
;;     internal, database agnostic representation of the SQL statements to be
;;     sent)
;;    - inserts will be constructed using `org-element'/`org-ml' from target
;;      files on disk
;;  3) format MQL to database-specific SQL statements
;;  4) send SQL statements to the configured database

;; The code is roughly arranged as follows:
;; - constants
;; - customization variables
;; - stateless functions
;; - stateful IO functions

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'dash)
(require 's)
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
   '(:file-path :headline-offset :entry-offset :note-text :header-text :old-ts :new-ts))
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
  (defconst org-sql--mql-schema
    '((files
       (desc . "Each row stores metadata for one tracked org file")
       (columns
        (:file_path :desc "path to the org file"
                    :type text)
        (:md5 :desc "md5 checksum of the org file"
              :type text
              :constraints (notnull))
        (:size :desc "size of the org file in bytes"
               :type integer
               :constraints (notnull)))
       (constraints
        (primary :keys (:file_path))))


      (headlines
       (desc . "Each row stores one headline in a given org file and its metadata")
       (columns
        (:file_path :desc "path to file containing the headline"
                    :type text)
        (:headline_offset :desc "file offset of the headline's first character"
                          :type integer)
        (:headline_text :desc "raw text of the headline"
                        :type text
                        :constraints (notnull))
        (:keyword :desc "the TODO state keyword"
                  :type text)
        (:effort :desc "the value of the Effort property in minutes"
                 :type integer)
        (:priority :desc "character value of the priority"
                   :type text)
        (:is_archived :desc "true if the headline has an archive tag"
                      :type boolean
                      :constraints (notnull))
        (:is_commented :desc "true if the headline has a comment keyword"
                       :type boolean
                       :constraints (notnull))
        (:content :desc "the headline contents"
                  :type text))
       (constraints
        (primary :keys (:file_path :headline_offset))
        (foreign :ref files
                 :keys (:file_path)
                 :parent-keys (:file_path)
                 :on_delete cascade
                 :on_update cascade)))

      (headline_closures
       (desc . "Each row stores the ancestor and depth of a headline relationship (eg closure table)")
       (columns
        (:file_path :desc "path to the file containing this headline"
                    :type text)
        (:headline_offset :desc "offset of this headline"
                          :type integer)
        (:parent_offset :desc "offset of this headline's parent"
                        :type integer)
        (:depth :desc "levels between this headline and the referred parent"
                :type integer))
       (constraints
        (primary :keys (:file_path :headline_offset :parent_offset))
        (foreign :ref headlines
                 :keys (:file_path :headline_offset)
                 :parent-keys (:file_path :headline_offset)
                 :on_delete cascade
                 :on_update cascade)
        (foreign :ref headlines
                 :keys (:file_path :parent_offset)
                 :parent-keys (:file_path :headline_offset)
                 :on_delete cascade
                 :on_update cascade)))

      (timestamps
       (desc . "Each row stores one timestamp")
       (columns
        (:file_path :desc "path to the file containing this timestamp"
                    :type text)
        (:headline_offset :desc "offset of the headline containing this timestamp"
                          :type integer
                          :constraints (notnull))
        (:timestamp_offset :desc "offset of this timestamp"
                           :type integer)
        (:raw_value :desc "text representation of this timestamp"
                    :type text
                    :constraints (notnull))
        (:is_active :desc "true if the timestamp is active"
                    :type boolean
                    :constraints (notnull))
        (:warning_type :desc "warning type of this timestamp"
                       :type enum
                       :allowed (all first))
        (:warning_value :desc "warning shift of this timestamp"
                        :type integer)
        (:warning_unit :desc "warning unit of this timestamp "
                       :type enum
                       :allowed (hour day week month year))
        (:repeat_type :desc "repeater type of this timestamp"
                      :type enum
                      :allowed (catch-up restart cumulate))
        (:repeat_value :desc "repeater shift of this timestamp"
                       :type integer)
        (:repeat_unit :desc "repeater unit of this timestamp"
                      :type enum
                      :allowed (hour day week month year))
        (:time_start :desc "the start time (or only time) of this timestamp"
                     :type integer
                     :constraints (notnull))
        (:time_end :desc "the end time of this timestamp"
                   :type integer)
        (:start_is_long :desc "true if the start time is in long format"
                        :type boolean
                        :constraints (notnull))
        (:end_is_long :desc "true if the end time is in long format"
                      :type boolean))
       (constraints
        (primary :keys (:file_path :timestamp_offset))
        (foreign :ref headlines
                 :keys (:file_path :headline_offset)
                 :parent-keys (:file_path :headline_offset)
                 :on_delete cascade
                 :on_update cascade)))

      (planning_entries
       (desc . "Each row stores the metadata for headline planning timestamps.")
       (columns
        (:file_path :desc "path to the file containing the entry"
                    :type text)
        (:headline_offset :desc "file offset of the headline with this tag"
                          :type integer)
        (:planning_type :desc "the type of this planning entry"
                        :type enum
                        :allowed (closed scheduled deadline))
        (:timestamp_offset :desc "file offset of this entries timestamp"
                           :type integer
                           :constraints (notnull)))
       (constraints
        (primary :keys (:file_path :headline_offset :planning_type))
        (foreign :ref timestamps
                 :keys (:file_path :timestamp_offset)
                 :parent-keys (:file_path :timestamp_offset)
                 :on_delete cascade
                 :on_update cascade)))

      (file_tags
       (desc . "Each row stores one tag at the file level")
       (columns
        (:file_path :desc "path to the file containing the tag"
                    :type text)
        (:tag :desc "the text value of this tag"
              :type text))
       (constraints
        (primary :keys (:file_path :tag))
        (foreign :ref files
                 :keys (:file_path)
                 :parent-keys (:file_path)
                 :on_delete cascade
                 :on_update cascade)))

      (headline_tags
       (desc . "Each row stores one tag")
       (columns
        (:file_path :desc "path to the file containing the tag"
                    :type text)
        (:headline_offset :desc "file offset of the headline with this tag"
                          :type integer)
        (:tag :desc "the text value of this tag"
              :type text)
        (:is_inherited :desc "true if this tag is from the ITAGS property"
                       :type boolean
                       :constraints (notnull)))
       (constraints
        (primary :keys (:file_path :headline_offset :tag :is_inherited))
        (foreign :ref headlines
                 :keys (:file_path :headline_offset)
                 :parent-keys (:file_path :headline_offset)
                 :on_delete cascade
                 :on_update cascade)))

      (properties
       (desc . "Each row stores one property")
       (columns
        (:file_path :desc "path to the file containing this property"
                    :type text)
        (:property_offset :desc "file offset of this property in the org file"
                          :type integer)
        (:key_text :desc "this property's key"
                   :type text
                   :constraints (notnull))
        (:val_text :desc "this property's value"
                   :type text
                   :constraints (notnull)))
       (constraints
        (primary :keys (:file_path :property_offset))
        (foreign :ref files
                 :keys (:file_path)
                 :parent-keys (:file_path)
                 :on_delete cascade
                 :on_update cascade)))

      (file_properties
       (desc . "Each row stores a property at the file level")
       (columns
        (:file_path :desc "path to file containin the property"
                    :type text)
        (:property_offset :desc "file offset of this property in the org file"
                          :type integer))
       (constraints
        (primary :keys (:file_path :property_offset))
        (foreign :ref files
                 :keys (:file_path)
                 :parent-keys (:file_path)
                 :on_delete cascade
                 :on_update cascade)
        (foreign :ref properties
                 :keys (:file_path :property_offset)
                 :parent-keys (:file_path :property_offset)
                 :on_delete cascade
                 :on_update cascade)))

      (headline_properties
       (desc . "Each row stores a property at the headline level")
       (columns
        (:file_path :desc "path to file containin the property"
                    :type text)
        (:property_offset :desc "file offset of this property in the org file"
                          :type integer)
        (:headline_offset :desc "file offset of the headline with this property"
                          :type integer
                          :constraints (notnull)))
       (constraints
        (primary :keys (:file_path :property_offset))
        (foreign :ref headlines
                 :keys (:file_path :headline_offset)
                 :parent-keys (:file_path :headline_offset)
                 :on_delete cascade
                 :on_update cascade)))
      
      (clocks
       (desc . "Each row stores one clock entry")
       (columns
        (:file_path :desc "path to the file containing this clock"
                    :type text)
        (:headline_offset :desc "offset of the headline with this clock"
                          :type integer
                          :constraints (notnull))
        (:clock_offset :desc "file offset of this clock"
                       :type integer)
        (:time_start :desc "timestamp for the start of this clock"
                     :type integer)
        (:time_end :desc "timestamp for the end of this clock"
                   :type integer)
        (:clock_note :desc "the note entry beneath this clock"
                     :type text))
       (constraints
        (primary :keys (:file_path :clock_offset))
        (foreign :ref headlines
                 :keys (:file_path :headline_offset)
                 :parent-keys (:file_path :headline_offset)
                 :on_delete cascade
                 :on_update cascade)))

      (logbook_entries
       (desc . "Each row stores one logbook entry (except for clocks)")
       (columns
        (:file_path :desc "path to the file containing this entry"
                    :type text)
        (:headline_offset :desc "offset of the headline with this entry"
                          :type integer
                          :constraints (notnull))
        (:entry_offset :desc "offset of this logbook entry"
                       :type integer)
        (:entry_type :desc "type of this entry (see `org-log-note-headlines')"
                     :type text)
        (:time_logged :desc "timestamp for when this entry was taken"
                      :type integer)
        (:header :desc "the first line of this entry (usually standardized)"
                 :type text)
        (:note :desc "the text of this entry underneath the header"
               :type text))
       (constraints
        (primary :keys (:file_path :entry_offset))
        (foreign :ref headlines
                 :keys (:file_path :headline_offset)
                 :parent-keys (:file_path :headline_offset)
                 :on_delete cascade
                 :on_update cascade)))

      (state_changes
       (desc . "Each row stores additional metadata for a state change logbook entry")
       (columns
        (:file_path :desc "path to the file containing this entry"
                    :type text)
        (:entry_offset :desc "offset of the logbook entry for this state change"
                       :type integer)
        (:state_old :desc "former todo state keyword"
                    :type text
                    :constraints (notnull))
        (:state_new :desc "updated todo state keyword"
                    :type text
                    :constraints (notnull)))
       (constraints
        (primary :keys (:file_path :entry_offset))
        (foreign :ref logbook_entries
                 :keys (:file_path :entry_offset)
                 :parent-keys (:file_path :entry_offset)
                 :on_delete cascade
                 :on_update cascade)))

      (planning_changes
       (desc . "Each row stores additional metadata for a planning change logbook entry")
       (columns
        (:file_path :desc "path to the file containing this entry"
                    :type text)
        (:entry_offset :desc "offset of the logbook entry for this planning change"
                       :type integer)
        (:timestamp_offset :desc "offset of the former timestamp"
                           :type integer
                           :constraints (notnull)))
       (constraints
        (primary :keys (:file_path :entry_offset))
        (foreign :ref timestamps
                 :keys (:file_path :timestamp_offset)
                 :parent-keys (:file_path :timestamp_offset)
                 :on_delete cascade
                 :on_update cascade)
        (foreign :ref logbook_entries
                 :keys (:file_path :entry_offset)
                 :parent-keys (:file_path :entry_offset)
                 :on_delete cascade
                 :on_update cascade)))

      (links
       (desc . "Each rows stores one link")
       (columns
        (:file_path :desc "path to the file containing this link"
                    :type text)
        (:headline_offset :desc "offset of the headline with this link"
                          :type integer
                          :constraints (notnull))
        (:link_offset :desc "file offset of this link"
                      :type integer)
        (:link_path :desc "target of this link (eg url, file path, etc)"
                    :type text
                    :constraints (notnull))
        (:link_text :desc "text of this link"
                    :type text)
        (:link_type :desc "type of this link (eg http, mu4e, file, etc)"
                    :type text
                    :constraints (notnull)))
       (constraints
        (primary :keys (:file_path :link_offset))
        (foreign :ref headlines
                 :keys (:file_path :headline_offset)
                 :parent-keys (:file_path :headline_offset)
                 :on_delete cascade
                 :on_update cascade))))
    "Org-SQL database schema represented in internal meta query
    language (MQL, basically a giant list)"))

;; TODO what about the windows users?
(defconst org-sql--sqlite-exe "sqlite3"
  "The sqlite client command.")

(defconst org-sql--psql-exe "psql"
  "The postgres client command.")

(defconst org-sql--postgres-createdb-exe "createdb"
  "The postgres 'create database' command.")

(defconst org-sql--postgres-dropdb-exe "dropdb"
  "The postgres 'drop database' command.")

;;;
;;; CUSTOMIZATION OPTIONS
;;;

(defgroup org-sql nil
  "Org mode SQL backend options."
  :tag "Org SQL"
  :group 'org)

;; TODO add sqlite pragma (synchronous and journalmode)
;; TODO add postgres transaction options
(defcustom org-sql-db-config
  (list 'sqlite :path (expand-file-name "org-sql.db" org-directory))
  "Configuration for the org-sql database.

This is a list like (DB-TYPE OPTION-PLIST). The valid keys and
values in OPTION-PLIST depend on the DB-TYPE. Note that all
values in the OPTION-PLIST must be strings.

The following symbols are valid for DB-TYPE:
- `sqlite' (requires the `sqlite3' command)
- `postgres' (requires the `psql', `createdb', and `dropdb'
  commands)

For 'sqlite', the following options are in OPTION-PLIST:
- `:path' (required): the path on disk to use for the database
  file

For 'postgres', the following options are in OPTION-PLIST:
- `:database' (required): the name of the database to use
- `:hostname': the hostname for the database connection
- `:port': the port for the database connection
- `:username': the username for the database connection
- `:password': the password for the database connection (NOTE:
  since setting this option will store the password in plain
  text, consider using a `.pgpass' file\\)"
  ;; TODO add type
  :group 'org-sql)

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

(defcustom org-sql-files nil
  "A list of org files or directories to put into sql database.
Any directories in this list imply that all files within the
directly are added. Only files ending in .org or .org_archive are
considered. See function `org-sql-files'."
  :type '(repeat :tag "List of files and directories" file)
  :group 'org-sql)

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
TYPE must be one of 'boolean', 'text', 'enum', or 'integer'."
  (declare (indent 1))
  (-let (((keys &as &alist 'boolean 'text 'enum 'integer) alist-forms))
    (unless (-none? #'null keys)
      (error "Must provide form for all types"))
    `(cl-case ,type
       (boolean ,@boolean)
       (text ,@text)
       (enum ,@enum)
       (integer ,@integer)
       (t (error "Invalid type: %s" ,type)))))

(defmacro org-sql--case-mode (mode &rest alist-forms)
  "Execute one of ALIST-FORMS depending on MODE.
TYPE must be one of 'sqlite' or 'postgres'."
  (declare (indent 1))
  (-let (((keys &as &alist 'sqlite 'postgres) alist-forms))
    (unless (-none? #'null keys)
      (error "Must provide form for all modes"))
    `(cl-case ,mode
       (postgres ,@postgres)
       (sqlite ,@sqlite)
       (t (error "Invalid mode: %s" ,mode)))))

;; ensure integrity of the metaschema

(eval-when-compile
  (defun org-sql--mql-schema-has-valid-keys (tbl-schema)
    "Verify that TBL-SCHEMA has valid keys in its table constraints."
    (-let* (((tbl-name . (&alist 'constraints 'columns)) tbl-schema)
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

  (defun org-sql--mql-schema-has-valid-parent-keys (tbl-schema)
    "Verify that TBL-SCHEMA has valid keys in its table foreign constraints."
    (cl-flet
        ((is-valid
          (foreign-meta tbl-name)
          (-let* (((&plist :parent-keys :ref) foreign-meta)
                  (parent-meta (alist-get ref org-sql--mql-schema))
                  (parent-columns (-map #'car (alist-get 'columns parent-meta)))
                  (parent-primary (--> (alist-get 'constraints parent-meta)
                                       (alist-get 'primary it)
                                       (plist-get it :keys))))
            ;; any parent keys must have corresponding columns in the referred
            ;; table
            (-some->> (-difference parent-keys parent-columns)
              (-map #'symbol-name)
              (s-join ", ")
              (error "Mismatched foreign keys between %s and %s: %s" tbl-name ref))
            ;; This isn't strictly a requirement (but still good practice); make
            ;; sure the foreign key refer to the primary key in the parent table
            (when (or (-difference parent-keys parent-primary)
                      (-difference parent-primary parent-keys))
              (error "Mismatched foreign and primary keys between %s and %s" tbl-name ref)))))
      (-let* (((tbl-name . meta) tbl-schema)
              (foreign (->> (alist-get 'constraints meta)
                            (--filter (eq (car it) 'foreign))
                            (-map #'cdr))))
        (--each foreign (is-valid it tbl-name)))))

  (-each org-sql--mql-schema #'org-sql--mql-schema-has-valid-keys)
  (-each org-sql--mql-schema #'org-sql--mql-schema-has-valid-parent-keys))

;; ensure MQL constructors are given the right input

(defun org-sql--mql-check-get-schema-keys (tbl-name)
  "Return a list of columns for TBL-NAME.
The columns are retrieved from `org-sql--mql-schema'."
  (let ((valid-keys (->> org-sql--mql-schema
                         (alist-get tbl-name)
                         (alist-get 'columns)
                         (-map #'car))))
    (unless valid-keys (error "Invalid table name: %s" tbl-name))
    valid-keys))

(defun org-sql--mql-check-columns-all (tbl-name plist)
  "Test if keys in PLIST are valid column names for TBL-NAME.
All column keys must be in PLIST."
  (declare (indent 2))
  (let ((valid-keys (org-sql--mql-check-get-schema-keys tbl-name))
        (input-keys (->> (-partition 2 plist)
                         (-map #'car))))
    (-some->> (-difference valid-keys input-keys)
      (error "Keys not given for table %s: %s" tbl-name))
    (-some->> (-difference input-keys valid-keys)
      (error "Keys not valid for table %s: %s" tbl-name))))

(defun org-sql--mql-check-columns-contains (tbl-name plist)
  "Test if keys in PLIST are valid column names for TBL-NAME.
Only some of the column keys must be in PLIST."
  (declare (indent 2))
  (let ((valid-keys (org-sql--mql-check-get-schema-keys tbl-name))
        (input-keys (->> (-partition 2 plist)
                         (-map #'car))))
    (-some->> (-difference input-keys valid-keys)
      (error "Keys not valid for table %s: %s" tbl-name))))

;;; data constructors

;; meta query language (MQL)

(defmacro org-sql--mql-insert (tbl-name &rest plist)
  "Return an MQL-insert list for TBL-NAME.
PLIST is a property list of the columns and values to insert."
  (declare (indent 1))
  (org-sql--mql-check-columns-all tbl-name plist)
  `(list ',tbl-name ,@plist))

(defmacro org-sql--add-mql-insert (acc tbl-name &rest plist)
  "Add a new MQL-insert list for TBL-NAME to ACC.
PLIST is a property list of the columns and values to insert."
  (declare (indent 2))
  `(cons (org-sql--mql-insert ,tbl-name ,@plist) ,acc))

(defmacro org-sql--mql-update (tbl-name set where)
  "Return an MQL-update list for TBL-NAME.
SET is a plist for the updated values of columns and WHERE is a plist of
columns that must be equal to the values in the plist in order for the update
to be applied."
  (declare (indent 1))
  (org-sql--mql-check-columns-contains tbl-name set)
  (org-sql--mql-check-columns-contains tbl-name where)
  `(list ',tbl-name
         (list 'set ,@set)
         (list 'where ,@where)))

(defmacro org-sql--mql-delete (tbl-name where)
  "Return an MQL-delete list for TBL-NAME.
WHERE is a plist of columns that must be equal to the values in
the plist in order for the delete to be applied."
  (org-sql--mql-check-columns-contains tbl-name where)
  `(list ',tbl-name
         (list 'where ,@where)))

;; TODO I forgot select

;; external state

;; TODO this is hilariously inefficient
(defmacro org-sql--map-plist (key form plist)
  "Return PLIST modified with FORM applied to KEY's value."
  (declare (indent 1))
  `(->> (-partition 2 ,plist)
        (--map-when (eq (car it) ,key)
                    (list (car it) (let ((it (cadr it))) ,form)))
        (-flatten-n 1)))

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

(defun org-sql--to-fstate (file-path hash attributes log-note-headings
                                     todo-keywords lb-config tree)
  "Return a plist representing the state of an org buffer.
The plist will include:
- `:file-path': the path to this org file on disk (given by
  FILE-PATH)
- `:md5': the hash of this org file (given by HASH)
- `:attributes': the ATTRIBUTES list for the file as returned via
  `file-attributes'
- `:top-section': the org-element TREE representation of this
  org-file's top section before the first headline
- `:headline': a list of org-element TREE headlines in this org
  file
- `:lb-config' the same list as that supplied to
  `org-ml-headline-get-supercontents' (based on LB-CONFIG)
- `:log-note-matcher': a list of log-note-matchers for this org
  file as returned by `org-sql--build-log-note-heading-matchers'
  (which depends on TODO-KEYWORDS and LOG-NOTE-HEADINGS)"
  (let* ((children (org-ml-get-children tree))
         (top-section (-some-> (assq 'section children) (org-ml-get-children))))
    (list :file-path file-path
          :md5 hash
          :attributes attributes
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

(defun org-sql--to-hstate (fstate headline)
  "Return new hstate set from FSTATE and HEADLINE.

An HSTATE represents the current headline being processed and
will include the follwing keys/values:
- `:file-path' the path to the current file being processed
- `:lb-config' the supercontents config plist
- `:log-note-matcher': a list of log-note-matchers for this org
  file as returned by `org-sql--build-log-note-heading-matchers'
- `:headline' the current headline node."
  (-let (((&plist :file-path f :lb-config c :log-note-matcher m) fstate))
    (list :file-path f
          :lb-config (org-sql--headline-update-supercontents-config c headline)
          :log-note-matcher m
          :headline headline)))

(defun org-sql--update-hstate (hstate headline)
  "Return a new HSTATE updated with information from HEADLINE.
Only the :lb-config and :headline keys will be changed."
  (->> (org-sql--replace-in-plist :headline headline hstate)
       (org-sql--map-plist :lb-config
         (org-sql--headline-update-supercontents-config it headline))))

(defun org-sql--to-fmeta (disk-path db-path hash)
  "Return a plist representing org file status.
DISK-PATH is the path to the org file on disk, DB-PATH is the
path on disk recorded in the database for this org file, and HASH
is the md5 of this org file."
  (list :disk-path disk-path :db-path db-path :hash hash))

;;; SQL string parsing functions

(defun org-sql--parse-output-to-plist (cols out)
  "Parse SQL output string OUT to an plist representing the data.
COLS are the column names as symbols used to obtain OUT."
  (unless (equal out "")
    (->> (s-trim out)
         (s-split "\n")
         (--map (s-split "|" it))
         (--map (-interleave cols it)))))

;;; MQL -> SQL string formatting functions

;; formatting function tree

(defun org-sql--compile-mql-format-function (mode type)
  "Return SQL value formatting function.
The returned function will depend on the MODE and TYPE."
  (cl-flet
      ((quote-string
        (s)
        (format "'%s'" s))
       (escape-string
        (newline s)
        (let ((newline* (format "'||%s||'" newline)))
          (->> (s-replace-regexp "'" "''" s)
               (s-replace-regexp "\n" newline*)))))
    ;; TODO this could be way more elegant (build the lambda with forms)
    (let ((formatter
           (org-sql--case-type type
             (boolean
              (org-sql--case-mode mode
                (postgres (lambda (b) (if (= b 1) "TRUE" "FALSE")))
                (sqlite (lambda (b) (if (= b 1) "1" "0")))))
             (enum (lambda (e) (quote-string (symbol-name e))))
             (integer #'number-to-string)
             (text
              (org-sql--case-mode mode
                (postgres
                 (lambda (s)
                   (quote-string (escape-string "chr(10)" s))))
                (sqlite
                 (lambda (s)
                   (quote-string (escape-string "char(10)" s)))))))))
      (lambda (s) (if s (funcall formatter s) "NULL")))))

(defun org-sql--compile-mql-schema-formatter-alist (mode mql-schema)
  "Return an alist of formatting functions for MQL-SCHEMA.
MODE is the SQL mode. The alist will mirror MSL schema except that the
car for each column will be a formatting function."
  (cl-flet
      ((get-type-function
        (mql-column)
        (-let* (((name . (&plist :type)) mql-column))
          (cons name (org-sql--compile-mql-format-function mode type)))))
    (-let* (((tbl-name . (&alist 'columns)) mql-schema))
      (cons tbl-name (-map #'get-type-function columns)))))

;; helper functions

(defun org-sql--format-mql-plist (formatter-alist sep plist)
  "Format a PLIST to a SQL-compliant string.
FORMATTER-ALIST is an alist of formatting functions matching the keys
in PLIST (whose keys in turn should match columns in the schema).
The keys and values will be formatted like \"key=val\" and
separated by SEP."
  (let ((keys (->> (-slice plist 0 nil 2)
                   (-map #'org-sql--format-mql-column-name)))
        (vals (->> (-partition 2 plist)
                   (--map (funcall (alist-get (car it) formatter-alist) (cadr it))))))
    (-some->> (--zip-with (format "%s=%s" it other) keys vals)
      (s-join sep))))

(defun org-sql--format-mql-column-name (column-name)
  "Return SQL string representation of COLUMN-NAME."
  (if (not (keywordp column-name)) (error "Not a keyword: %s" column-name)
    (s-chop-prefix ":" (symbol-name column-name))))

;; create table

(defun org-sql--format-mql-schema-enum-types (mql-schema)
  "Return a series of CREATE TYPE statements for MQL-SCHEMA.
The SQL statements will create all enum types found in
MQL-SCHEMA."
  (cl-labels
      ((format-column
        (table-name mql-column)
        (-let* (((column-name . (&plist :type :allowed)) mql-column)
                (column-name* (org-sql--format-mql-column-name column-name)))
          (when (and (eq type 'enum) allowed)
            (->> (--map (format "'%s'" it) allowed)
                 (s-join ",")
                 (format "CREATE TYPE enum_%s_%s AS ENUM (%s);" table-name column-name*)))))
       (format-table
        (mql-table)
        (-let (((table-name . (&alist 'columns)) mql-table))
          (-non-nil (--map (format-column table-name it) columns)))))
    (-mapcat #'format-table mql-schema)))

(defun org-sql--format-mql-schema-column-constraints (mql-column-constraints)
  "Return formatted column constraints for MQL-COLUMN-CONSTRAINTS."
  (cl-flet
      ((format-constraint
        (constraint)
        (pcase constraint
          ('notnull "NOT NULL")
          ('unique "UNIQUE")
          ;; TODO add CHECK?
          ;; TODO add PRIMARY KEY?
          (e (error "Unknown constraint %s" e)))))
    (->> mql-column-constraints
         (-map #'format-constraint)
         (s-join " "))))

(defun org-sql--format-mql-schema-type (config tbl-name mql-column)
  "Return SQL string for the type of MQL-COLUMN.
CONFIG is the `org-sql-db-config' list and TBL-NAME is the name
of the table."
  (-let* (((column-name . (&plist :type)) mql-column)
          (column-name* (org-sql--format-mql-column-name column-name)))
    (org-sql--case-mode (car config)
      (sqlite
       (org-sql--case-type type
         (enum "TEXT")
         (text "TEXT")
         (integer "INTEGER")
         (boolean "INTEGER")))
      (postgres
       (org-sql--case-type type
         (enum (format "enum_%s_%s" tbl-name column-name*))
         (text "TEXT")
         (integer "INTEGER")
         (boolean "BOOLEAN"))))))

(defun org-sql--format-mql-schema-columns (config tbl-name mql-columns)
  "Return SQL string for MQL-COLUMNS.
CONFIG is the `org-sql-db-config' list and TBL-NAME is the name
of the table."
  (cl-flet
      ((format-column
        (mql-column)
        (-let* (((name . (&plist :constraints)) mql-column)
                (name* (org-sql--format-mql-column-name name))
                (type* (org-sql--format-mql-schema-type config tbl-name mql-column))
                (column-str (format "%s %s" name* type*)))
          (if (not constraints) column-str
            (->> (org-sql--format-mql-schema-column-constraints constraints)
                 (format "%s %s" column-str))))))
    (-map #'format-column mql-columns)))

(defun org-sql--format-mql-schema-table-constraints (mql-tbl-constraints)
  "Return SQL string for MQL-TBL-CONSTRAINTS."
  (cl-labels
      ((format-primary
        (keyvals)
        (-let* (((&plist :keys) keyvals))
          (->> (-map #'org-sql--format-mql-column-name keys)
               (s-join ",")
               (format "PRIMARY KEY (%s)"))))
       (format-foreign
        (keyvals)
        (-let* (((&plist :ref :keys :parent-keys :on_delete :on_update) keyvals)
                (keys* (->> keys (-map #'org-sql--format-mql-column-name) (s-join ",")))
                (parent-keys* (->> parent-keys
                                   (-map #'org-sql--format-mql-column-name)
                                   (s-join ",")))
                (foreign-str (format "FOREIGN KEY (%s) REFERENCES %s (%s)"
                                     keys* ref parent-keys*))
                (on-delete* (-some->> on_delete
                              (symbol-name)
                              (upcase)
                              (format "ON DELETE %s")))
                (on-update* (-some->> on_update
                              (symbol-name)
                              (upcase)
                              (format "ON UPDATE %s"))))
          (->> (list foreign-str on-delete* on-update*)
               (-non-nil)
               (s-join " "))))
       (format-constraint
        (mql-constraint)
        (pcase mql-constraint
          (`(primary . ,keyvals) (format-primary keyvals))
          (`(foreign . ,keyvals) (format-foreign keyvals)))))
    (-map #'format-constraint mql-tbl-constraints)))

(defun org-sql--format-mql-schema-table (config mql-table)
  "Return CREATE TABLE (...) SQL string for MQL-TABLE.
CONFIG is the `org-sql-db-config' list."
  (-let* (((tbl-name . (&alist 'columns 'constraints)) mql-table))
    (->> (org-sql--format-mql-schema-table-constraints constraints)
         (append (org-sql--format-mql-schema-columns config tbl-name columns))
         (s-join ",")
         (format "CREATE TABLE IF NOT EXISTS %s (%s);" tbl-name))))

(defun org-sql--format-mql-schema (config mql-schema)
  "Return schema SQL string for MQL-SCHEMA.
CONFIG is the `org-sql-db-config' list."
  (let ((create-tables (->> mql-schema
                            (--map (org-sql--format-mql-schema-table config it))
                            (s-join ""))))
    (org-sql--case-mode (car config)
      (postgres
       (let ((create-types (->> (org-sql--format-mql-schema-enum-types mql-schema)
                                (s-join ""))))
         (concat create-types create-tables)))
      (sqlite
       create-tables))))

;; insert

(defun org-sql--format-mql-insert (formatter-alist mql-insert)
  "Return SQL string for MQL-INSERT.
FORMATTER-ALIST is an alist of functions given by
`org-sql--compile-mql-format-function'."
  (-let* (((tbl-name . keyvals) mql-insert)
          (formatter-list (alist-get tbl-name formatter-alist))
          (columns (->> (-slice keyvals 0 nil 2)
                        (-map #'org-sql--format-mql-column-name)
                        (s-join ",")))
          (values (->> (-partition 2 keyvals)
                       (--map (funcall (alist-get (car it) formatter-list) (cadr it)))
                       (s-join ","))))
    (format "INSERT INTO %s (%s) VALUES (%s);" tbl-name columns values)))

;; update

(defun org-sql--format-mql-update (formatter-alist mql-update)
  "Return SQL string for MQL-UPDATE.
FORMATTER-ALIST is an alist of functions given by
`org-sql--compile-mql-format-function'."
  (-let* (((tbl-name . (&alist 'set 'where)) mql-update)
          (formatter-list (alist-get tbl-name formatter-alist))
          (set* (org-sql--format-mql-plist formatter-list "," set))
          (where* (org-sql--format-mql-plist formatter-list " and " where)))
    (format "UPDATE %s SET %s WHERE %s;" tbl-name set* where*)))

;; delete

(defun org-sql--format-mql-delete (formatter-alist mql-delete)
  "Return SQL string for MQL-DELETE.
FORMATTER-ALIST is an alist of functions given by
`org-sql--compile-mql-format-function'."
  (-let* (((tbl-name . (&alist 'where)) mql-delete)
          (formatter-list (alist-get tbl-name formatter-alist)))
    (if (not where) (format "DELETE FROM %s;" tbl-name)
      (->> (org-sql--format-mql-plist formatter-list " and " where)
           (format "DELETE FROM %s WHERE %s;" tbl-name)))))

;; select

(defun org-sql--format-mql-select (formatter-alist mql-select)
  "Return SQL string for MQL-SELECT.
FORMATTER-ALIST is an alist of functions given by
`org-sql--compile-mql-format-function'."
  (-let* (((tbl-name . (&alist 'columns 'where)) mql-select)
          (formatter-list (alist-get tbl-name formatter-alist))
          (columns* (or (-some->> (-map #'org-sql--format-mql-column-name columns)
                          (s-join ","))
                        "*")))
    (if (not where) (format "SELECT %s FROM %s;" columns* tbl-name)
      (->> (org-sql--format-mql-plist formatter-list " AND " where)
           (format "SELECT %s FROM %s WHERE %s;" columns* tbl-name)))))

;;; SQL string -> SQL string formatting functions

(defun org-sql--format-sql-transaction (mode sql-statements)
  "Return SQL string for a transaction.
SQL-STATEMENTS is a list of SQL statements to be included in the

transaction. MODE is the SQL mode."
  (-let ((bare-transaction (-some->> sql-statements
                             (s-join "")
                             (format "BEGIN TRANSACTION;%sCOMMIT;"))))
    ;; TODO might want to add performance options here
    (when bare-transaction
      (org-sql--case-mode mode
        (sqlite (concat "PRAGMA foreign_keys = ON;" bare-transaction))
        (postgres bare-transaction)))))

;;; org-element/org-ml wrapper functions

;; TODO these are all functions that may be included in org-ml in the future
        
(defun org-sql--headline-get-path (headline)
  "Return the path for HEADLINE node.
Path will be a list of offsets for the parent headline and its
parents (with HEADLINE on the right end of the list)."
  (cl-labels
      ((get-path
        (acc node)
        (if (or (null node) (eq 'org-data (car node))) acc
          (get-path (cons (org-ml-get-property :begin node) acc)
                    (org-ml-get-property :parent node)))))
    (get-path nil headline)))
        
(defun org-sql--headline-get-archive-itags (headline)
  "Return archive itags from HEADLINE or nil if none."
  (unless org-sql-exclude-inherited-tags
    (-some-> (org-ml-headline-get-node-property "ARCHIVE_ITAGS" headline)
      (split-string))))

(defun org-sql--headline-get-tags (headline)
  "Return list of tags from HEADLINE."
  (->> (org-ml-get-property :tags headline)
       (-map #'substring-no-properties)))

(defun org-sql--headline-get-contents (headline)
  "Return the contents of HEADLINE.
This includes everything in the headline's section element that
is not the planning, logbook drawer, or property drawer."
  (-some->> (org-ml-headline-get-section headline)
    ;; TODO need a function in org-ml that returns non-meta
    ;; TODO this only works when `org-log-into-drawer' is defined
    (--remove (org-ml-is-any-type '(planning property-drawer) it))
    (--remove (and (org-ml-is-type 'drawer it)
                   (equal (org-element-property :drawer-name it)
                          org-log-into-drawer)))))

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
  (-let* (((&plist :file-path :headline) hstate)
          (headline-offset (org-ml-get-property :begin headline))
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
                                ;; TODO make this function public
                                (org-ml--property-is-eq :begin ts-offset it)))))))
         (get-substring
          (match-bounds)
          (when match-bounds
            (-let (((begin . end) match-bounds))
              (substring header-text begin end)))))
      (let ((old-ts (get-timestamp-node old-state))
            (new-ts (get-timestamp-node new-state)))
        (org-sql--to-entry type
          :file-path file-path
          :entry-offset (org-ml-get-property :begin item)
          :headline-offset headline-offset
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

;; org-element tree -> MQL inserts (see `org-sql--mql-insert')

(defun org-sql--add-mql-insert-headline-logbook-item (acc entry)
  "Add MQL-insert for item ENTRY to ACC."
  (-let (((entry-type . (&plist :entry-offset
                                :header-text
                                :note-text
                                :headline-offset
                                :file-path
                                :ts))
          entry))
    (org-sql--add-mql-insert acc logbook_entries
      :file_path file-path
      :headline_offset headline-offset
      :entry_offset entry-offset
      :entry_type (symbol-name entry-type)
      :time_logged (-some->> ts
                     (org-ml-timestamp-get-start-time)
                     (org-ml-time-to-unixtime))
      :header header-text
      :note note-text)))

(defun org-sql--add-mql-insert-state-change (acc entry)
  "Add MQL-insert for state change ENTRY to ACC."
  (-let (((&plist :entry-offset :file-path :old-state :new-state) (cdr entry)))
    (--> (org-sql--add-mql-insert-headline-logbook-item acc entry)
         (org-sql--add-mql-insert it state_changes
           :file_path file-path
           :entry_offset entry-offset
           :state_old old-state
           :state_new new-state))))

(defun org-sql--add-mql-insert-planning-change (acc hstate entry)
  "Add MQL-insert for planning change ENTRY to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (-let (((&plist :entry-offset :file-path :headline-offset :old-ts) (cdr entry)))
    (--> (org-sql--add-mql-insert-headline-logbook-item acc entry)
         (org-sql--add-mql-insert-timestamp it hstate old-ts)
         (org-sql--add-mql-insert it planning_changes
           :file_path file-path
           :entry_offset entry-offset
           :timestamp_offset (org-ml-get-property :begin old-ts)))))

(defun org-sql--add-mql-insert-headline-logbook-items (acc hstate logbook)
  "Add MQL-inserts for LOGBOOK to ACC.
LOGBOOK is the logbook value of the supercontents list returned
by `org-ml-headline-get-supercontents'. HSTATE is a plist as
returned by `org-sql--to-hstate'."
  ;; TODO what about unknown stuff?
  (-let (((&plist :headline :file-path) hstate))
    (cl-flet
        ((add-entry
          (acc entry)
          (let ((entry-type (car entry)))
            (cond
             ((memq entry-type org-sql-excluded-logbook-types)
              acc)
             ((memq entry-type '(redeadline deldeadline reschedule delschedule))
                 ;; TODO this is inconsistent and it bugs me
              (org-sql--add-mql-insert-planning-change acc hstate entry))
             ((eq entry-type 'state)
              (org-sql--add-mql-insert-state-change acc entry))
             (t
              (org-sql--add-mql-insert-headline-logbook-item acc entry))))))
      (->> (org-ml-logbook-get-items logbook)
           (--map (org-sql--item-to-entry hstate it))
           (-reduce-from #'add-entry acc)))))

(defun org-sql--add-mql-insert-clock (acc hstate clock note-text)
  "Add MQL-insert for CLOCK to ACC.
NOTE-TEXT is either a string or nil representing the clock-note.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (-let (((&plist :headline :file-path) hstate)
         (value (org-ml-get-property :value clock)))
    (org-sql--add-mql-insert acc clocks
      :file_path file-path
      :headline_offset (org-ml-get-property :begin headline)
      :clock_offset (org-ml-get-property :begin clock)
      :time_start (-some-> value
                    (org-ml-timestamp-get-start-time)
                    (org-ml-time-to-unixtime))
      :time_end (-some-> value
                  (org-ml-timestamp-get-end-time)
                  (org-ml-time-to-unixtime))
      :clock_note (unless org-sql-exclude-clock-notes note-text))))

(defun org-sql--add-mql-insert-headline-logbook-clocks (acc hstate logbook)
  "Add MQL-inserts for LOGBOOK to ACC.
LOGBOOK is the logbook value of the supercontents list returned
by `org-ml-headline-get-supercontents'. HSTATE is a plist as
returned by `org-sql--to-hstate'."
  (->> (org-ml-logbook-get-clocks logbook)
       (org-sql--clocks-append-notes hstate)
       (--reduce-from
        (org-sql--add-mql-insert-clock acc hstate (car it) (cdr it))
        acc)))

(defun org-sql--add-mql-insert-headline-properties (acc hstate)
  "Add MQL-insert for each property in the current headline to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (if (eq 'all org-sql-excluded-properties) acc
    ;; TODO only do this once
    (-let* ((ignore-list (append org-sql--ignored-properties-default
                                 org-sql-excluded-properties))
            ((&plist :headline :file-path) hstate)
            (headline-offset (org-ml-get-property :begin headline)))
      (cl-flet
          ((is-ignored
            (node-property)
            (member (org-ml-get-property :key node-property) ignore-list))
           (add-property
            (acc np)
            (let ((property-offset (org-ml-get-property :begin np)))
              (--> (org-sql--add-mql-insert acc properties
                     :file_path file-path
                     :property_offset property-offset
                     :key_text (org-ml-get-property :key np)
                     :val_text (org-ml-get-property :value np))
                   (org-sql--add-mql-insert it headline_properties
                     :file_path file-path
                     :headline_offset headline-offset
                     :property_offset property-offset)))))
        (->> (org-ml-headline-get-node-properties headline)
             (-remove #'is-ignored)
             (-reduce-from #'add-property acc))))))

(defun org-sql--add-mql-insert-headline-tags (acc hstate)
  "Add MQL-insert for each tag in the current headline to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (if (eq 'all org-sql-excluded-tags) acc
    (-let* (((&plist :headline :file-path) hstate)
            (offset (org-ml-get-property :begin headline)))
      (cl-flet
          ((add-tag
            (acc tag inherited)
            (org-sql--add-mql-insert acc headline_tags
              :file_path file-path
              :headline_offset offset
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

(defun org-sql--add-mql-insert-headline-links (acc hstate contents)
  "Add MQL-insert for each link in the current headline to ACC.
CONTENTS is a list corresponding to that returned by
`org-ml-headline-get-supercontents'. HSTATE is a plist as
returned by `org-sql--to-hstate'."
  (if (eq 'all org-sql-excluded-link-types) acc
    (-let* (((&plist :headline :file-path) hstate)
            (offset (org-ml-get-property :begin headline))
            (links (->> (--mapcat (org-ml-match '(:any * link) it) contents)
                        (--remove (member (org-ml-get-property :type it)
                                          org-sql-excluded-link-types)))))
      (cl-flet
          ((add-link
            (acc link)
            (org-sql--add-mql-insert acc links
              :file_path file-path
              :headline_offset offset
              :link_offset (org-ml-get-property :begin link)
              :link_path (org-ml-get-property :path link)
              :link_text (->> (org-ml-get-children link)
                              (-map #'org-ml-to-string)
                              (s-join ""))
              :link_type (org-ml-get-property :type link))))
        (-reduce-from #'add-link acc links)))))

(defun org-sql--add-mql-insert-timestamp (acc hstate timestamp)
  "Add MQL-insert for TIMESTAMP to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (cl-flet
      ((get-resolution
        (time)
        (when time (if (org-ml-time-is-long time) 1 0))))
    (-let* ((start (org-ml-timestamp-get-start-time timestamp))
            (end (org-ml-timestamp-get-end-time timestamp))
            ((&plist :headline :file-path) hstate)
            (headline-offset (org-ml-get-property :begin headline)))
      (org-sql--add-mql-insert acc timestamps
        :file_path file-path
        :headline_offset headline-offset
        :timestamp_offset (org-ml-get-property :begin timestamp)
        :is_active (if (org-ml-timestamp-is-active timestamp) 1 0)
        :warning_type (org-ml-get-property :warning-type timestamp)
        :warning_value (org-ml-get-property :warning-value timestamp)
        :warning_unit (org-ml-get-property :warning-unit timestamp)
        :repeat_type (org-ml-get-property :repeater-type timestamp)
        :repeat_value (org-ml-get-property :repeater-value timestamp)
        :repeat_unit (org-ml-get-property :repeater-unit timestamp)
        :time_start (org-ml-time-to-unixtime start)
        :start_is_long (get-resolution start)
        :time_end (-some-> end (org-ml-time-to-unixtime))
        :end_is_long (get-resolution end)
        :raw_value (org-ml-get-property :raw-value timestamp)))))

(defun org-sql--add-mql-insert-headline-timestamps (acc hstate contents)
  "Add MQL-insert for each timestamp in the current headline to ACC.
CONTENTS is a list corresponding to that returned by
`org-ml-headline-get-supercontents'. HSTATE is a plist as
returned by `org-sql--to-hstate'."
  (if (eq org-sql-excluded-contents-timestamp-types 'all) acc
    (-if-let (pattern (-some--> org-sql--content-timestamp-types
                        (-difference it org-sql-excluded-contents-timestamp-types)
                        (--map `(:type ',it) it)
                        `(:any * (:and timestamp (:or ,@it)))))
        (-let* (((&plist :headline) hstate)
                (timestamps (--mapcat (org-ml-match pattern it) contents))
                (headline-offset (org-ml-get-property :begin headline)))
          (--reduce-from (org-sql--add-mql-insert-timestamp acc hstate it)
                         acc timestamps))
      acc)))

(defun org-sql--add-mql-insert-headline-planning (acc hstate)
  "Add MQL-insert for each planning timestamp in the current headline to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (-let (((&plist :headline :file-path) hstate))
    (-if-let (planning (org-ml-headline-get-planning headline))
        (let ((offset (org-ml-get-property :begin headline)))
          (cl-flet
              ((add-planning-maybe
                (acc type)
                (-if-let (ts (org-ml-get-property type planning))
                    (--> (org-sql--add-mql-insert-timestamp acc hstate ts)
                         (org-sql--add-mql-insert it planning_entries
                           :file_path file-path
                           :headline_offset offset
                           :planning_type (->> (symbol-name type)
                                               (s-chop-prefix ":")
                                               (intern))
                           :timestamp_offset (org-ml-get-property :begin ts)))
                  acc)))
            (--> '(:closed :deadline :scheduled)
                 (-difference it org-sql-excluded-headline-planning-types)
                 (-reduce-from #'add-planning-maybe acc it))))
      acc)))

(defun org-sql--add-mql-insert-headline-closures (acc hstate)
  "Add MQL-insert for parent closures from the current headline to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (-let* (((&plist :headline :file-path) hstate)
          (offset (org-ml-get-property :begin headline)))
    (cl-flet
        ((add-closure
          (acc parent-offset depth)
          (org-sql--add-mql-insert acc headline_closures
            :file_path file-path
            :headline_offset offset
            :parent_offset parent-offset
            :depth depth)))
      (->> (org-sql--headline-get-path headline)
           (reverse)
           (--map-indexed (list it it-index))
           (reverse)
           (--reduce-from (apply #'add-closure acc it) acc)))))

(defun org-sql--add-mql-insert-headline (acc hstate)
  "Add MQL-insert the current headline's metadata to ACC.
HSTATE is a plist as returned by `org-sql--to-hstate'."
  (cl-flet
      ((effort-to-int
        (s)
        (pcase (-some->> s
                 (string-trim)
                 (s-match "^\\(\\([0-9]+\\)\\|\\([0-9]+\\):\\([0-6][0-9]\\)\\)$")
                 (-drop 2))
          (`(nil ,h ,m) (+ (* 60 (string-to-number h)) (string-to-number m)))
          (`(,m) (string-to-number m)))))
    (-let* (((&plist :file-path :lb-config :headline) hstate)
            (supercontents (org-ml-headline-get-supercontents lb-config headline))
            (logbook (org-ml-supercontents-get-logbook supercontents))
            (contents (org-ml-supercontents-get-contents supercontents)))
      (--> (org-sql--add-mql-insert acc headlines
             :file_path file-path
             :headline_offset (org-ml-get-property :begin headline)
             :headline_text (org-ml-get-property :raw-value headline)
             :keyword (org-ml-get-property :todo-keyword headline)
             :effort (-> (org-ml-headline-get-node-property "Effort" headline)
                         (effort-to-int))
             :priority (-some->> (org-ml-get-property :priority headline)
                         (byte-to-string))
             :is_archived (if (org-ml-get-property :archivedp headline) 1 0)
             :is_commented (if (org-ml-get-property :commentedp headline) 1 0)
             :content (-some->> (-map #'org-ml-to-string contents)
                        (s-join "")))
           (org-sql--add-mql-insert-headline-planning it hstate)
           (org-sql--add-mql-insert-headline-tags it hstate)
           (org-sql--add-mql-insert-headline-properties it hstate)
           (org-sql--add-mql-insert-headline-timestamps it hstate contents)
           (org-sql--add-mql-insert-headline-links it hstate contents)
           (org-sql--add-mql-insert-headline-logbook-clocks it hstate logbook)
           (org-sql--add-mql-insert-headline-logbook-items it hstate logbook)))))

(defun org-sql--add-mql-insert-headlines (acc fstate)
  "Add MQL-insert headlines in FSTATE to ACC.
FSTATE is a list given by `org-sql--to-fstate'."
  (-let (((&plist :headlines) fstate))
    (cl-labels
        ((add-headline
          (acc hstate hl)
          (let ((sub (org-ml-headline-get-subheadlines hl))
                (hstate* (if hstate (org-sql--update-hstate hstate hl)
                           (org-sql--to-hstate fstate hl))))
            (--> (org-sql--add-mql-insert-headline acc hstate*)
                 (org-sql--add-mql-insert-headline-closures it hstate*)
                 (--reduce-from (add-headline acc hstate* it) it sub)))))
      (--reduce-from (add-headline acc nil it) acc headlines))))

(defun org-sql--add-mql-insert-file-tags (acc fstate)
  "Add MQL-insert for each file tag in file to ACC.
FSTATE is a list given by `org-sql--to-fstate'."
  (-let (((&plist :file-path :top-section) fstate))
    (cl-flet
        ((add-tag
          (acc tag)
          (org-sql--add-mql-insert acc file_tags
            :file_path file-path
            :tag tag)))
      (->> (--filter (org-ml-is-type 'keyword it) top-section)
           (--filter (equal (org-ml-get-property :key it) "FILETAGS"))
           (--mapcat (s-split " " (org-ml-get-property :value it)))
           (-uniq)
           (-reduce-from #'add-tag acc)))))

(defun org-sql--add-mql-insert-file-properties (acc fstate)
  "Add MQL-insert for each file property in file to ACC.
FSTATE is a list given by `org-sql--to-fstate'."
  (-let (((&plist :file-path :top-section) fstate))
    (cl-flet
        ((add-property
          (acc keyword)
          (-let ((offset (org-ml-get-property :begin keyword))
                 ((key value) (--> (org-ml-get-property :value keyword)
                                   (s-split-up-to " " it 1))))
            (--> (org-sql--add-mql-insert acc properties
                   :file_path file-path
                   :property_offset offset
                   :key_text key
                   :val_text value)
                 (org-sql--add-mql-insert it file_properties
                   :file_path file-path
                   :property_offset offset)))))
      (->> (--filter (org-ml-is-type 'keyword it) top-section)
           (--filter (equal (org-ml-get-property :key it) "PROPERTY"))
           (-reduce-from #'add-property acc)))))

(defun org-sql--add-mql-insert-file (acc fstate)
  "Add MQL-insert for file in FSTATE to ACC.
FSTATE is a list given by `org-sql--to-fstate'."
  (-let (((&plist :file-path :md5 :attributes) fstate))
    (-> (org-sql--add-mql-insert acc files
          :file_path file-path
          :md5 md5
          :size (file-attribute-size attributes)))))

(defun org-sql--fstate-to-mql-insert (fstate)
  "Return all MQL-inserts for FSTATE.
FSTATE is a list given by `org-sql--to-fstate'."
  (-> nil
      (org-sql--add-mql-insert-file fstate)
      (org-sql--add-mql-insert-file-properties fstate)
      (org-sql--add-mql-insert-file-tags fstate)
      (org-sql--add-mql-insert-headlines fstate)
      (reverse)))

(defun org-sql--fmeta-to-mql-update (fmeta)
  "Return MQL-update for FMETA.
FMETA is a list given by `org-sql--to-fmeta'."
  (-let (((&plist :disk-path :hash) fmeta))
    (org-sql--mql-update files (:file_path disk-path) (:md5 hash))))

(defun org-sql--fmeta-to-mql-delete (fmeta)
  "Return MQL-delete for FMETA.
FMETA is a list given by `org-sql--to-fmeta'."
  (-let (((&plist :db-path) fmeta))
    (org-sql--mql-delete files (:file_path db-path))))

;; fmeta function (see `org-sql--to-fmeta')

(defun org-sql--merge-fmeta (disk-fmeta db-fmeta)
  "Return a list of merged fmeta.
Each member of the returned list and the arguments is a list
given by `org-sql--to-fmeta'. DISK-FMETA is fmeta for org files
on disk and DB-FMETA is fmeta for files in the database. This
function will merge the two inputs such that those with common
hashes will be considered equal and the final list will have only
unique hashes."
  (cl-labels
      ((hash<
        (a b)
        (-let (((&plist :hash a-hash) a)
               ((&plist :hash b-hash) b))
          (string< a-hash b-hash)))
       (combine
        (a b)
        (-let (((&plist :disk-path :hash) a)
               ((&plist :db-path :hash) b))
          (org-sql--to-fmeta disk-path db-path hash)))
       (merge
        (acc as bs)
        (pcase (cons as bs)
         (`(nil . nil) acc)
         (`(,as* . nil) (append (reverse as*) acc))
         (`(nil . ,bs*) (append (reverse bs*) acc))
         (`((,a . ,as*) . (,b . ,bs*))
          (cond
           ((hash< a b) (merge (cons a acc) as* bs))
           ((hash< b a) (merge (cons b acc) as bs*))
           (t (merge (cons (combine a b) acc) as* bs*)))))))
    (merge nil (sort disk-fmeta #'hash<) (sort db-fmeta #'hash<))))

(defun org-sql--classify-fmeta (disk-fmeta db-fmeta)
  "Return a list of classified file actions.
DISK-FMETA and DB-FMETA are lists of file cells where each member is like
\(md5 . filepath). Return an alist where the keys represent the
actions to take on the files on disk/in the database. The keys of
the alist will be 'noops', 'inserts', 'updates', and 'deletes'."
  (cl-flet
      ((get-path
        (key alist)
        (alist-get key alist nil nil #'equal))
       (get-group
        (transaction)
        (-let (((&plist :disk-path :db-path) transaction))
          ;; for a given md5, check the corresponding path given for its disk
          ;; location and in the db to determine the action to take
          (cond
           ;; if paths are equal, do nothing
           ((equal disk-path db-path) 'noops)
           ;; if paths non-nil but unequal, assume disk path changed and update
           ((and disk-path db-path) 'updates)
           ;; if path on in db doesn't exist, assume new file and insert
           ((and disk-path (not db-path) 'inserts))
           ;; if path on on disk doesn't exist, assume removed file and delete
           ((and (not disk-path) db-path) 'deletes)
           ;; at least one path should be non-nil, else there is a problem
           (t (error "Transaction classifier: this should not happen"))))))
    (->> (org-sql--merge-fmeta disk-fmeta db-fmeta)
         (-group-by #'get-group))))

;;;
;;; STATEFUL FUNCTIONS
;;;

;;; low-level IO

(defun org-sql--run-command (path &rest args)
  "Execute PATH with ARGS.
Return a cons cell like (RETURNCODE . OUTPUT)."
  (apply #'org-sql--run-command* path nil args))

(defun org-sql--run-command* (path file &rest args)
  "Execute PATH with ARGS and FILE routed to stdin.
Return a cons cell like (RETURNCODE . OUTPUT)."
  (with-temp-buffer
    (let ((rc (apply #'call-process path file (current-buffer) nil args)))
      (cons rc (buffer-string)))))

;;; fmeta -> fstate

(defun org-sql--fmeta-get-fstate (fmeta)
  "Return the fstate for FMETA.
FSTATE is a list as given by `org-sql--to-fstate'."
  (-let* (((&plist :disk-path :hash) fmeta)
          (attributes (file-attributes disk-path)))
          ;; (log-note-headings
          ;;  (or (alist-get disk-path org-sql-log-note-headings-overrides
          ;;                 nil nil #'equal)
          ;;      org-log-note-headings)))
    (with-current-buffer (find-file-noselect disk-path t)
      (let ((tree (org-element-parse-buffer))
            (todo-keywords (-map #'substring-no-properties org-todo-keywords-1))
            (lb-config (list :log-into-drawer org-log-into-drawer
                             :clock-into-drawer org-clock-into-drawer
                             :clock-out-notes org-log-note-clock-out)))
        (org-sql--to-fstate disk-path hash attributes org-log-note-headings
                            todo-keywords lb-config tree)))))

;;; reading fmeta from external state

(defun org-sql--disk-get-fmeta ()
  "Get a list of fmeta for org files on disk.
Each fmeta will have it's :db-path set to nil. Only files in
`org-sql-files' will be considered."
  (cl-flet
      ((get-md5
        (fp)
        (-let (((rc . hash) (org-sql--run-command "md5sum" fp)))
          (if (= 0 rc) (car (s-split-up-to " " hash 1))
            (error "Could not get md5"))))
       (expand-if-dir
        (fp)
        (if (not (file-directory-p fp)) `(,fp)
          (directory-files fp t "\\`.*\\.org\\(_archive\\)?\\'"))))
    (if (stringp org-sql-files)
        (error "`org-sql-files' must be a list of paths")
      (->> (-mapcat #'expand-if-dir org-sql-files)
           (-map #'expand-file-name)
           (-filter #'file-exists-p)
           (--map (org-sql--to-fmeta it nil (get-md5 it)))))))

(defun org-sql--db-get-fmeta ()
  "Get a list of fmeta for the database.
Each fmeta will have it's :disk-path set to nil."
  (-let* ((columns '(:file_path :md5))
          ;; TODO add compile check for this
          (sql-select (org-sql--format-mql-select nil `(files (columns ,@columns))))
          ((rc . out) (org-sql--send-sql sql-select)))
    (if (/= 0 rc) (error out)
      (->> (s-trim out)
           (org-sql--parse-output-to-plist columns)
           (--map (-let (((&plist :md5 h :file_path p) it))
                    (org-sql--to-fmeta nil p h)))))))

(defun org-sql--get-transactions ()
  "Return SQL string of the update transaction.
This transaction will bring the database to represent the same
state as the orgfiles on disk."
  (-let* ((disk-fmeta (org-sql--disk-get-fmeta))
          (db-fmeta (org-sql--db-get-fmeta))
          (mode (car org-sql-db-config))
          (formatter-alist
           (->> org-sql--mql-schema
                (--map (org-sql--compile-mql-schema-formatter-alist mode it))))
          ((&alist 'updates 'inserts 'deletes)
           (org-sql--classify-fmeta disk-fmeta db-fmeta)))
    (cl-flet
        ((inserts-to-sql
          (fmeta)
          (->> (org-sql--fmeta-get-fstate fmeta)
               (org-sql--fstate-to-mql-insert)
               (--map (org-sql--format-mql-insert formatter-alist it))))
         (updates-to-sql
          (fmeta)
          (->> (org-sql--fmeta-to-mql-update fmeta)
               (org-sql--format-mql-update formatter-alist)))
         (deletes-to-sql
          (fmeta)
          (->> (org-sql--fmeta-to-mql-delete fmeta)
               (org-sql--format-mql-delete formatter-alist))))
      (->> (append (-map #'deletes-to-sql deletes)
                   (-map #'updates-to-sql updates)
                   (-mapcat #'inserts-to-sql inserts))
           (org-sql--format-sql-transaction mode)))))

(defun org-sql-dump-update-transactions ()
  "Dump the update transaction to a separate buffer."
  (let ((out (org-sql--get-transactions)))
    (switch-to-buffer "SQL: Org-update-dump")
    (insert (s-replace ";" ";\n" out))))

;;; SQL command wrappers

(defun org-sql--exec-sqlite-command (config-keys &rest args)
  "Execute a sqlite command with ARGS.
CONFIG-KEYS is the plist component if `org-sql-db-config'."
  (-let (((&plist :path) config-keys))
    (apply #'org-sql--run-command org-sql--sqlite-exe (cons path args))))

(defun org-sql--exec-postgres-command-sub (exe config-keys &rest args)
  "Execute a postgres command with ARGS.
CONFIG-KEYS is the plist component if `org-sql-db-config'. EXE is
a symbol for the executate to run and is one of 'psql',
'createdb', or 'dropdb'. The connection options for the postgres
server. will be handled here."
  (-let* (((&plist :hostname :port :username :password) config-keys)
          (h (-some->> hostname (list "-h")))
          (p (-some->> port (list "-p")))
          (u (-some->> username (list "-U")))
          (w '("-w"))
          (process-environment
           (if (not password) process-environment
             (cons (format "PGPASSWORD=%s" password) process-environment)))
          (exe* (cl-case exe
                  (psql org-sql--psql-exe)
                  (createdb org-sql--postgres-createdb-exe)
                  (dropdb org-sql--postgres-dropdb-exe)
                  (t (error "Invalid postgres exe: %s" exe)))))
    (apply #'org-sql--run-command exe* (append h p u w args))))

(defun org-sql--exec-postgres-command (config-keys &rest args)
  "Execute a postgres command with ARGS.
CONFIG-KEYS is the plist component if `org-sql-db-config'. Note this
uses the 'psql' client command in the background."
  (-let* (((&plist :database) config-keys)
          (d (-some->> database (list "-d")))
          (f (list "-At")))
    (apply #'org-sql--exec-postgres-command-sub 'psql config-keys (append d f args))))

(defun org-sql--send-sql (sql-cmd)
  "Execute SQL-CMD.
The database connection will be handled transparently."
  (-let* (((mode . keyvals) org-sql-db-config))
    (org-sql--case-mode mode
      (sqlite
       (org-sql--exec-sqlite-command keyvals sql-cmd))
      (postgres
       (org-sql--exec-postgres-command keyvals "-c" sql-cmd)))))

;; TODO is this necessary now that I am not using a shell to execute?
(defun org-sql--send-sql* (sql-cmd)
  "Execute SQL-CMD as a separate file input.
The database connection will be handled transparently."
  (if (not sql-cmd) '(0 . "")
    (-let* ((tmp-path (format "%sorg-sql-cmd-%s" (temporary-file-directory) (round (float-time))))
            ((mode . keyvals) org-sql-db-config))
      (f-write sql-cmd 'utf-8 tmp-path)
      (let ((res
             (org-sql--case-mode mode
               (sqlite
                (org-sql--exec-sqlite-command keyvals (format ".read %s" tmp-path)))
               (postgres
                (org-sql--exec-postgres-command keyvals "-f" tmp-path)))))
        (f-delete tmp-path)
        res))))

;;; high-level database operations

(defun org-sql--db-exists ()
  "Return t if the configured database exists."
  (-let (((mode . keyvals) org-sql-db-config))
    (org-sql--case-mode mode
      (sqlite
       (-let (((&plist :path) keyvals))
         (file-exists-p path)))
      (postgres
       (-let (((&plist :database) keyvals)
              ((rc . out) (org-sql--exec-postgres-command-sub 'psql keyvals "-qtl")))
         (if (/= 0 rc) (error out)
           (->> (s-split "\n" out)
                (--map (s-trim (car (s-split "|" it))))
                (--find (equal it database)))))))))

(defun org-sql--db-has-valid-schema ()
  "Return t if the configured database has a valid schema.
Note that this currently only tests the existence of the schema's tables."
  (-let* ((table-names (--map (symbol-name (car it)) org-sql--mql-schema))
          ((sql-cmd parse-fun)
           (org-sql--case-mode (car org-sql-db-config)
             (sqlite
              (list ".tables"
                    (lambda (s)
                      (--mapcat (s-split " " it t) (s-lines s)))))
             (postgres
              (list "\\dt"
                    (lambda (s)
                      (->> (s-trim s)
                           (s-lines)
                           (--map (nth 1 (s-split "|" it)))))))))
          ((rc . out) (org-sql--send-sql sql-cmd)))
    (if (/= 0 rc) (error out)
      (org-sql--sets-equal table-names (funcall parse-fun out) :test #'equal))))

(defun org-sql--db-create ()
  "Create the configured database."
  (-let (((mode . keyvals) org-sql-db-config))
    (org-sql--case-mode mode
      (sqlite
       ;; this is a silly command that should work on all platforms (eg doesn't
       ;; require `touch' to make an empty file)
       (org-sql--exec-sqlite-command keyvals ".schema"))
      (postgres
       (-let (((&plist :database) keyvals))
         (org-sql--exec-postgres-command-sub 'createdb keyvals database))))))

(defun org-sql--db-create-tables ()
  "Create the schema for the configured database."
  (let ((sql-cmd (org-sql--format-mql-schema org-sql-db-config org-sql--mql-schema)))
    (org-sql--send-sql sql-cmd)))

(defun org-sql--delete-db ()
  "Delete the configured database."
  (-let (((mode . keyvals) org-sql-db-config))
    (org-sql--case-mode mode
      (sqlite
       (-let (((&plist :path) keyvals))
         (delete-file path)))
      (postgres
       (-let (((&plist :database) keyvals))
         (org-sql--exec-postgres-command-sub 'dropdb keyvals database))))))

;;;
;;; PUBLIC API
;;; 

;;; non-interactive

(defun org-sql-init-db ()
  "Initialize the Org-SQL database."
  (org-sql--db-create)
  (org-sql--db-create-tables))

(defun org-sql-update-db ()
  "Update the Org-SQL database.
This means the state of all files from `org-sql-files' will be
pushed and updated to the database."
  (let ((inhibit-message t))
    (org-save-all-org-buffers))
  (org-sql--send-sql* (org-sql--get-transactions)))

(defun org-sql-clear-db ()
  "Clear the Org-SQL database without deleting it."
  ;; only delete from files as we assume actions here cascade down
  (->> (org-sql--mql-delete files nil)
       (org-sql--format-mql-delete nil)
       (org-sql--send-sql)))

(defun org-sql-reset-db ()
  "Reset the Org-SQL database.
This will delete the database and create a new one with the
required schema."
  (org-sql--delete-db)
  (org-sql-init-db))

;;; interactive

(defun org-sql-user-update ()
  "Update the Org SQL database."
  (interactive)
  ;; TODO need to see if schema is correct?
  (message "Updating Org SQL database")
  (let ((out (org-sql-update-db)))
    (when org-sql-debug
      (print "Debug output for org-sql update")
      (print (if (equal out "") "Run Successfully" out))))
  (message "Org SQL update complete"))

(defun org-sql-user-clear-all ()
  "Remove all entries in the database."
  (interactive)
  (if (y-or-n-p "Really clear all? ")
      (progn
        (message "Clearing Org SQL database")
        (let ((out (org-sql-clear-db)))
          (when org-sql-debug
            (print "Debug output for org-sql clear-all")
            (print (if (equal out "") "Run Successfully" out))))
        (message "Org SQL clear completed"))
    (message "Aborted")))

(defun org-sql-user-reset ()
  "Reset the database with default schema."
  (interactive)
  (if (or (not (org-sql--db-exists))
          (y-or-n-p "Really reset database? "))
      (progn
        (org-sql--delete-db)
        (message "Resetting Org SQL database")
        (let ((out (org-sql-init-db)))
          (when org-sql-debug
            (print "Debug output for org-sql user-reset")
            (print (if (equal out "") "Run Successfully" out))))
        (message "Org SQL reset completed"))
    (message "Aborted")))

(provide 'org-sql)
;;; org-sql.el ends here
