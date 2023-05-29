Simple treemacs backend for project.el

;; Installation

;;; MELPA

If you installed from MELPA, you're done.

;;; Manual

Install these required packages:

`treemacs'

Then put this file in your load-path, and put this in your init
file:

(require 'project-treemacs)

Or using `use-package':

(use-package project-treemacs
  :demand t
  :after treemacs
  :load-path "path/to/project-treemacs")

;; Usage

Enable the backend with `project-treemacs-mode'
With the `treemacs' side panel visible, use any of the `project.el'
project management commands as you normally would.

Treemacs projects map to project.el projects
Treemacs workspaces map project.el projects + project external roots

`project-find-file', `project-switch-to-buffer', `project-find-regexp' et al
operate on the current treemacs project.

`project-or-external-find-file', and `project-or-external-find-regexp'
operate on the current treemacs workspace.

;; Tips
You can customize settings in the `project-treemacs' group.
