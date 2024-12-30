           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            STANDARD-THEMES: LIKE THE DEFAULT THEME BUT MORE
                               CONSISTENT

                          Protesilaos Stavrou
                          info@protesilaos.com
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the Emacs package
called `standard-themes', and provides every other piece of information
pertinent to it.

The documentation furnished herein corresponds to stable version 2.2.0,
released on 2024-12-29.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 2.3.0-dev.

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
5. Customization options
.. 1. Option to disable other themes
.. 2. Option for themes to toggle
.. 3. Option for themes to rotate
.. 4. Option to enable mixed fonts
.. 5. Option to control the UI typeface
.. 6. Option to enable more bold constructs
.. 7. Option to enable more italic constructs
.. 8. Option for command prompts
.. 9. Option for headings
.. 10. Palette overrides
6. Loading a theme
7. Preview theme colors
8. Use colors from the active Standard theme
9. Do-It-Yourself customizations
.. 1. Get a single color from the palette
.. 2. The general approach to advanced DIY changes
.. 3. A theme-agnostic hook for theme loading
.. 4. Add support for hl-todo
.. 5. Configure bold and italic faces
.. 6. Tweak `org-modern' timestamps
.. 7. Tweak goto-address-mode faces
10. Faces defined by the Standard themes
11. Supported packages or face groups
.. 1. Explicitly supported packages or face groups
.. 2. Implicitly supported packages or face groups
.. 3. Packages that are hard to support
12. Acknowledgements
13. GNU Free Documentation License
14. Indices
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


2 About the Standard themes
═══════════════════════════

  The `standard-themes' are a collection of light and dark themes for
  GNU Emacs. The `standard-light' and `standard-dark' emulate the
  out-of-the-box looks of Emacs (which technically do NOT constitute a
  theme) while bringing to them thematic consistency, customizability,
  and extensibility. Other themes are stylistic variations of those.

  Why call them “standard”? Obviously because: Standard Themes Are Not
  Derivatives but the Affectionately Reimagined Default … themes.


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

  ┌────
  │ ;; Make customisations that affect Emacs faces BEFORE loading a theme
  │ ;; (any change needs a theme re-load to take effect).
  │ (require 'standard-themes)
  │ 
  │ ;; Read the doc string of each of those user options.  These are some
  │ ;; sample values.
  │ (setq standard-themes-bold-constructs t
  │       standard-themes-italic-constructs t
  │       standard-themes-disable-other-themes t
  │       standard-themes-mixed-fonts t
  │       standard-themes-variable-pitch-ui t
  │       standard-themes-prompts '(extrabold italic)
  │       standard-themes-to-toggle '(standard-light standard-dark)
  │       standard-themes-to-rotate '(standard-light standard-light-tinted standard-dark standard-dark-tinted)
  │ 
  │       ;; more complex alist to set weight, height, and optional
  │       ;; `variable-pitch' per heading level (t is for any level not
  │       ;; specified):
  │       standard-themes-headings
  │       '((0 . (variable-pitch light 1.9))
  │ 	(1 . (variable-pitch light 1.8))
  │ 	(2 . (variable-pitch light 1.7))
  │ 	(3 . (variable-pitch semilight 1.6))
  │ 	(4 . (variable-pitch semilight 1.5))
  │ 	(5 . (variable-pitch 1.4))
  │ 	(6 . (variable-pitch 1.3))
  │ 	(7 . (variable-pitch 1.2))
  │ 	(agenda-date . (1.3))
  │ 	(agenda-structure . (variable-pitch light 1.8))
  │ 	(t . (variable-pitch 1.1))))
  │ 
  │ ;; All the Standard themes are listed in `standard-themes-items'.
  │ (standard-themes-load-theme 'standard-light)
  │ 
  │ (define-key global-map (kbd "<f5>") #'standard-themes-toggle)
  │ (define-key global-map (kbd "M-<f5>") #'standard-themes-rotate)
  └────


5 Customization options
═══════════════════════

  The `standard-themes' provide user options which tweak secondary
  aspects of the theme. All customizations need to be evaluated before
  loading a theme. Any change after the theme has been loaded requires a
  re-load ([Loading a theme]).


[Loading a theme] See section 6

5.1 Option to disable other themes
──────────────────────────────────

  The user option `standard-themes-disable-other-themes' controls
  whether to disable other themes when loading a Standard theme
  ([Loading a theme]).

  When the value is non-nil, the command `standard-themes-toggle' as
  well as the functions `standard-themes-load-dark' and
  `standard-themes-load-light', will disable all other themes while
  loading the given Standard theme. This is done to ensure that Emacs
  does not blend two or more themes: such blends lead to awkward results
  that undermine the work of the designer.

  When the value is nil, the aforementioned command and functions will
  only disable the other Standard theme.

  This option is provided because Emacs themes are not necessarily
  limited to colors/faces: they can consist of an arbitrary set of
  customizations.  Users who use such customization bundles must set
  this variable to a nil value.


[Loading a theme] See section 6


5.2 Option for themes to toggle
───────────────────────────────

  The user option `standard-themes-to-toggle' is a list of Standard
  themes to switch between when using the command
  `standard-themes-toggle'.

  The list must include two items. If there are more, they are ignored.


5.3 Option for themes to rotate
───────────────────────────────

  The user option `standard-themes-to-rotate' is a list of Standard
  themes to switch between when using the command
  `standard-themes-rotate'.


5.4 Option to enable mixed fonts
────────────────────────────────

  The user option `standard-themes-mixed-fonts' controls whether
  strictly spacing-sensitive constructs inherit from `fixed-pitch' (a
  monospaced font family) to ensure proper alignment at all times.

  By default (a `nil' value for this user option) no face inherits from
  `fixed-pitch': they all use the default font family, regardless of
  whether it is monospaced or not.

  When `standard-themes-mixed-fonts' is set to a non-`nil' value, faces
  such as for Org tables, inline code, code blocks, and the like, are
  rendered in a monospaced font (the inherit the `fixed-pitch' face).
  The user can thus set their default font family to a proportionately
  spaced font without worrying about breaking the alignment of relevant
  elements (or if they simply prefer the aesthetics of mixed mono and
  proportionately spaced font families).

  A temporary switch to a proportionately spaced font (known in Emacs as
  `variable-pitch') can be enabled in the current buffer with the
  activation of the built-in `variable-pitch-mode'. Mixed fonts work
  well in this case.

  To get consistent typography, the user may need to edit the font
  family of the `fixed-pitch' and `variable-pitch' faces.  The
  `fontaine' package on GNU ELPA (by Protesilaos) can be helpful in this
  regard.


5.5 Option to control the UI typeface
─────────────────────────────────────

  The user option `standard-themes-variable-pitch-ui' controls whether
  the elements of the User Interface (UI) use a proportionately spaced
  font.

  By default (a `nil' value), all UI elements use the default font
  family. When this user option is set to a non-`nil' value, all UI
  elements will inherit the face `variable-pitch', thus rendering them
  in a proportionately spaced font.

  In this context, the UI elements are:

  • `header-line'
  • `mode-line' (active and inactive)
  • `tab-bar-mode'
  • `tab-line-mode'

  To get consistent typography, the user may need to edit the font
  family of the `fixed-pitch' and `variable-pitch' faces.  The
  `fontaine' package on GNU ELPA (by Protesilaos) can be helpful in this
  regard.


5.6 Option to enable more bold constructs
─────────────────────────────────────────

  The user option `standard-themes-bold-constructs' determines whether
  select faces will inherit the `bold' face. When the value is
  non-`nil', a bold weight is applied to code constructs. This affects
  keywords, builtins, and a few other elements.

  [Configure bold and italic faces].


[Configure bold and italic faces] See section 9.5


5.7 Option to enable more italic constructs
───────────────────────────────────────────

  The user option `standard-themes-italic-constructs' determines whether
  select faces will inherit the `italic' face. When the value is
  non-`nil', an italic style is applied to code constructs. This affects
  comments, doc strings, and a few other minor elements.

  [Configure bold and italic faces].


[Configure bold and italic faces] See section 9.5


5.8 Option for command prompts
──────────────────────────────

  The user option `standard-themes-prompts' controls the style of all
  prompts, such as those of the minibuffer and REPLs.

  Possible values are expressed as a list of properties (default is
  `nil' or an empty list). The list can include any of the following
  symbols:

  ⁃ `italic'
  ⁃ A font weight, which must be supported by the underlying typeface:
    • `thin'
    • `ultralight'
    • `extralight'
    • `light'
    • `semilight'
    • `regular'
    • `medium'
    • `semibold'
    • `bold'
    • `heavy'
    • `extrabold'
    • `ultrabold'

  The default (a `nil' value or an empty list) means to only use a
  foreground color without any typographic additions.

  The `italic' property adds a slant to the font’s forms (italic or
  oblique forms, depending on the typeface).

  The symbol of a font weight attribute such as `light', `semibold', et
  cetera, adds the given weight to links. Valid symbols are defined in
  the variable `standard-themes-weights'. The absence of a weight means
  that the one of the underlying text will be used.

  Combinations of any of those properties are expressed as a list, like
  in these examples:

  ┌────
  │ (bold italic)
  │ (italic semibold)
  └────

  The order in which the properties are set is not significant.

  In user configuration files the form may look like this:

  ┌────
  │ (setq standard-themes-prompts '(extrabold italic))
  └────

  The foreground and background colors of prompts can be modified by
  applying palette overrides ([Palette overrides]).


[Palette overrides] See section 5.10


5.9 Option for headings
───────────────────────

  The user option `standard-themes-headings' provides support for
  individual heading styles for regular heading levels 0 through 8, as
  well as the Org agenda headings.

  This is an alist that accepts a `(KEY . LIST-OF-VALUES)' combination.
  The `KEY' is either a number, representing the heading’s level (0
  through 8) or `t', which pertains to the fallback style.  The named
  keys `agenda-date' and `agenda-structure' apply to the Org agenda.

  Level 0 is a special heading: it is used for what counts as a document
  title or equivalent, such as the `#+title' construct we find in Org
  files.  Levels 1-8 are regular headings.

  The `LIST-OF-VALUES' covers symbols that refer to properties, as
  described below.  Here is a complete sample with various stylistic
  combinations, followed by a presentation of all available properties:

  ┌────
  │ (setq standard-themes-headings
  │       '((1 . (variable-pitch 1.5))
  │ 	(2 . (1.3))
  │ 	(agenda-date . (1.3))
  │ 	(agenda-structure . (variable-pitch light 1.8))
  │ 	(t . (1.1))))
  └────

  Properties:

  ⁃ A font weight, which must be supported by the underlying typeface:
    • `thin'
    • `ultralight'
    • `extralight'
    • `light'
    • `semilight'
    • `regular'
    • `medium'
    • `semibold'
    • `bold' (default)
    • `heavy'
    • `extrabold'
    • `ultrabold'
  ⁃ A floating point as a height multiple of the default or a cons cell
    in the form of `(height . FLOAT)'.

  By default (a `nil' value for this variable), all headings have a bold
  typographic weight and use a desaturated text color.

  A `variable-pitch' property changes the font family of the heading to
  that of the `variable-pitch' face (normally a proportionately spaced
  typeface).

  The symbol of a weight attribute adjusts the font of the heading
  accordingly, such as `light', `semibold', etc.  Valid symbols are
  defined in the variable `standard-themes-weights'.  The absence of a
  weight means that bold will be used by virtue of inheriting the `bold'
  face.

  A number, expressed as a floating point (e.g. 1.5), adjusts the height
  of the heading to that many times the base font size.  The default
  height is the same as 1.0, though it need not be explicitly stated.
  Instead of a floating point, an acceptable value can be in the form of
  a cons cell like `(height . FLOAT)' or `(height FLOAT)', where FLOAT
  is the given number.

  Combinations of any of those properties are expressed as a list, like
  in these examples:

  ┌────
  │ (semibold)
  │ (variable-pitch semibold 1.3)
  │ (variable-pitch semibold (height 1.3)) ; same as above
  │ (variable-pitch semibold (height . 1.3)) ; same as above
  └────

  The order in which the properties are set is not significant.

  In user configuration files the form may look like this:

  ┌────
  │ (setq standard-themes-headings
  │       '((1 . (variable-pitch 1.5))
  │ 	(2 . (1.3))
  │ 	(agenda-date . (1.3))
  │ 	(agenda-structure . (variable-pitch light 1.8))
  │ 	(t . (1.1))))
  └────

  When defining the styles per heading level, it is possible to pass a
  non-`nil' value (`t') instead of a list of properties.  This will
  retain the original aesthetic for that level.  For example:

  ┌────
  │ (setq standard-themes-headings
  │       '((1 . t)           ; keep the default style
  │ 	(2 . (semibold 1.2))
  │ 	(t . (rainbow)))) ; style for all other headings
  │ 
  │ (setq standard-themes-headings
  │       '((1 . (variable-pitch 1.5))
  │ 	(2 . (semibold))
  │ 	(t . t))) ; default style for all other levels
  └────

  Note that the text color of headings, of their background, and
  overline can all be set via the overrides.  It is possible to have any
  color combination for any heading level (something that could not be
  done in older versions of the themes).

  The foreground, background, and overline colors of headings can be
  modified by applying palette overrides ([Palette overrides]).


[Palette overrides] See section 5.10


5.10 Palette overrides
──────────────────────

  The Standard themes define their own color palette as well as semantic
  color mappings.  The former is the set of color values such as what
  shade of blue to use.  The latter refers to associations between a
  color value and a syntactic construct, such as a `variable' for
  variables in programming modes or `heading-1' for level 1 headings in
  Org and others.

  The definition is stored in the variable `NAME-palette', where `NAME'
  is the symbol of the theme, such as `standard-light'.  Overrides for
  those associations are specified in the variable
  `NAME-palette-overrides'.

  The variable `standard-themes-common-palette-overrides' is available
  for shared values.  It is advised to only use this for mappings that
  do not specify a color value directly.  This way, the text remains
  legible by getting the theme-specific color value it needs.

  All associations take the form of `(KEY VALUE)' pairs.  For example,
  the `standard-light-palette' contains `(blue-warmer "#3a5fcd")'.
  Semantic color mappings are the same, though the `VALUE' is one of the
  named colors of the theme.  For instance, `standard-light-palette'
  maps the aforementioned like `(link blue-warmer)'.

  The easiest way to learn about a theme’s definition is to use the
  command `describe-variable' (bound to `C-h v' by default) and then
  search for the `NAME-palette'.  The resulting Help buffer will look
  like this:

  ┌────
  │ standard-light-palette is a variable defined in ‘standard-light-theme.el’.
  │ 
  │ Its value is shown below.
  │ 
  │ The ‘standard-light’ palette.
  │ 
  │   This variable may be risky if used as a file-local variable.
  │ 
  │ Value:
  │ ((bg-main "#ffffff")
  │  (fg-main "#000000")
  │  (bg-dim "#ededed")
  │ 
  │ [... Shortened for the purposes of this manual.]
  └────

  The user can study this information to identify the overrides they
  wish to make.  Then they can specify them and re-load the theme for
  changes to take effect.  Sample of how to override a color value and a
  semantic mapping:

  ┌────
  │ (setq standard-light-palette-overrides
  │       '((blue-warmer "#5230ff") ; original value is #3a5fcd
  │ 	(variable blue-warmer))) ; original value is yellow-cooler
  └────

  The overrides can contain as many associations as the user needs.

  Changes to color values are reflected in the preview of the theme’s
  palette ([Preview theme colors]).  They are shown at the top of the
  buffer.  In the above example, the first instance of `blue-warmer' is
  the override and the second is the original one.

  Contact me if you need further help with this.


[Preview theme colors] See section 7


6 Loading a theme
═════════════════

  Emacs can load and maintain enabled multiple themes at once.  This
  typically leads to awkward styling and weird combinations.  The theme
  looks broken and the designer’s intent is misunderstood.  Before
  loading either of the `standard-themes', the user is encouraged to
  disable all others ([Disable other themes]):

  ┌────
  │ (mapc #'disable-theme custom-enabled-themes)
  └────

  Then load the theme of choice.  For example:

  ┌────
  │ (load-theme 'standard-light :no-confirm)
  └────

  The `:no-confirm' is optional.  It simply skips the step where Emacs
  asks the user whether they are sure about loading the theme.

  Consider adding code like the above to the user configuration file,
  such as `init.el'.

  As the Standard themes are extensible, another way to load the theme
  of choice is to use either `standard-themes-load-dark' or
  `standard-themes-load-light'. These functions take care to (i) disable
  other themes, (ii) load the specified Standard theme, and (iii) run
  the `standard-themes-post-load-hook' which is useful for
  do-it-yourself customizations ([The general approach to DIY changes]).
  These two functions are also called by the command
  `standard-themes-toggle'.


[Disable other themes] See section 5.1

[The general approach to DIY changes] See section 9.2


7 Preview theme colors
══════════════════════

  The command `standard-themes-preview-colors' uses minibuffer
  completion to select an item from the Standard themes and then
  produces a buffer with previews of its color palette entries.  The
  buffer has a naming scheme which reflects the given choice, like
  `standard-light-preview-colors' for the `standard-light' theme.

  The command `standard-themes-preview-colors-current' skips the
  minibuffer selection process and just produces a preview for the
  current Standard theme.

  When called with a prefix argument (`C-u' with the default key
  bindings), these commands will show a preview of the palette’s
  semantic color mappings instead of the named colors.

  Aliases for those commands are `standard-themes-list-colors' and
  `standard-themes-list-colors-current'.

  Overrides to color values are reflected in the buffers produced by the
  aforementioned commands ([Palette overrides]).

  Each row shows a foreground and background coloration using the
  underlying value it references.  For example a line with `#b3303a' (a
  shade of red) will show red text followed by a stripe with that same
  color as a backdrop.

  The name of the buffer describes the given Standard theme and what the
  contents are, such as `*standard-light-list-colors*' for named colors
  and `=*standard-light-list-mappings*' for the semantic color mappings.


[Palette overrides] See section 5.10


8 Use colors from the active Standard theme
═══════════════════════════════════════════

  Advanced users may want to call color variables from the palette of
  the active Standard theme.  The macro `standard-themes-with-colors'
  supplies those to any form called inside of it.  For example:

  ┌────
  │ (standard-themes-with-colors
  │   (list bg-main fg-main bg-mode-line))
  │ ;; => ("#ffffff" "#000000" "#b3b3b3")
  └────

  The above return value is for `standard-light' when that is the active
  Standard theme.  Switching to `standard-dark' and evaluating this code
  anew will give us the relevant results for that theme:

  ┌────
  │ (standard-themes-with-colors
  │   (list bg-main fg-main bg-mode-line cursor))
  │ ;; => ("#000000" "#ffffff" "#505050")
  └────

  [Do-It-Yourself customizations].

  The palette of each Standard theme is considered stable.  No removals
  shall be made.  Though please note that some tweaks to individual hues
  or color mapping are still possible.  At any rate, we will not
  outright break any code that uses `standard-themes-with-colors'.


[Do-It-Yourself customizations] See section 9


9 Do-It-Yourself customizations
═══════════════════════════════

  This section shows how the user can tweak the Standard themes to their
  liking, often by employing the `standard-themes-with-colors' macro
  ([Use colors from the active Standard theme]).


[Use colors from the active Standard theme] See section 8

9.1 Get a single color from the palette
───────────────────────────────────────

  [The general approach to advanced DIY changes].

  The fuction `standard-themes-get-color-value' can be called from Lisp
  to return the value of a color from the active Standard theme palette.
  It takea a `COLOR' argument and an optional `OVERRIDES'.

  `COLOR' is a symbol that represents a named color entry in the
  palette.

  [Preview theme colors].

  If the value is the name of another color entry in the palette (so a
  mapping), this function recurs until it finds the underlying color
  value.

  With an optional `OVERRIDES' argument as a non-nil value, it accounts
  for palette overrides.  Else it reads only the default palette.

  [Palette overrides].

  With optional `THEME' as a symbol among `standard-themes-collection',
  use the palette of that item.  Else use the current Standard theme.

  If `COLOR' is not present in the palette, this function returns the
  `unspecified' symbol, which is safe when used as a face attribute’s
  value.

  An example with `standard-light' to show how this function behaves
  with/without overrides and when recursive mappings are introduced.

  ┌────
  │ ;; Here we show the recursion of palette mappings.  In general, it is
  │ ;; better for the user to specify named colors to avoid possible
  │ ;; confusion with their configuration, though those still work as
  │ ;; expected.
  │ (setq standard-themes-common-palette-overrides
  │       '((cursor red)
  │ 	(prompt cursor)
  │ 	(variable prompt)))
  │ 
  │ ;; Ignore the overrides and get the original value.
  │ (standard-themes-get-color-value 'variable)
  │ ;; => "#a0522d"
  │ 
  │ ;; Read from the overrides and deal with any recursion to find the
  │ ;; underlying value.
  │ (standard-themes-get-color-value 'variable :overrides)
  │ ;; => "#b3303a"
  └────


[The general approach to advanced DIY changes] See section 9.2

[Preview theme colors] See section 7

[Palette overrides] See section 5.10


9.2 The general approach to advanced DIY changes
────────────────────────────────────────────────

  When the user wants to customize Emacs faces there are two
  considerations they need to make if they care about robustness:

  1. Do not hardcode color values, but instead use the relevant
     variables from the Standard themes.
  2. Make the changes persist through theme changes between the Standard
     themes.

  For point 1 we provide the `standard-themes-with-colors' macro, while
  for point 2 we have the `standard-themes-post-load-hook'.  The hook
  runs at the end of the command `standard-themes-toggle'.

  [Use colors from the active Standard theme].

  [A theme-agnostic hook for theme loading].

  We need to wrap our code in the `standard-themes-with-colors' and
  declare it as a function which we then add to the hook.  Here we show
  the general approach of putting those pieces together.

  To customize faces in a way that mirrors the Standard themes’ source
  code, we use the built-in `custom-set-faces'.  The value it accepts
  has the same syntax as that found in `standard-themes.el',
  specifically the `standard-themes-faces' constant.  It thus is easy to
  copy lines from there and tweak them.  Let’s pick a couple of
  font-lock faces (used in all programming modes, among others):

  ┌────
  │ (defun my-standard-themes-custom-faces ()
  │   "My customizations on top of the Standard themes.
  │ This function is added to the `standard-themes-post-load-hook'."
  │   (standard-themes-with-colors
  │     (custom-set-faces
  │      ;; These are the default specifications
  │      `(font-lock-comment-face ((,c :inherit standard-themes-italic :foreground ,comment)))
  │      `(font-lock-variable-name-face ((,c :foreground ,variable))))))
  │ 
  │ ;; Using the hook lets our changes persist when we use the commands
  │ ;; `standard-themes-toggle', `standard-themes-load-dark',
  │ ;; `standard-themes-load-light'.
  │ (add-hook 'standard-themes-post-load-hook #'my-standard-themes-custom-faces)
  └────

  Each of the Standard themes has its own color palette and
  corresponding mapping of values to constructs.  So the color of the
  `comment' variable will differ between the themes.  For the purpose of
  our demonstration, we make variables look like comments and comments
  like variables:

  ┌────
  │ (defun my-standard-themes-custom-faces ()
  │   "My customizations on top of the Standard themes.
  │ This function is added to the `standard-themes-post-load-hook'."
  │   (standard-themes-with-colors
  │     (custom-set-faces
  │      `(font-lock-comment-face ((,c :foreground ,variable)))
  │      `(font-lock-variable-name-face ((,c :inherit standard-themes-italic :foreground ,comment))))))
  │ 
  │ ;; Using the hook lets our changes persist when we use the commands
  │ ;; `standard-themes-toggle', `standard-themes-load-dark',
  │ ;; `standard-themes-load-light'.
  │ (add-hook 'standard-themes-post-load-hook #'my-standard-themes-custom-faces)
  └────

  All changes take effect when a theme is loaded again.  As such, it is
  better to use either `standard-themes-load-dark' or
  `standard-themes-load-light' at startup so that the function added to
  the hook gets applied properly upon first load.  Like this:

  ┌────
  │ (defun my-standard-themes-custom-faces ()
  │   "My customizations on top of the Standard themes.
  │ This function is added to the `standard-themes-post-load-hook'."
  │   (standard-themes-with-colors
  │     (custom-set-faces
  │      `(font-lock-comment-face ((,c :foreground ,variable)))
  │      `(font-lock-variable-name-face ((,c :inherit standard-themes-italic :foreground ,comment))))))
  │ 
  │ ;; Using the hook lets our changes persist when we use the commands
  │ ;; `standard-themes-toggle', `standard-themes-load-dark',
  │ ;; `standard-themes-load-light'.
  │ (add-hook 'standard-themes-post-load-hook #'my-standard-themes-custom-faces)
  │ 
  │ ;; Load the theme and run `standard-themes-post-load-hook'
  │ (standard-themes-load-light) ; OR (standard-themes-load-dark)
  └────

  Please contact us if you have specific questions about this mechanism.
  We are willing to help and shall provide comprehensive documentation
  where necessary.


[Use colors from the active Standard theme] See section 8

[A theme-agnostic hook for theme loading] See section 9.3


9.3 A theme-agnostic hook for theme loading
───────────────────────────────────────────

  The themes are designed with the intent to be useful to Emacs users of
  varying skill levels, from beginners to experts.  This means that we
  try to make things easier by not expecting anyone reading this
  document to be proficient in Emacs Lisp or programming in general.

  Such a case is with the use of the `standard-themes-post-load-hook',
  which is called after the evaluation of any of the commands we provide
  for loading a theme ([Loading a theme]).  We recommend using that hook
  for advanced customizations, because (1) we know for sure that it is
  available once the themes are loaded, and (2) anyone consulting this
  manual, especially the sections on enabling and loading the themes,
  will be in a good position to benefit from that hook.

  Advanced users who have a need to switch between the Standard themes
  and other items (e.g. the `modus-themes' and `ef-themes') will find
  that such a hook does not meet their requirements: it only works with
  the Standard themes and only with the functions they provide.

  A theme-agnostic setup can be configured thus:

  ┌────
  │ (defvar after-enable-theme-hook nil
  │    "Normal hook run after enabling a theme.")
  │ 
  │ (defun run-after-enable-theme-hook (&rest _args)
  │    "Run `after-enable-theme-hook'."
  │    (run-hooks 'after-enable-theme-hook))
  │ 
  │ (advice-add 'enable-theme :after #'run-after-enable-theme-hook)
  └────

  This creates the `after-enable-theme-hook' and makes it run after each
  call to `enable-theme', which means that it will work for all themes
  and also has the benefit that it does not depend on functions such as
  `standard-themes-select' and the others mentioned in this manual.  The
  function `enable-theme' is called internally by `load-theme', so the
  hook works everywhere.

  The downside of the theme-agnostic hook is that any functions added to
  it will likely not be able to benefit from macro calls that read the
  active theme, such as `standard-themes-with-colors' (the Modus and Ef
  themes have an equivalent macro).  Not all Emacs themes have the same
  capabilities.

  In this document, we always mention `standard-themes-post-load-hook'
  though the user can replace it with `after-enable-theme-hook' should
  they need to (provided they understand the implications).


[Loading a theme] See section 6


9.4 Add support for hl-todo
───────────────────────────

  The `hl-todo' package provides the user option
  `hl-todo-keyword-faces': it specifies an association list of `(KEYWORD
  . COLOR-VALUE)' pairs.  There are no faces, which the theme could
  style seamlessly.  As such, it rests on the user to specify
  appropriate color values.  This can be done either by hardcoding
  colors, which is inefficient, or by using the macro
  `standard-themes-with-colors' ([The general approach to DIY changes]).
  Here we show the latter method.

  ┌────
  │ (defun my-standard-themes-hl-todo-faces ()
  │   "Configure `hl-todo-keyword-faces' with Standard themes colors.
  │ The exact color values are taken from the active Standard theme."
  │   (standard-themes-with-colors
  │     (setq hl-todo-keyword-faces
  │ 	  `(("HOLD" . ,yellow)
  │ 	    ("TODO" . ,red)
  │ 	    ("NEXT" . ,blue)
  │ 	    ("THEM" . ,magenta)
  │ 	    ("PROG" . ,cyan-warmer)
  │ 	    ("OKAY" . ,green-warmer)
  │ 	    ("DONT" . ,yellow-warmer)
  │ 	    ("FAIL" . ,red-warmer)
  │ 	    ("BUG" . ,red-warmer)
  │ 	    ("DONE" . ,green)
  │ 	    ("NOTE" . ,blue-warmer)
  │ 	    ("KLUDGE" . ,cyan)
  │ 	    ("HACK" . ,cyan)
  │ 	    ("TEMP" . ,red)
  │ 	    ("FIXME" . ,red-warmer)
  │ 	    ("XXX+" . ,red-warmer)
  │ 	    ("REVIEW" . ,red)
  │ 	    ("DEPRECATED" . ,yellow)))))
  │ 
  │ (add-hook 'standard-themes-post-load-hook #'my-standard-themes-hl-todo-faces)
  └────

  To find the names of the color variables, the user can rely on the
  commands for previewing the palette ([Preview theme colors]).


[The general approach to DIY changes] See section 9.2

[Preview theme colors] See section 7


9.5 Configure bold and italic faces
───────────────────────────────────

  The Standard themes do not hardcode a `:weight' or `:slant' attribute
  in the faces they cover.  Instead, they configure the generic faces
  called `bold' and `italic' to use the appropriate styles and then
  instruct all relevant faces that require emphasis to inherit from
  them.

  This practically means that users can change the particularities of
  what it means for a construct to be bold/italic, by tweaking the
  `bold' and `italic' faces.  Cases where that can be useful include:

  ⁃ The default typeface does not have a variant with slanted glyphs
    (e.g. Fira Mono/Code as of this writing on 2022-11-30), so the user
    wants to add another family for the italics, such as Hack.

  ⁃ The typeface of choice provides a multitude of weights and the user
    prefers the light one by default.  To prevent the bold weight from
    being too heavy compared to the light one, they opt to make `bold'
    use a semibold weight.

  ⁃ The typeface distinguishes between oblique and italic forms by
    providing different font variants (the former are just slanted
    versions of the upright forms, while the latter have distinguishing
    features as well).  In this case, the user wants to specify the font
    that applies to the `italic' face.

  To achieve those effects, one must first be sure that the fonts they
  use have support for those features.

  In this example, we set the default font family to Fira Code, while we
  choose to render italics in the Hack typeface (obviously one needs to
  pick fonts that work in tandem):

  ┌────
  │ (set-face-attribute 'default nil :family "Fira Code" :height 110)
  │ (set-face-attribute 'italic nil :family "Hack")
  └────

  And here we play with different weights, using Source Code Pro:

  ┌────
  │ (set-face-attribute 'default nil :family "Source Code Pro" :height 110 :weight 'light)
  │ (set-face-attribute 'bold nil :weight 'semibold)
  └────

  To reset the font family, one can use this:

  ┌────
  │ (set-face-attribute 'italic nil :family 'unspecified)
  └────

  Consider the `fontaine' package on GNU ELPA (by Protesilaos) which
  provides the means to configure font families via faces.


9.6 Tweak `org-modern' timestamps
─────────────────────────────────

  The `org-modern' package uses faces and text properties to make Org
  buffers more aesthetically pleasing.  It affects tables, timestamps,
  lists, headings, and more.

  In previous versions of the Standard themes, we mistakenly affected
  one of its faces: the `org-modern-label'.  It changed the intended
  looks and prevented the user option `org-modern-label-border' from
  having its desired effect.  As such, we no longer override that face.

  Users who were used to the previous design and who generally do not
  configure the user options of `org-modern' may thus notice a change in
  how clocktables (or generally tables with timestamps) are aligned.
  The simplest solution is to instruct the mode to not prettify
  timestamps, by setting the user option `org-modern-timestamp' to
  `nil'.  For example, by adding this to the init file:

  ┌────
  │ (setq org-modern-timestamp nil)
  └────

  Alignment in tables will also depend on the use of proportionately
  spaced fonts.  Enable the relevant option to work with those without
  any further trouble ([Enable mixed fonts]).

  For any further issues, you are welcome to ask for help.


[Enable mixed fonts] See section 5.4


9.7 Tweak goto-address-mode faces
─────────────────────────────────

  The built-in `goto-address-mode' uses heuristics to identify URLs and
  email addresses in the current buffer.  It then applies a face to them
  to change their style.  Some packages, such as `notmuch', use this
  minor-mode automatically.

  The faces are not declared with `defface', meaning that it is better
  that the theme does not modify them.  The user is thus encouraged to
  consider including this in their setup:

  ┌────
  │ (setq goto-address-url-face 'link
  │       goto-address-url-mouse-face 'highlight
  │       goto-address-mail-face 'link
  │       goto-address-mail-mouse-face 'highlight)
  └────

  My personal preference is to set `goto-address-mail-face' to `nil',
  because it otherwise adds too much visual noise to the buffer (email
  addresses stand out more, due to the use of the uncommon `@'
  caharacter but also because they are often enclosed in angled
  brackets).


10 Faces defined by the Standard themes
═══════════════════════════════════════

  The themes define some faces to make it possible to achieve
  consistency between various groups of faces.  For example, all “marks
  for selection” use the `standard-themes-mark-select' face.  If, say,
  the user wants to edit this face to include an underline, the change
  will apply to lots of packages, like Dired, Trashed, Ibuffer.

  [Do-It-Yourself customizations].

  All the faces defined by the themes:

  • `standard-themes-bold'
  • `standard-themes-fixed-pitch'
  • `standard-themes-fringe-error'
  • `standard-themes-fringe-info'
  • `standard-themes-fringe-warning'
  • `standard-themes-heading-0'
  • `standard-themes-heading-1'
  • `standard-themes-heading-2'
  • `standard-themes-heading-3'
  • `standard-themes-heading-4'
  • `standard-themes-heading-5'
  • `standard-themes-heading-6'
  • `standard-themes-heading-7'
  • `standard-themes-heading-8'
  • `standard-themes-intense-blue'
  • `standard-themes-intense-cyan'
  • `standard-themes-intense-green'
  • `standard-themes-intense-magenta'
  • `standard-themes-intense-red'
  • `standard-themes-intense-yellow'
  • `standard-themes-italic'
  • `standard-themes-key-binding'
  • `standard-themes-mark-delete'
  • `standard-themes-mark-other'
  • `standard-themes-mark-select'
  • `standard-themes-nuanced-blue'
  • `standard-themes-nuanced-cyan'
  • `standard-themes-nuanced-green'
  • `standard-themes-nuanced-magenta'
  • `standard-themes-nuanced-red'
  • `standard-themes-nuanced-yellow'
  • `standard-themes-prompt'
  • `standard-themes-subtle-blue'
  • `standard-themes-subtle-cyan'
  • `standard-themes-subtle-green'
  • `standard-themes-subtle-magenta'
  • `standard-themes-subtle-red'
  • `standard-themes-subtle-yellow'
  • `standard-themes-ui-variable-pitch'
  • `standard-themes-underline-error'
  • `standard-themes-underline-info'
  • `standard-themes-underline-warning'


[Do-It-Yourself customizations] See section 9


11 Supported packages or face groups
════════════════════════════════════

  The `standard-themes' will only ever support a curated list of
  packages based on my judgement ([Packages that are hard to support]).
  Nevertheless, the list of explicitly or implicitly supported packages
  already covers everything most users need.


[Packages that are hard to support] See section 11.3

11.1 Explicitly supported packages or face groups
─────────────────────────────────────────────────

  • all basic faces
  • all-the-icons
  • all-the-icons-dired
  • all-the-icons-ibuffer
  • ansi-color
  • auctex
  • auto-dim-other-buffers
  • breadcrumb
  • bongo
  • bookmark
  • calendar and diary
  • cider
  • centaur-tabs
  • change-log and log-view (part of VC)
  • chart
  • clojure-mode
  • company
  • compilation
  • completions
  • consult
  • corfu
  • corfu-candidate-overlay
  • custom (`M-x customize')
  • denote
  • dictionary
  • diff-hl
  • diff-mode
  • dired
  • dired-subtree
  • diredfl
  • dirvish
  • display-fill-column-indicator-mode
  • doom-modeline
  • ediff
  • eglot
  • eldoc
  • elfeed
  • embark
  • epa
  • erc
  • ert
  • eshell
  • eww
  • flycheck
  • flymake
  • flyspell
  • font-lock
  • git-commit
  • git-rebase
  • gnus
  • hi-lock (`M-x highlight-regexp')
  • ibuffer
  • image-dired
  • info
  • isearch, occur, query-replace
  • jit-spell
  • keycast
  • lin
  • line numbers (`display-line-numbers-mode' and global variant)
  • magit
  • man
  • marginalia
  • markdown-mode
  • messages
  • mode-line
  • mu4e
  • nerd-icons
  • nerd-icons-completion
  • nerd-icons-dired
  • nerd-icons-ibuffer
  • neotree
  • notmuch
  • olivetti
  • orderless
  • org
  • org-habit
  • org-modern
  • outline-mode
  • outline-minor-faces
  • package (`M-x list-packages')
  • perspective
  • powerline
  • pulsar
  • pulse
  • rainbow-delimiters
  • rcirc
  • recursion-indicator
  • regexp-builder (re-builder)
  • ruler-mode
  • shell-script-mode (sh-mode)
  • show-paren-mode
  • shr
  • smerge
  • tab-bar-mode
  • tab-line-mode
  • tempel
  • term
  • textsec
  • transient
  • trashed
  • tree-sitter
  • tty-menu
  • vc (`vc-dir.el', `vc-hooks.el')
  • vertico
  • vundo
  • wgrep
  • which-function-mode
  • which-key
  • whitespace-mode
  • widget
  • writegood-mode
  • woman
  • ztree


11.2 Implicitly supported packages or face groups
─────────────────────────────────────────────────

  Those are known to work with the Standard themes either because their
  colors are appropriate or because they inherit from basic faces which
  the themes already cover:

  • apropos
  • dim-autoload
  • hl-todo
  • icomplete
  • ido
  • multiple-cursors
  • paren-face
  • which-key
  • xref

  Note that “implicitly supported” does not mean that they always fit in
  perfectly.  If there are refinements we need to made, then we need to
  intervene ([Explicitly supported packages or face groups]).


[Explicitly supported packages or face groups] See section 11.1


11.3 Packages that are hard to support
──────────────────────────────────────

  These are difficult to support due to their (i) incompatibility with
  the design of the `standard-themes', (ii) complexity or multiple
  points of entry, (iii) external dependencies, (iv) existence of better
  alternatives in my opinion, or (v) inconsiderate use of color
  out-of-the-box and implicit unwillingness to be good Emacs citizens:

  avy
        its UI is prone to visual breakage and is hard to style
        correctly.

  calibredb
        has an external dependency that I don’t use.

  ctrlf
        use the built-in isearch or the `consult-line' command of
        `consult'.

  dired+
        it is complex and makes inconsiderate use of color.

  ein (Emacs IPython Notebook)
        external dependency that I don’t use.

  ement.el
        has an external dependency that I don’t use.

  helm
        it is complex and makes inconsiderate use of color.  Prefer the
        `vertico', `consult', and `embark' packages.

  info+
        it is complex and makes inconsiderate use of color.

  ivy/counsel/swiper
        use the `vertico', `consult', and `embark' packages which are
        designed to be compatible with standard Emacs mechanisms and are
        modular.

  lsp-mode
        has external dependencies that I don’t use.

  solaire
        in principle, it is incompatible with practically every theme
        that is not designed around it.  Emacs does not distinguish
        between “UI” and “syntax” buffers.

  sx
        has an external dependency that I don’t use.

  telega
        has an external dependency that I don’t use (I don’t even have a
        smartphone).

  treemacs
        it has too many dependencies and does too many things.

  web-mode
        I don’t use all those Web technologies and cannot test this
        properly without support from an expert.  It also defines lots
        of faces that hardcode color values for no good reason.

  The above list is non-exhaustive though you get the idea.


12 Acknowledgements
═══════════════════

  This project is meant to be a collective effort.  Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to code
        Clemens Radermacher.

  Ideas and/or user feedback
        Filippo Argiolas, Fritz Grabo, Manuel Uberti, Tassilo Horn, Zack
        Weinberg.


13 GNU Free Documentation License
═════════════════════════════════


14 Indices
══════════

14.1 Function index
───────────────────


14.2 Variable index
───────────────────


14.3 Concept index
──────────────────
