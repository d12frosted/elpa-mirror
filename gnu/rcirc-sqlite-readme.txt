1 rcirc-sqlite: rcirc logging in SQLite
═══════════════════════════════════════

  Find here the source for `rcirc-sqlite.el', that stores the logging
  from `rcirc' into a SQLite database.

  `rcirc' is a default, simple IRC client in Emacs. rcirc can be enabled
  to log the IRC chats, it logs to files.

  This minor mode, when activated, diverts the rcirc logs to a SQLite
  database.


2 Installation and activation
═════════════════════════════

2.1 Installation
────────────────


2.2 Install from GNU ELPA
─────────────────────────

  The GNU ELPA package name is: `rcirc-sqlite'

  To install the package:

  • `M-x package-refresh-contents'
  • `M-x package-install'

  and search for `rcirc-sqlite'.

  Or use `use-package'

  ┌────
  │ (use-package rcirc-sqlite
  │     :ensure t
  │     :config
  │     (add-hook 'rcirc-mode-hook #'rcirc-sqlite-log-mode))
  └────


2.3 Manual installation
───────────────────────

  Create a directory for the package.

  ┌────
  │ mkdir ~/.emacs.d/manualpackages
  └────

  At this directory as a load path to your init file:

  ┌────
  │ (add-to-list 'load-path "~/.emacs.d/manualpackages")
  │ (require 'rcirc-sqlite)
  └────

  Re-evaluate your init file or restart Emacs, whatever you prefer.


2.4 Activation
──────────────

  The command `rcirc-sqlite-log-mode' toggles between activation and
  deactivation of `rcirc-sqlite'.


  To start `rcirc-sqlite' automatically when `rcirc' is started, add the
  following to your init file:

  ┌────
  │ (require 'rcirc-sqlite)
  │ (add-hook 'rcirc-mode-hook #'rcirc-sqlite-log-mode)
  └────


3 Usage
═══════

  Use the following commands to query the database.

  • `M-x rcirc-sqlite-view-log': display the logs.
  • `M-x rcirc-sqlite-text-search' perform full text search in the logs.
  • `M-x rcirc-sqlite-stats' displays some stats.


3.1 `rcirc-sqlite-view-log'
───────────────────────────

  Default this commands shows the last 200 messages, optionally narrowed
  to a specific channel, or month.


3.2 `rcirc-sqlite-text-search'
──────────────────────────────

  Perform full text searches in the database.

  Prompts:

  • for a search string
  • for a channel
  • for a month
  • for a nick

  Completion is used to choose a channel, month, or nick.

  When a channel is chosen, the search is performed within the chat logs
  of that specific channel. Choose `All channels' to search everywhere.

  When a month is chosen, the search is performed within the messages
  that were send in that specific month. Choose `Anytime' to search
  everywhere.

  When a nick is chosen, the search is performed within the chats of
  that specific nick. Choose `All nicks' to search independent of the
  sender.

  The search string is used to do a full text search in the SQLite
  database. When the search string is `foo', chat messages containing
  the word `foo' will be found, but chat messages containing the word
  `foobar' will not be found.

  To search for both `foo' and `foobar', use the search string `foo*'.

  Likewise, to search for URLs, use something like `"http://*"' or
  `"https://*"' as search string, or for example `"gopher://*"'. Because
  of the colon (`:'), the double quotes (`"') here are required.


3.3 `rcirc-sqlite-stats'
────────────────────────

  This command gives an overview of the number of messages in the
  database.

  The user is prompted for a nick. Choose a nick through completion.

  When a nick is chosen, the buffer `*rcirc log*' is opened where each
  channel with one or more chat messages from that nick is listed,
  together with the number of chat messages from that nick.

  When `All nicks' is chosen, the buffer shows the row count for each
  channel in the database.

  When `Nicks per channel' is chosen, the buffer shows for each channel
  the number of uniq nicks.

  When `Channels per nick' is chosen, the buffer shows for each nick the
  number of channels with messages from this nick.

  Use drill-down in the stats buffer to get more details, either by the
  "RET" key, or the left mouse button.


4 Contribute
════════════

  A copyright assignment to the FSF is required for all non-trivial code
  contributions.


5 Source code
═════════════

  `rcirc-sqlite' is developed at [Codeberg].


[Codeberg] <https://codeberg.org/mattof/rcirc-sqlite>


6 Bugs and patches
══════════════════

  Please use the "Issues" option in the Codeberg repository.


7 Distribution
══════════════

  `rcirc-sqlite.el' and all other source files in this directory are
  distributed under the GNU Public License, Version 3, or any later
  version.
