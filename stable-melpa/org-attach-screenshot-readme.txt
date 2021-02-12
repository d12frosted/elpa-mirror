allows taking screenshots from within an emacs org buffer by using
the org-attach-screenshot command. The link to the file will be placed at
(point) and org inline images will be turned on to display it.

Screenshots are placed into the org entry's attachment
directory. If no attachment directory has been defined, the user
will be offered choices for creating one or using a directory of an
entry higher up in the hierarchy.

The emacs frame from which the command is issued will hide away
during the screenshot taking, except if a prefix argument has been
given (so to allow taking images of the emacs session itself).

Requires the "import" command from the ImageMagick suite

Put this file into your load-path and the following into your ~/.emacs:
  (require 'org-attach-screenshot)
