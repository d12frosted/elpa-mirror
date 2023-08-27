Emacs IPython Notebook (EIN), despite its name, is a jupyter client for all
languages.  It does not work under non-WSL Windows environments.

As of 2023, EIN has been sunset for a number of years having been
unable to keep up with jupyter's web-first ecosystem.  Even during
its heyday EIN never fully reconciled emac's monolithic buffer
architecture to the notebook's by-cell discretization, leaving
gaping functional holes like crippled undo.

Certainly in 2012 when jupyter was much smaller, an emacs client
made perfect sense.  With many years of hindsight, it's now clear
the json-driven, git-averse notebook format is anathema to emacs's
plain text ethos.
