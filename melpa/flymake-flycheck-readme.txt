WARNING: EARLY PREVIEW CODE, SUBJECT TO CHANGE

This package provides support for running any flycheck checker as a
flymake diagnostic backend.  The effect is that flymake will
control when the checker runs, and flymake will receive its errors.

For example, to enable a couple of flycheck checkers in a bash
buffer, the following code is sufficient:

    (setq-local flymake-diagnostic-functions
                (list (flymake-flycheck-diagnostic-function-for 'sh-shellcheck)
                      (flymake-flycheck-diagnostic-function-for 'sh-posix-bash)))

In order to add diagnostic functions for all checkers that are
available in the current buffer, you can use:

    (setq-local flymake-diagnostic-functions (flymake-flycheck-all-chained-diagnostic-functions))

but note that this will disable any existing flymake diagnostic
backends.

Some caveats:

* Flycheck UI packages will have no idea of what the checkers are
  doing, because they are run without flycheck's coordination.
* Flycheck's notion of "chained checkers" is not handled
  automatically, so although multiple chained checkers can be used,
  they will all be executed simultaneously even if earlier checkers
  fail.  This could either be considered a feature, or lead to
  redundant confusing messages.
