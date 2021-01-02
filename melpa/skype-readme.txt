Improving Skype GUI.
This is under development...

To use this program, locate this file to load-path directory,
and add the following code to your .emacs.
------------------------------
(require 'skype)
(setq skype--my-user-handle "your skype account")
------------------------------
If you have anything.el, bind `skype--anything-command' to key,
like (global-set-key (kbd "M-9") 'skype--anything-command).
