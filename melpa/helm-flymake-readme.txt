
`helm' interface for flymake.
When `flymake-mode' is t, M-x `helm-flymake' lists warning and error
messages in *helm flymake* buffer.
C-u M-x `helm-flymake' insert the line number of current cursor position
into minibuffer.
Within the `helm-flymake' buffer if `helm-execute-persistent-action'
is executed (by default bound to C-j), then point will be moved to the
line number of the selected warning/error. If you would no longer
like to be at this place in the buffer, simply hit C-g to exit the
`helm-flymake' mini-buffer and point will be returned to its original
position.
When Enter/<return> is pressed the "default" action is executed
moving point to the line of the selected warning/error and closing
the `helm-flymake' mini-buffer.

; Installation:

Add followings on your .emacs.

  (require 'helm-config)
  (require 'helm-flymake)
