This package lets users conveniently modify PDF metadata, labels, and
bookmarks within Emacs.  Metadata is retrieved from PDFs using the pdftk CLI
tool.  Therefore, a dependency for this package is a pdftk binary.  This
package has only been tested in Linux.

USAGE:

Open a PDF file (in any major mode) and call `pdf-meta-edit-modify'.  This
creates and opens a `pdf-meta-edit-mode' buffer whose contents is a
plain-text representation of the metadata of that PDF.  Edit the contents of
this buffer.  Once done, "commit" the buffer contents to the PDF file via C-c
C-c, which calls `pdf-meta-edit-commit'.

The metadata of a PDF file includes bookmarks (outline), labels (document
pagination), page information, and other information.  The representation of
this metadata is composed of subsections.  For instance, information
pertaining to a bookmark subsection includes fields for the pdf page number,
the level of the bookmark, and the title of the bookmark.  Pdf-meta-edit
provides commands to conveniently add new bookmark and label subsections: see
`pdf-meta-edit-bookmark-subsection' and `pdf-meta-edit-label-subsection'.
For a thorough documentation of the representation of PDF metadata and
possible fields and values, see the cpdf manual:
https://github.com/johnwhitington/cpdf-source/blob/master/cpdfmanual.pdf.
