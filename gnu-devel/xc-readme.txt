1 About
═══════

  xc.el provides an Emacs interface for [xc].


[xc] <https://xcfile.dev/>

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

  You can install this package directly from Codeberg like so:

  ┌────
  │ (use-package xc
  │   :vc (:url "https://codeberg.org/ryanprior/xc.el.git" :branch "main"))
  └────

  If you use Spacemacs, you can add this data to your
  `dotspacemacs-additional-packages':

  ┌────
  │ (xc :location (recipe :fetcher codeberg
  │                       :repo "ryanprior/xc.el"))
  └────


  If you would like to help me get this into GNU Elpa, feel free to bug
  me.  (Otherwise I will probably get around to it eventually.)


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
  point to the executable you prefer to use. An absolute path is
  recommended, but a relative path is also permitted, which might be
  handy i.e. as a directory-local variable.


◊ 2.2.1.2 `xc-type'

  When invoked, `xc' will use whichever type of README it finds,
  searching the current directory and then in parents: either
  `README.md' or `README.org'. In a directory that has both files, it
  will prefer Markdown. If you want to limit `xc' to use only one type,
  customize `xc-type' as either "org" or "md".
