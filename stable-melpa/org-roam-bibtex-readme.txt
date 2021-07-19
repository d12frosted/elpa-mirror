
This library offers an integration between Bibtex-completion and
Org-roam by delegating the tasks of note's creation, editing and
retrieval to Org-roam.  From the Org-roam's perspective, the
library provides a means to populate Org-roam templates with
bibliographic information secured through Bibtex-completion,.

To use it:

call interactively `org-roam-bibtex-mode' or call (org-roam-bibtex-mode +1)
from Lisp.

After enabling `org-roam-bibtex-mode', the function `orb-edit-notes' will be
used as `bibtex-completion-edit-notes-function' in Helm-bibtex, Ivy-bibtex.

Additionally, `orb-org-ref-edit-note', which is a simple wrapper around
`orb-edit-note', is installed as Org-ref's `org-ref-notes-function'.  See
Org-ref's documentation for how to setup many-files notes.  Take a notice
that because of its size, Org-ref is not a dependency of Org Roam BibTeX, so
it will not be pulled automatically by your package manager and must be
installed manually.

As a user option, `org-roam-capture-templates' can be dynamically
pre-expanded with BibTeX field values.  See `orb-preformat-keywords' for
more details.

Optionally, automatic switching to the perspective (Persp-mode) with the
notes project (Projectile) is possible.  See `orb-edit-note' for more
details.
