This library lets elisp authors easily define an idiomatic command
to reformat the current buffer using a command-line program,
together with an optional minor mode which can apply this command
automatically on save.

By default, reformatter.el expects programs to read from stdin and
write to stdout, and you should prefer this mode of operation where
possible.  If this isn't possible with your particular formatting
program, refer to the options for `reformatter-define', and see the
examples in the package's tests.

As an example, let's define a reformat command that applies the
"dhall format" command.  We'll assume here that we've already defined a
variable `dhall-command' which holds the string name or path of the
dhall executable:

    (reformatter-define dhall-format
      :program dhall-command
      :args '("format"))

The `reformatter-define' macro expands to code which generates
`dhall-format-buffer' and `dhall-format-region' interactive
commands, and a local minor mode called
`dhall-format-on-save-mode'.  The :args" and :program expressions
will be evaluated at runtime, so they can refer to variables that
may (later) have a buffer-local value.  A custom variable will be
generated for the mode lighter, with the supplied value becoming
the default.

The generated minor mode allows idiomatic per-directory or per-file
customisation, via the "modes" support baked into Emacs' file-local
and directory-local variables mechanisms.  For example, users of
the above example might add the following to a project-specific
.dir-locals.el file:

    ((dhall-mode
      (mode . dhall-format-on-save)))

See the documentation for `reformatter-define', which provides a
number of options for customising the generated code.

Library authors might like to provide autoloads for the generated
code, e.g.:

    ;;;###autoload (autoload 'dhall-format-buffer "current-file" nil t)
    ;;;###autoload (autoload 'dhall-format-region "current-file" nil t)
    ;;;###autoload (autoload 'dhall-format-on-save-mode "current-file" nil t)
