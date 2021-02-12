
A minor mode for filtering search buffer output.

With double-saber-mode enabled, use "d" to delete words and "x" to narrow.

Installation:
To load this file, add (require 'double-saber) to your init file.

You can configure double-saber for different modes using
double-saber-mode-setup. The following is an example for ripgrep.

(add-hook 'ripgrep-search-mode-hook
         (lambda ()
           (double-saber-mode)
           (setq-local double-saber-start-line 5)
           (setq-local double-saber-end-text "Ripgrep finished")))

Setting the start line and end text prevents useful text at those locations
from getting deleted.

Please see README.md for more documentation, or read it online at
https://github.com/dp12/double-saber
