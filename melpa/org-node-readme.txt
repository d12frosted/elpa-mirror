If you were the sort of person to prefer "id:" links,
over "file:" links, radio-targets or any other type of link,
you're in the right place!

Now you can worry less about mentally tracking subtree hierarchies
and directory structures.  Once you've assigned an ID to something,
you can find it later.

The philosophy is the same as org-roam: if you assign an ID every
time you make an entry that you know you might want to link to from
elsewhere, then it tends to work out that the `org-node-find' command
can jump to more-or-less every entry you'd ever want to jump to.

That's just the core of it as described to someone not familiar with
zettelkasten-inspired software.  In fact, out of the simplicity
arises something powerful, more to be experienced than explained.

Compared to org-roam:

  + Compatible (you can use both packages and compare)
  + Fast
    + Speedup factor around 500x
  + No SQLite
  + Never again sit through a slow `org-id-update-id-locations'
  + If you want, opt out of those file-level :PROPERTIES: drawers
    + Set `org-node-prefer-with-heading'
  + Try to rely in a bare-metal way on upstream org-id and org-capture
  + Extra utilities, notably to auto-rename files and links
  + An alternative way to display backlinks

  - No support for "roam:" links
  - No `org-roam-db-query'
    - There's an elisp API, but if you're more familiar with SQL,
      it's still a downgrade

Compared to denote:

  + No mandatory filename style (can match Denote format if you like)
  + You can have as many "notes" as you want inside one file.
    + You could possibly use Denote for coarse browsing,
      and org-node for more granular browsing.

  - No support for "denote:" links
  - No support for Markdown or other file types

Finally, an oddity:

Due to relying on the org-id table, if a vendor README.org or other
downloaded Org file has a heading with an ID, it's considered part of
your collection -- simply because of the 1:1 correspondence, that if
it's known to org-id, it's known to org-node.

These headings can be filtered after-the-fact by `org-node-filter-fn',
so that you do not see them in org-node commands.
