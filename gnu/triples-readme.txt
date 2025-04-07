                               ━━━━━━━━━
                                TRIPLES
                               ━━━━━━━━━


The `triples' package is a standard database package designed for use in
other emacs modules.  It works with either the builtin sqlite in Emacs
29 or the [emacsql] package, and provides a simple way of storing
entities and their associated schema.  The triples package is well
suited to graph-like applications, where links between entities are
important.  The package has wrappers for most common operations, but it
is anticipated that occasionally client modules would need to make their
own sqlite calls.  Many different database instances can be handled by
the `triples' package.  It is expected that clients supply the database
connection.  However, a standard triples database can be used, which is
defined in `triples-default-database-filename', and used when no
filename is used to connect to by clients of the triples library.

This package is useful for simple applications that don't want to write
their own SQL calls, as well as more complicated applications that want
to store many different kinds of objects without having to set up and
manage a variety of tables, especially when there is a graph-like
relationship between the entities.  It also is suited for applications
where different packages want to store different data about the same set
of entities, or store the same data about very different sets of
entities.  For example, having everything that has a creation time be
treated uniformly, regardless of the type of entity, is something that
would be require more advanced solutions in normal SQL but is standard
and easy in a Triple database.  These benefits are due to the fact that
the storage is extremely regular and flexible, with a schema defining
multiple types that are independent of each other, and with all the
schema being software-managed, but installed in the database itself.
The disadvantage is that it can be significantly more inefficient.
However, for the kind of applications that emacs typically uses, the
inefficiencies typically are not significant.


[emacsql] <https://github.com/magit/emacsql>


1 Installing
════════════

  This module is available through GNU ELPA, and can be installed as
  normal.  However, most of the time this module is only useful in
  concert with another module which uses it as a library and will
  declare it as a dependency, so unless you are planning on developing
  with it, there is usually no need to install it directly.


2 Maturity
══════════

  This module is somewhat new and should be considered beta quality.

  While it has basic functionality, there are significant parts, such as
  a querying language, that are missing.  Whether anyone needs such
  parts will determine the priority in which they get built.


3 Using the `triples' library
═════════════════════════════

3.1 Types and Schema
────────────────────

  `triples' employs a design in which each entity can be a member of
  many /types/, and each /type/ has multiple /properties/.  The
  properties that a type has is defined by /schema/.  Let's take an
  example:

  ┌────
  │ ;; We assume a database called db has already been set up.
  │ (triples-add-schema db 'person
  │        '(name :base/unique t :base/type string)
  │        '(age :base/unique t :base/type integer))
  │ (triples-add-schema db 'employee
  │        '(id :base/unique t :base/type integer)
  │        '(manager :base/unique t)
  │        '(reportees :base/virtual-reversed employee/manager))
  └────

  This adds a type called `person', which can be set on any entity.
  There's another type called `employee', which can also be set,
  independently of other types.  This schema is stored in the database
  itself, so the database can function properly regardless on what elisp
  has been loaded.  The schema can be redefined multiple times without
  any issues.

  The `person' has 2 properties, `name', and `age'.  They are both
  marked as unique, so they take a single value, not a list.  If
  `:base/unique' was not true, the value would be a list.  We also
  specify what type it is, which can be any elisp type.  `employee' is
  similarly constructed, but has an interesting property, `reportees',
  which is a `base/virtual-reversed' property, meaning that it is
  supplied with values, but rather can get them from the reversed
  relation of `employee/manager'.

  We'll explore how these types are used can be used in the section
  after next.


3.2 The triples concept
───────────────────────

  A triple is a unit of data consisting of a /subject/, a /predicate/,
  an /object/, and, optionally, internal metadata about the unit.  The
  triple can be thought of as a link between the subject and object via
  the predicate.

  Let's say that, as in the example above, we want to store someone's
  name.  The triples would be a /subject/ that uniquely identifies the
  person, a /predicate/ that indicates the link between subject and
  object is about a name, and the object, which is the name value.

  The object can become the subject, and this explains how the
  `base/virtual-reversed' predicate works.  If Bob is the manager of
  Alice, then there could be a triple with Alice as the subject,
  `manager' as the predicate, and Bob as the object.  But we can also
  find the reversed links, and ask who all are all the people that Bob
  manages.  In this case, Bob is the subject, and Alice is the object.
  However, we don't actually need to store this information and try to
  keep it in sync, we can just get it by querying for when the Bob is
  the object and `manager' is the predicate.

  The ideas behind the database and notes on design can be found in the
  [triples-design.org file].


[triples-design.org file] <file:triples-design.org>


3.3 Connecting
──────────────

  Before a database can be used, it should be connected with.  This is
  done by the `triples-connect' function, which can be called with a
  filename or without.  If a filename isn't given, a default one for the
  triples library, given in `triples-default-database-filename' is used.
  This provides a standard database for those that want to take
  advantage of the possibilities of having data from different sources
  that can build on each other.

  An example of using this standard database is simply:
  ┌────
  │ (let ((db (triples-connect)))
  │   (do-something-with db)
  │   (do-something-else-with db))
  └────
  You could also use a global variable to hold the database connection,
  if you need the database to be active during many user actions.


3.4 Setting and retrieving
──────────────────────────

  A subject can be set all at once (everything about the subject), or
  dealt with per-type.  For example, the following are equivalent:

  ┌────
  │ (triples-delete-subject db "alice")
  │ (triples-set-type db "alice" 'person :name "Alice Aardvark" :age 41)
  │ (triples-set-type db "alice" 'employee :id 1901 :manager "bob")
  └────

  ┌────
  │ (triples-set-subject db "alice" '(person :name "Alice Aardvark" :age 41)
  │ 		     '(employee :id 1901 :manager "bob"))
  └────

  In the second, the setting of the entire subject implies deleting
  everything previously associated with it.

  Here is how the data is retrieved:

  ┌────
  │ (triples-get-subject db "alice")
  └────
  Which returns, assuming we have "catherine" and "dennis" who have
  "alice" as their `employee/manager':
  ┌────
  │ '(:person/name "Alice Aardvark" :person/age 41 :employee/id 1901 :employee/manager "bob" :employee/reportees '("catherine" "dennis"))
  └────

  Or,
  ┌────
  │ (triples-get-type db "alice" 'employee)
  └────
  Which returns
  ┌────
  │ '(:manager "bob" :reportees '("catherine" "dennis"))
  └────

  Note that these subject names are just for demonstration purposes, and
  wouldn't make good subjects because they wouldn't be unique in
  practice.  See [our document on triples design] for more information.

  There are other useful functions, including:
  • `triples-get-types', which gets all the types a subject has,
  • `triples-delete-subject', which deletes all data associated with a
    subject,
  • `triples-with-predicate', gets all triples that is about a specific
    property,
  • `triples-subject-with-predicate-object', get all subjects whose
    predicate is equal to /object/,
  • `triples-subjects-of-type', get all subjects which have a particular
    type.
  • `triples-search', get all properties where a predicate matches given
    text.  Can take an optional limit to restrict the number of results.
  • `triples-remove-schema-type' , remove a type and all associated data
    from the schema (should be rarely used).


[our document on triples design] <file:triples-design.org>


3.5 Predicates, with type and without
─────────────────────────────────────

  Sometimes the triples library will require predicates that are without
  type, and sometimes with type, or "combined predicates".  The rule is
  that if the type is already specified in the function, it does not
  need to be respecified.  If the type is not specified, it is included
  in the combined predicate.

  When returning data, if data is from just one type, the type is not
  returned in the returned predicates.  If the data is from multiple
  types, the type is returned as combined predicates.


3.6 Using direct SQL access
───────────────────────────

  Sometimes clients of this library need to do something with the
  database, and the higher-level triples functionality doesn't help.  If
  you would like lower-level functionality into handling triples, you
  can use the same low-level methods that the rest of this library uses.
  These start with `triples-db-'.
  • `triples-db-insert': Add a triple.  Uses SQL's `REPLACE' command, so
    there can't be completely duplicate triples (including the property,
    which often can serve as a disambiguation mechanism).
  • `triples-db-delete': Delete triples matching the arguments.  Empty
    arguments match everything, so `(triples-db-delete db)' will delete
    all triples.
  • `triples-db-delete-subject-predicate-prefix': Delete triples
    matching subjects and with predicates with a certain prefix.  This
    can't be done with `triples-db-delete' because that method uses
    exact matching for all arguments, and this uses prefix matching for
    the predicate.
  • `triples-db-select-pred-op': Select triples that contain, for a
    predicate, an object with some relationship to the passed in value.
    This function lets you look for values equal to, greater, less, than
    or, "like", the passed in value.
  • `triples-db-select': Select triples matching any of the parts of the
    triple.  Like `triples-db-delete', empty arguments match everything.
    You can specify exactly what to return with a selector.

  Sometimes this still doesn't cover what you might want to do.  In that
  case, you should write your own direct database access.  However,
  please follow the coding patterns for the functions above in writing
  it, so that the code works with both Emacs 29's builtin sqlite, and
  `emacsql'.


3.7 Search
──────────

  Triples supports [SQLite's FTS5 extension], which lets you run full
  text searches with scored results over text objects in the triples
  database.  This will create new FTS tables to store the data necessary
  for the search.  It is only available using the built-in sqlite in
  Emacs 29.1 and later.  To enable:

  ┌────
  │ (require 'triples-fts)
  │ (triples-fts-setup db)
  │ 
  │ ;; If you need to rebuild the index
  │ (triples-fts-rebuild db)
  │ 
  │ ;; Find the subjects for all objects that contain "panda", ordering by most
  │ ;; relevant to least.
  │ (triples-fts-query-subject db "panda")
  │ 
  │ ;; Find the subjects for all objects with the predicate `description/text' (type
  │ ;; description, property text) that contain the word "panda", ordering by most
  │ ;; relevant to least.
  │ (triples-fts-query-subject db "description/text:panda")
  │ 
  │ ;; The same, but with substitution with an abbreviation.
  │ (triples-fts-query-subject db "desc:panda" '(("desc" . "description/text")))
  └────

  This is different than `triples-search' which does a straight text
  match on a particular predicate only, and returns results without
  ranking them.


[SQLite's FTS5 extension] <https://www.sqlite.org/fts5.html>


3.8 Backups
───────────

  If your application wants to back up your database, the function
  `triples-backup' provides the capability to do so safely.  It can be
  called like:
  ┌────
  │ (triples-backup db db-file 3)
  └────
  Where `db' is the database, `db-file' is the filename where that
  database is stored, and `3' is the number of most recent backup files
  to keep.  All older backup files will be deleted.  The backup is
  stored where other emacs file backups are kept, defined by
  `backup-directory-alist'.

  The `triples-backups' module provides a way to backup a database in a
  way defined in the database itself (so multiple clients of the same
  database can work in a sane way together).  The number of backups to
  be kept, along with the "strategy" of when we want backups to happen
  is defined once per database.
  ┌────
  │ ;; Set up a backup configuration if none exists.
  │ (require 'triples-backups)
  │ (unless (triples-backups-configuration db)
  │   (triples-backups-setup db 3 'daily))
  └────

  Once this is set up, whenever a change happens, simply call
  `triples-backups-maybe-backup' with the database and the filename
  where the database was opened from, which will back up the database if
  appropriate.  This should be done after any important database write,
  once the action, at the application level, is finished.  The triples
  module doesn't know when an appropriate point would be, so this is up
  to the client to run.
  ┌────
  │ (defun my-package-add-data (data)
  │   (my-package-write-new-data package-db data)
  │   (triples-backups-maybe-backup db db-filename))
  └────


4 Using `triples' to develop apps with shared data
══════════════════════════════════════════════════

  One possibility that arises from a design with entities (in triples
  terms, subjects) having multiple decomposable types like is done in
  the `triples' library is the possibility of many modules using the
  same database, each one adding their own data, but being able to make
  use out of each other's data.

  For example, in the examples above we have a simple system for storing
  data about people and employees.  If another module adds a type for
  annotations, now you can potentially annotate any entity, including
  people and employees.  If another module adds functionality to store
  and complete on email addresses, now people, employees, and
  potentially types added by other modules such as organizations could
  have email addresses.

  If this seems to fit your use case, you may want to try to just use
  the default database.  The downside of this is that nothing prevents
  other modules from changing, corrupting or deleting your data.
