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

Compared to Org-roam:

  + Compatible (you can use both packages and compare)
  + Fast
  + No SQLite
  + If you want, opt out of those file-level :PROPERTIES: drawers
    + See user option `org-node-prefer-with-heading'
  + Try to rely in a bare-metal way on upstream org-id and org-capture
  + Extra utilities, notably to auto-rename files and links
  + An alternative way to display backlinks

  - No support for "roam:" links
  - Smaller package ecosystem
    + Packages based on org-roam can still work!  Either by using
      org-roam at the same time, or by configuring
      `org-mem-roamy-do-overwrite-real-db' and enabling
      `org-mem-roamy-db-mode'.
  - Blind to TRAMP files (for now)

Compared to Denote:

  + Compatible (you can use both packages and compare)
  + No mandatory filename style (can match Denote format if you like)
  + You can have as many "notes" as you want inside one file.
    + You could possibly use Denote for coarse browsing,
      and Org-node for more granular browsing.

  - No support for "denote:" links
  - No support for Markdown or other file types
  - Blind to TRAMP files (for now)
