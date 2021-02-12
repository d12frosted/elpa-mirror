
Purpose
-------
maxframe provides the ability to maximize the emacs frame and stay within
the display resolution.

Usage
-----
Example of lines to be added to your .emacs:

    (require 'maxframe)
    (add-hook 'window-setup-hook 'maximize-frame t)

If using two framebuffers (monitors), it might be necesssary to specify a
mf-max-width value set to the pixel width of main framebuffer.  This is
necessary because emacs does not yet support sniffing different
framebuffers.  Example:

    (require 'maxframe)
    (setq mf-max-width 1600)  ;; Pixel width of main monitor.
    (add-hook 'window-setup-hook 'maximize-frame t)

To restore the frame to it's original dimensions, call restore-frame:

    M-x restore-frame

How it works
------------
puts the emacs frame in the top left corner of the display and calculates
the maximum number of columns and rows that can fit in the display

Limitations
-----------
Requires Emacs 22 (for fringe support), but maximize-frame still works
under Emacs 21 on Windows.

Credits
-------
The w32 specific functions were borrowed from the Emacs Manual:
http://www.gnu.org/software/emacs/windows/big.html#windows-like-window-ops
