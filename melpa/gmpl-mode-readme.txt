                             _____________

                               GMPL-MODE

                              Junpeng Qiu
                             _____________


Table of Contents
_________________

1 Overview
2 Usage
.. 2.1 Using the Major Mode
.. 2.2 Using `gmpl-glpsol-solve-dwim'
3 *TODO*


Major mode for editing GMPL(MathProg) files.

If you are writing GMPL and using GLPK and to solve problems, try this
out!


1 Overview
==========

  GMPL is a modeling language to create mathematical programming models
  which can be used by [GLPK].

  Although GMPL is a subset of AMPL, the current Emacs major mode for
  AMPL, which can be found at [https://github.com/dpo/ampl-mode],
  doesn't work well with GMPL files. Here is the list of the reasons why
  `gmpl-mode' works better compared to `ampl-mode' when editing GMPL
  files:
  1. Support single quoted string and C style comments.
  2. Some keywords(such as `for', `end') are highlighted properly, and
     it provides better hightlighting generally.
  3. A usable indent function.
  4. Some useful commands to interact with `glpsol' directly.


  [GLPK] https://www.gnu.org/software/glpk/


2 Usage
=======

2.1 Using the Major Mode
~~~~~~~~~~~~~~~~~~~~~~~~

  First, add the `load-path' and load the file:
  ,----
  | (add-to-list 'load-path "/path/to/gmpl-mode.el")
  | (require 'gmpl-mode)
  `----

  Use `gmpl-mode' when editing files with the `.mod' extension:
  ,----
  | (add-to-list 'auto-mode-alist '("\\.mod\\'" . gmpl-mode))
  `----


2.2 Using `gmpl-glpsol-solve-dwim'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  When in `gmpl-mode', you can use C-c C-c to invoke
  `gmpl-glpsol-solve-dwim'. This command will use the content of the
  current buffer(or the region if the region is active) as the input for
  the `glpsol' command, and then display the results in a separate
  buffer with some colors added. The following command is basically what
  `gmpl-glpsol-solve-dwim' does(Yes, `--ranges' only makes sense for
  simplex):
  ,----
  | glpsol -m input-file -o output-file --ranges sensitivity-file
  `----

  You can set the variable `gmpl-glpsol-program' to the exact location
  of your `glpsol' command if it is not in the PATH or has some other
  magic name.

  It is also possible that you can pass extra arguments to `glpsol'
  command. The buffer-local variable, `gmpl-glpsol-extra-args', controls
  the value of extra arguments. To set extra arguments for `glpsol', use
  `M-x gmpl-glpsol-set-extra-args' (which is bound to C-c C-a).

  For example, if you want to set the `--interior' option for `glpsol',
  you can use `M-x gmpl-glpsol-set-extra-args' or C-c C-a. This command
  will set the value of `gmpl-glpsol-extra-args' and add the following
  lines at the end of the file:
  ,----
  | # Local Variables:
  | # gmpl-glpsol-extra-args: "--interior"
  | # End:
  `----

  After that, when we invoke `gmpl-glpsol-solve-dwim', essentially
  following command will be used:
  ,----
  | glpsol -m input-file -o output-file --ranges sensitivity-file --interior
  `----

  You can use `gmpl-glpsol-set-extra-args' to set the value of
  `gmpl-glpsol-extra-args' in different buffers so that you can have
  different commnd line arguments for different problems.


3 *TODO*
========

  - Translate LaTeX equations to GMPL format and solve the problem
    directly.
  - Add company-keywords support.
