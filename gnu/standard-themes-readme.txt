           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            STANDARD-THEMES: LIKE THE DEFAULT THEME BUT MORE
                               CONSISTENT

                          Protesilaos Stavrou
                          info@protesilaos.com
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the Emacs package
called `standard-themes', and provides every other piece of information
pertinent to it.

The documentation furnished herein corresponds to stable version 3.0.0,
released on 2025-11-09.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 3.1.0-dev.

⁃ Package name (GNU ELPA): `standard-themes'
⁃ Official manual: <https://protesilaos.com/emacs/standard-themes>
⁃ Change log: <https://protesilaos.com/emacs/standard-themes-changelog>
⁃ Sample pictures:
  <https://protesilaos.com/emacs/standard-themes-pictures>
⁃ Git repositories:
  ⁃ GitHub: <https://github.com/protesilaos/standard-themes>
  ⁃ GitLab: <https://gitlab.com/protesilaos/standard-themes>
⁃ Backronym: Standard Themes Are Not Derivatives but the Affectionately
  Reimagined Default … themes.

If you are viewing the README.org version of this file, please note that
the GNU ELPA machinery automatically generates an Info manual out of it.

Table of Contents
─────────────────

1. COPYING
2. About the Standard themes
3. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
4. Sample configuration
5. Working with other Modus themes or taking over Modus
.. 1. Loading only Standard themes with the convenience wrappers we provide
.. 2. Combining core Modus themes with all their derivatives
.. 3. Taking over the Modus commands altogether
.. 4. Customisation options for compatibility with Modus
6. Acknowledgements
7. GNU Free Documentation License
8. Indices
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


2 About the Standard themes
═══════════════════════════

  The `standard-themes' are a collection of light and dark themes for
  GNU Emacs. The `standard-light' and `standard-dark' emulate the
  out-of-the-box looks of Emacs (which technically do NOT constitute a
  theme) while bringing to them thematic consistency, customizability,
  and extensibility. Other themes are stylistic variations of those.

  Why call them “standard”? Obviously because: Standard Themes Are Not
  Derivatives but the Affectionately Reimagined Default … themes.

  Starting with version `3.0.0', the `standard-themes' are built on top
  of the `modus-themes'. This means that all customisation options of
  the Modus themes apply to the Standard themes ([Sample
  configuration]).  Same for all Modus commands that load a
  theme. Enable `standard-themes-take-over-modus-themes-mode' to set up
  this arrangement (or enable `modus-themes-include-derivatives-mode'
  instead to blend Standard and Modus into one collection).


[Sample configuration] See section 4


3 Installation
══════════════




3.1 GNU ELPA package
────────────────────

  The package is available as `standard-themes'.  Simply do:

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
  │ # Clone this repo, naming it "standard-themes"
  │ git clone https://github.com/protesilaos/standard-themes standard-themes
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/standard-themes")
  └────

  Everything is in place to set up the package.


4 Sample configuration
══════════════════════

  Starting with version `3.0.0', the `standard-themes' are built on top
  of the `modus-themes'. This means that all customisation is done via
  the Modus user options ([Customisation options]). Furthermore, all
  theme-loading commands are those of Modus ([Working with other Modus
  themes or taking over Modus]).

  ┌────
  │ (use-package standard-themes
  │   :ensure t
  │   :init
  │   ;; This makes the Modus commands listed below consider only the Ef
  │   ;; themes.  For an alternative that includes Modus and all
  │   ;; derivative themes (like Ef), enable the
  │   ;; `modus-themes-include-derivatives-mode' instead.  The manual of
  │   ;; the Ef themes has a section that explains all the possibilities:
  │   ;;
  │   ;; - Evaluate `(info "(standard-themes) Working with other Modus themes or taking over Modus")'
  │   ;; - Visit <https://protesilaos.com/emacs/standard-themes#h:d8ebe175-cd61-4e0b-9b84-7a4f5c7e09cd>
  │   (standard-themes-take-over-modus-themes-mode 1)
  │   :bind
  │   (("<f5>" . modus-themes-rotate)
  │    ("C-<f5>" . modus-themes-select)
  │    ("M-<f5>" . modus-themes-load-random))
  │   :config
  │   ;; All customisations here.
  │   (setq modus-themes-mixed-fonts t)
  │   (setq modus-themes-italic-constructs t)
  │ 
  │   ;; Finally, load your theme of choice (or a random one with
  │   ;; `modus-themes-load-random', `modus-themes-load-random-dark',
  │   ;; `modus-themes-load-random-light').
  │   (modus-themes-load-theme 'standard-light-tinted))
  └────


[Customisation options] See section 5.4

[Working with other Modus themes or taking over Modus] See section 5


5 Working with other Modus themes or taking over Modus
══════════════════════════════════════════════════════

  Starting version `3.0.0', the Standard themes are built on top of the
  Modus themes. This means that they inherit the comprehensive
  infrastructure of Modus and all of its wide face/package coverage. To
  make the change easier for existing users, we provide aliases for user
  options and commands.


5.1 Loading only Standard themes with the convenience wrappers we provide
─────────────────────────────────────────────────────────────────────────

  All the old commands Standard provided for loading one of its themes
  will still work as before, meaning that they will only ever show and
  load a theme that belongs to the Standard collection ([Combining core
  Modus themes with all their derivatives]).

  Internally, these commands are now using the Modus infrastructure and
  are then limiting the set of themes to the Standard collection. They
  are thus convenience wrappers around the equivalent Modus commands.

  • `standard-themes-toggle'

  • `standard-themes-rotate'

  • `standard-themes-select'

  • `standard-themes-load-random'

  • `standard-themes-load-random-dark'

  • `standard-themes-load-random-light'

  Additionally, the commands `standard-themes-list-colors' and
  `standard-themes-list-colors-current' use the relevant Modus
  functionality under the hood while working only with Standard themes.

  Depending on their needs, users may prefer to take over Modus
  completely, instead of relying on these convenience wrapper commands
  ([Taking over the Modus commands altogether]).


[Combining core Modus themes with all their derivatives] See section 5.2

[Taking over the Modus commands altogether] See section 5.3


5.2 Combining core Modus themes with all their derivatives
──────────────────────────────────────────────────────────

  The minor mode `modus-themes-include-derivatives-mode' makes all the
  theme-loading commands that Modus defines consider all core and
  derivative themes. This means that something like
  `modus-themes-select' will offer `modus-operandi' and `ef-summer' as
  two of the many possible candidates.

  In this scenario, the Modus and Standard collections become part of a
  larger family of themes as opposed to only considering one or the
  other ([Loading only Standard themes with the convenience wrappers we
  provide]).  Enable `modus-themes-include-derivatives-mode' and then
  access them all with the following commands:

  • `modus-themes-toggle'

  • `modus-themes-rotate'

  • `modus-themes-select'

  • `modus-themes-load-random'

  • `modus-themes-load-random-dark'

  • `modus-themes-load-random-light'

  • `modus-themes-list-colors' (alias `modus-themes-preview-colors')

  • `modus-themes-list-colors-current' (alias
    `modus-themes-preview-colors-current')

  Consult the manual of the Modus themes for further details and/or read
  the documentation string of each command.


[Loading only Standard themes with the convenience wrappers we provide]
See section 5.1


5.3 Taking over the Modus commands altogether
─────────────────────────────────────────────

  The minor mode `standard-themes-take-over-modus-themes-mode' makes all
  Modus commands that load a theme consider only Standard themes. This
  is the opposite of allowing different theme collections to be blended
  together ([Combining core Modus themes with all their derivatives]).
  It effectively is the same as using one of the convenience wrapper
  commands we already provide ([Loading only Standard themes with the
  convenience wrappers we provide]).

  This minor mode exists to accommodate the needs of users who install
  both the Modus and Standard theme packages (and possibly other Modus
  derivatives). They can maintain a single/shared configuration and then
  decide when to enable `standard-themes-take-over-modus-themes-mode' to
  switch to using just the Standard themes. In this scenario, a key
  binding to, say, `modus-themes-rotate' does not need to be updated: it
  internally reads only Standard themes. When
  `standard-themes-take-over-modus-themes-mode' is disabled, that same
  key binding will revert to doing what it did before (load only a core
  Modus theme or Modus plus derivatives if
  `modus-themes-include-derivatives-mode' is enabled).


[Combining core Modus themes with all their derivatives] See section 5.2

[Loading only Standard themes with the convenience wrappers we provide]
See section 5.1


5.4 Customisation options for compatibility with Modus
──────────────────────────────────────────────────────

  Consult the Modus themes manual for all customisation options. All the
  user options defined by the Standard themes prior to their version
  `3.0.0' (i.e. before building on top of the Modus themes) are now
  aliases for the equivalent Modus options. We do this for backward
  compatibility.  Concretely:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Old name                                  Is alias for CURRENT NAME             
  ─────────────────────────────────────────────────────────────────────────────────
   standard-themes-disable-other-themes      modus-themes-disable-other-themes     
   standard-themes-to-toggle                 modus-themes-to-toggle                
   standard-themes-to-rotate                 modus-themes-to-rotate                
   standard-themes-after-load-theme-hook     modus-themes-after-load-theme-hook    
   standard-themes-italic-constructs         modus-themes-italic-constructs        
   standard-themes-bold-constructs           modus-themes-bold-constructs          
   standard-themes-variable-pitch-ui         modus-themes-variable-pitch-ui        
   standard-themes-mixed-fonts               modus-themes-mixed-fonts              
   standard-themes-headings                  modus-themes-headings                 
   standard-themes-completions               modus-themes-completions              
   standard-themes-prompts                   modus-themes-prompts                  
   standard-themes-common-palette-overrides  modus-themes-common-palette-overrides 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


6 Acknowledgements
══════════════════

  This project is meant to be a collective effort.  Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to code
        Clemens Radermacher, Trevor Arjeski.

  Ideas and/or user feedback
        EyoelYT, Filippo Argiolas, Fritz Grabo, Manuel Uberti, Tassilo
        Horn, Zack Weinberg.


7 GNU Free Documentation License
════════════════════════════════


8 Indices
═════════

8.1 Function index
──────────────────


8.2 Variable index
──────────────────


8.3 Concept index
─────────────────
