
########   Compatibility   ########################################

Works with Emacs-23.2.1, 23.1.1

########   Quick start   ########################################

Add to your ~/.emacs

(require 'key-combo)
(key-combo-mode 1)

and some chords, for example

 (key-combo-define-global (kbd "=") '(" = " " == " " === " ))
 (key-combo-define-global (kbd "=>") " => ")

or load default settings

 (key-combo-load-default)
