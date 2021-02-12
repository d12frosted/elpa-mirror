Place minibuffer at the top of the current frame on `read-from-minibuffer`.

While it's fine for me to have eldoc, flymake and other messages to appear
at the bottom of the screen, editing minibuffer (find file, create VC
branch, etc.) feels more comfortable in the upper area of the screen.

`mini-frame-mode` makes an advice around `read-from-minibuffer` function to
create and show minibuffer-only child frame to accept input.

By default mini-frame is placed at the top of the current frame and occupied
full width.  Those who use vertical completion candidates list may configure
mini-frame not to occupy full width:

  (custom-set-variables
   '(mini-frame-show-parameters
     '((top . 10)
       (width . 0.7)
       (left . 0.5))))

Users of Emacs 27 will benefits the most because of `resize-mini-frames`
variable: mini-frame will be resized vertically to fit content.

Users of Emacs 26 will need to configure frame height explicitly, e.g.:

  (custom-set-variables
   '(mini-frame-show-parameters
     '((top . 0)
       (width . 1.0)
       (left . 0.5)
       (height . 15))))

One can configure the list of commands that must not be shown in the child
frame by customizing the `mini-frame-ignore-commands`.
The `eval-expression` command is there by default because mini-frame have no
modeline to display eldoc hints.  And because there must be some place to
turn `mini-frame-mode` off if something goes wrong (I hope not) :)
