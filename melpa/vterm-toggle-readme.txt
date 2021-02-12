
Provides the command vterm-toggle which toggles between the
vterm buffer and whatever buffer you are editing.

This is done in an "intelligent" way.  Features are:
o Starts a vterm if none is existent.
o Minimum distortion of your window configuration.
o When done in the vterm-buffer you are returned to the same window
  configuration you had before you toggled to the shell.
o If you desire, you automagically get a "cd" command in the shell to the
  directory where your current buffers file exists( even in a ssh session); just call
  vterm-toggle-cd instead of vterm-toggle.
