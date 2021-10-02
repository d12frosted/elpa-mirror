This is a framework for a sort of meta mode which provides support
for multiple major modes in different regions (`chunks') of a
buffer -- sort of.  Actually, multiple indirect buffers are used,
one per mode (apart from the base buffer, which has the default
mode).  A post-command hook selects the correct buffer for the mode
around point.  This is done on the basis of calling the elements of
`multi-chunk-fns' and taking the value corresponding to a start
position closest to point.

[I originally tried maintaining information about the local major
mode on a text property maintained by font-lock along with a
`point-entered' property to control changing the indirect buffer.
This worked less well for reasons I've forgotten, unfortunately.
The post-command hook seems to be efficient enough in the simple
cases I've tried, and is most general.]

Using indirect buffers ensures that we always have the correct
local buffer properties like the keymap and syntax table, including
the local variable list.  There are other implementations of this
sort of thing, e.g. for literate programming, but as far as I know,
they all work either by continually re-executing the major mode
functions or by swapping things like the keymap in and out
explicitly.  Using indirect buffers seems to be the right thing and
is at least potentially more robust, for instance for things like
specific subprocesses associated with the buffer for Ispell or
whatever.  (However, it has the potential confusion of there
actually being multiple buffers, even if they mostly act like one.
It also may interact badly with other modes using
`post-command-hook', as with Flyspell.)  Also, it's fairly simple.

Maybe it won't turn out to be the best approach, but it currently
seems to me to be better than the approach used by MMM mode
<URL:http://mmm-mode.sourceforge.net/>, and is a lot less code.  I
suspect doing the job any better would require fairly serious
surgery on buffer behaviour.  For instance, consider being able
programmatically to treat discontinuous buffer regions as
continuous according to, say, text properties.  That would work
rather like having multiple gaps which the most primitive movement
functions skip.

The other major difference to MMM mode is that we don't operate on
more-or-less static regions in different modes which need to be
re-parsed explicitly and/or explicitly inserted.  Instead they're
dynamically defined, so that random editing DTRT.

Things like font-lock and Imenu need to be done piecewise over the
chunks.  Some functions, such as indentation, should be executed
with the buffer narrowed to the current chunk.  This ensures they
aren't thrown by syntax in other chunks which could confuse
`parse-partial-sexp'.

The intention is that other major modes can be defined with this
framework for specific purposes, e.g. literate programming systems,
e.g. literate Haskell, mixing Haskell and LaTeX chunks.  See the
example of haskell-latex.el, which can activate the literate mode
just by adding to `haskell-mode-hook'.  The multiple modes can also
be chosen on the basis of the file contents, e.g. noweb.el.

Problems:
* C-x C-v in the indirect buffer just kills both buffers.  (Perhaps an
  Emacs bug.)
* Flyspell needs modifying so as not to cause trouble with this.
  For the moment we hack the Flyspell hook functions.
* The behaviour of the region can appear odd if point and mark are in
  regions corresponding to different modes, since they are actually in
  different buffers.  We really want point and marks to be shared among
  the indirect buffers.
* `view-file' doesn't work properly -- only the main buffer gets the
  minor mode.  Probably fixable using `view-mode-hook'.
* Doubtless facilities other than Imenu, Font Lock and Flyspell
  should be supported explicitly or fixed up to work with this,
  e.g. by narrowing to the chunk around commands.  There may be a
  need for more hooks or other support in base Emacs to help.
* Fontification currently doesn't work properly with modes which
  define their own fontification functions, at least the way nXML mode
  does it.  nXML seems to need hacking to get this right, maybe by
  converting it to use font-lock.  nXML is the only mode I know
  which defines its own `fontification-functions', although PSGML
  does its own fontification differently again.  Generally, any
  fontification which doesn't respect the narrowing in force will
  cause problems.  (One might think about `flet'ting `widen' to
  `ignore' around fontification functions, but that means they can't
  parse from a previous point, as things like nXML should
  legitimately be able to do.)

Todo:
* Provide a simple way to define multi-chunk functions by a series
  of delimiting regexps, similarly to MMM mode -- someone asked for
  that.
* Provide a means for code describing `island' chunks, which
  doesn't know about the base or other modes, to describe a chain
  of chunks in that mode for mapping over chunks.