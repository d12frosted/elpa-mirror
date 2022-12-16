	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		 DENOTE: SIMPLE NOTES WITH AN EFFICIENT
			   FILE-NAMING SCHEME

			  Protesilaos Stavrou
			  info@protesilaos.com
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for the Emacs package called `denote' (or `denote.el'), and
provides every other piece of information pertinent to it.

The documentation furnished herein corresponds to stable version 1.2.0,
released on 2022-12-16.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 1.3.0-dev.

⁃ Package name (GNU ELPA): `denote'
⁃ Official manual: <https://protesilaos.com/emacs/denote>
⁃ Change log: <https://protesilaos.com/emacs/denote-changelog>
⁃ Git repo on SourceHut: <https://git.sr.ht/~protesilaos/denote>
  • Mirrors:
    ⁃ GitHub: <https://github.com/protesilaos/denote>
    ⁃ GitLab: <https://gitlab.com/protesilaos/denote>
⁃ Mailing list: <https://lists.sr.ht/~protesilaos/denote>
⁃ Backronyms: Denote Everything Neatly; Omit The Excesses.  Don’t Ever
  Note Only The Epiphenomenal.

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
..... 4. The `denote-date-prompt-use-org-read-date' option
..... 5. Add or remove keywords interactively
.. 2. Create note using Org capture
.. 3. Maintain separate directory silos for notes
.. 4. Exclude certain directories from all operations
.. 5. Exclude certain keywords from being inferred
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
.. 3. Insert links, but only those missing from current buffer
.. 4. Insert links from marked files in Dired
.. 5. Link to an existing note or create a new one
.. 6. The backlinks’ buffer
.. 7. Writing metanotes
.. 8. Visiting linked files via the minibuffer
.. 9. Miscellaneous information about links
8. Fontification in Dired
9. Use Org dynamic blocks
10. Minibuffer histories
11. Extending Denote
.. 1. Keep a journal or diary
.. 2. Create a note with the region’s contents
.. 3. Split an Org subtree into its own note
.. 4. Narrow the list of files in Dired
.. 5. Use `dired-virtual-mode' for arbitrary file listings
.. 6. Use Embark to collect minibuffer candidates
.. 7. Search file contents
.. 8. Bookmark the directory with the notes
.. 9. Use the `citar-denote' package for bibliography notes
.. 10. Use the `consult-notes' package
.. 11. Treat your notes as a project
.. 12. Variants of `denote-open-or-create'
.. 13. Variants of `denote-link-or-create'
12. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
13. Sample configuration
14. For developers or advanced users
15. Contributing
16. Things to do
17. Publications about Denote
18. Alternatives to Denote
.. 1. Alternative ideas with Emacs and further reading
19. Frequently Asked Questions
.. 1. Why develop Denote when PACKAGE already exists?
.. 2. Why not rely exclusively on Org?
.. 3. Why care about Unix tools when you use Emacs?
.. 4. Why many small files instead of few large ones?
.. 5. Does Denote perform well at scale?
.. 6. I add TODOs to my notes; will many files slow down the Org agenda?
.. 7. I want to sort by last modified, why won’t Denote let me?
.. 8. How do you handle the last modified case?
.. 9. Speed up backlinks’ buffer creation?
.. 10. Why do I get “Search failed with status 1” when I search for backlinks?
20. Acknowledgements
21. GNU Free Documentation License
22. Indices
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

[Writing metanotes] See section 7.7

[Keep a journal or diary] See section 11.1


3 Points of entry
═════════════════

  There are five ways to write a note with Denote: invoke the `denote',
  `denote-type', `denote-date', `denote-subdirectory', `denote-template'
  commands, or leverage the `org-capture-templates' by setting up a
  template which calls the function `denote-org-capture'.  We explain
  all of those in the subsequent sections.


3.1 Standard note creation
──────────────────────────

  The `denote' command will prompt for a title.  If a region is active,
  the text of the region becomes the default at the minibuffer prompt
  (meaning that typing `RET' without any input will use the default
  value).  Once the title is supplied, the `denote' command will then
  ask for keywords.  The resulting note will have a file name as already
  explained: [The file naming scheme]

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

    [The denote-date-prompt-use-org-read-date option].

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

[The denote-date-prompt-use-org-read-date option] See section 3.1.4

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

        [The denote-date-prompt-use-org-read-date option].

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

[The denote-date-prompt-use-org-read-date option] See section 3.1.4

[The denote-templates option] See section 3.1.2

◊ 3.1.3.1 Write your own convenience commands

  The convenience commands we provide only cover some basic use-cases
  ([Convenience commands for note creation]).  The user may require
  combinations that are not covered, such as to prompt for a template
  and for a subdirectory, instead of only one of the two.  To this end,
  we show how to follow the code we use in Denote to write your own
  variants of those commands.

  First let’s take a look at the definition of one of those commands.
  They all look the same, but we use `denote-subdirectory' for this
  example:

  ┌────
  │ (defun denote-subdirectory ()
  │   "Create note while prompting for a subdirectory.
  │ 
  │ Available candidates include the value of the variable
  │ `denote-directory' and any subdirectory thereof.
  │ 
  │ This is equivalent to calling `denote' when `denote-prompts' is
  │ set to '(subdirectory title keywords)."
  │   (declare (interactive-only t))
  │   (interactive)
  │   (let ((denote-prompts '(subdirectory title keywords)))
  │     (call-interactively #'denote)))
  └────

  The hyphenated word after `defun' is the name of the function.  It has
  to be unique.  Then we have the documentation string (or “doc string”)
  which is for the user’s convenience.

  This function is `interactive', meaning that it can be called via
  `M-x' or be assigned to a key binding.  Then we have the local binding
  of the `denote-prompts' to the desired combination (“local” means
  specific to this function without affecting other contexts).  Lastly,
  it calls the standard `denote' command interactively, so it uses all
  the prompts in their specified order.

  Now let’s say we want to have a command that (i) asks for a template
  and (ii) for a subdirectory ([The denote-templates option]).  All we
  need to do is tweak the `let' bound value of `denote-prompts' and give
  our command a unique name:

  ┌────
  │ ;; Like `denote-subdirectory' but also ask for a template
  │ (defun denote-subdirectory-with-template ()
  │   "Create note while also prompting for a template and subdirectory.
  │ 
  │ This is equivalent to calling `denote' when `denote-prompts' is
  │ set to '(template subdirectory title keywords)."
  │   (declare (interactive-only t))
  │   (interactive)
  │   (let ((denote-prompts '(template subdirectory title keywords)))
  │     (call-interactively #'denote)))
  └────

  The tweaks to `denote-prompts' determine how the command will behave
  ([The denote-prompts option]).  Use this paradigm to write your own
  variants which you can then assign to keys or invoke with `M-x'.


  [Convenience commands for note creation] See section 3.1.3

  [The denote-templates option] See section 3.1.2

  [The denote-prompts option] See section 3.1.1


3.1.4 The `denote-date-prompt-use-org-read-date' option
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  By default, Denote uses its own simple prompt for date or date+time
  input ([The denote-prompts option]).  This is done when the
  `denote-prompts' option includes a `date' symbol and/or when the user
  invokes the `denote-date' command.

  Users who want to benefit from the more advanced date selection method
  that is common in interactions with Org mode, can set the user option
  `denote-date-prompt-use-org-read-date' to a non-nil value.


[The denote-prompts option] See section 3.1.1


3.1.5 Add or remove keywords interactively
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The commands `denote-keywords-add' and `denote-keywords-remove'
  streamline the process of interactively updating a file’s keywords in
  the front matter and renaming it accordingly.

  The `denote-keywords-add' asks for keywords using the familiar
  minibuffer prompt ([Standard note creation]).  It then renames the
  file ([Rename a single file based on its front matter]).

  Similarly, the `denote-keywords-remove' removes one or more keywords
  from the list of existing keywords and then renames the file
  accordingly.


[Standard note creation] See section 3.1

[Rename a single file based on its front matter] See section 4.3


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


3.3 Maintain separate directory silos for notes
───────────────────────────────────────────────

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

  It is possible to configure other user options of Denote to have a
  silo-specific value.  For example, this one changes the
  `denote-known-keywords' only for this particular silo:

  ┌────
  │ ;;; Directory Local Variables.  For more information evaluate:
  │ ;;;
  │ ;;;     (info "(emacs) Directory Variables")
  │ 
  │ ((nil . ((denote-directory . default-directory)
  │ 	 (denote-known-keywords . ("food" "drink")))))
  └────

  This one is like the above, but also disables `denote-infer-keywords':

  ┌────
  │ ;;; Directory Local Variables.  For more information evaluate:
  │ ;;;
  │ ;;;     (info "(emacs) Directory Variables")
  │ 
  │ ((nil . ((denote-directory . default-directory)
  │ 	 (denote-known-keywords . ("food" "drink"))
  │ 	 (denote-infer-keywords . nil))))
  └────

  To expand the list of local variables to, say, cover specific major
  modes, we can do something like this:

  ┌────
  │ ;;; Directory Local Variables.  For more information evaluate:
  │ ;;;
  │ ;;;     (info "(emacs) Directory Variables")
  │ 
  │ ((nil . ((denote-directory . default-directory)
  │ 	 (denote-known-keywords . ("food" "drink"))
  │ 	 (denote-infer-keywords . nil)))
  │  (org-mode . ((org-hide-emphasis-markers . t)
  │ 	      (org-hide-macro-markers . t)
  │ 	      (org-hide-leading-stars . t))))
  └────

  As not all user options have a “safe” local value, Emacs will ask the
  user to confirm their choice and to store it in the Custom code
  snippet that is normally appended to init file (or added to the file
  specified by the user option `custom-file').

  Finally, it is possible to have a `.dir-locals.el' for subdirectories
  of any `denote-directory'.  Perhaps to specify a different set of
  known keywords, while not making the subdirectory a silo in its own
  right.  We shall not expand on such an example, as we trust the user
  to experiment with the best setup for their workflow.

  Feel welcome to ask for help if the information provided herein is not
  sufficient.  The manual shall be expanded accordingly.


3.4 Exclude certain directories from all operations
───────────────────────────────────────────────────

  The user option `denote-excluded-directories-regexp' instructs all
  Denote functions that read or check file/directory names to omit
  directories that match the given regular expression.  The regexp needs
  to match only the name of the directory, not its full path.

  Affected operations include file prompts and functions that return the
  available files in the value of the user option `denote-directory'
  ([Maintain separate directory silos for notes]).

  File prompts are used by several commands, such as `denote-link' and
  `denote-subdirectory'.

  Functions that check for files include `denote-directory-files' and
  `denote-directory-subdirectories'.

  The match is performed with `string-match-p'.

  [For developers or advanced users].


[Maintain separate directory silos for notes] See section 3.3

[For developers or advanced users] See section 14


3.5 Exclude certain keywords from being inferred
────────────────────────────────────────────────

  The user option `denote-excluded-keywords-regexp' omits keywords that
  match a regular expression from the list of inferred keywords.

  Keywords are inferred from file names and provided at relevant prompts
  as completion candidates when the user option `denote-infer-keywords'
  is non-nil.

  The match is performed with `string-match-p'.


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

  If `FILE' has a Denote-compliant identifier, retain it while updating
  the `TITLE' and `KEYWORDS' fields of the file name.  Else create an
  identifier based on the following conditions:

  • If `FILE' does not have an identifier and optional `DATE' is non-nil
    (such as with a prefix argument), invoke the function
    `denote-prompt-for-date-return-id'.  It prompts for a date and uses
    it to derive the identifier.

  • If `FILE' does not have an identifier and optional `DATE' is nil
    (this is the case without a prefix argument), use the file
    attributes to determine the last modified date and format it as an
    identifier.

  • As a fallback, derive an identifier from the current time.

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

  If called interactively with a prefix argument `C-u' or from Lisp with
  a non-nil `AUTO-CONFIRM' argument, this “yes or no” prompt is skipped.

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

  This is how it looks for Org mode (when `denote-file-type' is nil or
  the `org' symbol):

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

  These variables have a string value with specifiers that are used by
  the `format' function.  The formatting operation passes four arguments
  which include the values of the given entries.  If you are an advanced
  user who wants to edit this variable to affect how front matter is
  produced, consider using something like `%2$s' to control where the
  Nth argument is placed.

  When editing the value, make sure to:

  1. Not use empty lines inside the front matter block.

  2. Insert at least one empty line after the front matter block and do
     not use any empty line before it.

  These help with consistency and might prove useful if we ever need to
  operate on the front matter as a whole.

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

  The description of the link is taken from the target file’s front
  matter or, if that is not available, from the file name.  If the
  region is active, its text is used as the link’s description instead.
  If the active region has no text, the inserted link used just the
  identifier, as with the `C-u' prefix mentioned above.

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


7.3 Insert links, but only those missing from current buffer
────────────────────────────────────────────────────────────

  As a variation on the `denote-link-add-links' command, one may wish to
  only include ’missing links’, i.e. links that are not yet present in
  the current file.

  This can be achieved with `denote-link-add-missing-links'. The command
  is similar to `denote-link-add-links', but will only include links to
  notes that are not yet linked to ([Insert links matching a regexp]).


[Insert links matching a regexp] See section 7.2


7.4 Insert links from marked files in Dired
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


7.5 Link to an existing note or create a new one
────────────────────────────────────────────────

  In one’s note-taking workflow, there may come a point where they are
  expounding on a certain topic but have an idea about another subject
  they would like to link to ([Linking notes]).  The user can always
  rely on the other linking facilities we have covered herein to target
  files that already exist.  Though they may not know whether they
  already have notes covering the subject or whether they would need to
  write new ones.  To this end, Denote provides two convenience
  commands:

  `denote-link-after-creating'
        Create new note in the background and link to it directly.

        Use `denote' interactively to produce the new note.  Its doc
        string or this manual explains which prompts will be used and
        under what conditions ([Standard note creation]).

        With optional `ID-ONLY' as a prefix argument (this is the `C-u'
        key, by default) create a link that consists of just the
        identifier.  Else try to also include the file’s title.  This
        has the same meaning as in `denote-link' ([Adding a single
        link]).

        IMPORTANT NOTE: Normally, `denote' does not save the buffer it
        produces for the new note.  This is a safety precaution to not
        write to disk unless the user wants it (e.g. the user may choose
        to kill the buffer, thus cancelling the creation of the note).
        However, for this command the creation of the note happens in
        the background and the user may miss the step of saving their
        buffer.  We thus have to save the buffer in order to (i)
        establish valid links, and (ii) retrieve whatever front matter
        from the target file.

  `denote-link-or-create'
        Use `denote-link' on `TARGET' file, creating it if necessary.

        If `TARGET' file does not exist, call
        `denote-link-after-creating' which runs the `denote' command
        interactively to create the file.  The established link will
        then be targeting that new file.

        If `TARGET' file does not exist, add the user input that was
        used to search for it to the history of the
        `denote-title-prompt'.  The user can then retrieve and possibly
        further edit their last input, using it as the newly created
        note’s actual title.  At the `denote-title-prompt' type `M-p'
        with the default key bindings, which calls
        `previous-history-element'.

        With optional `ID-ONLY' as a prefix argument create a link with
        just the file’s identifier.  This has the same meaning as in
        `denote-link'.

        This command has the alias
        `denote-link-to-existing-or-new-note', which helps with
        discoverability.


[Linking notes] See section 7

[Standard note creation] See section 3.1

[Adding a single link] See section 7.1


7.6 The backlinks’ buffer
─────────────────────────

  The command `denote-link-backlinks' produces a bespoke buffer which
  displays backlinks to the current note.  A “backlink” is a link back
  to the present entry.

  By default, the backlinks’ buffer is desinged to display the file name
  of the note linking to the current entry.  Each file name is presented
  on its own line, like this:

  ┌────
  │ Backlinks to "On being honest" (20220614T130812)
  │ ------------------------------------------------
  │ 
  │ 20220614T145606--let-this-glance-become-a-stare__journal.txt
  │ 20220616T182958--feeling-butterflies-in-your-stomach__journal.txt
  └────

  When the user option `denote-backlinks-show-context' is non-nil, the
  backlinks’ buffer displays the line on which a link to the current
  note occurs.  It also shows multiple occurances, if present.  It looks
  like this (and has the appropriate fontification):

  ┌────
  │ Backlinks to "On being honest" (20220614T130812)
  │ ------------------------------------------------
  │ 
  │ 20220614T145606--let-this-glance-become-a-stare__journal.txt
  │ 37: growing into it: [[denote:20220614T130812][On being honest]].
  │ 64: As I said in [[denote:20220614T130812][On being honest]] I have never
  │ 20220616T182958--feeling-butterflies-in-your-stomach__journal.txt
  │ 62: indifference.  In [[denote:20220614T130812][On being honest]] I alluded
  └────

  Note that the width of the lines in the context depends on the
  underlying file.  In the above example, the lines are split at the
  `fill-column'.  Long lines will show up just fine.  Also note that the
  built-in user option `xref-truncation-width' can truncate long lines
  to a given maximum number of characters.

  [Speed up backlinks’ buffer creation?]

  The backlinks’ buffer runs the major-mode `denote-backlinks-mode'.  It
  binds keys to move between links with `n' (next) and `p' (previous).
  These are stored in the `denote-backlinks-mode-map' (use `M-x
  describe-mode' (`C-h m') in an unfamiliar buffer to learn more about
  it).  When the user option `denote-backlinks-show-context' is non-nil,
  all relevant Xref key bindings are fully functional: again, check
  `describe-mode'.

  The backlinking facility uses Emacs’ built-in Xref infrastructure.  On
  some operating systems, the user may need to add certain executables
  to the relevant environment variable.

  [Why do I get “Search failed with status 1” when I search for
  backlinks?]

  Backlinks to the current file can also be visited by using the
  minibuffer completion interface with the `denote-link-find-backlink'
  command ([Visiting linked files via the minibuffer]).

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


[Speed up backlinks’ buffer creation?] See section 19.9

[Why do I get “Search failed with status 1” when I search for
backlinks?] See section 19.10

[Visiting linked files via the minibuffer] See section 7.8


7.7 Writing metanotes
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

[Insert links from marked files in Dired] See section 7.4


7.8 Visiting linked files via the minibuffer
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

  To visit backlinks to the current note via the minibuffer, use
  `denote-link-find-backlink'.  This is an alternative to placing
  backlinks in a dedicated buffer ([The backlinks’ buffer]).


[Extending Denote] See section 11

[The backlinks’ buffer] See section 7.6


7.9 Miscellaneous information about links
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


9 Use Org dynamic blocks
════════════════════════

  Denote can optionally integrate with Org mode’s “dynamic blocks”
  facility.  Start by loading the relevant library:

  ┌────
  │ ;; Register Denote's Org dynamic blocks
  │ (require 'denote-org-dblock)
  └────

  A dynamic block gets its contents by evaluating a given function,
  depending on the type of block.  The type of block and its parameters
  are stated in the opening `#+BEGIN' line of the block.  Typing `C-c
  C-c' with point on that line runs the function, with the given
  arguments, and populates the block’s contents accordingly.

  Denote leverages Org dynamic blocks to streamline the inclusion of (i)
  links to notes whose name matches a given search query (like
  `denote-link-add-links') and (ii) backlinks to the current note
  (similar to `denote-link-find-backlink').

  These two types of blocks are named `denote-links' and
  `denote-backlinks' respectively.  The latter does not accept any
  parameters, while the former does, which we explain below by also
  demonstrating how dynamic blocks are written.

  A dynamic block looks like this:

  ┌────
  │ #+BEGIN: denote-links :regexp "_journal"
  │ 
  │ #+END:
  └────


  Here we have the `denote-links' type, with the `:regexp' parameter.
  The value of the `:regexp' parameter is the same as that of the
  command `denote-link-add-links' ([Insert links matching a regexp]).
  The linked entry provides practical examples of patterns that make
  good use of Denote’s file-naming scheme ([The file-naming scheme]).

  In this example, we instruct Org to produce a list of all notes that
  include the `journal' keyword in their file name (keywords in file
  names are prefixed with the underscore).  So the following:

  ┌────
  │ #+BEGIN: denote-links :regexp "_journal"
  │ 
  │ #+END:
  └────


  Becomes something like this once we type `C-c C-c' with point on the
  `#+BEGIN' line (Org makes the links look prettier by default):

  ┌────
  │ #+BEGIN: denote-links :regexp "_journal"
  │ - [[denote:20220616T182958][Feeling butterflies in your stomach]]
  │ - [[denote:20220818T221036][Between friend and stranger]]
  │ #+END:
  └────


  The dynamic block takes care to keep the list in order and to add any
  missing links when the block is evaluated anew.

  Depending on one’s workflow, the dynamic block can be instructed to
  list only those links which are missing from the current buffer
  (similar to `denote-link-add-missing-links').  Adding the
  `:missing-only' parameter with a non-`nil' value achieves this
  effect. The `#+BEGIN' line looks like this:

  ┌────
  │ #+BEGIN: denote-links :regexp "_journal" :missing-only t
  └────


  To reverse the order links appear in, add `:reverse t' to the
  `#+BEGIN' line.

  The `denote-links' block can also accept a `:block-name' parameter
  with a string value that names the block.  Once the dynamic block is
  evaluated, a `#+NAME' is prepended to the block’s contents.  This can
  be referenced in other source blocks to parse the named block’s
  contents as input of another process.  The details are beyond the
  scope of Denote.

  As for the `denote-backlinks' dynamic block type, it simply produces a
  list of notes that link to the current file.  It accepts no parameters
  and looks like this:

  ┌────
  │ #+BEGIN: denote-backlinks
  │ 
  │ #+END:
  └────


  The Org manual describes the technicalities of Dynamic Blocks.
  Evaluate:

  ┌────
  │ (info "(org) Dynamic Blocks")
  └────

  Dynamic blocks are particularly useful for metanote entries that
  reflect on the status of earlier notes ([Writing metanotes]).


[Insert links matching a regexp] See section 7.2

[The file-naming scheme] See section 5

[Writing metanotes] See section 7.7


10 Minibuffer histories
═══════════════════════

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


11 Extending Denote
═══════════════════

  Denote is a tool with a narrow scope: create notes and link between
  them, based on the aforementioned file-naming scheme.  For other
  common operations the user is advised to rely on standard Emacs
  facilities or specialised third-party packages.  This section covers
  the details.


11.1 Keep a journal or diary
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


11.2 Create a note with the region’s contents
─────────────────────────────────────────────

  Sometimes it makes sense to gather notes in a single file and later
  review it to make multiple notes out of it.  With the following code,
  the user marks a region and then invokes the command
  `my-denote-create-new-note-from-region': it prompts for a title and
  keywords and then uses the region’s contents to fill in the newly
  created note.

  ┌────
  │ (defun my-denote-create-new-note-from-region (beg end)
  │   "Create note whose contents include the text between BEG and END.
  │ Prompt for title and keywords of the new note."
  │   (interactive "r")
  │   (if-let (((region-active-p))
  │ 	   (text (buffer-substring-no-properties beg end)))
  │       (progn
  │ 	(denote (denote--title-prompt) (denote--keywords-prompt))
  │ 	(insert text))
  │     (user-error "No region is available")))
  └────

  Have a different workflow?  Feel welcome to discuss it in any of our
  official channels ([Contributing]).


[Contributing] See section 15


11.3 Split an Org subtree into its own note
───────────────────────────────────────────

  With Org files in particular, it is common to have nested headings
  which could be split off into their own standalone notes.  In Org
  parlance, an entry with all its subheadings is a “subtree”.  With the
  following code, the user places the point inside the heading they want
  to split off and invokes the command `my-denote-org-extract-subtree'.
  It will create a note using the heading’s text and tags for the new
  file.  The contents of the subtree become the contents of the new note
  and are removed from the old one.

  ┌────
  │ (defun my-denote-org-extract-subtree ()
  │   "Create new Denote note using current Org subtree.
  │ Make the new note use the Org file type, regardless of the value
  │ of `denote-file-type'.
  │ 
  │ Use the subtree title as the note's title.  If available, use the
  │ tags of the heading are used as note keywords.
  │ 
  │ Delete the original subtree."
  │   (interactive)
  │   (if-let ((text (org-get-entry))
  │ 	   (heading (org-get-heading :no-tags :no-todo :no-priority :no-comment)))
  │       (progn
  │ 	(delete-region (org-entry-beginning-position) (org-entry-end-position))
  │ 	(denote heading (org-get-tags) 'org)
  │ 	(insert text))
  │     (user-error "No subtree to extract; aborting")))
  └────

  Have a different workflow?  Feel welcome to discuss it in any of our
  official channels ([Contributing]).


[Contributing] See section 15


11.4 Narrow the list of files in Dired
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


11.5 Use `dired-virtual-mode' for arbitrary file listings
─────────────────────────────────────────────────────────

  Emacs’ Dired is a powerful file manager that builds its functionality
  on top of the Unix `ls' command.  As noted elsewhere in this manual,
  the user can update the `ls' flags that Dired uses to display its
  contents ([I want to sort by last modified, why won’t Denote let
  me?]).

  What Dired cannot do is parse the output of a result that is produced
  by piped commands, such as `ls -l | sort -t _ -k2'.  This specific
  example targets the second underscore-separated field of the file
  name, per our conventions ([The file-naming scheme]).  Conceretely, it
  matches the “alpha” as the sorting key in something like this:

  ┌────
  │ 20220929T200432--testing-file-one__alpha.txt
  └────

  Consider then, how Dired will sort those files by their identifier:

  ┌────
  │ 20220929T200432--testing-file-one__alpha.txt
  │ 20220929T200532--testing-file-two__beta.txt
  │ 20220929T200632--testing-file-three__alpha.txt
  │ 20220929T200732--testing-file-four__beta.txt
  └────

  Whereas on the command line, we can get the following:

  ┌────
  │ $ ls | sort -t _ -k 2
  │ 20220929T200432--testing-file-one__alpha.txt
  │ 20220929T200632--testing-file-three__alpha.txt
  │ 20220929T200532--testing-file-two__beta.txt
  │ 20220929T200732--testing-file-four__beta.txt
  └────

  This is where `dired-virtual-mode' shows its utility.  If we tweak our
  command-line invocation to include `ls -l', this mode can behave like
  Dired on the listed files.  (We omit the output of the `-l' flag from
  this tutorial, as it is too verbose.)

  What we now need is to capture the output of `ls -l | sort -t _ -k 2'
  in an Emacs buffer and then enable `dired-virtual-mode'.  To do that,
  we can rely on either `M-x shell' or `M-x eshell' and then manually
  copy the relevant contents.

  For the user’s convenience, I share what I have for Eshell to quickly
  capture the last command’s output in a dedicated buffer:

  ┌────
  │ (defcustom prot-eshell-output-buffer "*Exported Eshell output*"
  │   "Name of buffer with the last output of Eshell command.
  │ Used by `prot-eshell-export'."
  │   :type 'string
  │   :group 'prot-eshell)
  │ 
  │ (defcustom prot-eshell-output-delimiter "* * *"
  │   "Delimiter for successive `prot-eshell-export' outputs.
  │ This is formatted internally to have newline characters before
  │ and after it."
  │   :type 'string
  │   :group 'prot-eshell)
  │ 
  │ (defun prot-eshell--command-prompt-output ()
  │   "Capture last command prompt and its output."
  │   (let ((beg (save-excursion
  │ 	       (goto-char (eshell-beginning-of-input))
  │ 	       (goto-char (point-at-bol)))))
  │     (when (derived-mode-p 'eshell-mode)
  │       (buffer-substring-no-properties beg (eshell-end-of-output)))))
  │ 
  │ ;;;###autoload
  │ (defun prot-eshell-export ()
  │   "Produce a buffer with output of the last Eshell command.
  │ If `prot-eshell-output-buffer' does not exist, create it.  Else
  │ append to it, while separating multiple outputs with
  │ `prot-eshell-output-delimiter'."
  │   (interactive)
  │   (let ((eshell-output (prot-eshell--command-prompt-output)))
  │     (with-current-buffer (get-buffer-create prot-eshell-output-buffer)
  │       (let ((inhibit-read-only t))
  │ 	(goto-char (point-max))
  │ 	(unless (eq (point-min) (point-max))
  │ 	  (insert (format "\n%s\n\n" prot-eshell-output-delimiter)))
  │ 	(goto-char (point-at-bol))
  │ 	(insert eshell-output)
  │ 	(switch-to-buffer-other-window (current-buffer))))))
  └────

  Bind `prot-eshell-export' to a key in the `eshell-mode-map' and give
  it a try (I use `C-c C-e').  In the produced buffer, activate the
  `dired-virtual-mode'.


[I want to sort by last modified, why won’t Denote let me?] See section
19.7

[The file-naming scheme] See section 5


11.6 Use Embark to collect minibuffer candidates
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


[Narrow the list of files in Dired] See section 11.4


11.7 Search file contents
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


11.8 Bookmark the directory with the notes
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


11.9 Use the `citar-denote' package for bibliography notes
──────────────────────────────────────────────────────────

  Peter Prevos has produced the `citar-denote' package which makes it
  possible to write notes on BibTeX entries with the help of the `citar'
  package.  These notes have the citation’s unique key associated with
  them in the file’s front matter.  They also get a configurable keyword
  in their file name, making it easy to find them in Dired and/or
  retrieve them with the various Denote methods.

  With `citar-denote', the user leverages standard minibuffer completion
  mechanisms (e.g. with the help of the `vertico' and `embark' packages)
  to manage bibliographic notes and access those notes with ease.  The
  package’s documentation covers the details:
  <https://github.com/pprevos/citar-denote/>.


11.10 Use the `consult-notes' package
─────────────────────────────────────

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


11.11 Treat your notes as a project
───────────────────────────────────

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


11.12 Variants of `denote-open-or-create'
─────────────────────────────────────────

  The command `denote-open-or-create' prompts to visit a file in the
  `denote-directory'.  If the user input does not have any matches,
  `denote-open-or-create' will call the `denote' command interactively.
  It will then use whatever prompts `denote' normally has, per the user
  option `denote-prompts' ([Standard note creation]).

  To speed up the process or to maintain variants that suit one’s
  workflow, we provide these ready-to-use commands that one can add to
  their Emacs init file.  They can be assigned to key bindings or be
  used via `M-x' after they have been evaluated.

  ┌────
  │ ;;;###autoload
  │ (defun denote-open-or-create-with-date ()
  │   "Invoke `denote-open-or-create' but also prompt for date.
  │ 
  │ The date can be in YEAR-MONTH-DAY notation like 2022-06-30 or
  │ that plus the time: 2022-06-16 14:30.  When the user option
  │ `denote-date-prompt-use-org-read-date' is non-nil, the date
  │ prompt uses the more powerful Org+calendar system.
  │ 
  │ This is the equivalent to calling `denote-open-or-create' when
  │ `denote-prompts' is set to \\='(date title keywords)."
  │   (declare (interactive-only t))
  │   (interactive)
  │   (let ((denote-prompts '(date title keywords)))
  │     (call-interactively #'denote-open-or-create)))
  │ 
  │ ;;;###autoload
  │ (defun denote-open-or-create-with-type ()
  │   "Invoke `denote-open-or-create' but also prompt for file type.
  │ This is the equivalent to calling `denote-open-or-create' when
  │ `denote-prompts' is set to \\='(type title keywords)."
  │   (declare (interactive-only t))
  │   (interactive)
  │   (let ((denote-prompts '(type title keywords)))
  │     (call-interactively #'denote-open-or-create)))
  │ 
  │ ;;;###autoload
  │ (defun denote-open-or-create-with-subdirectory ()
  │   "Invoke `denote-open-or-create' but also prompt for subdirectory.
  │ This is the equivalent to calling `denote-open-or-create' when
  │ `denote-prompts' is set to \\='(subdirectory title keywords)."
  │   (declare (interactive-only t))
  │   (interactive)
  │   (let ((denote-prompts '(subdirectory title keywords)))
  │     (call-interactively #'denote-open-or-create)))
  │ 
  │ ;;;###autoload
  │ (defun denote-open-or-create-with-template ()
  │   "Invoke `denote-open-or-create' but also prompt for template.
  │ This is the equivalent to calling `denote-open-or-create' when
  │ `denote-prompts' is set to \\='(template title keywords).
  │ 
  │ For templates, refer to `denote-templates'."
  │   (declare (interactive-only t))
  │   (interactive)
  │   (let ((denote-prompts '(template title keywords)))
  │     (call-interactively #'denote-open-or-create)))
  └────


[Standard note creation] See section 3.1


11.13 Variants of `denote-link-or-create'
─────────────────────────────────────────

  The command `denote-link-or-create' uses `denote-link' on a `TARGET'
  file, creating it if necessary.  The `TARGET' matches the user input
  at a minibuffer prompt: it is a file in the `denote-directory'.

  If `TARGET' file does not exist, The `denote-link-or-create' calls
  `denote-link-after-creating' which runs the standard `denote' command
  interactively to create the file ([Standard note creation]).  The
  established link will then be targeting that new file.

  When called with an optional prefix argument (`C-u' by default)
  `denote-link-or-create' creates a link that consists of just the
  identifier.  Else it tries to also include the file’s title.  This has
  the same meaning as in `denote-link' ([Linking notes]).

  To speed up the process or to maintain variants that suit one’s
  workflow, we provide these ready-to-use commands that one can add to
  their Emacs init file.  They can be assigned to key bindings or be
  used via `M-x' after they have been evaluated.

  ┌────
  │ ;;;###autoload
  │ (defun denote-link-or-create-with-date ()
  │   "Invoke `denote-link-or-create' but also prompt for date.
  │ 
  │ The date can be in YEAR-MONTH-DAY notation like 2022-06-30 or
  │ that plus the time: 2022-06-16 14:30.  When the user option
  │ `denote-date-prompt-use-org-read-date' is non-nil, the date
  │ prompt uses the more powerful Org+calendar system.
  │ 
  │ This is the equivalent to calling `denote-link-or-create' when
  │ `denote-prompts' is set to \\='(date title keywords)."
  │   (declare (interactive-only t))
  │   (interactive)
  │   (let ((denote-prompts '(date title keywords)))
  │     (call-interactively #'denote-link-or-create)))
  │ 
  │ ;;;###autoload
  │ (defun denote-link-or-create-with-type ()
  │   "Invoke `denote-link-or-create' but also prompt for file type.
  │ This is the equivalent to calling `denote-link-or-create' when
  │ `denote-prompts' is set to \\='(type title keywords)."
  │   (declare (interactive-only t))
  │   (interactive)
  │   (let ((denote-prompts '(type title keywords)))
  │     (call-interactively #'denote-link-or-create)))
  │ 
  │ ;;;###autoload
  │ (defun denote-link-or-create-with-subdirectory ()
  │   "Invoke `denote-link-or-create' but also prompt for subdirectory.
  │ This is the equivalent to calling `denote-link-or-create' when
  │ `denote-prompts' is set to \\='(subdirectory title keywords)."
  │   (declare (interactive-only t))
  │   (interactive)
  │   (let ((denote-prompts '(subdirectory title keywords)))
  │     (call-interactively #'denote-link-or-create)))
  │ 
  │ ;;;###autoload
  │ (defun denote-link-or-create-with-template ()
  │   "Invoke `denote-link-or-create' but also prompt for template.
  │ This is the equivalent to calling `denote-link-or-create' when
  │ `denote-prompts' is set to \\='(template title keywords).
  │ 
  │ For templates, refer to `denote-templates'."
  │   (declare (interactive-only t))
  │   (interactive)
  │   (let ((denote-prompts '(template title keywords)))
  │     (call-interactively #'denote-link-or-create)))
  └────


[Standard note creation] See section 3.1

[Linking notes] See section 7


12 Installation
═══════════════




12.1 GNU ELPA package
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


12.2 Manual installation
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


13 Sample configuration
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
  │ (setq denote-excluded-directories-regexp nil)
  │ (setq denote-excluded-keywords-regexp nil)
  │ 
  │ ;; Pick dates, where relevant, with Org's advanced interface:
  │ (setq denote-date-prompt-use-org-read-date t)
  │ 
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
  │ ;; By default, we do not show the context of links.  We just display
  │ ;; file names.  This provides a more informative view.
  │ (setq denote-backlinks-show-context t)
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
  │   (define-key map (kbd "C-c n b") #'denote-link-backlinks)
  │   (define-key map (kbd "C-c n f f") #'denote-link-find-file)
  │   (define-key map (kbd "C-c n f b") #'denote-link-find-backlink)
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
  │ 
  │ ;; Also check the commands `denote-link-after-creating',
  │ ;; `denote-link-or-create'.  You may want to bind them to keys as well.
  └────


14 For developers or advanced users
═══════════════════════════════════

  Denote is in a stable state and can be relied upon as the basis for
  custom extensions.  Further below is a list with the functions or
  variables we provide for public usage.  Those are in addition to all
  user options and commands that are already documented in the various
  sections of this manual.

  In this context “public” is any form with single hyphens in its
  symbol, such as `denote-directory-files'.  We expressly support those,
  meaning that we consider them reliable and commit to documenting any
  changes in their particularities (such as through `make-obsolete', a
  record in the change log, a blog post on the maintainer’s website, and
  the like).

  By contradistinction, a “private” form is declared with two hyphens in
  its symbol such as `denote--file-extension'.  Do not use those as we
  might change them without further notice.

  Variable `denote-id-format'
        Format of ID prefix of a note’s filename.  The note’s ID is
        derived from the date and time of its creation ([The file-naming
        scheme]).

  Variable `denote-id-regexp'
        Regular expression to match `denote-id-format'.

  Variable `denote-title-regexp'
        Regular expression to match the TITLE field in a file name ([The
        file-naming scheme]).

  Variable `denote-keywords-regexp'
        Regular expression to match the KEYWORDS field in a file name
        ([The file-naming scheme]).

  Variable `denote-excluded-punctuation-regexp'
        Punctionation that is removed from file names.  We consider
        those characters illegal for our purposes.

  Variable `denote-excluded-punctuation-extra-regexp'
        Additional punctuation that is removed from file names.  This
        variable is for advanced users who need to extend the
        `denote-excluded-punctuation-regexp'.  Once we have a better
        understanding of what we should be omitting, we will update
        things accordingly.

  Function `denote-file-is-note-p'
        Return non-nil if `FILE' is an actual Denote note.  For our
        purposes, a note must not be a directory, must satisfy
        `file-regular-p', its path must be part of the variable
        `denote-directory', it must have a Denote identifier in its
        name, and use one of the extensions implied by
        `denote-file-type'.

  Function `denote-file-has-identifier-p'
        Return non-nil if `FILE' has a Denote identifier.

  Function `denote-file-has-supported-extension-p'
        Return non-nil if `FILE' has supported extension.  Also account
        for the possibility of an added `.gpg' suffix. Supported
        extensions are those implied by `denote-file-type'.

  Function `denote-file-is-writable-and-supported-p'
        Return non-nil if `FILE' is writable and has supported
        extension.

  Function `denote-keywords'
        Return appropriate list of keyword candidates.  If
        `denote-infer-keywords' is non-nil, infer keywords from existing
        notes and combine them into a list with `denote-known-keywords'.
        Else use only the latter set of keywords ([Standard note
        creation]).

  Function `denote-keywords-sort'
        Sort `KEYWORDS' if `denote-sort-keywords' is non-nil.
        `KEYWORDS' is a list of strings, per `denote-keywords-prompt'.

  Function `denote-directory'
        Return path of the variable `denote-directory' as a proper
        directory, also because it accepts a directory-local value for
        what we internally refer to as “silos” ([Maintain separate
        directories for notes]).

  Function `denote-directory-files'
        Return list of absolute file paths in variable
        `denote-directory'.  Files only need to have an identifier.  The
        return value may thus include file types that are not implied by
        `denote-file-type'. To limit the return value to text files, use
        the function `denote-directory-text-only-files'.  Remember that
        the `denote-directory' accepts a directory-local value
        ([Maintain separate directories for notes]).

  Function `denote-directory-text-only-files'
        Return list of text files in variable `denote-directory'.
        Filter `denote-directory-files' using `denote-file-is-note-p'.

  Function `denote-directory-subdirectories'
        Return list of subdirectories in variable
        `denote-directory'. Omit dotfiles (such as .git)
        unconditionally.  Also exclude whatever matches
        `denote-excluded-directories-regexp'.  Note that the
        `denote-directory' accepts a directory-local value for what we
        call “silos” ([Maintain separate directories for notes]).

  Function `denote-directory-files-matching-regexp'
        Return list of files matching `REGEXP' in
        `denote-directory-files'.

  Function `denote-file-name-relative-to-denote-directory'
        Return name of `FILE' relative to the variable
        `denote-directory'.  `FILE' must be an absolute path.

  Function `denote-get-path-by-id'
        Return absolute path of `ID' string in `denote-directory-files'.

  Function `denote-barf-duplicate-id'
        Throw a `user-error' if `IDENTIFIER' already exists.

  Function `denote-sluggify'
        Make `STR' an appropriate slug for file names and related
        ([Sluggified title and keywords]).

  Function `denote-sluggify-and-join'
        Sluggify `STR' while joining separate words.

  Function `denote-desluggify'
        Upcase first char in `STR' and dehyphenate `STR', inverting
        `denote-sluggify'.  Basically, convert `this-is-a-test' to `This
        is a test'.

  Function `denote-sluggify-keywords'
        Sluggify `KEYWORDS', which is a list of strings ([Sluggified
        title and keywords]).

  Function `denote-filetype-heuristics'
        Return likely file type of `FILE'.  Use the file extension to
        detect the file type of the file.

        If more than one file type correspond to this file extension,
        use the first file type for which the key-title-kegexp matches
        in the file or, if none matches, use the first type with this
        file extension in `denote-file-type'.

        If no file types in `denote-file-types' has the file extension,
        the file type is assumed to be the first of `denote-file-types'.

  Function `denote-format-file-name'
        Format file name.  `PATH', `ID', `KEYWORDS', `TITLE-SLUG' are
        expected to be supplied by `denote' or equivalent: they will all
        be converted into a single string.  `EXTENSION' is the file type
        extension, as a string.

  Function `denote-extract-keywords-from-path'
        Extract keywords from `PATH' and return them as a list of
        strings.  `PATH' must be a Denote-style file name where keywords
        are prefixed with an underscore.  If `PATH' has no such
        keywords, which is possible, return nil ([The file-naming
        scheme]).

  Function `denote-extract-id-from-string'
        Return existing Denote identifier in `STRING', else nil.

  Function `denote-retrieve-filename-identifier'
        Extract identifier from `FILE' name.  To return an existing
        identifier or create a new one, refer to the
        `denote-retrieve-or-create-file-identifier' function.

  Function `denote-retrieve-or-create-file-identifier'
        Return `FILE' identifier, generating one if appropriate.  The
        conditions are as follows:

        • If `FILE' has an identifier, return it.

        • If `FILE' does not have an identifier and optional `DATE' is
          non-nil, invoke `denote-prompt-for-date-return-id'.

        • If `FILE' does not have an identifier and DATE is nil, use the
          file attributes to determine the last modified date and format
          it as an identifier.

        • As a fallback, derive an identifier from the current time.

        To only return an existing identifier, refer to the function
        `denote-retrieve-filename-identifier'.

  Function `denote-retrieve-filename-title'
        Extract title from `FILE' name, else return `file-name-base'.
        Run `denote-desluggify' on the title if the extraction is
        successful.

  Function `denote-retrieve-title-value'
        Return title value from `FILE' front matter per `FILE-TYPE'.

  Function `denote-retrieve-title-line'
        Return title line from `FILE' front matter per `FILE-TYPE'.

  Function `denote-retrieve-keywords-value'
        Return keywords value from `FILE' front matter per `FILE-TYPE'.

  Function `denote-retrieve-keywords-line'
        Return keywords line from `FILE' front matter per `FILE-TYPE'.

  Function `denote-file-prompt'
        Prompt for file with identifier in variable `denote-directory'.
        With optional `INITIAL-TEXT', use it to prepopulate the
        minibuffer.

  Function `denote-keywords-prompt'
        Prompt for one or more keywords.  In the case of multiple
        entries, those are separated by the `crm-sepator', which
        typically is a comma.  In such a scenario, the output is sorted
        with `string-lessp'.  To sort the return value, use
        `denote-keywords-sort'.

  Function `denote-title-prompt'
        Read file title for `denote'.  With optional `DEFAULT-TITLE' use
        it as the default value.

  Function `denote-file-type-prompt'
        Prompt for `denote-file-type'.  Note that a non-nil value other
        than `text', `markdown-yaml', and `markdown-toml' falls back to
        an Org file type.  We use `org' here for clarity.

  Function `denote-date-prompt'
        Prompt for date, expecting `YYYY-MM-DD' or that plus `HH:MM' (or
        even `HH:MM:SS').  Use Org’s more advanced date selection
        utility if the user option
        `denote-date-prompt-use-org-read-date' is non-nil.  It requires
        Org ([The denote-date-prompt-use-org-read-date option]).

  Function `denote-prompt-for-date-return-id'
        Use `denote-date-prompt' and return it as `denote-id-format'.

  Function `denote-template-prompt'
        Prompt for template key in `denote-templates' and return its
        value.

  Function `denote-subdirectory-prompt'
        Prompt for subdirectory of the variable `denote-directory'.  The
        table uses the `file' completion category (so it works with
        packages such as `marginalia' and `embark').

  Function `denote-rename-file-prompt'
        Prompt to rename file named `OLD-NAME' to `NEW-NAME'.

  Function `denote-rename-file-and-buffer'
        Rename file named `OLD-NAME' to `NEW-NAME', updating buffer
        name.

  Function `denote-update-dired-buffers'
        Update Dired buffers of variable `denote-directory'.  Note that
        the `denote-directory' accepts a directory-local value for what
        we internally refer to as “silos” ([Maintain separate
        directories for notes]).

  Variable `denote-file-types'
        Alist of `denote-file-type' and their format properties.

        Each element is of the form `(SYMBOL PROPERTY-LIST)'.  `SYMBOL'
        is one of those specified in `denote-file-type' or an arbitrary
        symbol that defines a new file type.

        `PROPERTY-LIST' is a plist that consists of eight elements:

        1. `:extension' is a string with the file extension including
           the period.

        2. `:date-function' is a function that can format a date.  See
           the functions `denote--date-iso-8601',
           `denote--date-rfc3339', and `denote--date-org-timestamp'.

        3. `:front-matter' is either a string passed to `format' or a
           variable holding such a string.  The `format' function
           accepts four arguments, which come from `denote' in this
           order: `TITLE', `DATE', `KEYWORDS', `IDENTIFIER'.  Read the
           doc string of `format' on how to reorder arguments.

        4. `:title-key-regexp' is a regular expression that is used to
           retrieve the title line in a file.  The first line matching
           this regexp is considered the title line.

        5. `:title-value-function' is the function used to format the
           raw title string for inclusion in the front matter (e.g. to
           surround it with quotes).  Use the `identity' function if no
           further processing is required.

        6. `:title-value-reverse-function' is the function used to
           retrieve the raw title string from the front matter.  It
           performs the reverse of `:title-value-function'.

        7. `:keywords-key-regexp' is a regular expression used to
           retrieve the keywords’ line in the file.  The first line
           matching this regexp is considered the keywords’ line.

        8. `:keywords-value-function' is the function used to format the
           keywords’ list of strings as a single string, with
           appropriate delimiters, for inclusion in the front matter.

        9. `:keywords-value-reverse-function' is the function used to
           retrieve the keywords’ value from the front matter.  It
           performs the reverse of the `:keywords-value-function'.

        10. `:link' is a string, or variable holding a string, that
            specifies the format of a link.  See the variables
            `denote-org-link-format', `denote-md-link-format'.

        11. `:link-in-context-regexp' is a regular expression that is
            used to match the aforementioned link format.  See the
            variables `denote-org-link-in-context-regexp',
            `denote-md-link-in-context-regexp'.

        If `denote-file-type' is nil, use the first element of this list
        for new note creation.  The default is `org'.

  Variable `denote-org-front-matter'
        Specifies the Org front matter.  It is passed to `format' with
        arguments `TITLE', `DATE', `KEYWORDS', `ID' ([Change the front
        matter format])

  Variable `denote-yaml-front-matter'
        Specifies the YAML (Markdown) front matter.  It is passed to
        `format' with arguments `TITLE', `DATE', `KEYWORDS', `ID'
        ([Change the front matter format])

  Variable `denote-toml-front-matter'
        Specifies the TOML (Markdown) front matter.  It is passed to
        `format' with arguments `TITLE', `DATE', `KEYWORDS', `ID'
        ([Change the front matter format])

  Variable `denote-text-front-matter'
        Specifies the plain text front matter.  It is passed to `format'
        with arguments `TITLE', `DATE', `KEYWORDS', `ID' ([Change the
        front matter format])

  Variable `denote-org-link-format'
        Format of Org link to note.  The value is passed to `format'
        with `IDENTIFIER' and `TITLE' arguments, in this order.  Also
        see `denote-org-link-in-context-regexp'.

  Variable `denote-md-link-format'
        Format of Markdown link to note.  The `%N$s' notation used in
        the default value is for `format' as the supplied arguments are
        `IDENTIFIER' and `TITLE', in this order.  Also see
        `denote-md-link-in-context-regexp'.

  Variable `denote-id-only-link-format'
        Format of identifier-only link to note.  The value is passed to
        `format' with `IDENTIFIER' as its sole argument.  Also see
        `denote-id-only-link-in-context-regexp'.

  Variable `denote-org-link-in-context-regexp'
        Regexp to match an Org link in its context.  The format of such
        links is `denote-org-link-format'.

  Variable `denote-md-link-in-context-regexp'
        Regexp to match an Markdown link in its context.  The format of
        such links is `denote-md-link-format'.

  Variable `denote-id-only-link-in-context-regexp'
        Regexp to match an identifier-only link in its context.  The
        format of such links is `denote-id-only-link-format'.

  Function `denote-surround-with-quotes'
        Surround string `S' with quotes.  This can be used in
        `denote-file-types' to format front mattter.

  Function `denote-date-org-timestamp'
        Format `DATE' using the Org inactive timestamp notation.

  Function `denote-date-rfc3339'
        Format `DATE' using the RFC3339 specification.

  Function `denote-date-iso-8601'
        Format `DATE' according to ISO 8601 standard.

  Function `denote-trim-whitespace'
        Trim whitespace around string `S'.  This can be used in
        `denote-file-types' to format front mattter.

  Function `denote-trim-whitespace-then-quotes'
        Trim whitespace then quotes around string `S'.  This can be used
        in `denote-file-types' to format front mattter.

  Function `denote-format-keywords-for-md-front-matter'
        Format front matter `KEYWORDS' for markdown file type.
        `KEYWORDS' is a list of strings.  Consult the
        `denote-file-types' for how this is used.

  Function `denote-format-keywords-for-text-front-matter'
        Format front matter `KEYWORDS' for text file type.  `KEYWORDS'
        is a list of strings.  Consult the `denote-file-types' for how
        this is used.

  Function `denote-format-keywords-for-org-front-matter'
        Format front matter `KEYWORDS' for org file type.  `KEYWORDS' is
        a list of strings.  Consult the `denote-file-types' for how this
        is used.

  Function `denote-extract-keywords-from-front-matter'
        Format front matter `KEYWORDS' for org file type.  `KEYWORDS' is
        a list of strings.  Consult the `denote-file-types' for how this
        is used.


[The file-naming scheme] See section 5

[Standard note creation] See section 3.1

[Maintain separate directories for notes] See section 3.3

[Sluggified title and keywords] See section 5.1

[The denote-date-prompt-use-org-read-date option] See section 3.1.4

[Change the front matter format] See section 6.1


15 Contributing
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


[Things to do] See section 16

[Acknowledgements] See section 20


16 Things to do
═══════════════

  Denote should work well for what is described in this manual.  Though
  we can always do better.  This is a non-exhaustive list with some
  low-priority ideas you may want to help with ([Contributing]).

  • Support mutually-exclusive sets of tags.  For example, a `home'
    keyword would preclude `work'.  Personally, I am not a fan of such
    arrangements as there may be a case where something applies to both
    ends of this prefigured binary.  Though we can think about it.

  • Add command that expands the identifier in links to a full file
    name.  This would be useful for some sort of “export” operation
    where the absolute file path is necessary and where the Denote
    linking mechanism is not available.  Though this could be handled by
    the exporter, by doing something like what `denote-link-find-file'
    does.

  • Add command that rewrites full names in links, if they are invalid.
    This would complement the renaming mechanism.  Personally, I think
    old titles in links are not a problem, because they show you what
    was true at the time and are usually relevant to their context.
    Again though, it is an option worth exploring.

  • Ensure integration between `denote:' links and the `embark' package.
    The idea is to allow Embark to understand the Denote buttons are
    links to files and correctly infer the absolute path.  I am not sure
    what a user would want to do with this, but maybe there are some
    interesting possibilities.

  You are welcome to suggest more ideas.  If they do not broaden the
  scope of Denote, they can be added to denote.el.  Otherwise we might
  think of extensions to the core package.


[Contributing] See section 15


17 Publications about Denote
════════════════════════════

  The Emacs community is putting Denote to great use.  This section
  includes publications that show how people configure their note-taking
  setup.  If you have a blog post, video, or configuration file about
  Denote, feel welcome to tell us about it ([Contributing]).

  ⁃ David Wilson (SystemCrafters): /Generating a Blog Site from Denote
    Entries/, 2022-09-09, <https://www.youtube.com/watch?v=5R7ad5xz5wo>.

  ⁃ David Wilson (SystemCrafters): /Trying Out Prot’s Denote, an Org
    Roam Alternative?/, 2022-07-15,
    <https://www.youtube.com/watch?v=QcRY_rsX0yY>.

  ⁃ Jack Baty: /Keeping my Org Agenda updated based on Denote keywords/,
    2022-11-30, <https://baty.net/2022/keeping-my-org-agenda-updated>.

  ⁃ Jeremy Friesen: /Denote Emacs Configuration/, 2022-10-02,
    <https://takeonrules.com/2022/10/09/denote-emacs-configuration/>

  ⁃ Jeremy Friesen: /Exploring the Denote Emacs Package/, 2022-10-01,
    <https://takeonrules.com/2022/10/01/exploring-the-denote-emacs-package/>

  ⁃ Jeremy Friesen: /Migration Plan for Org-Roam Notes to Denote/,
    2022-10-02,
    <https://takeonrules.com/2022/10/02/migration-plan-for-org-roam-notes-to-denote/>

  ⁃ Jeremy Friesen: /Project Dispatch Menu with Org Mode Metadata,
    Denote, and Transient/, 2022-11-19,
    <https://takeonrules.com/2022/11/19/project-dispatch-menu-with-org-mode-metadata-denote-and-transient/>

  ⁃ Peter Prevos: /Simulating Text Files with R to Test the Emacs Denote
    Package/, 2022-07-28,
    <https://lucidmanager.org/productivity/testing-denote-package/>.


[Contributing] See section 15


18 Alternatives to Denote
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

18.1 Alternative ideas with Emacs and further reading
─────────────────────────────────────────────────────

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


[Alternatives to Denote] See section 18


19 Frequently Asked Questions
═════════════════════════════

  I (Protesilaos) answer some questions I have received or might get.
  It is assumed that you have read the rest of this manual: I will not
  go into the specifics of how Denote works.


19.1 Why develop Denote when PACKAGE already exists?
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


19.2 Why not rely exclusively on Org?
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


19.3 Why care about Unix tools when you use Emacs?
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


19.4 Why many small files instead of few large ones?
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


19.5 Does Denote perform well at scale?
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


19.6 I add TODOs to my notes; will many files slow down the Org agenda?
───────────────────────────────────────────────────────────────────────

  Yes, many files will slow down the agenda due to how that works.  Org
  collects all files specified in the `org-agenda-files', searches
  through their contents for timestamped entries, and then loops through
  all days to determine where each entry belongs.  The more days and
  more files, the longer it takes to build the agenda.  Doing this with
  potentially hundreds of files will have a noticeable impact on
  performance.

  This is not a deficiency of Denote.  It happens with generic Org
  files.  The way the agenda is built is heavily favoring the use of a
  single file that holds all your timestamped entries (or at least a few
  such files).  Tens or hundreds of files are inefficient for this job.
  Plus doing so has the side-effect of making Emacs open all those
  files, which you probably do not need.

  If you want my opinion though, be more forceful with the separation of
  concerns.  Decouple your knowledge base from your ephemeral to-do
  list: Denote (and others) can be used for the former, while you let
  standard Org work splendidly for the latter—that is what I do, anyway.

  Org has a powerful linking facility, whether you use `org-store-link'
  or do it via an `org-capture' template.  If you want a certain note to
  be associated with a task, just store the task in a single `tasks.org'
  (or however you name it) and link to the relevant context.

  Do not mix your knowledge base with your to-do items.  If you need
  help figuring out the specifics of this workflow, you are welcome to
  ask for help in our relevant channels ([Contributing]).


[Contributing] See section 15


19.7 I want to sort by last modified, why won’t Denote let me?
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

  There is also “virtual Dired” if you need something that cannot be
  done with Dired ([Use dired-virtual-mode for arbitrary file
  listings]).


[Use dired-virtual-mode for arbitrary file listings] See section 11.5


19.8 How do you handle the last modified case?
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


19.9 Speed up backlinks’ buffer creation?
─────────────────────────────────────────

  Denotes leverages the built-in `xref' library to search for the
  identifier of the current file and return any links to it.  For users
  of Emacs version 28 or higher, there exists a user option to specify
  the program that performs this search: `xref-search-program'.  The
  default is `grep', which can be slow, though one may opt for `ugrep',
  `ripgrep', or even specify something else (read the doc string of that
  user option for the details).

  Try either for these for better results:

  ┌────
  │ (setq xref-search-program 'ripgrep)
  │ 
  │ ;; OR
  │ 
  │ (setq xref-search-program 'ugrep)
  └────

  To use whatever executable is available on your system, use something
  like this:

  ┌────
  │ ;; Prefer ripgrep, then ugrep, and fall back to regular grep.
  │ (setq xref-search-program
  │       (cond
  │        ((or (executable-find "ripgrep")
  │ 	    (executable-find "rg"))
  │ 	'ripgrep)
  │        ((executable-find "ugrep")
  │ 	'ugrep)
  │        (t
  │ 	'grep)))
  └────


19.10 Why do I get “Search failed with status 1” when I search for backlinks?
─────────────────────────────────────────────────────────────────────────────

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


20 Acknowledgements
═══════════════════

  Denote is meant to be a collective effort.  Every bit of help matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to code or the manual
        Abin Simon, Alan Schmitt, Benjamin Kästner, Charanjit Singh,
        Clemens Radermacher, Colin McLear, Damien Cassou, Elias Storms,
        Eshel Yaron, Florian, Graham Marlow, Hilde Rhyne, Jack Baty,
        Jean-Philippe Gagné Guay, Jürgen Hötzel, Kaushal Modi, Kyle
        Meyer, Marc Fargas, Noboru Ota (nobiot), Peter Prevos, Philip
        Kaludercic, Quiliro Ordóñez, Stefan Monnier, Thibaut Benjamin.

  Ideas and/or user feedback
        Abin Simon, Alan Schmitt, Alfredo Borrás, Benjamin Kästner,
        Colin McLear, Damien Cassou, Elias Storms, Federico Stilman,
        Florian, Frank Ehmsen, Guo Yong, Hanspeter Gisler, Jack Baty,
        Jeremy Friesen, Juanjo Presa, Johan Bolmsjö, Kaushal Modi,
        M. Hadi Timachi, Paul van Gelder, Peter Prevos, Shreyas Ragavan,
        Stefan Thesing, Summer Emacs, Sven Seebeck, Taoufik, Viktor
        Haag, Yi Liu, Ypot, atanasj, hpgisler, pRot0ta1p, sienic, sundar
        bp.

  Special thanks to Peter Povinec who helped refine the file-naming
  scheme, which is the cornerstone of this project.

  Special thanks to Jean-Philippe Gagné Guay for the numerous
  contributions to the code base.


21 GNU Free Documentation License
═════════════════════════════════


22 Indices
══════════

22.1 Function index
───────────────────


22.2 Variable index
───────────────────


22.3 Concept index
──────────────────
