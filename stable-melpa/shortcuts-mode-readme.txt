This is a minor mode which adds a sticky window to the top of the
frame listing the last ten buffers that were accessed.  You can
then instantly switch the current window to one of the recent
buffers using C-1 through C-0.  Think of it as an extremely
lightweight tab bar oriented around keyboard navigation.

The shortcut bar also supports basic mouse navigation.  Left click
switches the current window to the selected buffer, and middle
click kills the selected buffer.

As a special case, certain utility buffers (*Buffer List*,
*Ibuffer*, the *shortcuts* buffer itself) are excluded from the top
bar.  Dired buffers are also filtered, because otherwise navigating
the filesystem through Dired (which creates a new buffer for each
directory) tends to fill up all the top slots.
