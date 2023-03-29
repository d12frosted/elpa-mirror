Jinx provides just-in-time spell-checking via libenchant
(https://abiword.github.io/enchant/).  The package aims to achieve
high performance and low resource usage, without impacting your
editing experience.  Overall Jinx should just work out of the box
without much intervention.

Jinx highlights misspellings lazily only in the visible part of the
text.  The window boundaries and text folding are taken into
account.  Jinx binds directly to the native libenchant API, such
that process communication with a backend Aspell process can be
avoided.  Libenchant is widely used as spell-checking API by text
editors and supports Nuspell, Hunspell, Aspell and a few lesser
known backends.  Jinx automatically compiles `jinx-mod.c' and loads
the dynamic module at startup.  Libenchant must be installed on
your system for compilation.  If `pkg-config' is available it will
be used to locate libenchant.  On Debian or Ubuntu, install the
packages `libenchant-2-2', `libenchant-2-dev' and `pkg-config'.
On Fedora or RHEL, install the package `enchant2-devel'.

Jinx supports multiple languages in a buffer at the same time via
the `jinx-languages' customization variable.  It offers flexible
settings to ignore misspellings via faces (`jinx-exclude-faces' and
`jinx-include-faces'), regular expressions (`jinx-exclude-regexps')
and programmable predicates.  Jinx comes preconfigured for the most
important major modes.

Jinx offers the auto-loaded modes `global-jinx-mode' and
`jinx-mode'.  You can either enable `global-jinx-mode' or add
`jinx-mode' to the hooks of the modes.

(add-hook 'emacs-startup-hook #'global-jinx-mode)

(dolist (hook '(text-mode-hook prog-mode-hook conf-mode-hook))
  (add-hook hook #'jinx-mode))

Furthermore Jinx brings two auto-loaded commands `jinx-correct' and
`jinx-languages'.  In order to correct misspellings bind
`jinx-correct' to a convenient key in your configuration.  Jinx is
independent of the Ispell package, so you can reuse the binding M-$
which is bound to `ispell-word' by default.  When pressing M-$,
Jinx offers correction suggestions for the misspelling next to
point.  If the prefix key C-u is pressed, the entire buffer is
spell-checked.

(keymap-global-set "<remap> <ispell-word>" #'jinx-correct)

Jinx offers a similar UI as Augusto Stoffel's jit-spell package and
borrows ideas from it.  Jit-spell uses Ispell process communication
instead of a native API.  It does not restrict the highlighting to
the visible text.  In my setup I observed an increase in load and
latency as a consequence, in particular in combination with stealth
locking and commands which trigger fontification eagerly like
`consult-line' from my Consult package.

The technique to spell-check only the visible text was inspired by
Campbell Barton's spell-fu package.  Spell-fu maintains the
dictionary itself via a hash table, which results in high memory
usage for languages with compound words or inflected word forms.
In Jinx we avoid the complexity of managing the dictionary and
access the advanced spell-checker algorithms directly via
libenchant (affixation, compound words, etc.).
