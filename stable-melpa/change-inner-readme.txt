# change-inner.el

change-inner gives you vim's `ci` command, building on
[expand-region](https://github.com/magnars/expand-region.el). It is most easily
explained by example:

    function test() {
      return "semantic kill";
    }

With point after the word `semantic`

 * `change-inner "` would kill the contents of the string
 * `change-outer "` would kill the entire string
 * `change-inner {` would kill the return-statement
 * `change-outer {` would kill the entire block

I use `M-i` and `M-o` for this.

Giving these commands a prefix argument `C-u` means copy instead of kill.

## Installation

Start by installing
[expand-region](https://github.com/magnars/expand-region.el).

    (require 'change-inner)
    (global-set-key (kbd "M-i") 'change-inner)
    (global-set-key (kbd "M-o") 'change-outer)

## It's not working in my favorite mode

That may just be because expand-region needs some love for your mode. Please
open a ticket there: https://github.com/magnars/expand-region.el
