
With Avy, you can move point to any position in Emacs – even in a
different window – using very few keystrokes.  For this, you look at
the position where you want point to be, invoke Avy, and then enter
the sequence of characters displayed at that position.

If the position you want to jump to can be determined after only
issuing a single keystroke, point is moved to the desired position
immediately after that keystroke.  In case this isn't possible, the
sequence of keystrokes you need to enter is comprised of more than
one character.  Avy uses a decision tree where each candidate position
is a leaf and each edge is described by a character which is distinct
per level of the tree.  By entering those characters, you navigate the
tree, quickly arriving at the desired candidate position, such that
Avy can move point to it.

Note that this only makes sense for positions you are able to see
when invoking Avy.  These kinds of positions are supported:

* character positions
* word or subword start positions
* line beginning positions
* link positions
* window positions

If you're familiar with the popular `ace-jump-mode' package, this
package does all that and more, without the implementation
headache.
