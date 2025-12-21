Provide a simple way to periodically run a subset of `kill-emacs-hook',
ensuring that state variables are written to disk long before something
happens to your Emacs session.

An example setup looks like:

    (require 'eager-state)
    (setq eager-state-idle-delay 15)
    (setq eager-state-periodic-delay 60)
    (setq eager-state-faster-shutdown t)
    (setq eager-state-kill-emacs-hook-subset
          '( bookmark-exit-hook-internal
             savehist-autosave
             transient-maybe-save-history
             org-clock-save
             org-id-locations-save
             save-place-kill-emacs-hook
             recentf-save-list
             recentf-cleanup
             doom-cleanup-project-cache-h
             doom-persist-scratch-buffers-h))

Note how the above list is cribbed from real-world values of
`kill-emacs-hook'.

The `require' statement enables a global minor mode `eager-state-mode',
which manages a timer that periodically tries to run the above listed
functions.

You can add any symbol to the list, even if it is not yet defined as a
function.  A given symbol will only be funcalled if it is present both in
that list, and in `kill-emacs-hook'.

To add new functions that you don't want on `kill-emacs-hook', add
them to `eager-state-sync-hook' instead.
