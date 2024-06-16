`most-faces' is a package that provides a list of most faces (as
symbols) available in GNU Emacs core as well as packages from GNU
Elpa, Nongnu Elpa and Melpa.  In fact, `most-faces' provides two
variables:

`most-faces-as-faces' is a list of symbols that are defined as
faces, e.g. via `defface'.  For example, `foo' might be a member of
it because it might have been defined as follows:

  (defface foo '((t :foreground "#123456")) "Some docstring.")

`most-faces-as-variables' is a list of symbols that are defined as
variables with a value that is a symbol that is defined as a face.
For example, `bar' might be a member of it because it might be
defined as follows:

  (defvar bar 'foo)

Please contribute missing faces!
