Eev's central idea is that you can keep "executable logs" of what you
do, in a format that is reasonably readable and that is easy to "play
back" later, step by step and in any order. We call these "executable
logs" _e-scripts_. These "steps" are mainly of two kinds:

   1) elisp hyperlinks, and
   2) lines sent to shell-like programs.

To run the tutorial: install this package, then type `M-x
eev-beginner'. This will load all the main modules, activate the
eev-mode keybindings, and open this tutorial,

  http://angg.twu.net/eev-intros/find-eev-quick-intro.html
  (find-eev-quick-intro)

in a sandboxed buffer. The URL aboves points to an HTMLized version of
the sandboxed tutorial, and the `(find-*-intro)' sexp opens it in
Emacs. You can find an index of the other sandboxed tutorials here:

  http://angg.twu.net/eev-intros/find-eev-intro.html
  (find-eev-intro)

The home page of eev is:

  http://angg.twu.net/#eev



Autoloads
=========
Eev handles autoloads in a very atypical way, explained in these three
places:

  http://angg.twu.net/eev-current/eev-load.el.html#autoloads
  http://angg.twu.net/eev-intros/find-eev-install-intro.html#7.3
  http://angg.twu.net/eev-intros/find-eev-intro.html#4
  (find-eev "eev-load.el" "autoloads")
  (find-eev-install-intro "7.3. Autoloads")
  (find-eev-intro "4. The prefix `find-'")

If you load eev in one of these three ways

  1. `M-x eev-beginner'
  2. (require 'eev-beginner)
  3. (require 'eev-load)

then everything will work. If you try to use a package that tries to
bypass autoloads - say, by loading the file that seems to contain the
definition of `eev-foo' when you try to run `M-x eev-foo' - then lots
of things will break. =(



Eev mode
========
Eev mode only activates some keybindings and adds a reminder saying
"eev" to the mode line, as explained here:

  http://angg.twu.net/eev-intros/find-eev-intro.html#1
  (find-eev-intro "1. `eev-mode'")

It is possible to use eev's elisp hyperlink functions with eev-mode
turned off: just put the point on a line with an elisp hyperlink and
type `C-e C-x C-e' to execute it. To load all the main modules of eev
to make its functions available to be used in this way, do this:

  (require 'eev-load)

then you can use `M-x eev-mode' to toggle eev-mode on and off when
desired.
