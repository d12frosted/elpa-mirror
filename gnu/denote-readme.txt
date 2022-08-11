	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		 DENOTE: SIMPLE NOTES WITH AN EFFICIENT
			   FILE-NAMING SCHEME

			  Protesilaos Stavrou
			  info@protesilaos.com
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for the Emacs package called `denote' (or `denote.el'), and
provides every other piece of information pertinent to it.

The documentation furnished herein corresponds to stable version 0.5.0,
released on 2022-08-10.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.6.0-dev.

⁃ Package name (GNU ELPA): `denote'
⁃ Official manual: <https://protesilaos.com/emacs/denote>
⁃ Change log: <https://protesilaos.com/emacs/denote-changelog>
⁃ Git repo on SourceHut: <https://git.sr.ht/~protesilaos/denote>
  • Mirrors:
    ⁃ GitHub: <https://github.com/protesilaos/denote>
    ⁃ GitLab: <https://gitlab.com/protesilaos/denote>
⁃ Mailing list: <https://lists.sr.ht/~protesilaos/denote>

If you are viewing the README.org version of this file, please note that
the GNU ELPA machinery automatically generates an Info manual out of it.

Table of Contents
─────────────────

1. COPYING
2. Overview
3. Points of entry
.. 1. Standard note creation
..... 1. The `denote-prompts' option
..... 2. The `denote-templates' option
..... 3. Convenience commands for note creation
.. 2. Create note using Org capture
.. 3. Maintain separate directories for notes
4. Renaming files
.. 1. Rename a single file
.. 2. Rename multiple files at once
.. 3. Rename a single file based on its front matter
.. 4. Rename multiple files based on their front matter
5. The file-naming scheme
.. 1. Sluggified title and keywords
.. 2. Features of the file-naming scheme for searching or filtering
6. Front matter
.. 1. Change the front matter format
.. 2. Regenerate front matter
7. Linking notes
.. 1. Adding a single link
.. 2. Insert links matching a regexp
.. 3. Insert links from marked files in Dired
.. 4. The backlinks’ buffer
.. 5. Writing metanotes
.. 6. Visiting linked files via the minibuffer
.. 7. Miscellaneous information about links
8. Fontification in Dired
9. Minibuffer histories
10. Extending Denote
.. 1. Keep a journal or diary
.. 2. Narrow the list of files in Dired
.. 3. Use Embark to collect minibuffer candidates
.. 4. Search file contents
.. 5. Bookmark the directory with the notes
.. 6. Use the consult-notes package
.. 7. Treat your notes as a project
11. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
12. Sample configuration
13. Contributing
14. Things to do
15. Alternatives to Denote
.. 1. Alternative ideas wih Emacs and further reading
16. Frequently Asked Questions
.. 1. Why develop Denote when PACKAGE already exists?
.. 2. Why not rely exclusively on Org?
.. 3. Why care about Unix tools when you use Emacs?
.. 4. Why many small files instead of few large ones?
.. 5. Does Denote perform well at scale?
.. 6. I add TODOs to my files; will the many files slow down the Org agenda?
.. 7. I want to sort by last modified, why won’t Denote let me?
.. 8. How do you handle the last modified case?
.. 9. Why do I get “Search failed with status 1” when I search for backlinks?
17. Acknowledgements
18. GNU Free Documentation License
19. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2022 Free Software Foundation, Inc.

        Permission is granted to copy, distribute and/or modify
        this document under the terms of the GNU Free
        Documentation License, Version 1.3 or any later version
        published by the Free Software Foundation; with no
        Invariant Sections, with the Front-Cover Texts being “A
        GNU Manual,” and with the Back-Cover Texts as in (a)
        below.  A copy of the license is included in the section
        entitled “GNU Free Documentation License.”

        (a) The FSF’s Back-Cover Text is: “You have the freedom to
        copy and modify this GNU manual.”


2 Overview
══════════

  Denote aims to be a simple-to-use, focused-in-scope, and effective
  note-taking tool for Emacs.  It is based on the following core design
  principles:

  Predictability
        File names must follow a consistent and descriptive naming
        convention ([The file-naming scheme]).  The file name alone
        should offer a clear indication of what the contents are,
        without reference to any other metadatum.  This convention is
        not specific to note-taking, as it is pertinent to any form of
        file that is part of the user’s long-term storage ([Renaming
        files]).

  Composability
        Be a good Emacs citizen, by integrating with other packages or
        built-in functionality instead of re-inventing functions such as
        for filtering or greping.  The author of Denote (Protesilaos,
        aka “Prot”) writes ordinary notes in plain text (`.txt'),
        switching on demand to an Org file only when its expanded set of
        functionality is required for the task at hand ([Points of
        entry]).

  Portability
        Notes are plain text and should remain portable.  The way Denote
        writes file names, the front matter it includes in the note’s
        header, and the links it establishes must all be adequately
        usable with standard Unix tools.  No need for a database or some
        specialised software.  As Denote develops and this manual is
        fully fleshed out, there will be concrete examples on how to do
        the Denote-equivalent on the command-line.

  Flexibility
        Do not assume the user’s preference for a note-taking
        methodology.  Denote is conceptually similar to the Zettelkasten
        Method, which you can learn more about in this detailed
        introduction: <https://zettelkasten.de/introduction/>.  Notes
        are atomic (one file per note) and have a unique identifier.
        However, Denote does not enforce a particular methodology for
        knowledge management, such as a restricted vocabulary or
        mutually exclusive sets of keywords.  Denote also does not check
        if the user writes thematically atomic notes.  It is up to the
        user to apply the requisite rigor and/or creativity in pursuit
        of their preferred workflow ([Writing metanotes]).

  Hackability
        Denote’s code base consists of small and reusable functions.
        They all have documentation strings.  The idea is to make it
        easier for users of varying levels of expertise to understand
        what is going on and make surgical interventions where necessary
        (e.g. to tweak some formatting).  In this manual, we provide
        concrete examples on such user-level configurations ([Keep a
        journal or diary]).

  Now the important part…  “Denote” is the familiar word, though it also
  is a play on the “note” concept.  Plus, we can come up with acronyms,
  recursive or otherwise, of increasingly dubious utility like:

  ⁃ Don’t Ever Note Only The Epiphenomenal
  ⁃ Denote Everything Neatly; Omit The Excesses

  But we’ll let you get back to work.  Don’t Eschew or Neglect your
  Obligations, Tasks, and Engagements.


[The file-naming scheme] See section 5

[Renaming files] See section 4

[Points of entry] See section 3

[Writing metanotes] See section 7.5

[Keep a journal or diary] See section 10.1


3 Points of entry
═════════════════

  There are five ways to write a note with Denote: invoke the `denote',
  `denote-type', `denote-date', `denote-subdirectory', `denote-template'
  commands, or leverage the `org-capture-templates' by setting up a
  template which calls the function `denote-org-capture'.  We explain
  all of those in the subsequent sections.


3.1 Standard note creation
──────────────────────────

  The `denote' command will prompt for a title.  Once that is supplied,
  it will ask for keywords.  The resulting note will have a file name as
  already explained: [The file naming scheme]

  The file type of the new note is determined by the user option
  `denote-file-type' ([Front matter]).

  The keywords’ prompt supports minibuffer completion.  Available
  candidates are those defined in the user option
  `denote-known-keywords'.  More candidates can be inferred from the
  names of existing notes, by setting `denote-infer-keywords' to non-nil
  (which is the case by default).

  Multiple keywords can be inserted by separating them with a comma (or
  whatever the value of the `crm-separator' is—which should be a comma).
  When the user option `denote-sort-keywords' is non-nil (the default),
  keywords are sorted alphabetically (technically, the sorting is done
  with `string-lessp').

  The interactive behaviour of the `denote' command is influenced by the
  user option `denote-prompts' ([The denote-prompts option]).

  The `denote' command can also be called from Lisp.  Read its doc
  string for the technicalities.

  In the interest of discoverability, `denote' is also available under
  the alias `denote-create-note'.


[The file naming scheme] See section 5

[Front matter] See section 6

[The denote-prompts option] See section 3.1.1

3.1.1 The `denote-prompts' option
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The user option `denote-prompts' determines how the `denote' command
  will behave interactively ([Standard note creation]).

  The value is a list of symbols, which includes any of the following:

  • `title': Prompt for the title of the new note.

  • `keywords': Prompts with completion for the keywords of the new
    note.  Available candidates are those specified in the user option
    `denote-known-keywords'.  If the user option `denote-infer-keywords'
    is non-nil, keywords in existing note file names are included in the
    list of candidates.  The `keywords' prompt uses
    `completing-read-multiple', meaning that it can accept multiple
    keywords separated by a comma (or whatever the value of
    `crm-sepator' is).

  • `file-type': Prompts with completion for the file type of the new
    note.  Available candidates are those specified in the user option
    `denote-file-type'.  Without this prompt, `denote' uses the value of
    `denote-file-type'.

  • `subdirectory': Prompts with completion for a subdirectory in which
    to create the note.  Available candidates are the value of the user
    option `denote-directory' and all of its subdirectories.  Any
    subdirectory must already exist: Denote will not create it.

  • `date': Prompts for the date of the new note.  It will expect an
    input like 2022-06-16 or a date plus time: 2022-06-16 14:30.
    Without the `date' prompt, the `denote' command uses the
    `current-time'.

  • `template': Prompts for a KEY among the `denote-templates'.  The
    value of that KEY is used to populate the new note with content,
    which is added after the front matter ([The denote-templates
    option]).

  The prompts occur in the given order.

  If the value of this user option is nil, no prompts are used.  The
  resulting file name will consist of an identifier (i.e. the date and
  time) and a supported file type extension (per `denote-file-type').

  Recall that Denote’s standard file-naming scheme is defined as follows
  ([The file-naming scheme]):

  ┌────
  │ DATE--TITLE__KEYWORDS.EXT
  └────


  If either or both of the `title' and `keywords' prompts are not
  included in the value of this variable, file names will be any of
  those permutations:

  ┌────
  │ DATE.EXT
  │ DATE--TITLE.EXT
  │ DATE__KEYWORDS.EXT
  └────


  When in doubt, always include the `title' and `keywords' prompts.

  Finally, this user option only affects the interactive use of the
  `denote' command (advanced users can call it from Lisp).  For ad-hoc
  interactive actions that do not change the default behaviour of the
  `denote' command, users can invoke these convenience commands:
  `denote-type', `denote-subdirectory', `denote-date'.  They are
  described in the subsequent section ([Convenience commands for note
  creation]).


[Standard note creation] See section 3.1

[The denote-templates option] See section 3.1.2

[The file-naming scheme] See section 5

[Convenience commands for note creation] See section 3.1.3


3.1.2 The `denote-templates' option
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The user option `denote-templates' is an alist of content templates
  for new notes.  A template is arbitrary text that Denote will add to a
  newly created note right below the front matter.

  Templates are expressed as a `(KEY . STRING)' association.

  • The `KEY' is the name which identifies the template.  It is an
    arbitrary symbol, such as `report', `memo', `statement'.

  • The `STRING' is ordinary text that Denote will insert as-is.  It can
    contain newline characters to add spacing.  Below we show some
    concrete examples.

  The user can choose a template either by invoking the command
  `denote-template' or by changing the user option `denote-prompts' to
  always prompt for a template when calling the `denote' command.

  [The denote-prompts option].

  [Convenience commands for note creation].

  Templates can be written directly as one large string.  For example
  (the `\n' character is read as a newline):

  ┌────
  │ (setq denote-templates
  │       '((report . "* Some heading\n\n* Another heading")
  │ 	(memo . "* Some heading
  │ 
  │ * Another heading
  │ 
  │ ")))
  └────

  Long strings may be easier to type but interpret indentation
  literally.  Also, they do not scale well.  A better way is to use some
  Elisp code to construct the string.  This would typically be the
  `concat' function, which joins multiple strings into one.  The
  following is the same as the previous example:

  ┌────
  │ (setq denote-templates
  │       `((report . "* Some heading\n\n* Another heading")
  │ 	(memo . ,(concat "* Some heading"
  │ 			 "\n\n"
  │ 			 "* Another heading"
  │ 			 "\n\n"))))
  └────

  Notice that to evaluate a function inside of an alist we use the
  backtick to quote the alist (NOT the straight quote) and then prepend
  a comma to the expression that should be evaluated.  The `concat' form
  here is not sensitive to indentation, so it is easier to adjust for
  legibility.

  DEV NOTE: We do not provide more examples at this point, though feel
  welcome to ask for help if the information provided herein is not
  sufficient.  We shall expand the manual accordingly.


[The denote-prompts option] See section 3.1.1

[Convenience commands for note creation] See section 3.1.3


3.1.3 Convenience commands for note creation
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Sometimes the user needs to create a note that has different
  requirements from those of `denote' ([Standard note creation]).  While
  this can be achieved globally by changing the `denote-prompts' user
  option, there are cases where an ad-hoc method is the appropriate one
  ([The denote-prompts option]).

  To this end, Denote provides the following convenience interactive
  commands for note creation:

  Create note by specifying file type
        The `denote-type' command creates a note while prompting for a
        file type.

        This is the equivalent to calling `denote' when `denote-prompts'
        is set to `'(file-type title keywords)'.  In practical terms,
        this lets you produce, say, a note in Markdown even though you
        normally write in Org ([Standard note creation]).

        The `denote-create-note-using-type' is an alias of
        `denote-type'.

  Create note using a date
        Normally, Denote reads the current date and time to construct
        the unique identifier of a newly created note ([Standard note
        creation]).  Sometimes, however, the user needs to set an
        explicit date+time value.

        This is where the `denote-date' command comes in.  It creates a
        note while prompting for a date.  The date can be in
        YEAR-MONTH-DAY notation like `2022-06-30' or that plus the time:
        `2022-06-16 14:30'.

        This is the equivalent to calling `denote' when `denote-prompts'
        is set to `'(date title keywords)'.

        The `denote-create-note-using-date' is an alias of
        `denote-date'.

  Create note in a specific directory
        The `denote-subdirectory' command creates a note while prompting
        for a subdirectory.  Available candidates include the value of
        the variable `denote-directory' and any subdirectory thereof
        (Denote does not create subdirectories).

        This is equivalent to calling `denote' when `denote-prompts' is
        set to `'(subdirectory title keywords)'.

        The `denote-create-note-in-subdirectory' is a more descriptive
        alias of `denote-subdirectory'.

  Create note and add a template
        The `denote-template' command creates a new note and inserts the
        specified template below the front matter ([The denote-templates
        option]).  Available candidates for templates are specified in
        the user option `denote-templates'.

        This is equivalent to calling `denote' when `denote-prompts' is
        set to `'(template title keywords)'.

        The `denote-create-note-with-template' is an alias of the
        command `denote-template', meant to help with discoverability.


[Standard note creation] See section 3.1

[The denote-prompts option] See section 3.1.1

[The denote-templates option] See section 3.1.2


3.2 Create note using Org capture
─────────────────────────────────

  For integration with `org-capture', the user must first add the
  relevant template.  Such as:

  ┌────
  │ (with-eval-after-load 'org-capture
  │   (add-to-list 'org-capture-templates
  │ 	       '("n" "New note (with Denote)" plain
  │ 		 (file denote-last-path)
  │ 		 #'denote-org-capture
  │ 		 :no-save t
  │ 		 :immediate-finish nil
  │ 		 :kill-buffer t
  │ 		 :jump-to-captured t)))
  └────

  [ In the future, we might develop Denote in ways which do not require
    such manual intervention.  More user feedback is required to
    identify the relevant workflows. ]

  Once the template is added, it is accessed from the specified key.
  If, for instance, `org-capture' is bound to `C-c c', then the note
  creation is initiated with `C-c c n', per the above snippet.  After
  that, the process is the same as with invoking `denote' directly,
  namely: a prompt for a title followed by a prompt for keywords
  ([Standard note creation]).

  Users may prefer to leverage `org-capture' in order to extend file
  creation with the specifiers described in the `org-capture-templates'
  documentation (such as to capture the active region and/or create a
  hyperlink pointing to the given context).

  IMPORTANT.  Due to the particular file-naming scheme of Denote, which
  is derived dynamically, such specifiers or other arbitrary text cannot
  be written directly in the template.  Instead, they have to be
  assigned to the user option `denote-org-capture-specifiers', which is
  interpreted by the function `denote-org-capture'.  Example with our
  default value:

  ┌────
  │ (setq denote-org-capture-specifiers "%l\n%i\n%?")
  └────

  Note that `denote-org-capture' ignores the `denote-file-type': it
  always sets the Org file extension for the created note to ensure that
  the capture process works as intended, especially for the desired
  output of the `denote-org-capture-specifiers'.


[Standard note creation] See section 3.1


3.3 Maintain separate directories for notes
───────────────────────────────────────────

  The user option `denote-directory' accepts a value that represents the
  path to a directory, such as `~/Documents/notes'.  Normally, the user
  will have one place where they store all their notes, in which case
  this arrangement shall suffice.

  There is, however, the possibility to maintain separate directories of
  notes.  By “separate”, we mean that they do not communicate with each
  other: no linking between them, no common keywords, nothing.  Think of
  the scenario where one set of notes is for private use and another is
  for an employer.  We call these separate directories “silos”.

  To create silos, the user must specify a local variable at the root of
  the desired directory.  This is done by creating a `.dir-locals.el'
  file, with the following contents:

  ┌────
  │ ;;; Directory Local Variables.  For more information evaluate:
  │ ;;;
  │ ;;;     (info "(emacs) Directory Variables")
  │ 
  │ ((nil . ((denote-directory . default-directory))))
  └────

  When inside the directory that contains this `.dir-locals.el' file,
  all Denote commands/functions for note creation, linking, the
  inference of available keywords, et cetera will use the silo as their
  point of reference.  They will not read the global value of
  `denote-directory'.  The global value of `denote-directory' is read
  everywhere else except the silos.

  In concrete terms, this is a representation of the directory
  structures (notice the `.dir-locals.el' file is needed only for the
  silos):

  ┌────
  │ ;; This is the global value of 'denote-directory' (no need for a .dir-locals.el)
  │ ~/Documents/notes
  │ |-- 20210303T120534--this-is-a-test__journal_philosophy.txt
  │ |-- 20220303T120534--another-sample__journal_testing.md
  │ `-- 20220620T181255--the-third-test__keyword.org
  │ 
  │ ;; A silo with notes for the employer
  │ ~/different/path/to/notes-for-employer
  │ |-- .dir-locals.el
  │ |-- 20210303T120534--this-is-a-test__conference.txt
  │ |-- 20220303T120534--another-sample__meeting.md
  │ `-- 20220620T181255--the-third-test__keyword.org
  │ 
  │ ;; Another silo with notes for my volunteering
  │ ~/different/path/to/notes-for-volunteering
  │ |-- .dir-locals.el
  │ |-- 20210303T120534--this-is-a-test__activism.txt
  │ |-- 20220303T120534--another-sample__teambuilding.md
  │ `-- 20220620T181255--the-third-test__keyword.org
  └────


4 Renaming files
════════════════

  Denote provides commands to rename files and update their front matter
  where relevant.  For Denote to work, only the file name needs to be in
  order, by following our naming conventions ([The file-naming scheme]).
  The linking mechanism, in particular, needs just the identifier in the
  file name ([Linking notes]).

  We write front matter in notes for the user’s convenience and for
  other tools to make use of that information (e.g. Org’s export
  mechanism).  The renaming mechanism takes care to keep this data in
  sync with the file name, when the user performs a change.

  Renaming is useful for managing existing files created with Denote,
  but also for converting older text files to Denote notes.

  Lastly, Denote’s file-naming scheme is not specific to notes or text
  files: it is useful for all sorts of items, such as multimedia and
  PDFs that form part of the user’s longer-term storage.  While Denote
  does not manage such files (e.g. doesn’t create links to them), it
  already has all the mechanisms to facilitate the task of renaming
  them.


[The file-naming scheme] See section 5

[Linking notes] See section 7

4.1 Rename a single file
────────────────────────

  The `denote-rename-file' command renames a file and updates existing
  front matter if appropriate.

  If in Dired, the `FILE' to be renamed is the one at point, else the
  command prompts with minibuffer completion for a target file.

  If `FILE' has a Denote-compliant identifier, the command retains it
  while updating the `TITLE' and `KEYWORDS' fields of the file name.
  Otherwise it creates an identifier based on the file’s attribute of
  last modification time.  If such attribute cannot be found, the
  identifier falls back to the current date and time.

  The default `TITLE' is retrieved from a line starting with a title
  field in the file’s contents, depending on the given file type ([Front
  matter]).  Else, the file name is used as a default value at the
  minibuffer prompt.

  As a final step after the `FILE', `TITLE', and `KEYWORDS' prompts, ask
  for confirmation, showing the difference between old and new file
  names.  For example:

  ┌────
  │ Rename sample.txt to 20220612T052900--my-sample-title__testing.txt? (y or n)
  └────

  The file type extension (e.g. `.txt') is read from the underlying file
  and is preserved through the renaming process.  Files that have no
  extension are simply left without one.

  Renaming only occurs relative to the current directory.  Files are not
  moved between directories.

  If the `FILE' has Denote-style front matter for the `TITLE' and
  `KEYWORDS', this command asks to rewrite their values in order to
  reflect the new input (this step always requires confirmation and the
  underlying buffer is not saved, so consider invoking
  `diff-buffer-with-file' to double-check the effect).  The rewrite of
  the `FILE' and `KEYWORDS' in the front matter should not affect the
  rest of the block.

  If the file doesn’t have front matter but is among the supported file
  types (per `denote-file-type'), the `denote-rename-file' command adds
  front matter at the top of it and leaves the buffer unsaved for
  further inspection.

  This command is intended to (i) rename existing Denote notes while
  updating their title and keywords in the front matter, (ii) convert
  existing supported file types to Denote notes, and (ii) rename
  non-note files (e.g. PDF) that can benefit from Denote’s file-naming
  scheme.  The latter is a convenience we provide, since we already have
  all the requisite mechanisms in place (though Denote does not—and will
  not—manage such files).


[Front matter] See section 6


4.2 Rename multiple files at once
─────────────────────────────────

  The `denote-dired-rename-marked-files' command renames marked files in
  Dired to conform with our file-naming scheme.  The operation does the
  following:

  • the file’s existing file name is retained and becomes the `TITLE'
    field, per Denote’s file-naming scheme;

  • the `TITLE' is sluggified and downcased, per our conventions;

  • an identifier is prepended to the `TITLE';

  • the file’s extension is retained;

  • a prompt is asked once for the `KEYWORDS' field and the input is
    applied to all file names;

  • if the file is recognized as a Denote note, this command adds or
    rewrites front matter to include the new keywords.  A confirmation
    to carry out this step is performed once at the outset.  Note that
    the affected buffers are not saved.  The user can thus check them to
    confirm that the new front matter does not cause any problems
    (e.g. with the command `diff-buffer-with-file').  Multiple buffers
    can be saved with `save-some-buffers' (read its doc string).  The
    addition of front matter takes place only if the given file has the
    appropriate file type extension (per the user option
    `denote-file-type').


4.3 Rename a single file based on its front matter
──────────────────────────────────────────────────

  In the previous section, we covered the more general mechanism of the
  command `denote-rename-file' ([Rename a single file]).  There is also
  a way to have the same outcome by making Denote read the data in the
  current file’s front matter and use it to construct/update the file
  name.  The command for this is
  `denote-rename-file-using-front-matter'.  It is only relevant for
  files that (i) are among the supported file types, per
  `denote-file-type', and (ii) have the requisite front matter in place.

  Suppose you have an `.org' file with this front matter ([Front
  matter]):

  ┌────
  │ #+title:      My sample note file
  │ #+date:       [2022-08-05 Fri 13:10]
  │ #+filetags:   :testing:
  │ #+identifier: 20220805T131044
  └────

  Its file name reflects this information:

  ┌────
  │ 20220805T131044--my-sample-note-file__testing.org
  └────


  You want to change its title and keywords manually, so you modify it
  thus:

  ┌────
  │ #+title:      My modified sample note file
  │ #+date:       [2022-08-05 Fri 13:10]
  │ #+filetags:   :testing:denote:emacs:
  │ #+identifier: 20220805T131044
  └────

  The file name still shows the old title and keywords.  So after saving
  the buffer, you invoke `denote-rename-file-using-front-matter' and it
  updates the file name to:

  ┌────
  │ 20220805T131044--my-modified-sample-note-file__testing_denote_emacs.org
  └────


  The renaming is subject to a “yes or no” prompt that shows the old and
  new names, just so the user is certain about the change.

  The identifier of the file, if any, is never modified even if it is
  edited in the front matter: Denote considers the file name to be the
  source of truth in this case, to avoid potential breakage with typos
  and the like.


[Rename a single file] See section 4.1

[Front matter] See section 6


4.4 Rename multiple files based on their front matter
─────────────────────────────────────────────────────

  As already noted, Denote can rename a file based on the data in its
  front matter ([Rename a single file based on its front matter]).  The
  command `denote-dired-rename-marked-files-using-front-matter' extends
  this principle to a batch operation which applies to all marked files
  in Dired.

  Marked files must count as notes for the purposes of Denote, which
  means that they at least have an identifier in their file name and use
  a supported file type, per `denote-file-type'.  Files that do not meet
  this criterion are ignored.

  The operation does the following:

  • the title in the front matter becomes the `TITLE' component of the
    file name ([The file-naming scheme]);

  • the keywords in the front matter are used for the `KEYWORDS'
    component of the file name and are processed accordingly, if needed;

  • the identifier remains unchanged in the file name even if it is
    modified in the front matter (this is done to avoid breakage caused
    by typos and the like).

  NOTE that files must be saved, because Denote reads from the
  underlying file, not a modified buffer (this is done to avoid
  potential mistakes).  The return value of a modified buffer is the one
  prior to the modification, i.e. the one already written on disk.

  This command is useful for synchronizing multiple file names with
  their respective front matter.


[Rename a single file based on its front matter] See section 4.3

[The file-naming scheme] See section 5


5 The file-naming scheme
════════════════════════

  Notes are stored the `denote-directory'.  The default path is
  `~/Documents/notes'.  The `denote-directory' can be a flat listing,
  meaning that it has no subdirectories, or it can be a directory tree.
  Either way, Denote takes care to only consider “notes” as valid
  candidates in the relevant operations and will omit other files or
  directories.

  Every note produced by Denote follows this pattern ([Points of
  entry]):

  ┌────
  │ DATE--TITLE__KEYWORDS.EXTENSION
  └────


  The `DATE' field represents the date in year-month-day format followed
  by the capital letter `T' (for “time”) and the current time in
  hour-minute-second notation.  The presentation is compact:
  `20220531T091625'.  The `DATE' serves as the unique identifier of each
  note.

  The `TITLE' field is the title of the note, as provided by the user.
  It automatically gets downcased and hyphenated.  An entry about
  “Economics in the Euro Area” produces an `economics-in-the-euro-area'
  string for the `TITLE' of the file name.

  The `KEYWORDS' field consists of one or more entries demarcated by an
  underscore (the separator is inserted automatically).  Each keyword is
  a string provided by the user at the relevant prompt which broadly
  describes the contents of the entry.  Keywords that need to be more
  than one-word-long must be written with hyphens: any other character,
  such as spaces or the plus sign is automatically converted into a
  hyphen.  So when `emacs_library' appears in a file name, it is
  interpreted as two distinct keywords, whereas `emacs-library' is one
  keyword.  This is reflected in how the keywords are recorded in the
  note ([Front matter]).  While Denote supports multi-word keywords by
  default, the user option `denote-allow-multi-word-keywords' can be set
  to nil to forcibly join all words into one, meaning that an input of
  `word1 word2' will be written as `word1word2'.

  The `EXTENSION' is the file type.  By default, it is `.org'
  (`org-mode') though the user option `denote-file-type' provides
  support for Markdown with YAML or TOML variants (`.md' which runs
  `markdown-mode') and plain text (`.txt' via `text-mode').  Consult its
  doc string for the minutiae.  While files end in the `.org' extension
  by default, the Denote code base does not actually depend on org.el
  and/or its accoutrements.

  Examples:

  ┌────
  │ 20220610T043241--initial-thoughts-on-the-zettelkasten-method__notetaking.org
  │ 20220610T062201--define-custom-org-hyperlink-type__denote_emacs_package.md
  │ 20220610T162327--on-hierarchy-and-taxis__notetaking_philosophy.txt
  └────


  The different field separators, namely `--' and `__' introduce an
  efficient way to anchor searches (such as with Emacs commands like
  `isearch' or from the command-line with `find' and related).  A query
  for `_word' always matches a keyword, while a regexp in the form of,
  say, `"\\([0-9T]+?\\)--\\(.*?\\)_"' captures the date in group `\1'
  and the title in `\2' (test any regular expression in the current
  buffer by invoking `M-x re-builder').

  [Features of the file-naming scheme for searching or filtering].

  While Denote is an Emacs package, notes should work long-term and not
  depend on the functionality of a specific program.  The file-naming
  scheme we apply guarantees that a listing is readable in a variety of
  contexts.


[Points of entry] See section 3

[Front matter] See section 6

[Features of the file-naming scheme for searching or filtering] See
section 5.2

5.1 Sluggified title and keywords
─────────────────────────────────

  Denote has to be highly opinionated about which characters can be used
  in file names and the file’s front matter in order to enforce its
  file-naming scheme.  The private variable `denote--punctuation-regexp'
  holds the relevant value.  In simple terms:

  ⁃ What we count as “illegal characters” are converted into hyphens.

  ⁃ Input for a file title is hyphenated and downcased.  The original
    value is preserved in the note’s contents ([Front matter]).

  ⁃ Keywords should not have spaces or other delimiters.  If they do,
    they are converted into hyphens.  Keywords are always downcased.


[Front matter] See section 6


5.2 Features of the file-naming scheme for searching or filtering
─────────────────────────────────────────────────────────────────

  File names have three fields and two sets of field delimiters between
  them:

  ┌────
  │ DATE--TITLE__KEYWORDS.EXTENSION
  └────


  The first field delimiter is the double hyphen, while the second is
  the double underscore.  These practically serve as anchors for easier
  searching.  Consider this example:

  ┌────
  │ 20220621T062327--introduction-to-denote__denote_emacs.txt
  └────


  You will notice that there are two matches for the word `denote': one
  in the title field and another in the keywords’ field.  Because of the
  distinct field delimiters, if we search for `-denote' we only match
  the first instance while `_denote' targets the second one.  When
  sorting through your notes, this kind of specificity is invaluable—and
  you get it for free from the file names alone!

  Users can get a lot of value out of this simple arrangement, even if
  they have no knowledge of regular expressions.  One thing to consider,
  for maximum effect, is to avoid using multi-word keywords as those get
  hyphenated like the title and will thus interfere with the above:
  either set the user option `denote-allow-multi-word-keywords' to nil
  or simply insert single words at the relevant prompts.


6 Front matter
══════════════

  Notes have their own “front matter”.  This is a block of data at the
  top of the file, with no empty lines between the entries, which is
  automatically generated at the creation of a new note.  The front
  matter includes the title and keywords (aka “tags” or “filetags”,
  depending on the file type) which the user specified at the relevant
  prompt, as well as the date and unique identifier, which are derived
  automatically.

  This is how it looks for Org mode (when `denote-file-type' is nil):

  ┌────
  │ #+title:      This is a sample note
  │ #+date:       [2022-06-30 Thu 16:09]
  │ #+filetags:   :denote:testing:
  │ #+identifier: 20220630T160934
  └────

  For Markdown with YAML (`denote-file-type' has the `markdown-yaml'
  value), the front matter looks like this:

  ┌────
  │ ---
  │ title:      "This is a sample note"
  │ date:       2022-06-30T16:09:58+03:00
  │ tags:       ["denote", "testing"]
  │ identifier: "20220630T160958"
  │ ---
  └────

  For Markdown with TOML (`denote-file-type' has the `markdown-toml'
  value), it is:

  ┌────
  │ +++
  │ title      = "This is a sample note"
  │ date       = 2022-06-30T16:10:13+03:00
  │ tags       = ["denote", "testing"]
  │ identifier = "20220630T161013"
  │ +++
  └────

  And for plain text (`denote-file-type' has the `text' value), we have
  the following:

  ┌────
  │ title:      This is a sample note
  │ date:       2022-06-30
  │ tags:       denote  testing
  │ identifier: 20220630T161028
  │ ---------------------------
  └────

  The format of the date in the front matter is controlled by the user
  option `denote-date-format'.  When nil, Denote uses a
  file-type-specific format:

  • For Org, an inactive timestamp is used, such as `[2022-06-30 Wed
    15:31]'.

  • For Markdown, the RFC3339 standard is applied:
    `2022-06-30T15:48:00+03:00'.

  • For plain text, the format is that of ISO 8601: `2022-06-30'.

  If the value is a string, ignore the above and use it instead.  The
  string must include format specifiers for the date.  These are
  described in the doc string of `format-time-string'..


6.1 Change the front matter format
──────────────────────────────────

  Per Denote’s design principles, the code is hackable.  All front
  matter is stored in variables that are intended for public use.  We do
  not declare those as “user options” because (i) they expect the user
  to have some degree of knowledge in Emacs Lisp and (ii) implement
  custom code.

  [ NOTE for tinkerers: code intended for internal use includes double
    hyphens in its symbol.  “Internal use” means that it can be changed
    without warning and with no further reference in the change log.  Do
    not use any of it without understanding the consequences. ]

  The variables which hold the front matter format are:

  • `denote-org-front-matter'

  • `denote-text-front-matter'

  • `denote-toml-front-matter'

  • `denote-yaml-front-matter'

  These variables hold a string with specifiers that are used by the
  `format' function.  The formatting operation passes four arguments
  (five in the case of `denote-text-front-matter' as noted in its doc
  string) which include the values of the given entries.  The doc string
  of `denote-org-front-matter' describes the technicalities:

        The order of the arguments is TITLE, DATE, KEYWORDS, ID.
        If you are an advanced user who wants to edit this
        variable to affect how front matter is produced, consider
        using something like %2$s to control where Nth argument is
        placed.

        Make sure to:

        1. Not use empty lines inside the front matter block.

        2. Insert at least one empty line after the front matter
           block and do not use any empty line before it.

        These help with consistency and might prove useful if we
        ever need to operate on the front matter as a whole.

  With those granted, below are some examples.  The approach is the same
  for all variables.

  ┌────
  │ ;; Like the default, but upcase the entries
  │ (setq denote-org-front-matter
  │   "#+TITLE:      %s
  │ #+DATE:       %s
  │ #+FILETAGS:   %s
  │ #+IDENTIFIER: %s
  │ \n")
  │ 
  │ ;; Change the order (notice the %N$s notation)
  │ (setq denote-org-front-matter
  │   "#+title:      %1$s
  │ #+filetags:   %3$s
  │ #+date:       %2$s
  │ #+identifier: %4$s
  │ \n")
  │ 
  │ ;; Remove the date
  │ (setq denote-org-front-matter
  │   "#+title:      %1$s
  │ #+filetags:   %3$s
  │ #+identifier: %4$s
  │ \n")
  │ 
  │ ;; Remove the date and the identifier
  │ (setq denote-org-front-matter
  │   "#+title:      %1$s
  │ #+filetags:   %3$s
  │ \n")
  └────

  Note that `setq' has a global effect: it affects the creation of all
  new notes.  Depending on the workflow, it may be preferrable to have a
  custom command which `let' binds the different format.  We shall not
  provide examples at this point as this is a more advanced feature and
  we are not yet sure what the user’s needs are.  Please provide
  feedback and we shall act accordingly.


6.2 Regenerate front matter
───────────────────────────

  Sometimes the user needs to produce new front matter for an existing
  note.  Perhaps because they accidentally deleted a line and could not
  undo the operation.  The command `denote-add-front-matter' can be used
  for this very purpose.

  In interactive use, `denote-add-front-matter' must be invoked from a
  buffer that visits a Denote note.  It prompts for a title and then for
  keywords.  These are the standard prompts we already use for note
  creation, so the keywords’ prompt allows minibuffer completion and the
  input of multiple entries, each separated by a comma ([Points of
  entry]).

  The newly created front matter is added to the top of the file.

  This command does not rename the file (e.g. to update the keywords).
  To rename a file by reading its front matter as input, the user can
  rely on `denote-rename-file-using-front-matter' ([Renaming files]).

  Note that `denote-add-front-matter' is useful only for existing Denote
  notes.  If the user needs to convert a generic text file to a Denote
  note, they can use one of the command which first rename the file to
  make it comply with our file-naming scheme and then add the relevant
  front matter.


[Points of entry] See section 3

[Renaming files] See section 4


7 Linking notes
═══════════════

  Denote offers several commands for linking between notes.

  All links target files which are Denote notes.  This means that they
  have our file-naming scheme, are writable/regular (not directory,
  named pipe, etc.), and use the appropriate file type extension (per
  `denote-file-type').  Furthermore, the files need to be inside the
  `denote-directory' or one of its subdirectories.  No other file is
  recognised.

  The following sections delve into the details.


7.1 Adding a single link
────────────────────────

  The `denote-link' command inserts a link at point to an entry
  specified at the minibuffer prompt.  Links are formatted depending on
  the file type of current note.  In Org and plain text buffers, links
  are formatted thus: `[[denote:IDENTIFIER][TITLE]]'.  While in Markdown
  they are expressed as `[TITLE](denote:IDENTIFIER)'.

  When `denote-link' is called with a prefix argument (`C-u' by
  default), it formats links like `[[denote:IDENTIFIER]]'.  The user
  might prefer its simplicity.

  Inserted links are automatically buttonized and remain active for as
  long as the buffer is available.  In Org this is handled by the major
  mode: the `denote:' hyperlink type works exactly like the standard
  `file:'.  In Markdown and plain text, Denote performs the
  buttonization of those links.  To buttonize links in existing files
  while visiting them, the user must add this snippet to their setup (it
  already excludes Org):

  ┌────
  │ (add-hook 'find-file-hook #'denote-link-buttonize-buffer)
  └────

  The `denote-link-buttonize-buffer' is also an interactive function in
  case the user needs it.

  Links are created only for files which qualify as a “note” for our
  purposes ([Linking notes]).

  Links are styled with the `denote-faces-link' face, which looks
  exactly like an ordinary link by default.  This is just a convenience
  for the user/theme in case they want `denote:' links to remain
  distinct from other links.

  In Org files, broken links get the `denote-faces-broken-link' if the
  linked identifier does not resolve to a file path with a note.  The
  ability to use distinct faces for such a scenario is a feature of Org,
  which is not available in other supported file types that use Emacs’
  generic button mechanism.


[Linking notes] See section 7


7.2 Insert links matching a regexp
──────────────────────────────────

  The command `denote-link-add-links' adds links at point matching a
  regular expression or plain string.  The links are inserted as a
  typographic list, such as:

  ┌────
  │ - link1
  │ - link2
  │ - link3
  └────

  Each link is formatted according to the file type of the current note,
  as explained further above about the `denote-link' command.  The
  current note is excluded from the matching entries (adding a link to
  itself is pointless).

  When called with a prefix argument (`C-u') `denote-link-add-links'
  will format all links as `[[denote:IDENTIFIER]]', hence a typographic
  list:

  ┌────
  │ - [[denote:IDENTIFIER-1]]
  │ - [[denote:IDENTIFIER-2]]
  │ - [[denote:IDENTIFIER-3]]
  └────

  Same examples of a regular expression that can be used with this
  command:

  • `journal' match all files which include `journal' anywhere in their
    name.

  • `_journal' match all files which include `journal' as a keyword.

  • `^2022.*_journal' match all file names starting with `2022' and
    including the keyword `journal'.

  • `\.txt' match all files including `.txt'.  In practical terms, this
    only applies to the file extension, as Denote automatically removes
    dots (and other characters) from the base file name.

  If files are created with `denote-sort-keywords' as non-nil (the
  default), then it is easy to write a regexp that includes multiple
  keywords in alphabetic order:

  • `_denote.*_package' match all files that include both the `denote'
    and `package' keywords, in this order.

  • `\(.*denote.*package.*\)\|\(.*package.*denote.*\)' is the same as
    above, but out-of-order.

  Remember that regexp constructs only need to be escaped once (like
  `\|') when done interactively but twice when called from Lisp.  What
  we show above is for interactive usage.

  Links are created only for files which qualify as a “note” for our
  purposes ([Linking notes]).


[Linking notes] See section 7


7.3 Insert links from marked files in Dired
───────────────────────────────────────────

  The command `denote-link-dired-marked-notes' is similar to
  `denote-link-add-links' in that it inserts in the buffer a typographic
  list of links to Denote notes ([Insert links matching a regexp]).
  Though instead of reading a regular expression, it lets the user mark
  files in Dired and link to them.  This should be easier for users of
  all skill levels, instead of having to write a potentially complex
  regular expression.

  If there are multiple buffers that visit a Denote note, this command
  will ask to select one among them, using minibuffer completion.  If
  there is only one buffer, it will operate in it outright.  If there
  are no buffers, it will produce an error.

  With optional `ID-ONLY' as a prefix argument (`C-u' by default), the
  command inserts links with just the identifier, which is the same
  principle as with `denote-link' and others ([Adding a single link]).

  The command `denote-link-dired-marked-notes' is meant to be used from
  a Dired buffer.

  As always, links are created only for files which qualify as a “note”
  for our purposes ([Linking notes]).


[Insert links matching a regexp] See section 7.2

[Adding a single link] See section 7.1

[Linking notes] See section 7


7.4 The backlinks’ buffer
─────────────────────────

  The command `denote-link-backlinks' produces a bespoke buffer which
  displays the file name of all notes linking to the current one.  Each
  file name appears on its own line and is buttonized so that it
  performs the action of visiting the referenced file.  The backlinks’
  buffer looks like this:

  ┌────
  │ Backlinks to "On being honest" (20220614T130812)
  │ ------------------------------------------------
  │ 
  │ 20220614T145606--let-this-glance-become-a-stare__journal.txt
  │ 20220616T182958--not-feeling-butterflies-in-your-stomach__journal.txt
  └────

  The backlinks’ buffer is fontified by default, though the user has
  access to the `denote-link-fontify-backlinks' option to disable this
  effect by setting its value to nil.

  The placement of the backlinks’ buffer is subject to the user option
  `denote-link-backlinks-display-buffer-action'.  Due to the nature of
  the underlying `display-buffer' mechanism, this inevitably is a
  relatively advanced feature.  By default, the backlinks’ buffer is
  displayed below the current window.  The doc string of our user option
  includes a sample configuration that places the buffer in a left side
  window instead.  Reproducing it here for the sake of convenience:

  ┌────
  │ (setq denote-link-backlinks-display-buffer-action
  │       '((display-buffer-reuse-window
  │ 	 display-buffer-in-side-window)
  │ 	(side . left)
  │ 	(slot . 99)
  │ 	(window-width . 0.3)))
  └────

  The backlinks’ buffer runs the major-mode `denote-backlink-mode',
  which is derived from `special-mode'.  It binds keys to move between
  links with `n' (next) and `p' (previous).  These are stored in the
  `denote-backlink-mode-map' (use `M-x describe-mode' (`C-h m') in an
  unfamiliar buffer to learn more about it).

  Note that the backlinking facility uses Emacs’ built-in Xref
  infrastructure.  On some operating systems, the user may need to add
  certain executables to the relevant environment variable.

  [Why do I get “Search failed with status 1” when I search for
  backlinks?]


[Why do I get “Search failed with status 1” when I search for
backlinks?] See section 16.9


7.5 Writing metanotes
─────────────────────

  A “metanote” is an entry that describes other entries who have
  something in common.  Writing metanotes can be part of a workflow
  where the user periodically reviews their work in search of patterns
  and deeper insights.  For example, you might want to read your journal
  entries from the past year to reflect on your experiences, evolution
  as a person, and the like.

  The commands `denote-link-add-links', `denote-link-dired-marked-notes'
  are suited for this task.

  [Insert links matching a regexp].

  [Insert links from marked files in Dired].

  You will create your metanote the way you use Denote ordinarily
  (metanotes may have the `metanote' keyword, among others), write an
  introduction or however you want to go about it, invoke the command
  which inserts multiple links at once (see the above-cited nodes), and
  continue writing.

  Metanotes can serve as entry points to groupings of individual notes.
  They are not the same as a filtered list of files, i.e. what you would
  do in Dired or the minibuffer where you narrow the list of notes to a
  given query.  Metanotes contain the filtered list plus your thoughts
  about it.  The act of purposefully grouping notes together and
  contemplating on their shared patterns is what adds value.

  Your future self will appreciate metanotes for the function they serve
  in encapsulating knowledge, while current you will be equipped with
  the knowledge derived from the deliberate self-reflection.


[Insert links matching a regexp] See section 7.2

[Insert links from marked files in Dired] See section 7.3


7.6 Visiting linked files via the minibuffer
────────────────────────────────────────────

  Denote has a major-mode-agnostic mechanism to collect all linked file
  references in the current buffer and return them as an appropriately
  formatted list.  This list can then be used in interactive commands.
  The `denote-link-find-file' is such a command.  It uses minibuffer
  completion to visit a file that is linked to from the current note.
  The candidates have the correct metadata, which is ideal for
  integration with other standards-compliant tools ([Extending Denote]).
  For instance, a package such as `marginalia' will display accurate
  annotations, while the `embark' package will be able to work its magic
  such as in exporting the list into a filtered Dired buffer (i.e. a
  familiar Dired listing with only the files of the current minibuffer
  session).


[Extending Denote] See section 10


7.7 Miscellaneous information about links
─────────────────────────────────────────

  For convenience, the `denote-link' command has an alias called
  `denote-link-insert-link'.  The `denote-link-backlinks' can also be
  used as `denote-link-show-backlinks-buffer'.  While
  `denote-link-add-links' is aliased
  `denote-link-insert-links-matching-regexp'.  The purpose of these
  aliases is to offer alternative, more descriptive names of select
  commands.


8 Fontification in Dired
════════════════════════

  One of the upsides of Denote’s file-naming scheme is the predictable
  pattern it establishes, which appears as a near-tabular presentation
  in a listing of notes (i.e. in Dired).  The `denote-dired-mode' can
  help enhance this impression, by fontifying the components of the file
  name to make the date (identifier) and keywords stand out.

  There are two ways to set the mode.  Either use it for all
  directories, which probably is not needed:

  ┌────
  │ (add-hook 'dired-mode-hook #'denote-dired-mode)
  └────

  Or configure the user option `denote-dired-directories' and then set
  up the function `denote-dired-mode-in-directories':

  ┌────
  │ ;; We use different ways to specify a path for demo purposes.
  │ (setq denote-dired-directories
  │       (list denote-directory
  │ 	    (thread-last denote-directory (expand-file-name "attachments"))
  │ 	    (expand-file-name "~/Documents/vlog")))
  │ 
  │ (add-hook 'dired-mode-hook #'denote-dired-mode-in-directories)
  └────

  The faces we define for this purpose are:

  ⁃ `denote-faces-date'
  ⁃ `denote-faces-delimiter'
  ⁃ `denote-faces-extension'
  ⁃ `denote-faces-keywords'
  ⁃ `denote-faces-subdirectory'
  ⁃ `denote-faces-time'
  ⁃ `denote-faces-title'

  For the time being, the `diredfl' package is not compatible with this
  facility.

  The `denote-dired-mode' does not only fontify note files that were
  created by Denote: it covers every file name that follows our naming
  conventions ([The file-naming scheme]).  This is particularly useful
  for scenaria where, say, one wants to organise their collection of
  PDFs and multimedia in a systematic way (and, perhaps, use them as
  attachments for the notes Denote produces if you are writing Org notes
  and are using its standand attachments’ facility).


[The file-naming scheme] See section 5


9 Minibuffer histories
══════════════════════

  Denote has a dedicated minibuffer history for each one of its prompts.
  This practically means that using `M-p' (`previous-history-element')
  and `M-n' (`next-history-element') will only cycle through the
  relevant record of inputs, such as your latest titles in the `TITLE'
  prompt, and keywords in the `KEYWORDS' prompt.

  The built-in `savehist' library saves minibuffer histories.  Sample
  configuration:

  ┌────
  │ (require 'savehist)
  │ (setq savehist-file (locate-user-emacs-file "savehist"))
  │ (setq history-length 500)
  │ (setq history-delete-duplicates t)
  │ (setq savehist-save-minibuffer-history t)
  │ (add-hook 'after-init-hook #'savehist-mode)
  └────


10 Extending Denote
═══════════════════

  Denote is a tool with a narrow scope: create notes and link between
  them, based on the aforementioned file-naming scheme.  For other
  common operations the user is advised to rely on standard Emacs
  facilities or specialised third-party packages.  This section covers
  the details.


10.1 Keep a journal or diary
────────────────────────────

  While there are subtle technical differences between a journal and a
  diary, we will consider those equivalent in the interest of brevity:
  they both describe a personal space that holds a record of your
  thoughts about your experiences and/or view of events in the world.

  Suppose you are committed to writing an entry every day.  Unlike what
  we demonstrated before, your writing will follow a regular naming
  pattern.  You know that the title of the new note must always look
  like `Tuesday 14 June 2022' and the keyword has to be `journal' or
  `diary'.  As such, you want to automate the task instead of being
  prompted each time, as is the norm with `denote' and the relevant
  commands ([Points of entry]).  This is easy to accomplish because
  `denote' can be called from Lisp and given the required arguments of
  `TITLE' and `KEYWORDS' directly.  All you need is a simple wrapper
  function:

  ┌────
  │ (defun my-denote-journal ()
  │   "Create an entry tagged 'journal' with the date as its title."
  │   (interactive)
  │   (denote
  │    (format-time-string "%A %e %B %Y") ; format like Tuesday 14 June 2022
  │    '("journal"))) ; multiple keywords are a list of strings: '("one" "two")
  └────

  By invoking `my-denote-journal' you will go straight into the newly
  created note and commit to your writing outright.

  Of course, you can always set up the function so that it asks for a
  `TITLE' but still automatically applies the `journal' tag:

  ┌────
  │ (defun denote-journal-with-title ()
  │   "Create an entry tagged 'journal', while prompting for a title."
  │   (interactive)
  │   (denote
  │    (denote--title-prompt) ; ask for title, instead of using human-readable date
  │    '("journal")))
  └────

  Sometimes journaling is done with the intent to hone one’s writing
  skills.  Perhaps you are learning a new language or wish to
  communicate your ideas with greater clarity and precision.  As with
  everything that requires a degree of sophistication, you have to work
  for it—write, write, write!

  One way to test your progress is to set a timer.  It helps you gauge
  your output and its quality.  To use a timer with Emacs, consider the
  `tmr' package:

  ┌────
  │ (defun my-denote-journal-with-tmr ()
  │   "Like `my-denote-journal', but also set a 10-minute timer.
  │ The `tmr' command is part of the `tmr' package."
  │   (interactive)
  │   (denote
  │    (format-time-string "%A %e %B %Y")
  │    '("journal"))
  │   (tmr "10" "Practice writing in my journal")) ; set 10 minute timer with a description
  └────

  Once the timer elapses, stop writing and review your performance.
  Practice makes perfect!

  [ As Denote matures, we may add hooks to control what happens before
    or after the creation of a new note.  We shall also document more
    examples of tasks that can be accomplished with this package. ]

  Sources for `tmr':

  ⁃ Package name (GNU ELPA): `tmr'
  ⁃ Official manual: <https://protesilaos.com/emacs/tmr>
  ⁃ Change log: <https://protesilaos.com/emacs/denote-changelog>
  ⁃ Git repo on SourceHut: <https://git.sr.ht/~protesilaos/tmr>
    • Mirrors:
      ⁃ GitHub: <https://github.com/protesilaos/tmr>
      ⁃ GitLab: <https://gitlab.com/protesilaos/tmr>
  ⁃ Mailing list: <https://lists.sr.ht/~protesilaos/tmr>


[Points of entry] See section 3


10.2 Narrow the list of files in Dired
──────────────────────────────────────

  Emacs’ standard file manager (or directory editor) can read a regular
  expression to mark the matching files.  This is the command
  `dired-mark-files-regexp', which is bound to `% m' by default.  For
  example, `% m _denote' will match all files that have the `denote'
  keyword ([Features of the file-naming scheme for searching or
  filtering]).

  Once the files are matched, the user has to options: (i) narrow the
  list to the matching items or (ii) exclude the matching items from the
  list.

  For the former, we want to toggle the marks by typing `t' (calls the
  command `dired-toggle-marks' by default) and then hit the letter `k'
  (for `dired-do-kill-lines').  The remaining files are those that match
  the regexp that was provided earlier.

  For the latter approach of filtering out the matching items, simply
  involves the use of the `k' command (`dired-do-kill-lines') to omit
  the marked files from the list.

  These sequences can be combined to incrementally narrow the list.
  Note that `dired-do-kill-lines' does not delete files: it simply hides
  them from the current view.

  Revert to the original listing with `g' (`revert-buffer').

  For a convenient wrapper, consider this example:

  ┌────
  │ (defvar prot-dired--limit-hist '()
  │   "Minibuffer history for `prot-dired-limit-regexp'.")
  │ 
  │ ;;;###autoload
  │ (defun prot-dired-limit-regexp (regexp omit)
  │   "Limit Dired to keep files matching REGEXP.
  │ 
  │ With optional OMIT argument as a prefix (\\[universal-argument]),
  │ exclude files matching REGEXP.
  │ 
  │ Restore the buffer with \\<dired-mode-map>`\\[revert-buffer]'."
  │   (interactive
  │    (list
  │     (read-regexp
  │      (concat "Files "
  │ 	     (when current-prefix-arg
  │ 	       (propertize "NOT " 'face 'warning))
  │ 	     "matching PATTERN: ")
  │      nil 'prot-dired--limit-hist)
  │     current-prefix-arg))
  │   (dired-mark-files-regexp regexp)
  │   (unless omit (dired-toggle-marks))
  │   (dired-do-kill-lines))
  └────


[Features of the file-naming scheme for searching or filtering] See
section 5.2


10.3 Use Embark to collect minibuffer candidates
────────────────────────────────────────────────

  `embark' is a remarkable package that lets you perform relevant,
  context-dependent actions using a prefix key (simplifying in the
  interest of brevity).

  For our purposes, Embark can be used to produce a Dired listing
  directly from the minibuffer.  Suppose the current note has links to
  three other notes.  You might use the `denote-link-find-file' command
  to pick one via the minibuffer.  But why not turn those three links
  into their own Dired listing?  While in the minibuffer, invoke
  `embark-act' which you may have already bound to `C-.' and then follow
  it up with `E' (for the `embark-export' command).

  This pattern can be repeated with any list of candidates, meaning that
  you can narrow the list by providing some input before eventually
  exporting the results with Embark.

  Overall, this is very powerful and you might prefer it over doing the
  same thing directly in Dired, since you also benefit from all the
  power of the minibuffer ([Narrow the list of files in Dired]).


[Narrow the list of files in Dired] See section 10.2


10.4 Search file contents
─────────────────────────

  Emacs provides built-in commands which are wrappers of standard Unix
  tools: `M-x grep' lets the user input the flags of a `grep' call and
  pass a regular expression to the `-e' flag.

  The author of Denote uses this thin wrapper instead:

  ┌────
  │ (defvar prot-search--grep-hist '()
  │   "Input history of grep searches.")
  │ 
  │ ;;;###autoload
  │ (defun prot-search-grep (regexp &optional recursive)
  │   "Run grep for REGEXP.
  │ 
  │ Search in the current directory using `lgrep'.  With optional
  │ prefix argument (\\[universal-argument]) for RECURSIVE, run a
  │ search starting from the current directory with `rgrep'."
  │   (interactive
  │    (list
  │     (read-from-minibuffer (concat (if current-prefix-arg
  │ 				      (propertize "Recursive" 'face 'warning)
  │ 				    "Local")
  │ 				  " grep for PATTERN: ")
  │ 			  nil nil nil 'prot-search--grep-hist)
  │     current-prefix-arg))
  │   (unless grep-command
  │     (grep-compute-defaults))
  │   (if recursive
  │       (rgrep regexp "*" default-directory)
  │     (lgrep regexp "*" default-directory)))
  └────

  Rather than maintain custom code, consider using the excellent
  `consult' package: it provides commands such as `consult-grep' and
  `consult-find' which provide live results and are generally easier to
  use than the built-in commands.


10.5 Bookmark the directory with the notes
──────────────────────────────────────────

  Part of the reason Denote does not reinvent existing functionality is
  to encourage you to learn more about Emacs.  You do not need a bespoke
  “jump to my notes” directory because such commands do not scale well.
  Will you have a “jump to my downloads” then another for multimedia and
  so on?  No.

  Emacs has a built-in framework for recording persistent markers to
  locations.  Visit the `denote-directory' (or any dir/file for that
  matter) and invoke the `bookmark-set' command (bound to `C-x r m' by
  default).  It lets you create a bookmark.

  The list of bookmarks can be reviewed with the `bookmark-bmenu-list'
  command (bound to `C-x r l' by default).  A minibuffer interface is
  available with `bookmark-jump' (`C-x r b').

  If you use the `consult' package, its default `consult-buffer' command
  has the means to group together buffers, recent files, and bookmarks.
  Each of those types can be narrowed to with a prefix key.  The package
  `consult-dir' is an extension to `consult' which provides useful
  extras for working with directories, including bookmarks.


10.6 Use the consult-notes package
──────────────────────────────────

  If you are already using `consult' (which is a brilliant package), you
  will probably like its `consult-notes' extension.  It uses the
  familiar mechanisms of Consult to filter searches via a prefix key.
  For example:

  ┌────
  │ (setq consult-notes-sources
  │       `(("Notes"  ?n ,denote-directory)
  │ 	("Books"  ?b "~/Documents/books")))
  └────

  With the above, `M-x consult-notes' will list the files in those two
  directories.  If you type `n' and space, it narrows the list to just
  the notes, while `b' does the same for books.

  To search all your notes with grep (or ripgrep if installed – see
  `consult-notes-use-rg' variable) use the command
  `consult-notes-search-in-all-notes'. This will employ grep/ripgrep for
  searching terms in all the directories set in `consult-notes-sources'.

  Note that `consult-notes' is in its early stages of development.
  Expect improvements in the near future (written on 2022-06-22 16:48
  +0300).


10.7 Treat your notes as a project
──────────────────────────────────

  Emacs has a built-in library for treating a directory tree as a
  “project”.  This means that the contents of this tree are seen as part
  of the same set, so commands like `project-switch-to-buffer' (`C-x p
  b' by default) will only consider buffers in the current project
  (e.g. three notes that are currently being visited).

  Normally, a “project” is a directory tree whose root is under version
  control.  For our purposes, all you need is to navigate to the
  `denote-directory' (for the shell or via Dired) and use the
  command-line to run this (requires the `git' executable):

  ┌────
  │ git init
  └────


  From Dired, you can type `M-!' which invokes
  `dired-smart-shell-command' and then run the git call there.

  The project can then be registered by invoking any project-related
  command inside of it, such as `project-find-file' (`C-x p f').

  It is a good idea to keep your notes under version control, as that
  gives you a history of changes for each file.  We shall not delve into
  the technicalities here, though suffice to note that Emacs’ built-in
  version control framework or the exceptionally well-crafted `magit'
  package will get the job done (VC can work with other backends besides
  Git).


11 Installation
═══════════════




11.1 GNU ELPA package
─────────────────────

  The package is available as `denote'.  Simply do:

  ┌────
  │ M-x package-refresh-contents
  │ M-x package-install
  └────


  And search for it.

  GNU ELPA provides the latest stable release.  Those who prefer to
  follow the development process in order to report bugs or suggest
  changes, can use the version of the package from the GNU-devel ELPA
  archive.  Read:
  <https://protesilaos.com/codelog/2022-05-13-emacs-elpa-devel/>.


11.2 Manual installation
────────────────────────

  Assuming your Emacs files are found in `~/.emacs.d/', execute the
  following commands in a shell prompt:

  ┌────
  │ cd ~/.emacs.d
  │ 
  │ # Create a directory for manually-installed packages
  │ mkdir manual-packages
  │ 
  │ # Go to the new directory
  │ cd manual-packages
  │ 
  │ # Clone this repo, naming it "denote"
  │ git clone https://git.sr.ht/~protesilaos/denote denote
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/denote")
  └────

  Everything is in place to set up the package.


12 Sample configuration
═══════════════════════

  ┌────
  │ (require 'denote)
  │ 
  │ ;; Remember to check the doc strings of those variables.
  │ (setq denote-directory (expand-file-name "~/Documents/notes/"))
  │ (setq denote-known-keywords '("emacs" "philosophy" "politics" "economics"))
  │ (setq denote-infer-keywords t)
  │ (setq denote-sort-keywords t)
  │ (setq denote-file-type nil) ; Org is the default, set others here
  │ (setq denote-prompts '(title keywords))
  │ 
  │ ;; Read this manual for how to specify `denote-templates'.  We do not
  │ ;; include an example here to avoid potential confusion.
  │ 
  │ 
  │ ;; We allow multi-word keywords by default.  The author's personal
  │ ;; preference is for single-word keywords for a more rigid workflow.
  │ (setq denote-allow-multi-word-keywords t)
  │ 
  │ (setq denote-date-format nil) ; read doc string
  │ 
  │ ;; By default, we fontify backlinks in their bespoke buffer.
  │ (setq denote-link-fontify-backlinks t)
  │ 
  │ ;; Also see `denote-link-backlinks-display-buffer-action' which is a bit
  │ ;; advanced.
  │ 
  │ ;; If you use Markdown or plain text files (Org renders links as buttons
  │ ;; right away)
  │ (add-hook 'find-file-hook #'denote-link-buttonize-buffer)
  │ 
  │ ;; We use different ways to specify a path for demo purposes.
  │ (setq denote-dired-directories
  │       (list denote-directory
  │ 	    (thread-last denote-directory (expand-file-name "attachments"))
  │ 	    (expand-file-name "~/Documents/books")))
  │ 
  │ ;; Generic (great if you rename files Denote-style in lots of places):
  │ ;; (add-hook 'dired-mode-hook #'denote-dired-mode)
  │ ;;
  │ ;; OR if only want it in `denote-dired-directories':
  │ (add-hook 'dired-mode-hook #'denote-dired-mode-in-directories)
  │ 
  │ ;; Here is a custom, user-level command from one of the examples we
  │ ;; showed in this manual.  We define it here and add it to a key binding
  │ ;; below.
  │ (defun my-denote-journal ()
  │   "Create an entry tagged 'journal', while prompting for a title."
  │   (interactive)
  │   (denote
  │    (denote--title-prompt)
  │    '("journal")))
  │ 
  │ ;; Denote DOES NOT define any key bindings.  This is for the user to
  │ ;; decide.  For example:
  │ (let ((map global-map))
  │   (define-key map (kbd "C-c n j") #'my-denote-journal) ; our custom command
  │   (define-key map (kbd "C-c n n") #'denote)
  │   (define-key map (kbd "C-c n N") #'denote-type)
  │   (define-key map (kbd "C-c n d") #'denote-date)
  │   (define-key map (kbd "C-c n s") #'denote-subdirectory)
  │   (define-key map (kbd "C-c n t") #'denote-template)
  │   ;; If you intend to use Denote with a variety of file types, it is
  │   ;; easier to bind the link-related commands to the `global-map', as
  │   ;; shown here.  Otherwise follow the same pattern for `org-mode-map',
  │   ;; `markdown-mode-map', and/or `text-mode-map'.
  │   (define-key map (kbd "C-c n i") #'denote-link) ; "insert" mnemonic
  │   (define-key map (kbd "C-c n I") #'denote-link-add-links)
  │   (define-key map (kbd "C-c n l") #'denote-link-find-file) ; "list" links
  │   (define-key map (kbd "C-c n b") #'denote-link-backlinks)
  │   ;; Note that `denote-rename-file' can work from any context, not just
  │   ;; Dired bufffers.  That is why we bind it here to the `global-map'.
  │   (define-key map (kbd "C-c n r") #'denote-rename-file)
  │   (define-key map (kbd "C-c n R") #'denote-rename-file-using-front-matter))
  │ 
  │ ;; Key bindings specifically for Dired.
  │ (let ((map dired-mode-map))
  │   (define-key map (kbd "C-c C-d C-i") #'denote-link-dired-marked-notes)
  │   (define-key map (kbd "C-c C-d C-r") #'denote-dired-rename-marked-files)
  │   (define-key map (kbd "C-c C-d C-R") #'denote-dired-rename-marked-files-using-front-matter))
  │ 
  │ (with-eval-after-load 'org-capture
  │   (setq denote-org-capture-specifiers "%l\n%i\n%?")
  │   (add-to-list 'org-capture-templates
  │ 	       '("n" "New note (with denote.el)" plain
  │ 		 (file denote-last-path)
  │ 		 #'denote-org-capture
  │ 		 :no-save t
  │ 		 :immediate-finish nil
  │ 		 :kill-buffer t
  │ 		 :jump-to-captured t)))
  └────


13 Contributing
═══════════════

  Denote is a GNU ELPA package.  As such, any significant change to the
  code requires copyright assignment to the Free Software Foundation
  (more below).

  You do not need to be a programmer to contribute to this package.
  Sharing an idea or describing a workflow is equally helpful, as it
  teaches us something we may not know and might be able to cover either
  by extending Denote or expanding this manual ([Things to do]).  If you
  prefer to write a blog post, make sure you share it with us: we can
  add a section herein referencing all such articles.  Everyone gets
  acknowledged ([Acknowledgements]).  There is no such thing as an
  “insignificant contribution”—they all matter.

  ⁃ Package name (GNU ELPA): `denote'
  ⁃ Official manual: <https://protesilaos.com/emacs/denote>
  ⁃ Change log: <https://protesilaos.com/emacs/denote-changelog>
  ⁃ Git repo on SourceHut: <https://git.sr.ht/~protesilaos/denote>
    • Mirrors:
      ⁃ GitHub: <https://github.com/protesilaos/denote>
      ⁃ GitLab: <https://gitlab.com/protesilaos/denote>
  ⁃ Mailing list: <https://lists.sr.ht/~protesilaos/denote>

  If our public media are not suitable, you are welcome to contact me
  (Protesilaos) in private: <https://protesilaos.com/contact>.

  Copyright assignment is a prerequisite to sharing code.  It is a
  simple process.  Check the request form below (please adapt it
  accordingly).  You must write an email to the address mentioned in the
  form and then wait for the FSF to send you a legal agreement.  Sign
  the document and file it back to them.  This could all happen via
  email and take about a week.  You are encouraged to go through this
  process.  You only need to do it once.  It will allow you to make
  contributions to Emacs in general.

  ┌────
  │ Please email the following information to assign@gnu.org, and we
  │ will send you the assignment form for your past and future changes.
  │ 
  │ Please use your full legal name (in ASCII characters) as the subject
  │ line of the message.
  │ 
  │ REQUEST: SEND FORM FOR PAST AND FUTURE CHANGES
  │ 
  │ [What is the name of the program or package you're contributing to?]
  │ 
  │ GNU Emacs
  │ 
  │ [Did you copy any files or text written by someone else in these changes?
  │ Even if that material is free software, we need to know about it.]
  │ 
  │ Copied a few snippets from the same files I edited.  Their author,
  │ Protesilaos Stavrou, has already assigned copyright to the Free Software
  │ Foundation.
  │ 
  │ [Do you have an employer who might have a basis to claim to own
  │ your changes?  Do you attend a school which might make such a claim?]
  │ 
  │ 
  │ [For the copyright registration, what country are you a citizen of?]
  │ 
  │ 
  │ [What year were you born?]
  │ 
  │ 
  │ [Please write your email address here.]
  │ 
  │ 
  │ [Please write your postal address here.]
  │ 
  │ 
  │ 
  │ 
  │ 
  │ [Which files have you changed so far, and which new files have you written
  │ so far?]
  │ 
  └────


[Things to do] See section 14

[Acknowledgements] See section 17


14 Things to do
═══════════════

  Denote should work well for what is described in this manual.  Though
  we can always do better.  These are some of the tasks that are planned
  for the future and which you might want to help with ([Contributing]).

  This is a non-exhaustive list and you are always welcome to either
  report or work on something else.

  • ☐ Ensure integration between `denote:' links and Embark.
  • ☐ Add command that expands the identifier in links to a full name.
  • ☐ Add command that rewrites full names in links, if they are
    invalid.
  • ☐ Consider completion-at-point after `denote:' links.
  • ☐ Support mutually-exclusive sets of tags.

  These are just ideas.  We need to consider the pros and cons in each
  case and act accordingly.


[Contributing] See section 13


15 Alternatives to Denote
═════════════════════════

  What follows is a list of Emacs packages for note-taking.  I
  (Protesilaos) have not used any of them, as I was manually applying my
  file-naming scheme beforehand and by the time those packages were
  available I was already hacking on the predecessor of Denote as a
  means of learning Emacs Lisp (a package which I called “Unassuming
  Sidenotes of Little Significance”, aka “USLS” which is pronounced as
  “U-S-L-S” or “useless”).  As such, I cannot comment at length on the
  differences between Denote and each of those packages, beside what I
  gather from their documentation.

  [org-roam]
        The de facto standard in the Emacs milieu—and rightly so!  It
        has a massive community, is featureful, and should be an
        excellent companion to anyone who is invested in the Org
        ecosystem and/or knows what “Roam” is (I don’t).  It has been
        explained to me that Org Roam uses a database to store a cache
        about your notes.  It otherwise uses standard Org files.  The
        cache helps refer to the same node through aliases which can
        provide lots of options.  Personally, I follow a
        single-topic-per-note approach, so anything beyond that is
        overkill.  If the database is only for a cache, then maybe that
        has no downside, though I am careful with any kind of
        specialised program as it creates a dependency.  If you ask me
        about database software in particular, I have no idea how to use
        one, let alone debug it or retrieve data from it if something
        goes awry (I could learn, but that is beside the point).

  [zk (or zk.el)]
        Reading its documentation makes me think that this is Denote’s
        sibling—the two projects have a lot of things in common,
        including the preference to rely on plain files and standard
        tools.  The core difference is that Denote has a strict
        file-naming scheme.  Other differences in available features
        are, in principle, matters of style or circumstance: both
        packages can have them.  As its initials imply, ZK enables a
        zettelkasten-like workflow.  It does not enforce it though,
        letting the user adapt the method to their needs and
        requirements.

  [zettelkasten]
        This is another one of Denote’s relatives, at least insofar as
        the goal of simplicity is concerned.  The major difference is
        that according to its documentation “the name of the file that
        is created is just a unique ID”.  This is not consistent with
        our file-naming scheme which is all about making sense of your
        files by their name alone and being able to visually parse a
        listing of them without any kind of specialised tool (e.g. `ls
        -l' or `ls -C' on the command-line from inside the
        `denote-directory' give you a human-readable set of files names,
        while `find * -maxdepth 0 -type f' is another approach).

  [zetteldeft]
        This is a zettelkasten note-taking system built on top of the
        `deft' package.  Deft provides a search interface to a
        directory, in this case the one holding the user’s `zetteldeft'
        notes.  Denote has no such dependency and is not opinionated
        about how the user prefers to search/access their notes: use
        Dired, Grep, the `consult' package, or whatever else you already
        have set up for all things Emacs, not just your notes.

  Searching through `M-x list-packages' for “zettel” brings up more
  matches.  `zetteldesk' is an extension to Org Roam and, as such, I
  cannot possibly know what Org Roam truly misses and what the
  added-value of this package is.  `neuron-mode' builds on top of an
  external program called `neuron', which I have never used.

  Searching for “note” gives us a few more results.  `notes-mode' has
  precious little documentation and I cannot tell what it actually does
  (as I said in my presentation for LibrePlanet 2022, inadequate docs
  are a bug).  `side-notes' differs from what we try to do with Denote,
  as it basically gives you the means to record your thoughts about some
  other project you are working on and keep them on the side: so it and
  Denote should not be mutually exclusive.

  If I missed something, please let me know.


[org-roam] <https://github.com/org-roam/org-roam>

[zk (or zk.el)] <https://github.com/localauthor/zk>

[zettelkasten] <https://github.com/ymherklotz/emacs-zettelkasten>

[zetteldeft] <https://github.com/EFLS/zetteldeft>

15.1 Alternative ideas wih Emacs and further reading
────────────────────────────────────────────────────

  This section covers blog posts from the Emacs community on the matter
  of note-taking.  They may reference some of the packages covered in
  the previous section or provide their custom code ([Alternatives to
  Denote]).  The list is unsorted.

  ⁃ José Antonio Ortega Ruiz (aka “jao”) explains a note-taking method
    that is simple like Denote but differs in other ways.  An
    interesting approach overall:
    <https://jao.io/blog/2022-06-19-simple-note-taking.html>.

  ⁃ Jethro Kuan (the main `org-roam' developer) explains their
    note-taking techniques:
    <https://jethrokuan.github.io/org-roam-guide/>.  Good ideas all
    round, regardless of the package/code you choose to use.

  [ Development note: help expand this list. ]


[Alternatives to Denote] See section 15


16 Frequently Asked Questions
═════════════════════════════

  I (Protesilaos) answer some questions I have received or might get.
  It is assumed that you have read the rest of this manual: I will not
  go into the specifics of how Denote works.


16.1 Why develop Denote when PACKAGE already exists?
────────────────────────────────────────────────────

  I wrote Denote because I was using a variant of Denote’s file-naming
  scheme before I was even an Emacs user (I switched to Emacs from
  Tmux+Vim+CLI in the summer of 2019).  I was originally inspired by
  Jekyll, the static site generator, which I started using for my
  website in 2016 (was on WordPress before).  Jekyll’s files follow the
  `YYYY-MM-DD-TITLE.md' pattern.  I liked its efficiency relative to the
  unstructured mess I had before.  Eventually, I started using that
  scheme outside the confines of my website’s source code.  Over time I
  refined it and here we are.

  Note-taking is something I take very seriously, as I am a prolific
  writer (just check my website, which only reveals the tip of the
  iceberg).  As such, I need a program that does exactly what I want and
  which I know how to extend.  I originally tried to use Org capture
  templates to create new files with a Denote-style file-naming scheme
  but never managed to achieve it.  Maybe because `org-capture' has some
  hard-coded assumptions or I simply am not competent enough to hack on
  core Org facilities.  Whatever the case, an alternative was in order.

  The existence of PACKAGE is never a good reason for me not to conduct
  my own experiments for recreational, educational, or practical
  purposes.  When the question arises of “why not contribute to PACKAGE
  instead?” the answer is that without me experimenting in the first
  place, I would lack the skills for such a task.  Furthermore,
  contributing to another package does not guarantee I get what I want
  in terms of workflow.

  Whether you should use Denote or not is another matter altogether:
  choose whatever you want.


16.2 Why not rely exclusively on Org?
─────────────────────────────────────

  I think Org is one of Emacs’ killer apps.  I also believe it is not
  the right tool for every job.  When I write notes, I want to focus on
  writing.  Nothing more.  I thus have no need for stuff like org-babel,
  scheduling to-do items, clocking time, and so on.  The more “mental
  dependencies” you add to your workflow, the heavier the burden you
  carry and the less focused you are on the task at hand: there is
  always that temptation to tweak the markup, tinker with some syntactic
  construct, obsess about what ought to be irrelevant to writing as
  such.

  In technical terms, I also am not fond of Org’s code base (I
  understand why it is the way it is—just commenting on the fact).  Ever
  tried to read it?  You will routinely find functions that are
  tens-to-hundreds of lines long and have all sorts of special casing.
  As I am not a programmer and only learnt to write Elisp through trial
  and error, I have no confidence in my ability to make Org do what I
  want at that level, hence `denote' instead of `org-denote' or
  something.

  Perhaps the master programmer is one who can deal with complexity and
  keep adding to it.  I am of the opposite view, as language—code
  included—is at its communicative best when it is clear and accessible.

  Make no mistake: I use Org for the agenda and also to write technical
  documentation that needs to be exported to various formats, including
  this very manual.


16.3 Why care about Unix tools when you use Emacs?
──────────────────────────────────────────────────

  My notes form part of my longer-term storage.  I do not want to have
  to rely on a special program to be able to read them or filter them.
  Unix is universal, at least as far as I am concerned.

  Denote streamlines some tasks and makes things easier in general,
  which is consistent with how Emacs provides a layer of interactivity
  on top of Unix.  Still, Denote’s utilities can, in principle, be
  implemented as POSIX shell scripts (minus the Emacs-specific parts
  like fontification in Dired or the buttonization of links).

  Portability matters.  For example, in the future I might own a
  smartphone, so I prefer not to require Emacs, Org, or some other
  executable to access my files on the go.

  Furthermore, I might want to share those files with someone.  If I
  make Emacs a requirement, I am limiting my circle to a handful of
  relatively advanced users.

  Please don’t misinterpret this: I am using Emacs full-time for my
  computing and maintain a growing list of packages for it.  This is
  just me thinking long-term.


16.4 Why many small files instead of few large ones?
────────────────────────────────────────────────────

  I have read that Org favours the latter method.  If true, I strongly
  disagree with it because of the implicit dependency it introduces and
  the way it favours machine-friendliness over human-readability in
  terms of accessing information.  Notes are long-term storage.  I might
  want to access them on (i) some device with limited features, (ii)
  print on paper, (iii) share with another person who is not a tech
  wizard.

  There are good arguments for few large files, but all either
  prioritize machine-friendliness or presuppose the use of sophisticated
  tools like Emacs+Org.

  Good luck using `less' on a generic TTY to read a file with a zillion
  words, headings, sub-headings, sub-sub-headings, property drawers, and
  other constructs!  You will not get the otherwise wonderful folding of
  headings the way you do in Emacs—do not take such features for
  granted.

  My point is that notes should be atomic to help the user—and
  potentially the user’s family, friends, acquaintances—make sense of
  them in a wide range of scenaria.  The more program-agnostic your file
  is, the better for you and/or everyone else you might share your
  writings with.

  Human-readability means that we optimize for what matters to us.  If
  (a) you are the only one who will ever read your notes, (b) always
  have access to good software like Emacs+Org, (c) do not care about
  printing on paper, then Denote’s model is not for you.  Maybe you need
  to tweak some `org-capture' template to append a new entry to one mega
  file (I do that for my Org agenda, by the way, as I explained before
  about using the right tool for the job).


16.5 Does Denote perform well at scale?
───────────────────────────────────────

  Denote does not do anything fancy and has no special requirements: it
  uses standard tools to accomplish ordinary tasks.  If Emacs can cope
  with lots of files, then that is all you need to know: Denote will
  work.

  To put this to the test, Peter Prevos is running simulations with R
  that generate large volumes of notes.  You can read the technicalities
  here: <https://lucidmanager.org/productivity/testing-denote-package/>.
  Excerpt:

        Using this code I generated ten thousands notes and used
        this to test the Denote package to see it if works at a
        large scale. This tests shows that Prot’s approach is
        perfectly capable of working with thousands of notes.

  Of course, we are always prepared to make refinements to the code,
  where necessary, without compromising on the project’s principles.


16.6 I add TODOs to my files; will the many files slow down the Org agenda?
───────────────────────────────────────────────────────────────────────────

  I have not tested it, but assume that yes, many files will slow down
  the agenda due to how that works.

  If you want my opinion though, decouple your knowledge base from your
  ephemeral to-do list: Denote (and others) can be used for the former,
  while you let standard Org work splendidly for the latter—that is what
  I do, anyway.


16.7 I want to sort by last modified, why won’t Denote let me?
──────────────────────────────────────────────────────────────

  Denote does not sort files and will not reinvent tools that handle
  such functionality.  This is the job of the file manager or
  command-line executable that lists files.

  I encourage you to read the manpage of the `ls' executable.  It will
  help you in general, while it applies to Emacs as well via Dired.  The
  gist is that you can update the `ls' flags that Dired uses on-the-fly:
  type `C-u M-x dired-sort-toggle-or-edit' (`C-u s' by default) and
  append `--sort=time' at the prompt.  To reverse the order, add the
  `-r' flag.  The user option `dired-listing-switches' sets your default
  preference.


16.8 How do you handle the last modified case?
──────────────────────────────────────────────

  Denote does not insert any meta data or heading pertaining to edits in
  the file.  I am of the view that these either do not scale well or are
  not descriptive enough.  Suppose you use a “lastmod” heading with a
  timestamp: which lines where edited and what did the change amount to?

  This is where an external program can be helpful.  Use a Version
  Control System, such as Git, to keep track of all your notes.  Every
  time you add a new file, record the addition.  Same for post-creation
  edits.  Your VCS will let you review the history of those changes.
  For instance, Emacs’ built-in version control framework has a command
  that produces a log of changes for the current file: `M-x
  vc-print-log', bound to `C-x v l' by default.  From there one can
  access the corresponding diff output (use `M-x describe-mode' (`C-h
  m') in an unfamiliar buffer to learn more about it).  With Git in
  particular, Emacs users have the option of the all-round excellent
  `magit' package.

  In short: let Denote (or equivalent) create notes and link between
  them, the file manager organise and provide access to files, search
  programs deal with searching and narrowing, and version control
  software handle the tracking of changes.


16.9 Why do I get “Search failed with status 1” when I search for backlinks?
────────────────────────────────────────────────────────────────────────────

  Denote uses [Emacs’ Xref] to find backlinks.  Xref requires `xargs'
  and one of `grep' or `ripgrep', depending on your configuration.

  This is usually not an issue on *nix systems, but the necessary
  executables are not available on Windows Emacs distributions.  Please
  ensure that you have both `xargs' and either `grep' or `ripgrep'
  available within your `PATH' environment variable.

  If you have `git' on Windows installed, then you may use the following
  code (adjust the git’s installation path if necessary):
  ┌────
  │ (setenv "PATH" (concat (getenv "PATH") ";" "C:\\Program Files\\Git\\usr\\bin"))
  └────


[Emacs’ Xref] <info:emacs#Xref>


17 Acknowledgements
═══════════════════

  Denote is meant to be a collective effort.  Every bit of help matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to code or the manual
        Benjamin Kästner, Colin McLear, Damien Cassou, Jack Baty,
        Jean-Philippe Gagné Guay, Jürgen Hötzel, Kaushal Modi, Kyle
        Meyer, Peter Prevos, Philip Kaludercic, Quiliro Ordóñez, Stefan
        Monnier.

  Ideas and/or user feedback
        Abin Simon, Alan Schmitt, Alfredo Borrás, Benjamin Kästner,
        Colin McLear, Damien Cassou, Frank Ehmsen, Hanspeter Gisler,
        Jack Baty, Kaushal Modi, M. Hadi Timachi, Paul van Gelder, Peter
        Prevos, Shreyas Ragavan, Summer Emacs, Sven Seebeck, Taoufik,
        Ypot, hpgisler, pRot0ta1p.

  Special thanks to Peter Povinec who helped refine the file-naming
  scheme, which is the cornerstone of this project.

  Special thanks to Jean-Philippe Gagné Guay for the numerous
  contributions to the code base.


18 GNU Free Documentation License
═════════════════════════════════


19 Indices
══════════

19.1 Function index
───────────────────


19.2 Variable index
───────────────────


19.3 Concept index
──────────────────
