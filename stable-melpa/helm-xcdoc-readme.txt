
`helm-xcdoc.el' will be able to view on a eww by searching in the Xcode Document at helm interface


To use this package, add these lines to your init.el or .emacs file:

 (require 'helm-xcdoc)
 (setq helm-xcdoc-command-path "/Applications/Xcode.app/Contents/Developer/usr/bin/docsetutil")
 (setq helm-xcdoc-document-path "~/Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.AppleiOS8.1.iOSLibrary.docset")

----------------------------------------------------------------

to search document
M-x helm-xcdoc-search

to search document with other-window
M-x helm-xcdoc-search-other-window
