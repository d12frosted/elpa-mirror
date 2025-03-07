Emacs IPython Notebook (EIN), despite its name, is a jupyter client for all
languages.  It does not work under non-WSL Windows environments.

As of 2023, EIN has been sunset for a number of years having been
unable to keep up with jupyter's web-first ecosystem.  Even during
its heyday EIN never fully reconciled emac's monolithic buffer
architecture to the notebook's by-cell discretization, leaving
gaping functional holes like crippled undo.

**As of 2025, a greenfield notebook implementation resides at,**

https://github.com/commercial-emacs/xjupyter.git

It features full-fledged undo and relies on "mode overlays"
instead of the complex and fragile polymode.
