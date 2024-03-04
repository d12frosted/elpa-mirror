This package provides an EMMS player wrapper for Spotify. It supports two
types of links: internal spotify ids in form of "spotify:<type>:<id>" and in
form of a "https://open.spotify.com/<type>/<id>" URLs. The package delegates
actual playback to the desktop app, which must be already running. For proper
work, please disable Autoplay feature in the desktop app, so that EMMS would
have full control over the playback queue. As the package uses DBUS MPRIS
interface to control the player, it will work only on platforms where dbus is
available.
