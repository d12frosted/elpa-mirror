allows taking screenshots from within an Emacs org buffer by using
the org-attach-screenshot command. The link to the file will be placed at
(point) and org inline images will be turned on to display it.

Screenshots are placed into the org entry's attachment
directory. If no attachment directory has been defined, the user
will be offered choices for creating one or using a directory of an
entry higher up in the hierarchy.

The Emacs frame from which the command is issued will hide away
during the screenshot taking, except if a prefix argument has been
given (so to allow taking images of the Emacs session itself).

You can customize the command that is executed for taking the
screenshot. Look at the various customization variables.

Put this file into your load-path and the following into your ~/.emacs:
  (require 'org-attach-screenshot)
