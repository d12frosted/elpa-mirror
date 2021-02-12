A quick stab at providing a simple template facility like the one
present in TextMate (an OSX editor).  The general idea is that a
snippet of text (called a template) is inserted into a buffer
(perhaps triggered by an abbrev), and while the point is within the
snippet, a special keymap is active to permit the user to cycle the
point to any of the defined fields (placeholders) within the
template via `snippet-next-field' and `snippet-prev-field'.

For example, the following template might be a useful while editing
HTML:

  <a href="$$">$$</a>

This template might be useful for python developers.  In this
example, reasonable defaults have been supplied:

  for $${element} in $${sequence}:
      match = $${regexp}.search($${element})

When a template is inserted into a buffer (could be triggered by an
abbrev expansion, or simply bound to some key), point is moved to
the first field denoted by the "$$" characters (configurable via
`snippet-field-identifier').  The optional default for a field is
specified by the "{default}" (the delimiters are configurable via
`snippet-field-default-beg-char' and `snippet-field-defaul-end-char'.

If present, the default will be inserted and highlighted.  The user
then has the option of accepting the default by simply tabbing over
to the next field (any other key bound to `snippet-next-field' in
`snippet-map' can be used).  Alternatively, the user can start
typing their own value for the field which will cause the default
to be immediately replaced with the user's own input.  If two or
more fields have the same default value, they are linked together
(changing one will change the other dynamically as you type).

`snippet-next-field' (bound to <tab> by default) moves the point to
the next field.  `snippet-prev-field' (bound to <S-tab> by default)
moves the point to the previous field.  When the snippet has been
completed, the user simply tabs past the last field which causes
the snippet to revert to plain text in a buffer.  The idea is that
snippets should get out of a user's way as soon as they have been
filled and completed.

After tabbing past all of the fields, point is moved to the end of
the snippet, unless the user has specified a place within the
template with the `snippet-exit-identifier' ("$." by default).  For
example:

  if ($${test} {
      $.
  }

Indentation can be controlled on a per line basis by including the
`snippet-indent' string within the template.  Most often one would
include this at the beginning of a line; however, there are times
when indentation is better performed in other parts of the line.
The following shows how to use the functionality:

  if ($${test}) {
  $>this line would be indented
  this line will be indented after being inserted$>
  }
