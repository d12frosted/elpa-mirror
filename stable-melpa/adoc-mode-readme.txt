
# Introduction

[AsciiDoc](http://www.methods.co.nz/asciidoc/) is a text document format for
writing short documents, articles, books and UNIX man pages. AsciiDoc files
can be translated to HTML and DocBook markups.

adoc-mode is an Emacs major mode for editing AsciiDoc files. It emphasizes on
the idea that the document is highlighted so it pretty much looks like the
final output. What must be bold is bold, what must be italic is italic etc.
Meta characters are naturally still visible, but in a faint way, so they can
be easily ignored.


# Download

The raw file (adoc-mode.el) can be found
[here](https://raw.github.com/sensorflo/adoc-mode/master/adoc-mode.el).
Optionally you can get the sources from the [git
repository](https://github.com/sensorflo/adoc-mode).

You will also need to download the library
[markup-faces](https://github.com/sensorflo/markup-faces). If you install
adoc-mode via Emacs Lisp Packages, see below, markup-faces is installed
automatically if you don't have it yet.


# Installation

Installation is as usual, so if you are proficient with Emacs you don't need
to read this.

## Install the traditional way

1. Copy the file adoc-mode.el to a directory in your load-path, e.g.
   \~/.emacs.d. To add a specific directory to the load path, add this to our
   initialization file (probably ~/.emacs): `(add-to-list 'load-path
   "mypath")`

2. Add either of the two following lines to your initialization file. The
   first only loads adoc mode when necessary, the 2nd always during startup
   of Emacs.

   * `(autoload 'adoc-mode "adoc-mode" nil t)`

   * `(require 'adoc-mode)`

3. Optionally byte compile adoc-mode.el for faster startup: `M-x
   byte-compile`

4. To use adoc mode, call adoc-mode after you opened an AsciiDoc file: `M-x
   adoc-mode`


## Install via Emacs Lisp Packages (on Marmalade)

For this way you either need packages.el from
[here](https://github.com/technomancy/package.el) and or Emacs 24, where the
packages library is already included. adoc-mode is on the
[Marmalade](http://marmalade-repo.org/) package archive.

* Type `M-x package-install RET adoc-mode RET`.


## Possible steps after installation

Each of the following is optional

* According to AsciiDoc manual, .txt is the standard file extension of
  AsciiDoc files. Add the following to your initialization file to open all
  .txt files with adoc-mode as major mode automatically: `(add-to-list
  'auto-mode-alist (cons "\\.txt\\'" 'adoc-mode))`

* If your default face is a fixed pitch (monospace) face, but in AsciiDoc
  files you liked to have normal text with a variable pitch face,
  buffer-face-mode is for you: `(add-hook 'adoc-mode-hook (lambda()
  (buffer-face-mode t)))`


# Features

- sophisticated highlighting

- promote / demote title

- toggle title type between one line title and two line title

- adjust underline length of a two line title to match title text's length

- goto anchor defining a given id, default reading from xref at point

- support for outline (however only with the one-line title style)


## Coming features

The next features I plan to implement

- Demote / promote for list items
- Outline support also for two line titles
- Correctly highlighting backslash escapes


# Screenshot

The highlighting emphasizes on how the output will look like. _All_
characters are visible, however meta characters are displayed in a faint way.

![screenshot](http://dl.dropbox.com/u/75789984/adoc-mode.png)

