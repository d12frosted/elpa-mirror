This library offers two functions that perform schema validation.
Use this is your Elisp packages to provide very informative error
messages when your users accidentally misconfigure a variable.
For instance, if everything is fine, these do the same thing:

  1.  (validate-variable 'cider-known-endpoints)
  2.  cider-known-endpoints

However, if the user has misconfigured this variable, option
1. will immediately give them an informative error message, while
option 2. won't say anything and will lead to confusing errors down
the line.

The format and language of the schemas is the same one used in the
`:type' property of a `defcustom'.

    See: (info "(elisp) Customization Types")

Both functions throw a `user-error' if the value in question
doesn't match the schema, and return the value itself if it
matches.  The function `validate-variable' verifies whether the value of a
custom variable matches its custom-type, while `validate-value' checks an
arbitrary value against an arbitrary schema.

Missing features: `:inline', `plist', `coding-system', `color',
`hook', `restricted-sexp'.