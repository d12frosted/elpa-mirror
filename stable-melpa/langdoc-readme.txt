This library helps you to define help document mode for various languages.
`langdoc-define-help-mode' makes a major mode for help document
and a function to show a description of a symbol.  It takes at least six
arguments.

First three arguments are to define the help document mode.
* MODE-PREFIX
  Symbol to make a help mode name and a function name.
  `langdoc-define-help-mode' makes a major mode named MODE-PREFIX-mode
  and a function named MODE-PREFIX-describe-symbol.
* DESCRIPTION
  Description for MODE-PREFIX-mode.
* HELPBUF-NAME
  Buffer name for MODE-PREFIX-mode

Next three arguments are to define MODE-PREFIX-describe-symbol.
* POINTED-SYM-FN
  Function name which returns the string pointed by
  the cursor.  This function takes no arguments.
* SYMBOL
  List of strings which is used to complete words.
* MAKE-DOCUMENT-FN
  Function name which takes the word as a string
  and returns the help string.

Rest of the arguments is to make links in help buffers.
* LINK-REGEXP
  Regexp string to make links.
  If nil, MODE-PREFIX-describe-symbol does not make any links in help buffers.
* LINKED-STR-FN
  Function name which takes substrings matched in LINK-REGEXP
  and returns the string to be linked.
* MAKE-LINK-FN
  Function name which takes same arguments as LINKED-STR-FN
  and returns a string or a cons pair (SYM . FUN).
  SYM is a link to other document and FUN is the function to jump to the help buffer for SYM.
  If it returns a string, MODE-PREFIX-describe-symbol is used to jump to SYM.
* PREFIX-STR, SUFFIX-STR
  Prefix and suffix of the string returned from LINKED-STR-FN.

If you need a concrete example, see brainfuck-mode.el (https://github.com/tom-tan/brainfuck-mode/).
