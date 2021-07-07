
PDF Tools is, among other things, a replacement of DocView for PDF
files.  The key difference is, that pages are not prerendered by
e.g. ghostscript and stored in the file-system, but rather created
on-demand and stored in memory.

Note: This package is built and tested on GNU/Linux systems. It
works on macOS and Windows, but is officially supported only on
GNU/Linux systems. This package will not make macOS or Windows
specific functionality changes, behaviour on these systems is
provided as-is.

Note: If you ever update it, you need to restart Emacs afterwards.

To activate the package put

(pdf-tools-install)

somewhere in your .emacs.el .

M-x pdf-tools-help RET

gives some help on using the package and

M-x pdf-tools-customize RET

offers some customization options.

Features:

* View
  View PDF documents in a buffer with DocView-like bindings.

* Isearch
  Interactively search PDF documents like any other buffer. (Though
  there is currently no regexp support.)

* Follow links
  Click on highlighted links, moving to some part of a different
  page, some external file, a website or any other URI.  Links may
  also be followed by keyboard commands.

* Annotations
  Display and list text and markup annotations (like underline),
  edit their contents and attributes (e.g. color), move them around,
  delete them or create new ones and then save the modifications
  back to the PDF file.

* Attachments
  Save files attached to the PDF-file or list them in a dired buffer.

* Outline
  Use imenu or a special buffer to examine and navigate the PDF's
  outline.

* SyncTeX
  Jump from a position on a page directly to the TeX source and
  vice-versa.

* Misc
   + Display PDF's metadata.
   + Mark a region and kill the text from the PDF.
   + Search for occurrences of a string.
   + Keep track of visited pages via a history.
