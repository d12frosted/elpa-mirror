Elfeed is a web feed client for Emacs, which supports Atom, RSS
and JSON feeds.

After installation of Elfeed from a package archive, invoke M-x
elfeed to open the Elfeed search buffer.  The list of feeds can be
configured in your user configuration.

    (setq elfeed-feeds
      '(("https://nullprogram.com/feed/" blog emacs)
        "https://sachachua.com/blog/category/emacs-news/feed/" ;; no autotagging
        ("https://nedroid.com/feed/" webcomic)))

For the start a few basic commands suffice.  Inside the search
buffer press G to refresh the feeds, s to live filter the entries,
or c to reset the search filter.  Press RET on an entry to show it
in a separate buffer.

See the README for the full documentation.
