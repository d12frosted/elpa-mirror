This package provides the `x` text object to manipulate html/xml tag attributes.
it is a port of https://github.com/whatyouhide/vim-textobj-xmlattr vim plugin.

Try using `dax`, `vix` and `gUix`. You can customize the binding.

To install the package, Just use https://melpa.org.
Here's an oneliner using https://github.com/jwiegley/use-package:
(use-package exato :ensure t)

*customization*: to change the bind from `x` to your liking, you can customize exato-key:

(use-package exato
  :ensure t
  :init
  (setq exato-key "h"))
