** What

=emacsshot= provides a few commands to take a screenshot of
Emacs from within Emacs.

[[./emacsshot.png]]

** Usage

*** Quick

With =emacsshot= there are

- =M-x emacsshot-snap-frame=
- =M-x emacsshot-snap-window=
- =M-x emacsshot-snap-window-include-modeline=
- =M-x emacsshot-snap-mouse-drag=

for creating a shot of Emacs.

*** Hints and Detais

With the default settings =M-x emacsshot-snap-frame= creates file
'~/emacsshot.png' which is a snapshot of the current Emacs-frame
with all its windows.

There is also =M-x emacsshot-snap-window= which is for creating a
snapshot of the current Emacs-window (i.e. the window which contains
the active cursor.)

There is function =emacsshot-snap-window-include-modeline=
which does the same as =emacsshot-snap-window= but also includes the
modeline when taking the shot.

There is function =emacsshot-snap-mouse-drag= which snaps the
rectangle defined by a drag i.e. press button-1, keep pressed, move
the mouse and release the button.

The filenames are configurable.  Hint: =M-x customize-group
emacsshot=.  Note that the file-suffix defines the image-format
under which the file gets stored.  Note that the filenames may
contain paths which allows some organization of the shots.

It's possible to add a timestamp to the filename as postfix.  See
=M-x customize-variable emacsshot-with-timestamp=.

It might be a good idea to bind the functions to a key.  This can
make the usage more convenient.  Further the binding is a way to
avoid images which contain the command that has been used to create
the image e.g. "M-x emacsshot-snap-frame" in the minibuffer.

Beware of the heisenshot!

Concretely the print-key could trigger the shot.  Evaluation of

#+BEGIN_EXAMPLE
(global-set-key [print] 'emacsshot-snap-frame)
(global-set-key (kbd "C-M-S-<mouse-1>") 'emacsshot-snap-mouse-drag)

#+END_EXAMPLE

yields this behavior.

Or evaluate

#+BEGIN_EXAMPLE
(global-set-key [print]
 (lambda (&optional current-window)
  (interactive "P")
  (if current-window (emacsshot-snap-window)
    (emacsshot-snap-frame))))
#+END_EXAMPLE

to be able to snap the frame by pressing the print-key and to snap the
current window by prefixing the keypress with C-u.

Note that emacsshot currently trys to overwrite any existing file with
the target name without asking.

** Install

*** Emacs Package

When emacsshot has been installed as elpa-package
[[http://melpa.org/#/emacsshot][file:http://melpa.org/packages/emacsshot-badge.svg]] then the functions
are available without need of further action.

*** Direct Install

Activate this program by loading it into Emacs and evaluate it with
=M-x eval-buffer=.

Automatically activate this program at Emacs start by adding the lines

#+BEGIN_EXAMPLE
(add-to-list 'load-path "/...path to this program...")
(require 'emacsshot)
#+END_EXAMPLE

to your .emacs or whatever you use for Emacs intitialization.

** Dependencies

- Emacs is running under X.
- The programm =convert= of the ImageMagick-suite is available.

=convert= actually creates the snapshots.

** Development

*** Ideas, Contributions, Bugs

Contributions, ideas and bug-reports are welcome.  Contact the
maintainer.

** Related

There is elpa-package 'screenshot' which allows to pick windows
with the mouse, even windows from non-Emacs (!) programs.  See
http://melpa.org/#/screenshot.  BTW 'screenshot' has even more!

emacsshot only takes images of Emacs.

** History

| 201501071941 | New function to take snapshot of a window |
| 201505162319 | Optionally add timestamp to save-filename |
| 201912060235 | New function to take snapshot of a rectangle defined by a mouse-drag |
