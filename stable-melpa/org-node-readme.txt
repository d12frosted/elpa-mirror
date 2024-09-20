If you were the sort of person to prefer "id:" links over "file:" links or
any other type of link, you're in the right place!  Now you can rely on IDs
and worry less about mentally tracking your subtree hierarchies and
directory structures.  As long as you've assigned an ID to something, you
can find it later.

The philosophy is the same as org-roam: if you assign an ID every time you
make an entry that you know you might want to link to from elsewhere, then
it tends to work out that the `org-node-find' command can jump to more or
less every entry you'd ever want to jump to.  Pretty soon you've forgot that
your files have names.

Anyway, that's just the core of it as described to someone not familiar with
zettelkasten software.  In fact, out of the simplicity arises something
powerful, more to be experienced than explained.

Compared to other systems:

- org-roam: Same idea, compatible disk format(!), but org-node is faster,
  does not depend on SQLite, lets you opt out of file-level property
  drawers, does not support "roam:" links, and tries to rely in a bare-metal
  way on upstream org-id and org-capture.  As a drawback, if a heading in
  some Git README or whatever has an ID, it's considered part of your
  collection -- simply because if it's known to org-id, it's known to
  org-node.  These headings can be filtered after-the-fact.

- denote: Org-node is Org only, no Markdown, no support for "denote:" links.
  Filenames have no meaning (so could match the Denote format if you like),
  and you can have as many "notes" as you want inside one file.  You could
  possibly use Denote to search just files and org-node as a more granular
  search.
