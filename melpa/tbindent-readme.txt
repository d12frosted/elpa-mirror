
This provides the `tbindent-mode', a minor mode that seamlessly
converts the space-based indentation file into tab-based indented buffer.

While the minor mode is active you can change the indentation width by
executing the `tbindent-set-tab-width' command.  That command changes the
`tab-width' and the indentation width to the new value, to use narrower or
wider indentation.

When saving the buffer content back to the file, the mode automatically
converts the indentation back to the original space-indentation scheme.


Why?

Although not popular in most software development circles, using hard tabs
for indentation provides the undeniable advantage of flexibility in terms
of visual rendering.  Once all indentation level correspond to 1 hard-tab
you can easily change the visual width of indentation with the
`tbindent-set-tab-width' command.  That does not modify the content of the
file.

This feature may appeal to people that have problems working with small
indentation width imposed by language or team conventions.  It acts as a
workaround: temporary change the indentation scheme to a hard-tab based
indentation for editing, change the width of the hard tab for visibility
but keep the original indentation scheme inside the file.

For example, Dart and Gleam impose a 2-space indentation level.  For
buffers using major modes for those languages, we can use the following
procedure:

- set the indentation control variable to 2 and the `tab-width' to 2,
- tabify the indentation whitespace of the entire buffer excluding all
  strings and comments.
- change the with of hard tabs (controlled by the `tab-width' variable),
  and the width of the variables for the major mode to a larger value.

Once set-up we can see the code with a wider indentation and
continue to work with the rules imposed by the major mode logic.

Later, before saving the buffer back to the file, we simply perform the
following steps:

- restore the tab and indentation width back to 2,
- untabify all indentation whitespace,
- save the file.

The library provides all necessary functions, along with a special minor-mode
that automatically performs all operation seamlessly, allowing editing the
files with wider indentation despite the space-based indentation used in
the files.

The files retain their original space-based indentation scheme but you can
edit them with a wider or narrower indention width!

For more information see the README.rst.txt file.

---------------------------------------------------------------------------
