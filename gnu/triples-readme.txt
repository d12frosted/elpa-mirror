			       ━━━━━━━━━
				TRIPLES
			       ━━━━━━━━━


Table of Contents
─────────────────

1. Installing
2. Maturity
3. Types and Schema
4. The triples concept
5. Setting and retrieving
6. Predicates, with type and without
7. Using direct SQL access


The `triples' module is a standard database module designed for use in
other emacs modules.  It works with either the builtin sqlite in Emacs
29 or the [emacsql] module, and provides a simple way of storing
entities and their associated schema.  The triples module is well suited
to graph-like applications, where links between entities are important.
The module has wrappers for most common operations, but it is
anticipated that occasionally client modules would need to make their
own sqlite calls.  Many different database instances can be handled by
the `triples' module.  It is expected that clients supply the database
connection.


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

  This module is very new should be considered alpha quality.

  While it has basic functionality, there are significant parts, such as
  a querying language, that are missing.  Whether anyone needs such
  parts will determine the priority in which they get built.


3 Types and Schema
══════════════════

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


4 The triples concept
═════════════════════

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


5 Setting and retrieving
════════════════════════

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

  There are other useful functions, including:
  • `triples-get-types', which gets all the types a subject has,
  • `triples-delete-subject', which deletes all data associated with a
    subject,
  • `triples-with-predicate', gets all triples that is about a specific
    property,
  • `triples-with-predicate-object', get all subjects whose predicate is
    equal to /object/,
  • `triples-subjects-of-type', get all subjects which have a particular
    type.


6 Predicates, with type and without
═══════════════════════════════════

  Sometimes the triples library will require predicates that are without
  type, and sometimes with type, or "combined predicates".  The rule is
  that if the type is already specified in the function, it does not
  need to be respecified.  If the type is not specified, it is included
  in the combined predicate.

  When returning data, if data is from just one type, the type is not
  returned in the returned predicates.  If the data is from multiple
  types, the type is returned as combined predicates.


7 Using direct SQL access
═════════════════════════

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
  • `triples-db-select-predicate-object-fragment': Select triples that
    contain an object partially in which the fragment appears.
  • `triples-db-select': Select triples matching any of the parts of the
    triple.  Like `triples-db-delete', empty arguments match everything.
    You can specify exactly what to return with a selector.

  Sometimes this still doesn't cover what you might want to do.  In that
  case, you should write your own direct database access.  However,
  please follow the coding patterns for the functions above in writing
  it, so that the code works with both Emacs 29's builtin sqlite, and
  `emacsql'.
