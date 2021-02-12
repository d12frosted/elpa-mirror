Support for copying text with formatting information, like color,
to the system clipboard. Concretely, this allows you to paste
syntax highlighted source code into word processors and mail
editors.

On MS-Windows, Ruby must be installed.

Usage:

* `M-x highlight2clipboard-copy-region-to-clipboard RET' -- Copy
  the region, with formatting, to the clipboard.

* `M-x highlight2clipboard-copy-buffer-to-clipboard RET' -- Copy
  the buffer, with formatting, to the clipboard.

* Highlight2clipboard mode -- Global minor mode, when enabled, all
  copies and cuts are exported, with formatting information, to the
  clipboard.

Supported systems:

Copying formatted text to the clipboard is highly system specific.
Currently, Mac OS X and MS-Windows are supported. Contributions for
other systems are most welcome.

Known problems:

Font Lock mode, the system providing syntax highlighting in Emacs,
use "lazy highlighting". Effectively, this mean that only the
visible parts of a buffer are highlighted. The problem with this is
that when copying text to the clipboard, only the highlighted parts
gets formatting information. To get around this, walk through the
buffer, use `highlight2clipboard-ensure-buffer-is-fontified', or
use one of the `highlight2clipboard-copy-' functions.

This package generates some temporary files, which it does not
remove. It is assumed that the system temporary directory is
cleaned from time to time.

Implementation:

This package use the package `htmlize' to create an HTML version of
a highlighted text. This is added as a new flavor to the clipboard,
allowing an application to pick the most suited version.
