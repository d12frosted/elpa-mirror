Interact with Bundler from Emacs.

1) bundle-open

   Wraps 'bundle open' which, if the given gem is installed and has been
   required correctly, will open the gem's source directory with dired.

2) bundle-console

   Starts an inferior ruby process in the context of the current bundle
   using 'bundle console' (requires inf-ruby to be installed).

3) bundle-install, bundle-update, bundle-check

   Runs the corresponding Bundler command with async-shell-command and
   *Bundler* as the target buffer. This exists so the output won't mess
   with the default buffer used by M-& and async-shell-command.

; Install

$ cd ~/.emacs.d/vendor
$ git clone git://github.com/endofunky/bundler.el.git

In your emacs config:

(add-to-list 'load-path "~/.emacs.d/vendor/bundler.el")
(require 'bundler)
