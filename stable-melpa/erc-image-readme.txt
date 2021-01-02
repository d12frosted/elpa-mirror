
Show inlined images (png/jpg/gif/svg) in erc buffers.  Requires
Emacs 24.2

(require 'erc-image)
(add-to-list 'erc-modules 'image)
(erc-update-modules)

Or `(require 'erc-image)` and  `M-x customize-option erc-modules RET`

This plugin subscribes to hooks `erc-insert-modify-hook' and
`erc-send-modify-hook' to download and show images.  In this early
version it's doing this synchronously.

The function used to display the image is bound to the variable
`erc-image-display-func'. There are two possible values for that,
`erc-image-insert-inline' and `erc-image-insert-other-buffer'.

Set the value of erc-image-inline-rescale to a number for max size
of images to be displayed (resized if bigger). set the value to
'window to take window height as this value
