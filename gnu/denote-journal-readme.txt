           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            DENOTE-JOURNAL: CONVENIENCE FUNCTIONS FOR DAILY
                         JOURNALING WITH DENOTE

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

⁃ Package name (GNU ELPA): `denote-journal'
⁃ Official manual: <https://protesilaos.com/emacs/denote-journal>
⁃ Git repository: <https://github.com/protesilaos/denote-journal>
⁃ Backronym: Denote… Journaling Obviously Utilises Reasonableness
  Notwithstanding Affectionate Longing.

If you are viewing the README.org version of this file, please note that
the GNU ELPA machinery automatically generates an Info manual out of it.

Table of Contents
─────────────────

1. COPYING
2. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
3. Sample configuration
4. Overview
.. 1. Create new journal entry
.. 2. Create a new journal entry or use an existing one
.. 3. Link to a journal entry or create it if missing
.. 4. Integrate with the `calendar' to view or create journal entries
.. 5. The `denote-journal-directory'
.. 6. Title format of new journal entries
.. 7. Create a journal entry using Org capture
.. 8. The `denote-journal-hook'
.. 9. Journaling with a timer
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


2 Installation
══════════════




2.1 GNU ELPA package
────────────────────

  The package is available as `denote-journal'.  Simply do:

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


2.2 Manual installation
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
  │ # Clone this repo, naming it "denote-journal"
  │ git clone https://github.com/protesilaos/denote-journal denote-journal
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/denote-journal")
  └────

  Everything is in place to set up the package.


3 Sample configuration
══════════════════════

  ┌────
  │ (use-package denote-journal
  │   :ensure t
  │   ;; Bind those to some key for your convenience.
  │   :commands ( denote-journal-new-entry
  │ 	      denote-journal-new-or-existing-entry
  │ 	      denote-journal-link-or-create-entry )
  │   :hook (calendar-mode . denote-journal-calendar-mode)
  │   :config
  │   ;; Use the "journal" subdirectory of the `denote-directory'.  Set this
  │   ;; to nil to use the `denote-directory' instead.
  │   (setq denote-journal-directory
  │ 	(expand-file-name "journal" denote-directory))
  │   ;; Default keyword for new journal entries. It can also be a list of
  │   ;; strings.
  │   (setq denote-journal-keyword "journal")
  │   ;; Read the doc string of `denote-journal-title-format'.
  │   (setq denote-journal-title-format 'day-date-month-year))
  └────


4 Overview
══════════

  The `denote-journal' package makes it easier to use Denote for
  journaling. While it is possible to use the generic `denote' command
  (and related) to maintain a journal, this package defines extra
  functionality to streamline the journaling workflow.

  The code of `denote-journal' used to be bundled up with the `denote'
  package before version `4.0.0' of the latter and was available in the
  file `denote-journal-extras.el'. Users of the old code will need to
  adapt their setup to use the `denote-journal' package. This can be
  done by replacing all instances of `denote-journal-extras' with
  `denote-journal' across their configuration.


4.1 Create new journal entry
────────────────────────────

  The command `denote-journal-new-entry' creates a new entry in the
  journal. Such a file has the `denote-journal-keyword', which is the
  string `journal' by default (read the Denote manual about the
  file-naming scheme). The user can set this keyword to an arbitrary
  string (single word is preferred) or a list of strings.

  New journal entries are stored in the `denote-journal-directory',
  while any command that generates a new journal entry calls the
  `denote-journal-hook':

  • [The `denote-journal-hook'].
  • [The `denote-journal-directory'].

  The command `denote-journal-new-entry' creates a new entry
  unconditionally. This means that it will not check if the present day
  already has a note for it. Users who wish to only ever have one entry
  per day should use `denote-journal-new-or-existing-entry' instead
  ([Create a new journal entry or use an existing one]).


[The `denote-journal-hook'] See section 4.8

[The `denote-journal-directory'] See section 4.5

[Create a new journal entry or use an existing one] See section 4.2


4.2 Create a new journal entry or use an existing one
─────────────────────────────────────────────────────

  The command `denote-journal-new-or-existing-entry' locates an existing
  journal entry and opens it for editing or creates a new one.

  A journal entry is an editable file that has `denote-journal-keyword'
  as part of its file name. If there are multiple journal entries for
  the current date, `denote-journal-new-or-existing-entry' prompts to
  select one among them using minibuffer completion. If there is only
  one matching file, it visits it outright. If there is no journal
  entry, it creates a new one by calling `denote-journal-new-entry'
  ([Create new journal entry]). Depending on one’s workflow, this can
  also be done via `org-capture' ([Create a journal entry using Org
  capture]).

  When called with a prefix argument (`C-u' with default key bindings),
  the command `denote-journal-new-or-existing-entry' prompts for a date
  ([Integrate with the `calendar' to view or create journal
  entries]). It then determines whether to visit an existing file or
  create a new one, as described above. The date selection interface is
  controlled by the user option `denote-date-prompt-use-org-read-date',
  which is part of the main `denote' package. By default, this is a
  simple minibuffer prompt, though users can opt in to the more advanced
  minibuffer+calendar date picker that Org uses for its own date
  selection operations.


[Create new journal entry] See section 4.1

[Create a journal entry using Org capture] See section 4.7

[Integrate with the `calendar' to view or create journal entries] See
section 4.4


4.3 Link to a journal entry or create it if missing
───────────────────────────────────────────────────

  The command `denote-journal-link-or-create-entry' links to the journal
  entry for today or creates it in the background, if missing, and then
  links to it from the current file. If there are multiple journal
  entries for the same day, it prompts to select one among them and then
  links to it. When called with an optional prefix argument (such as
  `C-u' with default key bindings), the command prompts for a date and
  then performs the aforementioned. With a double prefix argument (`C-u
  C-u'), it also produces a link whose description includes just the
  file’s identifier.


4.4 Integrate with the `calendar' to view or create journal entries
───────────────────────────────────────────────────────────────────

  The command `denote-journal-calendar-new-or-existing' creates a new
  journal entry for the date at point in the `M-x calendar' buffer. If
  an entry exists, it visits it. This is the same as the command
  `denote-journal-new-or-existing-entry' ([Create a new journal entry or
  use an existing one]).

  The command `denote-journal-calendar-find-file' visits the Denote
  journal entry corresponding to the date at point in the `M-x
  calendar'. If there are multiple entries, it prompts with minibuffer
  completion to select one among them.

  The buffer-local minor mode `denote-journal-calendar-mode' marks the
  dates in the `M-x calendar' that have a Denote journal entry. The face
  applied to them is the `denote-journal-calendar'. Activate the mode
  via the `calendar-mode-hook':

  ┌────
  │ (add-hook 'calendar-mode-hook #'denote-journal-calendar-mode)
  └────

  The `denote-journal-calendar-mode' also activates the key map called
  `denote-journal-calendar-mode-map'. It defines bindings for the
  aforementioned commands: `F' for `denote-journal-calendar-find-file'
  and `N' for `denote-journal-calendar-new-or-existing'.


[Create a new journal entry or use an existing one] See section 4.2


4.5 The `denote-journal-directory'
──────────────────────────────────

  New journal entries are placed in the `denote-journal-directory',
  which defaults to a subdirectory of `denote-directory' called
  `journal'.

  If `denote-journal-directory' is nil, the `denote-directory' is used.
  Journal entries will thus be in a flat listing together with all other
  notes. They can still be retrieved easily by searching for the
  `denote-journal-keyword' (read the Denote manual about “Features of
  the file-naming scheme for searching or filtering”).


4.6 Title format of new journal entries
───────────────────────────────────────

  New journal entries will use the current date as the title of the
  entry. The exact format is controlled by the user option
  `denote-journal-title-format'. The value it can take is either nil, a
  custom string, or a symbol:

  • When `denote-journal-title-format' is set to a nil value, then new
    journal entries always prompt for a title. Users will want this if
    they prefer to journal using a given theme for the day rather than
    the date itself (e.g. instead of “1st of April 2025” they may prefer
    something like “Early Spring at the hut”).

  • When `denote-journal-title-format' is set to an empty or blank
    string (string with only spaces), then new journal entries will not
    use a file title.

  • When `denote-journal-title-format' is set to a symbol, it is one
    among `day' (results in a title like `Tuesday'),
    `day-date-month-year' (for a result like `Tuesday 1 April 2025'),
    `day-date-month-year-24h' (for `Tuesday 1 April 2025 13:46'), or
    `day-date-month-year-12h' (e.g. `Tuesday 1 April 2025 02:46 PM').

  • When `denote-journal-title-format' is set to a string, it is used
    literally except for any “format specifiers”, as interpreted by the
    function `format-time-string', which are replaced by their given
    date component. For example, the `"Week %V on %A %e %B %Y at %H:%M"'
    will yield a title like `Week 14 on 1 April 2025 at 13:48'.


4.7 Create a journal entry using Org capture
────────────────────────────────────────────

  Users who prefer to consolidate all their note-creating or todo-making
  commands in the `org-capture' interface will want to use a variant of
  `denote-journal-new-or-existing-entry' ([Create a new journal entry or
  use an existing one]):

  ┌────
  │ (with-eval-after-load 'org-capture
  │   (add-to-list 'org-capture-templates
  │ 	       '("j" "Journal" entry
  │ 		 (file denote-journal-path-to-new-or-existing-entry)
  │ 		 "* %U %?\n%i\n%a"
  │ 		 :kill-buffer t
  │ 		 :empty-lines 1)))
  └────

  Using the above, is the same as calling the command
  `denote-journal-new-or-existing-entry' and then manually appending a
  heading with a timestamp after the file’s front matter. The template
  shown above can be modified accordingly, in accordance with the
  documentation of `org-capture-templates'.


[Create a new journal entry or use an existing one] See section 4.2


4.8 The `denote-journal-hook'
─────────────────────────────

  All commands that create a new journal entry call the normal hook
  `denote-journal-hook' as a final step. The user can leverage this to
  produce consequences therefrom, such as to set a timer with the `tmr'
  package from GNU ELPA ([Journaling with a timer]).


[Journaling with a timer] See section 4.9


4.9 Journaling with a timer
───────────────────────────

  Sometimes journaling is done with the intent to hone one’s writing
  skills. Perhaps you are learning a new language or wish to communicate
  your ideas with greater clarity and precision. As with everything that
  requires a degree of sophistication, you have to work for it—write,
  write, write!

  One way to test your progress is to set a timer. It helps you gauge
  your output and its quality. To use a timer with Emacs, consider the
  `tmr' package (Protesilaos is the original author and maintainer). A
  new timer can be set with something like this:

  ┌────
  │ ;; Set 10 minute timer with the given description
  │ (tmr "10" "Practice writing in my journal")
  └────

  To make this timer start as soon as a new journal entry is created add
  a function to the `denote-journal-hook' ([The `denote-journal-hook']).
  For example:

  ┌────
  │ ;; Add an anonymous function, which is more difficult to modify after
  │ ;; the fact:
  │ (add-hook 'denote-journal-hook (lambda () (tmr "10" "Practice writing in my journal")))
  │ 
  │ ;; Or write a small function that you can then modify without
  │ ;; revaluating the hook:
  │ (defun my-denote-tmr ()
  │   (tmr "10" "Practice writing in my journal"))
  │ 
  │ ;; Now add your named function to the hook:
  │ (add-hook 'denote-journal-hook #'my-denote-tmr)
  │ 
  │ ;; Or to make it fully featured!  Define variables for the duration
  │ ;; and the description and set it up so that you only need to modify
  │ ;; those instead of the function:
  │ (defvar my-denote-tmr-duration "10")
  │ 
  │ (defvar my-denote-tmr-description "Practice writing in my journal")
  │ 
  │ (defun my-denote-tmr ()
  │   (tmr my-denote-tmr-duration my-denote-tmr-description))
  │ 
  │ (add-hook 'denote-journal-hook #'my-denote-tmr)
  └────

  Once the timer elapses, stop writing and review your performance.
  Practice makes perfect!

  Sources for `tmr':

  ⁃ Package name (GNU ELPA): `tmr'
  ⁃ Official manual: <https://protesilaos.com/emacs/tmr>
  ⁃ Change log: <https://protesilaos.com/emacs/tmr-changelog>
  ⁃ Git repositories:
    ⁃ GitHub: <https://github.com/protesilaos/tmr>
    ⁃ GitLab: <https://gitlab.com/protesilaos/tmr>
  ⁃ Backronym: TMR May Ring; Timer Must Run.


[The `denote-journal-hook'] See section 4.8


5 Acknowledgements
══════════════════

  Denote Journal is meant to be a collective effort.  Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to code or the manual
        Honza Pokorny, Stefan Monnier, Vineet C. Kulkarni.

  Ideas and/or user feedback
        Alan Schmitt, Kevin McCarthy.


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
