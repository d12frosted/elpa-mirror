Table of Contents
─────────────────

1 org-commentary
.. 1.1 Why?
.. 1.2 Installation
..... 1.2.1 MELPA
.. 1.3 Getting started
.. 1.4 Command line interface
..... 1.4.1 Not using Cask?
.. 1.5 API
.. 1.6 Customization
..... 1.6.1 Inclusion of the table of contents (TOC)
..... 1.6.2 Inclusion of subtrees
..... 1.6.3 Inclusion of drawers
..... 1.6.4 Inclusion of tags
..... 1.6.5 Export charset
.. 1.7 Similar projects


1 org-commentary
════════════════

  `org-commentary' — generate or update conventional [library headers]
  using Org mode files.


  [library headers]
  https://www.gnu.org/software/emacs/manual/html_node/elisp/Library-Headers.html


1.1 Why?
────────

  If you have a README file with the description of your Emacs Lisp
  package (which you definetely should have), you may as well want to
  use that file as the canonical source of the documentation for the
  package. However, there is another place which needs this
  documentation: the commentary section of your main library file; you
  can update it manually, but it's tedious and error prone (not to
  mention it's a violation of the [DRY] principle).

  Org mode has built-in export facilities which can be used to convert
  Org documents into various formats, including a simple plain text
  format (`ascii' backend).

  This package employs these facilities to generate library headers from
  Org files automatically; it may be used either from inside of Emacs or
  from the command line.


  [DRY] https://en.wikipedia.org/wiki/Don't_repeat_yourself


1.2 Installation
────────────────

  You can skip this section if you're going to use `org-commentary' as a
  development dependency of a [Cask]-managed project.


  [Cask] https://github.com/cask/cask


1.2.1 MELPA
╌╌╌╌╌╌╌╌╌╌╌

  `org-commentary' is available on both MELPA and MELPA Stable. Enable
  the corresponding repository by adding an entry to `package-archives':

  ┌────
  │ (require 'package)
  │ ;; you can enable MELPA Stable instead:
  │ ;; (add-to-list 'package-archives
  │ ;;              '("melpa-stable" . "https://stable.melpa.org/packages/"))
  │ (add-to-list 'package-archives
  │ 	     '("melpa" . "https://melpa.org/packages/"))
  │ (package-initialize)
  └────

  See the [documentation] on more details about setting up MELPA
  repositories.

  To install `org-commentary' use Emacs' package menu at `M-x
  list-packages' or run `M-x package-install RET org-commentary RET'.


  [documentation] https://melpa.org/#/getting-started


1.3 Getting started
───────────────────

  /Note/: these steps are written with assumption you're using Cask for
  project management; otherwise, see [Not using Cask?] section below for
  instructions on how to use `org-commentary' CLI without Cask.

  1. [Optional] If you have installed `org-commentary' manually, create
     a link to `org-commentary':

     ┌────
     │ $ cask link org-commentary path/to/org-commentary/installation
     └────

  2. Add `org-commentary' to the development dependencies of your
     library:

     ┌────
     │ (development
     │  (depends-on "org-commentary"))
     └────

     Fetch dependencies:

     ┌────
     │ $ cask install
     └────

  3. Put the [library header] boilerplate in your ELisp file.

  4. Generate /Commentary/ section of the library headers:

     ┌────
     │ $ cask exec org-commentary README.org your-package.el
     └────

  5. [Optional] Generate /Change Log/ section of the library headers:

     ┌────
     │ $ cask exec org-commentary --section changelog CHANGELOG.org your-package.el
     └────

  6. Commit.


  [Not using Cask?] See section 1.4.1

  [library header]
  https://www.gnu.org/software/emacs/manual/html_node/elisp/Library-Headers.html


1.4 Command line interface
──────────────────────────

  `org-commentary' provides an executable script which can be invoked
  like this:

  ┌────
  │ $ cask exec org-commentary [OPTION]... ORG-FILE ELISP-FILE
  └────

  Run `cask exec org-commentary --help' to see available options.


1.4.1 Not using Cask?
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Provided `org-commentary' is installed via the built-in package
  manager, you can invoke it from the shell like this:

  ┌────
  │ $ emacs -Q --batch --eval '(package-initialize)' -l org-commentary-cli -f \
  │     org-commentary -- [OPTION]... ORG-FILE ELISP-FILE
  └────

  For example, to see available options, run

  ┌────
  │ $ emacs -Q --batch --eval '(package-initialize)' -l org-commentary-cli -f org-commentary -- --help
  └────


1.5 API
───────

  Use `M-x describe-function <NAME>' for details.

  • *command* `org-commentary-update'

    Update library headers using the content of an Org document.

  • *function* `org-commentary-export-buffer-as-string'.

    Export the Org document opened in the current buffer as a string.

  • *function* `org-commentary-export-file-as-string'.

    Export an Org document as a string.


1.6 Customization
─────────────────

  The user can set a number of options which affect the exporting
  process.

  Each option can be set in several ways:

  • *in-file keyword*

    A line which starts with a `#+' followed by a keyword, a colon and
    then individual words defining a setting. Example:

    ┌────
    │ #+TITLE: the title of the document
    └────

  • *in-file option*

    An option in compact form using the `#+OPTIONS' keyword:

    ┌────
    │ #+OPTIONS: opt1 opt2 opt3 ... optN
    └────

    `opt' consists of a short key followed by a value. For example,
    option `toc:' toggles inclusion of the table of contents; the
    following setting excludes the table of contens from export:

    ┌────
    │ #+OPTIONS: toc:nil
    └────

    Accepted values vary from option to option.

    To specify a rather long list if such options, one can use several
    `#+OPTIONS' lines.

  • *property*

    An option specified via the optional property list `EXT-PLIST'
    passed as the last argument of the public functions (see the *API*
    section). For example, to enable export using UTF-8 characters, pass
    `(list :ascii-charset 'utf-8)' as the last argument of an export
    function.

  • *variable*

    A global variable.

  This package also enables setting the options via command line
  arguments, which are mapped to the corresponding *properties*.

  In-file settings take precedence over keyword properties, which in
  turn override global variables.

  This section gives a brief description of common options; for more
  details, see the dedicated sections ([Export settings], [Publishing
  options]) of the Org mode manual.


  [Export settings] http://orgmode.org/manual/Export-settings.html

  [Publishing options] http://orgmode.org/manual/Publishing-options.html


1.6.1 Inclusion of the table of contents (TOC)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The table of content is normally inserted before the first headline of
  the file.

  • *in-file option* `toc:'

    If this options is a number, use this number as the depth of the
    generated TOC.  Setting this option to `nil' disables default TOC.

    Synonyms:

    ⁃ *property* `:toc'
    ⁃ *variable* `org-commentary-with-toc'

  • *in-file keyword* `#+TOC'

    Insert TOC at the current position.

  See [Table of contents] for more details.


  [Table of contents] http://orgmode.org/manual/Table-of-contents.html


1.6.2 Inclusion of subtrees
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • *in-file keyword* `#+EXCLUDE_TAGS'

    The tags that exclude a tree from export (the default value is
    `:noexport:').

    Alternatives:

    ⁃ *in-file option* `exclude-tags:'
    ⁃ *property* `:exclude-tags'
    ⁃ *variable* `org-export-exclude-tags'

  • *in-file keyword* `#+INCLUDE_TAGS'

    The tags that select a tree for export (the default value is
    `:export:'). This setting takes precedence over `#+EXCLUDE_TAGS'.

    Alternatives:

    ⁃ *in-file option* `select-tags:'
    ⁃ *property* `:select-tags'
    ⁃ *variable* `org-export-select-tags'


1.6.3 Inclusion of drawers
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  /Note/: you need to specify custom drawers using the `#+DRAWERS'
  keyword for Org mode versions prior to 8.3.

  • *in-file optons* `d:'

    A list of drawers to include. If the first element is the atom
    `not', specify drawers to exclude instead.

    Alternatives:

    ⁃ *property* `:with-drawers'
    ⁃ *variable* `org-export-with-drawers'


1.6.4 Inclusion of tags
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • *in-file option* `tags:'

    Toggles inclusion of tags.

    Alternatives:

    ⁃ *property* `:with-tags'
    ⁃ *variable* `org-export-with-tags'


1.6.5 Export charset
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • *property* `:ascii-charset'

    The charset allowed to represent various elements and objects during
    export (the default value is `ascii').

    Alternatives:

    ⁃ *variable* `org-ascii-charset',
    ⁃ *command-line argument* `--charset' (`-c')


1.7 Similar projects
────────────────────

  • [org2elcomment] - provides an interactive function to update the
    commentary section of an Emacs Lisp file using the contents of an
    Org file opened in the current buffer.
  • [make-readme-markdown] - in contrast to `org-commentary', this
    package treats an Emacs Lisp file as the canonical source of
    documentation. That file is used to generate `README' in the
    Markdown format. The package provides additional features like
    auto-detected badges and API documentation of public functions.


  [org2elcomment] https://github.com/cute-jumper/org2elcomment

  [make-readme-markdown] https://github.com/mgalgs/make-readme-markdown
