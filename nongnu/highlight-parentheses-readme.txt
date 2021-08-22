# highlight-parentheses: Highlights parentheses surrounding point in Emacs

`highlight-parentheses.el` dynamically highlights the parentheses surrounding
point based on nesting-level using configurable lists of colors, background
colors, and other properties.

## Screenshot

See how parens are fontified in different shades of red based on nesting level
if they contain point.

![A screenshot showing highlight-parentheses.el in action](screenshot.png)

## Usage

Add the following to your `.emacs` file:

```elisp
(require 'highlight-parentheses)
```

Enable the mode using `M-x highlight-parentheses-mode` or by adding it to a hook
like so:

```elisp
(add-hook 'prog-mode-hook #'highlight-parentheses-mode)
```

There is also the global minor mode `global-highlight-parentheses-mode` which
enables the mode in every buffer.

Furthermore, you can enable it also in the minibuffer using the following
snippet:

```elisp
(add-hook 'minibuffer-setup-hook #'highlight-parentheses-minibuffer-setup)
```

## Installation

The package is available from both [NonGNU ELPA](https://elpa.nongnu.org/), and
[MELPA](https://melpa.org/).  With Emacs 28 (not yet released), NonGNU ELPA is
enabled by default, so you can just do `M-x package-install RET
highlight-parentheses RET`.

If you are using `use-package`, you can use the following recipe:

```elisp
(use-package highlight-parentheses
  :ensure t)
```

## Questions & Patches

For asking questions, sending feedback, or patches, refer to [my public inbox
(mailinglist)](https://lists.sr.ht/~tsdh/public-inbox).  Please mention the
project you are referring to in the subject.

## Bugs

Bugs and requests can be reported
[here](https://todo.sr.ht/~tsdh/highlight-parentheses.el).

## License

highlight-parentheses.el is licensed under the
[GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) (or later).
