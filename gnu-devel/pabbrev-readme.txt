           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            PABBREV - PREDICTIVE ABBREVIATION EXPANSIONS FOR
                                 EMACS
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Pabbrev provides predictive abbreviation expansion with no configuration
needed and works with any mode.

Pabbrev is another abbreviation expansion mode somewhat like
dabbrev-expand, in that it looks through the current buffer for symbols
that can complete the current symbol. Unlike dabbrev-expand, it does
this by discovering the words during the Emacs idle time, and places the
results into data structures which enable very rapid extraction of
expansions. The upshot of this is that it can offer suggestions as you
type, without causing an unacceptable slow down.

Pabbrev is a small package, un-intrusive and out of the way. Pabbrev can
be used with Emacs completion facilities and packages such as Company or
Corfu, for the user interaction and user interface.


1 Features
══════════

  • Timer-based auto-suggestions (does not block main user-interface)
  • In-buffer color-coded display of best candidate
  • Suggestions ranked by usage frequency or shortest-prefix
  • The best suggestion is inserted with TAB, on demand
  • List of all available suggestions


2 Installation and Configuration
════════════════════════════════

  Pabbrev is available from [GNU ELPA]. You can install it directly via
  `package-install'.

  To enable pabbrev in your Emacs, run `M-x global-pabbrev-mode'.


[GNU ELPA] <https://elpa.gnu.org/packages/corfu.html>


3 Key bindings
══════════════

  Pabbrev bind keybindings in pabbrev-mode-map, and currently only binds
  <TAB> key to pabbrev-expand-maybe function.


4 Contributions
═══════════════

  All non-significant contributions to this package require a copyright
  assignment to the FSF.
