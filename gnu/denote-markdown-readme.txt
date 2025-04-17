           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            DENOTE-MARKDOWN: EXTENSIONS TO BETTER INTEGRATE
                          MARKDOWN WITH DENOTE

                          Protesilaos Stavrou
                          info@protesilaos.com
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for the Emacs package called `denote-markdown' (or
`denote-markdown.el'), and provides every other piece of information
pertinent to it.

The documentation furnished herein corresponds to stable version 0.1.0,
released on 2025-04-15.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.2.0-dev.

⁃ Package name (GNU ELPA): `denote-markdown'
⁃ Official manual: <https://protesilaos.com/emacs/denote-markdown>
⁃ Git repository: <https://github.com/protesilaos/denote-markdown>
⁃ Backronyms: Denote… Markdown’s Ambitious Reimplimentations Knowingly
  Dilute Obvious Widespread Norms; Denote… Markup Agnosticism Requires
  Knowhow to Do Only What’s Necessary.

If you are viewing the README.org version of this file, please note that
the GNU ELPA machinery automatically generates an Info manual out of it.

Table of Contents
─────────────────

1. COPYING
2. Overview
.. 1. Use the `markdown-obsidian' file type
.. 2. Convert `:denote' links to paths in Markdown or Obsidian style
3. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
4. Sample configuration
5. Acknowledgements
6. GNU Free Documentation License
7. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2024-2025 Free Software Foundation, Inc.

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

  The `denote-markdown' package provides some convenience functions to
  better integrate Markdown with Deonte. This is mostly about converting
  links from one type to another so that they can work in different
  applications (because Markdown does not have a standardised way to
  define custom link types).

  The code of `denote-markdown' used to be bundled up with the `denote'
  package before version `4.0.0' of the latter and was available in the
  file `denote-md-extras.el'. Users of the old code will need to adapt
  their setup to use the `denote-markdown' package. This can be done by
  replacing all instances of `denote-md-extras' with `denote-markdown'
  across their configuration.


2.1 Use the `markdown-obsidian' file type
─────────────────────────────────────────

  The `denote' package defines two variants of Markdown file types, one
  with YAML front matter and another with TOML front matter. This
  `denote-markdown' package extends the list to include the
  `markdown-obsidian' type, which has front matter of the sort we find
  in the popular Obsidian application. Unlike the two variants defined
  in core Denote, `markdown-obsidian' does not have any front matter
  other than the title of the note as a top-level heading.


2.2 Convert `:denote' links to paths in Markdown or Obsidian style
──────────────────────────────────────────────────────────────────

  Although Markdown is a ubiquitous file format, there is no
  standardised way to extend its link facility. This means that we
  cannot reliably make `denote:' links work in applications outside of
  Emacs. Users who need to use their Denote files outside of Emacs must
  thus perform the requisite conversion to a format that is understood
  by the given application. We thus provide the following commands.

  Convert `denote:' links to file paths
        The command `denote-markdown-convert-links-to-file-paths' runs
        through the current Markdown file and converts every instance of
        a `denote:' link to file path implied by the Denote
        identifier. For example, this link `[Test
        description](denote:20241026T051243)' expands to the file link
        `[Test
        description](20241026T051243--test-description__denote_testing.md)'
        (remember that the Denote file-naming scheme can apply to any
        file type so links are file-agnostic accordingly, meaning that
        the expanded path here will be that of the actual note, not of
        an `.md' extension necessarily). When
        `denote-markdown-convert-links-to-file-paths' is called with a
        prefix argument (`C-u' by default), it produces absolute file
        system paths.

  Convert file paths links to `denote:'
        The command `denote-markdown-convert-links-to-denote-type' is
        the inverse of the above. It finds all the file paths, be they
        relative or absolute, and converts them into their corresponding
        `denote:' style links. It only does so for files with a Denote
        identifier.

  Convert `denote:' links to Obsidian type
        The command `denote-markdown-convert-links-to-obsidian-type'
        changes links from `[Test description](denote:20241026T051243)'
        to
        `[20241026T051243--test-description__keyword1](20241026T051243--test-description__keyword1.md)'.
        This is how the Obsidian application handles links and is useful
        for those who need to use their Denote files there ([Use the
        `markdown-obsidian' file type]).

  Convert Obsidian-style links to `denote:' type
        The command
        `denote-markdown-convert-obsidian-links-to-denote-type' does the
        inverse of `denote-markdown-convert-links-to-obsidian-type'.

  DEVELOPMENT NOTE: The regular expressions I am using to determine what
  is a link are much simpler than what the Emacs `markdown-mode' is
  using.  Everything seems to work on my end, though do let me know if
  there are bugs.


[Use the `markdown-obsidian' file type] See section 2.1


3 Installation
══════════════




3.1 GNU ELPA package
────────────────────

  The package is available as `denote-markdown'.  Simply do:

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


3.2 Manual installation
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
  │ # Clone this repo, naming it "denote-markdown"
  │ git clone https://github.com/protesilaos/denote-markdown denote-markdown
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/denote-markdown")
  └────

  Everything is in place to set up the package.


4 Sample configuration
══════════════════════

  ┌────
  │ (use-package denote-markdown
  │   :ensure t
  │   ;; Bind these commands to key bindings of your choice.
  │   :commands ( denote-markdown-convert-links-to-file-paths
  │ 	      denote-markdown-convert-links-to-denote-type
  │ 	      denote-markdown-convert-links-to-obsidian-type
  │ 	      denote-markdown-convert-obsidian-links-to-denote-type ))
  └────


5 Acknowledgements
══════════════════

  Denote Silo is meant to be a collective effort.  Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.


6 GNU Free Documentation License
════════════════════════════════


7 Indices
═════════

7.1 Function index
──────────────────


7.2 Variable index
──────────────────


7.3 Concept index
─────────────────
