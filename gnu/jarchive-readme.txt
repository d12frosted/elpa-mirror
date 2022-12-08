Jarchive teaches emacs how to open project dependencies that reside inside jar files.

# Package status

This package is still under active development, but should be relatively stable.
Any important or breaking changes will now be noted in the CHANGELOG.

It current works well with eglot on the Emacs master branch.
I've also included a patch for legacy versions of eglot that are not yet up to date with Emacs master.

See the [CHANGELOG](item/CHANGELOG.md "change log") for more information.

# Installing

This package is available on [ELPA](https://elpa.gnu.org/packages/jarchive.html "jarchive on elpa").
There is also an example of a [guix recipe](https://git.sr.ht/~abcdw/rde/tree/90af100a4d70d7016261d39b91b6748768ac374b/rde/packages/emacs-xyz.scm#L330 "jarchive guix recipe").

After installing this package, in your config call `jarchive-setup`:

```emacs-lisp
(jarchive-setup)
```

or it can be called interactively, via `M-x jarchive-setup`.
    
## Doom Emacs users: Note about when to call `jarchive-setup`

Some Emacs distributions like [Doom](https://github.com/doomemacs/doomemacs "doom emacs on github") (and many personal configurations), set the `file-name-handler-alist` var to nil on startup, then restore it's value when startup is complete.

If this is the case for you, `jarchive-setup` should be called AFTER everything is initialized, using `(with-eval-after-load "init" (jarchive-setup))`, where `"init"` refers to your `"init.el"` file.
This package modifies `file-name-handler-alist`, so it relies on it _not_ being reset after `jarchive-setup` is invoked.

## Working with Eglot

Jarchive will open jar dependencies provided to Eglot by lsp servers.

If you are using an older version of Eglot, like the melpa version released on [2022-10-20](https://melpa.org/packages/eglot-20221020.1010.el "Eglot Melpa Release 2022-10-20"), then you need to call `jarchive-patch-eglot` after Eglot is loaded, like so

``` emacs-lisp
(jarchive-patch-eglot)
```

This is _not_ required on newer versions of eglot. Installs that are up to date with eglot on [ELPA devel](https://elpa.gnu.org/devel/eglot.html "Eglot ELPA Devel Release") or eglot bundled with emacs 29 will work without patching.
This patch function is included so those on older releases of eglot can also take advantage of this package.
Eventually it will be removed (with some advanced notice).

# Usage

With it enabled, things like this will open up `page.clj` in a read-only buffer.

```emacs-lisp
(find-file "jar:file:///.m2/repository/hiccup/hiccup/1.0.5/hiccup-1.0.5.jar!/hiccup/page.clj")
```

When using eglot connected to a JVM language server, invoking `xref-find-definitions` should correctly open any dependencies that reside in JAR files.

## Other usage considerations

If you want eglot to manage the opened jar'd file in your project's current lsp session, set
``` emacs-lisp
(setq eglot-extend-to-xref t) 
```
This will allow xref to work across your project and the opened file.

If you do not want that, the eglot will probably start a new server to manage the newly opened file.
There are legitimate reasons to do this, because including it in the current LSP session will mean it is included when looking up references.
Large files, like the clojure core library, could create a lot of noise in xref lookups.
Another recommendation if you don't want them managed by eglot is to set
``` emacs-lisp
(setq eglot-autoshutdown t)
```
so that the transient lsp server that is started when opening the file is closed along with it.

## Language server compatibility

I personally only test this with [clojure-lsp](https://clojure-lsp.io/).

I have heard from other users that it also works with some unspecified java language server. 
I do know that it does not work with `JDTLS` at them moment, which requires all clients to implement custom language server extensions and a complicated non-standard URI scheme to open files in JARs.

Any language server that provides jar: scheme URIs should be picked up by this package.
If it doesn't, please let me know and I'd be happy to take a look.

## Questions and Bugs

Questions and patches can be submitted to the [mailing list](https://lists.sr.ht/~dannyfreeman/jarchive-dev).

Bugs can be submitted here: [bug tracker](https://todo.sr.ht/~dannyfreeman/jarchive).
Any bugs found should include steps to reproduce. 
If possible, and example repository containing a project and instructions (or a nix shell) for installing the language servers would be appreciated.
