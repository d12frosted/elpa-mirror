Provides commands analagous to `windmove' commands such as
`windmove-left' which also swap the buffers in the previous and new
windows.  This allows the user to "drag" the current buffer to
neighbouring windows.  The idea is to bind keys similarly to
`windmove', so that the two packages can be used interchangeably to
navigate and rearrange windows.

  (windmove-default-keybindings 'control)
  (windswap-default-keybindings 'control 'shift)
