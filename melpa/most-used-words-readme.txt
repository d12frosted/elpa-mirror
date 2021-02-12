Identify the most frequently used words in a buffer.

The command
  M-x most-used-words-buffer
goes through the current buffer keeping a count of words, as defined
by the default syntax table.  Once done, it displays a buffer of the
most frequently used words.

I wrote the following functions, and the wonderful posters at
gnu.emacs.help reviewed it.
Part of a discussion thread on gnu.emacs.help follows the
development:
https://groups.google.com/d/topic/gnu.emacs.help/nC8IsIuNeek/discussion

Special thanks are due to Stefan Monnier and Eric Abrahamsen, who
made suggestions that greatly improved performance; Emmanuel Berg
reminded me to prefix functions from CL-LIB; Bob Proulx,
Ben Bacarisse, Nick Dokos, Eli Zaretskii shared of their Unix wisdom
and experience; and Bob Newell tested it for his purposes.
