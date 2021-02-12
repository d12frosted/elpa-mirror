This package implements an extension to org-mode that synchronizes
org document with external services.  It provides an interface that
can be implemented in backends.  The current focus is on
bugtrackers services.

The entry points are `org-sync-import', `org-sync' and `org-sync-or-import'.
The first one prompts for an URL to import, the second one pulls, merges and
pushes every buglist in the current buffer and the third one
combines the others in one function: if nothing in the buffer can
be synchronized, ask for an URL to import.

The usual workflow is to first import your buglist with
`org-sync-import', modify it or add a bug and run `org-sync'.

A buglist is a top-level headline which has a :url: in its
PROPERTIES block.  This headline is composed of a list of
subheadlines which correspond to bugs.  The requirement for a bug
is to have a state, a title and an id.  If you add a new bug, it
wont have an id but it will get one once you sync.  If you omit the
status, OPEN is chose.

The status is an org TODO state.  It can either be OPEN or CLOSED.
The title is just the title of the headline.  The id is a number in
the PROPERTIES block of the headline.

Org DEADLINE timestamp are also handled and can be inserted in a
bug headline which can then be used by the backend if it supports
it.

Paragraphs under bug-headlines are considered as their description.
Additional data used by the backend are in the PROPERTIES block of
the bug.

To add a bug, just insert a new headline under the buglist you want
to modify e.g.:
    ** OPEN my new bug
Then simply call `org-sync'.
