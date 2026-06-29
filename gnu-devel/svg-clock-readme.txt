svg-clock provides a scalable analog clock.  Rendering is done by
means of svg (Scalable Vector Graphics).  In order to use svg-clock
you need to build Emacs with svg support.  (To check whether your
Emacs supports svg, do "M-: (image-type-available-p 'svg) RET"
which must return t).

Call `svg-clock' to start a clock.  This will open a new buffer
"*clock*" displaying a clock which fills the buffer's window.  Use
`svg-clock-insert' to insert a clock programmatically in any
buffer, possibly specifying the clock's size, colours and offset to
the current-time.  Arbitrary many clocks can be displayed
independently.  Clock instances ared updated automatically.  Their
resources (timers etc.) are cleaned up automatically when the
clocks are removed.