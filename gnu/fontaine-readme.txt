	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	       FONTAINE.EL: SET FONT CONFIGURATIONS USING
				PRESETS

			  Protesilaos Stavrou
			  info@protesilaos.com
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `fontaine' (or `fontaine.el'), and provides every other
piece of information pertinent to it.

The documentation furnished herein corresponds to stable version 0.1.0,
released on 2022-04-28.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.2.0-dev.

⁃ Homepage: <https://protesilaos.com/emacs/fontaine>.
⁃ Git repository: <https://git.sr.ht/~protesilaos/fontaine>.
⁃ Mailing list: <https://lists.sr.ht/~protesilaos/fontaine>.

Table of Contents
─────────────────

1. COPYING
2. Overview
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

  Fontaine lets the user specify presets of font configurations and set
  them on demand.  The user option `fontaine-presets' holds all such
  presets.

  Presets consist of a list of properties that govern the family,
  weight, and height of the faces `default', `fixed-pitch',
  `variable-pitch', `bold', and `italic'.  Each preset is identified by
  a user-defined symbol as the car of a property list.  It looks like
  this (check the default value of `fontaine-presets' for how everything
  is pieced together):

  ┌────
  │ (regular
  │  :default-family "Hack"
  │  :default-weight normal
  │  :default-height 100
  │  :fixed-pitch-family "Fira Code"
  │  :fixed-pitch-weight nil ; falls back to :default-weight
  │  :fixed-pitch-height 1.0
  │  :variable-pitch-family "Noto Sans"
  │  :variable-pitch-weight normal
  │  :variable-pitch-height 1.0
  │  :bold-family nil ; use whatever the underlying face has
  │  :bold-weight bold
  │  :italic-family "Source Code Pro"
  │  :italic-slant italic
  │  :line-spacing 1)
  └────

  The doc string of `fontaine-presets' explains all properties in detail
  and documents some important caveats or information about font
  settings in Emacs.

  The command `fontaine-set-preset' applies the desired preset.  If
  there is only one available, it implements it outright.  Otherwise it
  produces a minibuffer prompt with completion among the available
  presets.  When called from Lisp, the `fontaine-set-preset' requires a
  PRESET argument, such as:

  ┌────
  │ (fontaine-set-preset 'regular)
  └────

  The command `fontaine-set-face-font' prompts with completion for a
  face and then asks the user to specify the value of the relevant
  properties.  Preferred font families can be defined in the user option
  `fontaine-font-families', otherwise Fontaine will try to find suitable
  options among the fonts installed on the system (not always reliable,
  depending on the Emacs build and environment it runs in).  The list of
  faces to choose from is the same as that implied by the
  `fontaine-presets'.  Properties to change and their respective values
  will depend on the face.  For example, the `default' face requires a
  natural number for its height attribute, whereas every other face
  needs a floating point (understood as a multiple of the default
  height).  This command is for interactive use only and is supposed to
  be used for previewing certain styles before eventually codifying them
  as presets.

  Changing the `bold' and `italic' faces only has a noticeable effect if
  the underlying theme does not hardcode a weight and slant but inherits
  from those faces instead (e.g. the `modus-themes').

  The latest value of `fontaine-set-preset' is stored in a file whose
  location is defined in `fontaine-latest-state-file'.  Saving is done
  by the `fontaine-store-latest-preset' function, which should be
  assigned to a hook (e.g. `kill-emacs-hook').  To restore that value,
  the user can call the function `fontaine-restore-latest-preset' (such
  as by adding it to their init file).

  As for the name of this package, it is the French word for “fountain”
  which, in turn, is what the font or source is.  However, I will not
  blame you if you can only interpret it as a descriptive acronym: FONTs
  Are Irrelevant in Non-graphical Emacs (because that is actually true).


3 Installation
══════════════




3.1 GNU ELPA package
────────────────────

  The package is available as `fontaine'.  Simply do:

  ┌────
  │ M-x package-refresh-contents
  │ M-x package-install
  └────


  And search for it.


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
  │ # Clone this repo, naming it "fontaine"
  │ git clone https://git.sr.ht/~protesilaos/fontaine fontaine
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/fontaine")
  └────

  Everything is in place to set up the package.


4 Sample configuration
══════════════════════

  Remember to read the relevant doc strings.

  ┌────
  │ (require 'fontaine)
  │ 
  │ (setq fontaine-latest-state-file
  │       (locate-user-emacs-file "fontaine-latest-state.eld"))
  │ 
  │ (setq fontaine-presets
  │       '((regular
  │ 	 :default-family "Hack"
  │ 	 :default-weight normal
  │ 	 :default-height 100
  │ 	 :fixed-pitch-family "Fira Code"
  │ 	 :fixed-pitch-weight nil ; falls back to :default-weight
  │ 	 :fixed-pitch-height 1.0
  │ 	 :variable-pitch-family "Noto Sans"
  │ 	 :variable-pitch-weight normal
  │ 	 :variable-pitch-height 1.0
  │ 	 :bold-family nil ; use whatever the underlying face has
  │ 	 :bold-weight bold
  │ 	 :italic-family "Source Code Pro"
  │ 	 :italic-slant italic
  │ 	 :line-spacing 1)
  │ 	(large
  │ 	 :default-family "Iosevka"
  │ 	 :default-weight normal
  │ 	 :default-height 150
  │ 	 :fixed-pitch-family nil ; falls back to :default-family
  │ 	 :fixed-pitch-weight nil ; falls back to :default-weight
  │ 	 :fixed-pitch-height 1.0
  │ 	 :variable-pitch-family "FiraGO"
  │ 	 :variable-pitch-weight normal
  │ 	 :variable-pitch-height 1.05
  │ 	 :bold-family nil ; use whatever the underlying face has
  │ 	 :bold-weight bold
  │ 	 :italic-family nil ; use whatever the underlying face has
  │ 	 :italic-slant italic
  │ 	 :line-spacing 1)))
  │ 
  │ (fontaine-restore-latest-preset)
  │ 
  │ ;; Use `fontaine-recovered-preset' if available, else fall back to the
  │ ;; desired style from `fontaine-presets'.
  │ (if-let ((state fontaine-recovered-preset))
  │     (fontaine-set-preset state)
  │   (fontaine-set-preset 'regular))
  │ 
  │ ;; The other side of `fontaine-restore-latest-preset'.
  │ (add-hook 'kill-emacs-hook #'fontaine-store-latest-preset)
  │ 
  │ ;; fontaine does not define any key bindings.  This is just a sample that
  │ ;; respects the key binding conventions.  Evaluate:
  │ ;;
  │ ;;     (info "(elisp) Key Binding Conventions")
  │ (define-key global-map (kbd "C-c f") #'fontaine-set-preset)
  │ (define-key global-map (kbd "C-c F") #'fontaine-set-face-font)
  └────


5 Acknowledgements
══════════════════

  Fontaine is meant to be a collective effort.  Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to the code or manual
        Eli Zaretskii.


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
