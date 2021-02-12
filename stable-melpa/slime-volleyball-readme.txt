For RMF.

I was inspired by Bret Victor's "Inventing on Principle" talk [1] and wanted
to see how close Emacs could get to the graphical interactivity and feedback
of his environment.

The resulting research effort turned up some Emacs capabilities that were
new to me.  I was happily surprised to find Emacs's librsvg support could
draw SVG right in a buffer.  svg-clock showed me how to do the animation;
the erase-buffer/insert-image approach is inefficient but it works [2].  I
even came across some early-stage experimentation toward an Elisp vector
graphics library [3].

To put it all together, I decided to clone a great Java game I played a long
time ago (with the excuse of testing icedtea-web), Slime Volleyball [4].

This is the result; I hope you find it fun.

1. http://vimeo.com/36579366
2. http://elpa.gnu.org/packages/svg-clock.html
3. http://lists.gnu.org/archive/html/bug-gnu-emacs/2010-05/msg00491.html
4. http://oneslime.net/

Features
========

* One player quest mode
  (press SPC on start-up)

* Two player face-off mode
  (press 2 on start-up)

* God mode: instantly apply Elisp framents to hack the game environment
  (press G during the game)

* Slime training mode: a statistical learning algorithm for training
                       opponent slimes
  (press t on start-up,
   use M-: (slime-volleyball-save-strategy ...) to save the strategy, make
   sure to manually save the quantize, hash-situation and controller
   functions you come up with -- see green-slime.el.gz)

  I used this mode to train Green Slime and Grey Slime.

* Frame-by-frame debugging
  (F9 to enter/exit frame-by-frame mode, F8 to advance a frame)

* Music: disabled by default due to EMMS requirement
  (customize slime-volleyball-enable-sound)

Controls
========

The controls are a little different than in other games because Emacs
doesn't recognized key-up events.

One Player Mode
---------------

C-b, left,  a: start moving left
C-f, right, d: start moving right
C-p, up,    w: jump
C-n, down,  s: stop

Two Player Mode
---------------

Left Slime:

C-b, a: start moving left
C-f, d: start moving right
C-p, w: jump
C-n, s: stop

Right Slime:

left:  start moving left
right: start moving right
up:    jump
down:  stop

Potential Future Features
=========================

* Network support for two player mode or slime Turing test

* Time-to-space mapping for opponent slime design, like in [1]

* 8-bit music composition mode

* A really hard non-statistical end boss
