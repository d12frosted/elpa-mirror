Org-Babel support for evaluating go code.

Much of this is modeled after `ob-C'. Just like the `ob-C', you can specify
:flags headers when compiling with the "go run" command. Unlike `ob-C', you
can also specify :args which can be a list of arguments to pass to the
binary. If you quote the value passed into the list, it will use `ob-ref'
to find the reference data.

If you do not include a main function or a package name, `ob-go' will
provide it for you and it's the only way to properly use

very limited implementation:
- currently only support :results output.
- not much in the way of error feedback.
- cannot handle table or list input.

; Requirements:

- You must have go1 installed and the go should be in your `exec-path'. If
  not, feel free to modify `org-babel-go-command' to the location of your
  go command.

- `go-mode' is also recommended for syntax highlighting and
  formatting. Not this particularly needs it, it just assumes you
  have it.
