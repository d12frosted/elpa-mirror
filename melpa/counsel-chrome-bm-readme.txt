
  Soft requirement: jq (URL <https://stedolan.github.io/jq/>).
  Counsel-chrome-bm will work without jq, but it will be slow when you have
  a lot of bookmarks.

This package provides the commands `counsel-chrome-bm' and
`counsel-chrome-bm-all', which allow you to browse your Chrome bookmarks
with `ivy'.  Chromium and many Chromium-based browser are supported too.
Use `counsel-chrome-bm-file' to specify your bookmarks file if it is
not auto-detected.

By default jq will be used if available.  Set `counsel-chrome-bm-jq' to the
executable of jq if jq is not on the PATH.  If jq is not available the
package will fall back to using Emacs' JSON parsing.  This will be done
synchronous and might be slow if you have a lot of bookmarks, but on the
other hand it allows for fuzzy searching, which using jq does not.  If you
don't want to use jq even when available, set `counsel-chrome-bm-no-jq' to t.

Known supported browsers are: Chrome, Chromium, Vivaldi, Edge and Brave.
Known not working browsers are: Opera.
