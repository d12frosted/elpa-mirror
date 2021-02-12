
Purpose of this package: minor mode to repeat typing or commands

Installation instructions

Install this file somewhere in your load path, byte-compile it and
add one of the following to your .emacs file (remove the comment
delimiters ;-)

If you only want dot-mode to activate when you press "C-.", add the
the following to your .emacs:

    (autoload 'dot-mode "dot-mode" nil t) ; vi `.' command emulation
    (global-set-key [(control ?.)] (lambda () (interactive) (dot-mode 1)
                                      (message "Dot mode activated.")))

If you want dot-mode all the time (like me), add the following to
your .emacs:

    (require 'dot-mode)
    (add-hook 'find-file-hooks 'dot-mode-on)

You may still want to use the global-set-key above.. especially if you
use the *scratch* buffer.

To toggle dot mode on or off type `M-x dot-mode'

There are only two variables that allow you to modify how dot-mode
behaves:
          dot-mode-ignore-undo
          dot-mode-global-mode

dot-mode-ignore-undo - defaults to t.  When nil, it will record keystrokes
    that generate an undo just like any other keystroke that changed the
    buffer.  I personally find that annoying, but if you want dot-mode to
    always remember your undo's:
        (setq dot-mode-ignore-undo nil)
    Besides, you can always use dot-mode-override to record an undo when
    you need to (or even M-x undo).

dot-mode-global-mode - defaults to t.  When t, dot-mode only has one
    keyboard command buffer.  That means you can make a change in one
    buffer, switch buffers, then repeat the change.  When set to nil,
    each buffer gets its own command buffer.  That means that after
    making a change in a buffer, if you switch buffers, that change
    cannot repeated.  If you switch back to the first buffer, your
    change can then be repeated again.  This has a nasty side effect
    if your change yanks from the kill-ring (You could end up
    yanking text you killed in a different buffer).
    If you want to set this to nil, you should do so before dot-mode
    is activated on any buffers.  Otherwise, you may end up with some
    buffers having a local command buffer and others using the global
    one.

Usage instructions:

`C-.'    is bound to dot-mode-execute, which executes the buffer of
         stored commands as a keyboard macro.

`C-M-.'  is bound to dot-mode-override, which will cause dot-mode
         to remember the next keystroke regardless of whether it
         changes the buffer and regardless of the value of the
         dot-mode-ignore-undo variable.

`C-c-.'  is bound to dot-mode-copy-to-last-kbd-macro, which will
         copy the current dot mode keyboard macro to the last-kbd-macro
         variable.  It can then be executed via call-last-kbd-macro
         (normally bound to `C-x-e'), named via name-last-kbd-macro,
         and then inserted into your .emacs via insert-kbd-macro.

Known bugs:

none


; COMMENTARY
;
; This mode is written to address one argument in the emacs vs. vi
; jihad :-)  It emulates the vi `redo' command, repeating the
; immediately preceding sequence of commands.  This is done by
; recording input commands which change the buffer, i.e. not motion
; commands.

; DESIGN
;
; The heart of this minor mode is a state machine.  The function
; dot-mode-after-change is called from after-change-functions and
; sets a variable (is there one already?  I couldn't find it) which
; is examined by dot-mode-loop, called from from post-command-hook.
; This variable, dot-mode-changed, is used in conjunction with
; dot-mode-state to move to the next state in the state machine.
; The state machine is hard coded into dot-mode-loop in the
; interests of speed; it uses two normal states (idle and store)
; and two corresponding override states which allow the user to
; forcibly store commands which do not change the buffer.
;
; TODO
; * Explore using recent-keys for this functionality
