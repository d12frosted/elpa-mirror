
This defines a new global minor-mode `speed-of-thought-mode', which
activates locally on any supported buffer.  Currently, only
`emacs-lisp-mode' buffers are supported.

The mode is quite simple, and is composed of two parts:

; Abbrevs

A large number of abbrevs which expand function
initials to their name.  A few examples:

- wcb -> with-current-buffer
- i -> insert
- r -> require '
- a -> and

However, these are defined in a way such that they ONLY expand in a
place where you would use a function, so hitting SPC after "(r"
expands to "(require '", but hitting SPC after "(delete-region r"
will NOT expand the `r', because that's obviously not a function.
Furthermore, "#'r" will expand to "#'require" (note how it omits
that extra quote, since it would be useless here).

; Commands

It also defines 4 commands, which really fit into this "follow the
thought-flow" way of writing.  The bindings are as follows, I
understand these don't fully adhere to conventions, and I'd
appreciate suggestions on better bindings.

- M-RET :: Break line, and insert "()" with point in the middle.
- C-RET :: Do `forward-up-list', then do M-RET.

Hitting RET followed by a `(' was one of the most common key sequences
for me while writing elisp, so giving it a quick-to-hit key was a
significant improvement.

- C-c f :: Find function under point.  If it is not defined, create a
definition for it below the current function and leave point inside.
- C-c v :: Same, but for variable.

With these commands, you just write your code as you think of it.  Once
you hit a "stop-point" of sorts in your thought flow, you hit `C-c f/v`
on any undefined functions/variables, write their definitions, and hit
`C-u C-SPC` to go back to the main function.

; Small Example

With the above (assuming you use something like paredit or
electric-pair-mode), if you write:

  ( w t b M-RET i SPC text

You get

  (with-temp-buffer (insert text))
