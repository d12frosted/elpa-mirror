
A simple utility for setting backlight brightness on some
GNU/Linux systems using sysfs files.

This works like most system provided backlight brightness
controls but allows for increased resolution when the
brightness percentage nears zero.

USAGE

 M-x backlight
  Then use '<' or '>' to adjust backlight brightness, 'C-g' when done.

 M-x backlight-set-raw
  prompts for a value to write directly to the device file.
