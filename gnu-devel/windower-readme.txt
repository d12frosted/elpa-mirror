This package provides the commands below.  The commands are most useful when
bound to accessible bindings, for instance:

  (global-set-key (kbd "<s-tab>") 'windower-switch-to-last-buffer)
  (global-set-key (kbd "<s-o>") 'windower-toggle-single)
  (global-set-key (kbd "s-\\") 'windower-toggle-split)

  (global-set-key (kbd "<s-M-left>") 'windower-move-border-left)
  (global-set-key (kbd "<s-M-down>") 'windower-move-border-below)
  (global-set-key (kbd "<s-M-up>") 'windower-move-border-above)
  (global-set-key (kbd "<s-M-right>") 'windower-move-border-right)

  (global-set-key (kbd "<s-S-left>") 'windower-swap-left)
  (global-set-key (kbd "<s-S-down>") 'windower-swap-below)
  (global-set-key (kbd "<s-S-up>") 'windower-swap-above)
  (global-set-key (kbd "<s-S-right>") 'windower-swap-right)

For Evil users:
  (global-set-key (kbd "s-M-h") 'windower-move-border-left)
  (global-set-key (kbd "s-M-j") 'windower-move-border-below)
  (global-set-key (kbd "s-M-k") 'windower-move-border-above)
  (global-set-key (kbd "s-M-l") 'windower-move-border-right)

  (global-set-key (kbd "s-H") 'windower-swap-left)
  (global-set-key (kbd "s-J") 'windower-swap-below)
  (global-set-key (kbd "s-K") 'windower-swap-above)
  (global-set-key (kbd "s-L") 'windower-swap-right)