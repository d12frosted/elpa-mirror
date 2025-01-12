A custom and simple mode line for Emacs.

I.  Installation
  A. Manual installation
    1. Add `timu-line.el' (https://gitlab.com/aimebertrand/timu-line)
       to your `custom-load-path'.
    2. In your `~/.emacs.d/init.el' or `~/.emacs':
        (timu-line-mode 1)

  B. From Melpa
    1. M-x package-install RET timu-line RET.
    2. In your `~/.emacs.d/init.el' or `~/.emacs':
        (timu-line-mode 1)

  C. With use-package
    In your `~/.emacs.d/init.el' or `~/.emacs':
      (use-package timu-line
        :ensure t
        :config
        (timu-line-mode 1))

II.  Features
    The following is displayed in appropriate buffers only:

  A. Left side
     - Display hint when a kbd macro is running
     - Display evil state
     - Display Tramp host if applicable
     - Display buffer/file name
     - Display keybindings hint for the org capture buffer
     - Display keybindings hint for the git commit message buffer
     - Display keybindings hint for the forge post buffer
     - Display the vc branch
     - Display the python venv
     - Display Mu4e context
     - Display Elfeed search filter
     - Display Elfeed article counts
     - Display Monkeytype Stats

  B. Right side
     - Display the major mode
     - Display Mu4e mail count (works only with `mu' installed)
     - Display tab number `current:total'
     - Display column number of the point

III.  Options
  A. Faces
     The following faces can be set to ones liking.
     Either by the theme or with `set-face-attribute'.

     - `timu-line-bg-active-face'
     - `timu-line-bg-inactive-face'
     - `timu-line-active-face'
     - `timu-line-inactive-face'
     - `timu-line-special-face'
     - `timu-line-fancy-face'
     - `timu-line-status-face'
     - `timu-line-modified-face'
     - `timu-line-read-only-face'

  B. Control section display
     You can elect to display some sections or not by using the
     following variables:

     - `timu-line-show-vc-branch' - default value is t
     - `timu-line-show-lsp-indicator' - default value is nil
     - `timu-line-show-eglot-indicator' - default value is nil
     - `timu-line-show-python-virtual-env' - default value is t
     - `timu-line-show-org-capture-keys' - default value is t
     - `timu-line-show-git-commit-keys' - default value is t
     - `timu-line-show-forge-post-keys' - default value is t
     - `timu-line-show-mu4e-context' - default value is t
     - `timu-line-show-mu4e-index-update-indicator' - default value is nil
     - `timu-line-show-elfeed-counts' - default value is t
     - `timu-line-show-monkeytype-stats' - default value is nil
     - `timu-line-show-evil-state' - default value is nil
     - `timu-line-show-tramp-host' - default value is nil

  C. Delay time for forcing the mode-line update
     Some commands to not trigger a mode-line update.
     The `post-command-hook' `timu-line-delayed-force-update' tries to mitigate that.
     It forces the update of the mode-line with a delay for performance reasons.
     This variable controls the delay:

     - `timu-line-update-timer-time' - default value is 0.5

  D. Org capture hints for keybindings
     The variable `timu-line-org-capture-keys-string' contains the string to
     show in the mode line as keybindings hint in the org capture buffer.

  E. Modes for mu4e context
     `timu-line-mu4e-context-modes' is a custom variable containing a list of
     major modes in which to display the Mu4e context in the mode line.

  F. Modes for mu4e context
     `timu-line-elfeed-modes' controls in which modes the custom
     Elfeed string is displayed.
