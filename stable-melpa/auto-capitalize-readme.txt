`auto-capitalize-mode' is a minor mode that automatically capitalizes text as
you type. It does this at the start of sentences/paragraphs, as well as in
comments or strings in any `prog-mode' buffer, or indeed any buffer whose
major mode defines some syntax for comments (Org, TeX,...).

A basic configuration using `use-package' might look like

    (use-package auto-capitalize
      :init
      (auto-capitalize-global-mode))

Or, to also use the Org, SGML, and TeX plugins (the latter requiring AUCTeX):

    (use-package auto-capitalize
      :init
      (auto-capitalize-global-mode)
      :hook
      ((TeX-mode . auto-capitalize-tex-mode)
       (org-mode . auto-capitalize-org-mode)
       (sgml-mode . auto-capitalize-sgml-mode)))

The heart of the package is `auto-capitalize-after-change', which is
installed in `after-change-functions' when the mode is enabled. It serves as
the main entry point for the capitalization logic, which is based on two
hooks that you can add your own predicates to.

The `auto-capitalize-blocking-functions' hook gives you the right of first
refusal over capitalization: each function in that hook is called with two
arguments, TEXT-START and WORD-START, and returns non-nil to block
capitalization of the word at WORD-START. A single function in that hook
returning non-nil causes the check to fail and blocks capitalization. Note,
however, that even if every function in this hook returns nil, that does not
guarantee a word will be capitalized.

By default, this hook only contains
`auto-capitalize-default-blocking-function'.

The second hook is `auto-capitalize-trigger-functions'. These functions are
called with the same arguments as the blocking functions, and if any of them
return non-nil, capitalization occurs. By default, only
`auto-capitalize-default-trigger-function' is included in this hook.

Note that the blocking functions take precedence: they are called first, and
only if they all return nil, the trigger functions get called.

Additional plugins, like the provided `auto-capitalize-tex' and
`auto-capitalize-org', can add their own predicates buffer-locally.

Alternatively, if you don't want to write whole new predicates, you can
always customize some of the user options in the `auto-capitalize' group.
Examples include `auto-capitalize-strings', which controls whether strings in
prog-mode should be auto-capitalized, and its comment analogue
`auto-capitalize-comments'.

This package is a revamp of Yuta Yamada’s version
(https://github.com/yuutayamada/auto-capitalize-el), which is itself a fork
of the original auto-capitalize.el, written by Kevin Rodgers and shared on
the emacswiki (https://www.emacswiki.org/emacs/auto-capitalize.el). I have
tried to streamline the code, building on the refactoring process that Yuta
Yamada had already started, and removing/replacing old artifacts with their
modern equivalent. I have also modified the package’s interface to make it
simpler to use and to cover more cases.
