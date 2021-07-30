language-id is a small, focused library that helps other Emacs
packages identify the programming languages and markup languages
used in Emacs buffers.  The main point is that it contains an
evolving table of language definitions that doesn't need to be
replicated in other packages.

Right now there is only one public function, `language-id-buffer'.
It looks at the major mode and other variables and returns the
language's GitHub Linguist identifier.  We can add support for
other kinds of identifiers if there is demand.

This library does not do any statistical text matching to guess the
language.
