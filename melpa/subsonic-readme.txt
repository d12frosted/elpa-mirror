This package is meant to act as a simple subsonic frontend that
uses mpv for playing the actual music.  Use a ~/.authinfo.gpg file with
contents like the following to setup auth

machine SUBSONIC_URL login USERNAME password PASSWORD port subsonic

port is required to be 'subsonic' for this to work
