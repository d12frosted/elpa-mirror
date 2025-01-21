*e2ansi* (Emacs to ANSI) converts a text highlighted in Emacs to a
text with ANSI escape codes, which can be displayed in a terminal
window, with the highlighting still visible.

The `e2ansi-cat' command line tool can be used to generate text
with ANSI escape codes directly in the terminal. The actual syntax
highlighting is performed by Emacs running in batch mode.

Pager applications like `more' and `less' can be configured to
automatically invoke `e2ansi-cat', so that all viewed files will be
syntax highlighted. A nice side effect is that other conversions
that Emacs normally performs, like uncompressing files, are also
automatically applied.

This package can highlight all languages that Emacs supports,
either directly or via external packages. Since Emacs is exendible,
you can easily add an Emacs major mode for any programming language
or structured text.

Example:

| Before                     | After                         |
| ------                     | -----                         |
| ![](doc/no_color_dark.png) | ![](doc/default_dark_256.png) |

Quick install:


Emacs setup:

Install the `e2ansi' package using the Emacs package manager.

Optionally create an e2ansi-specific init file,
e.g. `~/.e2ansi'. (See below.)


Shell setup for `less':

Run the Emacs command `e2ansi-display-shell-setup' and copy
relevant lines to a suitable shell init file, like `~/.bashrc'.

The output assumes that a bash-compatible shell is used. The syntax
might need to be adjusted for other shells.

The Emacs package manager include the version number in the
installation location of `e2ansi'. This, unfortunately, means that
the shell configuration must be updated every time `e2ansi' is
updated.

The `e2ansi-cat' command line tool:

Syntax:

    e2ansi-cat [OPTION ...] file ...

If the name of the file is `-', the input is read from standard
input, so that the tool can be used in pipes:

    diff alpha.txt beta.txt | e2ansi-cat -

Options:

* `--theme' -- Specify the color theme to use.

* `--usage' or `--help' -- Show help text. (Note: Unless `--help'
  is preceeded by `--', Emacs will display its own help text.)

Options for display properties:

* `--background-mode' -- Specify `light' or `dark' background mode.

* `--colors' -- Number of colors, or `rgb24' for full 24 bit
  colors. This is both used when parsing the `min-colors'
  requirement in face definitions (c.f. `defface') and when
  deciding the kind of ANSI escape codes that is used.

* `--color-class' -- Specify one of the `color', `grayscale' or
  `mono' face specification requirement (c.f. `defface').

The *e2ansi* init file:

When using Emacs in batch mode, Emacs reads the site init file but
not the user init file. However, for *e2ansi*, it is often
desirable to load the user init files, for example, to configure
font-lock settings and add additional major modes.

When the command line tools `e2ansi-cat' and `e2ansi-info' are
launched, they try to load the init files `.e2ansi' and
`e2ansi-init.el' from the following locations:

* The user home directory.

* The `emacs' XDG config directory (typically `~/.config/emacs').

* The Emacs user directory (typically `~/.emacs.d').

This file can include configuration specific to *e2ansi*, or it can
load the normal user init files. This is a good place to specify
display properties such as the background mode.

For example:

    ;;; .e2ansi --- Init file for e2ansi.  -*- emacs-lisp -*-
    (require 'e2ansi-silent)
    (require 'e2ansi-magic)
    (setq face-explorer-background-mode 'dark)
    (load "~/.emacs" nil t)
    ;;; .e2ansi ends here

Integration with `less':

The shell pager commands `more' and `less' can be configured to use
`e2ansi-cat' to highlight viewed files. This is done by defining
the `LESSOPEN' environment variable with the name of a script and
`%s' (which is substituted for the file name), the `||-' prefix
says that the script can work in a pipe. In addition, the `MORE'
and `LESS' environment variables should contain the `-R' option --
without it the ANSI escape codes are not sent to the terminal. For
example (in bash syntax):

    export "LESSOPEN=||-PATH-TO-E2ANSI/bin/e2ansi-cat %s"
    export "LESS=-R"
    export "MORE=-R"

In addition, the command `emacs' must be in the path.

More about `less':

The command line tool `less' is preinstalled on most systems. If it
is missing or outdated on your system it's easy to download and
build a new version from http://www.greenwoodsoftware.com/less

The document [LessWindows](doc/LessWindows.md) describes how to
build `less' using `cmake', a modern build system.

The *e2ansi* modules:

* `e2ansi.el' -- The rendering engine for ANSI ecape codes.

* `e2ansi-magic.el' -- Set up `magic-mode-alist' to recognize file
  formats based on the content of files. This is useful when using
  `less' in pipes where Emacs can't use the file name extension to
  select a suitable major mode.

* `e2ansi-silent.el' -- Load this in batch mode to silence some
  messages from init files.

* `e2ansi-load-init.el' -- Support module for the command line
  tools to load the *e2ansi* init file.

* `bin/e2ansi-cat' -- Command line tool to add highligting a file
  using ANSI escape codes.

* `bin/e2ansi-info' -- Print various ANSI-related information to
  help you trim your ANSI environment.

Launching emacs script:

In some cases it's not possible to launch Emacs command like tools
`e2ansi-cat' directly, for example when using MS-Windows.

Instead, `emacs' can be used in match mode, for example:

    emacs --batch -l PATH-TO-E2ANSI/bin/e2ansi-cat

Additional Emacs options, like `-Q' (suppress the site init file)
can be specified.

Using *e2ansi* inside Emacs:

The following functions can be used in other applications:

* `e2ansi-write-file' -- Generate a file with ANSI escape codes.

* `e2ansi-view-buffer' -- Display the content of the buffer, with
  ANSI escape codes. (Typcailly, this doesn't look good, but it is
  useful to see which ANSI escpe codes are generated.)

* `e2ansi-string-to-ansi' -- Convert a highlighted string to a
  string with ANSI escape codes.

The `face-explorer' library:

In batch mode, Emacs natively doesn't provide face
attributes. Instead, *e2ansi* uses the `face-explorer' library to
deduce the properties of faces, based on the underlying face
definitions.

The following variables controls the display environment that
`face-explorer' uses. The variables can, for example, be set using
*e2ansi* command line options or in the *e2ansi* or Emacs init
file.

Each variable corresponds to a display property in face
specifications (see `defface').

* `face-explorer-background-mode' -- `light' or `dark'. This
  corresponds to the `background' display property.

* `face-explorer-number-of-colors' -- Number of colors, e.g. 8, 16,
  256, or t. Corresponds to the `min-color' display property. This
  also is used to decide the kind of ANSI escape codes to use.

* `face-explorer-color-class' -- `color', `grayscale', or
  `mono'. This corresponds to the `class' display property.

* `face-explorer-window-system-type' -- The window system
  used. This can be a symbol, a list of symbols, or t to match any
  type. Corresponds to the `type' display property.

Adapting init files to batch mode:

As Emacs most often is used in interactive mode there is a risk
that parts of the system or your init file doesn't work in batch
mode.

To exclude something when in batch mode, you can use:

    (unless noninteractive
      .. original code goes here ... )

Background:

What is Emacs?:

Emacs is a the mother of all text editors. It originates from the
1970:s, but is still in active development. It runs under all major
operating systems, including MS-Windows, macOS, and various
UNIX-like systems like Linux. You can use normal windows, run it in
a terminal window (great when working remotely), or use it to run
scripts in batch mode, which is how it is used by the command line
tools provided by this package.

Emacs provides state-of-the-art syntax highlighting.

Why use Emacs to power syntax highlighting in the terminal?:

There are many advantages:

* Emacs has support for a vast range of programming languages and
  other structured text formats. Many are provided by the basic
  Emacs distribution, others can be installed as separate packages.

* Emacs is fast and accurate -- it is designed for interactive use,
  and provides advanced support for parsing programming languages
  and other strucured text.

* Emacs supports color themes. If you don't like the ones provided,
  and can't find one on internet, you can easily write your own.

* Emacs is *extendible*. You can add an Emacs *major mode* for any
  structured format, or you can add a *minor mode* that can be used
  together with existing major modes. Syntax highlighting in Emacs
  is typically provided by *Font Lock rules*, which can range from
  using simple pattern matching to very complex code.

ANSI escpe codes:

ANSI escape codes, formally known as ISO/IEC 6429, is a system used
by various physical terminals and console programs to, for example,
to add colors attributes such as bold and italics to text.

See [Wikipedia](http://en.wikipedia.org/wiki/ANSI_escape_code) for
more information.

Colors:

Both foreground and background colors can be rendered. Note that
faces with the same background as the default face is not rendered
with a background.

Four modes are supported:

* 8 -- The eight basic ANSI colors.

* 16 -- The eight basic colors, plus 8 "bright" colors. These are
  represented as "bold" versions of the above.

* 256 -- Some modern terminal programs support a larger palette.
  This consist of the 16 basic colors, a 6*6*6 color cube plus a
  grayscale.

* 24 bit -- A palette with 256*256*256 colors.

Attributes:

* Bold

* Italics

* Underline

Operating system notes:

macOS:

On older versions of macOS an old version of Emacs was installed.
This version was used when the `emacs' was specified on the command
line (or in the `LESSOPEN' macro).

You can download a modern version from [Emacs For
macOS](http://emacsformacos.com). Once installed, add it's path
(typically `/Applications/Emacs.app/Contents/MacOS/Emacs') to the
`PATH' environment variable.

Gallery:

All images are screen captures of `less' running in a terminal
window. White or black backgrounds were used, even though some
themes have other backgrounds, when used inside Emacs.

Default 8 colors:

| Light                        | Dark                        |
| ------                       | -----                       |
| ![](doc/default_light_8.png) | ![](doc/default_dark_8.png) |

Default 256 colors:

| Light                          | Dark                          |
| ------                         | -----                         |
| ![](doc/default_light_256.png) | ![](doc/default_dark_256.png) |

Grayscale 256 colors:

| Light                            | Dark                            |
| ------                           | -----                           |
| ![](doc/grayscale_light_256.png) | ![](doc/grayscale_dark_256.png) |

Selected themes:

The following themes are included in the Emacs distribution.

| Tango                | Tsdh light              |
| ------               | -----                   |
| ![](doc/tango.png)   | ![](doc/tsdh-light.png) |

| Adwaita              | Misterioso              |
| ------               | -----                   |
| ![](doc/adwaita.png) | ![](doc/misterioso.png) |

