This package is a port of nvim-treesitter/nvim-treesitter-textobjects.
This package will let you create evil textobjects using the power
of treesitter grammars.  You can easily create
function,class,comment etc textobjects in multiple languages.

You can do a sample map like below to create a function textobj.
(define-key evil-outer-text-objects-map "f"
            (evil-textobj-treesitter-get-textobj "function.outer"))
`evil-textobj-treesitter-get-textobj' will return you a function
that you can use in a define-key map.  You can pass in any of the
supported queries as an arg of that function.  You can also pass in
multiple queries as a list and we will match on all of them, ranked
on which ones comes up first in the file.
You can find more info in the  README.md file at
https://github.com/meain/evil-textobj-treesitter
