kind-icon-mode adds an colorful icon or text prefix based on
:company-kind for compatible completion UI's.  The "kind" prefix is
typically used for differentiating completion candidates such as
variables, functions, etc.  It works in one of 2 ways:

 1. For UI's with "margin-formatters" capability, simply add
    `kind-icon-margin-formatter` to the margin formatter list.

 2. For UI's without a margin-formatters but which support
    "affixation functions" (an Emacs 28 and later completion
    property), use `kind-icon-enhance-completion' to wrap the
    normal completion-in-region-function.  E.g. (in the completion
    mode's hook):

    (setq completion-in-region-function
       (kind-icon-enhance-completion completion-in-region-function)

 3. If your UI supports neither margin-formatters nor affixation
    functions, ask them to do so!

Note that icon support requires svg-lib to be installed.

The `kind-icon-formatted' function creates, styles, and caches a
short-text or icon-based "badge" representing the kind of the
candidate.  Icons are by default loaded remotely from the
"material" library provided by svg-lib, which is required (unless
only short-text badges are desired, see `kind-icon-use-icons').
Customize `kind-icon-mapping' to configure mapping between kind and
both short-text and icons.