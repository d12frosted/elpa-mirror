;

Mhc is the personal schedule management package.
Please visit http://www.quickhack.net/mhc for details.

Minimum setup:

 (setq load-path
       (cons "~/src/mhc/emacs" load-path))
 (autoload 'mhc "mhc" nil t)
 (autoload 'mhc-import "mhc" nil t)

and M-x mhc
