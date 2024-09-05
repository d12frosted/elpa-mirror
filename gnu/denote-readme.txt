           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                 DENOTE: SIMPLE NOTES WITH AN EFFICIENT
                           FILE-NAMING SCHEME

                          Protesilaos Stavrou
                          info@protesilaos.com
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for the Emacs package called `denote' (or `denote.el'), and
provides every other piece of information pertinent to it.

The documentation furnished herein corresponds to stable version 3.1.0,
released on 2024-09-04.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 3.2.0-dev.

⁃ Package name (GNU ELPA): `denote'
⁃ Official manual: <https://protesilaos.com/emacs/denote>
⁃ Change log: <https://protesilaos.com/emacs/denote-changelog>
⁃ Git repositories:
  ⁃ GitHub: <https://github.com/protesilaos/denote>
  ⁃ GitLab: <https://gitlab.com/protesilaos/denote>
⁃ Video demo: <https://protesilaos.com/codelog/2022-06-18-denote-demo/>
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
..... 2. The `denote-history-completion-in-prompts' option
..... 3. The `denote-templates' option
..... 4. Convenience commands for note creation
..... 5. The `denote-save-buffers' option
..... 6. The `denote-kill-buffers' option
..... 7. The `denote-date-prompt-use-org-read-date' option
.. 2. Create a note from the current Org subtree
.. 3. Create note using Org capture
.. 4. Create note with specific prompts using Org capture
.. 5. Create a note with the region’s contents
..... 1. A custom `denote-region' that references the source
.. 6. Open an existing note or create it if missing
.. 7. Maintain separate directory silos for notes
..... 1. How to switch a silo
..... 2. Use custom commands to select a silo
..... 3. The `denote-silo-extras.el'
..... 4. Make Org export work with silos
..... 5. Make any Denote command work in a silo from anywhere
.. 8. Exclude certain files from file prompts
.. 9. Exclude certain directories from all operations
.. 10. Exclude certain keywords from being inferred
.. 11. Use Denote commands from the menu bar or context menu
4. Renaming files
.. 1. Rename a single file
..... 1. The `denote-rename-confirmations' option
.. 2. Rename a single file based on its front matter
.. 3. Rename multiple files interactively
.. 4. Rename multiple files at once by asking only for keywords
.. 5. Rename multiple files based on their front matter
.. 6. Rename a file by changing only its file type
.. 7. Rename a file by adding or removing a title interactively
.. 8. Rename a file by adding or removing keywords interactively
.. 9. Rename a file by adding or removing a signature interactively
.. 10. Find duplicate identifiers and put them in a Dired buffer
.. 11. Faces used by rename commands
5. The file-naming scheme
.. 1. Change the order of file name components
.. 2. Sluggification of file name components
.. 3. User-defined sluggification of file name components
..... 1. Custom sluggification to remove non-ASCII characters
.. 4. Features of the file-naming scheme for searching or filtering
6. Front matter
.. 1. Change the front matter format
.. 2. Regenerate front matter
7. Linking notes
.. 1. Adding a single link
.. 2. The `denote-org-store-link-to-heading' user option
.. 3. Insert link to an Org file with a further pointer to a heading
.. 4. Insert links matching a regexp
.. 5. Insert link to file with signature
.. 6. Insert links from marked files in Dired
.. 7. Link to an existing note or create a new one
.. 8. The backlinks’ buffer
..... 1. Backlinks for Org headings
.. 9. Writing metanotes
.. 10. Visiting linked files via the minibuffer
.. 11. Convert `denote:' links to `file:' links
.. 12. Fontify links in non-Org buffers
.. 13. Miscellaneous information about links
..... 1. Aliases for the linking commands
..... 2. The `denote-link-description-function' to format links
8. Choose which commands to prompt for
9. Fontification in Dired
10. Automatically rename Denote buffers
.. 1. The `denote-rename-buffer-format' option
11. Use Org dynamic blocks
.. 1. Org dynamic blocks to insert links
.. 2. The Org dynamic block to insert missing links only
.. 3. The Org dynamic block to insert backlinks
.. 4. Org dynamic block to insert file contents
.. 5. Org dynamic block to insert Org files as headings
12. Sort files by component
.. 1. Configure what extra prompts `denote-sort-dired' issues
.. 2. Define a sorting function per component
..... 1. Sort signatures that include Luhmann-style sequences
13. Keep a journal or diary
.. 1. Journaling with a timer
14. Minibuffer histories
15. Extending Denote
.. 1. Create a new note in any directory
.. 2. Narrow the list of files in Dired
.. 3. Use `dired-virtual-mode' for arbitrary file listings
.. 4. Use Embark to collect minibuffer candidates
.. 5. Search file contents
.. 6. Bookmark the directory with the notes
.. 7. Use the `denote-explore' package to explore your notes
.. 8. Use the `citar-denote' package for bibliography notes
.. 9. Use the `consult-notes' package for enhanced minibuffer interactions
.. 10. Use the `consult-notes' package
.. 11. Use the `denote-menu' package
.. 12. Treat your notes as a project
.. 13. Use the tree-based file prompt for select commands
.. 14. Rename files with Denote in the Image Dired thumbnails buffer
.. 15. Rename files with Denote using `dired-preview'
.. 16. Avoid duplicate identifiers when exporting Denote notes
..... 1. Export Denote notes with Org Mode
..... 2. Export Denote notes with Markdown
16. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
17. Sample configuration
18. For developers or advanced users
19. Troubleshoot Denote in a pristine environment
20. Contributing
.. 1. Wishlist of what we can do to extend Denote
21. Publications about Denote
22. Alternatives to Denote
.. 1. Alternative implementations and further reading
23. Frequently Asked Questions
.. 1. Why develop Denote when PACKAGE already exists?
.. 2. Why not rely exclusively on Org?
.. 3. Why care about Unix tools when you use Emacs?
.. 4. Why many small files instead of few large ones?
.. 5. Does Denote perform well at scale?
.. 6. I add TODOs to my notes; will many files slow down the Org agenda?
.. 7. I want to sort by last modified in Dired, why won’t Denote let me?
.. 8. How do you handle the last modified case?
.. 9. Why are some Org links opening outside Emacs?
.. 10. Speed up backlinks’ buffer creation?
.. 11. Why do I get “Search failed with status 1” when I search for backlinks?
.. 12. Why do I get a double `#+title' in Doom Emacs?
24. Acknowledgements
25. GNU Free Documentation License
26. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2022-2024 Free Software Foundation, Inc.

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
  note-taking and file-naming tool for Emacs.

  Denote is based on the idea that files should follow a predictable and
  descriptive file-naming scheme.  The file name must offer a clear
  indication of what the contents are about, without reference to any
  other metadata.  Denote basically streamlines the creation of such
  files or file names while providing facilities to link between them
  (where those files are editable).

  Denote’s file-naming scheme is not limited to “notes”.  It can be used
  for all types of file, including those that are not editable in Emacs,
  such as videos.  Naming files in a consistent way makes their
  filtering and retrieval considerably easier.  Denote provides relevant
  facilities to rename files, regardless of file type.

  Denote is based on the following core design principles:

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

[Writing metanotes] See section 7.9

[Keep a journal or diary] See section 13


3 Points of entry
═════════════════

  There are five main ways to write a note with Denote: invoke the
  `denote', `denote-type', `denote-date', `denote-subdirectory',
  `denote-template', `denote-signature' commands, or leverage the
  `org-capture-templates' by setting up a template which calls the
  function `denote-org-capture'.  We explain all of those in the
  subsequent sections.  Other more specialised commands exist as well,
  which one shall learn about as they read through this manual.  We do
  not want to overwhelm the user with options at this stage.

  All these commands constructs the file name in accordance with the
  user option `denote-file-name-components-order' ([Change the order of
  file name components]).


[Change the order of file name components] See section 5.1

3.1 Standard note creation
──────────────────────────

  The `denote' command will prompt for a title.  If a region is active,
  the text of the region becomes the default at the minibuffer prompt
  (meaning that typing `RET' without any input will use the default
  value).  Once the title is supplied, the `denote' command will then
  ask for keywords.  The resulting note will have a file name as already
  explained: [The file naming scheme]

  The `denote' command runs the hook `denote-after-new-note-hook' after
  creating the new note.

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

  Commands that prompt for user input to construct a Denote file name
  include, but are not limited to: `denote', `denote-signature',
  `denote-type', `denote-date', `denote-subdirectory',
  `denote-rename-file', `denote-dired-rename-files'.

  • [Convenience commands for note creation].
  • [Renaming files].

  The value of this user option is a list of symbols, which includes any
  of the following:

  • `title': Prompt for the title of the new note ([The
    `denote-history-completion-in-prompts' option]).

  • `keywords': Prompts with completion for the keywords of the new
    note.  Available candidates are those specified in the user option
    `denote-known-keywords'.  If the user option `denote-infer-keywords'
    is non-nil, keywords in existing note file names are included in the
    list of candidates.  The `keywords' prompt uses
    `completing-read-multiple', meaning that it can accept multiple
    keywords separated by a comma (or whatever the value of
    `crm-separator' is).

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

  • `signature': - Prompts for an arbitrary string that can be used to
    establish a sequential relationship between files (e.g. 1, 1a, 1b,
    1b1, 1b2, …).  Signatures have no strictly defined function and are
    up to the user to apply as they see fit.  One use-case is to
    implement Niklas Luhmann’s Zettelkasten system for a sequence of
    notes (Folgezettel).  Signatures are not included in a file’s front
    matter.  They are reserved solely for creating a sequence in a file
    listing, at least for the time being.  To insert a link that
    includes the signature, use the command `denote-link-with-signature'
    ([Insert link to file with signature]).

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
  `denote' or other relevant commands (advanced users can call it from
  Lisp). In Lisp usage, the behaviour is always what the caller
  specifies, based on the supplied arguments.


[Standard note creation] See section 3.1

[Convenience commands for note creation] See section 3.1.4

[Renaming files] See section 4

[The `denote-history-completion-in-prompts' option] See section 3.1.2

[The denote-date-prompt-use-org-read-date option] See section 3.1.7

[The denote-templates option] See section 3.1.3

[Insert link to file with signature] See section 7.5

[The file-naming scheme] See section 5


3.1.2 The `denote-history-completion-in-prompts' option
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The user option `denote-history-completion-in-prompts' toggles history
  completion in all `denote-prompts-with-history-as-completion'.

  When this user option is set to a non-nil value, Denote will use
  minibuffer history entries as completion candidates in all of the
  `denote-prompts-with-history-as-completion'. Those will show previous
  inputs from their respective history as possible values to select,
  either to (i) re-insert them verbatim or (ii) with the intent to edit
  them further (depending on the minibuffer user interface, one can
  select a candidate with `TAB' without exiting the minibuffer, as
  opposed to what `RET' normally does by selecting and exiting).

  When this user option is set to a nil value, all of the
  `denote-prompts-with-history-as-completion' will not use minibuffer
  completion: they will just prompt for a string of characters. Their
  history is still available through all the standard ways of retrieving
  minibuffer history, such as with the command
  `previous-history-element'.

  History completion still allows arbitrary values to be provided as
  input: they do not have to match the available minibuffer completion
  candidates.

  Note that some prompts, like `denote-keywords-prompt', always use
  minibuffer completion, due to the specifics of their data.

  [ Consider enabling the built-in `savehist-mode' to persist minibuffer
    histories between sessions.]


3.1.3 The `denote-templates' option
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The user option `denote-templates' is an alist of content templates
  for new notes.  A template is arbitrary text that Denote will add to a
  newly created note right below the front matter.

  Templates are expressed as a `(KEY . VALUE)' association.

  • The `KEY' is the name which identifies the template.  It is an
    arbitrary symbol, such as `report', `memo', `statement'.

  • The `VALUE' is either a string or the symbol of a function.

    • If it is a string, it is ordinary text that Denote will insert
      as-is.  It can contain newline characters to add spacing.  The
      manual of Denote contains examples on how to use the `concat'
      function, beside writing a generic string.

    • If it is a function, it is called without arguments and is
      expected to return a string.  Denote will call the function and
      insert the result in the buffer.

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

  For when the `VALUE' is a function, we have this:

  ┌────
  │ (setq denote-templates
  │       `((report . "* Some heading\n\n* Another heading")
  │ 	(blog . my-denote-template-function-for-blog) ; a function to return a string
  │ 	(memo . ,(concat "* Some heading"
  │ 			 "\n\n"
  │ 			 "* Another heading"
  │ 			 "\n\n"))))
  └────

  In this example, `my-denote-template-function-for-blog' is a function
  that returns a string. Denote will take care to insert it in the
  buffer.

  DEV NOTE: We do not provide more examples at this point, though feel
  welcome to ask for help if the information provided herein is not
  sufficient.  We shall expand the manual accordingly.


[The denote-prompts option] See section 3.1.1

[Convenience commands for note creation] See section 3.1.4


3.1.4 Convenience commands for note creation
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Sometimes the user needs to create a note that has different
  requirements from those of `denote' ([Standard note creation]).  While
  this can be achieved globally by changing the `denote-prompts' user
  option, there are cases where an ad-hoc method is the appropriate one
  ([The denote-prompts option]).

  To this end, Denote provides the following interactive convenience
  commands for note creation. They all work by appending a new prompt to
  the existing `denote-prompts'.

  Create note by specifying file type
        The `denote-type' command creates a note while prompting for a
        file type.

        This is the equivalent of calling `denote' when `denote-prompts'
        has the `file-type' prompt appended to its existing prompts. In
        practical terms, this lets you produce, say, a note in Markdown
        even though you normally write in Org ([Standard note
        creation]).

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

        This is the equivalent of calling `denote' when `denote-prompts'
        has the `date' prompt appended to its existing prompts.

        The `denote-create-note-using-date' is an alias of
        `denote-date'.

  Create note in a specific directory
        The `denote-subdirectory' command creates a note while prompting
        for a subdirectory.  Available candidates include the value of
        the variable `denote-directory' and any subdirectory thereof
        (Denote does not create subdirectories).

        This is the equivalent of calling `denote' when `denote-prompts'
        has the `subdirectory' prompt appended to its existing prompts.

        The `denote-create-note-in-subdirectory' is a more descriptive
        alias of `denote-subdirectory'.

  Create note and add a template
        The `denote-template' command creates a new note and inserts the
        specified template below the front matter ([The denote-templates
        option]).  Available candidates for templates are specified in
        the user option `denote-templates'.

        This is the equivalent of calling `denote' when `denote-prompts'
        has the `template' prompt appended to its existing prompts.

        The `denote-create-note-with-template' is an alias of the
        command `denote-template', meant to help with discoverability.

  Create note with a signature
        The `denote-signature' command first prompts for an arbitrary
        string to use in the optional `SIGNATURE' field of the file name
        and then asks for a title and keywords.  Signatures are
        arbitrary strings of alphanumeric characters which can be used
        to establish sequential relations between file at the level of
        their file name (e.g. 1, 1a, 1b, 1b1, 1b2, …).

        This is the equivalent of calling `denote' when `denote-prompts'
        has the `signature' prompt appended to its existing prompts.

        The `denote-create-note-using-signature' is an alias of the
        command `denote-signature' intended to make the functionality
        more discoverable.


[Standard note creation] See section 3.1

[The denote-prompts option] See section 3.1.1

[The denote-date-prompt-use-org-read-date option] See section 3.1.7

[The denote-templates option] See section 3.1.3

◊ 3.1.4.1 Write your own convenience commands

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
  ([The denote-prompts option]). Use this paradigm to write your own
  variants which you can then assign to keys, invoke with `M-x', or add
  to the list of commands available at the `denote-command-prompt'
  ([Choose which commands to prompt for]).


  [Convenience commands for note creation] See section 3.1.4

  [The denote-templates option] See section 3.1.3

  [The denote-prompts option] See section 3.1.1

  [Choose which commands to prompt for] See section 8


3.1.5 The `denote-save-buffers' option
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The user option `denote-save-buffer-after-creation' controls whether
  commands that create new notes save their buffer outright.

  The default behaviour of commands such as `denote' (or related) is to
  not save the buffer they create ([Points of entry]). This gives the
  user the chance to review the text before writing it to a file. The
  user may choose to delete the unsaved buffer, thus not creating a new
  note ([The `denote-save-buffer-after-creation' option]).

  This option also applies to notes affected by the renaming commands
  (`denote-rename-file' and related).

  If this user option is set to a non-nil value, such buffers are saved
  automatically. The assumption is that the user who opts in to this
  feature is familiar with the `denote-rename-file' operation (or
  related) and knows it is reliable ([Renaming files]).

  [The `denote-kill-buffers' option].


[Points of entry] See section 3

[The `denote-save-buffer-after-creation' option] See section 3.1.5

[Renaming files] See section 4

[The `denote-kill-buffers' option] See section 3.1.6


3.1.6 The `denote-kill-buffers' option
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The user option `denote-kill-buffers' controls whether to kill a
  buffer that was generated by a Denote command. This can happen when
  creating a new file or renaming an existing one.

  • [Points of entry].
  • [Renaming files].

  The default behaviour of creation or renaming commands such as
  `denote' or `denote-rename-file' is to not kill the buffer they create
  or modify at the end of their operation. The idea is to give the user
  the chance to confirm that everything is in order.

  If this user option is nil (the default), buffers affected by a
  creation or renaming command are not automatically killed.

  If set to the symbol `on-creation', new notes are automatically
  killed.

  If set to the symbol `on-rename', renamed notes are automatically
  killed.

  If set to t, new and renamed notes are killed.

  If a buffer is killed, it is also saved, as if `denote-save-buffers'
  were t ([The `denote-save-buffers' option]).

  In all cases, if the buffer already existed before the Denote
  operation it is NOT automatically killed.


[Points of entry] See section 3

[Renaming files] See section 4

[The `denote-save-buffers' option] See section 3.1.5


3.1.7 The `denote-date-prompt-use-org-read-date' option
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  By default, Denote uses its own simple prompt for date or date+time
  input ([The denote-prompts option]).  This is done when the
  `denote-prompts' option includes a `date' symbol and/or when the user
  invokes the `denote-date' command.

  Users who want to benefit from the more advanced date selection method
  that is common in interactions with Org mode, can set the user option
  `denote-date-prompt-use-org-read-date' to a non-nil value.


[The denote-prompts option] See section 3.1.1


3.2 Create a note from the current Org subtree
──────────────────────────────────────────────

  In Org parlance, an entry with all its subheadings and other contents
  is a “subtree”. Denote can operate on the subtree to extract it from
  the current file and create a new file out of it. One such workflow is
  to collect thoughts in a single document and produce longer standalone
  notes out of them upon review.

  The command `denote-org-extras-extract-org-subtree' is used for this
  purpose. It creates a new Denote note using the current Org subtree.
  In doing so, it removes the subtree from its current file and moves
  its contents into a new file. This command is part of the optional
  `denote-org-extras.el' extension, which is part of the `denote'
  package. It is loaded automatically as soon as one of its commands is
  invoked.

  The text of the subtree’s heading becomes the `#+title' of the new
  note. Everything else is inserted as-is.

  If the heading has any tags, they are used as the keywords of the new
  note. If the Org file has any `#+filetags' they are taken as well
  (Org’s `#+filetags' are inherited by the headings). If none of these
  are true and the user option `denote-prompts' includes an entry for
  keywords, then `denote-org-extras-extract-org-subtree' prompts for
  keywords. Else the new note has no keywords ([Add or remove keywords
  interactively]).

  If the heading has a `PROPERTIES' drawer, it is retained for further
  review.

  If the heading’s `PROPERTIES' drawer includes a `DATE' or `CREATED'
  property, or there exists a `CLOSED' statement with a timestamp value,
  use that to derive the date (or date and time) of the new note (if
  there is only a date, the time is taken as 00:00). If more than one of
  these is present, the order of preference is `DATE', then `CREATED',
  then `CLOSED'. If none of these is present, the current time is used.
  If the `denote-prompts' includes an entry for a date, then the command
  prompts for a date at this stage (also see
  `denote-date-prompt-use-org-read-date').

  For the rest, it consults the value of the user option
  `denote-prompts' in the following scenaria:

  • To optionally prompt for a subdirectory, otherwise it produces the
    new note in the `denote-directory'.
  • To optionally prompt for a file signature, otherwise to not use any.

  The new note is an Org file regardless of the user option
  `denote-file-type'.


[Add or remove keywords interactively] See section 4.8


3.3 Create note using Org capture
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


3.4 Create note with specific prompts using Org capture
───────────────────────────────────────────────────────

  This section assumes knowledge of how Denote+org-capture work, as
  explained in the previous section ([Create note using Org capture]).

  The previous section shows how to define an Org capture template that
  always prompts for a title and keywords.  There are, however, cases
  where the user wants more control over what kind of input Denote will
  prompt for.  To this end, we provide the function
  `denote-org-capture-with-prompts'.  Below we explain it and then show
  some examples of how to use it.

  The `denote-org-capture-with-prompts' is like `denote-org-capture' but
  with optional prompt parameters.

  When called without arguments, it does not prompt for anything.  It
  just returns the front matter with title and keyword fields empty and
  the date and identifier fields specified.  It also makes the file name
  consist of only the identifier plus the Org file name extension.

  [The file-naming scheme].

  Otherwise, it produces a minibuffer prompt for every non-nil value
  that corresponds to the `TITLE', `KEYWORDS', `SUBDIRECTORY', `DATE',
  and `TEMPLATE' arguments.  The prompts are those used by the standard
  `denote' command and all of its utility commands.

  [Points of entry].

  When returning the contents that fill in the Org capture template, the
  sequence is as follows: front matter, `TEMPLATE', and then the value
  of the user option `denote-org-capture-specifiers'.

  Important note: in the case of `SUBDIRECTORY' actual subdirectories
  must exist—Denote does not create them.  Same principle for `TEMPLATE'
  as templates must exist and are specified in the user option
  `denote-templates'.

  This is how one can incorporate `denote-org-capture-with-prompts' in
  their Org capture templates.  Instead of passing a generic `t' which
  makes it hard to remember what the argument means, we use semantic
  keywords like `:title' for our convenience (internally this does not
  matter as the value still counts as non-nil, so `:foo' for `TITLE' is
  treated the same as `:title' or `t').

  ┌────
  │ ;; This prompts for TITLE, KEYWORDS, and SUBDIRECTORY
  │ (add-to-list 'org-capture-templates
  │ 	     '("N" "New note with prompts (with denote.el)" plain
  │ 	       (file denote-last-path)
  │ 	       (function
  │ 		(lambda ()
  │ 		  (denote-org-capture-with-prompts :title :keywords :subdirectory)))
  │ 	       :no-save t
  │ 	       :immediate-finish nil
  │ 	       :kill-buffer t
  │ 	       :jump-to-captured t))
  │ 
  │ ;; This prompts only for SUBDIRECTORY
  │ (add-to-list 'org-capture-templates
  │ 	     '("N" "New note with prompts (with denote.el)" plain
  │ 	       (file denote-last-path)
  │ 	       (function
  │ 		(lambda ()
  │ 		  (denote-org-capture-with-prompts nil nil :subdirectory)))
  │ 	       :no-save t
  │ 	       :immediate-finish nil
  │ 	       :kill-buffer t
  │ 	       :jump-to-captured t))
  │ 
  │ ;; This prompts for TITLE and SUBDIRECTORY
  │ (add-to-list 'org-capture-templates
  │ 	     '("N" "New note with prompts (with denote.el)" plain
  │ 	       (file denote-last-path)
  │ 	       (function
  │ 		(lambda ()
  │ 		  (denote-org-capture-with-prompts :title nil :subdirectory)))
  │ 	       :no-save t
  │ 	       :immediate-finish nil
  │ 	       :kill-buffer t
  │ 	       :jump-to-captured t))
  └────


[Create note using Org capture] See section 3.3

[The file-naming scheme] See section 5

[Points of entry] See section 3


3.5 Create a note with the region’s contents
────────────────────────────────────────────

  The command `denote-region' takes the contents of the active region
  and then calls the `denote' command.  Once a new note is created, it
  inserts the contents of the region therein.  This is useful to quickly
  elaborate on some snippet of text or capture it for future reference.

  When the `denote-region' command is called with an active region, it
  finalises its work by calling
  `denote-region-after-new-note-functions'.  This is an abnormal hook,
  meaning that the functions added to it are called with arguments.  The
  arguments are two, representing the beginning and end positions of the
  newly inserted text.

  A common use-case for Org mode users is to call the command
  `org-insert-structure-template' after a region is inserted.  Emacs
  will thus prompt for a structure template, such as the one
  corresponding to a source block.  In this case the function added to
  `denote-region-after-new-note-functions' does not actually need
  aforementioned arguments: it can simply declare those as ignored by
  prefixing the argument names with an underscore (an underscore is
  enough, but it is better to include a name for clarity).  For example,
  the following will prompt for a structure template as soon as
  `denote-region' is done:

  ┌────
  │ (defun my-denote-region-org-structure-template (_beg _end)
  │   (when (derived-mode-p 'org-mode)
  │     (activate-mark)
  │     (call-interactively 'org-insert-structure-template)))
  │ 
  │ (add-hook 'denote-region-after-new-note-functions #'my-denote-region-org-structure-template)
  └────

  Remember that `denote-region-after-new-note-functions' are not called
  if `denote-region' is used without an active region.


3.5.1 A custom `denote-region' that references the source
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The `denote-region' command simply creates a new note and includes the
  highlighted region’s contents as the initial text of the note ([Create
  a note with the region’s contents]).  However, users may want a more
  streamlined workflow where the command is always used to capture
  quotes from other sources. In this example, we consider “other
  sources” to come from Emacs EWW buffers (with `M-x eww') or regular
  files outside the `denote-directory'.

  [ This is a proof-of-concept that does not cover all cases. If anyone
    wants to use a variation of this, just let me know. ]

  ┌────
  │ ;; Variant of `my-denote-region' to reference the source
  │ 
  │ (defun my-denote-region-get-source-reference ()
  │   "Get a reference to the source for use with `my-denote-region'.
  │ The reference is a URL or an Org-formatted link to a file."
  │   ;; We use a `cond' here because we can extend it to cover move
  │   ;; cases.
  │   (cond
  │    ((derived-mode-p 'eww-mode)
  │     (plist-get eww-data :url))
  │    ;; Here we are just assuming an Org format.  We can make this more
  │    ;; involved, if needed.
  │    (buffer-file-name
  │     (format "[[file:%s][%s]]" buffer-file-name (buffer-name)))))
  │ 
  │ (defun my-denote-region ()
  │   "Like `denote-region', but add the context afterwards.
  │ For how the context is retrieved, see `my-denote-region-get-source-reference'."
  │   (interactive)
  │   (let ((context (my-denote-region-get-source-reference)))
  │     (call-interactively 'denote-region)
  │     (when context
  │       (goto-char (point-max))
  │       (insert "\n")
  │       (insert context))))
  │ 
  │ ;; Add quotes around snippets of text captured with `denote-region' or `my-denote-region'.
  │ 
  │ (defun my-denote-region-org-structure-template (beg end)
  │   "Automatically quote (with Org syntax) the contents of `denote-region'."
  │   (when (derived-mode-p 'org-mode)
  │     (goto-char end)
  │     (insert "#+end_quote\n")
  │     (goto-char beg)
  │     (insert "#+begin_quote\n")))
  │ 
  │ (add-hook 'denote-region-after-new-note-functions #'my-denote-region-org-structure-template)
  └────

  With the above in place, calling the `my-denote-region' command does
  the following:

  • It creates a new note as usual, prompting for the relevant data.
  • Inserts the contents of the region below the front matter of the new
    note.
  • Adds Org-style quotation block markers around the inserted region.
  • Adds a link to the URL or file from where `my-denote-region' was
    called.


[Create a note with the region’s contents] See section 3.5


3.6 Open an existing note or create it if missing
─────────────────────────────────────────────────

  Sometimes it is necessary to briefly interrupt the ongoing writing
  session to open an existing note or, if that is missing, to create it.
  This happens when a new tangential thought occurs and the user wants
  to confirm that an entry for it is in place.  To this end, Denote
  provides the command `denote-open-or-create' as well as its more
  flexible counterpart `denote-open-or-create-with-command'.

  The `denote-open-or-create' prompts to visit a file in the
  `denote-directory'.  At this point, the user must type in search terms
  that match a file name.  If the input does not return any matches and
  the user confirms their choice to proceed (usually by typing RET
  twice, depending on the minibuffer settings), `denote-open-or-create'
  will call the `denote' command interactively to create a new note.  It
  will then use whatever prompts `denote' normally has, per the user
  option `denote-prompts' ([Standard note creation]).  If the title
  prompt is involved (the default behaviour), the
  `denote-open-or-create' sets up this prompt to have the previous input
  as the default title of the note to-be-created.  This means that the
  user can type RET at the empty prompt to re-use what they typed in
  previously.  Commands to use previous inputs from the history are also
  available (`M-p' or `M-n' in the minibuffer, which call
  `previous-history-element' and `next-history-element' by default).
  Accessing the history is helpful to, for example, make further edits
  to the available text.

  The `denote-open-or-create-with-command' is like the above, except
  when it is about to create the new note it first prompts for the
  specific file-creating command to use ([Points of entry]).  For
  example, the user may want to specify a signature for this new file,
  so they can select the `denote-signature' command.

  Denote provides similar functionality for linking to an existing note
  or creating a new one ([Link to a note or create it if missing]).


[Standard note creation] See section 3.1

[Points of entry] See section 3

[Link to a note or create it if missing] See section 7.7


3.7 Maintain separate directory silos for notes
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
  │ ((nil . ((denote-directory . "/path/to/silo/"))))
  └────

  When inside the directory that contains this `.dir-locals.el' file,
  all Denote commands/functions for note creation, linking, the
  inference of available keywords, et cetera will use the silo as their
  point of reference ([How to switch a silo]). They will not read the
  global value of `denote-directory'. The global value of
  `denote-directory' is read everywhere else except the silos.

  [Use custom commands to select a silo].

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
  │ ((nil . ((denote-directory . "/path/to/silo/")
  │ 	 (denote-known-keywords . ("food" "drink")))))
  └────

  This one is like the above, but also disables `denote-infer-keywords':

  ┌────
  │ ;;; Directory Local Variables.  For more information evaluate:
  │ ;;;
  │ ;;;     (info "(emacs) Directory Variables")
  │ 
  │ ((nil . ((denote-directory . "/path/to/silo/")
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
  │ ((nil . ((denote-directory . "/path/to/silo/")
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


[How to switch a silo] See section 3.7.1

[Use custom commands to select a silo] See section 3.7.2

3.7.1 How to switch a silo
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Switching to a silo directory will make all Denote commands use the
  silo’s path as the `denote-directory', instead of the global value of
  that variable ([Maintain separate directory silos for notes]). There
  are three ways to switch to a silo:

  1. Visit a file inside of that directory.
  2. Use the `dired' command to open the directory in a buffer.
  3. Use the command `cd' to select the directory without moving away
     from the current buffer.


[Maintain separate directory silos for notes] See section 3.7


3.7.2 Use custom commands to select a silo
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  [ As part of version 2.1.0, the contents of this section are formally
    provided in the file `denote-silo-extras.el'.  We keep this here for
    existing users.  Otherwise consult the new entry in the manual ([The
    `denote-silo-extras.el']). ]

  We implement silos as directory-local values of the user option
  `denote-directory'.  This means that all Denote commands read from the
  local value if they are invoked from that context.  For example, if
  `~/Videos/recordings' is a silo and `~/Documents/notes' is the
  default/global value of `denote-directory' all Denote commands will
  read the video’s path when called from there (e.g. by using Emacs’
  `dired'); any other context reads the global value.

  [Maintain separate directory silos for notes].

  There are cases where the user (i) wants to maintain multiple silos
  and (ii) prefers an interactive way to switch between them without
  going through Dired.  Since this is specific to the user’s workflow,
  it is easier to have some custom code for it.  The following should be
  added to the user’s Denote configuration:

  ┌────
  │ (defvar my-denote-silo-directories
  │   `("/home/prot/Videos/recordings"
  │     "/home/prot/Documents/books"
  │     ;; You don't actually need to include the `denote-directory' here
  │     ;; if you use the regular commands in their global context.  I am
  │     ;; including it for completeness.
  │     ,denote-directory)
  │   "List of file paths pointing to my Denote silos.
  │   This is a list of strings.")
  │ 
  │ (defvar my-denote-commands-for-silos
  │   '(denote
  │     denote-date
  │     denote-subdirectory
  │     denote-template
  │     denote-type)
  │   "List of Denote commands to call after selecting a silo.
  │   This is a list of symbols that specify the note-creating
  │   interactive functions that Denote provides.")
  │ 
  │ (defun my-denote-pick-silo-then-command (silo command)
  │   "Select SILO and run Denote COMMAND in it.
  │   SILO is a file path from `my-denote-silo-directories', while
  │   COMMAND is one among `my-denote-commands-for-silos'."
  │   (interactive
  │    (list (completing-read "Select a silo: " my-denote-silo-directories nil t)
  │ 	 (intern (completing-read
  │ 		  "Run command in silo: "
  │ 		  my-denote-commands-for-silos nil t))))
  │   (let ((denote-directory silo))
  │     (call-interactively command)))
  └────

  With this in place, `M-x my-denote-pick-silo-then-command' will use
  minibuffer completion to select a silo among the predefined options
  and then ask for the command to run in that context.

  Note that `let' binding `denote-directory' can be used in custom
  commands and other wrapper functions to override the global default
  value of `denote-directory' to select silos.

  To see another example of a wrapper function that `let' binds
  `denote-directory', see:

  [Extending Denote: Split an Org subtree into its own note].


[The `denote-silo-extras.el'] See section 3.7.3

[Maintain separate directory silos for notes] See section 3.7

[Extending Denote: Split an Org subtree into its own note] See section
3.2


3.7.3 The `denote-silo-extras.el'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The `denote-silo-extras.el' provides optional convenience functions
  for working with silos ([Maintain separate directory silos for
  notes]).  Start by loading the relevant library:

  ┌────
  │ (require 'denote-silo-extras)
  └────

  The user option `denote-silo-extras-directories' specifies a list of
  directories that the user has set up as `denote-directory' silos.

  The command `denote-silo-extras-create-note' prompts for a directory
  among `denote-silo-extras-directories' and runs the `denote' command
  from there.

  Similar to the above, the command `denote-silo-extras-open-or-create'
  prompts for a directory among `denote-silo-extras-directories' and
  runs the `denote-open-or-create' command from there.

  The command `denote-silo-extras-select-silo-then-command' prompts with
  minibuffer completion for a directory among
  `denote-silo-extras-directories'.  Once the user selects a silo, a
  second prompt asks for a Denote note-creation command to call from
  inside that silo ([Points of entry]).


[Maintain separate directory silos for notes] See section 3.7

[Points of entry] See section 3


3.7.4 Make Org export work with silos
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The Org export infrastructure is designed to ignore directory-local
  variables. This means that Denote silos, which depend on setting the
  local value of the variable `denote-directory', do not work as
  intended ([Maintain separate directory silos for notes]). More
  specifically, the Denote links do not resolve to the right file,
  because their path is changed during the export process.

  I brought this to the attention of the Org maintainer. The guidance
  from their side is to use the `#+bind' keyword to specify a local
  value for the `denote-directory':
  <https://lists.gnu.org/archive/html/emacs-orgmode/2024-06/msg00206.html>.
  The prerequisite is to set `org-export-allow-bind-keywords' to a
  non-nil value:

  ┌────
  │ (setq org-export-allow-bind-keywords t)
  └────

  I do not think this is an elegant solution, but here are two possible
  ways to go about it, anyway:

  1. Manually add the `#+bind' keyword to each file you want to export.
     It has to be like this:

     ┌────
     │ #+bind: denote-directory "/path/to/silo/"
     └────

  2. Alternatively, you can make the Org front matter that Denote uses
     for new files automatically include the `#+bind' keyword with its
     desired value. Here is a complete `.dir-locals.el' which (i)
     defines the silo and (ii) modifies the `denote-org-front-matter'
     accordingly:

     ┌────
     │    ;;; Directory Local Variables.  For more information evaluate:
     │    ;;;
     │    ;;;     (info "(emacs) Directory Variables")
     │ 
     │    ((nil . ((denote-directory . "/path/to/silo/")
     │ 	    (denote-org-front-matter .
     │ 	     "#+title:      %s
     │ #+date:       %s
     │ #+filetags:   %s
     │ #+identifier: %s
     │ #+bind:       denote-directory \"/path/to/silo/\"
     │ \n"))))
     └────

     [ Note that if you are reading the Org source of this manual, you
       need to use the command `org-edit-special' on the above code
       blocks before copying the code. This is because Org automatically
       prepends a comma to disambiguate those entries from actual
       keywords of the current file. ]


[Maintain separate directory silos for notes] See section 3.7


3.7.5 Make any Denote command work in a silo from anywhere
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Denote silos are instantiated with a directory-local value for the
  `denote-directory' ([Maintain separate directory silos for
  notes]). This means that all Denote commands will operate on the silo
  when the user is inside of that directory ([How to switch a
  silo]). Sometimes though, the user may not want to switch to the silo,
  then call a Denote command, and finally switch away from the silo:
  this context change can be done only for the duration of a command.

  Here we show how easy it is to transiently bind the value of the
  `denote-directory' to the path of a silo (well, any path for that
  matter).

  ┌────
  │ (defun my-denote-journal-extras-new-or-existing-entry ()
  │   "Like `denote-journal-extras-new-or-existing-entry' for my silo."
  │   (interactive)
  │   (let ((denote-directory "/path/to/silo/"))
  │     (call-interactively 'denote-journal-extras-new-or-existing-entry)))
  └────

  All the user needs to do here is change the exact command that is
  passed to the `call-interactively'. We use an example from the
  journaling conveniences that we provide ([Keep a journal or diary]).

  With this in place, the user can now call their own command, such as
  the `my-denote-journal-extras-new-or-existing-entry' shown above, when
  they need to write a note there without manually switching to the
  silo. Of course, these commands can be assigned to key bindings for
  greater convenience. For example:

  ┌────
  │ (define-key global-map (kbd "C-c n j") #'my-denote-journal-extras-new-or-existing-entry)
  └────


[Maintain separate directory silos for notes] See section 3.7

[How to switch a silo] See section 3.7.1

[Keep a journal or diary] See section 13


3.8 Exclude certain files from file prompts
───────────────────────────────────────────

  The user option `denote-excluded-files-regexp' is a regular expression
  that matches files names which should be excluded from all Denote file
  prompts. Such prompts are present when linking to a file with one of
  the many commands, like `denote-link' ([Linking notes]), or when
  trying to open a file that may or may not exist ([Open an existing
  note or create it if missing]).

  Functions that check for files include `denote-directory-files' and
  `denote-file-prompt'.

  The match is performed with `string-match-p'.

  [For developers or advanced users].


[Linking notes] See section 7

[Open an existing note or create it if missing] See section 3.6

[For developers or advanced users] See section 18


3.9 Exclude certain directories from all operations
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


[Maintain separate directory silos for notes] See section 3.7

[For developers or advanced users] See section 18


3.10 Exclude certain keywords from being inferred
─────────────────────────────────────────────────

  The user option `denote-excluded-keywords-regexp' omits keywords that
  match a regular expression from the list of inferred keywords.

  Keywords are inferred from file names and provided at relevant prompts
  as completion candidates when the user option `denote-infer-keywords'
  is non-nil.

  The match is performed with `string-match-p'.


3.11 Use Denote commands from the menu bar or context menu
──────────────────────────────────────────────────────────

  Denote registers a submenu for the `menu-bar-mode'.  Users will find
  the entry called “Denote”.  From there they can use their pointer to
  select a command.  For a sample of how this looks, read the
  development log:
  <https://protesilaos.com/codelog/2023-03-31-emacs-denote-menu/>.

  The command `denote-menu-bar-mode' toggles the presentation of the
  menu. It is enabled by default.

  Emacs also provides support for operations through a context menu.
  This is typically the set of actions that are made available via a
  right mouse click.  Users who enable `context-menu-mode' can register
  the Denote entry for it by adding the following to their configuration
  file:

  ┌────
  │ (add-hook 'context-menu-functions #'denote-context-menu)
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
  but also for converting older text files to Denote notes.  Denote’s
  file-naming scheme is not specific to notes or text files: it is
  relevant for all sorts of items, such as multimedia and PDFs that form
  part of the user’s longer-term storage.  While Denote does not manage
  such files (e.g. doesn’t create links to them), it already has all the
  mechanisms to facilitate the task of renaming them.

  All renaming commands run the `denote-after-rename-file-hook' after a
  succesful operation. They also construct the file name in accordance
  with the user option `denote-file-name-components-order' ([Change the
  order of file name components]).

  Apart from renaming files, Denote can also rename only the buffer.
  The idea is that the underlying file name is correct but it can be
  easier to use shorter buffer names when displaying them on the mode
  line or switching between then with commands like `switch-to-buffer'.

  [Automatically rename Denote buffers].

  [Find duplicate identifiers and put them in a Dired buffer].


[The file-naming scheme] See section 5

[Linking notes] See section 7

[Change the order of file name components] See section 5.1

[Automatically rename Denote buffers] See section 10

[Find duplicate identifiers and put them in a Dired buffer] See section
4.10

4.1 Rename a single file
────────────────────────

  The `denote-rename-file' command renames a file and updates existing
  front matter if appropriate. It is possible to do the same with
  multiple files ([Rename multiple files interactively]).

  It always renames the file where it is located in the file system: it
  never moves it to another directory.

  If in Dired, it considers `FILE' to be the one at point, else it
  prompts with minibuffer completion for one. When called from Lisp,
  `FILE' is a file system path represented as a string.

  If `FILE' has a Denote-compliant identifier, it retains it while
  updating components of the file name referenced by the user option
  `denote-prompts' ([The `denote-prompts' option]). By default, these
  are the `TITLE' and `KEYWORDS'. The `SIGNATURE' is another one. When
  called from Lisp, `TITLE' and `SIGNATURE' are strings, while
  `KEYWORDS' is a list of strings.

  If there is no identifier, `denote-rename-file' creates an identifier
  based on the following conditions:

  1. If the `denote-prompts' includes an entry for date prompts, then it
     prompts for `DATE' and takes its input to produce a new
     identifier. For use in Lisp, `DATE' must conform with
     `denote-valid-date-p'.

  2. If `DATE' is nil (e.g. when `denote-prompts' does not include a
     date entry), it uses the file attributes to determine the last
     modified date of `FILE' and formats it as an identifier.

  3. As a fallback, it derives an identifier from the current date and
     time.

  4. At any rate, if the resulting identifier is not unique among the
     files in the variable `denote-directory', it increments it such
     that it becomes unique.

  In interactive use, and assuming `denote-prompts' includes a title
  entry, the `denote-rename-file' makes the `TITLE' prompt have
  prefilled text in the minibuffer that consists of the current title of
  `FILE'. The current title is either retrieved from the front matter
  (such as the `#+title' in Org) or from the file name.

  The command does the same for the `SIGNATURE' prompt, subject to
  `denote-prompts', by prefilling the minibuffer with the current
  signature of `FILE', if any.

  Same principle for the `KEYWORDS' prompt: it converts the keywords in
  the file name into a comma-separated string and prefills the
  minibuffer with it (the `KEYWORDS' prompt accepts more than one
  keywords, each separated by a comma, else the `crm-separator').

  For all prompts, the `denote-rename-file' interprets an empty input as
  an instruction to remove that file name component. For example, if a
  `TITLE' prompt is available and `FILE' is
  `20240211T093531--some-title__keyword1.org' then it renames `FILE' to
  `20240211T093531__keyword1.org'. If a file name component is present,
  but there is no entry for it in `denote-prompts', keep it as-is.

  [ NOTE: Please check with your minibuffer user interface how to
    provide an empty input. The Emacs default setup accepts the empty
    minibuffer contents as they are, though popular packages like
    `vertico' use the first available completion candidate instead. For
    `vertico', the user must either move one up to select the prompt and
    then type `RET' there with empty contents, or use the command
    `vertico-exit-input' with empty contents. That Vertico command is
    bound to `M-RET' as of this writing on 2024-02-13 08:08 +0200. ]

  When renaming `FILE', the command reads its file type extension (like
  `.org') and preserves it through the renaming process. Files that have
  no extension are left without one.

  As a final step, ask for confirmation, showing the difference between
  old and new file names.  Do not ask for confirmation if the user
  option `denote-rename-confirmations' does not contain the symbol
  `modify-file-name' ([The `denote-rename-confirmations' option]).

  If `FILE' has front matter for `TITLE' and `KEYWORDS', ask to rewrite
  their values in order to reflect the new input, unless
  `denote-rename-confirmations' lacks `rewrite-front-matter'. When the
  `denote-save-buffers' is nil (the default), do not save the underlying
  buffer, thus giving the user the option to double-check the result,
  such as by invoking the command `diff-buffer-with-file'. The rewrite
  of the `TITLE' and `KEYWORDS' in the front matter should not affect
  the rest of the front matter.

  If the file does not have front matter but is among the supported file
  types (per `denote-file-type'), add front matter to the top of it and
  leave the buffer unsaved for further inspection ([Front matter]). Save
  the buffer if `denote-save-buffers' is non-nil ([The
  `denote-save-buffers' option]).

  Construct the file name in accordance with the user option
  `denote-file-name-components-order' ([Change the order of file name
  components]).

  Run the `denote-after-rename-file-hook' after renaming `FILE'.

  This command is intended to (i) rename Denote files, (ii) convert
  existing supported file types to Denote notes, and (ii) rename
  non-note files (e.g. `PDF') that can benefit from Denote’s file-naming
  scheme.

  For a version of this command that works with multiple files
  one-by-one, use `denote-dired-rename-files' ([Rename multiple files
  interactively]).


[Rename multiple files interactively] See section 4.3

[The `denote-prompts' option] See section 3.1.1

[The `denote-rename-confirmations' option] See section 4.1.1

[Front matter] See section 6

[The `denote-save-buffers' option] See section 3.1.5

[Change the order of file name components] See section 5.1

4.1.1 The `denote-rename-confirmations' option
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The user option `denote-rename-confirmations' controls what kind of
  confirmation renaming commands ask for ([Renaming files]).  Its value
  is a list of symbols.

  The value is either nil, in which case no confirmation is ever
  requested, or a list of symbols among the following:

  • `modify-file-name' means that renaming commands will ask for
    confirmation before modifying the file name.

  • `rewrite-front-matter' means that renaming commands will ask for
    confirmation before rewritting the front matter.

  • `add-front-matter' means that renaming commands will ask for
    confirmation before adding new front matter to the file.

  The default behaviour of the `denote-rename-file' command (and others
  like it) is to ask for an affirmative answer as a final step before
  changing the file name and, where relevant, inserting or updating the
  corresponding front matter.

  Specialized commands that build on top of `denote-rename-file' (or
  related) may internally bind this user option to a non-nil value in
  order to perform their operation (e.g. `denote-dired-rename-files'
  goes through each marked Dired file, prompting for the information to
  use, but carries out the renaming without asking for confirmation
  ([Rename multiple files interactively])).


[Renaming files] See section 4

[Rename multiple files interactively] See section 4.3


4.2 Rename a single file based on its front matter
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

  At this stage, the file name still shows the old title and keywords.
  You now invoke `denote-rename-file-using-front-matter' and it updates
  the file name to:

  ┌────
  │ 20220805T131044--my-modified-sample-note-file__testing_denote_emacs.org
  └────


  By default, the renaming is subject to a “yes or no” prompt that shows
  the old and new names, just so the user is certain about the change.
  Though this can be modified ([The `denote-rename-confirmations'
  option]).

  The identifier of the file, if any, is never modified even if it is
  edited in the front matter: Denote considers the file name to be the
  source of truth in this case, to avoid potential breakage with typos
  and the like.

  This command constructs the file name in accordance with the user
  option `denote-file-name-components-order' ([Change the order of file
  name components]).


[Rename a single file] See section 4.1

[Front matter] See section 6

[The `denote-rename-confirmations' option] See section 4.1.1

[Change the order of file name components] See section 5.1


4.3 Rename multiple files interactively
───────────────────────────────────────

  The command `denote-dired-rename-files' (alias
  `denote-dired-rename-marked-files') renames the files that are marked
  in a Dired buffer. Its behaviour is similar to the
  `denote-rename-file' in that it prompts for a title, keywords, and
  signature ([Rename a single file]). It does so over each marked file,
  renaming one after the other.

  Unlike `denote-rename-file', the command `denote-dired-rename-files'
  does not ask to confirm the changes made to the files: it performs
  them outright (same as setting `denote-rename-confirmations' to a nil
  value). This is done to make it easier to rename multiple files
  without having to confirm each step. For an even more direct approach,
  check the command `denote-dired-rename-marked-files-with-keywords'.

  • [Rename by writing only keywords]
  • [Rename multiple files based on their front matter]


[Rename a single file] See section 4.1

[Rename by writing only keywords] See section 4.4

[Rename multiple files based on their front matter] See section 4.5


4.4 Rename multiple files at once by asking only for keywords
─────────────────────────────────────────────────────────────

  The `denote-dired-rename-marked-files-with-keywords' command renames
  marked files in Dired to conform with our file-naming scheme. It does
  so by writing keywords to them. Specifically, it does the following:

  • retains the file’s existing name and makes it the `TITLE' field, per
    Denote’s file-naming scheme;

  • sluggifies the `TITLE' and adjusts its letter casing, according to
    our conventions;

  • prepends an identifier to the `TITLE', if one is missing;

  • preserves the file’s extension, if any;

  • prompts once for `KEYWORDS' and applies the user’s input to the
    corresponding field in the file name, rewriting any keywords that
    may exist while removing keywords that do exist if `KEYWORDS' is
    empty;

  • adds or rewrites existing front matter to the underlying file, if it
    is recognized as a Denote note (per the `denote-file-type' user
    option), such that it includes the new keywords.

  [ Note that the affected buffers are not saved, unless the user option
    `denote-rename-no-confirm' is non-nil. Users can thus check them to
    confirm that the new front matter does not cause any problems (e.g.
    with the `diff-buffer-with-file' command). Multiple buffers can be
    saved in one go with the command `save-some-buffers' (read its doc
    string). ]

  Construct the file name in accordance with the user option
  `denote-file-name-components-order' ([Change the order of file name
  components]).

  Run the `denote-after-rename-file-hook' after the renaming is done.

  For more specialized versions of this command that only add or remove
  keywords, use `denote-dired-rename-marked-files-add-keywords' and
  `denote-dired-rename-marked-files-remove-keywords', respectively.


[Change the order of file name components] See section 5.1


4.5 Rename multiple files based on their front matter
─────────────────────────────────────────────────────

  As already noted, Denote can rename a file based on the data in its
  front matter ([Rename a single file based on its front matter]).  The
  command `denote-dired-rename-marked-files-using-front-matter' extends
  this principle to a batch operation which applies to all marked files
  in Dired.

  Marked files must count as notes for the purposes of Denote, which
  means that they at least have an identifier in their file name and use
  a supported file type, per `denote-file-type'. Files that do not meet
  this criterion are ignored, because Denote cannot know if they have
  front matter and what that may be. For such files, it is still
  possible to rename them interactively ([Rename multiple files
  interactively]).


[Rename a single file based on its front matter] See section 4.2

[Rename multiple files interactively] See section 4.3


4.6 Rename a file by changing only its file type
────────────────────────────────────────────────

  The command `denote-change-file-type-and-front-matter' provides the
  convenience of converting a note taken in one file type, say, `.txt'
  into another like `.org'. It presents a choice among the
  `denote-file-type' options.

  The conversion does NOT modify the existing front matter.  Instead, it
  prepends new front matter to the top of the file.  We do this as a
  safety precaution since the user can, in principle, add arbitrary
  extras to their front matter that we would not want to touch.

  If in Dired, `denote-change-file-type-and-front-matter' operates on
  the file at point, else the current file, else it prompts with
  minibuffer completion for one.

  The title of the file is retrieved from a line starting with a title
  field in the file’s front matter, depending on the previous file type
  (e.g.  `#+title' for Org).  The same process applies for keywords.

  As a final step, the command asks for confirmation, showing the
  difference between old and new file names.

  This command constructs the file name in accordance with the user
  option `denote-file-name-components-order' ([Change the order of file
  name components]).


[Change the order of file name components] See section 5.1


4.7 Rename a file by adding or removing a title interactively
─────────────────────────────────────────────────────────────

  The command `denote-rename-file-title' streamlines the process of
  interactively adding or removing a title to/from a file, while
  changing its file name accordingly. It asks for a title using the
  familiar minibuffer prompt ([Standard note creation]). It then renames
  the file. The command respect the values of
  `denote-rename-confirmations' and `denote-save-buffers':

  • [The `denote-rename-confirmations' option].
  • [The `denote-save-buffers' option].

  Technically, `denote-rename-file-title' is a wrapper for
  `denote-rename-file', doing all the things that does ([Rename a single
  file]).

  Concretely, this command can add or remove a title in one go. It does
  it by prepopulating the minibuffer prompt with the existing
  title. Users can then modify it. An empty input means to remove the
  title altogether ([The file-naming scheme]).

  [ NOTE: Please check with your minibuffer user interface how to
    provide an empty input. The Emacs default setup accepts the empty
    minibuffer contents as they are, though popular packages like
    `vertico' use the first available completion candidate instead. For
    `vertico', the user must either move one up to select the prompt and
    then type `RET' there with empty contents, or use the command
    `vertico-exit-input' with empty contents. That Vertico command is
    bound to `M-RET' as of this writing on 2024-06-30 10:37 +0300. ]


[Standard note creation] See section 3.1

[The `denote-rename-confirmations' option] See section 4.1.1

[The `denote-save-buffers' option] See section 3.1.5

[Rename a single file] See section 4.1

[The file-naming scheme] See section 5


4.8 Rename a file by adding or removing keywords interactively
──────────────────────────────────────────────────────────────

  The command `denote-rename-file-keywords' streamlines the process of
  interactively adding or removing keywords to a file, while changing
  its file name and front matter accordingly. It asks for keywords using
  the familiar minibuffer prompt ([Standard note creation]). It then
  renames the file ([Rename a single file based on its front matter]).
  The command respect the values of `denote-rename-confirmations' and
  `denote-save-buffers':

  • [The `denote-rename-confirmations' option].
  • [The `denote-save-buffers' option].

  Technically, `denote-rename-file-keywords' is a wrapper for
  `denote-rename-file', doing all the things that does ([Rename a single
  file]).

  Concretely, this command can add or remove keywords in one go. It does
  it by prepopulating the minibuffer prompt with the existing keywords.
  Users can then use the `crm-separator' (normally a comma), to write
  new keywords or edit what is in the prompt to rewrite them
  accordingly. An empty input means to remove all keywords ([The
  file-naming scheme]).

  [ NOTE: Please check with your minibuffer user interface how to
    provide an empty input. The Emacs default setup accepts the empty
    minibuffer contents as they are, though popular packages like
    `vertico' use the first available completion candidate instead. For
    `vertico', the user must either move one up to select the prompt and
    then type `RET' there with empty contents, or use the command
    `vertico-exit-input' with empty contents. That Vertico command is
    bound to `M-RET' as of this writing on 2024-06-30 10:37 +0300. ]


[Standard note creation] See section 3.1

[Rename a single file based on its front matter] See section 4.2

[The `denote-rename-confirmations' option] See section 4.1.1

[The `denote-save-buffers' option] See section 3.1.5

[Rename a single file] See section 4.1

[The file-naming scheme] See section 5


4.9 Rename a file by adding or removing a signature interactively
─────────────────────────────────────────────────────────────────

  The command `denote-rename-file-signature' streamlines the process of
  interactively adding or removing a signature to/from a file, while
  changing its file name accordingly. It asks for a signature using the
  familiar minibuffer prompt ([Standard note creation]). It then renames
  the file. The command respect the values of
  `denote-rename-confirmations' and `denote-save-buffers':

  • [The `denote-rename-confirmations' option].
  • [The `denote-save-buffers' option].

  Technically, `denote-rename-file-signature' is a wrapper for
  `denote-rename-file', doing all the things that does ([Rename a single
  file]).

  Concretely, this command can add or remove a signature in one go. It
  does it by prepopulating the minibuffer prompt with the existing
  signature. Users can then modify it. An empty input means to remove
  the signature altogether ([The file-naming scheme]).

  [ NOTE: Please check with your minibuffer user interface how to
    provide an empty input. The Emacs default setup accepts the empty
    minibuffer contents as they are, though popular packages like
    `vertico' use the first available completion candidate instead. For
    `vertico', the user must either move one up to select the prompt and
    then type `RET' there with empty contents, or use the command
    `vertico-exit-input' with empty contents. That Vertico command is
    bound to `M-RET' as of this writing on 2024-06-30 10:37 +0300. ]


[Standard note creation] See section 3.1

[The `denote-rename-confirmations' option] See section 4.1.1

[The `denote-save-buffers' option] See section 3.1.5

[Rename a single file] See section 4.1

[The file-naming scheme] See section 5


4.10 Find duplicate identifiers and put them in a Dired buffer
──────────────────────────────────────────────────────────────

  Denote takes care to create unique identifiers, though its mechanism
  relies on reading the existing identifiers in the `denote-directory'
  or the current directory. When we are renaming files across different
  directories, there is a small chance that some files have the same
  attributes and are thus assigned identical identifiers. If those files
  ever make it into a consolidated `denote-directory', we will have
  duplicates, which break the linking mechanism.

  As this is an edge case, we do not include any code to address it in
  the Denote code base. Though here is a way to find duplicate
  identifiers inside the current directory:

  ┌────
  │ (defun my-denote--get-files-in-dir (directory)
  │   "Return file names in DIRECTORY."
  │   (directory-files directory :full-paths directory-files-no-dot-files-regexp))
  │ 
  │ (defun my-denote--same-identifier-p (file1 file2)
  │   "Return non-nil if FILE1 and FILE2 have the same identifier."
  │   (let ((id1 (denote-retrieve-filename-identifier file1))
  │ 	(id2 (denote-retrieve-filename-identifier file2)))
  │     (equal id1 id2)))
  │ 
  │ (defun my-denote-find-duplicate-identifiers (directory)
  │   "Find all files in DIRECTORY that need a new identifier."
  │   (let* ((ids (my-denote--get-files-in-dir directory))
  │ 	 (unique-ids (seq-uniq ids #'my-denote--same-identifier-p)))
  │     (seq-difference ids unique-ids #'equal)))
  │ 
  │ (defun my-denote-dired-show-duplicate-identifiers (directory)
  │   "Put duplicate identifiers from DIRECTORY in a dedicated Dired buffer."
  │   (interactive
  │    (list
  │     (read-directory-name "Select DIRECTORY to check for duplicate identifiers: " default-directory)))
  │   (if-let ((duplicates (my-denote-find-duplicate-identifiers directory)))
  │       (dired (cons (format "Denote duplicate identifiers" directory) duplicates))
  │     (message "No duplicates identifiers in `%s'" directory)))
  └────

  Evaluate this code and then call the command
  `my-denote-dired-show-duplicate-identifiers'.  If there are
  duplicates, it will put them in a dedicated Dired buffer.  From there,
  you can view the file contents as usual, and manually edit the
  identifiers as you see fit (e.g. edit them one by one, or change to
  the writable Dired and record a keyboard macro that makes use of a
  counter to increment by 1—contact me if you need any help).


4.11 Faces used by rename commands
──────────────────────────────────

  These are the faces used by the various Denote rename commands to
  style or highlight the old/new/current file shown in the relevant
  minibuffer prompts:

  • `denote-faces-prompt-current-name'
  • `denote-faces-prompt-new-name'
  • `denote-faces-prompt-old-name'


5 The file-naming scheme
════════════════════════

  Notes are stored in the `denote-directory'.  The default path is
  `~/Documents/notes'.  The `denote-directory' can be a flat listing,
  meaning that it has no subdirectories, or it can be a directory tree.
  Either way, Denote takes care to only consider “notes” as valid
  candidates in the relevant operations and will omit other files or
  directories.

  Every note produced by Denote follows this pattern by default ([Points
  of entry]):

  ┌────
  │ DATE==SIGNATURE--TITLE__KEYWORDS.EXTENSION
  └────


  The `DATE' field represents the date in year-month-day format followed
  by the capital letter `T' (for “time”) and the current time in
  hour-minute-second notation.  The presentation is compact:
  `20220531T091625'.  The `DATE' serves as the unique identifier of each
  note and, as such, is also known as the file’s ID or identifier.

  File names can include a string of alphanumeric characters in the
  `SIGNATURE' field. Signatures have no clearly defined purpose and are
  up to the user to define. One use-case is to use them to establish
  sequential relations between files (e.g. 1, 1a, 1b, 1b1, 1b2, …).

  Signatures are an optional extension to Denote’s file-naming scheme.
  They can be added to newly created files on demand, with the command
  `denote-signature', or by modifying the value of the user option
  `denote-prompts'.

  The `TITLE' field is the title of the note, as provided by the user.
  It automatically gets downcased by default and is also hyphenated
  ([Sluggification of file name components]).  An entry about “Economics
  in the Euro Area” produces an `economics-in-the-euro-area' string for
  the `TITLE' of the file name.

  The `KEYWORDS' field consists of one or more entries demarcated by an
  underscore (the separator is inserted automatically).  Each keyword is
  a string provided by the user at the relevant prompt which broadly
  describes the contents of the entry.

  Each of the keywords is a single word, with multiple keywords
  providing the multi-dimensionality needed for advanced searches
  through Denote files.  Users who need to compose a keyword out of
  multiple words such as camelCase/CamelCase and are encouraged to use
  the `denote-file-name-slug-functions' user option accordingly
  ([Sluggification of file name components]).

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

  The `denote-prompts' can be configured in such ways to yield the
  following file name permutations:

  ┌────
  │ DATE.EXT
  │ DATE--TITLE.EXT
  │ DATE__KEYWORDS.EXT
  │ DATE==SIGNATURE.EXT
  │ DATE==SIGNATURE--TITLE.EXT
  │ DATE==SIGNATURE--TITLE__KEYWORDS.EXT
  │ DATE==SIGNATURE__KEYWORDS.EXT
  └────


  When in doubt, stick to the default design, which is carefully
  considered and works well ([Change the order of file name
  components]).

  While Denote is an Emacs package, notes should work long-term and not
  depend on the functionality of a specific program.  The file-naming
  scheme we apply guarantees that a listing is readable in a variety of
  contexts.  The Denote file-naming scheme is, in essence, an effective,
  low-tech invention.


[Points of entry] See section 3

[Sluggification of file name components] See section 5.2

[Features of the file-naming scheme for searching or filtering] See
section 5.4

[Change the order of file name components] See section 5.1

5.1 Change the order of file name components
────────────────────────────────────────────

  Our standard file-naming scheme prescribes a specific order for the
  file name components ([The file-naming scheme]). Though we provide the
  user option `denote-file-name-components-order' to let the user
  reorder them as they see fit.

  The value of this user option is a list of the following symbols:

  • `identifier': This is the combination of the date and time. When it
    is the first on the list, it looks like `20240519T073456' and does
    not have a component separator of its own due its unambiguous
    format. When it is placed anywhere else in the file name, it is
    prefixed with `@@', so it looks like `@@20240519T073456'.

  • `signature': This is an arbitrary string that can be used to qualify
    the file in some way, according to the user’s methodology (e.g. to
    add a sequence to notes). The string is always prefixed with the
    `==' to remain unambiguous.

  • `title': This is an arbitrary string which describes the file. It is
    always prefixed with `--' to be unambiguous.

  • `keywords': This is a series of one or more words that succinctly
    group the file. Multiple keywords are separated by an underscore
    prefixed to each of them. The file name component is always prefixed
    with `__'.

  All four symbols must appear exactly once. Duplicates are ignored. Any
  missing symbol is added automatically.

  Some examples:

  ┌────
  │ (setq denote-file-name-components-order '(identifier signature title keywords))
  │ ;; => 20240519T07345==hello--this-is-the-title__denote_testing.org
  │ 
  │ (setq denote-file-name-components-order '(signature identifier title keywords))
  │ ;; => ==hello@@20240519T07345--this-is-the-title__denote_testing.org
  │ 
  │ (setq denote-file-name-components-order '(title signature identifier keywords))
  │ ;; => --this-is-the-title==hello@@20240519T07345__denote_testing.org
  │ 
  │ (setq denote-file-name-components-order '(keywords title signature identifier))
  │ ;; => __denote_testing--this-is-the-title==hello@@20240519T07345.org
  └────

  Also see how to configure the Denote prompts, which affect which
  components are actually used in the order specified herein ([The
  `denote-prompts' option]).

  Before deciding on this, please consider the longer-term implications
  of file names with varying patterns. Consistency makes things
  predictable and thus easier to find. So pick one order and never touch
  it again. When in doubt, leave the default file-naming scheme as-is.


[The file-naming scheme] See section 5

[The `denote-prompts' option] See section 3.1.1


5.2 Sluggification of file name components
──────────────────────────────────────────

  Files names can contain any character that the file system
  permits. Denote imposes a few additional restrictions:

  ⁃ The tokens “`=", =__' and `--' are interpreted by Denote and should
    appear only once.

  ⁃ The dot character is not allowed in a note’s file name, except to
    indicate the file type extension. Denote recognises two extensions
    for encrypted files, like `.txt.gpg'.

  By default, Denote enforces other rules to file names through the user
  option `denote-file-name-slug-functions'. These rules are applied to
  file names by default:

  ⁃ What we count as “illegal characters” are removed.  The constant
    `denote-excluded-punctuation-regexp' holds the relevant value.

  ⁃ Input for a file title is hyphenated.  The original value is
    preserved in the note’s contents ([Front matter]).

  ⁃ Spaces or other delimiters are removed from keywords, meaning that
    `hello-world' becomes `helloworld'.  This is because hyphens in
    keywords do not work everywhere, such as in Org. Plus, hyphens are
    word separators in the title and we want to keep distinct separators
    for each component to make search easier and semantic ([Features of
    the file-naming scheme for searching or filtering]).

  ⁃ Signatures are like the above, but use the equals sign instead of
    hyphens as a word separator.

  ⁃ All file name components are downcased. Further down we document how
    to deviate from these rules, such as to accept input of the form
    `helloWorld' or `HelloWorld' verbatim.

  Denote imposes these restrictions to enforce uniformity, which is
  helpful long-term as it keeps all files with the same predictable
  pattern. Too many permutations make searches more difficult to express
  accurately and be confident that the matches cover all files.
  Nevertheless, one of the principles of Denote is its flexibility or
  hackability and so users can deviate from the aforementioned
  ([User-defined sluggification of file name components]).


[Front matter] See section 6

[Features of the file-naming scheme for searching or filtering] See
section 5.4

[User-defined sluggification of file name components] See section 5.3


5.3 User-defined sluggification of file name components
───────────────────────────────────────────────────────

  The user option `denote-file-name-slug-functions' controls the
  sluggification of file name components ([Sluggification of file name
  components]).  The default method is outlined above and in the
  previous section ([The file-naming scheme]).

  The value of this user option is an alist where each element is a cons
  cell of the form `(COMPONENT . METHOD)'. For example, here is the
  default value:

  ┌────
  │ '((title . denote-sluggify-title)
  │   (signature . denote-sluggify-signature)
  │   (keyword . denote-sluggify-keyword))
  └────

  • The `COMPONENT' is an unquoted symbol among `title', `signature',
    `keyword', which refers to the corresponding component of the file
    name.

  • The `METHOD' is a function to format the given component. This
    function must take a string as its parameter and return the string
    formatted for the file name. Note that even in the case of the
    `keyword' component, the function receives one string representing a
    single keyword and returns it formatted for the file name. Joining
    the keywords together is handled internally by Denote.

  One commonly requested deviation from the sluggification rules is to
  not sluggify individual keywords, such that the user’s input is taken
  as-is. This can be done as follows:

  ┌────
  │ (setq denote-file-name-slug-functions
  │       '((title . denote-sluggify-title)
  │ 	(keyword . identity)
  │ 	(signature . denote-sluggify-signature)))
  └────

  The `identity' function simply returns the string it receives, thus
  not altering it in any way.

  Another approach is to keep the sluggification but not downcase the
  string. We can do this by modifying the original functions used by
  Denote. For example, we have this:

  ┌────
  │ ;; The original function for reference
  │ (defun denote-sluggify-title (str)
  │   "Make STR an appropriate slug for title."
  │   (downcase (denote--slug-hyphenate (denote--slug-no-punct str))))
  │ 
  │ ;; Our variant of the above, which does the same thing except from
  │ ;; downcasing the string.
  │ (defun my-denote-sluggify-title (str)
  │   "Make STR an appropriate slug for title."
  │   (denote--slug-hyphenate (denote--slug-no-punct str)))
  │ 
  │ ;; Now we use our function to sluggify titles without affecting their
  │ ;; letter casing.
  │ (setq denote-file-name-slug-functions
  │       '((title . my-denote-sluggify-title) ; our function here
  │ 	(signature . denote-sluggify-signature)
  │ 	(keyword . denote-sluggify-keyword)))
  └────

  Follow this principle for all the sluggification functions ([Custom
  sluggification to remove non-ASCII characters]).

  To access the source code, use either of the following built-in
  methods:

  1. Call the command `find-library' and search for `denote'. Then
     navigate to the symbol you are searching for.

  2. Invoke the command `describe-symbol', search for the symbol you are
     interested in, and from the resulting Help buffer either click on
     the first link or do `M-x help-view-source' (bound to `s' in Help
     buffers, by default).

  Remember that deviating from the default file-naming scheme of Denote
  will make things harder to use in the future, as files can/will have
  permutations that create uncertainty. The sluggification scheme and
  concomitant restrictions we impose by default are there for a very
  good reason: they are the distillation of years of experience. Here we
  give you what you wish, but bear in mind it may not be what you need.
  You have been warned.


[Sluggification of file name components] See section 5.2

[The file-naming scheme] See section 5

[Custom sluggification to remove non-ASCII characters] See section 5.3.1

5.3.1 Custom sluggification to remove non-ASCII characters
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  A common use-case for Denote is to rename files such as videos
  downloaded from the Internet. Sometimes, those files have Unicode
  characters that (i) not all fonts support and (ii) create all sorts of
  problems with pattern matching, such as when searching through file
  names.

  By default, Denote does not remove Unicode characters because users
  may actually want them (e.g. Latin characters with accents). Those who
  do, however, wish to keep everything limited to the ASCII range can
  use the following in their Emacs configuration ([User-defined
  sluggification of file name components]).

  ┌────
  │ ;; These are the same as the default Denote sluggification functions,
  │ ;; except they remove all non-ASCII characters.
  │ (defun my-denote-sluggify-title (str)
  │   (downcase
  │    (denote--slug-hyphenate
  │     (denote--slug-no-punct
  │      (denote-slug-keep-only-ascii str)))))
  │ 
  │ (defun my-denote-sluggify-signature (str)
  │   (downcase
  │    (denote--slug-put-equals
  │     (denote--slug-no-punct-for-signature
  │      (denote-slug-keep-only-ascii str)
  │      "-+"))))
  │ 
  │ (defun my-denote-sluggify-keyword (str)
  │   (downcase
  │    (replace-regexp-in-string
  │     "-" ""
  │     (denote--slug-hyphenate
  │      (denote--slug-no-punct
  │       (denote-slug-keep-only-ascii str))))))
  │ 
  │ (defcustom denote-file-name-slug-functions
  │   '((title . my-denote-sluggify-title)
  │     (signature . my-denote-sluggify-signature)
  │     (keyword . my-denote-sluggify-keyword)))
  └────


[User-defined sluggification of file name components] See section 5.3


5.4 Features of the file-naming scheme for searching or filtering
─────────────────────────────────────────────────────────────────

  By default, file names have three fields and two sets of field
  delimiters between them:

  ┌────
  │ DATE--TITLE__KEYWORDS.EXTENSION
  └────


  When a signature is present, this becomes:

  ┌────
  │ DATE==SIGNATURE--TITLE__KEYWORDS.EXTENSION
  └────


  Field delimiters practically serve as anchors for easier searching.
  Consider this example:

  ┌────
  │ 20220621T062327==1a2--introduction-to-denote__denote_emacs.txt
  └────


  You will notice that there are two matches for the word `denote': one
  in the title field and another in the keywords’ field.  Because of the
  distinct field delimiters, if we search for `-denote' we only match
  the first instance while `_denote' targets the second one.  When
  sorting through your notes, this kind of specificity is invaluable—and
  you get it for free from the file names alone!  Similarly, a search
  for `=1' will show all notes that are related to each other by virtue
  of their signature.

  Users can get a lot of value out of this simple yet effective
  arrangement, even if they have no knowledge of regular expressions.
  One thing to consider, for maximum effect, is to avoid using
  multi-word keywords as those can get hyphenated like the title and
  will thus interfere with the above: either set the user option
  `denote-allow-multi-word-keywords' to nil or simply insert single
  words at the relevant prompts.


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

  All links target files which are Denote files. This means that they
  have our file-naming scheme. Files need to be inside the
  `denote-directory' or one of its subdirectories. No other file is
  recognised.

  The following sections delve into the details ([Why are some Org links
  opening outside Emacs?]).


[Why are some Org links opening outside Emacs?] See section 23.9

7.1 Adding a single link
────────────────────────

  The `denote-link' command inserts a link at point to a file specified
  at the minibuffer prompt. Links are formatted depending on the file
  type of the current note. In Org and plain text buffers, links are
  formatted thus: `[[denote:IDENTIFIER][DESCRIPTION]]'. While in
  Markdown they are expressed as `[DESCRIPTION](denote:IDENTIFIER)'.

  [ We optionally support links to Org headings ([The
    `denote-org-store-link-to-heading' user option]).  Other file types
    do not have the features of Org, so we cannot generalise this. ]

  When `denote-link' is called with a prefix argument (`C-u' by
  default), it formats links like `[[denote:IDENTIFIER]]', regardless of
  file type ([Fontify links in non-Org buffers]). The user might prefer
  its simplicity.

  By default, the description of the link is determined thus:

  • If the region is active, its text becomes the description of the
    link. In other words, the region text becomes the link.
  • If the region is active but has no text, the description is empty
    and so the link is formatted the same way as if using the `C-u'
    prefix argument.
  • If there is no region active, the description consists of the target
    file’s signature and title ([Insert link to file with
    signature]). The title is retrieved either from the front matter or
    the file name.
  • If the target file has no signature, the title is used.

  Links are created only for files which qualify as a “note” for our
  purposes ([Linking notes]). Users who need to link to Denote files
  from anywhere, can write a simple command to that effect:

  ┌────
  │ (defun my-denote-link-global (file file-type description &optional id-only)
  │   "Like the `denote-link', but works in any buffer.
  │ The FILE, FILE-TYPE, DESCRIPTION, and ID-ONLY have the same meaning as
  │ in `denote-link'."
  │   (interactive
  │    (let* ((file (denote-file-prompt nil "Link to FILE"))
  │ 	  (file-type (denote-filetype-heuristics buffer-file-name))
  │ 	  (description (when (file-exists-p file)
  │ 			 (denote--link-get-description file))))
  │      (list file file-type description current-prefix-arg)))
  │   (unless (file-exists-p file)
  │     (user-error "The linked file does not exists"))
  │   (let ((beg (point)))
  │     (denote--delete-active-region-content)
  │     (insert (denote-format-link file description file-type id-only))
  │     (unless (derived-mode-p 'org-mode)
  │       (make-button beg (point) 'type 'denote-link-button))))
  └────

  Links are styled with the `denote-faces-link' face, which looks
  exactly like an ordinary link by default.  This is just a convenience
  for the user/theme in case they want `denote:' links to remain
  distinct from other links.


[The `denote-org-store-link-to-heading' user option] See section 7.2

[Fontify links in non-Org buffers] See section 7.12

[Insert link to file with signature] See section 7.5

[Linking notes] See section 7


7.2 The `denote-org-store-link-to-heading' user option
──────────────────────────────────────────────────────

  The user option `denote-org-store-link-to-heading' determines whether
  `org-store-link' links to the current Org heading (such links are
  merely “stored” and need to be inserted afterwards with the command
  `org-insert-link'). Note that the `org-capture' command uses the
  `org-link' internally if it has to store a link.

  When its value is non-nil, `org-store-link' stores a link to the
  current Org heading inside the Denote Org file. If the heading does
  not have a `CUSTOM_ID', it creates it and includes it in the heading’s
  `PROPERTIES' drawer. If a `CUSTOM_ID' exists, `org-store-link' use it
  as-is.

  This makes the resulting link a combination of the `denote:' link
  type, pointing to the identifier of the current file, plus the value
  of the heading’s `CUSTOM_ID', such as:

  • `[[denote:20240118T060608][Some test]]'
  • `[[denote:20240118T060608::#h:eed0fb8e-4cc7-478f-acb6-f0aa1a8bffcd][Some
    test::Heading text]]'

  Both lead to the same Denote file, but the latter jumps to the heading
  with the given `CUSTOM_ID'. Notice that the link to the heading also
  has a different description, which includes the heading text.

  The value of the `CUSTOM_ID' is determined by the Org user option
  `org-id-method'. The sample shown above uses the default UUID
  infrastructure.

  If `denote-org-store-link-to-heading' is set to a nil value, the
  command `org-store-link' only stores links to the Denote file (using
  its identifier), but not to the given heading. This is what Denote was
  doing in versions prior to `2.3.0'.

  Note that the optional extension `denote-org-extras.el' defines the
  command `denote-org-extras-link-to-heading', which always links to a
  file+heading regardless of the aforementioned user option ([Insert
  link to an Org file with a further pointer to a heading]).

  [ This feature only works in Org mode files, as other file types do
    not have a linking mechanism that handles unique identifiers for
    headings or other patterns to jump to. If `org-store-link' is
    invoked in one such file, it captures only the Denote identifier of
    the file, even if this user option is set to a non-nil value. ]


[Insert link to an Org file with a further pointer to a heading] See
section 7.3


7.3 Insert link to an Org file with a further pointer to a heading
──────────────────────────────────────────────────────────────────

  As part of the optional `denote-org-extras.el' extension, the command
  `denote-org-extras-link-to-heading' prompts for a link to an Org file
  and then asks for a heading therein, using minibuffer completion. Once
  the user provides input at the two prompts, the command inserts a link
  at point which has the following pattern:
  `[[denote:IDENTIFIER::#ORG-HEADING-CUSTOM-ID]][Description::Heading
  text]]'.

  Because only Org files can have links to individual headings, the
  command `denote-org-extras-link-to-heading' prompts only for Org files
  (i.e. files which include the `.org' extension). Remember that Denote
  works with many file types ([The file-naming scheme]).

  This feature is similar to the concept of the user option
  `denote-org-store-link-to-heading' ([The
  `denote-org-store-link-to-heading' user option]). It is, however,
  interactive and differs in the directionality of the action. With that
  user option, the command `org-store-link' will generate a `CUSTOM_ID'
  for the current heading (or capture the value of one as-is), giving
  the user the option to then call `org-insert-link' wherever they see
  fit. By contrast, the command `denote-org-extras-link-to-heading'
  prompts for a file, then a heading, and inserts the link at point.

  Just as with files, it is possible to show backlinks for the given
  heading ([Backlinks for Org headings]).


[The file-naming scheme] See section 5

[The `denote-org-store-link-to-heading' user option] See section 7.2

[Backlinks for Org headings] See section 7.8.1


7.4 Insert links matching a regexp
──────────────────────────────────

  The command `denote-add-links' adds links at point matching a regular
  expression or plain string.  The links are inserted as a typographic
  list, such as:

  ┌────
  │ - link1
  │ - link2
  │ - link3
  └────

  Each link is formatted according to the file type of the current note,
  as explained further above about the `denote-link' command.  The
  current note is excluded from the matching entries (adding a link to
  itself is pointless).

  When called with a prefix argument (`C-u') `denote-add-links' will
  format all links as `[[denote:IDENTIFIER]]', hence a typographic list:

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


7.5 Insert link to file with signature
──────────────────────────────────────

  The command `denote-link-with-signature' prompts for a file among
  those that contain a `==SIGNATURE' and inserts a link to it.  The
  description of the link includes the text of the signature and that of
  the file’s title, if any.  For example, a link to the following file:

  ┌────
  │ 20230925T144303==abc--my-first-signature-note__denote_testing.txt
  └────


  will get this link: `[[denote:20230925T144303][abc My first signature
  note]]'.

  For more advanced uses, refer to the doc string of the `denote-link'
  function ([Adding a single link]).


[Adding a single link] See section 7.1


7.6 Insert links from marked files in Dired
───────────────────────────────────────────

  The command `denote-link-dired-marked-notes' is similar to
  `denote-add-links' in that it inserts in the buffer a typographic list
  of links to Denote notes ([Insert links matching a regexp]).  Though
  instead of reading a regular expression, it lets the user mark files
  in Dired and link to them.  This should be easier for users of all
  skill levels, instead of having to write a potentially complex regular
  expression.

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


[Insert links matching a regexp] See section 7.4

[Adding a single link] See section 7.1

[Linking notes] See section 7


7.7 Link to an existing note or create a new one
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
        produces for the new note ([The
        `denote-save-buffer-after-creation' option]).  This is a safety
        precaution to not write to disk unless the user wants it
        (e.g. the user may choose to kill the buffer, thus cancelling
        the creation of the note). However, for this command the
        creation of the note happens in the background and the user may
        miss the step of saving their buffer. We thus have to save the
        buffer in order to (i) establish valid links, and (ii) retrieve
        whatever front matter from the target file.

  `denote-link-after-creating-with-command'
        This command is like `denote-link-after-creating' except it
        prompts for a note-creating command ([Points of entry]).  Use
        this to, for example, call `denote-signature' so that the newly
        created note has a signature as part of its file name.  Optional
        `ID-ONLY' has the same meaning as in the command
        `denote-link-after-creating'.

  `denote-link-or-create'
        Use `denote-link' on `TARGET' file, creating it if necessary.

        If `TARGET' file does not exist, call
        `denote-link-after-creating' which runs the `denote' command
        interactively to create the file.  The established link will
        then be targeting that new file.

        If `TARGET' file does not exist, add the user input that was
        used to search for it to the history of the
        `denote-file-prompt'.  The user can then retrieve and possibly
        further edit their last input, using it as the newly created
        note’s actual title.  At the `denote-file-prompt' type `M-p'
        with the default key bindings, which calls
        `previous-history-element'.

        With optional `ID-ONLY' as a prefix argument create a link with
        just the file’s identifier.  This has the same meaning as in
        `denote-link'.

        This command has the alias
        `denote-link-to-existing-or-new-note', which helps with
        discoverability.

  `denote-link-or-create-with-command'
        This is like the above, except when it is about to create the
        new note it first prompts for the specific file-creating command
        to use ([Points of entry]). For example, the user may want to
        specify a signature for this new file, so they can select the
        `denote-signature' command.

  In all of the above, an optional prefix argument (`C-u' by default)
  creates a link that consists of just the identifier.  This has the
  same meaning as in the regular `denote-link' command.

  Denote provides similar functionality for opening an existing note or
  creating a new one ([Open an existing note or create it if missing]).


[Linking notes] See section 7

[Standard note creation] See section 3.1

[Adding a single link] See section 7.1

[The `denote-save-buffer-after-creation' option] See section 3.1.5

[Points of entry] See section 3

[Points of entry] See section 3

[Open an existing note or create it if missing] See section 3.6


7.8 The backlinks’ buffer
─────────────────────────

  The command `denote-backlinks' produces a bespoke buffer which
  displays backlinks to the current note.  A “backlink” is a link back
  to the present entry.

  By default, the backlinks’ buffer is designed to display the file name
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
  note occurs.  It also shows multiple occurrences, if present.  It
  looks like this (and has the appropriate fontification):

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

  The command `denote-backlinks-toggle-context' will toggle between the
  compact and detailed views inside of the current backlinks buffer.

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
  minibuffer completion interface with the `denote-find-backlink'
  command ([Visiting linked files via the minibuffer]).

  The placement of the backlinks’ buffer is subject to the user option
  `denote-backlinks-display-buffer-action'. Due to the nature of the
  underlying `display-buffer' mechanism, this inevitably is a relatively
  advanced feature. By default, the backlinks’ buffer is displayed below
  the current window. The doc string of our user option includes a
  sample configuration that places the buffer in a left side window
  instead. Reproducing it here for the sake of convenience:

  ┌────
  │ (setq denote-backlinks-display-buffer-action
  │       '((display-buffer-reuse-window
  │ 	 display-buffer-in-side-window)
  │ 	(side . left)
  │ 	(slot . 99)
  │ 	(window-width . 0.3)
  │ 	(dedicated . t)
  │ 	(preserve-size . (t . t))))
  └────


[Speed up backlinks’ buffer creation?] See section 23.10

[Why do I get “Search failed with status 1” when I search for
backlinks?] See section 23.11

[Visiting linked files via the minibuffer] See section 7.10

7.8.1 Backlinks for Org headings
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The optional `denote-org-extras.el' can generate Denote links to
  individual headings ([Insert link to an Org file with a further
  pointer to a heading]).  It is then possible to produce a
  corresponding backlinks buffer with the command
  `denote-org-extras-backlinks-for-heading'. The resulting buffer
  behaves the same way as the standard backlinks buffer we provide ([The
  backlinks’ buffer]). An Org dynamic block with backlinks to the
  current heading is also an option ([Org dynamic blocks to insert links
  or backlinks]).


[Insert link to an Org file with a further pointer to a heading] See
section 7.3

[The backlinks’ buffer] See section 7.8

[Org dynamic blocks to insert links or backlinks] See section 11.1


7.9 Writing metanotes
─────────────────────

  A “metanote” is an entry that describes other entries who have
  something in common.  Writing metanotes can be part of a workflow
  where the user periodically reviews their work in search of patterns
  and deeper insights.  For example, you might want to read your journal
  entries from the past year to reflect on your experiences, evolution
  as a person, and the like.

  The commands `denote-add-links', `denote-link-dired-marked-notes' are
  suited for this task.

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


[Insert links matching a regexp] See section 7.4

[Insert links from marked files in Dired] See section 7.6


7.10 Visiting linked files via the minibuffer
─────────────────────────────────────────────

  Denote has a major-mode-agnostic mechanism to collect all linked file
  references in the current buffer and return them as an appropriately
  formatted list.  This list can then be used in interactive commands.
  The `denote-find-link' is such a command.  It uses minibuffer
  completion to visit a file that is linked to from the current note.
  The candidates have the correct metadata, which is ideal for
  integration with other standards-compliant tools ([Extending Denote]).
  For instance, a package such as `marginalia' will display accurate
  annotations, while the `embark' package will be able to work its magic
  such as in exporting the list into a filtered Dired buffer (i.e. a
  familiar Dired listing with only the files of the current minibuffer
  session).

  To visit backlinks to the current note via the minibuffer, use
  `denote-find-backlink'.  This is an alternative to placing backlinks
  in a dedicated buffer ([The backlinks’ buffer]).


[Extending Denote] See section 15

[The backlinks’ buffer] See section 7.8


7.11 Convert `denote:' links to `file:' links
─────────────────────────────────────────────

  Sometimes the user needs to translate all `denote:' link types to
  their `file:' equivalent. This may be because some other tool does not
  recognise `denote:' links (or other custom links types—which are a
  standard feature of Org, by the way). The user thus needs to (i)
  either make a copy of their Denote note or edit the existing one, and
  (ii) convert all links to the generic `file:' link type that
  external/other programs understand.

  The optional extension `denote-org-extras.el' contains two commands
  that are relevant for this use-case:

  Convert `denote:' links to `file:' links
        The command `denote-org-extras-convert-links-to-file-type' goes
        through the buffer to find all `denote:' links. It gets the
        identifier of the link and resolves it to the actual file system
        path. It then replaces the match so that the link is written
        with the `file:' type and then the file system path. The
        optional search terms and/or link description are preserved
        ([Insert link to an Org file with a further pointer to a
        heading]).

  Convert `file:' links to `denote:' links
        The command `denote-org-extras-convert-links-to-denote-type'
        behaves like the one above. The difference is that it finds the
        file system path and converts it into its identifier.


[Insert link to an Org file with a further pointer to a heading] See
section 7.3


7.12 Fontify links in non-Org buffers
─────────────────────────────────────

  Denote links are automatically fontified in Org buffers ([Adding a
  single link]).  This means that Org recognises the link and applies
  the relevant properties to it to make it clickable/actionable. Other
  major modes, such as `markdown-mode' (for `.md' files) or `text-mode'
  (for `.txt' files) do not have this feature built into them. Users can
  still get the same behaviour as with Org by activating the
  `denote-fontify-links-mode'.

  The `denote-fontify-links-mode' is a buffer-local minor mode. Users
  can enable it automatically in plain text files that correspond to
  denote notes with something like this:

  ┌────
  │ (add-hook 'text-mode-hook #'denote-fontify-links-mode-maybe)
  └────

  The `text-mode-hook' applies to all modes derived from `text-mode',
  including `markdown-mode'. Though a more explicit setup does no harm:

  ┌────
  │ (add-hook 'markdown-mode-hook #'denote-fontify-links-mode-maybe)
  └────

  Because Org already recognises `denote:' links, the function
  `denote-fontify-links-mode-maybe' will not enable the mode
  `denote-fontify-links-mode' in Org buffers.

  In files whose major mode is `markdown-mode', the default key binding
  `C-c C-o' (which calls the command `markdown-follow-thing-at-point')
  correctly resolves `denote:' links. Interested users can refer to the
  function `denote-link-markdown-follow' for the implementation details.


[Adding a single link] See section 7.1


7.13 Miscellaneous information about links
──────────────────────────────────────────

7.13.1 Aliases for the linking commands
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  For convenience, the `denote-link' command has an alias called
  `denote-insert-link'.  The `denote-backlinks' can also be used as
  `denote-show-backlinks-buffer'.  While `denote-add-links' is aliased
  `denote-link-insert-links-matching-regexp'.  The purpose of these
  aliases is to offer alternative, more descriptive names of select
  commands.


7.13.2 The `denote-link-description-function' to format links
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The user option `denote-link-description-function' takes as its value
  the symbol of a function. This is used to format the text of the link.
  The default function inserts the title. If the file has a signature,
  it includes that as well, prepending it to the title.

  The function specified accepts a single `FILE' argument and returns
  the description as a string.


8 Choose which commands to prompt for
═════════════════════════════════════

  The user option `denote-commands-for-new-notes' specifies a list of
  commands that are available at the `denote-command-prompt'.  This
  prompt is used by Denote commands that ask the user how to create a
  new note, as described elsewhere in this manual:

  • [Open an existing note or create it if missing]
  • [Link to a note or create it if missing]

  The default value includes all the basic file-creating commands
  ([Points of entry]).  Users may customise this value if (i) they only
  want to see fewer options and/or (ii) wish to include their own custom
  command in the list ([Write your own convenience commands]).


[Open an existing note or create it if missing] See section 3.6

[Link to a note or create it if missing] See section 7.7

[Points of entry] See section 3

[Write your own convenience commands] See section 3.1.4.1


9 Fontification in Dired
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

  The user option `denote-dired-directories-include-subdirectories'
  specifies whether the `denote-dired-directories' also cover their
  subdirectories. By default they do not. Set this option to `t' to
  include subdirectories as well.

  The faces we define for this purpose are:

  ⁃ `denote-faces-date'
  ⁃ `denote-faces-delimiter'
  ⁃ `denote-faces-extension'
  ⁃ `denote-faces-keywords'
  • `denote-faces-signature'
  ⁃ `denote-faces-subdirectory'
  ⁃ `denote-faces-time'
  ⁃ `denote-faces-title'

  For more control, we also provide these:

  #+vindex denote-faces-year +vindex denote-faces-month +vindex
  #denote-faces-day +vindex denote-faces-hour +vindex
  #denote-faces-minute +vindex denote-faces-second
  ⁃ `denote-faces-year'
  ⁃ `denote-faces-month'
  ⁃ `denote-faces-day'
  ⁃ `denote-faces-hour'
  ⁃ `denote-faces-minute'
  ⁃ `denote-faces-second'

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


10 Automatically rename Denote buffers
══════════════════════════════════════

  The minor mode `denote-rename-buffer-mode' provides the means to
  automatically rename the buffer of a Denote file upon visiting the
  file. This applies both to existing Denote files as well as new ones
  ([Points of entry]). Enable the mode thus:

  ┌────
  │ (denote-rename-buffer-mode 1)
  └────

  Buffers are named by applying the function specified in the user
  option `denote-rename-buffer-function'. The default function is
  `denote-rename-buffer': it renames the buffer based on the template
  set in the user option `denote-rename-buffer-format'. By default, the
  formatting template targets only the `TITLE' component of the file
  name ([The file-naming scheme]). Other fields are explained elsewhere
  in this manual ([The denote-rename-buffer-format]).

  Note that renaming a buffer is not the same as renaming a file
  ([Renaming files]). The former is just for convenience inside of
  Emacs.  Whereas the latter is for writing changes to disk, making them
  available to all programs.


[Points of entry] See section 3

[The file-naming scheme] See section 5

[The denote-rename-buffer-format] See section 10.1

[Renaming files] See section 4

10.1 The `denote-rename-buffer-format' option
─────────────────────────────────────────────

  The user option `denote-rename-buffer-format' controls how the
  function `denote-rename-buffer' chooses the name of the
  buffer-to-be-renamed.

  The value of this user option is a string. The following specifiers
  are placeholders for Denote file name components ([The file-naming
  scheme]):

  • The `%t' is the Denote `TITLE' of the file.
  • The `%i' is the Denote `IDENTIFIER' of the file.
  • The `%d' is the same as `%i' (`DATE' mnemonic).
  • The `%s' is the Denote `SIGNATURE' of the file.
  • The `%k' is the Denote `KEYWORDS' of the file.
  • The `%b' is an indicator of whether or not the file has backlinks
    pointing to it. The indicator string is defined in the user option
    `denote-rename-buffer-backlinks-indicator', alias
    `denote-buffer-has-backlinks-string'.
  • The `%%' is a literal percent sign.

  In addition, the following flags are available for each of the
  specifiers:

  `0'
        Pad to the width, if given, with zeros instead of spaces.
  `-'
        Pad to the width, if given, on the right instead of the left.
  `<'
        Truncate to the width and precision, if given, on the left.
  `>'
        Truncate to the width and precision, if given, on the right.
  `^'
        Convert to upper case.
  `_'
        Convert to lower case.

  When combined all together, the above are written thus:

  ┌────
  │ %<flags><width><precision>SPECIFIER-CHARACTER
  └────


  Any other string it taken as-is.  Users may want, for example, to
  include some text that makes Denote buffers stand out, such as a `[D]'
  prefix.  Examples:

  ┌────
  │ ;; Use a literal [D] prefix, followed by the title and then the
  │ ;; backlinks indicator (default).
  │ (setq denote-rename-buffer-format "[D] %t%b")
  │ 
  │ ;; Customize what the backlink indicator looks like.  This two-faced
  │ ;; arrow is the default.
  │ (setq denote-rename-buffer-backlinks-indicator  "<-->")
  │ 
  │ ;; Use just the title and keywords with some emoji in between, because
  │ ;; why not?
  │ (setq denote-rename-buffer-format "%t 🤨 %k")
  │ 
  │ ;; Use the title with a literal "[D]" before it.
  │ (setq denote-rename-buffer-format "[D] %t")
  │ 
  │ ;; As above, but also add the `denote-rename-buffer-backlinks-indicator' at the end.
  │ (setq denote-rename-buffer-format "[D] %t")
  └────

  Users who need yet more flexibility are best served by writing their
  own function and assigning it to the `denote-rename-buffer-function'.


[The file-naming scheme] See section 5


11 Use Org dynamic blocks
═════════════════════════

  [ As part of version 2.3.0, all dynamic blocks are defined in the file
    `denote-org-extras.el'. The file which was once called
    `denote-org-dblock.el' contains aliases for the new function names
    and displays a warning about its deprecation. There is no need to
    `require' the `denote-org-extras' feature because all of Denote’s
    Org dynamic blocks are autoloaded (meaning that they work as soon as
    they are used). For backward compatibility, all dynamic blocks
    retain their original names as an alias for the newer one. ]

  Denote can optionally integrate with Org mode’s “dynamic blocks”
  facility. This means that it can use special blocks that are evaluated
  with `C-c C-x C-u' (`org-dblock-update') to generate their contents.
  The following subsections describe the types of Org dynamic blocks
  provided by Denote.

  • [Org dynamic blocks to insert links or backlinks]
  • [Org dynamic block to insert file contents]

  A dynamic block gets its contents by evaluating a function that
  corresponds to the type of block. The block type and its parameters
  are stated in the opening `#+BEGIN' line. Typing `C-c C-x C-u'
  (`org-dblock-update') with point on that line runs (or re-runs) the
  associated function with the given parameters and populates the
  block’s contents accordingly.

  Dynamic blocks are particularly useful for metanote entries that
  reflect on the status of earlier notes ([Writing metanotes]).

  The Org manual describes the technicalities of Dynamic Blocks.
  Evaluate:

  ┌────
  │ (info "(org) Dynamic Blocks")
  └────


[Org dynamic blocks to insert links or backlinks] See section 11.1

[Org dynamic block to insert file contents] See section 11.4

[Writing metanotes] See section 7.9

11.1 Org dynamic blocks to insert links
───────────────────────────────────────

  [ As part of version 2.3.0, all dynamic blocks are defined in the file
    `denote-org-extras.el'. The file which was once called
    `denote-org-dblock.el' contains aliases for the new function names
    and displays a warning about its deprecation. There is no need to
    `require' the `denote-org-extras' feature because all of Denote’s
    Org dynamic blocks are autoloaded (meaning that they work as soon as
    they are used). For backward compatibility, all dynamic blocks
    retain their original names as an alias for the newer one. ]

  The `denote-links' block can be inserted at point with the command
  `denote-org-extras-dblock-insert-links' or by manually including the
  following in an Org file:

  ┌────
  │ #+BEGIN: denote-links :regexp "YOUR REGEXP HERE" :excluded-dirs-regexp nil :sort-by-component nil :reverse-sort nil :id-only nil :include-date nil
  │ 
  │ #+END:
  └────


  All the parameters except for `:regexp' are optional.

  The `denote-links' block is also registered as an option for the
  command `org-dynamic-block-insert-dblock'.

  Type `C-c C-x C-u' (`org-dblock-update') with point on the `#+BEGIN'
  line to update the block.

  • The `:regexp' parameter is mandatory. Its value is a string and its
    behaviour is the same as that of the `denote-add-links' command
    ([Insert links matching a regexp]). Concretely, it produces a
    typographic list of links to files matching the giving regular
    expression. The value of the `:regexp' parameter may also be of the
    form read by the `rx' macro (Lisp notation instead of a string), as
    explained in the Emacs Lisp Reference Manual (evaluate this code to
    read the documentation: `(info "(elisp) Rx Notation")'). Note that
    you do not need to write an actual regular expression to get
    meaningful results: even something like `_journal' will work to
    include all files that have a `journal' keyword.

  • The `:excluded-dirs-regexp' is a string that contains a word or
    regular expression that matches against directory files names
    to-be-excluded from the results. This has the same meaning as
    setting the `denote-excluded-directories-regexp' user option
    ([Exclude certain directories from all operations]). The user option
    has a global effect, which is overridden locally in the dynamic
    block. When the value of `:excluded-dirs-regexp' is nil (the
    default), the value of `denote-excluded-directories-regexp' is used
    (which is also nil by default, meaning that all directories are
    included). When the value of `excluded-dirs-regexp' is `t' or some
    other symbol, then the `denote-excluded-directories-regexp' is
    ignored altogether. This is useful in the scenario where the user
    option is set to exclude some directories but the dynamic blocks
    wants to lift that restriction.

  • The `:sort-by-component' parameter is optional. It sorts the files
    by the given Denote file name component. The value it accepts is an
    unquoted symbol among `title', `keywords', `signature',
    `identifier'.  When using the command
    `denote-org-extras-dblock-insert-files', this parameter is
    automatically inserted together with the (`:regexp' parameter) and
    the user is prompted for a file name component.

  • The `:reverse-sort' parameter is optional. It reverses the order in
    which files appear in. This is meaningful even without the presence
    of the parameter `:sort-by-component', though it also combines with
    it.

  • The `:id-only' parameter is optional. It accepts a `t' value, in
    which case links are inserted without a description text but only
    with the identifier of the given file. This has the same meaning as
    with the `denote-link' command and related facilities ([Linking
    notes]).

  • The `:include-date' parameter controls whether to display the date
    of the file name after the title. This is done when its value is
    `t'. By default (a nil value), no date is shown.

  • An optional `:block-name' parameter can be specified with a string
    value to add a `#+name' to the results. This is useful for further
    processing using Org facilities (a feature that is outside Denote’s
    purview).

  In some workflows, users may want to have a separate block to see what
  other links they are missing since they last updated the dynamic
  block. We cover that case as well ([The Org dynamic block to insert
  missing links only]).


[Insert links matching a regexp] See section 7.4

[Exclude certain directories from all operations] See section 3.9

[Linking notes] See section 7

[The Org dynamic block to insert missing links only] See section 11.2


11.2 The Org dynamic block to insert missing links only
───────────────────────────────────────────────────────

  The `denote-missing-links' block is available with the command
  `denote-org-extras-dblock-insert-missing-links'. It is like the
  aforementioned `denote-links' block, except it only lists links to
  files that are not present in the current buffer ([Org dynamic blocks
  to insert links]).  The parameters are otherwise the same and are all
  optional except for `:regexp':

  ┌────
  │ #+BEGIN: denote-missing-links :regexp "YOUR REGEXP HERE" :excluded-dirs-regexp nil :sort-by-component nil :reverse-sort nil :id-only nil :include-date nil
  │ 
  │ #+END:
  └────


  The `denote-missing-links' block is also registered as an option for
  the command `org-dynamic-block-insert-dblock'.

  Remember to type `C-c C-x C-u' (`org-dblock-update') with point on the
  `#+BEGIN' line to update the block.


[Org dynamic blocks to insert links] See section 11.1


11.3 The Org dynamic block to insert backlinks
──────────────────────────────────────────────

  Apart from links to files matching a regular expression, we can also
  produce a list of backlinks to the current file. The dynamic block can
  be inserted at point with the command
  `denote-org-extras-dblock-insert-backlinks' or by manually writing
  this in an Org file:

  ┌────
  │ #+BEGIN: denote-backlinks :excluded-dirs-regexp nil :sort-by-component nil :reverse-sort nil :id-only nil :this-heading-only nil :include-date nil
  │ 
  │ #+END:
  └────


  The `denote-backlinks' block is also registered as an option for the
  command `org-dynamic-block-insert-dblock'.

  Remember to type `C-c C-x C-u' (`org-dblock-update') with point on the
  `#+BEGIN' line to update the block.

  The parameters recognised by this dynamic block are almost the same as
  that for inserting links ([Org dynamic blocks to insert links]). They
  are all optional in this case and there is no parameter expecting a
  regular expression for matching files to link to.

  Additionally, the `denote-backlinks' block also recognises the
  `:this-heading-only' parameter. It determines if the backlinks are
  about the file or the heading under which the dynamic block is
  inserted ([Backlinks for Org headings]). When this parameter is
  omitted or nil (the default), then the backlinks are about the whole
  file, but if this parameter has a `t' value then the backlinks are
  specifically for the heading ([Insert link to an Org file with a
  further pointer to a heading]).


[Org dynamic blocks to insert links] See section 11.1

[Backlinks for Org headings] See section 7.8.1

[Insert link to an Org file with a further pointer to a heading] See
section 7.3


11.4 Org dynamic block to insert file contents
──────────────────────────────────────────────

  [ As part of version 2.3.0, all dynamic blocks are defined in the file
    `denote-org-extras.el'. The file which was once called
    `denote-org-dblock.el' contains aliases for the new function names
    and displays a warning about its deprecation. There is no need to
    `require' the `denote-org-extras' feature because all of Denote’s
    Org dynamic blocks are autoloaded (meaning that they work as soon as
    they are used). For backward compatibility, all dynamic blocks
    retain their original names as an alias for the newer one. ]

  Denote can optionally use Org’s dynamic blocks facility to produce a
  section that lists entire file contents ([Use Org dynamic blocks]).
  This works by instructing Org to match a regular expression of Denote
  files, the same way we do with Denote links ([Insert links matching a
  regexp]).

  This is useful to, for example, compile a dynamically concatenated
  list of scattered thoughts on a given topic, like `^2023.*_emacs' for
  a long entry that incorporates all the notes written in 2023 with the
  keyword `emacs'.

  To produce such a block, call the command
  `denote-org-extras-dblock-insert-files' or manually write the
  following block in an Org file and then type `C-c C-x C-u'
  (`org-dblock-update') on the `#+BEGIN' line to run it (do it again to
  recalculate the block):

  ┌────
  │ #+BEGIN: denote-files :regexp "YOUR REGEXP HERE" :sort-by-component nil :reverse-sort nil :no-front-matter nil :file-separator nil :add-links nil
  │ 
  │ #+END:
  └────


  All parameters are optional except for `:regexp'.

  The `denote-files' block is also registered as an option for the
  command `org-dynamic-block-insert-dblock'.

  Remember to type `C-c C-x C-u' (`org-dblock-update') with point on the
  `#+BEGIN' line to update the block.

  To fully control the output, include these additional optional
  parameters, which are described further below:


  • The `:regexp' parameter is mandatory. Its value is a string,
    representing a regular expression to match Denote file names. Its
    value may also be an `rx' expression instead of a string, as noted
    in the previous section ([Org dynamic blocks to insert links or
    backlinks]).  Note that you do not need to write an actual regular
    expression to get meaningful results: even something like `_journal'
    will work to include all files that have a `journal' keyword.

  • The `:excluded-dirs-regexp' is a string that contains a word or
    regular expression that matches against directory files names
    to-be-excluded from the results. This has the same meaning as
    setting the `denote-excluded-directories-regexp' user option
    ([Exclude certain directories from all operations]). The user option
    has a global effect, which is overridden locally in the dynamic
    block. When the value of `:excluded-dirs-regexp' is nil (the
    default), the value of `denote-excluded-directories-regexp' is used
    (which is also nil by default, meaning that all directories are
    included). When the value of `excluded-dirs-regexp' is `t' or some
    other symbol, then the `denote-excluded-directories-regexp' is
    ignored altogether. This is useful in the scenario where the user
    option is set to exclude some directories but the dynamic blocks
    wants to lift that restriction.

  • The `:sort-by-component' parameter is optional. It sorts the files
    by the given Denote file name component. The value it accepts is an
    unquoted symbol among `title', `keywords', `signature',
    `identifier'.  When using the command
    `denote-org-extras-dblock-insert-files', this parameter is
    automatically inserted together with the (`:regexp' parameter) and
    the user is prompted for a file name component.

  • The `:reverse-sort' parameter is optional. It reverses the order in
    which files appear in. This is meaningful even without the presence
    of the parameter `:sort-by-component', though it also combines with
    it.

  • The `:file-separator' parameter is optional. If it is omitted, then
    Denote will use no separator between the files it inserts. If the
    value is `t' the `denote-org-extras-dblock-file-contents-separator'
    is applied at the end of each file: it introduces some empty lines
    and a horizontal rule between them to visually distinguish
    individual files. If the `:file-separator' value is a string, it is
    used as the file separator (e.g. use `"\n"' to insert just one empty
    new line).

  • The `:no-front-matter' parameter is optional. When set to a `t'
    value, Denote tries to remove front matter from the files it is
    inserting in the dynamic block. The technique used to perform this
    operation is by removing all lines from the top of the file until
    the first empty line. This works with the default front matter that
    Denote adds, but is not 100% reliable with all sorts of user-level
    modifications and edits to the file. When the `:no-front-matter' is
    set to a natural number, Denote will omit that many lines from the
    top of the file.

  • The `:add-links' parameter is optional. When it is set to a `t'
    value, all files are inserted as a typographic list and are indented
    accordingly. The first line in each list item is a link to the file
    whose contents are inserted in the following lines. When the value
    is `id-only', then links are inserted without a description text but
    only with the identifier of the given file. This has the same
    meaning as with the `denote-link' command and related facilities
    ([Linking notes]). Remember that Org can fold the items in a
    typographic list the same way it does with headings. So even long
    files can be presented in this format without much trouble.

  • An optional `:block-name' parameter can be specified with a string
    value to add a `#+name' to the results. This is useful for further
    processing using Org facilities (a feature that is outside Denote’s
    purview).


[Use Org dynamic blocks] See section 11

[Insert links matching a regexp] See section 7.4

[Org dynamic blocks to insert links or backlinks] See section 11.1

[Exclude certain directories from all operations] See section 3.9

[Linking notes] See section 7


11.5 Org dynamic block to insert Org files as headings
──────────────────────────────────────────────────────

  [ IMPORTANT NOTE: This dynamic block only works with Org files,
    because it has to assume the Org notation in order to insert each
    file’s contents as its own heading. ]

  As a variation of the previously covered block that inserts file
  contents, we have the
  `denote-org-extras-dblock-insert-files-as-headings' command ([Org
  dynamic block to insert file contents]). It Turn the `#+title' of each
  file into a top-level heading. Then it increments all original
  headings in the file by one, so that they become subheadings of what
  once was the `#+title'. Similarly, the `#+filetags' of each file as
  tags for the top-level heading (what was the `#+title').

  Because of how it is meant to work, this dynamic block only works with
  Org files.

  In its simplest form, this dynamic block looks like this, with
  `:regexp' as the only mandatory parameter:

  ┌────
  │ #+BEGIN: denote-files-as-headings :regexp "YOUR REGEXP HERE"
  │ 
  │ #+END:
  └────


  Though when you use the command
  `denote-org-extras-dblock-insert-files-as-headings' you get all the
  parameters included:

  ┌────
  │ #+BEGIN: denote-files-as-headings :regexp "YOUR REGEXP HERE" :excluded-dirs-regexp nil :sort-by-component title :reverse-sort nil :add-links t
  │ 
  │ #+END:
  └────


  • The `:regexp' parameter is mandatory. Its value is a string,
    representing a regular expression to match Denote file names. Its
    value may also be an `rx' expression instead of a string, as noted
    in the previous section ([Org dynamic blocks to insert links or
    backlinks]).  Note that you do not need to write an actual regular
    expression to get meaningful results: even something like `_journal'
    will work to include all files that have a `journal' keyword.

  • The `:excluded-dirs-regexp' is a string that contains a word or
    regular expression that matches against directory files names
    to-be-excluded from the results. This has the same meaning as
    setting the `denote-excluded-directories-regexp' user option
    ([Exclude certain directories from all operations]). The user option
    has a global effect, which is overridden locally in the dynamic
    block. When the value of `:excluded-dirs-regexp' is nil (the
    default), the value of `denote-excluded-directories-regexp' is used
    (which is also nil by default, meaning that all directories are
    included). When the value of `excluded-dirs-regexp' is `t' or some
    other symbol, then the `denote-excluded-directories-regexp' is
    ignored altogether. This is useful in the scenario where the user
    option is set to exclude some directories but the dynamic blocks
    wants to lift that restriction.

  • The `:sort-by-component' parameter is optional. It sorts the files
    by the given Denote file name component. The value it accepts is an
    unquoted symbol among `title', `keywords', `signature',
    `identifier'.  When using the command
    `denote-org-extras-dblock-insert-files', this parameter is
    automatically inserted together with the (`:regexp' parameter) and
    the user is prompted for a file name component.

  • The `:reverse-sort' parameter is optional. It reverses the order in
    which files appear in. This is meaningful even without the presence
    of the parameter `:sort-by-component', though it also combines with
    it.

  • The `:add-links' parameter is optional. When it is set to a `t'
    value, all the top-level headings (those that were the `#+title' of
    each file) are generated as links, pointing to the original file.
    This has the same meaning as with the `denote-link' command and
    related facilities ([Linking notes]).

  • An optional `:block-name' parameter can be specified with a string
    value to add a `#+name' to the results. This is useful for further
    processing using Org facilities (a feature that is outside Denote’s
    purview).


[Org dynamic block to insert file contents] See section 11.4

[Org dynamic blocks to insert links or backlinks] See section 11.1

[Exclude certain directories from all operations] See section 3.9

[Linking notes] See section 7


12 Sort files by component
══════════════════════════

  The `denote-sort.el' file is an optional extension to the core
  functionality of Denote, which empowers users to sort files by the
  given file name component ([The file-naming scheme]).

  The command `denote-sort-dired' produces a Dired file listing with a
  flat, filtered, and sorted set of files from the `denote-directory'
  ([Define a sorting function per component]). It does so by means of
  three minibuffer prompts:

  1. It first asks for a regular expression with which to match Denote
     files. Remember that due to Denote’s efficient file-naming scheme,
     you do not need to write some complex regular expression. Even
     something like `_journal' will match only files with a `journal'
     keyword.
  2. Once the regular expression is provided, the command asks for a
     Denote file name component to sort files by. This is a symbol among
     `title', `keywords', `signature', and `identifier'.
  3. Finally, it asks a “yes or no” on whether to reverse the sort
     order.

  The resulting Dired listing is a regular Dired buffer, unlike that of
  `dired-virtual-mode' ([Use `dired-virtual-mode' for arbitrary file
  listings]).

  The dynamic Org blocks that Denote defines to insert file contents
  also use this feature ([Org dynamic block to insert file contents]).


[The file-naming scheme] See section 5

[Define a sorting function per component] See section 12.2

[Use `dired-virtual-mode' for arbitrary file listings] See section 15.3

[Org dynamic block to insert file contents] See section 11.4

12.1 Configure what extra prompts `denote-sort-dired' issues
────────────────────────────────────────────────────────────

  By default, the `denote-sort-dired' command prompts for (i) a query to
  match file names, (ii) a file name component to sort by, and (iii)
  whether to reverse the sorting. Users can configure the latter two by
  modifying the user option `denote-sort-dired-extra-prompts'.

  It accepts either a nil value or a list of symbols among
  `sort-by-component' and `reverse-sort'. The order those symbols appear
  in the list is significant, with the leftmost coming first.

  In case of a nil value, those extra prompts will not happen, meaning
  that `denote-sort-dired' will fall back to using
  `denote-sort-dired-default-sort-component' and
  `denote-sort-dired-default-reverse-sort'.

  Here are some examples:

  ┌────
  │ ;; The default extra prompts...
  │ (setq denote-sort-dired-extra-prompts '(sort-by-component reverse-sort))
  │ 
  │ ;; When using `denote-sort-dired', ask whether to reverse the sort and
  │ ;; then which file name component to sort by.  These are always done
  │ ;; after the prompt to search for files matching a regexp.
  │ (setq denote-sort-dired-extra-prompts '(reverse-sort sort-by-component))
  │ 
  │ ;; Do not prompt for a reverse sort.  Just use the value of
  │ ;; `denote-sort-dired-default-reverse-sort' (which is nil out-of-the-box).
  │ (setq denote-sort-dired-extra-prompts '(sort-by-component))
  │ 
  │ ;; Do not issue any extra prompts.  Always sort by the `title' file
  │ ;; name component and never do a reverse sort.
  │ (setq denote-sort-dired-extra-prompts nil)
  │ (setq denote-sort-dired-default-sort-component 'title)
  │ (setq denote-sort-dired-default-reverse-sort nil)
  └────


12.2 Define a sorting function per component
────────────────────────────────────────────

  When sorting by `title', `keywords', or `signature' with the
  `denote-sort-dired' command, Denote will internally apply a sorting
  function that is specific to each component. These are subject to user
  configuration:

  • `denote-sort-title-comparison-function'

  • `denote-sort-keywords-comparison-function'

  • `denote-sort-signature-comparison-function'

  By default, all these user options use the same sorting function,
  namely `string-collate-lessp'. Users who have specific needs for any
  of those file name components can write their own sorting algorithms
  ([Sort signatures that include Luhmann-style sequences]).


[Sort signatures that include Luhmann-style sequences] See section
12.2.1

12.2.1 Sort signatures that include Luhmann-style sequences
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Niklas Luhmann would edit notes to form sequences of thoughts with
  branching paths, such as `1.1', `1.1a', `1.2', `1.2a', `1.2b', etc.
  With the Denote file-naming scheme, we make the word separator in each
  file name component use the same character as the entire field, so
  words in a title have a dash between them and signatures have the
  equals sign ([The file-naming scheme]). Thus, our Luhmann-style
  signature will be slightly different in their looks: `1=1', `1=1a',
  `1=2', `1=2a', `1=2b'.

  When using the `denote-sort-dired' command with default settings, our
  signatures will not sort in an intuitive way. This is because they
  combine numbers and letters, which require a different approach than
  what the default sorting function is using ([Define a sorting function
  per component]).  In the following code block, we show a sorting
  algorithm that should do the right thing while dealing with
  Luhmann-style signatures.

  ┌────
  │ (defun my-denote--split-luhman-sig (signature)
  │   "Split numbers and letters in Luhmann-style SIGNATURE string."
  │   (replace-regexp-in-string
  │    "\\([a-zA-Z]+?\\)\\([0-9]\\)" "\\1=\\2"
  │    (replace-regexp-in-string
  │     "\\([0-9]+?\\)\\([a-zA-Z]\\)" "\\1=\\2"
  │     signature)))
  │ 
  │ (defun my-denote--pad-sig (signature)
  │   "Create a new signature with padded spaces for all components"
  │   (combine-and-quote-strings
  │    (mapcar
  │     (lambda (x)
  │       (string-pad x 5 32 t))
  │     (split-string (my-denote--split-luhman-sig signature) "=" t))
  │    "="))
  │ 
  │ (defun my-denote-sort-for-signatures (sig1 sig2)
  │   "Return non-nil if SIG1 is smaller that SIG2.
  │ Perform the comparison with `string<'."
  │   (string< (my-denote--pad-sig sig1) (my-denote--pad-sig sig2)))
  │ 
  │ ;; Change the sorting function only when we sort by signature.
  │ (setq denote-sort-signature-comparison-function #'my-denote-sort-for-signatures)
  └────

  DEVELOPMENT NOTE 2024-08-01 08:27 +0300: If you need to sort in a
  certain way but do not know how to write the relevant Elisp, please
  let me know. I am happy to help and we can then include our findings
  in the manual for the benefit of the community.


[The file-naming scheme] See section 5

[Define a sorting function per component] See section 12.2


13 Keep a journal or diary
══════════════════════════

  Denote provides a general-purpose mechanism to create new files that
  broadly count as “notes” ([Points of entry]).  Such files can be daily
  entries in a journal.  While it is possible to use the generic
  `denote' command to maintain a journal, we provide an optional set of
  convenience options and commands as part of
  `denote-journal-extras.el'.  To use those, add the following the
  Denote configuration:

  ┌────
  │ (require 'denote-journal-extras)
  └────

  The command `denote-journal-extras-new-entry' creates a new entry in
  the journal.  Such a file has the `denote-journal-extras-keyword',
  which is `journal' by default ([The file-naming scheme]).  The user
  can set this keyword to an arbitrary string (single word is
  preferred).  New journal entries can be stored in the
  `denote-directory' or subdirectory thereof.  To make it easier for the
  user, the new journal entry will be placed in
  `denote-journal-extras-directory', which defaults to a subdirectory of
  `denote-directory' called `journal'.

  If `denote-journal-extras-directory' is nil, the `denote-directory' is
  used.  Journal entries will thus be in a flat listing together with
  all other notes.  They can still be retrieved easily by searching for
  the `denote-journal-extras-keyword' ([Features of the file-naming
  scheme for searching or filtering]).

  Furthermore, the command `denote-journal-extras-new-entry' will use
  the current date as the title of the new entry.  The exact format is
  controlled by the user option `denote-journal-extras-title-format'.
  Acceptable values for `denote-journal-extras-title-format' and their
  corresponding styles are:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Symbol                   Style                             
  ────────────────────────────────────────────────────────────
   day                      Monday                            
   day-date-month-year      Monday 19 September 2023          
   day-date-month-year-24h  Monday 19 September 2023 20:49    
   day-date-month-year-12h  Monday 19 September 2023 08:49 PM 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  For example:

  ┌────
  │ (setq denote-journal-extras-title-format 'day-date-month-year)
  └────

  If the value of this user option is `nil', then
  `denote-journal-extras-new-entry' will prompt for a title.

  The `denote-journal-extras-new-entry' command also accepts an optional
  `DATE' argument. When called internactively, this is a universal
  prefix (e.g. `C-u' with the default key bindings). With `DATE', it
  prompts for a date to create a new journal entry for. The date prompt
  can optionally use the Org date+calendar selection interface ([The
  `denote-date-prompt-use-org-read-date' option]).

  In terms of workflow, using the current date as the title is better
  for maintaining a daily journal.  A prompt for an arbitrary title is
  more suitable for those who like to keep a record of something like a
  thought or event (though this can also be achieved by the regular
  `denote' command or maybe `denote-subdirectory').

  The `denote-journal-extras-new-entry' command calls the normal hook
  `denote-journal-extras-hook' after it is done.  The user can leverage
  this to produce consequences therefrom, such as to set a timer with
  the `tmr' package from GNU ELPA ([Journaling with a timer]).

  The command `denote-journal-extras-new-or-existing-entry' locates an
  existing journal entry or creates a new one.  A journal entry is one
  that has `denote-journal-extras-keyword' as part of its file name.  If
  there are multiple journal entries for the current date, it prompts
  for one among them using minibuffer completion.  If there is only one,
  it visits it outright.  If there is no journal entry, it creates one
  by calling `denote-journal-extra-new-entry' (as described above).

  The command `denote-journal-extras-link-or-create-entry' links to the
  journal entry for today or creates it in the background, if missing,
  and then links to it from the current file. If there are multiple
  journal entries for the same day, it prompts to select one among them
  and then links to it. When called with an optional prefix argument
  (such as `C-u' with default key bindings), the command prompts for a
  date and then performs the aforementioned. With a double prefix
  argument (`C-u C-u'), it also produces a link whose description
  includes just the file’s identifier.


[Points of entry] See section 3

[The file-naming scheme] See section 5

[Features of the file-naming scheme for searching or filtering] See
section 5.4

[The `denote-date-prompt-use-org-read-date' option] See section 3.1.7

[Journaling with a timer] See section 13.1

13.1 Journaling with a timer
────────────────────────────

  [ Revised as part of version 2.1.0 to conform with how we now tend to
    the needs of users who use Denote for journaling purposes ([Keep a
    journal or diary]). ]

  Sometimes journaling is done with the intent to hone one’s writing
  skills.  Perhaps you are learning a new language or wish to
  communicate your ideas with greater clarity and precision.  As with
  everything that requires a degree of sophistication, you have to work
  for it—write, write, write!

  One way to test your progress is to set a timer.  It helps you gauge
  your output and its quality.  To use a timer with Emacs, consider the
  `tmr' package.  A new timer can be set with something like this:

  ┌────
  │ ;; Set 10 minute timer with the given description
  │ (tmr "10" "Practice writing in my journal")
  └────

  To make this timer start as soon as a new journal entry is created
  with the command `denote-journal-extras-new-entry', add a function to
  the `denote-journal-extras-hook'.  For example:

  ┌────
  │ ;; Add an anonymous function, which is more difficult to modify after
  │ ;; the fact:
  │ (add-hook 'denote-journal-extras-hook (lambda ()
  │ 					(tmr "10" "Practice writing in my journal")))
  │ 
  │ ;; Or write a small function that you can then modify without
  │ ;; revaluating the hook:
  │ (defun my-denote-tmr ()
  │   (tmr "10" "Practice writing in my journal"))
  │ 
  │ (add-hook 'denote-journal-extras-hook 'my-denote-tmr)
  │ 
  │ ;; Or to make it fully featured, define variables for the duration and
  │ ;; the description and set it up so that you only need to modify
  │ ;; those:
  │ (defvar my-denote-tmr-duration "10")
  │ 
  │ (defvar my-denote-tmr-description "Practice writing in my journal")
  │ 
  │ (defun my-denote-tmr ()
  │   (tmr my-denote-tmr-duration my-denote-tmr-description))
  │ 
  │ (add-hook 'denote-journal-extras-hook 'my-denote-tmr)
  └────

  Once the timer elapses, stop writing and review your performance.
  Practice makes perfect!

  Sources for `tmr':

  ⁃ Package name (GNU ELPA): `tmr'
  ⁃ Official manual: <https://protesilaos.com/emacs/tmr>
  ⁃ Change log: <https://protesilaos.com/emacs/denote-changelog>
  ⁃ Git repo on SourceHut: <https://git.sr.ht/~protesilaos/tmr>
    • Mirrors:
      ⁃ GitHub: <https://github.com/protesilaos/tmr>
      ⁃ GitLab: <https://gitlab.com/protesilaos/tmr>
  ⁃ Mailing list: <https://lists.sr.ht/~protesilaos/tmr>


[Keep a journal or diary] See section 13


14 Minibuffer histories
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


15 Extending Denote
═══════════════════

  Denote is a tool with a narrow scope: create notes and link between
  them, based on the aforementioned file-naming scheme.  For other
  common operations the user is advised to rely on standard Emacs
  facilities or specialised third-party packages.  This section covers
  the details.


15.1 Create a new note in any directory
───────────────────────────────────────

  The commands that create new files are designed to write to the
  `denote-directory'. The idea is that the linking mechanism can find
  any file by its identifier if it is in the `denote-directory'
  (searching the entire file system would be cumbersome).

  However, these are cases where the user needs to create a new note in
  an arbitrary directory. The following command can do this. Put the
  code in your configuration file and evaluate it. Then call the command
  by its name with `M-x'.

  ┌────
  │ (defun my-denote-create-note-in-any-directory ()
  │   "Create new Denote note in any directory.
  │ Prompt for the directory using minibuffer completion."
  │   (declare (interactive-only t))
  │   (interactive)
  │   (let ((denote-directory (read-directory-name "New note in: " nil nil :must-match)))
  │     (call-interactively 'denote)))
  └────


15.2 Narrow the list of files in Dired
──────────────────────────────────────

  Emacs’ standard file manager (or directory editor) can read a regular
  expression to mark the matching files.  This is the command
  `dired-mark-files-regexp', which is bound to `% m' by default.  For
  example, `% m _denote' will match all files that have the `denote'
  keyword ([Features of the file-naming scheme for searching or
  filtering]).

  Once the files are matched, the user has two options: (i) narrow the
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
section 5.4


15.3 Use `dired-virtual-mode' for arbitrary file listings
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
23.7

[The file-naming scheme] See section 5


15.4 Use Embark to collect minibuffer candidates
────────────────────────────────────────────────

  `embark' is a remarkable package that lets you perform relevant,
  context-dependent actions using a prefix key (simplifying in the
  interest of brevity).

  For our purposes, Embark can be used to produce a Dired listing
  directly from the minibuffer.  Suppose the current note has links to
  three other notes.  You might use the `denote-find-link' command to
  pick one via the minibuffer.  But why not turn those three links into
  their own Dired listing?  While in the minibuffer, invoke `embark-act'
  which you may have already bound to `C-.' and then follow it up with
  `E' (for the `embark-export' command).

  This pattern can be repeated with any list of candidates, meaning that
  you can narrow the list by providing some input before eventually
  exporting the results with Embark.

  Overall, this is very powerful and you might prefer it over doing the
  same thing directly in Dired, since you also benefit from all the
  power of the minibuffer ([Narrow the list of files in Dired]).


[Narrow the list of files in Dired] See section 15.2


15.5 Search file contents
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


15.6 Bookmark the directory with the notes
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


15.7 Use the `denote-explore' package to explore your notes
───────────────────────────────────────────────────────────

  Peter Prevos has developed the `denote-explore' package which provides
  four groups of Emacs commands to explore your Denote files:

  Summary statistics
        Count notes, attachments and keywords.
  Random walks
        Generate new ideas using serendipity.
  Janitor
        Manage your denote collection.
  Visualisations
        Visualise your Denote network.

  The package’s documentation covers the details:
  <https://lucidmanager.org/productivity/denote-explore/>.


15.8 Use the `citar-denote' package for bibliography notes
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
  <https://lucidmanager.org/productivity/bibliographic-notes-in-emacs-with-citar-denote/>.


15.9 Use the `consult-notes' package for enhanced minibuffer interactions
─────────────────────────────────────────────────────────────────────────

  The `consult-denote' package by me (Protesilaos) integrates Denote
  with Daniel Mendler’s `consult' package:
  <https://github.com/protesilaos/consult-denote>.

  The idea is to preserve the familiar patterns of interaction with the
  various Denote commands but add to them an extra layer of
  functionality, such as the preview mechanism that Consult provides
  (e.g. preview the file you are about to link to).

  Additionally, `consult-denote' defines new “sources” for the
  `consult-buffer' command. This command provides a single point of
  entry for buffers, recently opened files, and bookmarks. With
  `consult-denote', it has a dedicated place for Denote-specific
  buffers, silos, and more (all of which are configurable).

  Unlike the `consult-notes' package by Colin McLear, `consult-denote'
  uses the same presentation of data in the minibuffer to stay in sync
  with Denote and make its feature set entirely optional ([Use the
  `consult-notes' package]).  It also only works with Denote.


[Use the `consult-notes' package] See section 15.10


15.10 Use the `consult-notes' package
─────────────────────────────────────

  [ Also check the `consult-denote' package by me (Protesilaos): [Use
    the `consult-notes' package for enhanced minibuffer interactions]. ]

  If you are using Daniel Mendler’s `consult' (which is a brilliant
  package), you will most probably like its `consult-notes' extension,
  developed by Colin McLear.  It uses the familiar mechanisms of Consult
  to preview the currently selected entry and to filter searches via a
  prefix key.  For example:

  ┌────
  │ (setq consult-notes-file-dir-sources
  │       `(("Denote Notes"  ?d ,(denote-directory))
  │ 	("Books"  ?b "~/Documents/books/")))
  └────

  With the above, `M-x consult-notes' will list the files in those two
  directories.  If you type `d' and space, it narrows the list to just
  the notes, while `b' does the same for books.

  The other approach is to enable the `consult-notes-denote-mode'.  It
  takes care to add the `denote-directory' to the sources that
  `consult-notes' reads from.  Denote notes are then filtered by the `d'
  prefix followed by a space.

  The minor mode has the extra feature of reformatting the title of
  notes shown in the minibuffer.  It isolates the `TITLE' component of
  each note and shows it without hyphens, while presenting keywords in
  their own column.  The user option `consult-notes-denote-display-id'
  can be set to `nil' to hide the identifier.  Depending on how one
  searches through their notes, this refashioned presentation may be the
  best option ([Features of the file-naming scheme for searching or
  filtering]).


[Use the `consult-notes' package for enhanced minibuffer interactions]
See section 15.9

[Features of the file-naming scheme for searching or filtering] See
section 5.4


15.11 Use the `denote-menu' package
───────────────────────────────────

  Denote’s file-naming scheme is designed to be efficient and to provide
  valueable meta information about the file.  The cost, however, is that
  it is terse and harder to read, depending on how the user chooses to
  filter and process their notes.

  To this end, [the `denote-menu' package by Mohamed Suliman] provides
  the convenience of a nice tabular interface for all notes.
  `denote-menu' removes the delimiters that are found in Denote file
  names and presents the information in a human-readable format.
  Furthermore, the package provides commands to interact with the list
  of notes, such as to filter them and to transition from the tabular
  list to Dired.  Its documentation expands on the technicalities.


[the `denote-menu' package by Mohamed Suliman]
<https://github.com/namilus/denote-menu>


15.12 Treat your notes as a project
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


15.13 Use the tree-based file prompt for select commands
────────────────────────────────────────────────────────

  Older versions of Denote had a file prompt that resembled that of the
  standard `find-file' command (bound to `C-x C-f' by default).  This
  means that it used a tree-based method of navigating the filesystem by
  selecting the specific directory and then the given file.

  Currently, Denote flattens the file prompt so that every file in the
  `denote-directory' and its subdirectories can be matched from anywhere
  using the power of Emacs’ minibuffer completion (such as with the help
  of the `orderless' package in addition to built-in options).

  Users who need the old behaviour on a per-command basis can define
  their own wrapper functions as shown in the following code block.

  ┌────
  │ ;; This is the old `denote-file-prompt' that we renamed to
  │ ;; `denote-file-prompt-original' for clarity.
  │ (defun denote-file-prompt-original (&optional initial-text)
  │   "Prompt for file with identifier in variable `denote-directory'.
  │ With optional INITIAL-TEXT, use it to prepopulate the minibuffer."
  │   (read-file-name "Select note: " (denote-directory) nil nil initial-text
  │ 		  (lambda (f)
  │ 		    (or (denote-file-has-identifier-p f)
  │ 			(file-directory-p f)))))
  │ 
  │ ;; Our wrapper command that changes the current `denote-file-prompt'
  │ ;; to the functionality of `denote-file-prompt-original' only when
  │ ;; this command is used.
  │ (defun my-denote-link ()
  │   "Call `denote-link' but use Denote's original file prompt.
  │ See `denote-file-prompt-original'."
  │   (interactive)
  │   (cl-letf (((symbol-function 'denote-file-prompt) #'denote-file-prompt-original))
  │     (call-interactively #'denote-link)))
  └────


15.14 Rename files with Denote in the Image Dired thumbnails buffer
───────────────────────────────────────────────────────────────────

  [Rename files with Denote using `dired-preview']

  Just as with the `denote-dired-rename-marked-files-with-keywords', we
  can use Denote in the Image Dired buffer ([Rename multiple files at
  once]).  Here is the custom code:

  ┌────
  │ (autoload 'image-dired--with-marked "image-dired")
  │ (autoload 'image-dired-original-file-name "image-dired-util")
  │ 
  │ (defun my-denote-image-dired-rename-marked-files (keywords)
  │   "Like `denote-dired-rename-marked-files-with-keywords' but for Image Dired.
  │ Prompt for KEYWORDS and rename all marked files in the Image
  │ Dired buffer to have a Denote-style file name with the given
  │ KEYWORDS.
  │ 
  │ IMPORTANT NOTE: if there are marked files in the corresponding
  │ Dired buffers, those will be targeted as well.  This is not the
  │ fault of Denote: it is how Dired and Image Dired work in tandem.
  │ To only rename the marked thumbnails, start by unmarking
  │ everything in Dired.  Then mark the items in Image Dired and
  │ invoke this command."
  │   (interactive (list (denote-keywords-prompt)) image-dired-thumbnail-mode)
  │   (image-dired--with-marked
  │    (when-let* ((file (image-dired-original-file-name))
  │ 	       (dir (file-name-directory file))
  │ 	       (id (or (denote-retrieve-filename-identifier file) ""))
  │ 	       (file-type (denote-filetype-heuristics file))
  │ 	       (title (denote--retrieve-title-or-filename file file-type))
  │ 	       (signature (or (denote-retrieve-filename-signature file) "")
  │ 	       (extension (file-name-extension file t))
  │ 	       (new-name (denote-format-file-name dir id keywords title extension signature))
  │ 	       (default-directory dir))
  │      (denote-rename-file-and-buffer file new-name))))
  └────

  While the `my-denote-image-dired-rename-marked-files' renames files in
  the helpful Denote-compliant way, users may still need to not prepend
  a unique identifier and not sluggify (hyphenate and downcase) the
  image’s existing file name.  To this end, the following custom command
  can be used instead:

  ┌────
  │ (defun my-image-dired-rename-marked-files (keywords)
  │   "Like `denote-dired-rename-marked-files-with-keywords' but for Image Dired.
  │ Prompt for keywords and rename all marked files in the Image
  │ Dired buffer to have Denote-style keywords, but none of the other
  │ conventions of Denote's file-naming scheme."
  │   (interactive (list (denote-keywords-prompt)) image-dired-thumbnail-mode)
  │   (image-dired--with-marked
  │    (when-let* ((file (image-dired-original-file-name))
  │ 	       (dir (file-name-directory file))
  │ 	       (file-type (denote-filetype-heuristics file))
  │ 	       (title (denote--retrieve-title-or-filename file file-type))
  │ 	       (extension (file-name-extension file t))
  │ 	       (kws (denote--keywords-combine keywords))
  │ 	       (new-name (concat dir title "__" kws extension))
  │ 	       (default-directory dir))
  │      (denote-rename-file-and-buffer file new-name))))
  └────


[Rename files with Denote using `dired-preview'] See section 15.15

[Rename multiple files at once] See section 4.3


15.15 Rename files with Denote using `dired-preview'
────────────────────────────────────────────────────

  The `dired-preview' package (by me/Protesilaos) automatically displays
  a preview of the file at point in Dired.  This can be helpful in
  tandem with Denote when we want to rename multiple files by taking a
  quick look at their contents.

  The command `denote-dired-rename-marked-files-with-keywords' will
  generate Denote-style file names based on the keywords it prompts
  for. Identifiers are derived from each file’s modification date
  ([Rename multiple files at once]). There is no need for any custom
  code in this scenario.

  As noted in the section about Image Dired, the user may sometimes not
  need a fully fledged Denote-style file name but only append
  Denote-like keywords to each file name (e.g. `Original
  Name__denote_test.jpg' instead of
  `20230710T195843--original-name__denote_test.jpg').

  [Rename files with Denote in the Image Dired thumbnails buffer]

  In such a workflow, it is unlikely to be dealing with ordinary text
  files where front matter can be helpful.  A custom command does not
  need to behave like what Denote provides out-of-the-box, but can
  instead append keywords to file names without conducting any further
  actions.  We thus have:

  ┌────
  │ (defun my-denote-dired-rename-marked-files-keywords-only ()
  │   "Like `denote-dired-rename-marked-files-with-keywords' but only for keywords in file names.
  │ 
  │ Prompt for keywords and rename all marked files in the Dired
  │ buffer to only have Denote-style keywords, but none of the other
  │ conventions of Denote's file-naming scheme."
  │   (interactive nil dired-mode)
  │   (if-let ((marks (dired-get-marked-files)))
  │       (let ((keywords (denote-keywords-prompt)))
  │ 	(dolist (file marks)
  │ 	  (let* ((dir (file-name-directory file))
  │ 		 (file-type (denote-filetype-heuristics file))
  │ 		 (title (denote--retrieve-title-or-filename file file-type))
  │ 		 (extension (file-name-extension file t))
  │ 		 (kws (denote--keywords-combine keywords))
  │ 		 (new-name (concat dir title "__" kws extension)))
  │ 	    (denote-rename-file-and-buffer file new-name)))
  │ 	(revert-buffer))
  │     (user-error "No marked files; aborting")))
  └────


[Rename multiple files at once] See section 4.3

[Rename files with Denote in the Image Dired thumbnails buffer] See
section 15.14


15.16 Avoid duplicate identifiers when exporting Denote notes
─────────────────────────────────────────────────────────────

  When exporting Denote notes to, for example, an HTML or PDF file,
  there is a high probability that the same file name is used with a new
  extension.  This is problematic because it creates files with
  duplicate identifiers.  The `20230515T085612--example__keyword.org'
  produces a `20230515T085612--example__keyword.pdf'.  Any link to the
  `20230515T085612' will thus break: it does not honor Denote’s
  expectation of finding unique identifiers.  This is not the fault of
  Denote: exporting is done by the user without Denote’s involvement.

  Org Mode and Markdown use different approaches to exporting files.  No
  recommended method is available for plain text files as there is no
  standardised export functionality for this format (the user can always
  create a new note using the file type they want on a case-by-case
  basis: [Convenience commands for note creation]).


[Convenience commands for note creation] See section 3.1.4

15.16.1 Export Denote notes with Org Mode
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Org Mode has a built-in configurable export engine.  You can prevent
  duplicate identifiers when exporting manually for each exported file
  or by advising the Org export function.

  Denote also provides commands to convert `denote:' links to their
  `file:' equivalent, in case this is a required pre-processing step for
  export purposes ([Convert `denote:' links to `file:' links]).


[Convert `denote:' links to `file:' links] See section 7.11

◊ 15.16.1.1 Manually configure Org export

  Insert `#+export_file_name: FILENAME' in the front matter before
  exporting to force a filename called whatever the value of `FILENAME'
  is.  The `FILENAME' does not specify the file type extension, such as
  `.pdf'.  This is up to the export engine.  For example, a Denote note
  with a complete file name of `20230515T085612--example__keyword.org'
  and a front matter entry of `#+export_file_name: hello' will be
  exported as `hello.pdf'.

  The advantage of this manual method is that it gives the user full
  control over the resulting file name.  The disadvantage is that it
  depends on the user’s behaviour.  Forgetting to add a new name can
  lead to duplicate identifiers, as already noted in the introduction to
  this section ([Export Denote notes]).


  [Export Denote notes] See section 15.16


◊ 15.16.1.2 Automatically store Org exports in another folder

  It is possible to automatically place all exports in another folder by
  making Org’s function `org-export-output-file-name' create the target
  directory if needed and move the exported file there.  Remember that
  advising Elisp code must be handled with care, as it might break the
  original function in subtle ways.

  ┌────
  │ (defvar my-org-export-output-directory-prefix "./export_"
  │   "Prefix of directory used for org-mode export.
  │ 
  │ The single dot means that the directory is created on the same
  │ level as the one where the Org file that performs the exporting
  │ is.  Use two dots to place the directory on a level above the
  │ current one.
  │ 
  │ If this directory is part of `denote-directory', make sure it is
  │ not read by Denote.  See `denote-excluded-directories-regexp'.
  │ This way there will be no known duplicate Denote identifiers
  │ produced by the Org export mechanism.")
  │ 
  │ (defun my-org-export-create-directory (fn extension &rest args)
  │   "Move Org export file to its appropriate directory.
  │ 
  │ Append the file type EXTENSION of the exported file to
  │ `my-org-export-output-directory-prefix' and, if absent, create a
  │ directory named accordingly.
  │ 
  │ Install this as advice around `org-export-output-file-name'.  The
  │ EXTENSION is supplied by that function.  ARGS are its remaining
  │ arguments."
  │   (let ((export-dir (format "%s%s" my-org-export-output-directory-prefix extension)))
  │     (unless (file-directory-p export-dir)
  │       (make-directory export-dir)))
  │   (apply fn extension args))
  │ 
  │ (advice-add #'org-export-output-file-name :around #'my-org-export-create-directory)
  └────

  The target export directory should not be a subdirectory of
  `denote-directory', as that will result in duplicate identifiers.
  Exclude it with the `denote-excluded-directories-regexp' user option
  ([Exclude certain directories from all operations]).

  [ NOTE: I (Protesilaos) am not a LaTeX user and cannot test the
    following. ]

  Using a different directory will require some additional configuration
  when exporting using LaTeX.  The export folder cannot be inside the
  path of the `denote-directory' to prevent Denote from recognising it
  as an attachment:
  <https://emacs.stackexchange.com/questions/45751/org-export-to-different-directory>.


  [Exclude certain directories from all operations] See section 3.9


◊ 15.16.1.3 Org Mode Publishing

  Org Mode also has a publishing tool for exporting a collection of
  files. Some user might apply this approach to convert their note
  collection to a public or private website.

  The `org-publish-project-alist' variable drives the publishing
  process, including the publishing directory.

  The publishing directory should not be a subdirectory of
  `denote-directory', as that will result in duplicate identifiers.
  Exclude it with the `denote-excluded-directories-regexp' user option
  ([Exclude certain directories from all operations]).


  [Exclude certain directories from all operations] See section 3.9


15.16.2 Export Denote notes with Markdown
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Exporting from Markdown requires an external processor (e.g.,
  Markdown.pl, Pandoc, or MultiMarkdown).  The `markdown-command'
  variable defines the command line used in export, for example:

  ┌────
  │ (setq markdown-command "multimarkdown")
  └────

  The export process thus occurs outside of Emacs.  Users need to read
  the documentation of their preferred processor to prevent the creation
  of duplicate Denote identifiers.


16 Installation
═══════════════




16.1 GNU ELPA package
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


16.2 Manual installation
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


17 Sample configuration
═══════════════════════

  ┌────
  │ (require 'denote)
  │ 
  │ ;; Remember to check the doc strings of those variables.
  │ (setq denote-directory (expand-file-name "~/Documents/notes/"))
  │ (setq denote-save-buffers nil)
  │ (setq denote-known-keywords '("emacs" "philosophy" "politics" "economics"))
  │ (setq denote-infer-keywords t)
  │ (setq denote-sort-keywords t)
  │ (setq denote-file-type nil) ; Org is the default, set others here
  │ (setq denote-prompts '(title keywords))
  │ (setq denote-excluded-directories-regexp nil)
  │ (setq denote-excluded-keywords-regexp nil)
  │ (setq denote-rename-confirmations '(rewrite-front-matter modify-file-name))
  │ 
  │ ;; Pick dates, where relevant, with Org's advanced interface:
  │ (setq denote-date-prompt-use-org-read-date t)
  │ 
  │ 
  │ ;; Read this manual for how to specify `denote-templates'.  We do not
  │ ;; include an example here to avoid potential confusion.
  │ 
  │ 
  │ (setq denote-date-format nil) ; read doc string
  │ 
  │ ;; By default, we do not show the context of links.  We just display
  │ ;; file names.  This provides a more informative view.
  │ (setq denote-backlinks-show-context t)
  │ 
  │ ;; Also see `denote-backlinks-display-buffer-action' which is a bit
  │ ;; advanced.
  │ 
  │ ;; If you use Markdown or plain text files (Org renders links as buttons
  │ ;; right away)
  │ (add-hook 'text-mode-hook #'denote-fontify-links-mode-maybe)
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
  │ 
  │ ;; Automatically rename Denote buffers using the `denote-rename-buffer-format'.
  │ (denote-rename-buffer-mode 1)
  │ 
  │ ;; Denote DOES NOT define any key bindings.  This is for the user to
  │ ;; decide.  For example:
  │ (let ((map global-map))
  │   (define-key map (kbd "C-c n n") #'denote)
  │   (define-key map (kbd "C-c n c") #'denote-region) ; "contents" mnemonic
  │   (define-key map (kbd "C-c n N") #'denote-type)
  │   (define-key map (kbd "C-c n d") #'denote-date)
  │   (define-key map (kbd "C-c n z") #'denote-signature) ; "zettelkasten" mnemonic
  │   (define-key map (kbd "C-c n s") #'denote-subdirectory)
  │   (define-key map (kbd "C-c n t") #'denote-template)
  │   ;; If you intend to use Denote with a variety of file types, it is
  │   ;; easier to bind the link-related commands to the `global-map', as
  │   ;; shown here.  Otherwise follow the same pattern for `org-mode-map',
  │   ;; `markdown-mode-map', and/or `text-mode-map'.
  │   (define-key map (kbd "C-c n i") #'denote-link) ; "insert" mnemonic
  │   (define-key map (kbd "C-c n I") #'denote-add-links)
  │   (define-key map (kbd "C-c n b") #'denote-backlinks)
  │   (define-key map (kbd "C-c n f f") #'denote-find-link)
  │   (define-key map (kbd "C-c n f b") #'denote-find-backlink)
  │   ;; Note that `denote-rename-file' can work from any context, not just
  │   ;; Dired bufffers.  That is why we bind it here to the `global-map'.
  │   (define-key map (kbd "C-c n r") #'denote-rename-file)
  │   (define-key map (kbd "C-c n R") #'denote-rename-file-using-front-matter))
  │ 
  │ ;; Key bindings specifically for Dired.
  │ (let ((map dired-mode-map))
  │   (define-key map (kbd "C-c C-d C-i") #'denote-link-dired-marked-notes)
  │   (define-key map (kbd "C-c C-d C-r") #'denote-dired-rename-files)
  │   (define-key map (kbd "C-c C-d C-k") #'denote-dired-rename-marked-files-with-keywords)
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
  │ 
  │ 
  │ ;; If you want to have Denote commands available via a right click
  │ ;; context menu, use the following and then enable
  │ ;; `context-menu-mode'.
  │ (add-hook 'context-menu-functions #'denote-context-menu)
  └────


18 For developers or advanced users
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

  Variable `denote-signature-regexp'
        Regular expression to match the `SIGNATURE' field in a file
        name.

  Variable `denote-title-regexp'
        Regular expression to match the `TITLE' field in a file name
        ([The file-naming scheme]).

  Variable `denote-keywords-regexp'
        Regular expression to match the `KEYWORDS' field in a file name
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

  Function `denote-identifier-p'
        Return non-nil if `IDENTIFIER' string is a Denote identifier.

  Function `denote-file-is-note-p'
        Return non-nil if `FILE' is an actual Denote note. For our
        purposes, a note must satisfy `file-regular-p' and
        `denote-filename-is-note-p'.

  Function `denote-file-has-identifier-p'
        Return non-nil if `FILE' has a Denote identifier.

  Function `denote-file-has-signature-p'
        Return non-nil if `FILE' has a signature.

  Function `denote-file-has-supported-extension-p'
        Return non-nil if `FILE' has supported extension.  Also account
        for the possibility of an added `.gpg' suffix. Supported
        extensions are those implied by `denote-file-type'.

  Function `denote-file-is-writable-and-supported-p'
        Return non-nil if `FILE' is writable and has supported
        extension.

  Function `denote-file-type-extensions'
        Return all file type extensions in `denote-file-types'.

  Variable `denote-encryption-file-extensions'
        List of strings specifying file extensions for encryption.

  Function `denote-file-type-extensions-with-encryption'
        Derive `denote-file-type-extensions' plus
        `denote-encryption-file-extensions'.

  Function `denote-get-file-extension'
        Return extension of `FILE' with dot included.  Account for
        `denote-encryption-file-extensions'.  In other words, return
        something like `.org.gpg' if it is part of the file, else return
        `.org'.

  Function `denote-get-file-extension-sans-encryption'
        Return extension of `FILE' with dot included and without the
        encryption part.  Build on top of `denote-get-file-extension'
        though always return something like `.org' even if the actual
        file extension is `.org.gpg'.

  Function `denote-keywords'
        Return appropriate list of keyword candidates.  If
        `denote-infer-keywords' is non-nil, infer keywords from existing
        notes and combine them into a list with `denote-known-keywords'.
        Else use only the latter set of keywords ([Standard note
        creation]).

  Function `denote-keywords-sort'
        Sort `KEYWORDS' if `denote-sort-keywords' is non-nil.
        `KEYWORDS' is a list of strings, per `denote-keywords-prompt'.

  Function `denote-keywords-combine'
        Combine `KEYWORDS' list of strings into a single
        string. Keywords are separated by the underscore character, per
        the Denote file-naming scheme.

  Function `denote-valid-date-p'
        Return `DATE' as a valid date. A valid `DATE' is a value that
        can be parsed by either `decode-time' or `date-to-time' .Those
        functions signal an error if `DATE' is a value they do not
        recognise. If `DATE' is nil, return nil.

  Function `denote-parse-date'
        Return `DATE' as an appropriate value for the `denote'
        command. Pass `DATE' through `denote-valid-date-p' and use its
        return value. If either that or `DATE' is nil, return
        `current-time'.

  Function `denote-directory'
        Return path of the variable `denote-directory' as a proper
        directory, also because it accepts a directory-local value for
        what we internally refer to as “silos” ([Maintain separate
        directories for notes]).  Custom Lisp code can `let' bind the
        value of the variable `denote-directory' to override what this
        function returns.

  Function `denote-directory-files'
        Return list of absolute file paths in variable
        `denote-directory'. Files that match
        `denote-excluded-files-regexp' are excluded from the list. Files
        only need to have an identifier. The return value may thus
        include file types that are not implied by
        `denote-file-type'. With optional `FILES-MATCHING-REGEXP',
        restrict files to those matching the given regular
        expression. With optional `OMIT-CURRENT' as a non-nil value, do
        not include the current Denote file in the returned list. With
        optional `TEXT-ONLY' as a non-nil value, limit the results to
        text files that satisfy `denote-file-is-note-p'.

  Function `denote-directory-subdirectories'
        Return list of subdirectories in variable
        `denote-directory'. Omit dotfiles (such as .git)
        unconditionally.  Also exclude whatever matches
        `denote-excluded-directories-regexp'.  Note that the
        `denote-directory' accepts a directory-local value for what we
        call “silos” ([Maintain separate directories for notes]).

  Function `denote-file-name-relative-to-denote-directory'
        Return name of `FILE' relative to the variable
        `denote-directory'.  `FILE' must be an absolute path.

  Function `denote-get-path-by-id'
        Return absolute path of `ID' string in `denote-directory-files'.

  Function `denote-get-identifier-at-point'
        Return the identifier at point or `POINT'.

  Function `denote-slug-keep-only-ascii'
        Remove all non-ASCII characters from `STR' and replace them with
        spaces. This is useful as a helper function to construct
        `denote-file-name-slug-functions' ([Custom sluggification to
        remove non-ASCII characters]).

  Function `denote-sluggify'
        Make `STR' an appropriate slug for file name `COMPONENT'
        ([Sluggification of file name components]).  Apply the function
        specified in `denote-file-name-slug-function' to `COMPONENT'
        which is one of `title', `signature', `keyword'. If the
        resulting string still contains consecutive `-',=_= or `=', they
        are replaced by a single occurence of the character, if
        necessary according to `COMPONENT'. If `COMPONENT' is `keyword',
        remove underscores from `STR' as they are used as the keywords
        separator in file names.

  Function `denote-sluggify-keyword'
        Sluggify `STR' while joining separate words.

  Function `denote-sluggify-signature'
        Make `STR' an appropriate slug for signatures ([Sluggification
        of file name components]).

  Function `denote-sluggify-keywords'
        Sluggify `KEYWORDS', which is a list of strings ([Sluggification
        of file name components]).

  Function `denote-filetype-heuristics'
        Return likely file type of `FILE'. If in the process of
        `org-capture', consider the file type to be that of
        Org. Otherwise, use the file extension to detect the file type
        of `FILE'.

        If more than one file type correspond to this file extension,
        use the first file type for which the :title-key-regexp in
        `denote-file-types' matches in the file.

        Return nil if the file type is not recognized.

  Function `denote-use-date'
        The date to be used in a note creation command. See the
        documentation of `denote' for acceptable values.  This variable
        is ignored if nil. Only ever `let' bind this, otherwise the
        title will always be the same and the title prompt will be
        skipped.

  Function `denote-use-directory'
        The directory to be used in a note creation command. See the
        documentation of `denote' for acceptable values. This variable
        is ignored if nil. Only ever `let' bind this, otherwise the
        title will always be the same and the title prompt will be
        skipped.

  Function `denote-use-file-type'
        The file type to be used in a note creation command. See the
        documentation of `denote' for acceptable values. This variable
        is ignored if nil. Only ever `let' bind this, otherwise the
        title will always be the same and the title prompt will be
        skipped.

  Function `denote-use-keywords'
        The keywords to be used in a note creation command. See the
        documentation of `denote' for acceptable values. This variable
        is ignored if nil. Only ever `let' bind this, otherwise the
        title will always be the same and the title prompt will be
        skipped.

  Function `denote-use-signature'
        The signature to be used in a note creation command. See the
        documentation of `denote' for acceptable values. This variable
        is ignored if nil. Only ever `let' bind this, otherwise the
        title will always be the same and the title prompt will be
        skipped.

  Function `denote-use-template'
        The template to be used in a note creation command. See the
        documentation of `denote' for acceptable values. This variable
        is ignored if nil. Only ever `let' bind this, otherwise the
        title will always be the same and the title prompt will be
        skipped.

  Function `denote-use-title'
        The title to be used in a note creation command. See the
        documentation of `denote' for acceptable values. This variable
        is ignored if nil. Only ever `let' bind this, otherwise the
        title will always be the same and the title prompt will be
        skipped.

  Function `denote-format-file-name'
        Format file name. `DIR-PATH', `ID', `KEYWORDS', `TITLE',
        `EXTENSION' and `SIGNATURE' are expected to be supplied by
        `denote' or equivalent command.

        `DIR-PATH' is a string pointing to a directory. It ends with a
        forward slash (the function `denote-directory' makes sure this
        is the case when returning the value of the variable
        `denote-directory').  `DIR-PATH' cannot be nil or an empty
        string.

        `ID' is a string holding the identifier of the note. It cannot
        be nil or an empty string and must match `denote-id-regexp'.

        `DIR-PATH' and `ID' form the base file name.

        `KEYWORDS' is a list of strings that is reduced to a single
        string by `denote-keywords-combine'. `KEYWORDS' can be an empty
        list or a nil value, in which case the relevant file name
        component is not added to the base file name.

        `TITLE' and `SIGNATURE' are strings. They can be an empty
        string, in which case their respective file name component is
        not added to the base file name.

        `EXTENSION' is a string that contains a dot followed by the file
        type extension. It can be an empty string or a nil value, in
        which case it is not added to the base file name.

  Function `denote-extract-keywords-from-path'
        Extract keywords from `PATH' and return them as a list of
        strings.  `PATH' must be a Denote-style file name where keywords
        are prefixed with an underscore.  If `PATH' has no such
        keywords, which is possible, return nil ([The file-naming
        scheme]).

  Function `denote-extract-id-from-string'
        Return existing Denote identifier in `STRING', else nil.

  Function `denote-retrieve-filename-identifier'
        Extract identifier from `FILE' name, if present, else return
        nil.  To create a new one, refer to the
        `denote-create-unique-file-identifier' function.

  Function `denote-retrieve-filename-title'
        Extract Denote title component from `FILE' name, if present,
        else return nil.

  Function `denote-retrieve-filename-keywords'
        Extract keywords from `FILE' name, if present, else return
        nil. Return matched keywords as a single string.

  Function `denote-retrieve-filename-signature'
        Extract signature from `FILE' name, if present, else return nil.

  Function `denote-retrieve-title-or-filename'
        Return appropriate title for `FILE' given its `TYPE'. This is a
        wrapper for `denote-retrieve-front-matter-title-value' and
        `denote-retrieve-filename-title'.

  Function `denote-get-identifier'
        Convert `DATE' into a Denote identifier using
        `denote-id-format'. `DATE' is parsed by
        `denote-valid-date-p'. If `DATE' is nil, use the current time.

  Function `denote-create-unique-file-identifier'
        Create a new unique `FILE' identifier.  Test that the identifier
        is unique among `USED-IDS'.  The conditions are as follows:

        • If `DATE' is non-nil, invoke
          `denote-prompt-for-date-return-id'.

        • If `DATE' is nil, use the file attributes to determine the
          last modified date and format it as an identifier.

        • As a fallback, derive an identifier from the current time.

        With optional `USED-IDS' as nil, test that the identifier is
        unique among all files and buffers in variable
        `denote-directory'.

        To only return an existing identifier, refer to the function
        `denote-retrieve-filename-identifier'.

  Function `denote-retrieve-front-matter-title-value'
        Return title value from `FILE' front matter per `FILE-TYPE'.

  Function `denote-retrieve-front-matter-title-line'
        Return title line from `FILE' front matter per `FILE-TYPE'.

  Function `denote-retrieve-front-matter-keywords-value'
        Return keywords value from `FILE' front matter per
        `FILE-TYPE'. The return value is a list of strings.

  Function `denote-retrieve-front-matter-keywords-line'
        Return keywords line from `FILE' front matter per `FILE-TYPE'.

  Function `denote-add-prompts'
        Add list of `ADDITIONAL-PROMPTS' to `denote-prompts'. This is
        best done inside of a `let' to create a wrapper function around
        `denote', `denote-rename-file', and generally any command that
        consults the value of `denote-prompts'.

  Function `denote-signature-prompt'
        Prompt for signature string.  With optional `INITIAL-SIGNATURE'
        use it as the initial minibuffer text. With optional
        `PROMPT-TEXT' use it in the minibuffer instead of the default
        prompt. Previous inputs at this prompt are available for
        minibuffer completion if the user option
        `denote-history-completion-in-prompts' is set to a non-nil value
        ([The `denote-history-completion-in-prompts' option]).

  Function `denote-file-prompt'
        Prompt for file in variable `denote-directory'. Files that match
        `denote-excluded-files-regexp' are excluded from the list. With
        optional `FILES-MATCHING-REGEXP', filter the candidates per the
        given regular expression. With optional `PROMPT-TEXT', use it
        instead of the default call to select a file. With optional
        `NO-REQUIRE-MATCH' accept the given input as-is. Return the
        absolute path to the matching file.

  Function `denote-keywords-prompt'
        Prompt for one or more keywords.  Read entries as separate when
        they are demarcated by the `crm-separator', which typically is a
        comma. With optional `PROMPT-TEXT', use it to prompt the user
        for keywords. Else use a generic prompt. With optional
        `INITIAL-KEYWORDS' use them as the initial minibuffer text.

  Function `denote-title-prompt'
        Prompt for title string. With optional `INITIAL-TITLE' use it as
        the initial minibuffer text. With optional `PROMPT-TEXT' use it
        in the minibuffer instead of the default prompt. Previous inputs
        at this prompt are available for minibuffer completion if the
        user option `denote-history-completion-in-prompts' is set to a
        non-nil value ([The `denote-history-completion-in-prompts'
        option]).

  Variable `denote-title-prompt-current-default'
        Currently bound default title for `denote-title-prompt'.  Set
        the value of this variable within the lexical scope of a command
        that needs to supply a default title before calling
        `denote-title-prompt' and use `unwind-protect' to set its value
        back to nil.

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

  Function `denote-command-prompt'
        Prompt for command among `denote-commands-for-new-notes'
        ([Points of entry]).

  Variable `denote-prompts-with-history-as-completion'
        Prompts that conditionally perform completion against their
        history. These are minibuffer prompts that ordinarily accept a
        free form string input, as opposed to matching against a
        predefined set. These prompts can optionally perform completion
        against their own minibuffer history when the user option
        `denote-history-completion-in-prompts' is set to a non-nil value
        ([The `denote-history-completion-in-prompts' option]).

  Function `denote-files-matching-regexp-prompt'
        Prompt for `REGEXP' to filter Denote files by. With optional
        `PROMPT-TEXT' use it instead of a generic prompt.

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
        Prompt to rename file named `OLD-NAME' to `NEW-NAME'. If
        `denote-rename-confirmations' does not contain
        `modify-file-name', return t without prompting.

  Function `denote-rename-file-and-buffer'
        Rename file named `OLD-NAME' to `NEW-NAME', updating buffer
        name.

  Function `denote-rewrite-front-matter'
        Rewrite front matter of note after `denote-rename-file' (or
        related) The `FILE', `TITLE', `KEYWORDS', and `FILE-TYPE'
        arguments are given by the renaming command and are used to
        construct new front matter values if appropriate. If
        `denote-rename-confirmations' contains `rewrite-front-matter',
        prompt to confirm the rewriting of the front matter. Otherwise
        produce a `y-or-n-p' prompt to that effect.

  Function `denote-add-front-matter-prompt'
        Prompt to add a front-matter to `FILE'. Return non-nil if a new
        front matter should be added. If `denote-rename-confirmations'
        does not contain `add-front-matter', return t without prompting.

  Function `denote-rewrite-keywords'
        Rewrite `KEYWORDS' in `FILE' outright according to
        `FILE-TYPE'. Do the same as `denote-rewrite-front-matter' for
        keywords, but do not ask for confirmation. With optional
        `SAVE-BUFFER', save the buffer corresponding to `FILE'. This
        function is for use in the commands `denote-keywords-add',
        `denote-keywords-remove', `denote-dired-rename-files', or
        related.

  Function `denote-update-dired-buffers'
        Update Dired buffers of variable `denote-directory'. Also revert
        the current Dired buffer even if it is not inside the
        `denote-directory'. Note that the `denote-directory' accepts a
        directory-local value for what we internally refer to as “silos”
        ([Maintain separate directories for notes]).

  Variable `denote-file-types'
        Alist of `denote-file-type' and their format properties.

        Each element is of the form `(SYMBOL PROPERTY-LIST)'.  `SYMBOL'
        is one of those specified in `denote-file-type' or an arbitrary
        symbol that defines a new file type.

        `PROPERTY-LIST' is a plist that consists of the following
        elements:

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

  Function `denote-format-string-for-org-front-matter'
        Return string `S' as-is for Org or plain text front matter. If
        `S' is not a string, return an empty string.

  Function `denote-format-string-for-md-front-matter'
        Surround string `S' with quotes. If `S' is not a string, return
        a literal emptry string. This can be used in `denote-file-types'
        to format front mattter.

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

  Function `denote-select-linked-file-prompt'
        Prompt for linked file among `FILES'.

  Function `denote-link-return-links'
        Return list of links in current or optional `FILE'.  Also see
        `denote-link-return-backlinks'.

  Function `denote-link-return-backlinks'
        Return list of backlinks in current or optional `FILE'.  Also
        see `denote-link-return-links'.

  Variable `denote-link-signature-format'
        Format of link description for `denote-link-with-signature'.

  Function `denote-link-description-with-signature-and-title'
        Return link description for `FILE'.  Produce a description as
        follows:


        If the region is active, use it as the description.


        If `FILE' as a signature, then use the
        `denote-link-signature-format'.  By default, this looks like
        “signature title”.


        If `FILE' does not have a signature, then use its title as the
        description.

  Variable `denote-link-description-function'
        Function to use to create the description of links. The function
        specified should take a `FILE' argument and should return the
        description as a string. By default, the title of the file is
        returned as the description.


[The file-naming scheme] See section 5

[Standard note creation] See section 3.1

[Maintain separate directories for notes] See section 3.7

[Custom sluggification to remove non-ASCII characters] See section 5.3.1

[Sluggification of file name components] See section 5.2

[The `denote-history-completion-in-prompts' option] See section 3.1.2

[The denote-date-prompt-use-org-read-date option] See section 3.1.7

[Points of entry] See section 3

[Change the front matter format] See section 6.1


19 Troubleshoot Denote in a pristine environment
════════════════════════════════════════════════

  Sometimes we get reports on bugs that may not be actually caused by
  some error in the Denote code base.  To help gain insight into what
  the problem is, we need to be able to reproduce the issue in a minimum
  viable system.  Below is one way to achieve this.

  1. Find where your `denote.el' file is stored on your filesystem.

  2. Assuming you have already installed the package, one way to do this
     is to invoke `M-x find-library' and search for `denote'.  It will
     take you to the source file.  There do `M-x eval-expression', which
     will bring up a minibuffer prompt.  At the prompt evaluate:

  ┌────
  │ (kill-new (expand-file-name (buffer-file-name)))
  └────

  1. The above will save the full file system path to your kill ring.

  2. In a terminal emulator or an `M-x shell' buffer execute:

  ┌────
  │ emacs -Q
  └────

  1. This will open a new instance of Emacs in a pristine environment.
     Only the default settings are loaded.

  2. In the `*scratch*' buffer of `emacs -Q', add your configurations
     like the following and try to reproduce the issue:

  ┌────
  │ (require 'denote "/full/path/to/what/you/got/denote.el")
  │ 
  │ ;; Your configurations here
  └────

  Then try to see if your problem still occurs.  If it does, then the
  fault is with Denote.  Otherwise there is something external to it
  that we need to account for.  Whatever the case, this exercise helps
  us get a better sense of the specifics.


20 Contributing
═══════════════

  Denote is a GNU ELPA package. As such, any significant change to the
  code requires copyright assignment to the Free Software Foundation
  (more below).

  You do not need to be a programmer to contribute to this package.
  Sharing an idea or describing a workflow is equally helpful, as it
  teaches us something we may not know and might be able to cover either
  by extending Denote or expanding this manual. If you prefer to write a
  blog post, make sure you share it with us: we can add a section herein
  referencing all such articles. Everyone gets acknowledged
  ([Acknowledgements]). There is no such thing as an “insignificant
  contribution”—they all matter.

  ⁃ Package name (GNU ELPA): `denote'
  ⁃ Official manual: <https://protesilaos.com/emacs/denote>
  ⁃ Change log: <https://protesilaos.com/emacs/denote-changelog>
  ⁃ Git repositories:
    ⁃ GitHub: <https://github.com/protesilaos/denote>
    ⁃ GitLab: <https://gitlab.com/protesilaos/denote>

  If our public media are not suitable, you are welcome to contact me
  (Protesilaos) in private: <https://protesilaos.com/contact>.

  Copyright assignment is a prerequisite to sharing code. It is a simple
  process. Check the request form below (please adapt it accordingly).
  You must write an email to the address mentioned in the form and then
  wait for the FSF to send you a legal agreement. Sign the document and
  file it back to them. This could all happen via email and take about a
  week. You are encouraged to go through this process. You only need to
  do it once. It will allow you to make contributions to Emacs in
  general.

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


[Acknowledgements] See section 24

20.1 Wishlist of what we can do to extend Denote
────────────────────────────────────────────────

  These are various ideas to extend Denote. Whether they should be in
  the core package or a separate extension is something we can discuss.
  I, Protesilaos, am happy to help anyone who wants to do any of this.

  denote-consult.el
        This can be a separate package that enhances or replaces the
        various prompts we have for files (and maybe more) by using the
        `consult' package. Consult provides the preview mechanism and
        can probably be used for more things, such as to define a source
        for Denote-only buffers in the `consult-buffer' command. If we
        need to tweak things in `denote.el', I am happy to do it. For
        example, we could have a `denote-file-prompt-function' variable,
        which would default to `denote-file-prompt' (what we currently
        have) and would also such a hypothetical package to easily plug
        into what we have.

  denote-embark.el
        Provide integration with the `embark' package.  This can be for
        doing something with the identifier/link at point.  For example,
        it could provide an action to produce backlinks for the
        identifier/file we are linking to, not just the current one.

  denote-transient.el
        The `transient' package is built into Emacs 29 (Denote supports
        Emacs 28 though). We can use it to define an alternative to what
        we have for the menu bar. Perhaps this interface can used to
        toggle various options, such as to call `denote' with a
        different set of prompts.

  A `denote-directories' user option
        This can be either an extension of the `denote-directory'
        (accept a list of file paths value) or a new variable. The idea
        is to let the user define separate Denote directories which do
        know about the presence of each other (unlike silos). This way,
        a user can have an entry in `~/Documents/notes/' link to
        something `~/Git/projects/' and everything work as if the
        `denote-directory' is set to the `~/' (with the status quo as of
        2024-02-18 08:27 +0200).

  Signatures before identifiers
        This is probably going to increase the complixity of `denote.el'
        and may not be worth pursuing. But just to explore the idea: we
        could have an option to rearrange file names such that the
        signature appears before the identifier. If we can do this in a
        smart way, we can probably extend the principle for all file
        name components. Again though, this may be too complex and not
        worth doing.

  Encode the day in the identifier
        The idea is to use some coded reference for Monday, Tuesday,
        etc. instead of having the generic `T' in the identifier. For
        example, Monday is `A' so the identifier for it is something
        like `20240219A101522' instead of what we now have as
        `20240219T101522'. The old method should still be supported.
        Apart from changing a few regular expressions, this does not
        seem too complex to me. We would need a user option to opt in to
        such a feature. Then tweak the relevant parts. The tricky issue
        is to define a mapping of day names to letters/symbols that
        works for everyone. Do all countries have a seven-day week, for
        example? We need something universally applicable here.

  Anything else? You are welcome to discuss these and/or add to the
  list.


21 Publications about Denote
════════════════════════════

  The Emacs community is putting Denote to great use.  This section
  includes publications that show how people configure their note-taking
  setup.  If you have a blog post, video, or configuration file about
  Denote, feel welcome to tell us about it ([Contributing]).

  ⁃ David Wilson (SystemCrafters): /Generating a Blog Site from Denote
    Entries/, 2022-09-09, <https://www.youtube.com/watch?v=5R7ad5xz5wo>

  ⁃ David Wilson (SystemCrafters): /Trying Out Prot’s Denote, an Org
    Roam Alternative?/, 2022-07-15,
    <https://www.youtube.com/watch?v=QcRY_rsX0yY>

  ⁃ Jack Baty: /Keeping my Org Agenda updated based on Denote keywords/,
    2022-11-30, <https://baty.net/2022/keeping-my-org-agenda-updated>

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

  ⁃ Mohamed Suliman: /Managing a bibliography of BiBTeX entries with
    Denote/, 2022-12-20,
    <https://www.scss.tcd.ie/~sulimanm/posts/denote-bibliography.html>

  ⁃ Peter Prevos: /Simulating Text Files with R to Test the Emacs Denote
    Package/, 2022-07-28,
    <https://lucidmanager.org/productivity/testing-denote-package/>

  ⁃ Peter Prevos: /Emacs Writing Studio/, 2023-10-19. A configuration
    for authors, using Denote for taking notes, literature reviews and
    manage collections of images:
    • <https://lucidmanager.org/productivity/taking-notes-with-emacs-denote/>
    • <https://lucidmanager.org/productivity/denote-explore/>
    • <https://lucidmanager.org/productivity/bibliographic-notes-in-emacs-with-citar-denote/>
    • <https://lucidmanager.org/productivity/using-emacs-image-dired/>

  ⁃ Stefan Thesing: /Denote as a Zettelkasten/, 2023-03-02,
    <https://www.thesing-online.de/blog/denote-as-a-zettelkasten>

  ⁃ Summer Emacs: /An explanation of how I use Emacs/, 2023-05-04,
    <https://github.com/summeremacs/howiuseemacs/blob/main/full-explanation-of-how-i-use-emacs.org>


[Contributing] See section 20


22 Alternatives to Denote
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

22.1 Alternative implementations and further reading
────────────────────────────────────────────────────

  This section covers blog posts and implementations from the Emacs
  community about the topic of note-taking and file organization.  They
  may refer to some of the packages covered in the previous section or
  provide their custom code ([Alternatives to Denote]).  The list is
  unsorted.

  ⁃ José Antonio Ortega Ruiz (aka “jao”) explains a note-taking method
    that is simple like Denote but differs in other ways.  An
    interesting approach overall:
    <https://jao.io/blog/simple-note-taking.html>.

  ⁃ Jethro Kuan (the main `org-roam' developer) explains their
    note-taking techniques:
    <https://jethrokuan.github.io/org-roam-guide/>.  Good ideas all
    round, regardless of the package/code you choose to use.

  ⁃ Karl Voit’s tools [date2name], [filetags], [appendfilename], and
    [move2archive] provide a Python-based implementation to organize
    individual files which do not require Emacs.  His approach ([blog
    post] and his [presentation at GLT18]) has been complemented by
    [memacs] to process e.g., the date of creation of photographs, or
    the log of a phone call in a format compatible to org.

  [ Development note: help expand this list. ]


[Alternatives to Denote] See section 22

[date2name] <https://github.com/novoid/date2name>

[filetags] <https://github.com/novoid/filetags/>

[appendfilename] <https://github.com/novoid/appendfilename/>

[move2archive] <https://github.com/novoid/move2archive>

[blog post] <https://karl-voit.at/managing-digital-photographs/>

[presentation at GLT18] <https://www.youtube.com/watch?v=rckSVmYCH90>

[memacs] <https://github.com/novoid/memacs>


23 Frequently Asked Questions
═════════════════════════════

  I (Protesilaos) answer some questions I have received or might get.
  It is assumed that you have read the rest of this manual: I will not
  go into the specifics of how Denote works.


23.1 Why develop Denote when PACKAGE already exists?
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


23.2 Why not rely exclusively on Org?
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


23.3 Why care about Unix tools when you use Emacs?
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


23.4 Why many small files instead of few large ones?
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


23.5 Does Denote perform well at scale?
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


23.6 I add TODOs to my notes; will many files slow down the Org agenda?
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


[Contributing] See section 20


23.7 I want to sort by last modified in Dired, why won’t Denote let me?
───────────────────────────────────────────────────────────────────────

  Denote does not control how Dired sorts files. I encourage you to read
  the manpage of the `ls' executable. It will help you in general, while
  it applies to Emacs as well via Dired. The gist is that you can update
  the `ls' flags that Dired uses on-the-fly: type `C-u M-x
  dired-sort-toggle-or-edit' (`C-u s' by default) and append
  `--sort=time' at the prompt. To reverse the order, add the `-r' flag.
  The user option `dired-listing-switches' sets your default preference.

  For an on-demand sorted and filtered Dired listing of Denote files,
  use the command `denote-sort-dired' ([Sort files by component]).


[Sort files by component] See section 12


23.8 How do you handle the last modified case?
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


23.9 Why are some Org links opening outside Emacs?
──────────────────────────────────────────────────

  Org has its own mechanism to determine how best to open a link. This
  affects the `file:' link type, but also the `denote:' one (which is
  designed to be as close to `file:' as possible).

  When following a link, Org usually displays the data in an Emacs
  buffer, though it might launch an external application instead. The
  idea is to use a specialised program when that is relevant, such as to
  display a video. Though there can be scenaria the user does not like,
  such as when Org decides to load `.md' or `.html' files with an
  external app. To compound the problem, users can name any file type
  using the Denote file-naming scheme, including images, PDFs, videos,
  and more ([Renaming files]).

  To instruct Org to stay in Emacs for such cases, the user needs to
  modify the variable `org-file-apps', which is not specific to Denote.
  As one use-case, `org-file-apps' associates a regular expression to
  match file names with a method on how to display them (do `M-x
  describe-variable' and then search for `org-file-apps' to read its
  documentation). Thus, the user can use something like the following in
  their Org or Denote configuration:

  ┌────
  │ ;; Tell Org to use Emacs when opening files that end in .md
  │ (add-to-list 'org-file-apps '("\\.md\\'" . emacs))
  │ 
  │ ;; Do the same for .html
  │ (add-to-list 'org-file-apps '("\\.html\\'" . emacs))
  └────

  Each of these adds a new entry to the existing value of that user
  option. Replace `md' or `html' with the desired file type extension.


[Renaming files] See section 4


23.10 Speed up backlinks’ buffer creation?
──────────────────────────────────────────

  Denote leverages the built-in `xref' library to search for the
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


23.11 Why do I get “Search failed with status 1” when I search for backlinks?
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


23.12 Why do I get a double `#+title' in Doom Emacs?
────────────────────────────────────────────────────

  Doom Emacs provides a set of bespoke templates for Org. One of those
  prefills any new Org file with a `#+title' field. So when Denote
  creates a new Org file and inserts front matter to it, it inevitably
  adds an extra title to the existing one.

  This is not a Denote problem. We can only expect a new file to be
  empty by default. Check how to disable the relevant module in your
  Doom Emacs configuration file.


24 Acknowledgements
═══════════════════

  Denote is meant to be a collective effort.  Every bit of help matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to code or the manual
        Abdul-Lateef Haji-Ali, Abin Simon, Adam Růžička, Alan Schmitt,
        Alexandre Rousseau, Ashton Wiersdorf, Benjamin Kästner, Bruno
        Boal, Charanjit Singh, Clemens Radermacher, Colin McLear, Damien
        Cassou, Eduardo Grajeda, Elias Storms, Eshel Yaron, Florian,
        Glenna D., Graham Marlow, Hilde Rhyne, Ivan Sokolov, Jack Baty,
        Jakub Szczerbowski, Jean-Charles Bagneris, Jean-Philippe Gagné
        Guay, Jianwei Hou, Joseph Turner, Jürgen Hötzel, Kaushal Modi,
        Kai von Fintel, Kostas Andreadis, Kristoffer Balintona, Kyle
        Meyer, Marc Fargas, Matthew Lemon, Noboru Ota (nobiot), Norwid
        Behrnd, Peter Prevos, Philip Kaludercic, Quiliro Ordóñez,
        Stephen R. Kifer, Stefan Monnier, Stefan Thesing, Thibaut
        Benjamin, Tomasz Hołubowicz, Vedang Manerikar, Wesley Harvey,
        Zhenxu Xu, arsaber101, bryanrinders, ezchi, jarofromel, leinfink
        (Henrik), l-o-l-h (Lincoln), mattyonweb, maxbrieiev,
        mentalisttraceur, pmenair, relict007, skissue.

  Ideas and/or user feedback
        Abin Simon, Aditya Yadav, Alan Schmitt, Aleksandr Vityazev, Alex
        Hirschfeld, Alexis Purslane, Alfredo Borrás, Alp Eren Kose,
        Ashton Wiersdorf, Benjamin Kästner, Claudio Migliorelli, Claudiu
        Tănăselia, Colin McLear, Damien Cassou, Elias Storms, Federico
        Stilman, Florian, Frédéric Willem Frank Ehmsen, Glenna D., Guo
        Yong, Hanspeter Gisler Harold Ollivier, Jack Baty, Jay Rajput,
        Jean-Charles Bagneris, Jens Östlund, Jeremy Friesen, Jonathan
        Sahar, Johan Bolmsjö, Jonas Großekathöfer, Jousimies, Juanjo
        Presa, Julian Hoch, Kai von Fintel, Kaushal Modi, Kolmas,
        M. Hadi Timachi, Maikol Solis, Mark Olson, Mirko Hernandez,
        Niall Dooley, Nick Bell, Paul van Gelder, Peter Prevos, Peter
        Smith, Riccardo Giannitrapani, Samuel W. Flint, Sergio Rey,
        Suhail Singh, Shreyas Ragavan, Stefan Thesing, Summer Emacs,
        Sven Seebeck, Taoufik, TJ Stankus, Vick (VicZz), Viktor Haag,
        Vineet C. Kulkarni, Wade Mealing, Yi Liu, Ypot, atanasj, azegas,
        babusri, coherentstate, doolio, duli, drcxd, elge70,
        fingerknight, hpgisler, mentalisttraceur, pRot0ta1p, rbenit68,
        relict007, sienic, skissue, sundar bp, yetanotherfossman,
        zadca123

  Special thanks to Peter Povinec who helped refine the file-naming
  scheme, which is the cornerstone of this project.

  Special thanks to Jean-Philippe Gagné Guay for the numerous
  contributions to the code base.


25 GNU Free Documentation License
═════════════════════════════════


26 Indices
══════════

26.1 Function index
───────────────────


26.2 Variable index
───────────────────


26.3 Concept index
──────────────────
