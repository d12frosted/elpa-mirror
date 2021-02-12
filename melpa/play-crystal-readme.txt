https://play.crystal-lang.org/ is a web resource to submit/run/share Crystal code.
This package allows you to use this resource without exiting your favorite Emacs.

Usage:

Run one of the predefined interactive functions.

Insert code identified by RUN-ID into the current buffer:

   (play-crystal-insert RUN-ID)

Insert code identified by RUN-ID into another buffer:

   (play-crystal-insert-another-buffer RUN-ID)

Show code identified by RUN-ID in a browser using ’browse-url’:

   (play-crystal-browse RUN-ID)

Create new run submitting code from the current region:

   (play-crystal-submit-region)

Create new run submitting code from the current buffer:

   (play-crystal-submit-buffer)
