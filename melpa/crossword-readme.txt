* Download and play crossword puzzles in Emacs.

* Includes a browser to view puzzles' detailed metadata, including
  progress of partially played puzzles.

* Optionally, play against the clock, with the built-in timer.




; Dependencies: (all already part of core Emacs)

seq            - for `seq--into-vector'
tabulated-list - for `tabulated-list-mode', etal.
hl-line        - for `hl-line-mode'
calendar       - for `calendar-read' etal.


; Dependencies: (external to Emacs)

The package uses either `wget' or `curl' to download packages from
the network. These are both long-established standard programs and
at least one is probably already installed on your computer.




; Installation:

 1) Evaluate or load or install this file.

 2) Optionally, define a global keybinding or defalias for functions
    `crossword'

       (global-set-key (kbd "foo") 'crossword))
       (defalias 'crossword 'foo)

    Depending on your temperament and style, you might also want to
    set direct keybindings and aliases for functions
    `crossword-download', `crossword-display', and `crossword-load';
    however, they're just one menu-selection away from function
    `crossword'.




; Configuration:

 M-x `customize-group' <RET> crossword <RET>

 Initially, you may want to change the default download path
 `crossword-save-path', but otherwise, try using the mode first
 without any customization.

 There exist four customizations for how POINT advances after you
 fill-in a square or navigate: `crossword-arrow-changes-direction'
 `crossword-wrap-on-entry-or-nav', `crossword-tab-to-next-unfilled'
 `crossword-auto-nav-only-within-clue'.

 If you don't usually play more than one crossword in a sitting,
 you may want to set `crossword-quit-to-browser' to NIL to save
 yourself a keystroke on exit.

 You can also customize the download sources to be used for network
 downloading (do share, please).

 There are also several 'faces' defined to allow custom colorization
 and fontification. Knock yourself out.



