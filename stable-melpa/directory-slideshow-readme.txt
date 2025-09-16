┌─────────┐
│ Summary │
└─────────┘
The premise of this package is that if you have a folder, you have
a slideshow.  The files are the slides.  You can create slideshows by
putting files (or symlinks) in folders.  But you can also present
the contents of some arbitrary directory created for some other
purpose.

The slides themselves are completely ordinary buffers with no
additional settings associated with the slideshow.  Slide
transitions and are performed from a separate control frame,
inspired by Ediff.  Further, the package imposes no restrictions on
which file types may be used as slides.  This makes slides
interactive—you can highlight, edit, navigate, execute code,
find-file, split-window, etc., all without inhibitions.  Moreover,
you can present the files you already have with no additional
setup, such as, for example, a photo album.

┌──────────┐
│ Features │
└──────────┘
- Speaker notes via '<file-name>.<ext>.speaker-notes'
- Upcoming slide previews in control frame
- Chunk (split window, 2 files per slide)
- Sliding Window (split window, sliding window effect)
- Autoplay slides
- Wrap around to beginning of slides
- With Dired-Narrow, can present a subset of files.
- Styles can be applied using `directory-slideshow-after-slide-render-hook'.

┌──────────────┐
│ Installation │
└──────────────┘
Example Elpaca + use-package installation with custom keymap

 (use-package directory-slideshow
   :ensure (:host github :repo "Duncan-Britt/directory-slideshow")
   :custom
   ((directory-slideshow-include-directories? t)
    (directory-slideshow-use-default-bindings nil))
   :bind
   (:map directory-slideshow-mode-map
         ("j" . directory-slideshow-advance)
         ("k" . directory-slideshow-retreat)
         ("l" . directory-slideshow-toggle-play)
         ("q" . directory-slideshow-quit)
         ("p" . directory-slideshow-toggle-preview-next-slide)
         ("w" . directory-slideshow-toggle-wrap-around)
         ("d" . directory-slideshow-toggle-autoplay-direction)
         ("t" . directory-slideshow-set-autoplay-timer)
         ("m" . directory-slideshow-set-presentation-mode)
         ("i" . directory-slideshow-toggle-landscape-images)))

┌───────┐
│ Usage │
└───────┘
The command `directory-slideshow-start' will either prompt you for
a directory, or, if in Dired, will initialize a slideshow with the
files ins the current buffer.  Then all the relevant keybindings
for navigation and settings will be visible within the control
frame.

`directory-slideshow-after-slide-render-hook' provides a means by
which you can customize the appearance of slides.  For example,

 (defun my/slideshow-text-adjustment ()
   (when (derived-mode-p 'text-mode)
     (text-scale-set 2)
     (olivetti-mode 1)
     (olivetti-set-width 60)))

 (add-hook 'directory-slideshow-after-slide-render-hook
           #'my/slideshow-text-adjustment)


By default, slides are ordered lexicographically by file
name.  `directory-slideshow-file-name-sort-compare-fn' can be set to
a custom function to change the way the slides are ordered.

To make any settings local to a slideshow, use '.dir-locals'.
