
Archive and reference source code snippets

This package provides commands for saving selecting code regions and
inserting them as org-mode styled code blocks. These code blocks are
tagged with an id that allows jumping back to the original source file.
The original source file is archived in a git managed repo each time
a code block is saved.

Saving full file copies enables referencing the orignal context and
avoids the problem of locating bookmarked regions when the file becomes
massively mutated or deleted. Using git solves the problem of saving
multiple versions of a file history in a space efficient way.

Additional helpers are provided for org-capture templates.

See the README for usage at https://github.com/mschuldt/code-archive
