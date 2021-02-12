This package defines the Org link types `orgit', `orgit-rev', and
`orgit-log', which can be used to link to Magit status, revision,
and log buffers.

Use the command `org-store-link' in such a buffer to store a link.
Later you can insert that into an Org buffer using the command
`org-insert-link'.

Alternatively you can use `org-insert-link' to insert a link
without first storing it.  When prompted, first enter just the
link type followed by a colon and press RET.  Then you are
prompted again and can provide the repository with completion.
The `orgit-rev' and `orgit-log' types additionally read a revision,
again with completion.

Format
------

The three link types defined here take these forms:

   orgit:/path/to/repo/            links to a `magit-status' buffer
   orgit-rev:/path/to/repo/::REV   links to a `magit-revision' buffer
   orgit-log:/path/to/repo/::ARGS  links to a `magit-log' buffer

Before v1.3.0 only the first revision was stored in `orgit-log'
links, and all other revisions were discarded.  All other arguments
were also discarded and Magit's usual mechanism for determining the
switches and options was used instead.

For backward compatibility, and because it is the common case and
looks best, ARGS by default has the form REV as before.  However if
linking to a log buffer that shows the log for multiple revisions,
then ("REV"...) is used instead.  If `orgit-log-save-arguments' is
non-nil, then (("REV"...) ("ARG"...) [("FILE"...)]) is always used,
which allows restoring the buffer most faithfully.

Export
------

When an Org file containing such links is exported, then the url of
the remote configured with `orgit-remote' is used to generate a web
url according to `orgit-export-alist'.  That webpage should present
approximately the same information as the Magit buffer would.

Both the remote to be considered the public remote, as well as the
actual web urls can be defined in individual repositories using Git
variables.

To use a remote different from `orgit-remote' but still use
`orgit-export-alist' to generate the web urls, use:

   git config orgit.remote REMOTE-NAME

To explicitly define the web urls, use something like:

   git config orgit.status http://example.com/repo/overview
   git config orgit.rev http://example.com/repo/revision/%r
   git config orgit.log http://example.com/repo/history/%r
