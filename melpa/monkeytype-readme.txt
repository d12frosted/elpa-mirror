Emacs Monkeytype is a typing game/tutor inspired by monkeytype.com but for
Emacs.

Features:

- Type any text you want.

- Mode-line live WPM (`monkeytype-mode-line-interval-update' adjust the
update frequency).

- Visual representation of typed text including errors and
retries/corrections.

- Auto stop after 5 seconds of no input (`C-c C-c r` [`monkeytype-resume']
resumes).

- Optionally randomise practice words/transitions (see:
`monkeytype-randomize').

- Optionally downcase practice words/transitions (see:
`monkeytype-downcase').

- Optionally treat newlines as whitespace (see:
`monkeytype-treat-newline-as-space').

- Optionally auto-fill text to the defaults `fill-column' value (see:
`monkeytype-auto-fill').

- Select a region of text and treat it as words for practice (e.i.,
optionally downcased, randomised, etc... see: `monkeytype-region-as-words').

- After a test, practice troubling/hard key combinations/transitions (useful
when practising with different keyboard layouts).

- Mistyped words or hard transitions can be saved to `~/.monkeytype/{words or
transitions}` (see: `monkeytype-directory' `monkeytype-save-mistyped-words'
`monkeytype-save-hard-transitions').

- Saved mistyped/transitions files (or any file but defaults to
`~/.monkeytype/` dir) can be loaded with `monkeytyped-load-words-from-file'.

- `monkeytype-excluded-chars-regexp' customises the regexp used for removing
characters from words (defaults to: "[^[:alnum:]']").

- Ability to type most (saved) mistyped words (the amount of words is
configurable with `monkeytype-most-mistyped-amount' [defaults to 100]) see:
`monkeytype-most-mistyped-words'
