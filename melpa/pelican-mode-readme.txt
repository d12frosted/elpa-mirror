
pelican-mode is an Emacs minor mode for editing articles and pages
in Pelican sites.  Pelican is a static site generator which can
process a variety of text file formats.  For more information, see
URL https://blog.getpelican.com/.

It’s intended to be used alongside a major mode for the Pelican
document.  Currently supported formats are Markdown,
reStructuredText, AsciiDoc, and Org.  It also assumes you’ve set up
Pelican with “pelican-quickstart” or something like it.  In
particular it expects:

 * The existence of “pelicanconf.py” and “Makefile” in some
   ancestor directory.
 * The first component of the path (e.g. “content”) after that
   ancestor is irrelevant.
 * If the next component is “pages”, that indicates a page
   rather than an article.

To enable by default on all text files in a Pelican site:

    (require 'pelican-mode)
    (pelican-global-mode)

Or with ‘use-package’ and deferred loading:

    (use-package pelican-mode
      :demand :after (:any org rst markdown-mode adoc-mode)
      :config
      (pelican-global-mode))

Or, register ‘pelican-mode’ or ‘pelican-mode-enable-if-site’
as hook functions for more direct control.


