Side Notes
==========

Quickly display your quick side notes in quick side window.

Side notes live in a plain text file, called notes.txt by default, in
the current directory or any higher directory in the current hierarchy.
i.e. When locating notes, we first look for a notes.txt file in the
current directory, then one directory up, then two directories up, and
so forth.

Side notes are displayed in a side window with the command
side-notes-toggle-notes.

The filename is defined by user option side-notes-file.

To really mix things up, there's the user option
side-notes-secondary-file, which defaults to notes-2.txt, and will
display a separate notes file in a lower side window when the command
side-notes-toggle-notes is prefixed with an argument (C-u).

By default, having a notes file in any parent directory will locate that
file rather than visit a non-existing file in the current directory, but
you can override this by prefixing side-notes-toggle-notes with...

-  C-u C-u to force visiting side-notes-file within the current
   directory.
-  C-u C-u C-u to force visiting side-notes-secondary-file within
   the current directory.

Of course, you can use Markdown or Org Mode formatting by changing the
file extensions of side-notes-file and/or side-notes-secondary-file.

For more information on how to change the way the side window is
displayed, see (info "(elisp) Side Windows")


Installation
------------

Install from [MELPA stable][1] then add something like the following to
your init file:

    (define-key (current-global-map) (kbd "M-s n") #'side-notes-toggle-notes)

[1]: https://stable.melpa.org/#/side-notes
[2]: https://melpa.org/#/side-notes
