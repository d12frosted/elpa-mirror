
Provides `global-keycoach-mode' to help you remember and learn new
keybindings!

Features:

keycoach is a simple, unopinionated package with two main features:

- A configurable display to remind you about keybindings you want to learn.
  Keys are removed from the display (called the *indicator*) when they're
  typed.

- Error messages if you fail to use one of your keys to invoke a command
  (i.e. `M-x`).

For example, you can try to use all your keys every day, and set
`midnight-mode` to reset them for the next day.  See below!

Get started:

For a totally basic setup, this turns on `global-keycoach-mode` and sticks
some keys in your frame title:

```el
(use-package keycoach
  :load-path "~/.emacs.d/packages/keycoach" ; Coming to MELPA soon I hope

  :config

  (setq keycoach-keys '("s-w" "M-F" "C-M-y")
        keycoach-indicator-target 'frame-title)

  ;; Ready to turn on keycoach!
  (global-keycoach-mode)
  )
```

`keycoach-indicator-target' can be `frame-title', `mode-line',
`header-line', or nil.  Nil is the default: keycoach then displays nothing
on its own, and you place `keycoach-indicator-string' wherever you want it.

Related packages:

- `which-key-mode': a built-in mode that helps you discover keys.  It shows
available keys once you start a key sequence.  Answers "what can I press
here?", while keycoach enforces "press what you promised to learn."
- See the README for more.
