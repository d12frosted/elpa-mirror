This package is a front end for the command-line program djvused
from DjVuLibre, see https://djvu.sourceforge.net/.  It assumes you
have the programs djvused, djview, ddjvu, and djvm installed.
The main purpose of djvu.el is to edit Djvu documents via djvused.
If you only seek an Emacs viewer for Djvu documents, you may be
better off with DocView shipped with GNU Emacs.  Starting from
GNU Emacs 26, DocView supports Djvu documents.

A Djvu document contains an image layer (typically scanned page images)
as well as multiple textual layers [text (for scanned documents from OCR),
annotations, shared annotations, and bookmarks].  The command-line
program djvused allows one to edit these textual layers via suitable
scripts.  With Djvu mode you can edit and apply these djvused scripts
as if you were directly editing the textual layers of a Djvu document
(though Emacs never visits the Djvu document in the usual Emacs sense
of copying the content of a file into a buffer to manipulate it).
With Djvu mode you can also view the page images of a Djvu document,
yet Djvu mode does not attempt to reinvent the functionality of the
native viewer djview for Djvu documents.  (I find djview very efficient
/ fast for its purposes that also include features like searching the
text layer.)  So Djvu mode supports that you use djview to view the
Djvu document while editing its textual layers.  Djview and Djvu mode
complement each other.

A normal work flow is as follows:

Djvu files are assumed to have the file extension ".djvu".
When you visit the file foo.djvu, it puts you into the (read-only)
buffer foo.djvu.  Normally, this buffer (plus possibly the outline buffer)
is all you need.

The menu bar of this buffer lists most of the commands with their
respective key bindings.  For example, you can:

- Use `g' to go to the page you want.  (Yes, Djvu mode operates on one
  page at a time.  Anything else would be too slow for large documents.)

- Use `v' to (re)start djview using the position in the file foo.djvu
  matching where point is in the buffer foo.djvu.  (I find djview
  fast enough for this, even for larger documents.)

  Yet note also that, starting from its version 4.9, djview reloads
  djvu documents automatically when the djvu file changed on disk.
  So you need not restart it anymore while editing a Djvu document
  with Djvu mode.  (Thank you, Leon Bottou!)

  Djvu mode likewise detects when the file changed on disk
  (say, because the file was modified by some other application),
  so that you can revert the buffers visiting this file.

- To highlight a region in foo.djvu mark the corresponding region
  in the buffer foo.djvu (as usual, `transient-mark-mode' comes handy
  for this).  Then type `h' and add a comment in the minibuffer if you
  like.  Type C-x C-s to save this editing.  View your changes with
  djview.

- Type `i' to enable `djvu-image-mode', a minor mode displaying the
  current page as an image.  Then
    drag-mouse-1 defines a rect area
    S-drag-mouse-1 defines an area where to put a text area,
    C-drag-mouse-1 defines an area where to put a text area w/pushpin.

- Use `o' to switch to the buffer foo.djvu-o displaying the outline
  of the document (provided the document contains bookmarks that you
  can add with Djvu mode).  You can move through a multi-page document
  by selecting a bookmark in the outline buffer.

- The editing of the text, annotation, shared annotation and outline
  (bookmarks) layers really happens in the buffers foo.djvu-t,
  foo.djvu-a, foo-djvu-s, and foo.djvu-b.  The djvused script syntax
  used in these buffers is so close to Lisp that it was natural to give
  these buffers a `djvu-script-mode' that is derived from `lisp-mode'.

  You can check what is happening by switching to these buffers.
  The respective switching commands put point in these buffers
  such that it matches where you were in the main buffer foo.djvu.

  In these buffers, the menu bar lists a few low-level commands
  available for editing these buffers directly.  If you know the
  djvused script syntax, sometimes it can also be helpful to do
  such editing "by hand".

But wait: the syntax in the annotations buffer foo.djvu-a is a
slightly modified djvused script syntax.

- djvused can only highlight rectangles.  So the highlighting of
  larger areas of text must use multiple rectangles (i.e.,
  multiple djvused "mapareas").  To make editing easier, these
  are combined in the buffer foo.djvu-a.  (Before saving these
  things, they are converted using the proper djvused syntax.)

  When you visit a djvu file, Djvu mode recognizes mapareas
  belonging together by checking that "everything else in these
  mapareas except for the rects" is the same.  So if you entered
  a (unique) comment, this allows Djvu mode to combine all the
  mapareas when you visit such a file the second time.  Without a
  comment, this fails!

- djvused uses two different ways of specifying coordinates for
  rectangles
    (1) hidden text uses quadrupels (xmin ymin xmax ymax)
    (2) maparea annotations use (xmin ymin width height)
  Djvu mode always uses quadrupels (xmin ymin xmax ymax)
  Thus maparea coordinates are converted from and to djvused's format
  when reading and writing djvu files.

- Usually Djvu mode operates on the text and annotations layers
  for one page of a Djvu document.  If you really (I mean: REALLY)
  want to edit a raw djvused script for the complete text or
  annotations layer of a djvu document, use `djvu-text-script' or
  `djvu-annot-script' to generate these raw scripts.  When you have
  finished editing, you can re-apply the script by calling
  `djvu-process-script'.  Use this at your own risk.  This code does
  not check whether the raw script is meaningful.  You can loose the
  text or annotations layer if the script is messed up.