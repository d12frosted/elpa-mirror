Load this script

  (require 'scratch-pop)

and you can popup a scratch buffer with "M-x scratch-pop". If a
scratch is already displayed, new buffers (like =*scratch2*=,
=*scratch3*= ...) are created. You may also bind some keys to
"scratch-pop" if you want.

  (global-set-key "C-M-s" 'scratch-pop)

You can backup scratches by calling `scratch-pop-backup-scratches'
after setting `scratch-pop-backup-directory',

  (setq scratch-pop-backup-directory "~/.emacs.d/scratch_pop/")
  (add-hook 'kill-emacs-hook 'scratch-pop-backup-directory)

and then restore backups by calling `scratch-pop-restore-scratches'.

  (scratch-pop-restore-scratches 2) ; restores *scratch* and *scratch2*
