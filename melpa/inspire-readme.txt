inspire.el is an Emacs interface for literature and references searching
on the high energy article database inspirehep.net.

Common usage
============

inspire.el provides two main entry functions for searching on inspirehep:
`inspire-literature-search` for literature lookup,
and `inspire-author-search` for author lookup.
inspire.el will then pop-up a list of records where one can browse and examine
detailed information for each record.
The SPIRES syntax (https://help.inspirehep.net/knowledge-base/inspire-paper-search)
is available for `inspire-literature-search` function.

In the record list, use `n` and `p` to navigate through the list.
Other useful commands and their default bindings:
`u` `inspire-open-url` : open the web page associated to the item
`d` `inspire-download-pdf` : download PDF from a selected source
`b` `inspire-export-bibtex-new-buffer` : export the bibTeX entry to a temporary buffer
`B` `inspire-export-bibtex-to-file` : export the bibtex entry to a .bib file
`e` `inspire-download-pdf-export-bibtex` : download PDF and export bibTeX info to a file
`a` `inspire-record-author-lookup` : look up for a author profile in current record
`r` `inspire-reference-search` : look up for references of the current record
`c` `inspire-citation-search` : look up for citations of the current record
`[` `inspire-previous-search`
`]` `inspire-next-search` : navigate through the search history
`q` `inspire-exit` : exit the record list

Some texts in the record or author information buffer are clickable and will preform
corresponding action when clicked upon.
