translation of keyword classes from tools/vim
see http://xahlee.org/emacs/elisp_syntax_coloring.html

Put this in your .emacs file to enable autoloading of lammps-mode
and auto-recognition of "in.*" and "*.lmp" files:

(autoload 'lammps-mode "lammps-mode.el" "LAMMPS mode." t)
(setq auto-mode-alist (append auto-mode-alist
                              '(("in\\." . lammps-mode))
                              '(("\\.lmp\\'" . lammps-mode))
                              ))
