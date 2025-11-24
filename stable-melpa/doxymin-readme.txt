
Minor mode for creating Doxygen documentation.
Doxymin allows you to generate doxygen style comments for your C functions.
It also works for C++ and it might work for Java and C#. Technically should
work for all functions of languages using curly braces as delimiters.

- Invoke doxymin-mode with M-x doxymin-mode.  To have doxymin-mode
  invoked automatically when in C mode, put

  (add-hook 'c-mode-common-hook 'doxymin-mode)

  in your .emacs.

- Default key bindings are:
  - C-x C-d f will insert a Doxygen comment for the next function.
  - C-x C-d i will insert a Doxygen comment for the current file.

Doxymin has been tested on and works with:
- GNU Emacs 30.1

To submit a problem report, request a feature or get support, please
open an issue at https://gitlab.com/L0ren2/doxymin
