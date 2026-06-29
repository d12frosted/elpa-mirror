Entry point of this package is M-x midikbd-open RET

It opens a raw ALSA midi device (see its documentation for how to
deal with non-raw devices) and feeds MIDI note-on and note-off
events into the Emacs input queue associated with the terminal from
which midikbd-open has been called.  Macro recording and replay is
possible.  The interpretation of such events is left to
applications establishing appropriate key bindings.

Since macro recording and replay makes it very desirable to have
every generated event be interpretable standalone rather than split
into several Emacs events, every MIDI event is encoded into one
mouse-like event similar to <Ch1 C_4>.  Consequently, the following
functions are applicable to such events:

(event-start EVENT) returns the down event part
(event-end EVENT) returns the up event part

The up event is only available with bindings of <Ch1 up-C-4> and
similar, whereas the down event is available for all bindings.

up/down event parts may be further split with

(posn-area EV) returns a channel symbol Ch1..Ch16

(posn-x-y EV) returns numeric values 0..127 for pitch and velocity

(posn-timestamp EV) returns a millisecond time value that will wrap
around when reaching most-positive-fixnum, about every 12 days on a
32bit system.

Note events (omitting the channel modifier) are
<C_-1> <Csharp_-1> ... <G_9>

Since Midi does not encode enharmonics, there are no *flat_* key
names: it is the job of the key bindings to give a higher level
interpretation to the basic pitch.