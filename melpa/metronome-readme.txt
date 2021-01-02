This is a simple metronome for GNU Emacs. To install it from
source, add metronome.el to your load path and require it. Then M-x
metronome to play/pause, and C-u M-x metronome to set/play a new
tempo. When prompted, enter the BPM and optional beats per bar
preceded by space.

You can also set a new tempo by tapping two or more times
successively with the metronome-tap-tempo command, or with the
metronome-(in/de)crement-tempo commands.

For a visual reference of the tempo, beat and (optional) bar count,
use the metronome-display command. Press SPC to play/pause, n/p to
change tempo, h/s to tap/set a new tempo, and q to quit. See
metronome-mode for a list of commands.
