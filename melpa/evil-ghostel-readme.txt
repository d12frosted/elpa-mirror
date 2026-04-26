Provides evil-mode compatibility for the ghostel terminal emulator.
Synchronizes the terminal cursor with Emacs point during evil state
transitions so that normal-mode navigation works correctly.

Enable by adding to your init:

  (use-package evil-ghostel
    :after (ghostel evil)
    :hook (ghostel-mode . evil-ghostel-mode))
