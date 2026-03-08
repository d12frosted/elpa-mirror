GNU MathProg is a modeling language to describe optimization problems
using linear programming (LP) and mixed integer programming (MIP) models.
This package uses a Tree-sitter parser to provide syntax highlighting and
navigation for the MathProg language used by the GNU Linear Programming
Kit (GLPK).

The mode does not add any file name patterns to `auto-mode-alist'.
Usually the file extension '.mod' is used for a MathProg model file, but
that is already occupied for `m2-mode'.  You can either add the preferred
file name pattern in your personal Emacs configuration or use file local
variables to automatically enable the mode when visiting a model file.

The package uses a Tree-sitter library to parse MathProg code and you
need to install the appropriate parser (which is defined by the constant
`mathprog-ts-mode-treesit-language-source').  This can for example be
done by using this Elisp code:

   (require 'mathprog-ts-mode)
   (mathprog-ts-mode-install-grammar)

Note that a C compiler is required for this step.  Using the function
provided by the package ensures that a version of the parser matching the
package will be installed.  These commands should also be used to update
the parser to the correct version when the package is updated.
