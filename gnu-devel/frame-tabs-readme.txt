Minor mode to display buffer tabs in a side window on each frame.

This mode shows, in a side window on each frame, tabs listing the
names of all live buffers that have been displayed on that frame.
Clicking on a tab with the left mouse button switches to the
corresponding buffer in a window.  Clicking on a tab with the right
mouse button dismisses the buffer.  See 'frame-tabs-map'.
Alternatively, tabs can display an additional 'x' button which
permits to dismiss buffers with the left mouse button.  See
'frame-tabs-x' and 'frame-tabs-x-map'.

Caveats: Many desirable features are either underdeveloped or
simply don't work.  Navigating tabs windows with the keyboard has
not been implemented; neither has been displaying alternative items
like tabs representing window configurations.  You're welcome to
expand existing and/or add new features at your like.