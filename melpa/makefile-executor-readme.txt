
A set of tools aimed at working with Makefiles on a project level.

Currently available:
- Interactively selecting a make target and running it.
  Bound to 'C-c C-e' when 'makefile-executor-mode' is enabled.
- Re-running the last execution.  We usually run things in
  Makefiles many times after all!  Bound to '`C-c C-c'` in `makefile-mode` when
  'makefile-executor-mode'` is enabled.
- Running a makefile target in a dedicated buffer.  Useful when
  starting services and other long-running things!  Bound to
  '`C-c C-d'` in `makefile-mode` when 'makefile-executor-mode'` is enabled.
- Calculation of variables et.c.; $(BINARY) will show up as what it
  evaluates to.
- If `projectile' is installed, execution from any buffer in a
  project.  If more than one is found,
  an interactive prompt for one is shown.  This is added to the
  `projectile-commander' on the 'm' key.

To enable it, use the following snippet to add the hook into 'makefile-mode':

(add-hook 'makefile-mode-hook 'makefile-executor-mode)
