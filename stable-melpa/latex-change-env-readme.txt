This package provides a way to modify LaTeX environments, as well as
the display math mode (seeing it as an environment of sorts).  Thus,
henceforth the world "environment" shall—in addition to
\begin--\end-style environments—also refer to display math.

Refer to the README for a full account of the package's
functionality, as well as how to install it.  Briefly:

+ The entry point is the `latex-change-env' function, which—when
  invoked from inside an environments—pops up a list of possible
  actions, as defined by the `latex-change-env-options' variable.

+ Labels are changed/deleted in a previous way, with an option to
  edit the respective label across the whole project; see below.
  Also, deleted labels are stored for the current session (based on
  the specific contents of the environment) and potentially restored
  when switching from e.g. display math to an environment with an
  associated label prefix in `latex-change-env-labels'.

+ What exactly we mean by "display math" is controlled by the
  `latex-change-env-math-display' variable.

+ This package depends on AUCTeX—but you are already using that
  anyways.

+ If you're customizing `latex-change-env-edit-labels-in-project', we
  also depend on project.el, meaning Emacs 27.1 and up.
