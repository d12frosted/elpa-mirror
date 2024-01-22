
EBDB records for MUA buffers can be displayed using Universal
Sidecar.  As of now, it only supports `message-mode',
`gnus-article-mode' and `gnus-summary-mode' (patches welcome to
support others, though I suspect it's just the major mode names
that need set).  To use this section, add `ebdb-mua-sidecar' to
your `universal-sidecar-sections', and have
`ebdb-mua-sidecar-insinuate' run somewhere in your init.

The following options are available:

 - `:header' allows you to change the header of the section from
   the default "Addressees:".
 - `:updatep' (default 'existing), determines how records are
   updated (see also `ebdb-update-records').
 - `:formatter' (default `ebdb-default-multiline-formatter')
   determines how records are formatted.  This should be an
   instance of `ebdb-record-formatter'.
