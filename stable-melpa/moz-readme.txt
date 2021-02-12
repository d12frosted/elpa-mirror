
This file implements communication with Firefox via MozRepl
(http://hyperstruct.net/projects/mozrepl).  It is a slightly
modified version of the file moz.el that comes with MozLab.  To use
it you have to install the MozRepl addon in Firefox.

This file contains

  * a major mode for direct interaction in a buffer (as with
    telnet) with MozRepl, `inferior-moz-mode'.
  * a minor mode for sending code portions or whole files from
    other buffers to MozRepl, `moz-minor-mode'.

Assuming you want to use javascript-mode to edit Javascript files,
enter the following in your .emacs initialization file (from Emacs
integration in the help text):

  (add-to-list 'auto-mode-alist '("\\.js$" . javascript-mode))
  (autoload 'inferior-moz-mode "moz" "MozRepl Inferior Mode" t)
  (autoload 'moz-minor-mode "moz" "MozRepl Minor Mode" t)
  (add-hook 'javascript-mode-hook 'javascript-moz-setup)
  (defun javascript-moz-setup () (moz-minor-mode 1))

Replace javascript-mode above with the name of your favorite
javascript mode.

If you got this with nXhtml the setup above is already done for
you.

*Note 1* You have to start the MozRepl server in Firefox (or
 whatever Mozilla browser you use). From the menus do

   Tools - MozRepl - Start

*Note 2* For clearness and brevity the documentation says Firefox
 where the correct term should rather be "your Mozilla web
 browser".
