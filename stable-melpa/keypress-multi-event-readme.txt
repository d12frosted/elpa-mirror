
   This package provides a method to define multiple functions to
   be performed for the same keypress. You can use this as a
   convenience feature to toggle among several functions. It was
   originally written as the back-end for package `home-end',
   allowing those two keys to smartly cycle between moving POINT to
   the beginning/end of a line, the beginning/end of the window,
   the beginning/end of the buffer, and back to POINT.

   Create a function which calls `keypress-multi-event' with a list
   of the functions to be associated with the keypress, and bind
   that keypress to that function. By default, subsequent
   keypresses cycle through the list, but you can change that
   behavior by optionally adding an index into the list as a second
   argument, or you could also directly manipulate the underlying
   buffer-local variable `keypress-multi-event--state'. Both
   methods are illustrated in package `home-end'.
