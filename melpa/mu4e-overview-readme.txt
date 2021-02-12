This package lets you see a hierarchy of maildirs in a separate buffer:

mymail@gmail.com
 [Gmail]
  .Trash [0/25]
  .Starred [0/0]
  .Spam [0/3]
  .Sent Mail [0/4]
  .Important [0/21]
  .Drafts [0/0]
  .All Mail [0/56]
 Trash [0/0]
 Inbox [2/45]

M-x `mu4e-overview' displays a buffer with a list of all maildirs.  The root
maildir can be set via the variable `mu4e-maildir'.

The number of unread and total number of emails is displayed next to each
maildir in this format: [UNREAD-COUNT/TOTAL-COUNT].  If UNREAD-COUNT is not
zero, that maildir is highlighted.

Use n and p keys to go to next/previous maildir (or alternatively,
tab/backtab).  Use [ and ] keys to go to previous/next *unread* maildir.

When you click on a maildir or type RET when point is on it, mu4e headers
view is displayed, which shows messages only in that maildir.  Type C-u RET
to show only unread messages.
