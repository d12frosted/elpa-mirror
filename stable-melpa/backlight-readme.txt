
A simple utility for setting backlight brightness on some
GNU/Linux systems using sysfs files.

This works like most system provided backlight brightness
controls but allows for increased resolution when the
brightness percentage nears zero.

On some systems a udev rule must be added, in /etc/udev/rules.d/backlight.rules add:
     ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="acpi_video0", GROUP="video", MODE="then"
then reload with:
    sudo udevadm control --reload-rules && udevadm trigger

USAGE

 M-x backlight
  Then use '<' or '>' to adjust backlight brightness, 'C-g' when done.

 M-x backlight-set-raw
  prompts for a value to write directly to the device file.
