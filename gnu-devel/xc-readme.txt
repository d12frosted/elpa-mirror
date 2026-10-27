1 About
═══════

  xc.el is an Emacs interface for [xc], the README-based task runner. It
  provides an "`xc'" command to run some task associated with the
  current buffer. The optional Treemacs integration adds a node for `xc'
  commands to the project's tree.


[xc] <https://github.com/joerdav/xc>

1.1 Action shot
───────────────

  <file:./screenshot-v1.png>


2 To use
════════

  • `M-x' xc `RET' task-name `RET'
    Runs the given task. The set of available tasks is offered for
    completion.
  • In Treemacs, a project with `xc' tasks in its root README will show
    an `[XC TASKS]' list in its tree. To run a task, double-click it, or
    move point to your desired task and press `RET'. See the action shot
    above for an example, and "Configuration" below for instructions to
    enable the Treemacs integration.


2.1 Installation instructions
─────────────────────────────

  xc.el is part of GNU Emacs and you can install it [from ELPA] by
  running `M-x' package-install `RET' xc `RET' or by adding
  `(use-package xc)' to your init.


[from ELPA] <https://elpa.gnu.org/packages/xc.html>


2.2 Configuration
─────────────────

  ┌────
  │ ;; Recommended: bind to keyboard
  │ (bind-key "C-c x" #'xc)
  │ 
  │ ;; If you use Treemacs, initialize the integration:
  │ (with-eval-after-load 'treemacs
  │   (require 'xc-treemacs))
  └────


2.2.1 Customization options
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

◊ 2.2.1.1 `xc-executable'

  By default, the package will use whatever `xc' is found on your
  `PATH'. If that's not what you want, customize `xc-executable' to
  point to the executable you prefer to use.


◊ 2.2.1.2 `xc-type'

  When invoked, `xc' will use whichever type of README it finds,
  searching the current directory and then in parents: either
  `README.md' or `README.org'. In a directory that has both files, it
  will prefer Markdown. If you want to limit `xc' to use only one type,
  customize `xc-type' as either "org" or "md".
