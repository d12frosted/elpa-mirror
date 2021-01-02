
Automatically byte-comple elisp files ASYNCHRONOUSLY when saved.
It invokes "emacs -Q --batch --eval '(setq load-path ...)'
-l ~/.emacs.d/initfuncs.el -f batch-byte-compile this-file.el"

If you define your own macros, put them into ~/.emacs.d/initfuncs.el first.
