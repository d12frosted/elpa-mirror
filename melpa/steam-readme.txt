Launch games in your Steam library from Emacs.  First set your `steam-username':

(setq steam-username "your_username")

Here `steam-username' refers to the text in the CUSTOM URL field
in your Steam account profile settings.

Then use `steam-launch' to play a game! You can also insert your steam
library into an org-mode file, in order to organize your games, and launch
them from there.  Run either `steam-insert-org-text' or
`steam-insert-org-images' (if you want the logotypes for the games in your
org file).  The logotypes will be saved locally (see variable `steam-logo-dir'
into a folder relative to the org-file.
