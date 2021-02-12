To enable the Go guru in Emacs, use this command to download,
build, and install the tool in $GOROOT/bin:

    $ go get golang.org/x/tools/cmd/guru

Verify that the tool is on your $PATH:

    $ guru -help
    Go source code guru.
    Usage: guru [flags] <mode> <position>
    ...

Then copy this file to a directory on your `load-path',
and add this to your ~/.emacs:

    (require 'go-guru)

Inside a buffer of Go source code, select an expression of
interest, and type `C-c C-o d' (for "describe") or run one of the
other go-guru-xxx commands.  If you use `menu-bar-mode', these
commands are available from the Guru menu.

To enable identifier highlighting mode in a Go source buffer, use:

    (go-guru-hl-identifier-mode)

To enable it automatically in all Go source buffers,
add this to your ~/.emacs:

    (add-hook 'go-mode-hook #'go-guru-hl-identifier-mode)

See http://golang.org/s/using-guru for more information about guru.
