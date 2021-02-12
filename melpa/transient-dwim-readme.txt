Using transient to display the preconfigured transient dispatcher
for your situation (major-mode or installed packages).

By installing this package, if you want to know what features
exist in major-mode for the first time, or if you want to use
a package you can't remember keybindings for, pressing M-= (if
you're using the recommended settings) will be your first step.

You don't have to remember the cumbersome keybindings since
now.  Just look at the neatly aligned menu and press the key
that appears.

To use this package, simply add below code to your init.el:
  (define-key global-map (kbd "M-=") 'transient-dwim-dispatch)
