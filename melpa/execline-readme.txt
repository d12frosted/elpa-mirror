Major mode for editing execline scripts.  Features:

  * syntax highlighting of commends, builtin commands and variable substitution.
  * completion of builtin commands.
  * working "comment-region" command.
  * indentation of blocks
  * automatic enable of mode in *.exec files.
  * automatic enable of mode in files with "execlineb" interpreter

Missing features:

  * adaptive indentation.  Current indentation algorithm assumes that
    previous line indented by same algorithm.  Trying to use indentation,
    provided by this mode in buffer with script, indented with another style
    (say, with two spaces per indentation level), causes wrong results.
