
Org-roam-bibtex, ORB for short, offers integration of Org-roam with BibTeX
Emacs software: Org-ref, Helm/Ivy-bibtex and Citar.  The main task of ORB is
to seamlessly expose Org-roam as a note management solution to these
packages, shadowing their native facilities for taking bibliographic
notes.  As its main feature, ORB enables expansion of BibTeX keywords in
Org-roam templates.

Main usage:

Call interactively `org-roam-bibtex-mode' or call (org-roam-bibtex-mode +1)
from Lisp.  Enabling `org-roam-bitex-mode' sets appropriate functions for
creating and retrieving Org-roam notes from Org-ref, Helm/Ivy-bibtex and
Citar.

Other commands:

- `orb-insert-link':  insert a link or citation to an Org-roam note that has
   an associated BibTeX entry
- `orb-note-actions': call a dispatcher of useful note actions

Soft dependencies: Org-ref, Citar, Helm, Ivy, Hydra, Projectile, Persp-mode
