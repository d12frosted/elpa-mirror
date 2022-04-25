Highlight word stems in text buffers, thereby providing artificial
fixation points to improve speed reading.

Use M-x stem-reading-mode in a text buffer to turn on (or off) the
minor mode. Customize `stem-reading-highlight-face' to modify the
default highlight. Set `stem-reading-overlay' to add the highlight
to all words unconditionally.

With some modes, instead of highlighting the word stem, it might be
convenient to de-light the remaining part of a word instead. You can
achieve this effect by customizing `stem-reading-delight-face'.

On Hi-Dpi displays (and a good font), a configuration similar to the
following can give excellent results:

(require 'stem-reading-mode)
(set-face-attribute 'stem-reading-highlight-face nil :weight 'unspecified)
(set-face-attribute 'stem-reading-delight-face nil :weight 'light)
