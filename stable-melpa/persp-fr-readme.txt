This code is an extension of the `persp-mode' mode that uses your
GUI window title (aka Emacs frame name) to show the list of current
perspectives and indicates the current one.  It also permits to
move the current perspective to the left, right, first or last
position.

Installation:

From the MELPA: M-x package-install RET `persp-fr' RET.

From a file: M-x `package-install-file' RET 'path to this file' RET
Or put this file into your load-path.

Usage:

The same as `persp-mode':

   (require 'persp-fr)    ;; was (require 'persp-mode)
   (persp-fr-start)

Customization:

The customization group lets you tweak few parameters: M-x `customize-group'
RET 'persp-fr' RET.

Useful keys to change to next/previous perspective, as in most user
interfaces using tabs, and to move current perspective to left/right:

    (global-set-key [(control prior)] 'persp-prev)
    (global-set-key [(control next)] 'persp-next)
    (global-set-key [(control meta next)] 'persp-fr-move-right)
    (global-set-key [(control meta prior)] 'persp-fr-move-left)


Tested only under Linux / Gnome.  Feedback welcome!

Thanks to:
   - Naoya Yamashita, for fixing some lint issues
