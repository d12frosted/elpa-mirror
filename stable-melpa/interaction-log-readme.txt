
This package provides a buffer *Emacs Log* showing the last hit
keys and executed commands, messages and file loads in
chronological order.  This enables you to reconstruct the last
seconds of your work with Emacs.  It's also useful for
giving presentations or making screencasts with Emacs.

Installation: Put this file in your load path and byte-compile it.
To start logging automatically at startup, add this to your init
file:

(require 'interaction-log)
(interaction-log-mode +1)

You probably will want to have a hotkey for showing the log
buffer, so also add something like

(global-set-key
 (kbd "C-h C-l")
 (lambda () (interactive) (display-buffer ilog-buffer-name)))

Alternatively, there is a command `ilog-show-in-new-frame' that
you can use to display the log buffer in a little new frame whose
parameters can be controlled by customizing
`ilog-new-frame-parameters'.

Usage: Use `interaction-log-mode' to toggle logging.  Enabling the
mode will cause all messages and all pressed keys (along with the
actually executed command and the according buffer) to be logged
in the background.  Also loading of files will be logged.  If an
executed command causes any buffer to change, it will be
highlighted in orange so you can check if you made changes by
accident.  If a command caused any message to be displayed in the
echo area (e.g. if an error occurred), it is highlighted in red.

If you find any bugs or have suggestions for improvement, please
tell me!
