A light Emacs theme based on the color palette of the Metropolis
LaTeX Beamer theme (https://github.com/matze/mtheme).

Metropolis itself only defines four colors:  mDarkTeal, mDarkBrown,
mLightBrown and mLightGreen, and derives everything else (block
backgrounds, progress bars, footnotes, ...) from them with simple
percentage color blends.  This theme follows the same approach: the
four base colors below are blended using the same ratios Metropolis
uses in its `.dtx' source to produce the rest of the palette, so the
result stays visually consistent with the original Beamer theme
while covering the much larger set of faces Emacs needs.

A few extra hues (cyan, blue, red, yellow, magenta) are derived the
same way (by blending the base colors together) to cover roles
Metropolis has no opinion on, such as types, constants, errors and
terminal colors.
