A minor mode to revert buffer for a given time interval.

This is more like `auto-revert-mode' but with a specified time
interval.  see `timer-revert-delay', defaults to 15 seconds.  This is useful
because Emacs' auto-revert-mode doesn't have a facility to tell the
frequency.

My use case is while writing latex documents, background running make needs
some time to finish, usually 5 to 10 seconds.  unlike `auto-revert-mode'
which is very eager to load the file as soon as its modified outside, this
one lazily waits for 15 seconds.  For best experience, if the background
process takes 5 seconds then `timer-revert-delay' should be around 10
seconds.  Okay the logic is not perfect though but minimizes conflicts.
