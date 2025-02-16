            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                             COLORFUL-MODE
             Preview any color in your buffer in real time.
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


<https://raw.githubusercontent.com/DevelopmentCool2449/colorful-mode/main/assets/colorful-mode-logo.svg>

      Preview any color in your buffer in real time.

🎨 `colorful-mode' is a minor mode that allow you highlight/preview any
color format such as *color hex* and *color names*, in your current
buffer in real time and in a user friendly way based/inspired on
🌈[rainbow-mode.el].


[rainbow-mode.el] <https://elpa.gnu.org/packages/rainbow-mode.html>


1 Features ✨
═════════════

  • Real time color highlight.
  • Supports:
    • Hexadecimal (#RRGGBB, #RGB, #RRGGBBAA, #RGBA).
    • Color names (Emacs, HTML, CSS).
    • CSS rgb/rgba, hsl/hsla and user-defined colors variables:
      • @define_color
      • var()
    • LaTex colors (gray, rbg, RGB, HTML)
  • Convert current color at point or in region to other formats such as
    hexadecimal or color names *(only available for some colors)* with
    mouse click support.
  • Prefix/suffix string instead highlight /(Optional)/.
  • Highlight only in strings /(Optional)/.
  • Blacklist color keywords from being highlighted.


2 Screenshots and animated GIFs 📷
══════════════════════════════════

  <https://raw.githubusercontent.com/DevelopmentCool2449/colorful-mode/main/assets/screenshot1.png>
  Supports for both GUI/TUI.

  <https://raw.githubusercontent.com/DevelopmentCool2449/colorful-mode/main/assets/screenshot2.png>
  Support for custom color string indicator.

  <https://raw.githubusercontent.com/DevelopmentCool2449/colorful-mode/main/assets/gif1.gif>

  <https://raw.githubusercontent.com/DevelopmentCool2449/colorful-mode/main/assets/gif2.gif>
  Change color support in real time.

  <https://raw.githubusercontent.com/DevelopmentCool2449/colorful-mode/main/assets/gif3.gif>
  Support for color changing at region.


3 User Options 🔧
═════════════════

3.1 Customizable User options
─────────────────────────────

  • `colorful-allow-mouse-clicks (default: t)' If non-nil, allow using
    mouse buttons for change color.
  • `colorful-use-prefix (default: nil)' If non-nil, use prefix for
    preview color instead highlight them.
  ┌────
  │ ⛔ WARNING: CSS-DERIVED MODES COLORIZE RGB AND HEX COLORS OUT THE BOX,
  │ THIS MAY INTERFERE WITH COLORFUL PREFIX, YOU CAN DISABLE THIS SETTING
  │ `css-fontify-colors' TO nil
  └────
  • `colorful-prefix-string (default: "●")' String to be used in
    highlights.  Only relevant if `colorful-use-prefix' is non-nil.
  • `colorful-prefix-alignment (default: 'left)' The position to put
    prefix string.  The value can be left or right.  Only relevant if
    `colorful-use-prefix' is non-nil.
  • `colorful-extra-color-keyword-functions' default:
    '(colorful-add-hex-colors (emacs-lisp-mode
    . colorful-add-color-names) ((html-mode css-mode) .
    (colorful-add-css-variables-colors colorful-add-rgb-colors
    colorful-add-hsl-colors colorful-add-color-names)) (latex-mode
    . colorful-add-latex-colors)) List of functions to add extra color
    keywords to colorful-color-keywords.

    It can be a cons cell specifying the mode (or a list of modes) e.g:

    (((css-mode css-ts-mode) . colorful-add-rgb-colors) (emacs-lisp-mode
      . (colorful-add-color-names colorful-add-rgb-colors)) ((text-mode
      html-mode) . (colorful-add-color-names colorful-add-rgb-colors))
      …)

    Or a simple list of functions for executing wherever colorful is
    active: (colorful-add-color-names colorful-add-rgb-colors)

    Available functions are:
    ⁃ colorful-add-hex-colors.
    ⁃ colorful-add-color-names.
    ⁃ colorful-add-css-variables-colors.
    ⁃ colorful-add-rgb-colors.
    ⁃ colorful-add-hsl-colors.
    ⁃ colorful-add-latex-colors

  • `colorful-exclude-colors (default: '("#define"))' List of keyword to
    don't highlight.
  • `colorful-short-hex-conversions (default: t)' If non-nil, hex values
    converted by colorful should be as short as possible.  Setting this
    to 2 will make hex values follow a 24-bit specification
    (#RRGGBB[AA]) and can make them inaccurate.
  • `colorful-only-strings (default: nil)' If non-nil colorful will only
    highlight colors inside strings.  If set to only-prog, only
    highlight colors in strings if current major mode is derived from
    prog-mode.
  • `global-colorful-modes (default: '(mhtml-mode html-ts-mode scss-mode
    css-mode css-ts-mode prog-mode))' Which major modes
    global-colorful-mode is switched on in (globally).


3.2 Faces
─────────

  • `colorful-base' Face used as base for highlight color names.
    Changing background or foreground color will have no effect.


3.3 Interactive User Functions.
───────────────────────────────

  • `colorful-change-or-copy-color' Change or copy color to a converted
    format at current cursor position.
  • `colorful-convert-and-change-color' Convert color to other format
    and replace color at point or active mark.  If mark is active,
    convert colors in mark.
  • `colorful-convert-and-copy-color' Convert color to an other and copy
    it at point.
  • `colorful-mode' Buffer-local minor mode.
  • `global-colorful-mode' Global minor mode.


3.4 Key bindings
────────────────

  These key bindings are defined by: `colorful-mode-map'
  • `C-x c x' → `colorful-change-or-copy-color'.
  • `C-x c c' → `colorful-convert-and-copy-color'.
  • `C-x c r' → `colorful-convert-and-change-color'.


4 Setups and Guides 📖
══════════════════════

4.1 Enabling colors to specifics major-modes
────────────────────────────────────────────

  If you want to use css rgb colors outside css-derived modes, you can
  add them to `colorful-extra-color-keyword-functions' in your config.

  ┌────
  │ (add-to-list 'colorful-extra-color-keyword-functions '(insert-your-major-mode . colorful-add-rgb-colors))
  └────

  If you want also use hsl and rgb together you can use this
  ┌────
  │ (add-to-list 'colorful-extra-color-keyword-functions '(insert-your-major-mode . (colorful-add-rgb-colors colorful-add-hsl-colors)))
  └────

  colorful provides extra functions out-the-box that enable additional
  highlighting:

  • `colorful-add-hex-colors': Add Hexadecimal Colors.
  • `colorful-add-color-names': Add color names.
  • `colorful-add-css-variables-colors': Add CSS user-defined color
    variables.
  • `colorful-add-rgb-colors': Add CSS RGB colors.
  • `colorful-add-hsl-colors': Add CSS HSL colors.
  • `colorful-add-latex-colors': Add LaTex rgb/RGB/HTML/Grey colors.

  See: `colorful-extra-color-keyword-functions' for more details.


5 Usage and Installation 📦
═══════════════════════════

  It's recommended that you must use emacs-28.x or higher.

  For install colorful run:
  • `M-x package-install colorful-mode'

  Once you have it installed you can activate colorful locally in your
  buffer with `M-x colorful-mode', if want enable it globally without
  using hooks then you can do `M-x global-colorful-mode'

  Or if you prefer using `use-package' macro:
  ┌────
  │ 
  │ (use-package colorful-mode
  │   :ensure t ; Optional
  │   :hook (prog-mode text-mode)
  │   ;; :config (global-colorful-mode) ; Enable it globally
  │   ...)
  │ 
  └────


6 How does it compare to `rainbow-mode' or built-in `css fontify colors'?
═════════════════════════════════════════════════════════════════════════

  `colorful-mode' improves `rainbow-mode' and `css-fontify-colors' in
  adding more features:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Comparation                                            colorful-mode.el  rainbow-mode.el  built-in css-fontify-colors 
  ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   Compatible with hl-line and other overlays?            ✓                 ❌               ❌                          
   Convert color to other formats?                        ✓                 ❌               ❌                          
   Optionally use string prefix/suffix instead highlight  ✓                 ❌               ❌                          
   Blacklist colors?                                      ✓                 ❌^{1}           ❌                          
   Allow highlight specifics colors in specific modes     ✓                 ✓^{2}            ❌                          
   Optionally highlight only in strings                   ✓                 ❌               ❌                          
   No performance issues?^{3}                             ❌                ✓                ✓                           
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ┌────
  │ [1] rainbow-mode (like colorful) uses regex for highlight some
  │     keywords, however it cannot exclude specifics colors keywords
  │     (such as "#def" that overrides C "#define" keyword).
  │ [2] Only for some colors.
  │ [3] I didn't a benchmark however due colorful-mode uses overlays
  │     instead text properties it can be a bit slow.
  └────

  The intention is to provide a featured alternative to
  `rainbow-mode.el' and `css-fontify-colors' with a user-friendly
  approach.

  If you prefer only highlights without color conversion, prefix/suffix
  string indicator and/or anything else you can use `rainbow-mode.el'.

  or something built-in and just for css then use built-in
  css-fontify-colors which is activated by default

  On the other hand, if you want convert colors, overlays, optional
  prefix strings and more features you can use `colorful-mode.el'.


7 [How to Contribute]
═════════════════════

  colorful-mode is part of GNU ELPA, if you want send patches you will
  need assign copyright to the Free Software Foundation.  Please see the
  [CONTRIBUTING.org] file for getting more information.


[How to Contribute]
<https://raw.githubusercontent.com/DevelopmentCool2449/colorful-mode/main/CONTRIBUITING.org>

[CONTRIBUTING.org]
<https://raw.githubusercontent.com/DevelopmentCool2449/colorful-mode/main/CONTRIBUITING.org>
