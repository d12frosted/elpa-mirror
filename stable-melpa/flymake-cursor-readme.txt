
Additional functionality that makes flymake error messages appear
in the minibuffer when point is on a line containing a flymake
error. This saves having to mouse over the error, which is a
keyboard user's annoyance.

-------------------------------------------------------

This flymake-cursor module displays the flymake error in the
minibuffer, after a short delay.  It is based on code I found roaming
around on the net, unsigned and unattributed. I suppose it's public
domain, because, while there is a "License" listed in it, there
is no license holder, no one to own the license.

This version is modified slightly from that code. The post-command fn
defined in this code does not display the message directly. Instead
it sets a timer, and when the timer fires, the timer event function
displays the message.

The reason to do this: the error message is displayed only if the
user doesn't do anything, for about one second. This way, if the user
scrolls through a buffer and there are myriad errors, the minibuffer
is not constantly being updated.

If the user moves away from the line with the flymake error message
before the timer expires, then no error is displayed in the minibuffer.

I've also updated the names of the defuns. They all start with flyc now.
