This package provides scrolling commands and several customization
options.  The commands use `pulse' to display a quickly fading
guideline on the line at which new contents are visible after
scrolling.  Also, scrolling can be divided into adjustable steps at
the desired speed.  Together, these features help your eyes to keep
their place in the buffer while scrolling.

To use this package, simply bind these commands to your preferred
keys:

+ `scrollkeeper-up'
+ `scrollkeeper-down'

;; Credits

+ Inspired by Clemens Radermacher's blog post, <https://with-emacs.com/posts/keep-scrollin-scrollin-scrollin/>.
+ Aided by studying Michael Heerdegen's package, <https://github.com/michael-heerdegen/on-screen.el>.

;; See also

These packages provide some similar functionality but in very different ways.

+ https://github.com/michael-heerdegen/on-screen.el: A more complex
and comprehensive implementation that uses hooks to observe
scrolling in other windows.

+ https://github.com/ska2342/highlight-context-line/: Highlights
the boundary line statically, using a minor mode rather than
commands.

+ https://github.com/Malabarba/beacon: Highlights the cursor rather
than the boundary line between new and old content.
