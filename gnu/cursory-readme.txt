            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             CURSORY.EL: MANAGE CURSOR STYLES USING PRESETS

                          Protesilaos Stavrou
                          info@protesilaos.com
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `cursory' (or `cursory.el'), and provides every other piece
of information pertinent to it.

The documentation furnished herein corresponds to stable version 1.2.0,
released on 2025-07-22.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 1.3.0-dev.

⁃ Package name (GNU ELPA): `cursory'
⁃ Official manual: <https://protesilaos.com/emacs/cursory>
⁃ Change log: <https://protesilaos.com/emacs/cursory-changelog>
⁃ Git repositories:
  ⁃ GitHub: <https://github.com/protesilaos/cursory>
  ⁃ GitLab: <https://gitlab.com/protesilaos/cursory>
⁃ Backronym: Cursor Usability Requires Styles Objectively Rated
  Yearlong.

Table of Contents
─────────────────

1. COPYING
2. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
3. Sample configuration
4. Overview
.. 1. Example hooks after setting a preset
5. Acknowledgements
6. Also see
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


2 Installation
══════════════




2.1 GNU ELPA package
────────────────────

  The package is available as `cursory'.  Simply do:

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
  │ # Clone this repo, naming it "cursory"
  │ git clone https://github.com/protesilaos/cursory cursory
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/cursory")
  └────

  Everything is in place to set up the package.


3 Sample configuration
══════════════════════

  Remember to read the doc string of each of these variables or
  functions.

  ┌────
  │ (use-package cursory
  │   :ensure t
  │   :demand t
  │   :if (display-graphic-p)
  │   :config
  │   (setq cursory-presets
  │ 	'((box
  │ 	   :cursor-color success ; will typically be green
  │ 	   :blink-cursor-interval 1.2)
  │ 	  (box-no-blink
  │ 	   :inherit box
  │ 	   :blink-cursor-mode -1)
  │ 	  (bar
  │ 	   :cursor-type (bar . 2)
  │ 	   :cursor-color error ; will typically be red
  │ 	   :blink-cursor-interval 0.8)
  │ 	  (bar-no-other-window
  │ 	   :inherit bar
  │ 	   :cursor-in-non-selected-windows nil)
  │ 	  (bar-no-blink
  │ 	   :inherit bar
  │ 	   :blink-cursor-mode -1)
  │ 	  (underscore
  │ 	   :cursor-color warning ; will typically be yellow
  │ 	   :cursor-type (hbar . 3)
  │ 	   :blink-cursor-interval 0.3
  │ 	   :blink-cursor-blinks 50)
  │ 	  (underscore-no-other-window
  │ 	   :inherit underscore
  │ 	   :cursor-in-non-selected-windows nil)
  │ 	  (underscore-thick
  │ 	   :inherit underscore
  │ 	   :cursor-type (hbar . 8)
  │ 	   :cursor-in-non-selected-windows (hbar . 3))
  │ 	  (t ; the default values
  │ 	   :cursor-color unspecified ; use the theme's original
  │ 	   :cursor-type box
  │ 	   :cursor-in-non-selected-windows hollow
  │ 	   :blink-cursor-mode 1
  │ 	   :blink-cursor-blinks 10
  │ 	   :blink-cursor-interval 0.2
  │ 	   :blink-cursor-delay 0.2)))
  │ 
  │   ;; I am using the default value of `cursory-latest-state-file'.
  │ 
  │   ;; Set last preset or fall back to desired style from
  │   ;; `cursory-presets'.  Alternatively, use the function
  │   ;; `cursory-set-last-or-fallback' (can be added to the
  │   ;; `after-init-hook'.
  │   (cursory-set-preset (or (cursory-restore-latest-preset) 'box))
  │ 
  │   ;; Persist configurations between Emacs sessions.  Also apply the
  │   ;; :cursor-color again when swithcing to another theme.
  │   (cursory-mode 1)
  │   :bind
  │   ;; We have to use the "point" mnemonic, because C-c c is often the
  │   ;; suggested binding for `org-capture' and is the one I use as well.
  │   ("C-c p" . cursory-set-preset))
  └────


4 Overview
══════════

  Cursory lets users define preset configurations for the cursor. Those
  cover the style of the cursor (e.g. box or bar), whether it is
  blinking or not, and how fast, as well as the colour it uses. Having
  distinct presets makes it easy to switch between, say, a “reading
  mode” with an ambient cursor and a “presentation mode” with a cursor
  that is more noticeable and thus easier to spot.

  The user option `cursory-presets' holds the presets.  The command
  `cursory-set-preset' is applies one among them.  The command supports
  minibuffer completion when there are multiple presets, else sets the
  single preset outright.

  The `cursory-set-preset' comman calls the `cursory-set-preset-hook' as
  its final step. Use this to run other functions after changing the
  cursor ([Example hooks after setting a preset]). The variable
  `cursory-last-selected-preset' may prove useful.

  Presets consist of an arbitrary symbol broadly described the style set
  followed by a list of properties that govern the cursor type in the
  active and inactive windows, as well as cursor blinking variables.
  They look like this:

  ┌────
  │ (bar
  │  :cursor-color unspecified
  │  :cursor-type (bar . 2)
  │  :cursor-in-non-selected-windows hollow
  │  :blink-cursor-mode 1
  │  :blink-cursor-blinks 10
  │  :blink-cursor-interval 0.5
  │  :blink-cursor-delay 0.2)
  └────

  The car of the list is an arbitrary, user-defined symbol that
  identifies (and can describe) the set.  Each of the properties
  corresponds to built-in variables: `cursor-type',
  `cursor-in-non-selected-windows', `blink-cursor-blinks',
  `blink-cursor-interval', `blink-cursor-delay'.  The value each
  property accepts is the same as the variable it references.

  The `:cursor-color' specifies the color value applied to the `cursor'
  face. When the value is nil or `unspecified', no changes to the
  `cursor' face are made. When the value is a hexadecimal RGB color
  value, like `#123456' it is used as-is. Same if it is a named color
  among those produced by the command `list-colors-display'. When the
  value is the symbol of a face (unquoted), then the foreground of that
  face is used for the `cursor' face, falling back to `default'.

  A property of `:blink-cursor-mode' is also available.  It is a numeric
  value of either `1' or `-1' and is given to the function
  `blink-cursor-mode': `1' is to enable, `-1' is to disable the mode.

  Presets can inherit from each other.  Using the special `:inherit'
  property, like this:

  ┌────
  │ (setq cursory-presets
  │       '(
  │ 	;; Sample code here ...
  │ 	(bar
  │ 	 :cursor-type (bar . 2)
  │ 	 :cursor-in-non-selected-windows hollow
  │ 	 :blink-cursor-mode 1
  │ 	 :blink-cursor-blinks 10
  │ 	 :blink-cursor-interval 0.5
  │ 	 :blink-cursor-delay 0.2)
  │ 
  │ 	(bar-no-other-window
  │ 	 :inherit bar
  │ 	 :cursor-in-non-selected-windows nil)
  │ 	;; More sample code here ...
  │ 	))
  └────

  In the above example, the `bar-no-other-window' is the same as `bar'
  except for the value of `:cursor-in-non-selected-windows'.

  The value given to the `:inherit' property corresponds to the name of
  another named preset (unquoted).  This tells the relevant Cursory
  functions to get the properties of that given preset and blend them
  with those of the current one.  The properties of the current preset
  take precedence over those of the inherited one, thus overriding them.

  A preset whose car is `t' is treated as the default option.  This
  makes it possible to specify multiple presets without duplicating
  their properties.  Presets beside `t' act as overrides of the defaults
  and, as such, need only consist of the properties that change from the
  default.  In the case of an `:inherit', properties are first taken
  from the inherited preset and then the default one.  See the original
  value of this variable for how that is done:

  ┌────
  │ (defcustom cursory-presets
  │   '((box
  │      :blink-cursor-interval 0.8)
  │     (box-no-blink
  │      :blink-cursor-mode -1)
  │     (bar
  │      :cursor-type (bar . 2)
  │      :blink-cursor-interval 0.5)
  │     (bar-no-other-window
  │      :inherit bar
  │      :cursor-in-non-selected-windows nil)
  │     (underscore
  │      :cursor-type (hbar . 3)
  │      :blink-cursor-blinks 50)
  │     (underscore-thin-other-window
  │      :inherit underscore
  │      :cursor-in-non-selected-windows (hbar . 1))
  │     (t ; the default values
  │      :cursor-type box
  │      :cursor-in-non-selected-windows hollow
  │      :blink-cursor-mode 1
  │      :blink-cursor-blinks 10
  │      :blink-cursor-interval 0.2
  │      :blink-cursor-delay 0.2))
  │   ;; Omitting the doc string for demo purposes
  │   )
  └────

  When called from Lisp, the `cursory-set-preset' command requires a
  PRESET argument, such as:

  ┌────
  │ (cursory-set-preset 'bar)
  └────

  The function `cursory-store-latest-preset' is used to save the last
  selected style in the `cursory-latest-state-file'.  The value can then
  be restored with the `cursory-restore-latest-preset' function.

  [Sample configuration].

  Instead of manually storing the latest Cursory preset, users can
  enable the `cursory-mode'. It arranges to track the latest preset each
  time after using `cursory-set-preset' or Emacs is closed. The mode
  will also persist the `:cursor-color' attribute, if set, when
  switching to another theme. Otherwise, the theme’s style will take
  precedence.

  The function `cursory-set-last-or-fallback' can be added to the user
  configuration to automatically set the last known Cursory preset or
  some known fallback values.


[Example hooks after setting a preset] See section 4.1

[Sample configuration] See section 3

4.1 Example hooks after setting a preset
────────────────────────────────────────

  The `cursory-set-preset-hook' is a normal hook (where functions are
  invoked without any arguments), which is called after the command
  `cursory-set-preset'. Here are some ideas on how to use it:

  ┌────
  │ ;; Imagine you have a preset where you want minimal cursor styles.
  │ ;; You call this `focus' and want when you switch to it to change the
  │ ;; cursor color.
  │ (defun my-cursory-change-color ()
  │ "Change to a subtle color when the `focus' Cursory preset is selected."
  │   (if (eq cursory-last-selected-preset 'focus)
  │       (set-face-background 'cursor "#999999")
  │     (face-spec-recalc 'cursor nil)))
  │ 
  │ (defun my-cursory-change-color-disable-line-numbers ()
  │   "Disable line numbers if the Cursory preset is `presentation' or `focus'."
  │   (when (memq cursory-last-selected-preset '(presentation focus))
  │     (display-line-numbers-mode -1)))
  └────

  I am happy to include more examples here, if users have any questions.


5 Acknowledgements
══════════════════

  Cursory is meant to be a collective effort.  Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to the code or manual
        Christopher League, Mehdi Khawari, Nicholas Vollmer, Philip
        Kaludercic, Stefan Monnier.


6 Also see
══════════

  The `electric-cursor' package by Case Duckworth lets the user
  automatically change the cursor style when a certain mode is
  activated.  For example, the box is the default and switches to a bar
  when `overwrite-mode' is on:
  <https://github.com/duckwork/electric-cursor>.


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
