This package defines two additional Org link types "elisp-function"
and "elisp-variable" which are intended to be used mainly in user
documentation.  By default opening these links is done by calling
`describe-function' and `describe-variable'.  That is only possible
when the function/variable is defined; therefor urls should include
the library defining the respective symbol.  If the symbol is not
`fbound'/`bound' when the link is opened and the url contains
information about the defining feature then that is loaded first.

  [[elisp-function:FEATURE:SYMBOL][...]]
  [[elisp-variable:FEATURE:SYMBOL][...]]
  [[elisp-function::SYMBOL][...]]
  [[elisp-variable::SYMBOL][...]]

If you want to capture information about a symbol while working on
elisp code you should instead use the "elisp-symbol" Org link type
defined in `org-elisp-symbol' (which is distributed with Org-Mode).
The link types defined here cannot be captured as that would
conflict with the "elisp-symbol" type.  Instead use the command:

  `org-elisp-help-function-insert-link' and
  `org-elisp-help-variable-insert-link'.
