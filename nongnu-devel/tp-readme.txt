1 `tp.el'
═════════

  Some functions, classes and methods to make it easier to create
  transient menus that send complex POST, PUT, or PATCH requests to JSON
  APIs.

  For more about transient, see <https://github.com/magit/transient>.

  NB: the code is very green so there'll likely be breaking changes.

  A typical use-case is where you have a single endpoint that takes many
  different parameters. It's handy for a user to be able to set all the
  options, then make a single request to change all the settings on the
  server. It's also expected that they'll be able to view all the
  current settings on the server, and make modifications to them for
  sending.

  The classes and methods define some transient behaviours that make
  sense for dealing with APIs:

  • We handle fetching and saving current server settings, and
    initialize our transients with the values fetched
  • We compare the state of a current transient option against the
    server values
  • We distinguish the formatting of server settings and current
    transient setting
  • When reading a string from the user, we provide the server setting
    as default input
  • We can seemlessly handle making requests with arrays,
    i.e. `source[key]', or `field[1][name]' parameters
  • We can easily fetch an infix's allowed values for `completing-read'
  • We (ususally) only send changed values to the server.


2 classes
═════════

  We define three classes for our infixes, all subclassed off
  `transient-option'.

  We also implement format-value and read methods to customize their
  behaviour.


2.1 `tp-option'
───────────────

  Our generic option class, from which our other classes inherit.

  Behaviour:

  • Format: show selected option, highlighted if changed, commented if
    default
  • Read: prompt to select an option using `completing-read'

  By default we always read, which means calling an infix never unsets
  it, but always either switches the value or prompts to update it.


2.2 `tp-option-str'
───────────────────

  A class for reading strings.

  Behaviour:

  • Format: the value from the server is displayed commented, changed
    values are highlighted.
  • Read: read a string, with the server value as initial input.


2.3 `tp-boolean'
────────────────

  We implement a boolean off `transient-option' rather than using
  transient's switches because we need to be able to explicitly send
  requests with either boolean value, whereas transient's switches are
  ignored if set to nil.

  Behaviour:

  • Format: display the true/false state next to the description
  • Read: directly switch the item's value


3 tp methods
════════════

  Apart from implementing existing transient methods, we define some of
  our own.


3.1 `tp-get-server-val'
───────────────────────

  Fetches the current value from the server. This can be reimplemented
  if the data to fetch is in some funky JSON rabbit hole.


3.2 `tp-arg-changed-p'
──────────────────────

  Compares the option provided against the current value on the server.


4 parsing
═════════

  `tp.el' currently parses JSON data into transient-specific
  alists. Nested values are in dotted `(parent.child . "value")'
  pairs. To parse such alists for sending to the server, there is
  `tp-parse-args-for-send' (see below).

  JSON data can be complex, and `tp.el' doesn't aim to implement a
  general parser. It's also possible that the way to obtain data from an
  API and the way it must be sent back differ in terms of nesting and
  field names, which makes completely automating or abstracting away the
  parsing aspect improbable.


4.1 JSON > transient
────────────────────

  When setting initial values of the transient, we fetch and parse data
  from the server:

  `tp-return-data' takes 3 argumements:

  • `fetch-fun', a data fetching function as its first argument, this
    should return JSON data parsed into Elisp
  • `editable-var' (optional), a list of strings, the names of the JSON
    fields that the data returned should be filtered by. this allows us
    to parse a limited set of our JSON into the transient (eg user
    settings, where the JSON return is the complete user object, but not
    all sections can be edited)
  • `field' (optional), the name of a JSON field whose cdr contains the
    data we want to retain.


4.2 transient > JSON
────────────────────

  This step has to be done in your transient's suffix function before
  sending data to the server. `tp.el' provides the following functions
  to help doing so:

  • `tp-parse-transient-args-for-send' calls two or three utility
    functions on a transient alist, parsing them back into Elisp JSON
    for sending as request parameters. If you don't want all of them to
    be called you can implement them manually.
  • `tp-only-changed-args' filters the data for only those options which
    have been changed in the transient.
  • `tp-dots-to-arrays' converts nested argument keys (ie `parent.child'
    into `parent[child]')
  • `tp-bools-to-strs' converts Elisp JSON booleans into string booleans
    (if you are sending query parameters rather than JSON data to the
    server.


5 requests
══════════

  `tp.el' doesn't actually implement any requests. if you want a library
  for requests, check out <https://codeberg.org/martianh/fedi.el>.

  `fedi.el' also contains utilities for converting the JSON alists that
  `tp.el' returns into request parameters.


6 examples
══════════

  • <https://codeberg.org/martianh/fj.el/src/branch/main/fj-transient.el>
  • <https://codeberg.org/martianh/mastodon.el/src/branch/develop/lisp/mastodon-transient.el>
