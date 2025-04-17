           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             DENOTE-SEQUENCE: SEQUENCE NOTES OR FOLGEZETTEL
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

⁃ Package name (GNU ELPA): `denote-sequence'
⁃ Official manual: <https://protesilaos.com/emacs/denote-sequence>
⁃ Git repository: <https://github.com/protesilaos/denote-sequence>
⁃ Backronym: Denote… Sequences Efficiently Queue Unsorted Entries
  Notwithstanding Curation Efforts.

If you are viewing the README.org version of this file, please note that
the GNU ELPA machinery automatically generates an Info manual out of it.

Table of Contents
─────────────────

1. COPYING
2. Sequence notes
.. 1. Select a sequencing scheme for `denote-sequence-scheme'
..... 1. Convert from one sequencing scheme to another
.. 2. Create parent, child, or sibling sequence notes
.. 3. Find a relative of the current sequence
.. 4. Link only to sequences
.. 5. Re-parent a file to extend a given sequence
.. 6. Show all or some sequences in a Dired buffer
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


2 Write sequence notes or "folgezettel"
═══════════════════════════════════════

  The `denote-sequence' package provides an optional extension to
  `denote' for naming files with a sequencing scheme. The idea is to
  establish hiearchical relationships between files, such that the
  contents of one logically follow or complement those of another.

  Denote defines an optional file name component called the `SIGNATURE'
  (read about the file-naming scheme in the Denote manual). This is a
  free form field that users can fill in with whatever text they want,
  such as to have a video split up into `part1' and `part2', or to set
  some kind of priority like `a' and `b', or even to have a special tag
  that stands out from the rest of the keywords.

  A more specialised use-case of the `SIGNATURE' is to define a
  hierarchical relationship between notes, such that the thoughts they
  expound on form sequences. For example, an article about the Labrador
  Retriever dog breed is a continuation of a thought process that
  extends something about dog breeds in general which, in turn, is a
  topic that belongs to the wider theme of dogs. A sequence, then, is a
  representation of such relationships. A note with a `SIGNATURE' of
  `1=1' (the `=' is the field separator of signatures, per the Denote
  file-naming scheme) is thus the first child of note `1' and the
  sibling of note `1=2'. In this regard, something unrelated to dogs
  will be its own parent, such as `2', and so on.

  All the relevant functions we provide take care to automatically use
  the right number for a given sequence ([Create parent, child, or
  sibling sequence notes]).  If, for example, we create a new child of
  parent `1=1', we make sure that it is the largest number among any
  existing children, so if `1=1=1' already exists we use `1=1=2', and
  the like.

  The `denote-sequence.el' optional extension is not necessary for such
  a workflow. Users can always define whatever `SIGNATURE' they want
  manually. The purpose of this extension is to streamline this work.


[Create parent, child, or sibling sequence notes] See section 2.2

2.1 Select a sequencing scheme for `denote-sequence-scheme'
───────────────────────────────────────────────────────────

  The user option `denote-sequence-scheme' allows users to select either
  the `numeric' scheme, which is like `1=1=2' or the `alphanumeric'
  scheme, which is `1a2' for the same sequence ([Convert from one
  sequencing scheme to another]):

  Numeric sequencing scheme
        A numeric sequence consists only of numbers. The level of depth
        is derived from the number of fields in the sequence, separated
        by the equals sign. Thus, the sequence `1=1=2' consists of three
        levels of depth. For deeper sequences, the numeric scheme will
        get longer, which some users may consider unwieldy. The upside,
        however, is that is easier to reason about larger numbers, such
        as `1=100=2=50'.

  Alphanumeric sequencing scheme
        An alphanumeric sequence combines numbers and letters. The level
        of depth is undestand by the alteration from numbers to letters
        and vice versa. As such, the sequence `1a2' has three levels of
        depth. This scheme is more compact, which users may like but can
        be harder to reason about large numbers, such as `1zzzv2zx'
        corresponding to the numeric `1=100=2=50' (this is because the
        number 26 is z, 27 is za, 52 is zz, and so on). In practice,
        large numbers may not be a problem, though this is something to
        keep in mind.


[Convert from one sequencing scheme to another] See section 2.1.1

2.1.1 Convert from one sequencing scheme to another
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The decision on the desired `denote-sequence-scheme' wil affect new
  notes long-term ([Select a sequencing scheme for
  `denote-sequence-scheme']).  It thus is important to think through
  your needs and proceed accordingly.

  Still, one cannot be sure which scheme they prefer until they
  experiment with it. It then is inconvenient to manually revert to the
  alternative scheme. To this end, we provide the command
  `denote-sequence-convert'. It convers one or more files from their
  current scheme to its counterpart.

  When called from inside a Denote file, it converts that file. When
  called from a Dired buffer, it operates on the marked files. If no
  files are marked, it works with the Dired file at point.

  Note that `denote-sequence-convert' DOES NOT REPARENT OR ANYHOW CHECK
  THE RESULTING SEQUENCES FOR DUPLICATES ([Re-parent a file to extend a
  given sequence]).


[Select a sequencing scheme for `denote-sequence-scheme'] See section
2.1

[Re-parent a file to extend a given sequence] See section 2.5


2.2 Create parent, child, or sibling sequence notes
───────────────────────────────────────────────────

  [ In the interest of simplicity, here we provide examples using the
    `numeric' value of `denote-sequence-scheme', though the
    `alphanumeric' will work as well ([Select a sequencing scheme for
    `denote-sequence-scheme']). ]

  A new sequence note can be of the type `parent', `child', and
  `sibling'. For the convenience of the user, we provide commands to
  create such “sequence notes”, link only between them (as opposed to a
  link to any other file with the Denote file-naming scheme (read the
  Denote manual about link-related commands)), and re-parent them on
  demand.

  Concretely, we provide the following commands:

  `denote-sequence'
        The most general way to create a new sequence note. It prompts
        for a type of sequence among `parent', `child', and `sibling'
        and the rest of the work accordingly. If the new sequence is not
        a parent, it thus prompts for an existing file to extend
        from. The rest of the interaction is that of all the usual
        Denote commands, such as to prompt for a title and keywords
        (read the Denote manual about the main points of entry).

  `denote-sequence-new-parent'
        This is a convenience wrapper of `denote-sequence' which
        directly creates a parent sequence.

  `denote-sequence-new-child'
        This is a convenience wrapper of `denote-sequence' which
        directly creates a child of an existing sequence, prompting for
        it using minibuffer completion.

  `denote-sequence-new-child-of-current'
        This will create a new child of the current file’s sequence. If
        the current file does not have such a sequence, then the command
        behaves the same as the aforementioned
        `denote-sequence-new-child'.

  `denote-sequence-new-sibling'
        This is a convenience wrapper of `denote-sequence' which
        directly creates a sibling of an existing sequence, prompting
        for it using minibuffer completion.

  `denote-sequence-new-sibling-of-current'
        This will create a new sibling of the current file’s
        sequence. If the current file does not have such a sequence,
        then the command behaves the same as the aforementioned
        `denote-sequence-new-sibling'.


[Select a sequencing scheme for `denote-sequence-scheme'] See section
2.1


2.3 Find a relative of the current sequence
───────────────────────────────────────────

  While reading a file with a sequence, you may want to find what its
  relatives are about. To this end, the command `denote-sequence-find'
  prompts for a type among `parent', `sibling', `child', and then asks
  to select a file among those matching the given type. It then visits
  the file.

  Instead of selecting a single file, the command
  `denote-sequence-find-dired' puts all the matching files in a bespoke
  Dired buffer ([Show all or some sequences in a Dired buffer]).


[Show all or some sequences in a Dired buffer] See section 2.6


2.4 Link only to sequences
──────────────────────────

  The command `denote-sequence-link' is a variant of the standard
  `denote-link' command which limits the list of files only to those
  which contain a sequence (read the Denote manual about link-related
  commands). Consider it a convenience to link to sequence notes more
  quickly. It is by no means necessary though, as the regular linking
  commands will work as expected with any Denote file, including those
  which contain a sequence as their file name `SIGNATURE' ([Write
  sequence notes or “folgezettel”]).


[Write sequence notes or “folgezettel”] See section 2


2.5 Re-parent a file to extend a given sequence
───────────────────────────────────────────────

  The command `denote-sequence-reparent' can be used from inside a file
  or for the file-at-point in Dired to make that file a child of a given
  sequence. It does so by prompting for the target file using minibuffer
  completion. Files available at this prompt are only those which
  contain a sequence as their file name `SIGNATURE' ([Write sequence
  notes or “folgezettel”]).


[Write sequence notes or “folgezettel”] See section 2


2.6 Show all or some sequences in a Dired buffer
────────────────────────────────────────────────

  [ In the interest of simplicity, here we provide examples using the
    `numeric' value of `denote-sequence-scheme', though the
    `alphanumeric' will work as well ([Select a sequencing scheme for
    `denote-sequence-scheme']). ]

  The command `denote-sequence-dired' produces a bespoke and fully
  fledged Dired buffers that contains all the sequences in their order
  (as opposed to a regular Dired which sorts files using the `ls'
  flags).

  With an optional `C-u' prefix argument, this command prompts for a
  prefix to only show sequences that include it (e.g. only show notes
  with `1=1', like `1=1=1' and `1=1=2' but not `1=2').

  With an optional double prefix argument of `C-u C-u', this command
  will prompt for the prefix as well as the level of depth to limit the
  results to. Here “depth” means how deep to go in a sequence where, for
  example, `1=1=2' is three levels of depth. It is possible to use an
  empty string at the prefix prompt to not limit the results to any
  prefix.

  A more specialised alternative for only relatives of a given sequence
  is also available ([Find a relative of the current sequence]).


[Select a sequencing scheme for `denote-sequence-scheme'] See section
2.1

[Find a relative of the current sequence] See section 2.3


3 Installation
══════════════




3.1 GNU ELPA package
────────────────────

  The package is available as `denote-sequence'.  Simply do:

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
  │ # Clone this repo, naming it "denote-sequence"
  │ git clone https://github.com/protesilaos/denote-sequence denote-sequence
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/denote-sequence")
  └────

  Everything is in place to set up the package.


4 Sample configuration
══════════════════════

  ┌────
  │ (use-package denote-sequence
  │   :ensure t
  │   :bind
  │   ( :map global-map
  │     ;; Here we make "C-c n s" a prefix for all "[n]otes with [s]equence".
  │     ;; This is just for demonstration purposes: use the key bindings
  │     ;; that work for you.  Also check the commands:
  │     ;;
  │     ;; - `denote-sequence-new-parent'
  │     ;; - `denote-sequence-new-sibling'
  │     ;; - `denote-sequence-new-child'
  │     ;; - `denote-sequence-new-child-of-current'
  │     ;; - `denote-sequence-new-sibling-of-current'
  │     ("C-c n s s" . denote-sequence)
  │     ("C-c n s f" . denote-sequence-find)
  │     ("C-c n s l" . denote-sequence-link)
  │     ("C-c n s d" . denote-sequence-dired)
  │     ("C-c n s r" . denote-sequence-reparent)
  │     ("C-c n s c" . denote-sequence-convert))
  │   :config
  │   ;; The default sequence scheme is `numeric'.
  │   (setq denote-sequence-scheme 'alphanumeric))
  │ 
  └────


5 Acknowledgements
══════════════════

  Denote Sequence is meant to be a collective effort.  Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to code or the manual
        Claudio Migliorelli, Kierin Bell.

  Ideas and/or user feedback
        Mirko Hernandez.


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
