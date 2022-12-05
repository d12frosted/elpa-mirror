org-calibre-notes is a utility package for importing notes and
highlights made through Calibre Ebook Reader while reading Ebooks
(epub).  It imports the notes to a org file, with heading structure
similar to the chapters/section structure of the ebook and each
note/highlight kept in the corresponding heading.  It also inserts
a Nov.el link to the ebook section so you can jump to the highlight
quickly.

To import: Open ebook in calibre reader then:
Export->Format = calibre highlights -> Copy to Clipboard
Then in Emacs do M-x org-calibre-notes-save
