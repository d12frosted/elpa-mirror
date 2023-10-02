
The usecase that started this project: I wanted to be able to see
possibly related papers that I've read when I read through the
ArXiv RSS feeds.  I initially wrote a basic command which could be
run manually for each Elfeed article, yet this is somewhat painful.
Thus came `universal-sidecar', and this particular sidecar section.
This extension is fairly simple, and builds on top of the
`bibtex-completion' library, so it's necessary to configure it
appropriately.  Once `bibtex-completion' is configured and the
`elfeed-related-works-section' is added to
`universal-sidecar-sections', if an article's authors have other
works in your Bibtex databases, they will be shown.  Note, however,
that as of now, search is only by author last name.
