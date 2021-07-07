Freeze It
=========

An Emacs minor mode to kill your inner editor! Every writer struggles to
balance their creative and critical sides, with progress frequently
hindered by the temptation to go back and revise to get things *just
right*. Freeze It aims to combat this temptation.

After an idle delay freeze-it-delay all text between point-min and a
configurable distance before point will be made read-only.

Option freeze-it-go-back controls how far this distance "goes back"
before freezing text. This can be nil, word, line, visible-line,
line, or paragraph.

Command freeze-it-show will momentarily highlight read-only text in
the buffer while there is no user input. The highlighting uses
freeze-it-show face and displays for freeze-it-show-delay seconds.

Text remains read-only until you kill the buffer, so that you can't
cheat. This is by design, because the minor mode targets the
psychological *temptation* to revise your writing, rather than just the
ability.

[1]: https://stable.melpa.org/#/freeze-it
[2]: https://melpa.org/#/freeze-it
