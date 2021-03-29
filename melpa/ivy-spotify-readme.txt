This package provides an ivy-based completion interface to
spotify's search API, analogous to counsel-spotify, using the
smaller espotify library.  The following interactive commands
are defined:

 - `ivy-spotify-album'
 - `ivy-spotify-artist'
 - `ivy-spotify-track'
 - `ivy-spotify-playlist'

A completing prompt will appear upon invoking it, and when
the input varies significantly or you end your input with `='
a web search will be triggered.  Several ivy actions (play,
play album, show candidate info) are available.

For espotify to work, you need to set valid values for
`espotify-client-id' and `espotify-client-secret'.  To get
valid values for them, one just needs to register a spotify
application at https://developer.spotify.com/my-applications

All .el files have been automatically generated from the literate program
https://codeberg.org/jao/espotify/src/branch/main/readme.org
