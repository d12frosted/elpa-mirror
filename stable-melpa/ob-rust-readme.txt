Org-Babel support for evaluating rust code.

Much of this is modeled after `ob-C'.  Just like the `ob-C', you can specify
:flags headers when compiling with the "rust run" command.  Unlike `ob-C', you
can also specify :args which can be a list of arguments to pass to the
binary.  If you quote the value passed into the list, it will use `ob-ref'
to find the reference data.

If you do not include a main function or a package name, `ob-rust' will
provide it for you and it's the only way to properly use

very limited implementation:
- currently only support :results output.

; Requirements:

- You must have rust and cargo installed and the rust and cargo should be in your `exec-path'
  rust command.

- rust-script

- `rust-mode' is also recommended for syntax highlighting and
  formatting.  Not this particularly needs it, it just assumes you
  have it.
