Emacs extension for driving just files

To list all the recipes present in your justfile, call

M-x justl

You don't have to call it from the actual justfile.  Calling it from
the directory where the justfile is present should be enough.

Alternatively, if you want to just execute a recipe, call

M-x justl-exec-recipe-in-dir

To execute default recipe, call justl-exec-default-recipe

Shortcuts:

On the just screen, place your cursor on a recipe

h => help popup
? => help popup
g => refresh
e => execute recipe
E => execute recipe with eshell
w => execute recipe with arguments
W => open eshell without executing

Customize:

By default, justl searches the executable named `just`, you can
change the `justl-executable` variable to set any explicit path.

You can also control the width of the RECIPE column in the justl
buffer via `justl-recipe width`.  By default it has a value of 20.
