This package implements NHexl mode, a minor mode for editing files
in hex dump format.  The mode command is called `nhexl-mode'.

This minor mode implements similar functionality to `hexl-mode',
but using a different implementation technique, which makes it
usable as a "plain" minor mode.  It works on any buffer, and does
not mess with the undo log or with the major mode.

It also comes with:

- `nhexl-nibble-edit-mode': a "nibble editor" minor mode.
  where the cursor pretends to advance by nibbles (4-bit) and the
  self-insertion keys let you edit the hex digits directly.

- `nhexl-overwrite-only-mode': a minor mode to try and avoid moving text.
  In this minor mode, not only self-inserting keys overwrite existing
  text, but commands like `yank' and `kill-region' as well.

- it overrides C-u to use hexadecimal, so you can do C-u a 4 C-f
  to advance by #xa4 characters.

Even though the hex addresses and hex data displayed by this mode aren't
actually part of the buffer's text (contrary to hexl-mode, for example,
they're only added to the display), you can search them with Isearch,
according to nhexl-isearch-hex-addresses and nhexl-isearch-hex-bytes.

Known bugs:

- When the buffer is displayed in several windows, the "cursor" in the hex
  area only reflects one of the window-points.  Fixing this would be rather
  painful:
  - for every cursor, we need an extra overlay with the `window'
    property with its own `before-string'.
  - because that overlay won't *replace* the normal overlay (the one
    without the `window' property), we will need to *remove* that
    overlay (lest we get 2 before-strings) and replace it with N overlays
    with a `window' property (for all N other windows that don't have
    their cursor on this line).
  FWIW, the original `hexl-mode' has the same kind of problem.

Wishlist:

- An equivalent to hexl-mode's `hexl-bits'.
- Always reload the file with find-file-literally instead
  of editing the multibyte representation?