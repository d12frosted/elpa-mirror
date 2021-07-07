Quick intro

To install, put this file (as well as maxima-font-lock.el)
somewhere in your Emacs load path.
To make sure that `maxima.el' is loaded when necessary, whether to
edit a file in maxima mode or interact with Maxima in an Emacs buffer,
put the lines
 (autoload 'maxima-mode "maxima" "Maxima mode" t)
 (autoload 'maxima "maxima" "Maxima interaction" t)
in your `.emacs' file.  If you want any file ending in `.mac' to begin
in `maxima-mode', for example, put the line
 (setq auto-mode-alist (cons '("\\.mac" . maxima-mode) auto-mode-alist))
to your `.emacs' file.
