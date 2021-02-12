This program is a comint mode for Emacs which allows you to run a
compatible javascript repl like Node.js/Spidermonkey/Rhino inside Emacs.
It also defines a few functions for sending javascript input to it
quickly.

Usage:
 Put js-comint.el in your load path
 Add (require 'js-comint) to your .emacs or ~/.emacs.d/init.el

 Optionally, set the `js-comint-program-command' string
 and the `js-comint-program-arguments' list to the executable that runs
 the JS interpreter and the arguments to pass to it respectively.
 For example, on windows you might need below setup:
   (setq js-comint-program-command "C:/Program Files/nodejs/node.exe")

 After setup, do: `M-x js-comint-repl'
 Away you go.
 `node_modules' is *automatically* searched and appended into environment
 variable `NODE_PATH'.  So 3rd party javascript is usable out of box.

 If you have nvm, you can select the versions of node.js installed and run
 them.  This is done thanks to nvm.el.
 Please note nvm.el is optional.  So you need *manually* install it.
 To enable nvm support, run `js-do-use-nvm'.
 The first time you start the JS interpreter with `js-comint-repl', you will
be asked to select a version of Node.js
 If you want to change version of node js, run `js-comint-select-node-version'

 `js-comint-clear' clears the content of REPL.

You may get cleaner output by following setup (highly recommended):

 Output matching `js-comint-drop-regexp' will be dropped silently

 You can add the following lines to your .emacs to take advantage of
 cool keybindings for sending things to the javascript interpreter inside
 of Steve Yegge's most excellent js2-mode.

  (add-hook 'js2-mode-hook
            (lambda ()
              (local-set-key (kbd "C-x C-e") 'js-send-last-sexp)
              (local-set-key (kbd "C-c b") 'js-send-buffer)))
