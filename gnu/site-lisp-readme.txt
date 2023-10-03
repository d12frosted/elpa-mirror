This package automates the management of local Lisp code.  Similar
to package.el, it will byte-compile files, scrape for autoload
cookies and update the `load-path', but "installing" a package just
involves placing a file or a directory into a "site-lisp"
directory, inside your Emacs configuration directory (see
`site-lisp-directory' if you wish to modify this behaviour).

New files will automatically be registered when
`site-lisp-initialise' is invoked (the function is autoloaded, so
you can add it directly to your init.el), but you can invoke the
command `site-lisp-reload' at any time to avoid restarting Emacs.