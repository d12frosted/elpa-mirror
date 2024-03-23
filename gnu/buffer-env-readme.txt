            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             BUFFER-ENV — BUFFER-LOCAL PROCESS ENVIRONMENTS
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


With this package, you can teach Emacs to call the correct version of
external programs such as linters, compilers and language servers on a
/per-project/ basis.  Thus you can work on several projects in parallel
with no undue interference and switch seamlessly between them.


1 Basic setup
═════════════

1.1 On the project side
───────────────────────

  Your project settings should go into a shell script named `.envrc'
  which exports a suitable `PATH', as well as any other desired
  environment variables.  Place this script at the root directory of
  your project.

  This follows the approach of the popular [direnv] program, and is
  mostly compatible with it.  However, buffer-env is entirely
  independent of direnv so it is not possible to use direnv-specific
  features in the `.envrc' scripts — at least not directly.

  Alternatively, it is possible to configure buffer-env to directly
  support other environment setup methods, such as Python virtualenvs,
  `.env' files or certain build tools.  See below for details.


[direnv] <https://direnv.net/>


1.2 On the Emacs side
─────────────────────

  The usual way to activate this package in Emacs is by including the
  following in your init file:

  ┌────
  │ (add-hook 'hack-local-variables-hook #'buffer-env-update)
  │ (add-hook 'comint-mode-hook #'buffer-env-update)
  └────

  In this way, any buffer potentially affected by [directory-local
  variables], as well as Comint buffers, will also be affected by
  buffer-env.  It is also possible to add `buffer-env-update' only to
  specific major-mode hooks, or call it interactively.


[directory-local variables]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Directory-Variables.html>


2 How this package works
════════════════════════

  When called interactively, `buffer-env-update' asks for a script file
  and executes it (in the sense detailed below).  The role of the script
  is to set some environment variables.  Then the Emacs variables
  `process-environment' and `exec-path' are made buffer-local and their
  values are set so as to replicate the environment defined by the
  script.

  When `buffer-env-update' is called from a hook, a file named
  `buffer-env-script-name' is looked up in the current directory or one
  of its parents.  If found, the same procedure as in the interactive
  case takes place.  Otherwise, nothing happens.

  It remains to clarify what “executing a script” means in the
  paragraphs above.  Normally, it simply means to execute the script as
  a shell script and collect all the exported variables.  However,
  certain script names are treated specially.  These are:

  • `.env': These files, used by Docker, Node.js and others, are simple
    lists of `VARIABLE=value' pairs.  They are still executed as shell
    scripts (which dictates when and how quotes are to be used, for
    instance), but no `export' statements are needed.
  • `guix.scm' and `manifest.scm': The development environment of the
    Guix package is loaded and exported to Emacs.  Make sure you have
    entered `guix shell' at least once before to install the
    dependencies, otherwise you may block Emacs for a long time.
  • `flake.nix' and `shell.nix': These files are used by the Nix package
    manager and are handled similarly to Guix.
  • `pyproject.toml': If you are using [Poetry], [Hatch] or [PDM],
    buffer-env can infer the project environment from them.
  • `*.ps1': Similar to a regular shell script, but interpreted by
    PowerShell.

  For instructions on how to extend this list, see the documentation of
  the variable `buffer-env-command-alist'.


[Poetry] <https://python-poetry.org/>

[Hatch] <https://hatch.pypa.io/>

[PDM] <https://pdm.fming.dev>


3 Integration with other environment management mechanisms
══════════════════════════════════════════════════════════

3.1 Python virtualenvs
──────────────────────

  In most cases, the easiest way to interface with Python virtualenvs is
  to create an `.envrc' file with the following contents:

  ┌────
  │ source path-to-virtualenv/bin/activate
  └────

  You can also call `buffer-env-update' interactively and select the
  `activate' script directly.

  However, if you want to avoid writing `.envrc' scripts and you create
  virtualenvs in a predictable place, say in a `.venv' directory at the
  root of each project, you can say

  ┌────
  │ (setq buffer-env-script-name ".venv/bin/activate")
  │ ;; alternatively, try to find a .envrc file first
  │ (setq buffer-env-script-name '(".envrc" ".venv/bin/activate"))
  └────

  Note that it is also possible to provide an absolute path for
  `buffer-env-script-name', and it is possible to specify it as a
  buffer- or directory-local variable.


3.2 .env files
──────────────

  To load the environment defined by a `.env' file, you can select it
  interactively with `buffer-env-update'.  To automate the process, set
  `buffer-env-script-name' to `".env"', either globally, dir-locally or
  buffer-locally.


3.3 Direnv
──────────

  Buffer-env is /mostly/ compatible with direnv; specifically, it
  assumes `.envrc' is a regular shell script, so you can't directly use
  anything from direnv's library of helper functions.  A workaround is
  to use the following configuration:

  ┌────
  │ (with-eval-after-load 'buffer-env
  │   (add-to-list 'buffer-env-command-alist '("/\\.envrc\\'" . "direnv exec . env -0")))
  └────

  If you need tighter integration with direnv, you may want to check out
  the [envrc] package.


[envrc] <https://github.com/purcell/envrc>


4 Compatibility issues
══════════════════════

  Most Emacs packages are not written with the possibility of a
  buffer-local process environment in mind.  This leads to issues with a
  few commands; specifically, those which start an external process
  after switching to a different buffer or remote directory.  Examples
  include:

  • `compile' and `project-compile' (`C-x p c') in Emacs 27 and older,
  • `async-shell-command' (`M-&').

  Fortunately, the problem has an easy fix provided by the [inheritenv]
  package, which see.

  Alternatively, if you speak Elisp and want to keep your configuration
  lean, you can just copy the function below and apply it as an
  `:around' advice to any affected commands.

  ┌────
  │ (eval-when-compile (require 'cl-lib))
  │ (defun buffer-env-inherit (fn &rest args)
  │   "Call FN with ARGS using the buffer-local process environment.
  │ Intended as an advice around commands that start a process after
  │ switching buffers."
  │   (cl-letf (((default-value 'process-environment) process-environment)
  │ 	    ((default-value 'exec-path) exec-path))
  │     (apply fn args)))
  └────


[inheritenv] <https://github.com/purcell/inheritenv>


5 Related packages
══════════════════

  This package is essentially a knockoff of the [envrc] package by Steve
  Purcell.  The main difference is that envrc depends on and tightly
  integrates with the [direnv] program, while buffer-env is minimalist
  and has no extra dependencies.

  For a comparison of the buffer-local approach to environment variables
  with the global approach used by most of the similar packages, see
  [envrc's design notes].

  There is a large number of Emacs packages interfacing with the Python
  virtualenv system.  They all seem to take the global approach and,
  therefore, the comparisons and caveats in the envrc design notes also
  apply, mutatis mutandis.


[envrc] <https://github.com/purcell/envrc>

[direnv] <https://direnv.net/>

[envrc's design notes] <https://github.com/purcell/envrc#design-notes>


6 Contributing
══════════════

  Discussions, suggestions and code contributions are welcome! Since
  this package is part of GNU ELPA, contributions require a copyright
  assignment to the FSF.
