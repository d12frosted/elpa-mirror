
Some actions and conveniences for interacting with various version control
packages.

See embark for detailed docs about setup & the README for a table of all the
keymaps and actions.

In short, embark allows one to define a "target" (in this instance we have
topic, pull-request, issue, commit and conflict) upon which actions can be
performed onto.

This package allows conveniences such as (for the purposes of these C-; will represent `embark-act'):
- Starting a review for a PR with C-; r
- Yank a PR URL with C-; y
- Keep the top/bottom/whole merge conflict with C-; /t/b/a

And many more. It should also be quite simple to add any desired functions to
the keymaps.
