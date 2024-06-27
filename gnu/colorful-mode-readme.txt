            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                             COLORFUL-MODE
             Preview any color in your buffer in real time.
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


<./assets/colorful-mode-logo.svg>

      Preview any color in your buffer in real time.

🟢colorful-mode is a minor mode that allow you preview any color format
such as *color hex* and *color names*, in your current buffer in real
time and in a user friendly way based on 🌈[rainbow-mode.el].


[rainbow-mode.el] <https://elpa.gnu.org/packages/rainbow-mode.html>


1 Features ✨
═════════════

  • Preview colors such as colors names, hexadecimal colors and more in
    your current buffer in real time.
  • Replace or copy to other color formats such as hexadecimal or color
    names (only for some colors).
  • Preview using highlight or a prefix/suffix string.
  • Allow preview colors only in strings.
  • Exclude colors from being highlighted such as hex values and color
    names.


2 Screenshots and animated GIFs 📷
══════════════════════════════════

  <./assets/gif1.gif> /With prefix instead highliht/.

  <./assets/gif2.gif> <./assets/gif3.gif> <./assets/screenshot1.png>
  <./assets/screenshot2.png>

  <./assets/screenshot3.png> /With a custom prefix (in this example a
  non-ASCII/non-Unicode character)/.


3 User Options, Setups and Guides 📖
════════════════════════════════════

3.1 Customizable User options
─────────────────────────────

  • `colorful-allow-mouse-clicks (default: t)' If non-nil, allow using
    mouse buttons for change color.
  • `colorful-use-prefix (default: nil)' If non-nil, use prefix for
    preview color instead highlight them.  *NOTE: css derived modes by
    default colorize rgb and hex colors, this may interfere with
    colorful prefix, you can disable this setting css-fontify-colors to
    nil*
  • `colorful-prefix-string (default: "●")' String to be used in
    highlights.  Only relevant if `colorful-use-prefix' is non-nil.
    `colorful-use-prefix'.
  • `colorful-prefix-alignment (default: 'left)' The position to put
    prefix string.  The value can be left or right.  Only relevant if
    `colorful-use-prefix' is non-nil.
  • `colorful-extra-color-keyword-functions' default: '((emacs-lisp-mode
    . colorful-add-color-names) ((mhtml-mode html-ts-mode css-mode
    css-ts-mode) . (colorful-add-rgb-colors colorful-add-hsl-colors
    colorful-add-color-names)) (latex-mode . colorful-add-latex-colors)
    colorful-add-hex-colors) List of functions to add extra color
    keywords to colorful-color-keywords.

    It can be a cons cell specifing the mode (or a list of modes) e.g:

    (((css-mode css-ts-mode) . colorful-add-rgb-colors) (emacs-lisp-mode
      . (colorful-add-color-names colorful-add-rgb-colors)) ((text-mode
      html-mode) . (colorful-add-color-names colorful-add-rgb-colors))
      …)

    Or a simple list of functions for executing wherever colorful is
    active: (colorful-add-color-names colorful-add-rgb-colors)

    Available functions are:
    ⁃ colorful-add-hex-colors.
    ⁃ colorful-add-color-names.
    ⁃ colorful-add-rgb-colors.
    ⁃ colorful-add-hsl-colors.
    ⁃ colorful-add-latex-colors

  • `colorful-exclude-colors (default: '("#def"))' List of keyword to
    don't highlight.
  • `colorful-short-hex-convertions (default: 2)' If set to 2, hex
    values converted by colorful should be as short as possible.
    Setting this to 2 will make hex values follow a 24-bit specification
    and can make them inaccurate.
  • `colorful-only-strings (default: nil)' If non-nil colorful will only
    highlight colors inside strings.  If set to only-prog, only
    highlight colors in strings if current major mode is derived from
    prog-mode.
  • `global-colorful-modes (default: '(mhtml-mode html-ts-mode scss-mode
    css-mode css-ts-mode prog-mode))' Which major modes
    global-colorful-mode is switched on in (globally).


3.2 Faces
─────────

  • `colorful-base' Face used as base for highlight color names.  Only
    used for draw box and change font &c., changing box color and/or
    background/foreground color face won't be applied.


3.3 Interactive User Functions.
───────────────────────────────

  • `colorful-change-or-copy-color' Change or copy color to a converted
    format at current cursor position.
  • `colorful-convert-and-change-color' Convert color to a valid format
    and replace color at current cursor position.
  • `colorful-convert-and-copy-color' Convert color to a valid format
    and copy it at current cursor position.
  • `colorful-mode' Buffer-local minor mode.
  • `global-colorful-mode' Global minor mode.


3.4 Key bindings
────────────────

  These key bindings are defined by: `colorful-mode-map'
  • `C-x c x' → `colorful-change-or-copy-color'.
  • `C-x c c' → `colorful-convert-and-copy-color'.
  • `C-x c r' → `colorful-convert-and-change-color'.


3.5 Adding extra colors
───────────────────────

  Colorful by default provides extra functions that highlight additional
  colors:

  • `colorful-add-hex-colors' Add Hexadecimal Colors.
  • `colorful-add-color-names' Add color names.
  • `colorful-add-rgb-colors' Add CSS RGB colors.
  • `colorful-add-hsl-colors' Add CSS HSL colors.
  • `colorful-add-latex-colors' Add LaTex rgb/RGB/HTML/Grey colors.

  For use them add it to:
  ┌────
  │ ;; In this example add emacs color names only for yaml-mode and derived.
  │   (add-to-list 'colorful-extra-color-keyword-functions '(yaml-mode . colorful-add-color-names))
  └────

  See: `colorful-extra-color-keyword-functions' for more details.


4 Usage and Installation 📦
═══════════════════════════

  It's recommended that you must use emacs-28.x or higher.

  For install colorful run:
  • `M-x package-install colorful-mode'

  Once you have it installed you can run colorful locally in your buffer
  with `M-x colorful-mode', if want enable it globally without using
  hooks then you can do `M-x global-colorful-mode'

  Or if you prefer using `use-package' macro:
  ┌────
  │ (use-package colorful-mode
  │   :ensure t ; Optional
  │   :hook (prog-mode text-mode)
  │   ...)
  │ 
  └────


5 How does it compare to `rainbow-mode'?
════════════════════════════════════════

  `colorful-mode' improves `rainbow-mode' in adding more features and
  fixing some /(and old)/ bugs:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Comparation                                            colorful-mode.el  rainbow-mode.el 
  ──────────────────────────────────────────────────────────────────────────────────────────
   Compatible with hl-line and other overlays?            ✓                 ❌              
   Convert color to other formats?                        ✓                 ❌              
   Opcionally use string prefix/suffix instead highlight  ✓                 ❌              
   Exclude keywords/colors?                               ✓                 ❌^{1}          
   Allow highlight specifics colors in specific modes     ✓                 ✓^{2}           
   Opcionally highlight only in strings                   ✓                 ❌              
   No performance issues?^{3}                             ❌                ✓               
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1. rainbow-mode (like colorful) uses regex for highlight some
     keywords, however it cannot exclude specifics colors keywords (such
     as "#def" that overrides C "#define" keyword).
  2. Only for some colors.
  3. I didn't a benchmark however due colorful-mode uses overlays
     instead text properties it can be a slow.

  The intention is to provide a featured alternative to
  `rainbow-mode.el' with a user-friendly approach.

  If you prefer only highlights without color convertion, prefix/suffix
  string indicator and/or anything else you can use `rainbow-mode.el'.

  On the other hand, if you want convert colors, overlays, optional
  prefix strings and more features you can use `colorful-mode.el'.


6 [How to Contribute]
═════════════════════

  colorful-mode is part of GNU ELPA, if you want send patches you will
  need assign copyright to the Free Software Fundation.  Please see the
  [CONTRIBUITING.org] file for getting more information.


[How to Contribute] <./CONTRIBUITING.org>

[CONTRIBUITING.org] <./CONTRIBUITING.org>
