Advanced highlighting package for Doxygen comments.

In addition to highlighting Doxygen commands and their arguments,
entire Doxygen comment are highlighted, making them stand out
compared to other comments.  In addition, and code blocks are
highlighted according to the language they are written in.

Usage:

This package provide two minor modes, `highlight-doxygen-mode' and
`highlight-doxygen-global-mode'.

Can enable `highlight-doxygen-mode' from the hook of a mode.

Alternatively, you can enable the minor mode for all major modes
specified in `highlight-doxygen-modes'.  Typically, this is done by
placing the following in a suitable init file:

    (highlight-doxygen-global-mode 1)

What is highlighted:

* The full Doxygen comment is highlighted with a different
  background color, to make them stand out compared to normal code
  other comments.

* Doxygen commands and their arguments are highlighted.  The
  arguments are highlighted according to the signature of the
  commands.  For example, the argument to the `\a' command is
  highlighted as a variable.

* Code blocks are highlighted using the Emacs highlighting rules
  for the language they are written in.  In addition, the
  background is changed to make the code block stand out.

* Customization friendly.  This package define a number of custom
  faces that can be customized to fine tune the appearance if this
  package.  The default value of all defined faces inherit from
  standard Emacs faces, which mean that customizations done by the
  user or themes are automatically used.

Code blocks:

A code block is specified using a pair of Doxygen commands like
`\code' and `\endcode' or `\dot' and `\enddot'.

Code blocks are syntax highlighted using the major mode they are
written in.  The major mode is selected as follows:

* If the `\code{.ext}' construct is used, the major mode associated
  with extension `.ext' is used.

* For `\dot', `\msc', and `\startuml' is used, the extensions
  `.dot', `.msc', and `.plantuml' are used, respectively.

* For `\code' blocks that does not specify an extension, the major
  mode of the buffer is used.
