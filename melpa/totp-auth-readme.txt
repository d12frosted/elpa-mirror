totp-auth.el - Time-based One Time Password support for Emacs

This package generates RFC6238 Time-based One Time Passwords
(in other words, what Google Authenticator implements)
and displays them (as well as optionally copying them to
the clipboard/primary selection), updating them as they expire.

It retrieves the shared secrets used to generate TOTP tokens
with ‘auth-sources’ and/or the freedesktop secrets API (aka
Gnome Keyring or KWallet).

You can call it with the command ‘totp-auth’, ie:

   M-x totp-auth RET

You can tab-complete based on the label of the secret.
Depending on the setting of ‘totp-auth-display-token-method’ the
TOTP token will be displayed (and kept up to date) either in
an Emacs buffer or a freedesktop notification.

If you want to import TOTP secrets from other apps you can call:

  M-x totp-auth-import-file RET

If you want the latest generated token automatically
copied to your GUI's selection for easy pasting, you
can customize ‘totp-auth-auto-copy-password’.
