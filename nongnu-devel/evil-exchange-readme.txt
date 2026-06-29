[![NonGNU ELPA](https://elpa.nongnu.org/nongnu/evil-exchange.svg)](https://elpa.nongnu.org/nongnu/evil-exchange.html)
[![MELPA](https://melpa.org/packages/evil-exchange-badge.svg)](https://melpa.org/#/evil-exchange)
[![Build Status](https://travis-ci.org/Dewdrops/evil-exchange.png?branch=master)](https://travis-ci.org/Dewdrops/evil-exchange)

English is not my first language, so feel free to correct any of my mistake.

evil-exchange
============

Easy text exchange operator for Evil. This is the port of [vim-exchange](https://github.com/tommcdo/vim-exchange) by Tom McDonald.

Default bindings
----------------

`gx` (evil-exchange)

On the first use, define (and highlight) the first {motion} to exchange. On the second use,
define the second {motion} and perform the exchange.

`gX` (evil-exchange-cancel)

Clear any {motion} pending for exchange.

### Notes

* `gx` (and `gX`) can also be used from visual mode, which is sometimes easier than coming
  up with the right {motion}
* If you're using the same motion again (e.g. exchanging two words using
  `gxiw`), you can use `.` (evil-repeat) the second time.
* `gxx` works as you expect.

Highlights
----------
* Unlike the original vim plugin's buffer local behaviour, this extension allows you to exchange texts across buffers.
* Works correctly even when text insertion/deletion occurs between two `evil-exchange` invokes.

Installation
------------

```lisp
(require 'evil-exchange)
;; change default key bindings (if you want) HERE
;; (setq evil-exchange-key (kbd "zx"))
(evil-exchange-install)
```

evil-exchange is also available in [melpa](https://melpa.org/) and is shipped with [spacemacs](https://github.com/syl20bnr/spacemacs).

Customization
-------

You can change the default bindings by customizing `evil-exchange-key` and/or `evil-exchange-cancel-key` BEFORE  `evil-exchange-install` is called.

Vim-compatible key bindings
-------

Due to the way how evil (and emacs) implements key bindings, `evil-exchange` can't be bound to `cx` (which is the default bindings of the original
vim plugin) by customizing `evil-exchange-key` option. If you prefer the key bindings suggested by vim-exchange, you can try the settings below:

```lisp
(require 'evil-exchange)
(evil-exchange-cx-install)
```

The `evil-exchange-cx-install` function tries to mimic the original vim plugin's behaviour, i.e. `cx` in normal state bound to `evil-exchange`,
`cxc` in normal state bound to `evil-exchange-cancel`, and `X` in visual state bound to `evil-exchange`.

Known Issues
-------

* Some packages may redefine `c` (`evil-change`) in normal state or/and `x` in operator state, which will conflict with the vim style bindings (`cx` and `cxc`). In this case, you may have to unbind them to make `evil-exchange-cx-install` work. Any PRs are welcome for compatibility.
