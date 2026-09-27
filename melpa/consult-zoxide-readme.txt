Jump to any directory zoxide remembers, from a Consult prompt.

  M-x consult-zoxide

Entries keep zoxide's own ranking and are annotated with their score
and, for git checkouts, the branch that is currently out.  Narrowing
keys select subsets: g git checkout roots, w worktrees, d entries
whose directory no longer exists.

A prefix argument lists the vanished entries too, which is how they get
pruned: narrow with d, then `embark-act-all' the removal action.  That
batch goes through unquestioned, every directory in it being gone
already; a batch holding directories that still exist is confirmed
first, so a mis-narrowed `embark-act-all' cannot empty the database.

Two integrations are opt-in, so that installing this package changes
nothing about Embark or consult-dir until you ask it to:

  (with-eval-after-load 'embark
    (consult-zoxide-embark-register))

  (with-eval-after-load 'consult-dir
    (consult-zoxide-consult-dir-register))

The first gives zoxide rows their own Embark keymap, the removal
action above among them, and lives in the `consult-zoxide-embark'
file.  The second adds a Zoxide source to `consult-dir'.  Neither
Embark nor consult-dir is a dependency.

`consult-zoxide-read' is the library entry point: it prompts and
returns a directory without visiting it, for callers such as an
Eshell `z' command.
