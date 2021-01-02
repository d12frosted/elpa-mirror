This package is obsolete.

Since version 22.1 Emacs has built-in support for themes.  That
implementation does not derive from the implementation provided
by this package.  Back when this was new we referred to the new
implementation as `deftheme' themes, as opposed to `color-theme'
themes.

This package comes with a large collection of themes.  If you
still use it because you want to use one of those, then you can
never-the-less migrate to the "new" theme implementation.  The
`color-theme-modern' package ports all themes that are bundles
with `color-theme' to the `deftheme' format.  It also ports a
few third-party themes.  Its documentation contains setup
instructions.  Don't forget to uninstall `color-theme'.

; Thanks

Deepak Goel  <deego@glue.umd.edu>
S. Pokrovsky <pok@nbsp.nsk.su> for ideas and discussion.
Gordon Messmer <gordon@dragonsdawn.net> for ideas and discussion.
Sriram Karra <karra@cs.utah.edu> for the color-theme-submit stuff.
Olgierd `Kingsajz' Ziolko <kingsajz@rpg.pl> for the spec-filter idea.
Brian Palmer for color-theme-library ideas and code
All the users that contributed their color themes.


