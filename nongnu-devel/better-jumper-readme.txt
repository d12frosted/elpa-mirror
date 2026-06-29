# better-jumper
[![NonGNU ELPA](https://elpa.nongnu.org/nongnu/better-jumper.svg)](https://elpa.nongnu.org/nongnu/better-jumper.html)

A configurable jump list implementation for Emacs that can be used to easily
jump back to previous locations.


# Usage

## Install

Better-jumper is available on [NonGNU ELPA](https://elpa.nongnu.org/) or MELPA.

`M-x package-install better-jumper`

```emacs-lisp
(require 'better-jumper)
```

`better-jumper` comes with a global mode: `better-jumper-mode` and a local mode: `better-jumper-local-mode`.

You can either a) enable globally:

```elisp
(better-jumper-mode +1)

;; and disable in specific modes
(push 'python-mode better-jumper-disabled-modes)

;; or disable it manually
(add-hook 'python-mode-hook #'turn-off-better-jumper-mode)
```

Or b) enable locally, where you need it:

```elisp
(add-hook 'python-mode-hook #'turn-on-better-jumper-mode)
```

## Getting started

Once `better-jumper` has been loaded it is ready to start tracking jump history.
Anytime `better-jumper-set-jump` is invoked the current location is added to
either the window or buffer specific jump list (depending on the
`better-jumper-context` setting). At any time the jump backward/forward
functions can be used to navigate through the jump history.

If you are an `evil` user then `better-jumper` can piggy back off of the built
in jumplist implementation to track when jumps occur. The setting
`better-jumper-use-evil-jump-advice` dictates this behavior and defaults to `t`.
Note that `better-jumper` does not interact with or alter evil's jump list in
any way.

## Summary of interactive commands

| Command                     | Description                                                         |
|--------------------------   |---------------------------------------------------------------------|
| better-jumper-set-jump      | Add a new jump location to jump list using current buffer/position  |
| better-jumper-jump-backward | Jump to back to previous location in jump list                      |
| better-jumper-jump-forward  | Jump forward to next location in jump list                          |
| better-jumper-get-jumps     | Get jump state for window or buffer                                 |
| better-jumper-set-jumps     | Set jump state for window or buffer                                 |

## Example keybinding

Configure the standard jump list navigation keybindings for evil/vim:

```lisp
(with-eval-after-load 'evil-maps
  (define-key evil-motion-state-map (kbd "C-o") 'better-jumper-jump-backward)
  (define-key evil-motion-state-map (kbd "<C-i>") 'better-jumper-jump-forward))
```

# Configuration Options

#### Jump Context (`better-jumper-context`)

This setting specifies the context in which jump lists are tracked. This can
either be set to `'buffer` or `'window`. If the value is `'buffer` then a jump
list is maintained for each individual buffer. Conversly, if the value is
`'window` then the jump list is maintained per window and will operate across
buffers in that window.

While in the `'window` context, jump lists are stored as persistent window
parameters and can be saved and restored along with the window configuration
using something like `desktop` or `persp-mode`. This is the default context.

While in the `'buffer` context, jump lists are maintained using buffer-local
variables and can optionally by saved using `savehist`.

#### New Window Behavior (`better-jumper-new-window-behavior`)

This setting specifies the behavior that will take place when a new window is
created AND the current context is set to `'window`. This can be either set to
`'copy` or `'empty`. If the value is `'copy` then the last selected window's
jump list will be copied to the new window. If the value is `'empty` then the
new window's jump list will start empty.

#### Add Jump Behavior (`better-jumper-add-jump-behavior`)

This setting specifies how the jump list is affected when a new jump is added.
If the value is set to `'append` then new items are always added to the end
of the jump list regardless of the current position. If the value is set to
`replace`, then if the any jumps newer than the current position in the jump
list will be replaced. I.e. If a user jumps back three times then adds a new
jump, those three jumps will be replaced by the new jump in the list.

#### Max Length  (`better-jumper-max-length`)

This is a numeric value that dictate the maximum length that a jump list can
grow to. If the length of a jump list exceeds this size then the oldest items in
the list will be dropped.

#### Use Evil Jump Advice (`better-jumper-use-evil-jump-advice`)

If non-nil better jumper will attach a piece of advice to the `evil-jump`
function that will ensure that anytime a jump is added using `evil-jump` a
corresponding jump will be added using `better-jumper`.

#### better-jumper-use-savehist (`better-jumper-use-savehist`)

If non-nil better jumper will use savehist to save jump history. This is
currently only implemented for the `'buffer` context. Persistent window
parameters are used to save and restore jump history for windows.

#### better-jumper-buffer-savehist-size (`better-jumper-buffer-savehist-size`)

This number dictates how many of the most recent buffers should have their jump
state saved to the savehist file when savehist is enabled the the context is set
to `'buffer`.

# Hooks

#### Pre-jump Hook (`better-jumper-pre-jump-hook`)

A hook that is invoked before a jump occurs.

#### Post-jump Hook (`better-jumper-post-jump-hook`)

A hook that is invoked after a jump occurs.

# Comparison with `evil-jump`

This package was heavily inspired by `evil-jump` and initially was planned as a
modification of or pull request to `evil`. It was primarily born out of the
desire to isolate jumps across `persp-mode` perspectives, however the changes
proved to be to large to be a simple modification. Additionally, this package
provides more customization options as well as a few other core improvements.

A few advantages of `better-jumper` are:

* Uses window persistent parameters to store jump lists. As a result
  `better-jumper` properly works with `persp-mode` and any other feature that
  manages window configurations.

* True buffer specific jump lists. When instructed to not cross buffer
  boundaries `evil-jumper` still tracks jumps per window only limits the jumps
  available to ones located in the current buffer.
  
* Configurable new window behavior. `evil-jumper` ALWAYS copies the jump list
  from the previously selected window to any newly created window.

# Caveats

* Jump locations are stored as `marker`s so they will maintain a more accurate
  location in the buffer. However, due to the fact that markers can't be
  serialized they are down converted to simple buffer positions when saved
  either via window configuration or savehist.
  
* Currently `savehist` support is only limited to the `'buffer` context. When
  running in the `'window` context, the jump list is stored as a persistent
  window parameter and is intended to be saved using alongside the window
  configuration using somethinig like `desktop` or `persp-mode`.
