                             ━━━━━━━━━━━━━
                              ANNOTATE.EL
                             ━━━━━━━━━━━━━


[https://elpa.nongnu.org/nongnu/annotate.svg]

[http://melpa.org/packages/annotate-badge.svg]

[http://stable.melpa.org/packages/annotate-badge.svg]


[https://elpa.nongnu.org/nongnu/annotate.svg]
<https://elpa.nongnu.org/nongnu/annotate.svg>

[http://melpa.org/packages/annotate-badge.svg]
<http://melpa.org/#/annotate>

[http://stable.melpa.org/packages/annotate-badge.svg]
<http://stable.melpa.org/#/annotate>


1 introduction
══════════════

  This package provides a minor mode `annotate-mode', which can add
  annotations to arbitrary files without changing the files
  themselves. This is very useful for code reviews. When `annotate-mode'
  is active, `C-c C-a' will create, edit, or delete annotations.
  <https://raw.githubusercontent.com/bastibe/annotate.el/master/example.png>


2 Usage
═══════

2.1 Quick start
───────────────

  With an active region, `C-c C-a' creates a new annotation for that
  region. With no active region, `C-c C-a' will create an annotation for
  the word under point. If point is on an annotated region, `C-c C-a'
  will edit that annotation instead of creating a new one. Typing `C-c
  C-d' or clearing the annotation deletes them.

  Use `C-c ]' to jump to the next annotation and `C-c [' to jump to the
  previous annotation.


2.2 Metadata
────────────

  The current database for annotations is contained in the file
  indicated by the variable `annotate-file' (`~/.emacs.d/annotations' by
  default) but each user can change this value in a dynamic way using
  the command `annotate-switch-db'. This command will take care to
  refresh/redraw all annotations in the buffers that uses
  `annotate-mode'.

  The database holds the hash of each annotated file so it can print a
  warning if the file has been modified outside Emacs (for example).

  Warning can be suppressed setting the variable
  `annotate-warn-if-hash-mismatch' to nil.

  Please note that switching database, in this context, means rebinding
  the aforementioned variable (`annotate-file'). This means than no more
  than a single database can be active for each Emacs session.

  If an empty annotation database (in memory) is saved the database file
  is deleted instead, if `annotate-database-confirm-deletion' is non nil
  (the default) a confirmation action is asked to the user before
  actually remove the file from the file system.


◊ 2.2.0.1 related customizable variable

  • `annotate-file'
  • `annotate-warn-if-hash-mismatch'
  • `annotate-database-confirm-deletion'


2.2.1 Non centralized database
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  To use multiple database in the same Emacs session `annotate-file'
  should be made [buffer-local],

  see:

  [this thread] and, in particular [this message].

  Finally, if the customizable variable `annotate-file-buffer-local' is
  non-nil (default `nil'), for each annotated file an annotation
  database is saved under the same directory that contains the annotated
  file.

  The name of the annotation database is built concatenating the name of
  the annotated file without the optional extension and the string value
  bound to the customizable variable
  `annotate-buffer-local-database-extension' (default: `notes'), example
  follows:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   annotated file    annotations file     
  ────────────────────────────────────────
   /home/user/foo.c  /home/user/foo.notes 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Important note: if `/home/user/foo.notes' exists, *will be
  overwritten*.


[buffer-local]
<https://www.gnu.org/software/emacs/manual/html_node/elisp/Buffer_002dLocal-Variables.html>

[this thread] <https://github.com/bastibe/annotate.el/issues/68>

[this message]
<https://github.com/bastibe/annotate.el/issues/68#issuecomment-728218022>

◊ 2.2.1.1 related customizable variable

  • `annotate-file-buffer-local'
  • `annotate-buffer-local-database-extension'


2.2.2 Uninstalling
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Users of [no-littering] can take advantage of its packages generated
  files management.


[no-littering] <https://github.com/emacscollective/no-littering>


2.3 keybindings
───────────────

2.3.1 `C-c C-a' (function annotate-annotate)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Creates a new annotation for that region.

  With no active region, `C-c C-a' will create an annotation for the
  word under point. If point is on an annotated region, `C-c C-a' will
  edit that annotation instead of creating a new one. Clearing the
  annotation deletes them.

  If `annotate-annotation-confirm-deletion' is non nil (the default is
  *nil*) a confirmation action is asked, using `y-or-n-p', to the user
  before actually remove the annotation.

  If point is the newline character and the customizable variable
  `annotate-endline-annotate-whole-line' is not nil (default is non nil)
  the whole line is annotated (or the next if the line is empty).

  If the line contains a single annotation that cover all the line,
  annotating the newline will ask to edit the annotation. If
  `annotate-endline-annotate-whole-line' is nil annotating a newline
  will signal an error.

  With a numeric prefix the annotations will be displayed with the faces
  indicated in `annotate-endline-annotate-whole-line' and
  `annotate-annotation-text-faces', respectively. The numeric prefix is
  used as index in the lists bound to the aforementioned variables.

  The first theme can be addressed by the prefix `1', the second by the
  prefix `2' and so on.


◊ 2.3.1.1 related customizable variable

  • `annotate-annotation-column';
  • `annotate-annotation-confirm-deletion';
  • `annotate-annotation-max-size-not-place-new-line';
  • `annotate-annotation-position-policy';
  • `annotate-endline-annotate-whole-line';
  • `annotate-annotation-text-faces'.


2.3.2 `C-c C-d'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Delete an annotation under point, if such annotation exists.

  If `annotate-annotation-confirm-deletion' is non nil (the default is
  *nil*) a confirmation action is asked, using `y-or-n-p', to the user
  before actually remove the annotation.


◊ 2.3.2.1 related customizable variable

  • `annotate-annotation-confirm-deletion'.


2.3.3 `C-c ]' (function annotate-goto-next-annotation)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Jump to the next annotation.


2.3.4 `C-c [' (function annotate-goto-previous-annotation)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Jump to the previous annotation.


2.3.5 `C-c C-s' (function annotate-show-annotation-summary)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Show summary window.

  A window with a list of annotated files together with their
  annotations is shown. If `annotate-summary-ask-query' is non nil
  (default is `t') then a prompt is shown where the user can insert a
  query to filter the annotation database, see "Query Language" below.

  The summary window allow editing and removing of annotation using the
  provided buttons.

  The annotation text can be pressed to and will open the annotated
  file, placing the cursor at the point where the corresponding
  annotated text appears.


◊ 2.3.5.1 related customizable variable

  • `annotate-summary-ask-query'.


3 Exporting
═══════════

  Annotations can be exported `annotate-export-annotations' as commented
  unified diffs, like this:

  <https://raw.githubusercontent.com/bastibe/annotate.el/master/diff-example.png>

  Alternatively, they can be integrated `annotate-integrate-annotations'
  as comments into the current buffer, like this:

  <https://raw.githubusercontent.com/bastibe/annotate.el/master/integrate-example.png>


◊ 3.0.0.1 related customizable variable

  • `annotate-integrate-marker'
  • `annotate-diff-export-options'
  • `annotate-integrate-highlight'
  • `annotate-fallback-comment'


4 Importing
═══════════

  An annotation database file can be imported using the command
  `annotate-import-annotations'.

  When importing, overlapping annotations will be merged in a single
  annotation with the new annotated text that maximizes the portion of
  text annotated, e.g.

  ┌────
  │ The quick brown fox ← text
  │  ^^^^^^^^           ← first annotation
  │       ********      ← second annotation
  │  +++++++++++++      ← merged annotation
  └────

  The text of the merged annotation is the concatenated text of the two
  annotations.

  Note that importing a database will modify permanently the file bound
  to the variable `annotate-file'. If unsure of the results, backup that
  file before importing.


◊ 4.0.0.1 related customizable variable

  • `annotate-database-confirm-import'.


5 Alternative visualization of annotations
══════════════════════════════════════════

  For typographically difficult scenarios (or just because you prefer
  it), such as variable-width fonts or overlay-heavy modes, the default
  visualization system that renders the annotation into the buffer could
  not properly works.

  In this case the users can switch to a "pop-up" style annotation
  setting to a non-nil value the variable `annotate-use-echo-area'.

  When such variable's value is not null, moving the mouse pointer over
  the annotated text will temporary show the annotation.

  The actual visuals of this "pop-up" can be different depending of your
  system's setup (see [this pull request] for a couple of examples.

  Moreover if `annotate-use-echo-area' and
  `annotate-print-annotation-under-cursor' value *both* non null,
  placing the cursor over an annotated text region will print the
  annotation's text in the minibuffer prefixed by the value of
  customizable variable `annotate-print-annotation-under-cursor-prefix',
  after a delay (in seconds) defined by the variable
  `annotate-print-annotation-under-cursor-delay'.

  Another alternative way to show annotations is provided by the
  command: `annotate-summary-of-file-from-current-pos'.

  Calling this command will show a summary window that prints all the
  annotations related to annotated text that appears (in the active
  buffer) beyond the current cursor position.


[this pull request] <https://github.com/bastibe/annotate.el/pull/81>

◊ 5.0.0.1 related customizable variable

  • `annotate-use-echo-area'
  • `annotate-print-annotation-under-cursor'
  • `annotate-print-annotation-under-cursor-prefix'
  • `annotate-print-annotation-under-cursor-delay'
  • `annotate-summary-of-file-from-current-pos'.


6 Other commands
════════════════

6.1 annotate-switch-db
──────────────────────

  This command will ask the user for a new annotation database files,
  load it and refresh all the annotations contained in each buffer where
  annotate minor mode is active.

  See the docstring for more information and [this thread] for a
  possible workflow where this command could be useful.


[this thread] <https://github.com/bastibe/annotate.el/issues/68>


6.2 annotate-toggle-annotation-text
───────────────────────────────────

  Shows or hides annotation's text under cursor.


6.3 annotate-toggle-all-annotations-text
────────────────────────────────────────

  Shows or hides the annotation's text in the whole buffer.


7 More documentation
════════════════════

  Please check `M-x customize-group RET annotate' as there is extensive
  documentation for each customizable variable.


8 BUGS
══════

8.1 Known bugs
──────────────

  • Annotations in org-mode source blocks will be underlined, but the
    annotations don't show up. This is likely a fundamental
    incompatibility with the way source blocks are highlighted and the
    way annotations are displayed.

  • Because of a limitation in the Emacs display routines
    `scroll-down-line' could get stuck on a annotated line. So no fix
    can be provided by the authors of `annotate.el', a possible
  workaround is to call the command with a numeric prefix equals to one
  plus the number of annotation text lines below the annotated text.

  For example:

  ┌────
  │ foo bar baz
  │ annotation
  └────

  needs a prefix of 2: `C-u 2 M-x scroll-down-line'

  But note that:

  ┌────
  │ foo bar baz   annotation
  └────

  Needs no prefix.

  • Deleting the first character of an annotated text will remove the
    annotation (this turned out to be useful, though).


8.2 Report bugs
───────────────

  To report bugs please, point your browser to the [issue tracker].


[issue tracker] <https://github.com/bastibe/annotate.el/issues>


9 Query Language
════════════════

  The summary window can shows results filtered by criteria specified
  with a very simple query language, the basis syntax for that language
  is shown below:

  ┌────
  │ [file-mask] [(and | or) [not] regex-note [(and | or) [not] regexp-note ...]]
  └────

  where:

  file-mask
        is a regular expression that should match the path of file the
        annotation refers to;
  and, or, not
        you guess? Classics logical operators;
  regex-note
        the text of annotation must match this regular expression.


9.1 Examples
────────────

  ┌────
  │ lisp$ and TODO
  └────

  matches the text `TODO' in all lisp files

  Parenthesis can be used for the expression related to the text of
  annotation, like this:

  ┌────
  │ lisp$ and (TODO or important)
  └────

  the same as above but checks also for string `important'

  ┌────
  │ /home/foo/
  └────

  matches all the annotation that refers to file in the directory
  `/home/foo'

  ┌────
  │ /home/foo/ and not minor
  └────

  matches all the annotation that refers to file in the directory
  `/home/foo' and that not contains the text `minor'.

  ┌────
  │ .* and "not"
  └────

  the quotation mark (") can be used to escape strings.

  As a shortcut, an empty query will match everything (just press
  `return' at prompt).


10 FAQ
══════

  Sometimes the package does not respect the customizable variable's
  value of `annotate-annotation-position-policy', is this a bug?

  No it is not, when a line which is using a non default font is
  annotated the software force the `:new-line' policy, that is the
  annotation will be displayed on a new line regardless of the value of
  the variable mentioned in the question.

  This is necessary to prevent the annotation to be pushed beyond the
  window limits if an huge font is used by the annotated text.


11 LICENSE
══════════

  This package is released under the MIT license, see file [LICENSE]


[LICENSE] <./LICENSE>
