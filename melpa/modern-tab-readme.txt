Two minor modes that give the two rows of tabs Emacs has the look of
the editors people come here from: a coloured bar beside the selected
tab, an icon on every tab, and — on the tab line — a close button
that buries a buffer another window shows and kills one no window
does.

  `modern-tab-bar-mode'   the tab bar, one tab per tab group
  `modern-tab-line-mode'  the tab line, one tab per window buffer

The two are independent — turn on either.  The indicator options
carry matching names in both; the icon options do not, because a tab
group is named by a string and a tab of the tab line by a buffer.

This file is the common one: the indicator beside a tab, the glyph
fallback, the icon table and the way a mode gives Emacs its
variables back.  It is also the file package-lint reads as the
package's main one, which is why it carries the name the whole
package is prefixed with: package-lint takes that prefix from the
main file's name, and `modern-tab-bar-mode' and
`modern-tab-line-mode' both live under `modern-tab-'.  It carries
the version and the dependency line for the same reason, and elpaca
reads them here too, because the id it is installed by is the name
of this file, and so is the repository.

Both modes are autoloaded, so nothing here needs requiring:

  (use-package modern-tab
    :vc (:url "https://github.com/MArpogaus/modern-tab" :rev :newest)
    :hook ((after-init . modern-tab-bar-mode)
           (after-init . modern-tab-line-mode)))

The buttons of the two rows are one family: every glyph a button
leads with is a codicon, so the plus of the tab bar, the close
button of both rows, the menu button and the mark on the selected
tab carry one weight and one visual size.  A filled shape among thin
ones shouts, and so does a bold one.

Icons come from nerd-icons where it is installed.  A graphic frame
shows the first glyph of a candidate list as it is — which fonts
draw it is the frame's business, fallbacks included.  A terminal is
asked whether it can encode the characters, and a glyph of a
private use area is refused there.  A symbol a UTF-8 terminal can
encode but its font has no glyph for still shows a box — name plain
strings in the icon options there.
