This is a simple API client for Emacs and marmalade-repo,
based on Nic Ferrier's lexical scope `web' client.

Mainly this is useful because it lets you upload a package to
marmalade-repo.  If you open a buffer with a package file in it you
just have to:

  M-x marmalade-upload [RET]

and enter your username and password and you're away.

If you're not in a package buffer then marmalade-client will ask
you what your package file is.  This means you can also upload
multi-file packages.

It also allows removal of packages.  Again you need to have a
login, you also need to be assigned an owner of a package:

  M-x marmalade-remove-package [RET]

marmalade does completion of package names based on what your Emacs
has downloaded from marmalade.  If a package is missing perhaps you
need to:

  M-x package-refresh-packages [RET]

and try again.

You can also add owners to your package:

 M-x marmalade-client-add-owner [RET]

This makes it easier to distribute the management of releases and
also to hand off a package when you get tired of maintaining it.
