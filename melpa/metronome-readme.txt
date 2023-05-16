This is a very simple metronome for GNU Emacs. To install it from
source, add metronome.el to your load path and require it. Then M-x
metronome to play/pause, and C-u M-x metronome to set a new tempo.

(require 'metronome)
(global-set-key (kbd "C-c m") 'metronome)
