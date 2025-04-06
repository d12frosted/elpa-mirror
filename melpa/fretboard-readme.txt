`fretboard` provides an interactive way to visualize guitar scales and chord
shapes directly in Emacs.  It displays a text-based representation of a
guitar fretboard with highlighted notes for different scales and chords.

The package supports various features:
- Display scales and chords with highlighted notes on the fretboard
- Support for various scale types (major, minor, pentatonic, etc.)
- Support for various chord types (major, minor, 7th, etc.)
- Multiple tuning options (standard, drop-D, open-G, etc.)
- Interactive navigation between notes, scales, and chord types

Usage:
- M-x fretboard - Display the fretboard, defaulting to the A major scale.
- M-x fretboard-display-scale - Display a specific scale on the fretboard
- M-x fretboard-display-chord - Display a specific chord on the fretboard
- M-x fretboard-set-tuning - Change the guitar tuning

Once viewing a fretboard, you can navigate with the following keys:
- n/p: Navigate to next/previous note (same scale/chord type)
- k/j: Navigate to next/previous scale/chord type (same note)
- ,/m: Navigate to next/previous mode (same scale, only for major scale)
- d: Toggle between scale and chord display
- t: Toggle between different tunings
- r: Toggle between note names and relative intervals
- s/c: Switch to scale/chord display
- q: Close all fretboard buffers
