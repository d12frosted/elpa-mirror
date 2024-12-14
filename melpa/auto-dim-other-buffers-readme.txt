The ‘auto-dim-other-buffers-mode’ is a global minor mode which makes windows
without focus less prominent.  With many windows in a frame, this mode helps
recognise which is the selected window by providing a non-intrusive but still
noticeable visual indicator.

The preferred way to install the mode is by grabbing ‘auto-dim-other-buffers’
package form MELPA:

    M-x package-install RET auto-dim-other-buffers RET

Once installed, the mode can be turned on (globally) with:

    M-x auto-dim-other-buffers-mode RET

To make the mode enabled every time Emacs starts, add the following to Emacs
initialisation file (see `user-init-file'):

    (add-hook 'after-init-hook (lambda ()
      (when (fboundp 'auto-dim-other-buffers-mode)
        (auto-dim-other-buffers-mode t))))

To configure how dimmed buffers look like, change
`auto-dim-other-buffers-face' and `auto-dim-other-buffers-hide-face' faces.
Those faces as well as other settings can be found in
‘auto-dim-other-buffers’ group which can be accessed with:

    M-x customize-group RET auto-dim-other-buffers RET

Note that despite it, the mode operates on *windows* rather than buffers.  In
other words, selected window is highlighted and all other windows are dimmed
even if they display the same buffer.  The package is named
`auto-dim-other-buffer' for historical reasons.
