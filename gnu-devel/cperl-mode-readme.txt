You can either fine-tune the bells and whistles of this mode or
bulk enable them by putting this in your Init file:

    (setq cperl-hairy t)

DO NOT FORGET to read micro-docs (available from `Perl' menu)   <<<<<<
or as help on variables `cperl-tips', `cperl-praise',           <<<<<<
`cperl-speed'.                                                  <<<<<<

Or search for "Short extra-docs" further down in this file for
details on how to use `cperl-mode' instead of `perl-mode' and lots
of other details.

The mode information (on C-h m) provides some customization help.

Faces used: three faces for first-class and second-class keywords
and control flow words, one for each: comments, string, labels,
functions definitions and packages, arrays, hashes, and variable
definitions.

This mode supports imenu.  You can use imenu from the keyboard
(M-g i), but you might prefer binding it like this:

    (define-key global-map [M-S-down-mouse-3] #'imenu)