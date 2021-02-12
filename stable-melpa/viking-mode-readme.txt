Viking minor  mode enables you to  delete things at point  with one
key stroke at once. More and more will be deleted if you repeat the
key stroke.  As visual  feedback the  thing to  be deleted  will be
highlighted shortly.

The default key binding is C-d, but  you may also bind it to C-k or
whatever you wish.

If you press C-d the first time,  the word at point will be deleted
(but if there's no word at  point but whitespaces or an empty line,
they will be deleted instead, which is the same as M-SPC).

If you press  C-d again, the remainder of the  line from point will
be deleted.  If pressed again,  the whole line, then  the paragraph
and finally the whole buffer will be deleted.

Like:
[keep pressing ctrl] C-d                  - del word | spc
                     C-d C-d              - del line remainder
                     C-d C-d C-d          - del line
                     C-d C-d C-d C-d      - del paragraph
                     C-d C-d C-d C-d C-d  - del buffer

However, this only works when pressing the  key in a row. If you do
something  else in  between, it  starts from  scratch (i.e.  delete
word).

You can also repeat the last delete function with C-S-d (ctrl-shift-d)
multiple times.

By default viking-mode is greedy: after applying a kill function it
looks  if  point  ends  up  alone   on  an  empty  line  or  inside
whitespaces.  In  such a case, those  will be deleted as  well. The
greedy behavior may be turned off however.

Another  variant is  to use  viking  mode together  with the  great
expand-region mode (available on  melpa). If installed and enabled,
a  region is  first marked  using expand-region  and then  deleted.
This makes the deletion cascade language aware.
