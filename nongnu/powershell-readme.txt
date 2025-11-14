PowerShell Mode
===============


PowerShell Mode is an Emacs major mode for editing and running
Microsoft PowerShell files.

Installation
============

**With MELPA**

First, add the package repository:

```lisp
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
```

Then install `powershell.el`:

<kbd>M-x package-install RET powershell RET</kbd>

You can also install the package use `use-package`:

```lisp
(use-package powershell
    :ensure t)
```

**El-Get**

`powershell.el` is included in the El-Get repository

Install powershell.el:

<kbd>M-x el-get-install RET powershell.el RET</kbd>

**Manually**

Download `powershell.el` and place the download directory on your
`load-path` like so:

```lisp
(add-to-list 'load-path "~/.emacs.d/path/to/powershell")
```

eglot & LSP Support
----------------------

`powershell-mode` has built in support for Language Server Protocol
(LSP) via `eglot`.

To download the latest language-server and register it with `eglot`,
simply invoke `M-x powershell-install-langserver`.

Doing this when a version is already installed will overwrite it with
the latest version available.

History
-------

I combined
[powershell.el](http://www.emacswiki.org/emacs/Powershell.el) and
[powershell-mode.el](http://www.emacswiki.org/emacs/PowerShell-Mode.el)
(last updated October 2012).  I used the name powershell.el with the
permission of the creator, Dino Chiesa.  Since powershell.el was
licensed with the new BSD license I combined the two files using the
more restrictive license, the GPL.  I also cleaned up the
documentation and reorganized some of the code.
