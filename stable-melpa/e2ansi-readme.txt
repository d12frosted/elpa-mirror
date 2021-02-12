*e2ansi* (Emacs to ANSI) provides syntax highlighting support for
`less' and for other tools that run in terminal windows.

The `e2ansi-cat' command line tool use ANSI escape sequences to
syntax highlight source files. The actual syntax highlighting is
performed by Emacs, the mother of all text editors, running in
batch mode.

Pager applications like `more' and `less' can be configured to
automatically invoke `e2ansi-cat', so that all viewed files will be
syntax highlighted. A nice side effect is that other conversions
that Emacs normally performs, like uncompressing files, are also
automatically applied.

Example:

| Before                     | After                         |
| ------                     | -----                         |
| ![](doc/no_color_dark.png) | ![](doc/default_dark_256.png) |

Syntax:

The `e2ansi-cat' command line tool is written in Emacs Lisp. To
start it, use:

    emacs --batch [...Emacs options...] -l bin/e2ansi-cat [...options...]

Alternatively, on UNIX-like operating systems the `e2ansi-cat' can
be executed directly, assuming that the `bin' directory is in the
load path. This assumes that Emacs is installed as `/usr/bin/emacs':

    e2ansi-cat [...options...]

Note, due to how Emacs parses options, some options passed to
`e2ansi-cat' is parsed by Emacs. Most notably, passing the option
`--help' to `e2ansi-cat' displays help for Emacs itself.

Command line options:

* `--background-mode' -- Specify `light' or `dark' background mode.

* `--colors' -- Number of colors, or `rgb24' for full 24 bit
  colors. This is both used when mapping faces to actual colors and
  to decide the kind of ANSI sequences that is used.

* `--color-class' -- Specify `color', `grayscale' or `mono'.

* `--theme' -- Specify the color theme to use.

* `--usage' -- Show help text.

Integration with `less':

The standard command line tool `less' can be configured to
preprocess any output given to it. `e2ansi-cat' can be used to
generate a syntax highlighted version. This is enabled by setting
the following environment variables, for example, to (using bash
syntax):

    export "LESSOPEN=|emacs --batch -l ~/.emacs -l bin/e2ansi-cat %s"
    export "LESS=-R"
    export "MORE=-R"

The `LESSOPEN' environment variable is used by `less' to specify an
input preprocessor. When using `e2ansi', the first character should
be a `|', this signals to less that the input preprocessor prints
the result on standard output.

The above example assumes that your init file is named `.emacs' and
located in your home directory. It also assumes that it adds the
location of the `e2ansi' package to the load path.

`less' and pipes:

Modern versions of `less' can also use the input preprocessor when
used in a pipe, for example:

    svn diff | less

For this, the `LESSOPEN' environment variable must start with `|-'.
In this case, the file name `-' is passed to the input
preprocessor, which is expected to read from standard input.

    export "LESSOPEN=|-emacs --batch -l ~/.emacs -l bin/e2ansi-cat %s"

Note: If your version of `less' is too old, using `|-' typically
yields error like "/bin/bash: -/: invalid option".

Also note that this makes it hard for Emacs to select a suitable
major mode, as it can not base this on the file name extension.
Typically, this result in incorrect or no highlighting.
Fortunately, Emacs has the ability inspect the file content when
selecting major mode, see `magic-mode-alist' for details. The
support file `e2ansi-magic.el' adds some file types to the list,
e.g. the `diff' format used by `svn'. You must explicitly load it
to take effect, either using `-l e2ansi-magic.el' or by loading in
from another file that is being loaded, like your init file.

Emacs init files:

When using Emacs in batch mode, Emacs reads the system init file
but not the user init file.

If you want to load your personal init file, you can load it using
-l command line option, for example:

    emacs -l ~/.emacs -l bin/e2ansi-cat file ...

To avoid loading the system init file, you can specify the -Q
command line option:

    emacs -Q -l ~/.emacs -l bin/e2ansi-cat file ...

Adapting your init file to batch mode:

As Emacs most often is used in interactive mode there is a risk
that parts of the system or your init file doesn't work in batch
mode.

To exclude something when in batch mode, you can use:

    (unless noninteractive
      .. original code goes here ... )

Silencing messages:

When Emacs is used in batch mode, message are emitted on the
standard error stream. This includes messages emitted when files
are loaded.

On UNIX-like operating systems, the standard error stream can be
redirected to /dev/null, for example:

    emacs --batch -l ~/.emacs -l bin/e2ansi-cat 2> /dev/null

Alternatively, the file `e2ansi-silent' can be loaded. This file
has the advantages that the Usage information of `e2ansi-cat' is
printed (when started without arguments) and that it works on all
operating systems. (If you load it before your init file, you might
need to specify the full path.)

    emacs --batch -l e2ansi-silent -l ~/.emacs -l bin/e2ansi-cat ...

Silencing messages in `site-start.el':

Normally, the file `site-start.el' is loaded by Emacs before any
file specified on the command line. To silence messages emitted by
this file, you can suppress loading it using -Q, load
`e2ansi-silent' and explicitly load the site-start file:

    emacs --batch -Q -l e2ansi-silent -l ../site-lisp/site-start -l ...

Note: When -Q is used, the `site-lisp' directory is not included in
the load path, the `../site-lisp' part compensate for this.

Emacs modules:

* `e2ansi.el' -- Render a syntax highlighted buffer using ANSI
  escape sequences. This can be used both in normal interactive
  mode and in batch mode.

* `e2ansi-magic.el' -- Set up `magic-mode-alist' to recognize file
  formats based on the content of files. This is useful when using
  `less' in pipes where Emacs can't use the file name extension to
  select a suitable major mode.

* `e2ansi-silent.el' -- Load this in batch mode to silence some
  messages from init files.

* `bin/e2ansi-cat' -- The command line tool for converting files in
  batch mode.

* `bin/e2ansi-info' -- Print various ANSI-related information to
  help you trim your ANSI environment.

Background:

What is Emacs:

Emacs is a the mother of all text editors. It originates from the
1970:s, but is still in active development. It runs under all major
operating systems, including MS-Windows, Mac OS X, and various
UNIX-like systems like Linux. You can use normal windows, run it in
a terminal window (great when working remotely), or use it to run
scripts in batch mode, which is how it is used by the command line
tools provided by this package.

Emacs provides state-of-the-art syntax highlighting.

Why use Emacs to power syntax highlighting in the terminal:

* Emacs has support for a vast range of programming languages and
  other structured text formats.

* Emacs is fast and accurate -- it is designed for interactive use,
  and provides advanced support for ensuring that a source buffer
  is parsed correctly.

* Emacs supports color themes. If you don't like the ones provided,
  and can't find one on internet, you can easily write your own.

* To add syntax highlighting support for other formats can easily be
  done by providing a standard Emacs major mode, where the syntax
  highlighting is provided by Font Lock keywords. You can use
  `font-lock-studio' to debug those keywords, it allows you single
  step match by match and it visualizes matches using a palette of
  background colors.

ANSI sequences:

ANSI sequences, formally known as ISO/IEC 6429, is a system used by
various physical terminals and console programs to, for example,
render colors and text attributes such as bold and italics.

See [Wikipedia](http://en.wikipedia.org/wiki/ANSI_escape_code) for
more information.

Colors:

Both foreground and background colors can be rendered. Note that
faces with the same background as the default face is not rendered
with a background.

Four modes are supported:

* 8 -- The eight basic ANSI colors are supported.

* 16 -- The eight basic colors, plus 8 "bright" colors. These are
  represented as "bold" versions of the above.

* 256 -- Some modern terminal programs support a larger palette.
  This consist of the 16 basic colors, a 6*6*6 color cube plus a
  grayscale.

* 24 bit -- Support for 256*256*256 colors.

Attributes:

* Bold

* Italics

* Underline

Operating system notes:

Mac OS X:

Mas OS X comes bundled with Emacs. Unfortunately, it's a relatively
old version, 22.1.1. It is fully functional, but it lacks some
features. Most notably, the default face definitions are broken
when 8 colors are used.

You can download a modern version from
[EmacsForOSX](http://emacsforosx.com). Once installed, the path to
the Emacs binary is typically
`/Applications/Emacs.app/Contents/MacOS/Emacs'.

The version of `less' that is preinstalled on 10.9 is 418 dating
from 2007. It supports the input preprocessors for named files (the
`|' syntax) but not for pipes (The `|-' syntax).

Fortunately, it's easy to download and build a new version of
`less' from http://www.greenwoodsoftware.com/less

Why Apple has not included a newer version, I do not understand.
Some claim that Apple is actively avoiding software licensed under
GPLv3+. However, `less' is available under two licenses so this
should not be a problem. I guess it's down to laziness and opting
to spend resources to invent yet another way of making menus
semi-opaque rather than providing their users with up to date
tools.

Microsoft Windows:

The command window in Microsoft Windows does not understand ANSI
sequences. Fortunately, modern versions of `less' is capable of
rendering ANSI sequences using colors.

Unfortunately, I'm not aware of any up to date distribution of
prebuilt versions of `less'. To make things worse, the build
scripts provided with `less' is somewhat hard to use.

In the document
[LessWindows](https://github.com/Lindydancer/e2ansi/doc/LessWindows.md)
I describe how to build `less' using `cmake', a modern build
system.

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



Future development:

This sections consists of things that might or might not appear in
this package in the future.

More command line tools:

More command line tools could make life simpler. For example:

* `e2ansi-exec' -- Run another command line tools and convert all
  arguments (that looks like files) to the corresponding ansi
  format. (To avoid converting files that should not be converted,
  this tool must include knowledge regarding common commands.) One
  problem with this tool is the bizarre way Emacs treats command
  line options -- hence, the entire tool, or parts of it, must be
  written in another script language like Ruby.q

* `e2ansi-tmp' -- Render a syntax highlighted version of a file as
  a temporary file and print the file name. This way a user could
  use the shell backquote syntax to feed syntax highlighted
  versions of a file to a third tool, for example:

        atool `e2ansi-tmp afile.c`

  A technical problem with this tool is that it leaves the
  temporary file behind. Hence, some kind of garbage collection
  mechanism must be put in place.

Generalization:

Much of the code in this package is generic. It could most likely
be used to generate other output formats like Markdown. One idea is
to break out the generic parts to a separate package.

Faster response time:

* By using a resident Emacs process, response time could be greatly
  reduced. Today, a bare-bone Emacs start fast, however, if you use
  a heavy init file (like I do) the start-up time goes up
  noticeably.

* Incremental syntax highlighting. Today, the entire buffer is
  syntax highlighted at once, before it is converted to ANSI. By
  only run font-lock on parts of the buffer before printing it, a
  receiving application like `less' could start faster.

Miscellaneous:

Various things.

* Check how things look when using a dark background, maybe
  something would need to be added to the overrides list.

* Don't use the "brightxxx" color names, they are not used by Emacs
  and it's only confusing.

* Add unit tests for individual parts and full source file tests
  where the entire output is compared against a known ANSI
  representation, as done in my `faceup' package.

* Describe Emacs font specification selection process.

* Better error handling when parsing command line arguments.

* Customization support.

* Optimize ANSI sequences. Today, whenever there is a change, a
  reset is emitted, plus codes to set all properties. However,
  sometimes it would be shorter to simple, say, add underline, and
  without touching the other properties.

* Security issues: Don't allow file local variables, or anything
  else, allow arbitrary elisp code to be executed when a file is
  viewed.

* Use floating point numbers when scoring, rather than scaling
  down.

* Promote some of the "list" commands from the "test" package.

* Inhibit rendering ANSI sequences when running `less' on a file
  already containing ANSI sequences.

* Add `--force' to force e2ansi to render a file using ANSI
  sequences, even when such sequences are found in the file.

* Mention `||-' in the documentation.

* Investigate why backgrounds spanning mutiple lines misbehaves in
  Terminal.app (and other terminals). Maybe always reset the
  background at the end of each line?

Acknowledgment:

Mark, thanks for writing `less'!
