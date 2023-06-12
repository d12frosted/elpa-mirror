This package enables inline playback of animated GIF or PNG in Org
buffers.

Usage:

Download org-inline-anim.el and insall it using package.el.

  (package-install-file "/path-to-download-dir/org-inline-anim.el")

Enable this feature in an Org buffer with M-x org-inline-anim-mode.
Add the following line in your init file to automatically enable
the feature in newly opened Org buffers.

  (add-hook 'org-mode-hook #'org-inline-anim-mode)

Now you can play animated GIF or PNG images in Org.

M-x org-inline-anim-animate (C-c C-x m) plays the animation once.
With a single prefix (C-u), it plays the animation in loop mode.
With a double prefix (C-u C-u), it shows the last frame and stops playback.
With a numeric arg 0 (C-u 0 or C-0), it shows the first frame and stops playback.

M-x org-inline-anim-animate-all (C-c C-x M) plays all animations
in the buffer at once.  The same prefix arguments are effective.

You can assign a non-nil value to `org-inline-anim-loop' for
animations to loop by default.  A single prefix (C-u) then means to
play only once.
