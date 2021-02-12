This package provides digistar-mode, a major mode for editing Digistar
scripts.  If installed via elpa, the auto-mode-list entry for this mode
will be setup automatically.  If installed manually, use a snippet like
the following to set it up:

    (when (locate-library "digistar-mode")
      (add-to-list 'auto-mode-alist '("\\.ds\\'" . digistar-mode)))
