Typo.el implements a Norvig-Style[0] spell-corrector for Emacs'
completion system.

To initialize this completion style, evaluate

   (add-to-list 'completion-styles 'typo t)

or configure the corresponding code in your initialisation file.

[0] https://norvig.com/spell-correct.html