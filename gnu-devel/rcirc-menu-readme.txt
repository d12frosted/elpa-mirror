If you are connected to too many channels, `rcirc-track-minor-mode'
is useless because the modeline is too short. Bind `rcirc-menu' to
a key instead:

(global-set-key (kbd "C-c r") 'rcirc-menu)