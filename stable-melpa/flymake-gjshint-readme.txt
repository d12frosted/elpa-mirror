Usage:

Add to your Emacs config:

  (require 'flymake-gjshint)
  (add-hook 'js-mode-hook 'flymake-gjshint:load)


If you want to disable flymake-gjshint in a certain directory
(e.g. test code directory), set flymake-gjshint to nil in `.dir-locals.el'.

Here’s an example of a `.dir-locals.el' file:
-----------------------------------
((nil . ((flymake-gjshint . nil))))
-----------------------------------

Command:

The following command is defined:

* `flymake-gjshint:fixjsstyle'
  Fix many of the glslint errors in current buffer by fixjsstyle.
