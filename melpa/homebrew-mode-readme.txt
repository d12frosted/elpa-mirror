# homebrew-mode

Emacs minor mode for editing [Homebrew](http://brew.sh) formulae.

## setup

```elisp
(add-to-list 'load-path "/where/is/homebrew-mode")
(require 'homebrew-mode)
(global-homebrew-mode)
```

## keys and commands

The command prefix is <kbd>C-c C-h</kbd>.  These are the commands currently mapped to it:

- <kbd>C-c C-h f</kbd>: Download the source file(s) for the formula
  in the current buffer.

- <kbd>C-c C-h u</kbd>: Download and unpack the source file(s) for the formula
  in the current buffer.

- <kbd>C-c C-h i</kbd>: Install the formula in the current buffer.

- <kbd>C-c C-h r</kbd>: Uninstall the formula in the current buffer.

- <kbd>C-c C-h t</kbd>: Run the test for the formula in the current buffer.

- <kbd>C-c C-h a</kbd>: Audit the formula in the current buffer.

- <kbd>C-c C-h s</kbd>: Open a new buffer running the Homebrew
  Interactive Shell (`brew irb`).

- <kbd>C-c C-h c</kbd>: Open a dired buffer in the Homebrew cache
  (default `/Library/Caches/Homebrew`).

- <kbd>C-c C-h d</kbd>: Add `depends_on` lines for the specified
  formulae.  Call with one prefix (<kbd>C-u</kbd>) argument to make
  them build-time dependencies; call with two (<kbd>C-u C-u</kbd>) for
  run-time.

- <kbd>C-c C-h p</kbd>: Insert Python `resource` blocks (requires poet,
  installed with `pip install homebrew-pypi-poet`).

## custom variables

These are just the most important variables; run `M-x customize-group
RET homebrew-mode` to see the rest.

- If you’re using Linuxbrew or a non-standard prefix on Mac OS, you’ll
  need to update `homebrew-prefix` to point at your `brew –-prefix`.

- If you’re using Linuxbrew or have your cache in a non-standard
  location on Mac OS, update `homebrew-cache-dir`.

- If you want to turn on whitespace-mode when editing formulae that
  have inline patches, set `homebrew-patch-whitespace-mode` to
  `t`. It’s off by default since it looks ugly.
