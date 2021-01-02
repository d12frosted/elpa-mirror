
The code provides a abbreviation expansion for Emacs.  Its fairly
similar to "dabbrev" expansion, which works based on the contents
of the current buffer (or other buffers).

Predictive abbreviation expansion works based on the previously
written text.  Unlike dynamic abbreviation, the text is analysed
during idle time, while Emacs is doing nothing else.  `pabbrev-mode'
tells you when this is happening.  If this irritates you unset
`pabbrev-idle-timer-verbose'.  The advantage of this is that its
very quick to look up potential abbreviations, which means that they
can be constantly displayed, without interfering with the user as
they type.  Certainly it works for me, on an old laptop, typing as
fast as I can (which is fast, since I learnt to type with four
fingers).

pabbrev's main entry point is through the minor mode
`pabbrev-mode'.  There is also a global minor mode, called
`global-pabbrev-mode', which does the same in all appropriate
buffers.

The current user interface looks like so...

p[oint]
pr[ogn]
pre[-command-hook]
pred[ictive]

As the user types the system narrows down the possibilities.  The
narrowing is based on how many times the words have been used
previously.  By hitting [tab] at any point the user can complete the
word.  The [tab] key is normally bound to `indent-line'.
`pabbrev-mode' preserves access to this command (or whatever else
[tab] was bound to), if there is no current expansion.

Sometimes you do not want to select the most commonly occurring
word, but a less frequently occurring word.  You can access this
functionality by hitting [tab] for a second time.  This takes you
into a special suggestions buffer, from where you can select
secondary selections.  See `pabbrev-select-mode' for more
details. There is also an option `pabbrev-minimal-expansion-p'
which results in the shortest substring option being offered as the
first replacement.

But is this actually of any use? Well having use the system for a
while now, I can say that it is sometimes.  I originally thought
that it would be good for text, but in general its not so
useful.  By the time you have realised that you have an expansion
that you can use, hit tab, and checked that its done the right
thing, you could have just typed the word directly in.  It's much
nicer in code containing buffers, where there tend to be lots of
long words, which is obviously where an abbreviation expansion
mechanism is most useful.

Currently pabbrev builds up a dictionary on a per major-mode basis.
While pabbrev builds up this dictionary automatically, you can also
explicitly add a buffer, or a region to the dictionary with
`pabbrev-scavenge-buffer', or `pabbrev-scavenge-region'.  There is
also a command `pabbrev-scavenge-some' which adds some words from
around point.  pabbrev remembers the word that it has seen already,
so run these commands as many times as you wish.

Although the main data structures are efficient during typing, the
pay off cost is that they can take a reasonable amount of time, and
processor power to gather up the words from the buffer.  There are
two main settings of interest to reduce this, which are
`pabbrev-scavenge-some-chunk-size' and
`pabbrev-scavenge-on-large-move'.  `pabbrev-mode' gathers text from
around point when point has moved a long way.  This means symbols
within the current context should be in the dictionary, but it can
make Emacs choppy, in handling.  Either reduce
`pabbrev-scavenge-some-chunk-size' to a smaller value, or
`pabbrev-scavenge-on-large-move' to nil to reduce the effects of
this.

NOTE: There are a set of standard conventions for Emacs minor
modes, particularly with respect to standard key bindings, which
pabbrev somewhat abuses.  The justification for this is that the
whole point of pabbrev mode is to speed up typing.  Access to its
main function has to be on a very easy to use keybinding.  The tab
seems to be a good choice for this.  By preserving access to the
original tab binding when there is no expansion, pabbrev mostly
"does what I mean", at least in my hands.

; Installation:

To install this file place in your `load-path', and add

(require 'pabbrev)

to your .emacs
