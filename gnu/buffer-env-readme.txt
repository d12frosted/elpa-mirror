	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	     BUFFER-ENV — BUFFER-LOCAL PROCESS ENVIRONMENTS
	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Basic setup
.. 1. On the project side
.. 2. On the Emacs side
2. Alternative settings
.. 1. Python virtualenvs
.. 2. .env files
.. 3. Direnv
.. 4. Non-Unix-like systems
3. Compatibility issues
4. Related packages
5. Contributing


With this package, you can teach Emacs to call the correct version of
external programs such as linters, compilers and language servers on a
/per-project/ basis.  Thus you can work on several projects in parallel
without undue interference and switching seamlessly between them.


1 Basic setup
═════════════

1.1 On the project side
───────────────────────

  Your project settings should go into a shell script named `.envrc'
  which exports a suitable `PATH', as well as any other desired
  environment variables.  Place this script at the root directory of
  your project.

  This follows the ansatz of the popular [direnv] program, and is mostly
  compatible with it.  However, buffer-env is entirely independent of
  direnv so it is not possible to use direnv-specific features in the
  `.envrc' scripts — at least not directly.

  Alternatively, it is possible to configure buffer-env to directly
  support other environment setup methods, such as Python virtualenvs or
  `.env' files.  See below for details.


[direnv] <https://direnv.net/>


1.2 On the Emacs side
─────────────────────

  The usual way to activate this package in Emacs is by including the
  following in your init file:

  ┌────
  │ (add-hook 'hack-local-variables-hook 'buffer-env-update)
  └────

  This way, any buffer potentially affected by [directory-local
  variables] will also be affected by buffer-env.  It is nonetheless
  possible to call `buffer-env-update' interactively or add it only to
  specific major-mode hooks.


[directory-local variables]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html>


2 Alternative settings
══════════════════════

  This package works as follows.  First, a file named `buffer-env-file'
  is looked up in the current directory or one of its parents.  In case
  of success, `buffer-env-command' is executed in a shell, with the
  found file as argument.  This command should print a null-separated
  list of environment variables (and nothing else) to stdout.  The
  buffer-local values of `process-environment' and `exec-path' are then
  set based on that.

  With this in sight, it should be possible to integrate with any of the
  numerous environment management tools out there.


2.1 Python virtualenvs
──────────────────────

  One can always source a virtualenv activation script from an `.envrc'
  script, but this additional step can be avoided by calling
  `buffer-env-update' manually and pointing to the `bin/activate'
  script.  This can be automated if you create virtualenvs in a
  predictable place, say in a `.venv' directory at the root of each
  project; in this case you can say

  ┌────
  │ (setq buffer-env-file ".venv/bin/activate")
  └────

  or a variation thereof.  Note that it is also possible to provide an
  absolute path for `buffer-env-file', and it is possible to specify it
  as a buffer- or directory-local variable.


2.2 .env files
──────────────

  To gather environment variables from `.env' files in the style of
  Docker, Node.js and others, use the following settings:

  ┌────
  │ (setq buffer-env-file ".env")
  │ (setq buffer-env-command "set -a && >&2 . \"$0\" && env -0")
  └────

  Obviously, this assumes that the `.env' file is correct when
  interpreted as a shell script, which dictates, for instance, how and
  when quotes are to be used.


2.3 Direnv
──────────

  As mentioned above, the default settings are compatible with direnv,
  but only as long as `.envrc' is a regular shell script.  If you need
  any direnv extensions, you will probably be better served by the
  [envrc] package.  It is nonetheless possible to take some advantage of
  direnv by setting

  ┌────
  │ (setq buffer-env-command "direnv exec . env -0")
  └────


[envrc] <https://github.com/purcell/envrc>


2.4 Non-Unix-like systems
─────────────────────────

  I need to know what the appropriate value of `buffer-env-command' is
  for those.  Drop me a line if you can help.


3 Compatibility issues
══════════════════════

  Most Emacs packages are not written with the possibility of a
  buffer-local process environment in mind.  This can lead to issues
  with a few commands; specifically, those which start an external
  process after switching to a different buffer or remote directory.
  Examples include:

  • `shell', `project-shell' (`C-x p s') and other REPLs;
  • `compile' and `project-compile' (`C-x p c') in Emacs 27 and older;
  • `async-shell-command' (`M-&').

  Fortunately, the problem has an easy fix provided by the [inheritenv]
  package, which see.

  Alternatively, if you speak Elisp and want to keep your configuration
  lean, you can just copy the function below and apply it as an
  `:around' advice to any affected commands.

  ┌────
  │ (defun buffer-env-inherit (fn &rest args)
  │   "Call FN with ARGS using the buffer-local process environment.
  │ Intended as an advice around commands that start a process after
  │ switching buffers."
  │   (cl-letf (((default-value 'process-environment) process-environment)
  │ 	    ((default-value 'exec-path) exec-path))
  │     (apply fn args)))
  └────


[inheritenv] <https://github.com/purcell/inheritenv>


4 Related packages
══════════════════

  This package is essentially a knockoff of the [envrc] package by Steve
  Purcell.  The main difference is that envrc depends on and tightly
  integrates with the [direnv] program, while buffer-env is minimalist
  and has no extra dependencies.

  For a comparison of the buffer-local approach to environment variables
  with the global approach used by most of the similar packages, see
  envrc's README.

  There is a large number of Emacs packages interfacing with Python's
  virtualenv system.  They all seem to take the global approach and,
  therefore, the comparisons and caveats in the envrc README also apply,
  mutatis mutandis.


[envrc] <https://github.com/purcell/envrc>

[direnv] <https://direnv.net/>


5 Contributing
══════════════

  Discussions, suggestions and code contributions are welcome! Since
  this package is part of GNU ELPA, nontrivial contributions (above 15
  lines of code) require a copyright assignment to the FSF.
