When editing a text, and `dynamic-spaces-mode' is enabled, text
separated by more than one space doesn't move, if possible.
Concretely, end-of-line comments stay in place when you edit the
code and you can edit a field in a table without affecting other
fields.

For example, this is the content of a buffer before an edit (where
`*' represents the cursor):

    alpha*gamma         delta
    one two             three

When inserting "beta" without dynamic spaces, the result would be:

    alphabeta*gamma         delta
    one two             three

However, with `dynamic-spaces-mode' enabled the result becomes:

    alphabeta*gamma     delta
    one two             three

Usage:

To enable *dynamic spaces* for all supported modes, add the
following to a suitable init file:

    (dynamic-spaces-global-mode 1)

Or, activate it for a specific major mode:

    (add-hook 'example-mode-hook 'dynamic-spaces-mode)

Alternatively, use `M-x customize-group RET dynamic-spaces RET'.

Space groups:

Two pieces of text are considered different (and
`dynamic-spaces-mode' tries to keep then in place) if they are
separated by a "space group".  The following is, by default,
considered space groups:

* A TAB character.

* Two or more whitespace characters.

However, the following are *not* considered space groups:

* whitespace in a quoted string.

* Two spaces, when preceded by a punctuation character and
  `sentence-end-double-space' is non-nil.

* Two spaces, when preceded by a colon and `colon-double-space' is
  non-nil.

Configuration:

You can use the following variables to modify the behavior or
`dynamic-spaces-mode':

* `dynamic-spaces-mode-list' - List of major modes where
  dynamic spaces mode should be enabled by the global mode.

* `dynamic-spaces-avoid-mode-list' - List of major modes where
  dynamic spaces mode should not be enabled.

* `dynamic-spaces-global-mode-ignore-buffer' - When non-nil in a
  buffer, `dynamic-spaces-mode' will not be enabled in that buffer
  when `dynamic-spaces-global-mode' is enabled.

* `dynamic-spaces-commands' - Commands that dynamic spaces mode
  should adjust spaces for.

* `dynamic-spaces-keys' - Keys, in `kbd' format, that dynamic
  spaces mode should adjust spaces for.  (This is needed as many
  major modes define electric command and bind them to typical edit
  keys.)

* `dynamic-spaces-find-next-space-group-function' - A function that
  would find the next dynamic space group.

Notes:

By default, this is disabled for org-mode since it interferes with
the org mode table edit system.
