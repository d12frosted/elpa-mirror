                        ━━━━━━━━━━━━━━━━━━━━━━━
                         TAXY-MAGIT-SECTION.EL
                        ━━━━━━━━━━━━━━━━━━━━━━━


[https://elpa.gnu.org/packages/taxy-magit-section.svg]

This library renders [Taxy] structs with [magit-section].


[https://elpa.gnu.org/packages/taxy-magit-section.svg]
<https://elpa.gnu.org/packages/taxy-magit-section.html>

[Taxy] <https://github.com/alphapapa/taxy.el>

[magit-section] <https://melpa.org/#/magit-section>


1 Installation
══════════════

  `taxy-magit-section' is distributed in [GNU ELPA], which is available
  in Emacs by default.  Use `M-x package-install RET taxy-magit-section
  RET', then `(require 'taxy-magit-section)' in your Elisp project.


[GNU ELPA] <https://elpa.gnu.org/>


2 Changelog
═══════════

2.1 0.14.3
──────────

  *Fixes*
  ⁃ Only use visible frames when checking image sizes.  (See [Ement.el
    #298].)


[Ement.el #298]
<https://github.com/alphapapa/ement.el/issues/298#issuecomment-2369652629>


2.2 0.14.2
──────────

  *Changes*
  ⁃ Avoid redundant calculations of the width of strings containing
    images (a minor performance improvement).


2.3 0.14.1
──────────

  *Fixes*
  ⁃ Don't pass string as `ELLIPSIS' argument to
    `truncate-string-to-width'; pass t, which defaults to value of
    variable `truncate-string-ellipsis'.  (The width of the string
    passed before, the U+2026 HORIZONTAL ELLIPSIS character, varies by
    font, and fonts which display it with a width different than that of
    a single space cause misalignment of columns.  Now users may specify
    the ellipsis string according to their needs.)
  ⁃ Try to find a graphical frame when calculating image widths for
    column widths (or signal an error if none are available, rather than
    leaving `image-size' to signal an error).  (For example, if both
    graphical and text frames are available, and a column's values
    contain an image, and the buffer is being redisplayed on a text
    frame, try to use a graphical frame for calculating the image width,
    rather than just signaling an error.)


2.4 0.14
────────

  *Fixes*
  ⁃ Reduce the potential width of macro-expanded docstrings to prevent
    byte-compiler warnings.


2.5 0.13
────────

  *Additions*

  ⁃ Function `taxy-magit-section-insert' takes a `:section-class'
    argument, which is passed to `magit-insert-section' as its `class'
    argument.  This allows a custom subclass of `magit-section' to be
    passed, which, with a custom method on `magit-section-ident-value',
    allows section visibility to be cached concisely.


2.6 0.12.2
──────────

  *Fixes*
  ⁃ Header alignment.


2.7 0.12.1
──────────

  *Fixes*
  ⁃ Compilation error.


2.8 0.12
────────

  *Fixes*
  ⁃ Section visibility caching.


2.9 0.11
────────

  *Additions*
  ⁃ Truncated column values receive help-echo tooltips so the full
    value can be viewed.


2.10 0.10
─────────

  *Fixes*
  ⁃ Require package `taxy' in package headers.


2.11 0.9.1
──────────

  *Fixes*
  ⁃ `taxy-magit-section-insert' appends heading faces, so users can
    override (or merge with) the default.
  ⁃ `taxy-magit-section-format-items' uses columns' headers as their
    minimum width, which preserves each column's width regardless of
    items' values.


2.12 0.9
────────

  ⁃ `taxy-magit-section' moved to separate package.
  ⁃ Better align columns whose values are images.


3 Development
═════════════

  `taxy-magit-section' is developed in a branch of the [main Taxy repo].


[main Taxy repo] <https://github.com/alphapapa/taxy.el>


4 Credits
═════════

  ⁃ Thanks to Stefan Monnier for his feedback, and for maintaining GNU
    ELPA.


5 License
═════════

  GPLv3
