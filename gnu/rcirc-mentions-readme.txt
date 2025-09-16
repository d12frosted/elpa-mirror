# rcirc-mentions: Collect mentions of your nick or keywords in a separate mentions buffer

The builtin `rcirc-track-minor-mode` provides a way to be informed when your
nick was mentioned in some channel and provides key bindings to quickly jump to
that channel.  But what if you cannot interact immediately?  That's where the
rcirc mentions buffer comes into play.

When you activate `rcirc-mentions-log-mode` in channel buffers (or
`rcirc-mentions-global-log-mode`), all mentions of your nick or a keyword in
`rcirc-keywords` will be collected in a buffer named `*rcirc mentions*`
(customizable by `rcirc-mentions-buffer-name`).  Those log entries have a
timestamp, the text of the message containing the mention, and most
importantly, they contain a clickable link to the location of the original
mention in some channel buffer.  That way, you have a logbook of the most
important events in one central place.

You can quickly switch to the mentions buffer from rcirc buffers where
`rcirc-mentions-log-mode` is active using
`rcirc-mentions-switch-to-mentions-buffer`.  The default binding is `C-c C-.`,
the keymap is `rcirc-mentions-log-mode-map`.

The mentions buffer uses a separate major mode, `rcirc-mentions-buffer-mode`,
which provides some navigation commands, e.g., `rcirc-mentions-next` (`n`) to
move to the next mention, and `rcirc-mentions-prev` (`p`) to move to the
previous mention.

## Installation & Usage

Add the following to your `.emacs` file:

```elisp
(use-package rcirc-mentions
  :after rcirc
  :config
  (rcirc-mentions-global-log-mode 1))
```

## Questions & Patches

For asking questions, sending feedback, or patches, refer to [my public inbox
(mailinglist)](https://lists.sr.ht/~tsdh/public-inbox).  Please mention the
project you are referring to in the subject.

## Bugs

Bugs and requests can be reported
[here](https://todo.sr.ht/~tsdh/rcirc-mentions).

## License

rcirc-mentions.el is licensed under the
[GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) (or later).
