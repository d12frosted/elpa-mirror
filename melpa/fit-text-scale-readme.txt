
You are too lazy to do the C-x C-+ + + +... - - - - ... + + - dance
all the time to see the FULL line in maximal font size?

You want a keystroke to see the whole buffer at once by changing the
font size?


~fit-text-scale~ is an automation to set the scale so that the text
uses the maximal space to fit in the window.

Scale stands for the zoom of the font.

There are three functions:
- Choose the maximal text scale to still see the full line.
- Choose the maximal text scale to still see the full lines.
- Choose the maximal text scale to still see all lines of a buffer.

The following code in an init file binds the
functionality to keys. Of course you don't need
to use this binding. Your can choose your own.

#+begin_src emacs-lisp
(global-set-key
 (kbd "C-x C-&")
 (lambda (&optional arg)
   (interactive "P")
   (cond
    ((equal arg '(4)) (fit-text-scale-max-font-size-fit-line))
    ((equal arg '(16)) (fit-text-scale-max-font-size-fit-line-up-to-cursor))
    (t (fit-text-scale-max-font-size-fit-lines)))))

(global-set-key
 (kbd "C-x C-*")
   #'fit-text-scale-max-font-size-fit-buffer)
#+end_src

With these settings there is

- ~C-x C-&~
  - Choose maximal text scale so that the longest line visible still
    fits in current window.
- ~C-u C-x C-&~
  - Choose maximal text scale so that the current line still
    fits in the window.
- ~C-u C-u C-x C-&~
  - Choose maximal text scale so that the current line up to the cursor
    still fits in the window. This can be useful with visual-line-mode.
- ~C-x C-*
  - Choose maximal text scale so that the vertical buffer content
    still fits into current window.
- ~C-x C-0~ (Already given.  This is good old ~text-scale-adjust~.)
  - Switch back to the default size when control about the sizes has
    been lost.
- ~C-x C-+~ + - and ~C-x C--~ - + for fine tuning.  (Also given.)
- ~C-g C-g C-g~... (hit the keyboard hard!) if something, hrm, hangs.

There are some parameters to fine tune the functionality.  Check it out with

    M-x customize-group fit-text-scale


~fit-text-scale~ is available on melpa.


Or use the good old style:

- Download fit-text-scale.el.

- Add the lines (with YOUR path to fit-text-scale.el)
to your init file.

#+begin_src emacs-lisp
(push "/PATH/TO/fit-text-scale" load-path)
(require 'fit-text-scale)
#+end_src
