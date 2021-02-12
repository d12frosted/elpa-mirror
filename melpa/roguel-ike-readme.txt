Description:

The goal of this project is to develop a coffee-break roguelike for Emacs.

The complete game will allow the player to create various characters
and to make them fulfill challenges like arena fight and short dungeon
explorations.

There isn't any level system.  Each stat can improve independently, by
doing related actions.  For example, sucessfull attacks will at term improve
character's strength.

Usage:

To load the file write this in your Emacs configuration:

    (add-to-list 'load-path "/path/to/roguel-ike/")
    (require 'roguel-ike)

Then, type `M-x roguel-ike`.

* use _y, u, h, j, k, l, b, n_ for movements
* use _._ to wait one turn
* use _<_ or _>_ to use stairs
* use _:_ to get information about your enemies
* use _s_ to use a skill
* use _q_ to quit

State of the project:

This project is an experiment :

* This is my first serious attempt to create a roguelike
* I'm using Emacs Lisp because I want to make it run on Emacs,
  but also to gain experience in Lisp programming and to see
  how a large Lisp program can be managed

Compatibilities:

It has been tested on Emacs 24.3.  It doesn't work on Emacs 23.

Dependencies:

* popup-el: [https://github.com/auto-complete/popup-el]

License:

This program is released under GPLv3 license.

See _LICENSE_ for more details.
