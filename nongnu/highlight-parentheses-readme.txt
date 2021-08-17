# highlight-parentheses.el: Highlights parentheses surrounding point in Emacs

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

## Screenshot

See how parens are fontified reddish if they contain point.

![A screenshot showing highlight-parentheses.el in action](screenshot.png)

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
