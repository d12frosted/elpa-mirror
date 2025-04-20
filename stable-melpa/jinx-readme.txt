Jinx is a fast just-in-time spell-checker for Emacs.  Jinx
highlights misspelled words in the text of the visible portion of
the buffer.  For efficiency, Jinx highlights misspellings lazily,
recognizes window boundaries and text folding, if any.  For
example, when unfolding or scrolling, only the newly visible part
of the text is checked if it has not been checked before.  Each
misspelling can be corrected from a list of dictionary words
presented as a completion menu.

Installing Jinx is straight-forward and configuring should not need
much intervention.  Jinx can be used completely on its own, but can
also safely co-exist with Emacs's built-in spell-checker Ispell.

Jinx's high performance and low resource usage comes from directly
calling the API of the Enchant library, see
https://rrthomas.github.io/enchant/.  Jinx automatically compiles
jinx-mod.c and loads the dynamic module at startup.  By binding
directly to the native Enchant API, Jinx avoids slower
inter-process communication.

See the manual for further information.
