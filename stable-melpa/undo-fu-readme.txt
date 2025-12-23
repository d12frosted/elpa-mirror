Undo/redo convenience wrappers to Emacs default undo commands.

The redo operation can be accessed from a key binding
and stops redoing once the initial undo action is reached.

If you want to cross the initial undo boundary to access
the full history, running [keyboard-quit] (typically C-g)
lets you continue redoing for functionality not typically
accessible with regular undo/redo.

If you prefer [keyboard-quit] not interfere with undo behavior
You may optionally set `undo-fu-ignore-keyboard-quit' & explicitly
call `undo-fu-disable-checkpoint'.
