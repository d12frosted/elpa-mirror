This package is intended to help in curating and authoring a set of
blog post files for a Hugo-generated website.

Hugo (https://gohugo.io) is an open-source static site generator.
It uses text input files (for example Markdown, Org, AsciiDoc,
Pandoc, or reStructuredText) to generate static web pages.  Unlike
dynamic web content, static pages do not change their content based
on the HTTP request.  Hugo processes a set of such input files in
one file-system tree into a corresponding set of HTML files in
another file system tree.  These HTML files can then be uploaded to
a web server as a website's content.

The hugoista package displays the set of those text input files in
an input file-system tree, which will be processed into blog posts
by Hugo.  It shows them in a list view, grouped by their Hugo
publication status (draft, scheduled, published, and expired) along
with further Hugo metadata associated with each blog post.  Within
each status group, entries can be sorted by date, publication date,
expiration date, or title.  The text input file associated with
each entry can be visited, and a new text input file for a new blog
post can be created using single-key shortcuts.

To show such a list of text input files, call the function
`hugoista'.  It accepts an optional argument, which is the root
directory of a Hugo input file-system tree (that is, the directory
where the `hugo.toml' file for the website is).  Each hugoista
buffer references it own website input directory.  It is thus
possible to have several hugoista buffers open at the same time,
each for a different website input directory.  As a convenience for
when a single website is to be managed only, the optional argument
can be omitted, in which case the directory indicated by
`hugoista-site-dir' will be used as the default website input
directory.

Two operations are provided to act on individual entries.
`hugoista-visit-post' (bound to RET by default), and
`hugoista-new-post' (bound to N and + by default).  Further
operations (for example renaming, or deleting text input files) can
conveniently be performed by other built-in facilities, such as for
example `dired'.