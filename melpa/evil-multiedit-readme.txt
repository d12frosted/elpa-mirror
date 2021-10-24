
This plugin was an answer to the lack of proper multiple cursor support in
Emacs+evil. It allows you to select and edit matches interactively,
integrating `iedit-mode' into evil-mode with an attempt at sensible defaults.

Since then, [evil-mc] has matured, and now that I use both I've found they
can coexist, filling different niches, complimenting evil's built-in
column/line-wise editing operations.

; Usage

Evil-multiedit does not automatically bind any keys. Call
`evil-multiedit-default-keybinds' to bind my recommended configuration:

 - S-r      (visual mode) Highlights all matches of the selection in the
            buffer.
 - M-d      In normal mode, this matches the word under the cursor.
              Consecutive presses will match the next match after point.
            In visual mode, the selection is used instead of the word at
              point.
            In insert mode, a blank marker (ala multiple cursors) is added at
              point.
 - M-S-d    Like M-d, but backwards instead of forward.
 - C-M-d    Restore the last iedit session.
 - RET      In normal mode, this toggles the iedit region at point.
            In visual mode, this disables all iedit regions *outside* the
              selection (i.e. restrict-to-region).
 - C-n/C-p  Navigate between iedit regions.

 This package also defines an ':ie[dit] REGEXP' ex command, to create iedit
 regions for every match of REGEXP.
