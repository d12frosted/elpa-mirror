
Elfeed Tube is an extension for Elfeed, the feed reader for Emacs, that
enhances your Youtube RSS feed subscriptions.

Typically Youtube RSS feeds contain only the title and author of each video.
Elfeed Tube adds video descriptions, thumbnails, durations, chapters and
"live" transcrips to video entries. See
https://github.com/karthink/elfeed-tube for demos. This information can
optionally be added to your entry in your Elfeed database.

The displayed transcripts and chapter headings are time-aware, so you can
click on any transcript segment to visit the video at that time (in a browser
or your video player if you also have youtube-dl). A companion package,
`elfeed-tube-mpv', provides complete mpv (video player) integration with the
transcript, including video seeking through the transcript and following
along with the video in Emacs.

To use this package,

(i) Subscribe to Youtube channel or playlist feeds in Elfeed. You can use the
helper function `elfeed-tube-add-feeds' provided by this package to search for
Youtube channels by URLs or search queries.

(ii) Place in your init file the following:

(require 'elfeed-tube)
(elfeed-tube-setup)

(iii) Use Elfeed as normal, typically with `elfeed'. Your Youtube feed
entries should be fully populated.

You can also call `elfeed-tube-fetch' in an Elfeed buffer to manually
populate an entry, or obtain an Elfeed entry-like summary for ANY youtube
video (no subscription needed) by manually calling `elfeed-tube-fetch' from
outside Elfeed.

User options:

There are three options of note:

`elfeed-tube-fields': Customize this to set the kinds of metadata you want
added to Elfeed's Youtube entries. You can selectively turn on/off
thumbnails, transcripts etc.

`elfeed-tube-auto-save-p': Set this boolean to save fetched Youtube metadata
to your Elfeed database, i.e. to persist the data on disk for all entries.

`elfeed-tube-auto-fetch-p': Unset this boolean to turn off fetching metadata.
You can then call `elfeed-tube-fetch' to manually fetch data for specific
feed entries.

See the customization group `elfeed-tube' for more options. See the README
for more information.
