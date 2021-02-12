
Emacs wrapper for pyopl (python online paper locator) to search and fetch
scientific citations online and add them to a bib file.

; Installation:

  (require 'empos)
  (setq empos-available-engines '("arxiv" "crossref"))
  (setq empos-favorite-engines '("crossref")) <- optional
  (setq empos-bib-file "path/to/bibliography.bib")
  (setq empos-secondary-bib "path/to/a/folder")

 empos-available-engines should contain engines that have been installed in pyopl.
 empos-favorite-engines contains the engines to be used. Note this is a custom variable
   and can be set through customization.
 empos-bib-file is the (absolute) path to the master bibliography file in which the
   references are appended.
 empos-secondary-bib is the (absolute) path to a folder in which the citations are going
   to be added.
