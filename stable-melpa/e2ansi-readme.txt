*e2ansi* (Emacs to ANSI) converts a text highlighted by Emacs to a
text with ANSI escape codes, which can be displayed in a terminal
window, with the highlighting visible.

The `e2ansi-cat' command line tool can be used to highlight text
directly in the terminal.  The actual syntax highlighting is
performed by Emacs running in batch mode.

Pager applications like `more' and `less' can be configured to
automatically invoke `e2ansi-cat', so that all viewed files will be
syntax highlighted.  A nice side effect is that other conversions
that Emacs normally performs, like uncompressing files, are also
automatically applied.

This package can highlight everything that Emacs supports,
inclduing many programming and markup languages.  Since Emacs is
extensible you can use third-party packages or implement support
for your own language formats.

Example:

| Before                     | After                         |
| ------                     | -----                         |
| ![](doc/no_color_dark.png) | ![](doc/default_dark_256.png) |

Quick install:

Install the `e2ansi' package using the Emacs package manager.  This
installs the main package, all dependencies, and a number of
command-line tools like `e2ansi-cat'.

Optionally create an e2ansi-specific init file,
e.g. `~/.e2ansi'. (See below.)

Integration with `less':

The pager applications `more' and `less' can be configured to use
`e2ansi-cat' to highlight viewed files.  This is done by defining
the `LESSOPEN' environment variable.

Make sure that the `emacs' command is in the path.

Semi-automatic setup:

Run the Emacs command `e2ansi-display-shell-setup' and copy
relevant lines to a suitable shell init file, like
`~/.bashrc'.  (The output assumes that a bash-compatible shell is
used.  The syntax might need to be adjusted for other shells.)

Manual setup:

Define the `LESSOPEN', `LESS', and `MORE' environment variables in
your shell init file.  For example (replacing `PATH-TO-E2ANSI' with
the location of the `e2ansi' module):

    export "LESSOPEN=||-PATH-TO-E2ANSI/bin/e2ansi-cat %s"
    export "LESS=-R"
    export "MORE=-R"

In the `LESSOPEN' environment variable `%s' is the placeholder for
the file to highlight and the `||-' prefix says that the script can
work in a pipe.

The `-R' option in the `LESS' and `MORE' environment variables
tells the tools to send ANSI sequences to the terminal.

The *e2ansi* init file:

When using Emacs in batch mode, Emacs does not read the user init
file.  However, for *e2ansi*, it is often desirable to load the
user init files, for example, to configure font-lock settings and
add additional packages.

When the command line tools `e2ansi-cat' and `e2ansi-info' are
launched, they try to load the init files `.e2ansi' and
`e2ansi-init.el' from the following locations:

* The user home directory.

* The `emacs' XDG config directory (typically `~/.config/emacs').

* The user Emacs directory (typically `~/.emacs.d').

This file can include configuration specific to *e2ansi*, or it can
load the normal user init files.  This is a good place to specify
display properties such as the background mode.

For example:

    ;;; .e2ansi --- Init file for e2ansi.  -*- emacs-lisp -*-
    (require 'e2ansi-silent)
    (require 'e2ansi-magic)
    (setq face-explorer-background-mode 'dark)
    (load "~/.emacs" nil t)
    ;;; .e2ansi ends here

Adapting init files to batch mode:

As Emacs most often is used in interactive mode there is a risk
that parts of the system or your init file doesn't work in batch
mode.

To exclude something when in batch mode, you can use:

    (unless noninteractive
      .. code not suitable for batch mode code goes here ... )

The *e2ansi* modules:

* `bin/e2ansi-cat' -- Command line tool to add highlighting a file
  using ANSI escape codes.

* `bin/e2ansi-info' -- Command line tool to display various
  ANSI-related information.

* `e2ansi.el' -- The rendering engine for ANSI escape codes.

* `e2ansi-magic.el' -- Set up `magic-mode-alist' to recognize file
  formats based on the content of files.  This is useful when using
  `less' in pipes where Emacs can't use the file name extension to
  select a suitable major mode.

* `e2ansi-silent.el' -- Load this in batch mode to silence some
  messages from init files.

* `e2ansi-load-init.el' -- Support module for the command line
  tools to load the *e2ansi* init file.

The `e2ansi-cat' command line tool:

Syntax:

    e2ansi-cat [OPTION ...] file ...

If the name of the file is `-', the input is read from standard
input, so that the tool can be used in pipes:

    diff alpha.txt beta.txt | e2ansi-cat -

Options:

* `--theme' -- Specify the Emacs color theme to use.

* `--usage' or `--help' -- Show help text.  (Note: Unless `--help'
  is preceded by `--', Emacs will display its own help text.)

Options for display properties:

* `--background-mode' -- Specify `light' or `dark' background mode.

* `--colors' -- Number of colors, or `rgb24' for full 24 bit
  colors.  This is both used when parsing the `min-colors'
  requirement in face definitions (c.f.  `defface') and when
  deciding the kind of ANSI escape codes that is used.

* `--color-class' -- Specify one of the `color', `grayscale' or
  `mono' face specification requirement (c.f.  `defface').

The `e2ansi-info' command line tool:

Syntax:

    e2ansi-info WHAT [OPTIONS]

OPTIONS are the same as accepted by `e2ansi-cat'.

Where WHAT can be:

* `settings' -- Print the terminal setting of e2ansi.

* `ansi16' -- Print a color table with the 16 basic colors.

* `ansi256' -- Print a color table with the 256 color palette.

* `faces' -- Print a selection of standard faces.

* `mbg' -- Print text with background spanning multiple lines.

Launching Emacs script:

In some cases it's not possible to launch Emacs command line tools
`e2ansi-cat' directly, for example when using MS-Windows.

Instead, `emacs' can be used in match mode, for example:

    emacs --batch -l PATH-TO-E2ANSI/bin/e2ansi-cat

Additional Emacs options, like `-Q' (suppress the site init file)
can be specified.

The *e2ansi* Emacs module:

Emacs commands:

* `e2ansi-write-file' -- Generate a file with ANSI escape codes.

* `e2ansi-view-buffer' -- Display the content of the buffer, with
  ANSI escape codes.  (Typically, this doesn't look good, but it is
  useful to see which ANSI escape codes are generated.)

Emacs functions and macros:

* `e2ansi-string-to-ansi' -- Convert a string with Emacs faces to a
  string with ANSI escape codes.

* `e2ansi-with-fictitious-display-as-terminal' -- Call block with
  the face-explorer fictitious display macting the terminal.

The `face-explorer' library:

In batch mode, Emacs natively doesn't provide face attributes.
Instead, *e2ansi* uses the `face-explorer' library to deduce the
properties of faces, based on the underlying face definitions.

The following variables controls the display environment that
`face-explorer' uses.  The variables can, for example, be set using
*e2ansi* command line options or in the *e2ansi* or the Emacs init
file.

Each variable corresponds to a display property in face
specifications (see `defface').

* `face-explorer-background-mode' -- `light' or `dark'.  This
  corresponds to the `background' display property.

* `face-explorer-number-of-colors' -- Number of colors, e.g. 8, 16,
  256, or t. Corresponds to the `min-color' display property.  This
  also is used to decide the kind of ANSI escape codes to use.

* `face-explorer-color-class' -- `color', `grayscale', or
  `mono'.  This corresponds to the `class' display property.

* `face-explorer-window-system-type' -- The window system
  used.  This can be a symbol, a list of symbols, or t to match any
  type.  Corresponds to the `type' display property.

Background:

What is Emacs?:

Emacs is a the mother of all text editors.  It originates from the
1970:s, but is still in active development.  It runs under all major
operating systems, including MS-Windows, macOS, and various
UNIX-like systems like Linux.  You can use normal windows, run it in
a terminal window (great when working remotely), or use it to run
scripts in batch mode, which is how it is used by the command line
tools provided by this package.

Emacs provides state-of-the-art syntax highlighting.

Why use Emacs to power syntax highlighting in the terminal?:

There are many advantages:

* Emacs has support for a vast range of programming languages and
  other structured text formats.  Many are provided by the basic
  Emacs distribution, others can be installed as separate packages.

* Emacs is fast and accurate -- it is designed for interactive use,
  and provides advanced support for parsing programming languages
  and other structured text.

* Emacs supports color themes.  If you don't like the ones provided,
  and can't find one on internet, you can easily write your own.

* Emacs is *extensible*.  You can add an Emacs *major mode* for any
  structured format, or you can add a *minor mode* that can be used
  together with existing major modes.  Syntax highlighting in Emacs
  is typically provided by *Font Lock rules*, which can range from
  using simple pattern matching to very complex code.

ANSI escape codes:

ANSI escape codes, formally known as ISO/IEC 6429, is a system used
by various physical terminals and console programs to, for example,
to add colors and attributes such as bold and italics to text.

See [Wikipedia](http://en.wikipedia.org/wiki/ANSI_escape_code) for
more information.

Colors:

Both foreground and background colors can be rendered.  Note that
faces with the same background as the default face is not rendered
with an explicit background color.

Four modes are supported:

* 8 -- The eight basic ANSI colors.

* 16 -- The eight basic colors, plus 8 "bright" colors.  These are
  represented as "bold" versions of the above.

* 256 -- Some modern terminal programs support a larger palette.
  This consist of the 16 basic colors, a 6*6*6 color cube plus a
  grayscale.

* 24 bit -- A palette with 256*256*256 colors.

Attributes:

* Bold

* Italics

* Underline

More about `less':

The pager application `less' is preinstalled on most systems.  If
it is missing or outdated on your system it's easy to download and
build a new version from http://www.greenwoodsoftware.com/less

The document [LessWindows](doc/LessWindows.md) describes how to
build `less' on Windows using `cmake', a modern build system.

Miscellaneous:

The Emacs package manager includes the version number in the
installation location of `e2ansi'.  This, unfortunately, means that
the shell configuration must be updated every time `e2ansi' is
updated.

Gallery:

All images are screen captures of `less' running in a terminal
window.  White or black backgrounds were used, even though some
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

