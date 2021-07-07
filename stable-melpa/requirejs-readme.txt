This module allows you to:
 - Sort a define block
  - define rules about how to sort shims/aliases
 - Helps you add new define paths to a define block
  - which uses the above sorting functionality when any arbitrary line is added to the path array.
 - Allows you to jump to a module under your cursor as long as it exists in the same requirejs project.

installation: put this file under an Emacs Lisp directory, then include this file (require 'requirejs)
 Usage:
Here is a sample configuration that may be helpful to get going.

(setq requirejs-require-base "~/path/to/your/project")
(requirejs-add-alias "jquery" "$" "path/to/jquery-<version>.js")

(add-hook 'js2-mode-hook
          '(lambda ()
             (local-set-key [(super a) ?s ?r ] 'requirejs-sort-require-paths)
             (local-set-key [(super a) ?a ?r ] 'requirejs-add-to-define)
             (local-set-key [(super a) ?r ?j ] 'requirejs-jump-to-module)
             ))


(setq requirejs-define-header-hook
      '(lambda ()
         (insert
          (format "// (c) Copyright %s ACME, Inc.  All rights reserved.\n"
                  (format-time-string "%Y")))))
