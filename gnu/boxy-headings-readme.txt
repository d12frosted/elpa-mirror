			    ━━━━━━━━━━━━━━━
			     BOXY HEADINGS
			    ━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Usage
.. 1. `boxy-headings'
2. License
3. Development
.. 1. Setup
.. 2. Commands
..... 1. `eldev lint'
..... 2. `eldev compile'
..... 3. `eldev package'
..... 4. `eldev md5'


View org files as a boxy diagram.

`package-install RET boxy-headings RET'


1 Usage
═══════

1.1 `boxy-headings'
───────────────────

  To view all headings in an org-mode file as a boxy diagram, use the
  interactive function `boxy-headings'

  Suggested keybinding:
  ┌────
  │ (define-key org-mode-map (kbd "C-c r o") 'boxy-headings)
  └────

  To modify the relationship between a headline and its parent, add the
  property REL to the child headline. Valid values are:
  • on-top
  • in-front
  • behind
  • above
  • below
  • right
  • left

  The tooltip for each headline shows the values that would be displayed
  if the org file was in org columns view.

  <file:demo/headings.gif>


2 License
═════════

  GPLv3


3 Development
═════════════

3.1 Setup
─────────

  Install [eldev]


[eldev] <https://github.com/doublep/eldev#installation>


3.2 Commands
────────────

3.2.1 `eldev lint'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Lint the `boxy-headings.el' file


3.2.2 `eldev compile'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Test whether ELC has any complaints


3.2.3 `eldev package'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Creates a dist folder with `boxy-headings-<version>.el'


3.2.4 `eldev md5'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Creates an md5 checksum against all files in the dist folder.
