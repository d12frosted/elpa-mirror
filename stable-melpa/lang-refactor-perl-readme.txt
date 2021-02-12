
Provides commands for simple refactorings for Perl, currently:
* extract variable.



; Installation:

Put in load-path and initialize with:
   (require 'lang-refactor-perl)

   ;; Suggested key bindings
   (global-set-key (kbd "\C-c r e v") 'lr-extract-variable)
   (global-set-key (kbd "\C-c r h r") 'lr-remove-highlights)

Note: This code is also part of Devel::PerlySense (install from
CPAN), so if you're already using that, you won't need to install
this package. In that case the key bindings will be slightly
different.

