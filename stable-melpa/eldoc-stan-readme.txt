
This file defines a hash table for looking up stan function eldoc
strings and stan eldoc-documentation-function.

Usage
The `eldoc-documentation-function' function needs to be set to
`eldoc-stan-eldoc-documentation-function' buffer locally in
`stan-mode'.

A convenience function `eldoc-stan-setup' can be added to the
mode-specific hook `stan-mode-hook'.
(add-hook 'stan-mode-hook #'eldoc-stan-setup)

With the `use-package', the following can be used:
(use-package eldoc-stan
  :hook (stan-mode . eldoc-stan-setup))

If you already have a custom stan-mode setup function, you can add
the following to its body.
(setq-local eldoc-documentation-function
            #'eldoc-stan-eldoc-documentation-function)

References
eldoc-documentation-function
 https://doc.endlessparentheses.com/Var/eldoc-documentation-function.html
Deep diving into a major mode - Part 2 (IDE Features)
 https://www.modernemacs.com/post/major-mode-part-2/
Displaying information for string under point
 https://emacs.stackexchange.com/questions/18581/displaying-information-for-string-under-point
c-eldoc.el: eldoc-mode plugin for C source code
 https://github.com/nflath/c-eldoc (available on melpa)
c-eldoc.el: Helpful description of the arguments to C/C++ functions and macros
 https://github.com/mooz/c-eldoc (uses deferred.el)
css-eldoc.el: eldoc-mode plugin for CSS
 https://github.com/zenozeng/css-eldoc
