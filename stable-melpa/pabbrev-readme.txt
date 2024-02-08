
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
details.  There is also an option `pabbrev-minimal-expansion-p'
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

; Package Support:

Some packages need extra support for pabbrev to work with. There are two
plists properties which package developers can use.

(put 'command-name 'pabbrev-expand-after-command t)

means that the following the named command (in this case command-name),
expansion will be offered. `self-insert-command' and a few others is
normally fine, but not always.

(put mode-name 'pabbrev-global-mode-excluded-modes t)

will mean that any buffer with this major mode will not have
global-pabbrev-mode activated.


; Bugs;

This package had an occasional bug which has historically been hard
to track down and reproduce.  Basically I end up with a load of
offering expansions in the buffer. It looks something like this....
pabbrev[-mode][v][ev][rev][brev][bbrev][abbrev] which is amusing
the first time, but more or less totally useless.

Thanks to the efforts of Martin Kuehl, I think we have tracked the
cause of the problem now (the old version depended on
pre-command-hook and post-command-hook being called
consecutively. But sometimes they get called twice). Please let us
know if you see this problem.

; Bug Reporting

Bug reports are more than welcome. However one particular problem
with this mode is that it makes heavy use of
`post-command-hook'. This is a very useful hook, but makes the
package difficult to debug. If you want to send in a bug report it
will help a lot if you can get a repeatable set of keypresses, that
always causes the problem.

; Implementation notes:

The core data structures are two hashes. The first of which looks
like this...
"the" -> ("the" . 5)
"there" -> ("there" . 3)

I call this the usage hash, as it stores the total number of times
each word has been seen.

The second hash which is called the prefix hash. It stores
prefixes, and usages...

"t"->
(("the" . 64)
 ("to" . 28)
 ("t" . 22)
 ("this" . 17))

"th"->
(("the" . 64)
 ("this" . 17)
 ("that" . 7))

"the"->
(("the" . 64)
 ("there" . 6)
 ("then" . 3)
 ("these" . 1))

The alist cons cells in the first hash are conserved in the second,
but the alists are not. The alist in the second hash is always
sorted, on the basis of word usage.

The point with this data structure is that I can find word usage
in constant time, from the first hash, and completions for a given
prefix, also in constant time. As access to completions happens as
the user types speed is more important here, than during
update, which is why the prefix hash maintains sorted alists. This
is probably at the cost of slower updating of words.

; Acknowledgements;

Many thanks to Martin Kuehl for tracking down the last bug which
stood between this being an "official" full release.

Once again I need to thank Stefan Monnier, for his comments on my
code base. Once day I will write a minor mode which Stefan Monnier
does not offer me advice on, but it would appear that this day has not
yet arrived!

I should also thank Kim F. Storm (and in turn Stephen Eglen), as
the user interface for this mode has been heavily influenced by
ido.el, a wonderful package which I use every day.

Carsten Dominik suggested I add the package suppport rather than the
existing defcustom which was not as good I think.

Scott Vokes added a nice patch, adding the single/multiple expansion, the
universal argument support and some bug fixes.
