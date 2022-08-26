This library provides a way to manage sets of buffers/files separate
from existing project management systems.  Its goal is to make it easy
to load things that may not fit into the definition of a project, or
are small subsets of projects, etc.

;; Installation

Place `buffer-sets.el` somewhere on your load path and `(require
'buffer-sets)`.  This package is also available on Melpa and may be
installed through `package.el`.

;; Enabling Buffer Sets Mode

`buffer-sets-mode` is a global minor mode which will load buffer set
definitions if necessary (see below), and ensure that buffer sets are
unloaded before Emacs is closed.  It also binds keys for buffer set
manipulation in `buffer-sets-mode-map`.

;;; Key Bindings

- `C-x L l` Load a buffer-set
- `C-x L L` List all buffer-sets
- `C-x L u` Unload a buffer-set
- `C-x L U` Unload *all* buffer sets
- `C-x L p` Unload most recently loaded buffer set
- `C-x L r` Reload a buffer set

;; Configuration

;;; Defining Buffer Sets

Buffer sets are defined through the alist `buffer-sets`.  These are of
the form `(key . definition)`, where `key` is a string name, and
`definition` is an alist with the following keys: `:files`, `:select`,
`:on-apply` and `:on-remove`, which have the following semantics:

- `:files` a list of files/directories to load
- `:select` the name of a buffer to select after loading the set
- `:on-apply` the name of a function to run after loading the set
- `:on-remove` the name of a function to run after loading the set

This variable may be `customize`d, and configuration by this method is
recommended for new users.

;;; Autoloading Buffer Sets

Buffer sets may be autoloaded by setting `buffer-sets-start-sets` to a
list of buffer set names and running
`buffer-sets-install-emacs-start-hook`.  These will be loaded in the
order specified.

;;; Load and Unload Hooks

The hooks `buffer-sets-load-set-hook` and
`buffer-sets-unload-set-hook` are run after loading and unloading a
set (respectively).

;;; Loading Buffer Set Definitions (and migration from old interface)

New users of `buffer-sets` should use `customize` (see above).

Past users of `buffer-sets` may instead configure `buffer-sets`
through an external file or a `setf` expression.  Note, that if you
used the old `define-buffer-set` interface, you may use
`buffer-sets-save` to automatically migrate to either `customize`
or to a setf expression in a file specified by
`buffer-sets-definitions-file`.  Which method of saving buffer set
definitions is used is controlled by the `buffer-sets-save-method`
variable.  If it is `:custom` the `customize` interface is used; if
`:file`, the file specified by `buffer-sets-definitions-file` is
written; if `nil` an error is signalled.


