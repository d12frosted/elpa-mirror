 Emacs Grails mode with Projectile for project-management.
   - You can run pre-defined or arbitrary Grails commans for a project.
   - You can also search service, domain or controller files against the current file or project.
   - You can browse documentation (wiki, guide, apidocs).
   - You can search plugins by tag or query string.
   - Menubar contributions if you make use of the menubar.
   - The default keymap prefix is `C-c ;` (see `grails-projectile-keymap-prefix`)

You can customize the mode using `M-x customize-group` [RET] grails-projectile.

Add the folder containing grails-projectile-mode.el in your load-path
(add-to-list 'load-path "~/.emacs.d/lisp/")

(require 'grails-projectile-mode)
(grails-projectile-global-mode t)

All the commands start with 'grails-projectile'
From a projectile managed buffer run `M-x grails-projectile-compile [RET]`
to compile your Grails application.

To list keybindings press `C-h b` or type `M-x describe-mode`
Then search for grails-projectile-mode.

There is integration with discover.el when it's available for easier
navigation between commands without resorting to muscle memory for keybindings.

; Change log: Split package into separate files.
