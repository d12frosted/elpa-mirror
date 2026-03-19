Solo-rpg is a set up support functions for playing solo roleplaying games
in Emacs.

Features include:
- Syntax highlighting of the Lonelog Solo RPG notation system
- Dice rolling
- Oracles:
  - Yes/No Oracle with probabilities
  - Action/Theme Oracle, inspired by the Mythic Game Master Emulator
  - Tarot cards with meanings
- Generators:
  - NPC name, appearance, and personality
  - Narrative events
  - Weather
  - Dungeon rooms and random events
  - Wilderness random events
  - City random events

To use this package, add the following to your configuration:

  (require 'solo-rpg)
  (with-eval-after-load 'solo-rpg
    ;; Note - you can replace "C-c r" with another key if you prefer
    (define-key solo-rpg-mode-map (kbd "C-c r") 'solo-rpg-menu)

To start solo-rpg-mode, type:

  M-x solo-rpg-mode

Once solo-rpg-mode is started, you can invoke the dashboard menu by
typing the shortcut key you chose above ("C-c r" by default).

Customization:

All cusomtization can be done by typing:

  M-x customize-group RET solo-rpg RET

  `solo-rpg-output-method' can be set to 'insert or 'message.
     - If set to 'message, output will be sent to message buffer only.
     - If set to 'insert, output will also be inserted in current buffer.
  `solo-rpg-auto-open-hud' can be set to t or nil, and determines whether
     or not the HUD which tracks Lonelog tags will be opened automatically.
