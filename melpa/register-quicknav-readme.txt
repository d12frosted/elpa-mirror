This package is built on top of `register.el' and allows you to quickly jump
to the next/previous position register.  If you reach the end, the search
wraps around and continues with the first (or last) register.  It can be used
across all files or individually for each buffer.

Features:

* Cycle through all position registers in both directions.
* Clear current register.
* Store point in unused register (range configurable).
* Clear all registers in the unused registers range.

Installation:

To use `register-quicknav.el', get it from
[MELPA](https://melpa.org/#/register-quicknav) or put it in your load-path
and add the following to your init.el:

(require 'register-quicknav)
(global-set-key (kbd "<C-f5>") #'register-quicknav-prev-register)
(global-set-key (kbd "<C-f6>") #'register-quicknav-next-register)
(global-set-key (kbd "<C-f7>") #'register-quicknav-point-to-unused-register)
(global-set-key (kbd "<C-S-<f7>") #'register-quicknav-clear-current-register)

Or, with use-package:

(use-package register-quicknav
  :bind (("C-<f5>"   . register-quicknav-prev-register)
         ("C-<f6>"   . register-quicknav-next-register)
         ("C-<f7>"   . register-quicknav-point-to-unused-register)
         ("C-S-<f7>" . register-quicknav-clear-current-register)))

Variables:

* `register-quicknav-buffer-only': Cycle only through position registers in
  current buffer.  Can be safely set as file- and/or dir-local variable.
* `register-quicknav-unused-registers-begin': Beginning of the range that is
  used to search for unused registers.  Defaults to `?A'.
* `register-quicknav-unused-registers-end': End of the range that is used to
  search for unused registers.  Defaults to `?Z'.

Differences to similar packages:

[iregister](https://github.com/atykhonov/iregister.el):

* Opens a minibuffer on each jump (thereby requiring an extra keystroke).
* Doesn't work with file-query registers
* Can't be restricted to the current buffer.
* Doesn't look like it's still maintained.

[register-channel](https://github.com/YangZhao11/register-channel):

* Is limited to 5 position registers by default, needs an extra keybinding
  for each additional register.
* Can't be restricted to the current buffer.
* Has no ability to jump to the next/previous register.
