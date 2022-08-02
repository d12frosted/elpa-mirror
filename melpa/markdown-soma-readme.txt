# Markdown Soma

### Live Markdown in Emacs

`markdown-soma` is an Emacs minor-mode which gives you live rendering of
Markdown to HTML.

Based on the Vim plugin [`vim-markdown-composer`][vmc],

## Usage

To start:

```
M-x markdown-soma-mode
```

The default browser will open a tab with the rendered markdown view.

Edits and commands in your current Emacs buffer, will trigger a new markdown
render in the browser. The browser view will automatically scroll so you can see
what you're editing. _(This could be better, suggestions on how to
improve it are welcome.)_

## Render hooks

A new markdown render triggers by hooks in  `markdown-soma--render-buffer-hooks`.

```lisp
;; default render buffer hooks

(setq markdown-soma--render-buffer-hooks
  '(after-revert-hook
    after-save-hook
    after-change-functions
    post-command-hook))
```

## Install

Via [MELPA](https://melpa.org)

```
M-x package-install markdown-soma
```

Using [Doom Emacs](https://github.com/doomemacs/doomemacs)

in `~/.doom.d/packages.el`

```lisp
(package! markdown-soma)
```

### Install `soma` executable

The source for the `soma` markdown/websocket server is included the package
repository. You'll need to compile it from source. If you don't have Rust on
your system, use [rustup] to get set up.

Once rust is ready, open a terminal at the package folder.

```shell
$ cargo install --path .

# compiles:
# ⟶ ~/.cargo/bin/soma
```

By default, `~/.cargo/bin` will be in your `$PATH`.

## Customizing

You can select a builtin CSS theme with::

```
M-x markdown-soma-select-builtin-css
```

To persist the setting, select a theme name and add it to your Emacs init with:

```lisp
(setq markdown-soma-custom-css
   (markdown-soma--css-pathname-from-builtin-name "theme name")
```

You can also use any other markdown aware CSS stylesheet (i.e. targets CSS
selectors `#markdown-preview` and/or `.markdown-preview` as markdown content
containers..)

Set a custom CSS file to use with:

```
M-x markdown-soma-select-css-file
```

Note: the CSS style will apply after restarting `markdown-soma-mode`.

```
M-x markdown-soma-restart
```

To persist the setting add to your Emacs init

```lisp
(setq markdown-soma-custom-css "/path/to/your.css")
```

You can select a [highlightjs] theme:

```
M-x markdown-soma-select-highlight-theme
```

To persist the setting add to your Emacs init

```lisp
;; Change "theme name" to the selected highlightjs theme.
(setq markdown-soma-highlightjs-theme "theme name")
```

## Markdown support

Soma converts markdown to HTML, using [pulldown-cmark].
It is 100% compliant with the common-markdown spec.

### Extensions

- Github flavored markdown (gfm) tables
- GFM code fences
- GFM task lists
- Strike-through

---

TeX/MathJax support thanks to [KaTeX][katex]

e.g. `\\sqrt{3x-1}` wrapped in `$` ⟶ `$\\sqrt{3x-1}$` to    display the expression ⟶  $\\sqrt{3x-1}$

wrapping with `\\(\\)` e.g. `\\(\\sqrt{3x-1}\\)` gives the same \\(\\sqrt{3x-1}\\) inline.

Use `$$...$$` or `\\[..\\]`to center the expression in a presentation style.

e.g. `$$\\sqrt{3x-1}$$`

$$\\sqrt{3x-1}$$

`$$n = {A \pm \sqrt{b^4-4ac} \over 2a}$$`

$$n = {A \pm \sqrt{b^4-4ac} \over 2a}$$

`$$\xleftrightharpoons{abc}$$`

$$\xleftrightharpoons{abc}$$

---

## Technical note.

Emacs sends text from the current buffer to `soma`
using `(process-send-string BUFFER-TEXT PROCESS)`.

`soma` converts input (assumed to be markdown text) and broadcasts
changes to connected clients (as HTML).

Emacs embeds a value for `scrollTo`, into the input with a
magic comment e.g.

```html
<!-- SOMA: {"scrollTo": 0} // scrolls to the top.  -->
```

In a nutshell [`pulldown-cmark`][pulldown-cmark] is doing the heavy lifting.
Providing the core markdown service, via [`aurelius`][jason-aurelius]. Which in
turn provides the web/websocket interface. The `soma` executable is essentially
just wrapping [`aurelius`][jason-aurelius] as a repeating `stdin` reader, i.e.
instead of terminating at EOF it will use this as a signal to broadcast the updated content to clients.

[highlightjs]: https://highlightjs.org
[rustup]: https://rustup.rs
[pulldown-cmark]: https://github.com/raphlinus/pulldown-cmark
[katex]: https://katex.org
[aurelius]: https://github.com/euclio/aurelius
[jason-aurelius]: https://github.com/jasonm23/aurelius
[vmc]: https://github.com/euclio/vim-markdown-composer
