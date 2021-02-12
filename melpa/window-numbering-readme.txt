
Enable window-numbering-mode and use M-1 through M-0 to navigate.

If you want to affect the numbers, use window-numbering-before-hook or
window-numbering-assign-func.
For instance, to always assign the calculator window the number 9, add the
following to your .emacs:

(setq window-numbering-assign-func
      (lambda () (when (equal (buffer-name) "*Calculator*") 9)))

; Changes Log:

   Fix numbering of minibuffer for recent Emacs versions.

2013-03-23 (1.1.2)
   Fix numbering in terminal mode with menu bar visible.
   Add face for window number.  (thanks to Chen Bin)

2008-04-11 (1.1.1)
   Added possibility to delete window with prefix arg.
   Cleaned up code and migrated to `defcustom'.

2007-02-18 (1.1)
   Added window-numbering-before-hook, window-numbering-assign-func.
