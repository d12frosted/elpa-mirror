A pretty simple (but, at least for me, effective) backend for Emacs 25
xref library using GNU Global.

## Overview

Emacs 25 introduces a new (and experimental) `xref' package.  The
package aims to provide a standardized access to cross-referencing
operations, while allowing the implementation of different back-ends
which implement that cross-referencing using different mechanisms.  The
gxref package implements an xref backend using the GNU Global tool.


## Prerequisites:

* GNU Global.
* Emacs version >= 25.1

## Installation

Gxref is now available on MELPA.  Once you
get [MELPA](https://melpa.org/#/getting-started) set up, you can
install gxref by typing

```
M-x package-install RET gxref RET
```

See [here][Installation] if you prefer to install manually.


## <a name="setup"></a>Setting up.

Add something like the following to your init.el file:

```elisp
(add-to-list 'xref-backend-functions 'gxref-xref-backend)
```

This will add gxref as a backend for xref functions.  The backend
will be used whenever a GNU Global project is detected.  That is,
whenever a GTAGS database file exists in the current directory or
above it, or an explicit project [was set](#setting_project).


## <a name="usage"></a>Usage

### Using gxref to locate tags

After [setup](#setup), invoking any of the xref functions will use
GNU Global whenever a GTAGS file can be located.  By default, xref
functions are bound as follows:


| Function              | Binding  |
|:---------------------:|:--------:|
| xref-find-definitions | M-.      |
| xref-find-references  | M-?      |
| xref-find-apropos     | C-M-.    |
| xref-pop-marker-stack | M-,      |

If a GTAGS file can't be located for the current buffer, xref will
fall back to whatever other backends it's configured to try.

### <a name="setting_project"></a>Project root directory.

By default, gxref searches for the root directory of the project,
and the GTAGS database file, by looking in the current directory,
and then upwards through parent directories until the database is located.
If you prefer, you can explicitly set the project directory.
This can be done either interactively, by typing `M-x
gxref-set-project-dir RET`, or by setting the variable
`gxref-gtags-root-dir` to the GTAGS directory.  You can also set up
`gxref-gtags-root-dir` as a file-local or a dir-local variable.

### Configuring gxref

gxref can be customized in several ways.  use
`M-x customize-group RET gxref RET` to start.

Additionally, the following variables can be used to affect the execution
of GNU Global. You can set them either globally, or as file-local or
dir-local variables:

 - gxref-gtags-conf
   The GTAGS/GLOBAL configuration file to use.

 - gxref-gtags-label
   GTAGS/GLOBAL Configuration label

 - gxref-gtags-lib-path
   the library path.  Passed to GNU Global using the GTAGSLIBPATH
   environment variable.

## Bug reports

If you find any bugs, please tell me about it at
the [gxref home page][Repository]
## Disclaimers:

Because the xref API in Emacs 25.1 is experimental, it's likely to
change in ways that will break this package.  I will try to keep up
with API changes.

## Source and License

Package source can be found in the github
repository [here][Repository].

It is released under version 3 of the GPL, which you can
find [here][License]

[Repository]: https://github.com/dedi/gxref
[Installation]: https://github.com/dedi/gxref/wiki/Installing-and-setting-up-gxref
[License]: https://www.gnu.org/licenses/gpl-3.0.en.html
