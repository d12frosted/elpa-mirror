
* Commentary
Bitcoin donations gratefully accepted: 1ArFina3Mi8UDghjarGqATeBgXRDWrsmzo

This library provides extra commands for [[http://www.emacswiki.org/emacs/LookMode][look-mode]] (see below).
In addition if you mark some files in a dired buffer and then run look-at-file (or press M-l),
all of the marked files will be visited in the *look* buffer.
** New commands
- look-dired-do-rename                  : Rename current looked file, to location given by TARGET.
- look-dired-unmark-looked-files        : Unmark all the files in `look-buffer' in the corresponding dired-mode buffer.
- look-dired-mark-looked-files          : Mark all the files in `look-buffer' in the corresponding dired-mode buffer.
- look-dired-mark-current-looked-file   : Mark `look-current-file' in the corresponding dired-mode buffer.
- look-dired-unmark-current-looked-file : Unmark `look-current-file' in the corresponding dired-mode buffer.
- look-dired-run-associated-program     : Run program associated with currently looked at file.

;;
