
This package defines commands which offer a more feature rich
alternative to the standard 'M-(' Emacs keybinding,
`insert-parentheses'.  These commands allow for the interactive
insertion, update and deletion of `customize'-able, mode-dependent
PAIRs via the use of overlays.

Suggested Keybinding:

   (global-set-key (kbd "M-(") 'ipe-insert-pair-edit)

Executing the `ipe-insert-pair-edit' command will first prompt the
user to enter a `customize'-able MNEMONIC (See: `ipe-pairs' /
`ipe-mode-pairs').  Entering a valid MNEMONIC will select a
'major-mode dependent' PAIR.  The PAIR consists of OPEN and CLOSE
strings which delimit text in some fashion.

The OPEN and CLOSE strings are then added to the buffer as
overlays, and the "Insert Pair Edit (ipe)" (`ipe-edit-mode') minor
mode is activated.

The "Insert Pair Edit (ipe)" minor mode supplies a large set of
commands to: interactively and independently move the overlays
representing the OPEN and CLOSE strings for the inserted PAIR about
the buffer, and; either insert (`ipe-edit--insert-pair'), or
discard (`ipe-edit--abort') them once they have been correctly
positioned.

Further help can be found after installation, from either:

* the keyboard:

  M-x ipe-help
  M-x ipe-help-info
  M-x ipe-options

* or, (if `ipe-menu-support-p' is enabled), from the Emacs `Edit`
  menu:

  Edit >
    Pairs >
      Options
      Info
      Help

Customizations for the mode can be found under the `ipe' group.

-------------------------------------------------------------------
