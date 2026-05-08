Elfeed is a web feed client for Emacs, which supports Atom and RSS
feeds.

After installation of Elfeed from a package archive, invoke M-x
elfeed to open the Elfeed search buffer.  The list of feeds can be
configured in your user configuration.

    (setq elfeed-feeds
      '(("http://nullprogram.com/feed/" blog emacs)
        "http://www.50ply.com/atom.xml" ;; no autotagging
        ("http://nedroid.com/feed/" webcomic)))

For the start a few basic commands suffice.  Inside the search
buffer press G to refresh the feeds, s to live filter the entries,
or c to reset the search filter.  Press RET on an entry to show it
in a separate buffer.

See the README for the full documentation.
