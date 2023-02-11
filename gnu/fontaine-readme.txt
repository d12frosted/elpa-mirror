	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	       FONTAINE.EL: SET FONT CONFIGURATIONS USING
				PRESETS

			  Protesilaos Stavrou
			  info@protesilaos.com
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `fontaine' (or `fontaine.el'), and provides every other
piece of information pertinent to it.

The documentation furnished herein corresponds to stable version 1.0.0,
released on 2023-02-11.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 1.1.0-dev.

⁃ Package name (GNU ELPA): `fontaine'
⁃ Official manual: <https://protesilaos.com/emacs/fontaine>
⁃ Change log: <https://protesilaos.com/emacs/fontaine-changelog>
⁃ Git repo on SourceHut: <https://git.sr.ht/~protesilaos/fontaine>
  • Mirrors:
    ⁃ GitHub: <https://github.com/protesilaos/fontaine>
    ⁃ GitLab: <https://gitlab.com/protesilaos/fontaine>
⁃ Mailing list: <https://lists.sr.ht/~protesilaos/fontaine>
⁃ Backronym: Fonts, Ornaments, and Neat Typography Are Irrelevant in
  Non-graphical Emacs.

Table of Contents
─────────────────

1. COPYING
2. Overview
.. 1. Shared and implicit fallback values for presets
.. 2. Inherit the properties of another named preset
3. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
4. Sample configuration
.. 1. Persist font configurations on theme switch
5. Acknowledgements
6. GNU Free Documentation License
7. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2022-2023 Free Software Foundation, Inc.

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
  them on demand on graphical Emacs frames.  The user option
  `fontaine-presets' holds all such presets.

  Presets consist of a list of properties that govern the family,
  weight, and height of the faces `default', `fixed-pitch',
  `fixed-pitch-serif', `variable-pitch', `bold', and `italic'.  Each
  preset is identified by a user-defined symbol as the car of a property
  list.  It looks like this (check the default value of
  `fontaine-presets' for how everything is pieced together):

  ┌────
  │ (regular
  │  ;; I keep all properties for didactic purposes, but most can be
  │  ;; omitted.
  │  :default-family "Monospace"
  │  :default-weight regular
  │  :default-height 100
  │  :fixed-pitch-family nil ; falls back to :default-family
  │  :fixed-pitch-weight nil ; falls back to :default-weight
  │  :fixed-pitch-height 1.0
  │  :fixed-pitch-serif-family nil ; falls back to :default-family
  │  :fixed-pitch-serif-weight nil ; falls back to :default-weight
  │  :fixed-pitch-serif-height 1.0
  │  :variable-pitch-family "Sans"
  │  :variable-pitch-weight nil
  │  :variable-pitch-height 1.0
  │  :bold-family nil ; use whatever the underlying face has
  │  :bold-weight bold
  │  :italic-family nil
  │  :italic-slant italic
  │  :line-spacing nil)
  └────

  The doc string of `fontaine-presets' explains all properties in detail
  and documents some important caveats or information about font
  settings in Emacs.

  [Shared and implicit fallback values for presets].

  The command `fontaine-set-preset' applies the desired preset.  If
  there is only one available, it implements it outright.  Otherwise it
  produces a minibuffer prompt with completion among the available
  presets.  When called from Lisp, the `fontaine-set-preset' requires a
  PRESET argument, such as:

  ┌────
  │ (fontaine-set-preset 'regular)
  └────

  The default behaviour of `fontaine-set-preset' is to change fonts
  across all graphical frames.  The user can, however, limit the changes
  to a given frame.  For interactive use, this is done by invoking the
  command with a universal prefix argument (`C-u' by default), which
  changes fonts only in the current frame.  When used in Lisp, the FRAME
  argument can be a frame object (satisfies `framep') or a non-nil
  value: the former applies the effects to the given object, while the
  latter means the current frame and thus is the same as interactively
  supplying the prefix argument.

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

  The `fontaine-set-face-font' also accepts an optional FRAME argument,
  which is the same as what was described above for
  `fontaine-set-preset'.

  The latest value of `fontaine-set-preset' is stored in a file whose
  location is defined in `fontaine-latest-state-file' (normally part of
  the `.emacs.d' directory).  Saving is done by the function
  `fontaine-store-latest-preset', which should be assigned to a hook
  (e.g. `kill-emacs-hook').  To restore that value, the user can call
  the function `fontaine-restore-latest-preset' (such as by adding it to
  their init file).

  For users of the `no-littering' package, `fontaine-latest-state-file'
  is not stored in their `.emacs.d', but in a standard directory
  instead: <https://github.com/emacscollective/no-littering>.

  As for the name of this package, it is the French word for “fountain”
  which, in turn, is what the font or source is.  However, I will not
  blame you if you can only interpret it as a descriptive acronym: FONTs
  Are Irrelevant in Non-graphical Emacs (because that is actually true).


[Shared and implicit fallback values for presets] See section 2.1

2.1 Shared and implicit fallback values for presets
───────────────────────────────────────────────────

  [Inherit the properties of another named preset].

  The user option `fontaine-presets' may look like this (though check
  its default value before you make any edits):

  ┌────
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
  └────

  Notice that not all properties need to be specified, as they have
  reasonable fallback values.  The above can be written thus (removed
  lines are left empty for didactic purposes):

  ┌────
  │ (setq fontaine-presets
  │       '((regular
  │ 	 :default-family "Hack"
  │ 
  │ 	 :default-height 100
  │ 	 :fixed-pitch-family "Fira Code"
  │ 
  │ 
  │ 	 :variable-pitch-family "Noto Sans"
  │ 
  │ 
  │ 
  │ 
  │ 	 :italic-family "Source Code Pro"
  │ 
  │ 	 :line-spacing 1)
  │ 	(large
  │ 	 :default-family "Iosevka"
  │ 
  │ 	 :default-height 150
  │ 
  │ 
  │ 
  │ 	 :variable-pitch-family "FiraGO"
  │ 
  │ 
  │ 
  │ 
  │ 
  │ 
  │ 	 :line-spacing 1)))
  └────

  Without the empty lines, we have this, which yields the same results
  as the first example:

  ┌────
  │ (setq fontaine-presets
  │       '((regular
  │ 	 :default-family "Hack"
  │ 	 :default-height 100
  │ 	 :fixed-pitch-family "Fira Code"
  │ 	 :variable-pitch-family "Noto Sans"
  │ 	 :italic-family "Source Code Pro"
  │ 	 :line-spacing 1)
  │ 	(large
  │ 	 :default-family "Iosevka"
  │ 	 :default-height 150
  │ 	 :variable-pitch-family "FiraGO"
  │ 	 :line-spacing 1)))
  └────

  We call the properties of the removed lines “implicit fallback
  values”.

  This already shows us that the value of `fontaine-presets' does not
  need to be extensive.  To further improve its conciseness, it accepts
  a special preset that provides a list of “shared fallback properties”:
  the `t' preset.  This one is used to define properties that are common
  to multiple presets, such as the `regular' and `large' we have
  illustrated thus far.  Here is how verbose presets can be expressed
  succinctly:

  ┌────
  │ ;; Notice the duplication of properties and how we will avoid it.
  │ (setq fontaine-presets
  │       '((regular
  │ 	 :default-family "Iosevka Comfy"
  │ 	 :default-weight normal
  │ 	 :default-height 100
  │ 	 :fixed-pitch-family nil ; falls back to :default-family
  │ 	 :fixed-pitch-weight nil ; falls back to :default-weight
  │ 	 :fixed-pitch-height 1.0
  │ 	 :variable-pitch-family "FiraGO"
  │ 	 :variable-pitch-weight normal
  │ 	 :variable-pitch-height 1.05
  │ 	 :bold-family nil ; use whatever the underlying face has
  │ 	 :bold-weight bold
  │ 	 :italic-family nil
  │ 	 :italic-slant italic
  │ 	 :line-spacing nil)
  │ 	(medium
  │ 	 :default-family "Iosevka Comfy"
  │ 	 :default-weight semilight
  │ 	 :default-height 140
  │ 	 :fixed-pitch-family nil ; falls back to :default-family
  │ 	 :fixed-pitch-weight nil ; falls back to :default-weight
  │ 	 :fixed-pitch-height 1.0
  │ 	 :variable-pitch-family "FiraGO"
  │ 	 :variable-pitch-weight normal
  │ 	 :variable-pitch-height 1.05
  │ 	 :bold-family nil ; use whatever the underlying face has
  │ 	 :bold-weight bold
  │ 	 :italic-family nil
  │ 	 :italic-slant italic
  │ 	 :line-spacing nil)
  │ 	(large
  │ 	 :default-family "Iosevka Comfy"
  │ 	 :default-weight semilight
  │ 	 :default-height 180
  │ 	 :fixed-pitch-family nil ; falls back to :default-family
  │ 	 :fixed-pitch-weight nil ; falls back to :default-weight
  │ 	 :fixed-pitch-height 1.0
  │ 	 :variable-pitch-family "FiraGO"
  │ 	 :variable-pitch-weight normal
  │ 	 :variable-pitch-height 1.05
  │ 	 :bold-family nil ; use whatever the underlying face has
  │ 	 :bold-weight extrabold
  │ 	 :italic-family nil
  │ 	 :italic-slant italic
  │ 	 :line-spacing nil)))
  │ 
  │ (setq fontaine-presets
  │       '((regular
  │ 	 :default-height 100)
  │ 	(medium
  │ 	 :default-weight semilight
  │ 	 :default-height 140)
  │ 	(large
  │ 	 :default-weight semilight
  │ 	 :default-height 180
  │ 	 :bold-weight extrabold)
  │ 	(t ; our shared fallback properties
  │ 	 :default-family "Iosevka Comfy"
  │ 	 :default-weight normal
  │ 	 ;; :default-height 100
  │ 	 :fixed-pitch-family nil ; falls back to :default-family
  │ 	 :fixed-pitch-weight nil ; falls back to :default-weight
  │ 	 :fixed-pitch-height 1.0
  │ 	 :variable-pitch-family "FiraGO"
  │ 	 :variable-pitch-weight normal
  │ 	 :variable-pitch-height 1.05
  │ 	 :bold-family nil ; use whatever the underlying face has
  │ 	 :bold-weight bold
  │ 	 :italic-family nil
  │ 	 :italic-slant italic
  │ 	 :line-spacing nil)))
  └────

  The `t' preset does not need to explicitly cover all properties.  It
  can rely on the aforementioned “implicit fallback values” to further
  reduce its verbosity (though the user can always write all properties
  if they intend to change their values).  We then have this
  transformation:

  ┌────
  │ ;; The verbose form
  │ (setq fontaine-presets
  │       '((regular
  │ 	 :default-height 100)
  │ 	(medium
  │ 	 :default-weight semilight
  │ 	 :default-height 140)
  │ 	(large
  │ 	 :default-weight semilight
  │ 	 :default-height 180
  │ 	 :bold-weight extrabold)
  │ 	(t ; our shared fallback properties
  │ 	 :default-family "Iosevka Comfy"
  │ 	 :default-weight normal
  │ 	 ;; :default-height 100
  │ 	 :fixed-pitch-family nil ; falls back to :default-family
  │ 	 :fixed-pitch-weight nil ; falls back to :default-weight
  │ 	 :fixed-pitch-height 1.0
  │ 	 :variable-pitch-family "FiraGO"
  │ 	 :variable-pitch-weight normal
  │ 	 :variable-pitch-height 1.05
  │ 	 :bold-family nil ; use whatever the underlying face has
  │ 	 :bold-weight bold
  │ 	 :italic-family nil
  │ 	 :italic-slant italic
  │ 	 :line-spacing nil)))
  │ 
  │ ;; The concise one which relies on "implicit fallback values"
  │ (setq fontaine-presets
  │       '((regular
  │ 	 :default-height 100)
  │ 	(medium
  │ 	 :default-weight semilight
  │ 	 :default-height 140)
  │ 	(large
  │ 	 :default-weight semilight
  │ 	 :default-height 180
  │ 	 :bold-weight extrabold)
  │ 	(t ; our shared fallback properties
  │ 	 :default-family "Iosevka Comfy"
  │ 	 :default-weight normal
  │ 	 :variable-pitch-family "FiraGO"
  │ 	 :variable-pitch-height 1.05)))
  └────


[Inherit the properties of another named preset] See section 2.2


2.2 Inherit the properties of another named preset
──────────────────────────────────────────────────

  [Shared and implicit fallback values for presets].

  When defining multiple presets, we may need to duplicate properties
  and then make tweaks to individual values.  Suppose we want to have
  two distinct presets for presentations: one is for coding related
  demonstrations and the other for prose.  Both must have some common
  styles, but must define distinct font families each of which is
  suitable for the given task.  In this case, we do not want to fall
  back to the generic `t' preset (per the default behaviour) and we also
  do not wish to duplicate properties manually, potentially making
  mistakes in the process.  Fontaine thus provides a method of
  inheriting a named preset’s properties by using the `:inherit'
  property with a value that references the name of another preset
  (technically, the `car' of that list).  Here is the idea:

  ┌────
  │ (setq fontaine-presets
  │       '((regular
  │ 	 :default-height 100)
  │ 	(code-demo
  │ 	 :default-family "Source Code Pro"
  │ 	 :default-weight semilight
  │ 	 :default-height 170
  │ 	 :variable-pitch-family "Sans"
  │ 	 :bold-weight extrabold)
  │ 	(prose-demo
  │ 	 :inherit code-demo ; copy the `code-demo' properties
  │ 	 :default-family "Sans"
  │ 	 :variable-pitch-family "Serif"
  │ 	 :default-height 220)
  │ 	(t
  │ 	 :default-family "Monospace"
  │ 	 ;; more generic fallback properties here...
  │ 	 )))
  └────

  In this scenario, the `regular' preset gets all its properties from
  the `t' preset.  We omit them here in the interest of brevity (see the
  default value of `fontaine-presets' and its documentation for the
  details).  In turn, the `code-demo' specifies more properties and
  falls back to `t' for any property not explicitly referenced therein.
  Finally, the `prose-demo' copies everything in `code-demo', overrides
  every property it specifies, and falls back to `t' for every other
  property.

  In the interest of simplicity, Fontaine does not support recursive
  inheritance.  If there is a compelling need for it, we can add it in
  future versions.


[Shared and implicit fallback values for presets] See section 2.1


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
  │ ;; Iosevka Comfy is my highly customised build of Iosevka with
  │ ;; monospaced and duospaced (quasi-proportional) variants as well as
  │ ;; support or no support for ligatures:
  │ ;; <https://git.sr.ht/~protesilaos/iosevka-comfy>.
  │ ;;
  │ ;; Iosevka Comfy            == monospaced, supports ligatures
  │ ;; Iosevka Comfy Fixed      == monospaced, no ligatures
  │ ;; Iosevka Comfy Duo        == quasi-proportional, supports ligatures
  │ ;; Iosevka Comfy Wide       == like Iosevka Comfy, but wider
  │ ;; Iosevka Comfy Wide Fixed == like Iosevka Comfy Fixed, but wider
  │ (setq fontaine-presets
  │       '((tiny
  │ 	 :default-family "Iosevka Comfy Wide Fixed"
  │ 	 :default-height 70)
  │ 	(small
  │ 	 :default-family "Iosevka Comfy Fixed"
  │ 	 :default-height 90)
  │ 	(regular
  │ 	 :default-height 100)
  │ 	(medium
  │ 	 :default-height 110)
  │ 	(large
  │ 	 :default-weight semilight
  │ 	 :default-height 140
  │ 	 :bold-weight extrabold)
  │ 	(presentation
  │ 	 :default-weight semilight
  │ 	 :default-height 170
  │ 	 :bold-weight extrabold)
  │ 	(jumbo
  │ 	 :default-weight semilight
  │ 	 :default-height 220
  │ 	 :bold-weight extrabold)
  │ 	(t
  │ 	 ;; I keep all properties for didactic purposes, but most can be
  │ 	 ;; omitted.  See the fontaine manual for the technicalities:
  │ 	 ;; <https://protesilaos.com/emacs/fontaine>.
  │ 	 :default-family "Iosevka Comfy"
  │ 	 :default-weight regular
  │ 	 :default-height 100
  │ 	 :fixed-pitch-family nil ; falls back to :default-family
  │ 	 :fixed-pitch-weight nil ; falls back to :default-weight
  │ 	 :fixed-pitch-height 1.0
  │ 	 :fixed-pitch-serif-family nil ; falls back to :default-family
  │ 	 :fixed-pitch-serif-weight nil ; falls back to :default-weight
  │ 	 :fixed-pitch-serif-height 1.0
  │ 	 :variable-pitch-family "Iosevka Comfy Duo"
  │ 	 :variable-pitch-weight nil
  │ 	 :variable-pitch-height 1.0
  │ 	 :bold-family nil ; use whatever the underlying face has
  │ 	 :bold-weight bold
  │ 	 :italic-family nil
  │ 	 :italic-slant italic
  │ 	 :line-spacing nil)))
  │ 
  │ ;; Recover last preset or fall back to desired style from
  │ ;; `fontaine-presets'.
  │ (fontaine-set-preset (or (fontaine-restore-latest-preset) 'regular))
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


4.1 Persist font configurations on theme switch
───────────────────────────────────────────────

  Themes re-apply face definitions when they are loaded.  This is
  necessary to render the theme.  For certain faces, such as `bold' and
  `italic', it means that their font family may be reset (depending on
  the particularities of the theme).

  To avoid such a problem, we can arrange to restore the current font
  preset which was applied by `fontaine-set-preset'.  Fontaine provides
  the command `fontaine-apply-current-preset'.  It can either be called
  interactively after loading a theme or be assigned to a hook that is
  ran at the post `load-theme' phase.

  Some themes that provide a hook are the `modus-themes' and `ef-themes'
  (both by Protesilaos), so we can use something like:

  ┌────
  │ (add-hook 'modus-themes-after-load-theme-hook #'fontaine-apply-current-preset))
  └────

  If both packages are used, we can either write two lines of `add-hook'
  or do this:

  ┌────
  │ ;; Persist font configurations while switching themes (doing it with
  │ ;; my `modus-themes' and `ef-themes' via the hooks they provide).
  │ (dolist (hook '(modus-themes-after-load-theme-hook ef-themes-post-load-hook))
  │   (add-hook hook #'fontaine-apply-current-preset))
  └────

  Themes must specify a hook that is called by their relevant commands
  at the post-theme-load phase.  This can also be done in a
  theme-agnostic way:

  ┌────
  │ ;; Set up the `after-enable-theme-hook'
  │ (defvar after-enable-theme-hook nil
  │   "Normal hook run after enabling a theme.")
  │ 
  │ (defun run-after-enable-theme-hook (&rest _args)
  │   "Run `after-enable-theme-hook'."
  │   (run-hooks 'after-enable-theme-hook))
  │ 
  │ (advice-add 'enable-theme :after #'run-after-enable-theme-hook)
  └────

  And then simply use that hook:

  ┌────
  │ (add-hook 'after-enable-theme-hook #'fontaine-apply-current-preset)
  └────


5 Acknowledgements
══════════════════

  Fontaine is meant to be a collective effort.  Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to the code or manual
        Christopher League, Eli Zaretskii, Florent Teissier, Terry
        F. Torrey.

  Ideas and user feedback
        Joe Higton, Ted Reed.


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
