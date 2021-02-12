Switch to the most recently used window.

Use the `ctrlxo' function to start switching between windows on visible
frames in the recent usage ordering.
`ctrlxo' also activates transient keymap:
- o to switch to the next window
- O to switch to the previous window
- C-g to cancel switching and select window that was active on `ctrlxo'
  invocation

Use the `ctrlxo-current-frame' function to start switching between windows
on the current frame.

Following example configuration will allow to switch between windows on
all visible frames with 'C-TAB' and between windows on the current frame
with 'C-x o':

    (require 'ctrlxo)
    (global-set-key (kbd "C-<tab>") #'ctrlxo)
    (global-set-key (kbd "C-x o") #'ctrlxo-current-frame)
    (define-key ctrlxo-map (kbd "<tab>") #'ctrlxo-forward)
    (define-key ctrlxo-map (kbd "<S-tab>") #'ctrlxo-backward)
