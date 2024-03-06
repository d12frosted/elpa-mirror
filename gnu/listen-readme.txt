                              ━━━━━━━━━━━
                               LISTEN.EL
                              ━━━━━━━━━━━


[https://elpa.gnu.org/packages/listen.svg]

This package aims to provide a simple audio/music player for Emacs.  It
should "just work," with little-to-no configuration, have intuitive
commands, and be easily extended and customized.  (Contrast to setting
up EMMS, or having to configure external players like MPD.)  A Transient
menu, under the command `listen', is the primary entry point.

The only external dependency is VLC, which is currently the only player
backend that is supported.  (Other backends may easily be added; see
library `listen-vlc' for example.)  Track metadata is read using EMMS's
native Elisp metadata library, which has been imported into this
package.

Queues are provided as the means to play consecutive tracks, and they
are shown in a `vtable'-based view buffer.  They are persisted between
sessions using the `persist' library, and they may be bookmarked.

The primary interface to one's music library is through the filesystem,
by selecting a file to play, or by adding files and directories to a
queue.  Although MPD is not required, support is provided for finding
files from a local MPD server's library using MPD's metadata searching.

A simple "library" view is provided that shows a list of files organized
into a hierarchy by genre, date, artist, album, etc.  (This will be made
more configurable and useful in the future.)

Note a silly limitation: a track may be present in a queue only once
(but who would want to have a track more than once in a playlist).


[https://elpa.gnu.org/packages/listen.svg]
<https://elpa.gnu.org/packages/listen.html>


1 Screenshots
═════════════

  <file:images/screenshot-modus-vivendi-tinted.png>


2 Installation
══════════════

  Note that Listen.el uses [VLC] to play audio, so it must be installed.
  Also, `ffprobe' (part of [FFmpeg]) is used to read track durations
  when available, but it is not required.


[VLC] <https://www.videolan.org/vlc/>

[FFmpeg] <https://ffmpeg.org/ffprobe.html>

2.1 GNU ELPA
────────────

  Listen.el is published in [GNU ELPA] as [listen], so it may be
  installed in Emacs with the command `M-x package-install RET listen
  RET'.  This is the recommended way to install Listen.el, as it will
  install the current stable release.

  The latest development build may be installed from [ELPA-devel] or
  from Git (see below).


[GNU ELPA] <http://elpa.gnu.org/>

[listen] <https://elpa.gnu.org/packages/listen.html>

[ELPA-devel] <https://elpa.gnu.org/devel/listen.html>


2.2 Git
───────

  The `master' branch of the Git repository is intended to be usable at
  all times; only minor bugs are expected to be found in it before a new
  stable release is made.

  To install, it is recommended to use [quelpa-use-package], like this
  (using [this helpful command] for upgrading versions):

  ┌────
  │ ;; Install and load `quelpa-use-package'.
  │ (package-install 'quelpa-use-package)
  │ (require 'quelpa-use-package)
  │ 
  │ ;; Install Listen.
  │ (use-package listen
  │   :quelpa (listen :fetcher github :repo "alphapapa/listen.el"))
  └────

  One might also use systems like [Elpaca] or [Straight] (which is also
  used by [DOOM]), but the author cannot offer support for them.


[quelpa-use-package] <https://github.com/quelpa/quelpa-use-package>

[this helpful command]
<https://github.com/alphapapa/unpackaged.el#upgrade-a-quelpa-use-package-forms-package>

[Elpaca] <https://github.com/progfolio/elpaca>

[Straight] <https://github.com/radian-software/straight.el>

[DOOM] <https://github.com/doomemacs/doomemacs>


3 Configuration
═══════════════

  Listen is intended to work with little-to-no configuration.  You can
  set the `listen-directory' to the location of your music library if
  it's not at `~/Music'.  See `M-x customize-group RET listen RET'.


4 Usage
═══════

  Use the command `listen' to show the Transient menu.  From there, it
  is–hopefully–self-explanatory.  Please feel free to give feedback if
  it doesn't seem so.


5 Changelog
═══════════

5.1 v0.5
────────

  *Additions*
  ⁃ Command `listen-queue-list' shows a list of queues.
  ⁃ Command `listen-jump' (bound to `j' in queue and library buffers)
    jumps to the track at point in a Dired buffer.
  ⁃ Command `listen-track-view' shows a track's complete metadata in a
    table view.
  ⁃ Mode `listen-queue-delay-mode' plays a queue with a configurable,
    random delay between tracks.
  ⁃ Option `listen-queue-repeat-mode' (also settable in `listen-menu')
    allows repeating a queue in-order or shuffled.
  ⁃ Option `listen-lighter-extra-functions' allows displaying extra
    information in the `listen-mode' lighter.
  ⁃ Option `listen-track-end-functions' allows running functions when a
    track finishes playing.
  ⁃ Show total queue duration at bottom of track list.
  ⁃ Show track ratings in library and queue buffers.

  *Changes*
  ⁃ All metadata in MP3 and Ogg files is available for display (not only
    standard tags).
  ⁃ For date field in library and queue views, show `originalyear' or
    `originaldate' metadata fields in preference to `date' (which seems
    generally more useful, as the `date' field may contain a full date,
    and sometimes of a later release).

  *Fixes*
  ⁃ Increase timeout for reading track durations.
  ⁃ Command `listen-queue-deduplicate' first removes any tracks not
    backed by a file.
  ⁃ In queue buffer, mark current track by comparing filename (rather
    than internal track identity).


5.2 v0.4
────────

  *Additions*
  ⁃ Command `listen-queue-deduplicate' removes duplicate tracks from a
    queue (by comparing artist, album, and title metadata
    case-insensitively).
  ⁃ Read track durations with `ffprobe' and show in library and queue
    views.
  ⁃ Bound key `?' to open the `listen' Transient menu in library and
    queue views.

  *Fixes*
  ⁃ Transposing a track in a queue keeps point on the track.
  ⁃ Autoloading of `listen' command.


5.3 v0.3
────────

  *Additions*
  ⁃ Command `listen-library-from-mpd' shows tracks selected from MPD in
    a library view.
  ⁃ Command `listen-library-from-queue' shows tracks selected from a
    queue buffer in a library view.
  ⁃ Command `listen-library-from-playlist-file' shows tracks from an M3U
    playlist in a library view.
  ⁃ Command `listen-queue-add-from-playlist-file' adds tracks from an
    M3U playlist file to a queue.

  *Changes*
  ⁃ Reading tracks from MPD allows multiple selection using
    `completing-read-multiple'.
  ⁃ Various improvements in robustness.
  ⁃ Command `listen-queue' doesn't recreate its buffer when already
    open.
  ⁃ Key bindings in `listen' Transient menu.
  ⁃ Function `listen-queue-complete' accepts argument `:allow-new-p' to
    return a new queue if the entered name doesn't match an existing
    one.

  *Fixes*
  ⁃ Completing read of tracks from MPD.
  ⁃ Unset VLC process's query-on-exit flag.

  *Credits*
  ⁃ Thanks to [Philip Kaludercic] for reviewing.


[Philip Kaludercic] <https://amodernist.com/>


5.4 v0.2
────────

  *Additions*
  ⁃ Command `listen-queue-jump' jumps to the currently playing track in
    the queue.
  ⁃ Command `listen-queue-shell-command' runs a shell command on the
    tracks selected in the queue.
  ⁃ Reverting a queue buffer with universal prefix argument refreshes
    the tracks' metadata from disk.

  *Fixes*
  ⁃ The queue could sometimes skip tracks when playing.
  ⁃ Improve handling of tracks that are changed during playback
    (e.g. metadata).
  ⁃ Update copyright statements in all libraries.


5.5 v0.1
────────

  Initial release.


6 Development
═════════════

  Feedback and patches are welcome.


6.1 Copyright assignment
────────────────────────

  Listen.el is published in GNU ELPA and is considered part of GNU
  Emacs.  Therefore, cumulative contributions of more than 15 lines of
  code require that the author assign copyright of such contributions to
  the FSF.  Authors who are interested in doing so may contact
  [assign@gnu.org] to request the appropriate form.


[assign@gnu.org] <mailto:assign@gnu.org>
