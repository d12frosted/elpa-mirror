To install the game manually, you need:

- "ducpel.el" (this file);
- "ducpel-glyphs.el" (it generates default images);
- directory with levels.

Add the following to your emacs init file:

  (add-to-list 'load-path "/path/to/ducpel-dir")
  (autoload 'ducpel "ducpel" nil t)

Also if you keep levels separately:

  (setq ducpel-levels-directory "/path/to/ducpel-levels-dir")

After that you can "M-x ducpel" and enjoy.  Use:

- arrow keys to move your man;
- TAB to switch to another man;
- "u" to undo a move;
- SPC to activate a special cell (exit or teleport);
- "R" to restart the level;
- "N"/"P"/"L" to go to the next/previous/particular level.

At any time you can replay your moves by pressing "rc" (2 keys).  If
you feel that a level is impassable, you may surrender (and see a
solution) by pressing "rS".

Contact the maintainer please, if you found a better solution (with
less moves) for some level or if you made an interesting level that
can become a part of ducpel.

For full documentation, see <https://github.com/alezost/ducpel>.
