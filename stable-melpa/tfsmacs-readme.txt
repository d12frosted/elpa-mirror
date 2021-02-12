Steps to setup:
  1. Obtain the Team Explorer Everywhere CLI tool from https://github.com/Microsoft/team-explorer-everywhere/releases
     (don't forget to run "tf eula" to accept the terms and conditions)
  2. Place tfsmacs.el in your load-path.  Or install from MELPA.
  3. In your .emacs file you can setup keybindings for the tfsmacs commands, there's a keymap:
       (require 'tfsmacs)
       (global-set-key  "\C-ct" 'tfsmacs-map)
     OR for individual commands:
       (global-set-key  "\C-ctp" 'tfsmacs-pendingchanges)
       (global-set-key  "\C-cto" 'tfsmacs-checkout)
       (global-set-key  "\C-cti" 'tfsmacs-checkin)
       ; etc.
  4. Customize the group tfsmacs to provide credentials and the location of the TEE tool
  5. Run tfsmacs-setup-workspace to configure collections and their workspaces in your computer

For a detailed user manual see:
https://github.com/sebasmonia/tfsmacs/blob/master/README.md
