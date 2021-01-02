Mingus is a client for the Music Player Daemon (MPD).  It provides an
interactive interface, where most emphasis lies on on-screen display/editing
of the playlist, and browsing in a buffer.  However, minibuffer operations are
becoming more intelligent with each version (with completive browsing
somewhat like in `find-file', and searching on multiple fields, also with
auto-completion).

Installation (Melpa)
====================

Mingus is now installable from Melpa, and this is the preferred method.

NOTE if you want to use the mingus-stays-home library (see below),
you still will have to put

(require 'mingus-stays-home)

in your init file.

For non-Melpa installs, see below.

Usage
=====

After installation the following commands will be available:

1) M-x mingus-help shows the Mingus help buffer;
2) M-x mingus will show the playlist;
3) M-x mingus-browse navigates your music collection.

You can switch between these buffers with keys 1: help, 2: playlist, 3: browser.

For other key bindings, see M-x mingus-help.

Mingus-stays-home
=================

When the computer running the mpd service is the same as the one from which
mingus is being run, you may use the library mingus-stays-home.
This library can provide stuff such as:

- id3 tagging
- cd-burning
- integration with dired and the shell

Check the file mingus-stays-home.el itself if you want to know
more.

Non-Melpa Installation
======================

Make sure you have libmpdee.el in your load-path.  NOTE for old-time users:
mpc is not required anymore.  Everything is done in lisp.  This also means that
mingus has become multi-platform (in an easy way).

1. When you install both the main mingus AND mingus-stays-home:

byte-compile, IN ORDER, repeat: IN ORDER, the files mingus.el and
mingus-stays-home.el

Add the following to your .emacs:

(add-to-list 'load-path "/path/where/mingus-and-mingus-stays-home-reside")
(autoload 'mingus "mingus-stays-home" nil t)

2. Mingus only (so NO mingus-stays-home) :

byte-compile the file mingus.el

Add the following to your .emacs:

(add-to-list 'load-path "/path/where/mingus/resides")
(autoload 'mingus "mingus" nil t)

Design Issues
=============

No editing of metadata tags is provided in mingus itself.  This is because mpd is
designed to be run in a network as a server (although it can be used on a single
system, which, in fact, is what I do); as such, clients to mpd are unaware of mpd's
root dir, and possibly/probably do not have write permissions on the music
files.

If you DO use mingus-stays-home, rough metadata-editing IS provided.  `mingus-id3-set'
tries to guess the values for artist, song, track number, and album from the name
encountered in the playlist.  Use it with caution though, as as I said, it is still
rough, e.g. having to abstract away from differences between the various tagging
formats.  I AM looking into taglib for an elegant solution.  But that will take some
time.  So be patient.

The interface is roughly based on that on ncmpc.  Many keybindings are alike,
except for some notoriously vi-style-ones.  Some significant features (main
reasons to write this stuff) :

MARKING Notice specifically the possibility to mark multiple songs in the playlist
for movement or deletion (by pressing the spacebar one toggles the mark at the
current line; if there is a region, it marks all songs in the region.) Pressing 'y'
asks for a regular expression against which to match the songs.  Pressing 'Y' unmarks
alike.  If a song matches, it is marked.  Unmarking all marks happens with a single
capital "U".

INSERTION POINT Another nice feature is "mingus-set-insertion-point" (Key:
"i") : mark a song after which you would like your next insertions to take
place.  Then go inserting.  Unset this behaviour with "u"
(mingus-unset-insertion-point), and songs will be added to 3the end of the
playlist again.  As of version 0.24 this is NOT time-consuming.  Yeah!

NOTE: right now these two functions are mutually exclusive.

Dired
=====

Ability to snap to the file location of a song instantly in `dired', so as
to perform file management or other actions on these files easily (such as
removal, movement or renaming), or just to check wtfs '3.ogg' actually
refers to.

You might want to change the `dired-mode-map' so that it will play well with
Mingus.  If you want to, you can set the variable `mingus-dired-add-keys' to
t; this can be done with `mingus-customize'.  It will set "SPC" to
`mingus-dired-add', "C-u SPC" to `mingus-dired-add-and-play' and add an item
for `mingus-dired-add' to the menu-bar in dired.  `mingus-dwim-add' and
`mingus-dwim-add-and-play' (see below) calls mingus-dired-add when in dired,
so binding this to a global key might be a nice solution too.

For those already familiar with mpd, and have set that up, you're done now.

If you get a message like

MPD_HOST and/or MPD_PORT environment variables are not set message: problems
getting a response from "localhost" on port 6600 : Connection refused

there are two options:

1. you want to run locally, so run mpd
first.  Do so from somewhere else or simply evaluate (mingus-start-daemon).
On some configurations of mpd this must be done as root.

For those unfamiliar with mpd, to set it up, put something like the following
in ~/.mpdconf (this is for when run a user)

port                "6600"
music_directory     "/your/music/directory"
playlist_directory  "~/playlists"
log_file            "~/.mpd.log"
message_file        "~/.mpd.err"

then run mpd

2. you want to connect to a remote host, but have not set the
environment variables MPD_HOST and/or MPD_PORT.  Do so by calling
(mingus-set-variables-interactively) (settings lost when emacs
restarted) or by means of customization (mingus-customize) or
(customize-group 'mingus).

NEW in mingus 0.21: `mingus-wake-up-call'; fixed the lisp-max-eval-depth
error message when leaving mingus-info on for a while; allowing spaces in
minibuffer operations, such as loading and saving of playlists, radio-streams
and the like, but most of all: inclusion of mingus-stays-home, which provides
nice integration features.  See that file for more information.  Emacs21
compatablity, except for parts of mingus-stays-home.

Known bugs
==========

* a file name cannot have a double quotes (") or a backtick (`) in it.  Do not
know how to fix that, so if anyone feels so inclined... You CAN query your
database (M-x mingus-query-regexp " RET) to know if you are in the possession
of such files, so you can adjust their names (with mingus-stays-home
installed: press 0 (zero) to go to dired to do so). The only way to insert
such files currently is by inserting their parent directory.

point-of-insertion only works with one file or directory at a time
