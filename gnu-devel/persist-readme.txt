This package provides variables which persist across sessions.

The main entry point is `persist-defvar' which behaves like
`defvar' but which persists the variables between session.  Variables
are automatically saved when Emacs exits.

Other useful functions are `persist-save' which saves the variable
immediately, `persist-load' which loads the saved value,
`persist-reset' which resets to the default value.

Values are stored in a directory in `user-emacs-directory', using
one file per value.  This makes it easy to delete or remove unused
variables.