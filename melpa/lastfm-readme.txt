lastfm.el provides a complete interface to the Last.fm API as defined by URL
`https://www.last.fm/api/'.  An API account, obtainable for free from
Last.fm, is needed to use the majority of provided services.  A one-time
authentication process is needed to access the rest of the methods.

Example usage to get the top tracks tagged as "rock" from last.fm, based on
user preferences,

(lastfm-tag-get-top-tracks "rock" :limit 3)
=> (("Nirvana" "Smells Like Teen Spirit")
    ("The Killers" "Mr Brightside")
    ("Oasis" "Wonderwall"))

Or add a track to your list of loved songs,

(lastfm-track-love "anathema" "springfield")
=> ("")

See the package URL for the full Last.fm API documentation.
