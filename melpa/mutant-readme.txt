
This package provides an interface for dealing with the
[Mutant](https://github.com/mbj/mutant) testing tool, enabling
one to easily launch it from a `.rb` file or even from a `dired` buffer.
The generated output is nicely formatted and provides direct links
to the errors reported by the mutations. I've tried
to mimic the `rspec-mode` overall experience as much as possible.

; Installation:

This package can be installed via `MELPA`, or manually by downloading
`mutant.el` and adding it to your init file, as it follows:

```elisp
(add-to-list 'load-path "/path/to/mutant")
(require 'mutant)
```

For having `mutant-mode` enabled automatically, I suggest you
to do the following:

```elisp
(add-hook 'ruby-mode-hook 'mutant-mode)
```
