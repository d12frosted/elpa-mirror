This package provides a way to modify LaTeX environments, macros, as
well as inline and display maths mode (seeing them as an environment
of sorts).  There exists a [blog post], which includes some moving
pictures that showcase the functionality of this package.

Note that, in the sequel, "environment" shall usually refer to LaTeX
environments, macros, as well as inline and display maths mode—not
just to LaTeX environments themselves.

Refer to the README for a full account of the package's
functionality, as well as how to install it.  Briefly:

+ The entry point is the `latex-change-env' function, which—when
  invoked from inside an environments—pops up a list of possible
  actions, as defined by the `latex-change-env-options' variable.
  There is also the option to cycle through arguments in
  `latex-change-env-cycle', which depends on [math-delimiters].

+ Labels are changed/deleted in a previous way, with an option to
  edit the respective label across the whole project; see below.
  Also, deleted labels are stored for the current session (based on
  the specific contents of the environment) and potentially restored
  when switching from e.g. display maths to an environment with an
  associated label prefix in `latex-change-env-labels'.

+ What exactly we mean by "inline" and "display maths" is controlled
  by the `latex-change-env-math-inline' and
  `latex-change-env-math-display' variables.

+ This package depends on AUCTeX—but you are already using that
  anyways.

+ If you're customizing `latex-change-env-edit-labels-in-project', we
  also depend on project.el, meaning Emacs 27.1 and up.

[blog post]: https://tony-zorman.com/posts/latex-change-env-0.3.html
[math-delimiters]: https://github.com/oantolin/math-delimiters
