This package defines the Org link type `orgit-file', which can be
used to link to files in Git repositories at specific revisions.

The package integrates with Magit to allow storing links from both
regular file buffers and Magit blob-mode buffers (when viewing
historical file revisions).

Format
------

The link type defined here takes this form:

   orgit-file:/path/to/repo/::REV::FILE  links to FILE at REV

You can optionally add a search option after FILE:

   orgit-file:/path/to/repo/::REV::FILE::SEARCH

Where SEARCH is any Org search string (e.g., a heading, custom ID,
line number, or regex).

Export
------

When an Org file containing such links is exported, then the url of
the remote configured with `orgit-remote' is used to generate a web
url according to `orgit-export-alist'.  That webpage should present
the file content at the specified revision.

Both the remote to be considered the public remote, as well as the
actual web urls can be defined in individual repositories using Git
variables.

To use a remote different from `orgit-remote' but still use
`orgit-export-alist' to generate the web urls, use:

   git config orgit.remote REMOTE-NAME

To explicitly define the web url for files, use something like:

   git config orgit.file http://example.com/repo/blob/%r/%f

Where %r is replaced with the revision and %f with the file path.
