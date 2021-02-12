lisp-butt-mode brings fat lisp butts in shape.

With lisp-butt-mode e.g.

	))))))))))))))))))))))))))))))))

gets displayed nicely as (pun intended):

	).)

Also closing brackets are respected.

There is a global `lisp-butt-global-mode' and a local `lisp-butt-mode'
variant.

Global:

- Toggle the mode with {M-x lisp-butt-global-mode RET}.
- Activate the mode with {C-u M-x lisp-butt-global-mode RET}.
- Deactivate the mode with {C-u -1 M-x lisp-butt-global-mode RET}.

Local:

- Toggle the mode with {M-x lisp-butt-mode RET}.
- Activate the mode with {C-u M-x lisp-butt-mode RET}.
- Deactivate the mode with {C-u -1 M-x lisp-butt-mode RET}.

Unveil the full butt at the cursor temporarily with

    {M-x lisp-butt-unfontify RET}

Customize lisp-butt-auto-unfontify

    {M-x customize-variable RET lisp-butt-auto-unfontify RET }

for automatic unfontification when point hits a butt.

Some configuration is possible.  See

    {M-x customize-group RET lisp-butt RET}

To turn on lisp-butt-mode automatically see

    {M-x customize-variable RET lisp-butt-global-mode RET}

See also the literate source file for modifying the whole thing.  E.g. see
https://gitlab.com/marcowahl/lisp-butt-mode.
