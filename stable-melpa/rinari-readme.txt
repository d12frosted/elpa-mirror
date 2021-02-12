Rinari Is Not A Ruby IDE.

Well, ok it kind of is.  Rinari is a set of Emacs Lisp modes that is
aimed towards making Emacs into a top-notch Ruby and Rails
development environment.

Rinari can be installed through ELPA (see http://tromey.com/elpa/)

To install from source, copy the directory containing this file
into your Emacs Lisp directory, assumed here to be ~/.emacs.d.  Add
these lines of code to your .emacs file:

;; rinari
(add-to-list 'load-path "~/.emacs.d/rinari")
(require 'rinari)
(global-rinari-mode)

Whether installed through ELPA or from source you probably want to
add the following lines to your .emacs file:

;; ido
(require 'ido)
(ido-mode t)

Note: if you cloned this from a git repo, you will have to grab the
submodules which can be done by running the following commands from
the root of the rinari directory

 git submodule init
 git submodule update
