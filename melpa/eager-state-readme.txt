This is both a library and an end-user package.

For the end-user, it provides a simple way to periodically run a subset of
`kill-emacs-hook', ensuring that state variables are written to disk long
before something happens to your Emacs session.

An example setup looks like:

    (require 'eager-state)
    (setq eager-state-idle-delay 10)         ; Default 15
    (setq eager-state-periodic-delay 100)    ; Default 60
    (setq eager-state-faster-shutdown t)     ; Default nil
    (setq eager-state-kill-emacs-hook-subset ; Default nil
          '(bookmark-exit-hook-internal
            savehist-autosave
            transient-maybe-save-history
            org-clock-save
            org-id-locations-save
            save-place-kill-emacs-hook
            recentf-save-list
            recentf-cleanup
            doom-cleanup-project-cache-h
            doom-persist-scratch-buffers-h))

Note how the above setting for `eager-state-kill-emacs-hook-subset' is a
loose selection of possible real-world values of `kill-emacs-hook'.

Loading the package with (require 'eager-state) enables a global minor mode
`eager-state-mode', which manages a timer that periodically tries to run
the above listed functions.

You can add any symbol to the list, even if it is not yet defined as a
function.  A given symbol will only be funcalled if it is present both in
that list, and in `kill-emacs-hook', at call time.

To add new functions that you don't want on `kill-emacs-hook', add
them to `eager-state-sync-hook' instead.

For library developers:

You can depend on this library and add your state-saving functions to
`eager-state-sync-hook'.  They'll run alongside the rest of them, in
accordance with user preferences.

Let's say your function is called `foo-write-some-data-to-disk'.
Then do this:

(require 'eager-state)
(add-hook 'eager-state-sync-hook #'foo-write-some-data-to-disk)
