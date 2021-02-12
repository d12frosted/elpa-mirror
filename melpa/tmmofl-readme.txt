
This code is used to run to functions depending on whether the
current font-lock font is at point.  As font-lock is usually
syntactically meaningful this means that you can for instance
toggle minor modes on and off depending on the current syntax.

To install this software place this file and the tmmofl-x.el file
into your load path and place

(require 'tmmofl)

if your .emacs.

To switch on this minor mode use the command tmmofl-mode.  The mode
line will indicate that the mode is switched on.  What this actually
does will depend on what the main mode of the current buffer
is.  The default behaviour is to switch `auto-fill' mode on when
point is within comments, and off when its in anything else.


; Notes for developers:
~/src/ht/home_website/
There are actually two ways to use this mode, firstly as a minor
mode. Default behaviour is to toggle auto-fill on and off, but you
might want additional behaviour. To do this you define a variable called
`tmmofl-MODENAME-actions' where mode name is the name for mode as
returned by the `major-mode' variable. This variable is as
follows...

(defvar tmmofl-jde-mode-actions
 '(
   (font-lock-comment-face
    (lambda()
      (progn
        (abbrev-mode 0)
        (auto-fill-mode 1)))
    (lambda()
      (progn
        (abbrev-mode 1)
        (auto-fill-mode 0))))

   (font-lock-string-face
    (lambda()
      (abbrev-mode 0))
    (lambda()
      (abbrev-mode 1)))))

This is a list each element of which is a list defining the
font-lock-symbol to be acted on, the on function, and the off
function. If tmmofl can not find this variable the default of...

(defvar tmmofl-default-actions
     '(
       (font-lock-comment-face
        (lambda()
          (auto-fill-mode 1))
        (lambda()
          (auto-fill-mode 0)))))

can be used instead, which toggles auto fill on and off when on of
off comments. There are some sample action variables defined in
tmmofl-x.el which you may load if you wish.

The second way to use this mode is outside of the tmmofl minor
mode. For instance say you wanted emacs to display the fully
referenced name of a class every time you moved point on top of a
Type declaration in Java code. If you had a function called
`java-show-full-class-name' (which I dont before you ask) you might
want to use tmmofl to call this function. To do this you would use
the `tmmofl-install-for-mode' function like so...

(tmmofl-install-for-mode
java-mode-hook
font-lock-type-face
(lambda()
  (java-show-full-class-name))
(lambda()
  ()))

where the first argument is the install hook. This would work
without showing the tmmofl mode information in the mode line. I am
fairly sure that this should work independantely of `tmmofl-mode'.

The software was designed, written and tested on win 95, using
NTEmacs. It has since been rewritten on a Gnu/Linux system. Please
let me know if it works elsewhere. The current version should be
available at http://www.bioinf.man.ac.uk/~lord


; Acknowledgements:

This code has grown up over about a year. It originally started off
as jde-auto-abbrev. I would like to thank Joakim Verona
(joakim@verona.se) who sent me the code which did part of what
tmmofl does (toggled abbrev mode!). He used `defadvice' on
`put-text-property'. I got the idea for using `post-command-hook'
from Gerd Neugebauer's multi-mode.el.
Finally Stefan Monnier who gave me lots of good advice about both
the overall structure of the file, and some specific problems I
had. Thanks a lot. Much appreciated.

TODO

More stuff in tmmofl-x.el, but at the moment its working quite
nicely.
