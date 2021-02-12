Picpocket is an image viewer which requires GNU Emacs 27.1 or later
or 25.1-26.3 compiled with ImageMagick.  It have commands for:

* File operations on the picture files (delete, move, copy, hardlink).
* Scale and rotate the picture.
* Associate pictures with tags which are saved to disk.
* Filter pictures according to tags.
* Customizing keystrokes for quick tagging and file operations.
* Undo and visual history of undoable commands.


Main entry points
-----------------

Command: picpocket
  View the pictures in the current directory.

Command: picpocket-directory
  View the pictures in specified directory.


Main keybindings
----------------

Space     - Next picture
BackSpace - Previous picture
r         - Rename picture file
c         - Copy picture file
k         - Delete picture file
t         - Edit tags
s         - Slide-show mode
[         - Rotate counter-clockwise
]         - Rotate clockwise
+         - Scale in
-         - Scale out
u         - Undo
M-u       - View history of undoable actions
e         - Customize keystrokes (see below)
TAB f     - Toggle full-screen
TAB r     - Toggle recursive inclusion of pictures in sub-directories
l l       - List current pictures
l n       - List current pictures with thumbnails
l T       - Browse tag database

With prefix argument many of the commands will operatate on all the
pictures in the current list instead of just the current picture.


Disclaimer
----------

Picpocket will secretly do stuff in the background with idle
timers.  This includes to load upcoming pictures into the image
cache.  The intention is that they should block Emacs for so short
periods that it is not noticable.  But if you want to get rid of
them set `picpocket-inhibit-timers' or kill the picpocket buffer.


Keystroke customization
-----------------------

Keystokes can be bound to commands that move/copy pictures into
directories and/or tag them.  The following creates commands on
keys 1 though 5 to tag according to liking.  Also creates some
commands to move picture files to directories according to genre.
Finally creates also one command to copy pictures to a backup
directory in the user's home directory.

(defvar my-picpocket-alist
  '((?1 tag "bad")
    (?2 tag "sigh")
    (?3 tag "good")
    (?4 tag "great")
    (?5 tag "awesome")
    (?F move "fantasy")
    (?S move "scifi")
    (?P move "steampunk")
    (?H move "horror")
    (?U move "urban-fantasy")
    (?B copy "~/backup")))

(setq picpocket-keystroke-alist 'my-picpocket-alist)

Digits and capital letters with no modifiers is reserved for these
kind of user keybindings.

It is recommended to set `picpocket-keystroke-alist' to a symbol as
above.  That makes the command `picpocket-edit-keystrokes' (bound
to `e' in picpocket buffer) jump to your definition for quick
changes.  Edit the list and type M-C-x to save it.

See the doc of `picpocket-keystroke-alist' for about the same thing
but with a few more details.


Tag database
------------

Tags associated with pictures are saved to disk.  By default to
~/.emacs.d/picpocket/.  This database maps the sha1 checksum of
picture files to list of tags.  This implies that you can rename or
move around the file anywhere and the tags will still be remembered
when you view it with picpocket again.

If you change the picture file content the sha1 checksum will
change.  For example this would happen if you rotate or crop the
picture with an external program.  That will break the association
between sha1 checksum and tags.  However picpocket also stores the
file name for each entry of tags.  The command
`picpocket-db-update' will go through the database and offer to
recover such lost associations.

If you change the file-name and the file content at the same time
there is no way to recover automatically.
