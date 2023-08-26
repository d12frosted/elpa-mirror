The core of the package is the ability to wrap a single checker
into a flymake diagnostic function which could be added to
`flymake-diagnostic-functions':

   (flymake-flycheck-diagnostic-function-for 'sh-shellcheck)

Flycheck has the convenient notion of "available" checkers, which is
determined at runtime according to mode and availability of necessary
tools, as well as config for explicitly "chained" checkers.

Accordingly, you can obtain the diagnostic functions for all checkers
that flycheck would enable in the current buffer like this:

   (flymake-flycheck-all-chained-diagnostic-functions)

In practical terms, most users will want to simply enable all
available checkers whenever `flymake-mode' is enabled:

   (add-hook 'flymake-mode-hook 'flymake-flycheck-auto)

If you find that `flymake' is now running `flycheck' checkers which
are redundant because there's already a `flymake' equivalent, simply
add those checkers to the `flycheck-disabled-checkers' variable, e.g.

   (add-to-list 'flycheck-disabled-checkers 'sh-shellcheck)

Some caveats:

* Flycheck UI packages will have no idea of what the checkers are
  doing, because they are run without flycheck's coordination.
* Flycheck's notion of "chained checkers" is not handled
  automatically, so although multiple chained checkers can be used,
  they will all be executed simultaneously even if earlier checkers
  fail.  This could either be considered a feature, or lead to
  redundant confusing messages.
