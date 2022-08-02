The package adds the =org-journal:= link type to Org Mode.  When
placed in an org-journal file, it serves as a "tag" that references
one or many paragraphs of the journal or the entire section.  These
tags are aggregated in the database that can be queried in various
ways.

The tag format is as follows:
[[org-journal:<kind>:<tag-name>::<number-of-paragraphs>][<tag-description>]]
where the ":<kind>" and "::<number-of-paragraphs>" part is
optional.

Enabling `org-journal-tags-autosync-mode' syncronizes these tags
with the database at the moment of saving the org-journal buffer.

Running `org-journal-tags-status' provides a status buffer with
some statistics about the journal and the used tags.  Running
`org-journal-tags-transient-query' opens a query constructor to
retrieve parts of journal referenced by a particular tag, regular
expression, etc.

Also take a look at the package README at
<https://github.com/SqrtMinusOne/org-journal-tags> for more
information.
