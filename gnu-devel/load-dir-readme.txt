This package provides a way to load all Emacs Lisp snippets (they
don't have to be libraries) in a directory on startup or when Emacs is
already running.  It won't reload snippets unless the user requests
it, so for instance adding a lambda to a hook is usually safe.

You can specify ~/.emacs.d/load.d, a single directory, or a list of
directories.  The file search can be recursive.  See the
customizable variable `load-dirs' for details.

The intent of ~/.emacs.d/load.d is to give package installers like
el-get.el (see https://github.com/dimitri/el-get) and other tools a
way to easily bootstrap themselves without necessarily modifying
your .emacs or custom files directly.