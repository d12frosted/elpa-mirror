
`eshell-z.el' is an Emacs port of z(1) <https://github.com/rupa/z>.

It keeps track of where you have been and how many commands you invoke there,
and provides a convenient way to jump to the directories you actually
use.

`eshell-z.el' and z(1) can work together by sharing the same data file.

Usage:

 ~ $ z -h
 usage: z [-chlrtx] [regex1 regex2 ... regexn]

     -c, --current        estrict matches to subdirectories of the current directory
     -h, --help           show a brief help message
     -l, --list           list only
     -r, --rank           match by rank only
     -t, --time           match by recent access only
     -x, --delete         remove the current directory from the datafile

 examples:

     z foo         cd to most frecent dir matching foo
     z foo bar     cd to most frecent dir matching foo, then bar
     z -r foo      cd to highest ranked dir matching foo
     z -t foo      cd to most recently accessed dir matching foo
     z -l foo      list all dirs matching foo (by frecency)

Install:

You can install this package from Melpa and Melpa-stable with package.el,
that is, ~M-x package-install RET eshell-z RET~. Or you can also install it
manually by add eshell-z.el to your `load-path', something like

  (add-to-list 'load-path "path/to/eshell-z.el")

Setup:

To use this package, add following code to your init.el or .emacs

  (add-hook 'eshell-mode-hook
            (defun my-eshell-mode-hook ()
              (require 'eshell-z)))
