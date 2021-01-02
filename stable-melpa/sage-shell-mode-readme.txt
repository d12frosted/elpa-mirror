This package provides a front end for Sage (http://www.sagemath.org/)
and a major mode derived from python-mode (sage-shell:sage-mode).

To use this package, check the return value of (executable-find "sage").
If (executable-find "sage") is a string, you are ready to use this package.
If not, put the following line to ~/.emacs.d/init.el
(setq sage-shell:sage-root "/path/to/sage/root_directory")
And replace /path/to/sage/root_directory to the path to $SAGE_ROOT.

Then you can run Sage process in Emacs by M-x sage-shell:run-sage.
You can run multiple Sage processes by M-x sage-shell:run-new-sage.
By putting the following line to ~/.emacs.d/init.el,
(sage-shell:define-alias)
you can run Sage by M-x run-sage instead of M-x sage-shell:run-sage.

Please visit https://github.com/sagemath/sage-shell-mode for more
infomation.
