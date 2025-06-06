           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            DENOTE-SILO: CONVENIENCE FUNCTIONS TO WORK WITH
                         MULTIPLE DENOTE SILOS

                          Protesilaos Stavrou
                          info@protesilaos.com
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for the Emacs package called `denote-silo' (or
`denote-silo.el'), and provides every other piece of information
pertinent to it.

The documentation furnished herein corresponds to stable version 0.1.0,
released on 2025-04-15.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.2.0-dev.

⁃ Package name (GNU ELPA): `denote-silo'
⁃ Official manual: <https://protesilaos.com/emacs/denote-silo>
⁃ Git repository: <https://github.com/protesilaos/denote-silo>
⁃ Backronym: Denote… Silos Insulate Localised Objects.

If you are viewing the README.org version of this file, please note that
the GNU ELPA machinery automatically generates an Info manual out of it.

Table of Contents
─────────────────

1. COPYING
2. Overview
.. 1. Create new notes in silos
.. 2. Switch to a silo directory
.. 3. Make Org export work with silos
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


2 Overview
══════════

  The `denote-silo' package makes it easier to work with multiple
  “silos”, as explained in the Denote manual. In short, a “silo” is a
  localised `denote-directory' that is not connected to the
  default/global `denote-directory' and other silos.

  The code of `denote-silo' used to be bundled up with the `denote'
  package before version `4.0.0' of the latter and was available in the
  file `denote-silo-extras.el'. Users of the old code will need to adapt
  their setup to use the `denote-silo' package. This can be done by
  replacing all instances of `denote-silo-extras' with `denote-silo'
  across their configuration.


2.1 Create new notes in silos
─────────────────────────────

  The user option `denote-silo-directories' specifies a list of
  directories that the user has set up as `denote-directory' silos.

  The command `denote-silo-create-note' prompts for a directory among
  `denote-silo-directories' and runs the `denote' command from there.

  Similar to the above, the command `denote-silo-open-or-create' prompts
  for a directory among `denote-silo-directories' and runs the
  `denote-open-or-create' command from there.

  The command `denote-silo-select-silo-then-command' prompts with
  minibuffer completion for a directory among `denote-silo-directories'.
  Once the user selects a silo, a second prompt asks for a Denote
  note-creation command to call from inside that silo (read about the
  “Points of entry” in the Denote manual).


2.2 Switch to a silo directory
──────────────────────────────

  The command `denote-silo-dired' prompts for a silo directory among
  those specified in the user option `denote-silo-directories' and
  switches to it using `dired'.

  The command `denote-silo-cd' is the same as above, except it used the
  `cd' to perform the switch. This is more subtle because the current
  buffer does not change, even though the “current directory” is
  different. Such an action is useful to, for example, affect what a
  shell or search command will consider as the current directory,
  without necessarily changing context completely.


2.3 Make Org export work with silos
───────────────────────────────────

  The Org export infrastructure is designed to ignore directory-local
  variables. This means that Denote silos, which depend on setting the
  local value of the variable `denote-directory', do not work as
  intended. More specifically, the Denote links do not resolve to the
  right file, because their path is changed during the export process.

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


3 Installation
══════════════




3.1 GNU ELPA package
────────────────────

  The package is available as `denote-silo'.  Simply do:

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
  │ # Clone this repo, naming it "denote-silo"
  │ git clone https://github.com/protesilaos/denote-silo denote-silo
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/denote-silo")
  └────

  Everything is in place to set up the package.


4 Sample configuration
══════════════════════

  ┌────
  │ (use-package denote-silo
  │   :ensure t
  │   ;; Bind these commands to key bindings of your choice.
  │   :commands ( denote-silo-create-note
  │ 	      denote-silo-open-or-create
  │ 	      denote-silo-select-silo-then-command
  │ 	      denote-silo-dired
  │ 	      denote-silo-cd )
  │   :config
  │   ;; Add your silos to this list.  By default, it only includes the
  │   ;; value of the variable `denote-directory'.
  │   (setq denote-silo-directories
  │ 	(list denote-directory
  │ 	      "~/Documents/personal/"
  │ 	      "~/Documents/work/")))
  └────


5 Acknowledgements
══════════════════

  Denote Silo is meant to be a collective effort.  Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.

  Ideas and/or user feedback
        Daniel Kahlenberg.


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
