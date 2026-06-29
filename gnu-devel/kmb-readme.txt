 This library provides the commands `kmb-kill-matching-buffers-no-ask'
 and `kmb-delete-process-and-kill-buffer-no-ask'.  The former kills
 buffers whose name matches a regular expression.  The latter,
 interactively kills the current buffer and if called from Lisp,
 then accepts a list of buffers to kill.
 Any of these commands ask for confirmation to kill the buffers.
 If one of the buffers is running a process, then the process is
 deleted before kill the buffer.

 This file also defines the commands `kmb-list-matching-buffers' and
 `kmb-list-buffers-matching-content' to list the buffers whose name
 or content match a regexp.


 Commands defined here:

  `kmb-delete-process-and-kill-buffer-no-ask',
  `kmb-kill-matching-buffers-no-ask', `kmb-list-buffers-matching-content',
  `kmb-list-matching-buffers'.

 Non-interactive functions defined here:

  `kmb--show-matches'.