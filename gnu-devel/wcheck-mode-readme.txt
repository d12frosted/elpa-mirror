A general interface for text checkers

Wcheck mode is a general-purpose text-checker interface for Emacs
text editor.  Wcheck mode a minor mode which provides an on-the-fly
text checker.  It checks the visible text area, as you type, and
possibly highlights some parts of it.  What is checked and how are all
configurable.

Wcheck mode can use external programs or Emacs Lisp functions for
checking text.  For example, Wcheck mode can be used with
spell-checker programs such as Ispell, Enchant and Hunspell, but
actually any tool that can receive text from standard input stream
and send text to standard output can be used.  Wcheck mode sends parts
of buffer's content to an external program or an Emacs Lisp function
and, relying on their output, decides if some parts of text should be
marked in the buffer.