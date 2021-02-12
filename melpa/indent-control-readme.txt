
Interface that combine all the indentation variables from each major
mode to one giant list.

You can set up the initial indentation level by changing the variable
`indent-control-records'.  This variable is a list on cons cell form
by (mode . level).  For example,

  `(actionscript-mode . 4)`

If you want to make the indentation level works consistently across
all buffer.  You would need to call function `indent-control-continue-with-record'
at the time you want the new buffer is loaded.
