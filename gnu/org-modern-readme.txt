                           ━━━━━━━━━━━━━━━━━━
                            MODERN ORG STYLE
                           ━━━━━━━━━━━━━━━━━━





1 Introduction
══════════════

  This package implements a modern style for your Org buffers using font
  locking and text properties. The package styles headlines, keywords,
  tables and source blocks. The styling is configurable, you can disable
  or modify the style of each syntax element individually via the
  `org-modern' customization group.

  <https://github.com/minad/org-modern/blob/screenshots/example.gif?raw=true>

  The screenshots shows [example.org] with `org-modern-mode' turned on
  and off. The elegant theme featured in the screenshot is
  [modus-operandi].

  Since this package adjusts text styling, it depends on your font
  settings. You should ensure that your `variable-pitch' and
  `fixed-pitch' fonts combine harmonically and have approximately the
  same height. As default font, I recommend variants of the [Iosevka]
  font, e.g., Iosevka Term Curly.  `org-modern-mode' tries to adjust the
  tag label display based on the value of `line-spacing'. This looks
  best if `line-spacing' has a value between 0.1 and 0.4 in the Org
  buffer. Larger values of `line-spacing' are not recommended, since
  Emacs does not center the text vertically (see Emacs [bug#76390]).


[example.org] <file:example.org>

[modus-operandi] <https://protesilaos.com/emacs/modus-themes>

[Iosevka] <https://github.com/be5invis/Iosevka>

[bug#76390] <https://debbugs.gnu.org/cgi/bugreport.cgi?bug=76390>


2 Configuration
═══════════════

  The package is available on GNU ELPA and MELPA. You can install the
  package with `package-install'. Then `org-modern' can be enabled
  manually in an Org buffer by invoking `M-x org-modern-mode'. In order
  to enable `org-modern' for all your Org buffers, add `org-modern-mode'
  to the Org mode hooks.

  ┌────
  │ ;; Option 1: Per buffer
  │ (add-hook 'org-mode-hook #'org-modern-mode)
  │ (add-hook 'org-agenda-finalize-hook #'org-modern-agenda)
  │ 
  │ ;; Option 2: Globally
  │ (with-eval-after-load 'org (global-org-modern-mode))
  └────

  Try the following more extensive setup in `emacs -Q' to reproduce the
  looks of the screenshot above after the installation of `org-modern'.

  ┌────
  │ ;; Minimal UI
  │ (package-initialize)
  │ (menu-bar-mode -1)
  │ (tool-bar-mode -1)
  │ (scroll-bar-mode -1)
  │ (modus-themes-load-operandi)
  │ 
  │ ;; Choose some fonts
  │ ;; (set-face-attribute 'default nil :family "Iosevka")
  │ ;; (set-face-attribute 'variable-pitch nil :family "Iosevka Aile")
  │ ;; (set-face-attribute 'org-modern-symbol nil :family "Iosevka")
  │ 
  │ ;; Add frame borders and window dividers
  │ (modify-all-frames-parameters
  │  '((right-divider-width . 40)
  │    (internal-border-width . 40)))
  │ (dolist (face '(window-divider
  │ 		window-divider-first-pixel
  │ 		window-divider-last-pixel))
  │   (face-spec-reset-face face)
  │   (set-face-foreground face (face-attribute 'default :background)))
  │ (set-face-background 'fringe (face-attribute 'default :background))
  │ 
  │ (setq
  │  ;; Edit settings
  │  org-auto-align-tags nil
  │  org-tags-column 0
  │  org-catch-invisible-edits 'show-and-error
  │  org-special-ctrl-a/e t
  │  org-insert-heading-respect-content t
  │ 
  │  ;; Org styling, hide markup etc.
  │  org-hide-emphasis-markers t
  │  org-pretty-entities t
  │  org-agenda-tags-column 0
  │  org-ellipsis "…")
  │ 
  │ (global-org-modern-mode)
  └────


3 Incompatibilities
═══════════════════

  • If `org-indent-mode' is enabled, `org-modern' will disable the block
    prettification in the fringe. See the package [org-modern-indent]
    which provides a different mechanism for block styling, than using
    the fringe.
  • `org-num-mode' interferes with the `org-modern' prettification of
    TODO keywords.
  • `visual-wrap-prefix-mode' relies on the `wrap-prefix' text property
    which is also used by `org-modern'.


[org-modern-indent] <https://github.com/jdtsmith/org-modern-indent>


4 Alternatives
══════════════

  The tag style of `org-modern' is inspired by Nicholas Rougier's
  [svg-tag-mode]. In contrast to `svg-tag-mode', the package
  `org-modern' avoids images and uses more efficient Emacs box text
  properties. By only styling the text via text properties, the styled
  text, e.g., dates or tags stay editable and are easy to interact with.

  The approach used here restricts the flexibility (e.g., no rounded
  corners) and creates dependence on the size and alignment of the
  font. Combining `org-modern-mode' with `svg-tag-mode' is possible. You
  can use SVG tags and use the table and block styling from
  `org-modern'. If you are interested in further tweaks, Emacs comes
  with the builtin `prettify-symbols-mode' which can be used for
  individual styling of custom keywords.

  Alternatives are the older [org-superstar] and [org-bullets] packages,
  which are more limited and mainly adjust headlines and
  lists. `org-superstar' relies on character composition, while
  `org-modern' uses text properties, which are considered more
  future-proof. Note that `org-modern' is a full replacement for both
  `org-superstar' and `org-bullets'. You can disable styling of certain
  elements, e.g., `org-modern-timestamp', if you only want to use the
  subset of `org-modern' equivalent to `org-superstar'.

  For an alternative source block styling technique, please take a look
  at the [org-modern-indent] package. Org-modern-indent can even style
  source blocks when `org-indent-mode' is enabled.


[svg-tag-mode] <https://github.com/rougier/svg-tag-mode>

[org-superstar] <https://github.com/integral-dw/org-superstar-mode>

[org-bullets] <https://github.com/sabof/org-bullets>

[org-modern-indent] <https://github.com/jdtsmith/org-modern-indent>


5 Contributions
═══════════════

  Since this package is part of [GNU ELPA] contributions require a
  copyright assignment to the FSF.


[GNU ELPA] <https://elpa.gnu.org/packages/org-modern.html>
