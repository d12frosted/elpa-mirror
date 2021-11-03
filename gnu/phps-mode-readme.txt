A major-mode that uses original PHP lex-analyzer and parser for syntax coloring, imenu and indentation making it easier to spot errors in syntax.

Also includes full support for PSR-1 and PSR-2 indentation and imenu.
Improved syntax table in comparison with old PHP major-mode.

For flycheck support run `(phps-mode-flycheck-setup)'.

For asynchronous lexer set: `(setq phps-mode-async-process t)'

For asynchronous lexer via `async.el' instead of threads set: `(setq phps-mode-async-process-using-async-el t)'

Please see README.md from the same repository for extended documentation.