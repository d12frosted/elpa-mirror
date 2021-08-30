Side Car Locals supports out-of-source locals,
in a way that makes it easy to manage locals for a project
without having to keep track of files inside your project,
which may not be in version control.
This means your local code can be conveniently versioned separately.

Besides this, there are some other differences with the built-in `dir-locals'.

- Trust is managed by paths with
  `sidecar-locals-paths-allow' and `sidecar-locals-paths-deny'.
- The files are evaluated instead of looking up individual variables.
- It's up to the scripts to set local variables e.g. `setq-local',
  and avoid changes to the global state in a way that might cause unexpected behavior.


; Usage


Write the following code to your .emacs file:

  (require 'sidecar-locals)
  (sidecar-locals-mode)
  (setq sidecar-locals-paths-allow '("/my/trusted/path/" "/other/path/*"))

Or with `use-package':

  (use-package sidecar-locals
    :config
    (setq sidecar-locals-paths-allow '("/my/trusted/path/" "/other/path/*")))
  (sidecar-locals-mode)
