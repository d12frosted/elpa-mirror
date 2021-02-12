
Goto Last Change

Goto the point of the most recent edit in the buffer.
When repeated, goto the second most recent edit, etc.
Negative argument, C-u -, for reverse direction.
Works by looking into buffer-undo-list to find points of edit.

You would probably like to bind this command to a key.
For example in your ~/.emacs:

  (require 'goto-chg)

  (global-set-key [(control ?.)] 'goto-last-change)
  (global-set-key [(control ?,)] 'goto-last-change-reverse)

Works with emacs-19.29, 19.31, 20.3, 20.7, 21.1, 21.4, 22.1 and 23.1
Works with XEmacs-20.4 and 21.4 (but see todo about `last-command' below)

--------------------------------------------------------------------
History

Ver 1.7.3 2019-01-07 Vasilij Schneidermann
   Fix errors when used with persistent undo
Ver 1.7.2 2018-01-05 Vasilij Schneidermann
   Fix byte-compiler warnings again
Ver 1.7.1 2017-12-31 Vasilij Schneidermann
   Fix byte-compiler warnings
Ver 1.7 2017-09-17 Vasilij Schneidermann
   Make it work with undo-tree-mode (see
   <https://github.com/martinp26/goto-chg>)
Ver 1.6 2013-12-12 David Andersson
   Add keywords; Cleanup comments
Ver 1.5 2013-12-11 David Andersson
   Autoload and document `goto-last-change-reverse'
Ver 1.4 2008-09-20 David Andersson
   Improved property change description; Update comments.
Ver 1.3 2007-03-14 David Andersson
   Added `goto-last-change-reverse'
Ver 1.2 2003-04-06 David Andersson
   Don't let repeating error depthen glc-probe-depth.
Ver 1.1 2003-04-06 David Andersson
   Zero arg describe changes. Negative arg go back.
   Autoload. Remove message using nil in stead of an empty string.
Ver 1.0 2002-05-18 David Andersson
   Initial version

--------------------------------------------------------------------

todo: Rename "goto-chg.el" -> "gotochange.el" or "goto-chgs" ?
todo: Rename function goto-last-change -> goto-last-edit ?
todo: Rename adjective "-last-" -> "-latest-" or "-most-recent-" ?
todo: There are some, maybe useful, funcs  for region undo
      in simple.el in emacs 20. Take a look.
todo: Add functionality to visit changed point in text order, not only in
       chronological order. (Naa, highlight-changes-mode does that).
todo: Inverse indication that a change has been saved or not
todo: Highlight the range of text involved in the last change?
todo: See session-jump-to-last-change in session.el?
todo: Unhide invisible text (e.g. outline mode) like isearch do.
todo: XEmacs sets last-command to `t' after an error, so you cannot reverse
       after "No furter change info". Should we bother?
todo: Try distinguish "No further change info" (end of truncated undo list)
       and "No further changes" (end of a complete undo list).

--------------------------------------------------------------------
