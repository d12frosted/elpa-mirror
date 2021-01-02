Minor mode to sync org-mode buffer and trello board

1) Add the following to your Emacs init file
- Either activate org-trello-mode in an org-buffer - M-x org-trello-mode

- Or add this in your Emacs setup
(require 'org-trello)
(add-hook 'org-mode-hook 'org-trello-mode)

2) Once - Install the consumer-key and read/write access-token for org-trello
to work in your name with your boards (C-c o i) or
M-x org-trello-install-key-and-token
(See http://org-trello.github.io/trello-setup.html#credentials for more
details)

You may want:
- to connect your org buffer to an existing board (C-c o I).  Beware that
this will only install properties needed to speak with trello board (and
nothing else).
M-x org-trello-install-board-metadata

- to update an existing org-buffer connected to a trello board (C-c o u).
M-x org-trello-update-board-metadata

- to create an empty board directly from a org-mode buffer (C-c o b)
M-x org-trello-create-board-and-install-metadata

3) Now check your setup is ok (C-c o d)
M-x org-trello-check-setup

6) For some more help (C-c o h)
M-x org-trello-help-describing-setup

7) The first time you attached your buffer to an existing trello board, you
may want to bootstrap your org-buffer (C-u C-c o s)
C-u M-x org-trello-sync-buffer

8) Sync a card from Org to Trello (C-c o c / C-c o C)
M-x org-trello-sync-card

9) Sync a card from Trello to Org (C-u C-c o c / C-u C-c o C)
C-u M-x org-trello-sync-card

10) Sync complete org buffer to trello (C-c o s)
M-x org-trello-sync-buffer

11) As already mentioned, you can sync all the org buffer from trello
(C-u C-c o s) or C-u M-x org-trello-sync-buffer

12) You can delete an entity, card/checklist/item at point (C-c o k)
M-x org-trello-kill-entity

13) You can delete all the cards (C-c o K / C-u C-c o k)
M-x org-trello-kill-cards / C-u M-x org-trello-kill-entity

14) You can directly jump to the trello card in the browser (C-c o j)
M-x org-trello-jump-to-trello-card

15) You can directly jump to the trello board in the browser
(C-c o J / C-u C-c o j)
M-x org-trello-jump-to-trello-board / C-u M-x org-trello-jump-to-trello-card

Now you can work with trello from the comfort of org-mode and Emacs

Enjoy!

More informations: https://org-trello.github.io
Issue tracker: https://github.com/org-trello/org-trello/issues
