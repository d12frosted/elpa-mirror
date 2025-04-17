           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             DENOTE-ORG: EXTENSIONS TO BETTER INTEGRATE ORG
                              WITH DENOTE

                          Protesilaos Stavrou
                          info@protesilaos.com
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for the Emacs package called `denote' (or `denote.el'), and
provides every other piece of information pertinent to it.

The documentation furnished herein corresponds to stable version 0.1.0,
released on 2025-04-15.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.2.0-dev.

⁃ Package name (GNU ELPA): `denote-org'
⁃ Official manual: <https://protesilaos.com/emacs/denote-org>
⁃ Git repository: <https://github.com/protesilaos/denote-org>
⁃ Backronym: Denote… Ordinarily Restricts Gyrations.

If you are viewing the README.org version of this file, please note that
the GNU ELPA machinery automatically generates an Info manual out of it.

Table of Contents
─────────────────

1. COPYING
2. Overview
3. Use Org dynamic blocks
.. 1. Org dynamic blocks to insert links
.. 2. The Org dynamic block to insert missing links only
.. 3. The Org dynamic block to insert backlinks
.. 4. Org dynamic block to insert file contents
.. 5. Org dynamic block to insert Org files as headings
4. Create a note from the current Org subtree
5. Insert link to an Org file with a further pointer to a heading
.. 1. Backlinks for Org headings
6. Convert `denote:' links to `file:' links in Org and vice versa
7. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
8. Sample configuration
9. Acknowledgements
10. GNU Free Documentation License
11. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2022-2025 Free Software Foundation, Inc.

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

  The `denote-org' package contains extra features that better integrate
  Denote with Org mode. These used to be available as part of the main
  `denote' package in a file called `denote-org-extras.el', but now live
  in this standalone package to main things easier to maintain and
  understand.

  With `denote-org', users have Org-specific extensions such as dynamic
  blocks, links to headings, and splitting an Org subtree into its own
  standalone file. The following sections cover the technicalities.


3 Use Org dynamic blocks
════════════════════════

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
  reflect on the status of earlier notes (read the Denote manual’s
  section about writing metanotes).

  The Org manual describes the technicalities of Dynamic Blocks.
  Evaluate:

  ┌────
  │ (info "(org) Dynamic Blocks")
  └────


[Org dynamic blocks to insert links or backlinks] See section 3.1

[Org dynamic block to insert file contents] See section 3.4

3.1 Org dynamic blocks to insert links
──────────────────────────────────────

  The `denote-links' block can be inserted at point with the command
  `denote-org-dblock-insert-links' or by manually including the
  following in an Org file:

  ┌────
  │ #+BEGIN: denote-links :regexp "YOUR REGEXP HERE" :not-regexp :excluded-dirs-regexp nil :sort-by-component nil :reverse-sort nil :id-only nil :include-date nil
  │ 
  │ #+END:
  └────


  All the parameters except for `:regexp' are optional.

  The `denote-links' block is also registered as an option for the
  command `org-dynamic-block-insert-dblock'.

  Type `C-c C-x C-u' (`org-dblock-update') with point on the `#+BEGIN'
  line to update the block.

  • The `:regexp' parameter is mandatory. Its value is a string and its
    behaviour is the same as that of the standard `denote-add-links'
    command (part of the main `denote' package). Concretely, it produces
    a typographic list of links to files matching the giving regular
    expression. The value of the `:regexp' parameter may also be of the
    form read by the `rx' macro (Lisp notation instead of a string), as
    explained in the Emacs Lisp Reference Manual (evaluate this code to
    read the documentation: `(info "(elisp) Rx Notation")'). Note that
    you do not need to write an actual regular expression to get
    meaningful results: even something like `_journal' will work to
    include all files that have a `journal' keyword.

  • The `:not-regexp' parameter is optional. It is a regular expression
    that applies after `:regexp' to filter out the matching files.

  • The `:excluded-dirs-regexp' is a string that contains a word or
    regular expression that matches against directory files names
    to-be-excluded from the results. This has the same meaning as
    setting the `denote-excluded-directories-regexp' user option (which
    is part of the main `denote' package). The user option has a global
    effect, which is overridden locally in the dynamic block. When the
    value of `:excluded-dirs-regexp' is nil (the default), the value of
    `denote-excluded-directories-regexp' is used (which is also nil by
    default, meaning that all directories are included). When the value
    of `excluded-dirs-regexp' is `t' or some other symbol, then the
    `denote-excluded-directories-regexp' is ignored altogether. This is
    useful in the scenario where the user option is set to exclude some
    directories but the dynamic blocks wants to lift that restriction.

  • The `:sort-by-component' parameter is optional. It sorts the files
    by the given Denote file name component. The value it accepts is an
    unquoted symbol among `title', `keywords', `signature',
    `identifier'.  When using the command
    `denote-org-dblock-insert-files', this parameter is automatically
    inserted together with the (`:regexp' parameter) and the user is
    prompted for a file name component.

  • The `:reverse-sort' parameter is optional. It reverses the order in
    which files appear in. This is meaningful even without the presence
    of the parameter `:sort-by-component', though it also combines with
    it.

  • The `:id-only' parameter is optional. It accepts a `t' value, in
    which case links are inserted without a description text but only
    with the identifier of the given file. This has the same meaning as
    with the `denote-link' command and related facilities (read the
    Denote manual’s section about linking to other files in the
    `denote-directory').

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


[The Org dynamic block to insert missing links only] See section 3.2


3.2 The Org dynamic block to insert missing links only
──────────────────────────────────────────────────────

  The `denote-missing-links' block is available with the command
  `denote-org-dblock-insert-missing-links'. It is like the
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


[Org dynamic blocks to insert links] See section 3.1


3.3 The Org dynamic block to insert backlinks
─────────────────────────────────────────────

  Apart from links to files matching a regular expression, we can also
  produce a list of backlinks to the current file. The dynamic block can
  be inserted at point with the command
  `denote-org-dblock-insert-backlinks' or by manually writing this in an
  Org file:

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


[Org dynamic blocks to insert links] See section 3.1

[Backlinks for Org headings] See section 5.1

[Insert link to an Org file with a further pointer to a heading] See
section 5


3.4 Org dynamic block to insert file contents
─────────────────────────────────────────────

  Denote can optionally use Org’s dynamic blocks facility to produce a
  section that lists entire file contents ([Use Org dynamic blocks]).
  This works by instructing Org to match a regular expression of Denote
  files, the same way we do with Denote links (read the Denote manual’s
  section about inserting links that match a regular expression).

  This is useful to, for example, compile a dynamically concatenated
  list of scattered thoughts on a given topic, like `^2023.*_emacs' for
  a long entry that incorporates all the notes written in 2023 with the
  keyword `emacs'.

  To produce such a block, call the command
  `denote-org-dblock-insert-files' or manually write the following block
  in an Org file and then type `C-c C-x C-u' (`org-dblock-update') on
  the `#+BEGIN' line to run it (do it again to recalculate the block):

  ┌────
  │ #+BEGIN: denote-files :regexp "YOUR REGEXP HERE" :not-regexp nil :sort-by-component nil :reverse-sort nil :no-front-matter nil :file-separator nil :add-links nil
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

  • The `:not-regexp' parameter is optional. It is a regular expression
    that applies after `:regexp' to filter out the matching files.

  • The `:excluded-dirs-regexp' is a string that contains a word or
    regular expression that matches against directory files names
    to-be-excluded from the results. This has the same meaning as
    setting the `denote-excluded-directories-regexp' user option (which
    is part of the main `denote' package). The user option has a global
    effect, which is overridden locally in the dynamic block. When the
    value of `:excluded-dirs-regexp' is nil (the default), the value of
    `denote-excluded-directories-regexp' is used (which is also nil by
    default, meaning that all directories are included). When the value
    of `excluded-dirs-regexp' is `t' or some other symbol, then the
    `denote-excluded-directories-regexp' is ignored altogether. This is
    useful in the scenario where the user option is set to exclude some
    directories but the dynamic blocks wants to lift that restriction.

  • The `:sort-by-component' parameter is optional. It sorts the files
    by the given Denote file name component. The value it accepts is an
    unquoted symbol among `title', `keywords', `signature',
    `identifier'.  When using the command
    `denote-org-dblock-insert-files', this parameter is automatically
    inserted together with the (`:regexp' parameter) and the user is
    prompted for a file name component.

  • The `:reverse-sort' parameter is optional. It reverses the order in
    which files appear in. This is meaningful even without the presence
    of the parameter `:sort-by-component', though it also combines with
    it.

  • The `:file-separator' parameter is optional. If it is omitted, then
    Denote will use no separator between the files it inserts. If the
    value is `t' the `denote-org-dblock-file-contents-separator' is
    applied at the end of each file: it introduces some empty lines and
    a horizontal rule between them to visually distinguish individual
    files. If the `:file-separator' value is a string, it is used as the
    file separator (e.g. use `"\n"' to insert just one empty new line).

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
    (those are explained at length in the Denote manual). Remember that
    Org can fold the items in a typographic list the same way it does
    with headings. So even long files can be presented in this format
    without much trouble.

  • An optional `:block-name' parameter can be specified with a string
    value to add a `#+name' to the results. This is useful for further
    processing using Org facilities (a feature that is outside Denote’s
    purview).


[Use Org dynamic blocks] See section 3

[Org dynamic blocks to insert links or backlinks] See section 3.1


3.5 Org dynamic block to insert Org files as headings
─────────────────────────────────────────────────────

  [ IMPORTANT NOTE: This dynamic block only works with Org files,
    because it has to assume the Org notation in order to insert each
    file’s contents as its own heading. ]

  As a variation of the previously covered block that inserts file
  contents, we have the `denote-org-dblock-insert-files-as-headings'
  command ([Org dynamic block to insert file contents]). It Turn the
  `#+title' of each file into a top-level heading. Then it increments
  all original headings in the file by one, so that they become
  subheadings of what once was the `#+title'. Similarly, the
  `#+filetags' of each file as tags for the top-level heading (what was
  the `#+title').

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
  `denote-org-dblock-insert-files-as-headings' you get all the
  parameters included:

  ┌────
  │ #+BEGIN: denote-files-as-headings :regexp "YOUR REGEXP HERE" :not-regexp nil :excluded-dirs-regexp nil :sort-by-component title :reverse-sort nil :add-links t
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

  • The `:not-regexp' parameter is optional. It is a regular expression
    that applies after `:regexp' to filter out the matching files.

  • The `:excluded-dirs-regexp' is a string that contains a word or
    regular expression that matches against directory files names
    to-be-excluded from the results. This has the same meaning as
    setting the `denote-excluded-directories-regexp' user option (which
    is part of the main `denote' package)). The user option has a global
    effect, which is overridden locally in the dynamic block. When the
    value of `:excluded-dirs-regexp' is nil (the default), the value of
    `denote-excluded-directories-regexp' is used (which is also nil by
    default, meaning that all directories are included). When the value
    of `excluded-dirs-regexp' is `t' or some other symbol, then the
    `denote-excluded-directories-regexp' is ignored altogether. This is
    useful in the scenario where the user option is set to exclude some
    directories but the dynamic blocks wants to lift that restriction.

  • The `:sort-by-component' parameter is optional. It sorts the files
    by the given Denote file name component. The value it accepts is an
    unquoted symbol among `title', `keywords', `signature',
    `identifier'.  When using the command
    `denote-org-dblock-insert-files', this parameter is automatically
    inserted together with the (`:regexp' parameter) and the user is
    prompted for a file name component.

  • The `:reverse-sort' parameter is optional. It reverses the order in
    which files appear in. This is meaningful even without the presence
    of the parameter `:sort-by-component', though it also combines with
    it.

  • The `:add-links' parameter is optional. When it is set to a `t'
    value, all the top-level headings (those that were the `#+title' of
    each file) are generated as links, pointing to the original file.
    This has the same meaning as with the `denote-link' command and
    related facilities (those are explained at length in the Denote
    manual).

  • An optional `:block-name' parameter can be specified with a string
    value to add a `#+name' to the results. This is useful for further
    processing using Org facilities (a feature that is outside Denote’s
    purview).


[Org dynamic block to insert file contents] See section 3.4

[Org dynamic blocks to insert links or backlinks] See section 3.1


4 Create a note from the current Org subtree
════════════════════════════════════════════

  In Org parlance, an entry with all its subheadings and other contents
  is a “subtree”. Denote can operate on the subtree to extract it from
  the current file and create a new file out of it. One such workflow is
  to collect thoughts in a single document and produce longer standalone
  notes out of them upon review.

  The command `denote-org-extract-org-subtree' is used for this
  purpose. It creates a new Denote note using the current Org subtree.
  In doing so, it removes the subtree from its current file and moves
  its contents into a new file. This command is part of the optional
  `denote-org.el' extension, which is part of the `denote' package. It
  is loaded automatically as soon as one of its commands is invoked.

  The text of the subtree’s heading becomes the `#+title' of the new
  note. Everything else is inserted as-is.

  If the heading has any tags, they are used as the keywords of the new
  note. If the Org file has any `#+filetags' they are taken as well
  (Org’s `#+filetags' are inherited by the headings). If none of these
  are true and the user option `denote-prompts' includes an entry for
  keywords, then `denote-org-extract-org-subtree' prompts for
  keywords. Else the new note has no keywords.

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


5 Insert link to an Org file with a further pointer to a heading
════════════════════════════════════════════════════════════════

  As part of the optional `denote-org.el' extension, the command
  `denote-org-link-to-heading' prompts for a link to an Org file and
  then asks for a heading therein, using minibuffer completion. Once the
  user provides input at the two prompts, the command inserts a link at
  point which has the following pattern:
  `[[denote:IDENTIFIER::#ORG-HEADING-CUSTOM-ID]][Description::Heading
  text]]'.

  Because only Org files can have links to individual headings, the
  command `denote-org-link-to-heading' prompts only for Org files
  (i.e. files which include the `.org' extension). Remember that Denote
  works with many file types (read the Denote manual’s section about the
  file-naming scheme).

  This feature is similar to the concept of the user option
  `denote-org-store-link-to-heading' (which is part of the main `denote'
  package). It is, however, interactive and differs in the
  directionality of the action. With that user option, the command
  `org-store-link' will generate a `CUSTOM_ID' for the current heading
  (or capture the value of one as-is), giving the user the option to
  then call `org-insert-link' wherever they see fit. By contrast, the
  command `denote-org-link-to-heading' prompts for a file, then a
  heading, and inserts the link at point.

  Just as with files, it is possible to show backlinks for the given
  heading ([Backlinks for Org headings]).


[Backlinks for Org headings] See section 5.1

5.1 Backlinks for Org headings
──────────────────────────────

  The optional `denote-org.el' can generate Denote links to individual
  headings ([Insert link to an Org file with a further pointer to a
  heading]).  It is then possible to produce a corresponding backlinks
  buffer with the command `denote-org-backlinks-for-heading'. The
  resulting buffer behaves the same way as the standard backlinks buffer
  we provide (read the Denote manual’s section about the backlinks
  buffer).  An Org dynamic block with backlinks to the current heading
  is also an option ([Org dynamic blocks to insert links or backlinks]).


[Insert link to an Org file with a further pointer to a heading] See
section 5

[Org dynamic blocks to insert links or backlinks] See section 3.1


6 Convert `denote:' links to `file:' links in Org and vice versa
════════════════════════════════════════════════════════════════

  Sometimes the user needs to translate all `denote:' link types to
  their `file:' equivalent. This may be because some other tool does not
  recognise `denote:' links (or other custom links types—which are a
  standard feature of Org, by the way). The user thus needs to (i)
  either make a copy of their Denote note or edit the existing one, and
  (ii) convert all links to the generic `file:' link type that
  external/other programs understand.

  The optional extension `denote-org.el' contains two commands that are
  relevant for this use-case:

  Convert `denote:' links to `file:' links
        The command `denote-org-convert-links-to-file-type' goes through
        the buffer to find all `denote:' links. It gets the identifier
        of the link and resolves it to the actual file system path. It
        then replaces the match so that the link is written with the
        `file:' type and then the file system path. The optional search
        terms and/or link description are preserved ([Insert link to an
        Org file with a further pointer to a heading]).

  Convert `file:' links to `denote:' links
        The command `denote-org-convert-links-to-denote-type' behaves
        like the one above. The difference is that it finds the file
        system path and converts it into its identifier.


[Insert link to an Org file with a further pointer to a heading] See
section 5


7 Installation
══════════════




7.1 GNU ELPA package
────────────────────

  The package is available as `denote-org'.  Simply do:

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


7.2 Manual installation
───────────────────────

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
  │ # Clone this repo, naming it "denote-org"
  │ git clone https://github.com/protesilaos/denote-org denote-org
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/denote-org")
  └────

  Everything is in place to set up the package.


8 Sample configuration
══════════════════════

  ┌────
  │ (use-package denote-org
  │   :ensure t
  │   :commands
  │   ;; I list the commands here so that you can discover them more
  │   ;; easily.  You might want to bind the most frequently used ones to
  │   ;; the `org-mode-map'.
  │   ( denote-org-link-to-heading
  │     denote-org-backlinks-for-heading
  │ 
  │     denote-org-extract-org-subtree
  │ 
  │     denote-org-convert-links-to-file-type
  │     denote-org-convert-links-to-denote-type
  │ 
  │     denote-org-dblock-insert-files
  │     denote-org-dblock-insert-links
  │     denote-org-dblock-insert-backlinks
  │     denote-org-dblock-insert-missing-links
  │     denote-org-dblock-insert-files-as-headings))
  └────


9 Acknowledgements
══════════════════

  Denote Org is meant to be a collective effort.  Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.


10 GNU Free Documentation License
═════════════════════════════════


11 Indices
══════════

11.1 Function index
───────────────────


11.2 Variable index
───────────────────


11.3 Concept index
──────────────────
