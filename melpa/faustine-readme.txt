Faustine allows the edition of Faust (http://faust.grame.fr) code.

## Features

- Faust code syntax hightlighting and indentation
- Project-based (inter-linked Faust files)
- Build/compile with output window
- Graphic diagrams generation and vizualisation in the (default) browser
- Browse generated C++ code inside Emacs
- Inter-linked files/buffers :
    - From "component" to Faust file
    - From "include" to Faust library file
- From error to file:line number
- From function name to online documentation
- Fully configurable (build type/target/architecture/toolkit, keyboard shortcuts, etc.)
- Automatic keyword completion (if [Auto-Complete](https://github.com/auto-complete/auto-complete) is installed)
- Automatic objets (functions, operators, etc.) template insertion with default sensible values (if [Yasnippet](https://github.com/joaotavora/yasnippet) is installed)
- Modeline indicator of the state of the code

## Installation

### Easy

- Install it from [MELPA](https://melpa.org).

### Hard

- Copy/clone this repository in `load-path`
- Copy/clone [Faust-mode](https://github.com/magnetophon/emacs-faust-mode) in `load-path`
- Add
```elisp
(require 'faust-mode)
(require 'faustine)
```
to your init file

### Faust
Oh, and of course install [the latest Faust](http://faust.grame.fr/download/) and ensure it's in the PATH.

### Recommended packages

Those package are not required, but Faustine makes good use of them, and they will make your life better anyway ; They are all available in MELPA, snapshot and stable.

- [Projectile](https://github.com/bbatsov/projectile)
- [AutoComplete](https://github.com/auto-complete/auto-complete)
- [Yasnippet](https://github.com/joaotavora/yasnippet)

## Usage

### Enter the mode

Use `faustine-mode` ; Optionally, add something like this to your init file:
```elisp
(add-to-list 'auto-mode-alist
             '("\\.dsp\\'" . faustine-mode))
```
to put any new Faust file in the mode.

### Commands
Every interactive command is documented in [the README](https://bitbucket.org/yphil/faustine/src/master/README.md) file.
