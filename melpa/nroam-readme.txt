nroam is a supplementary package for org-roam that replaces the backlink side
buffer of Org-roam.  Instead, it displays org-roam backlinks at the end of
org-roam buffers.

To setup nroam for all org-roam buffers, evaluate the following:
(add-hook 'org-mode-hook #'nroam-setup-maybe)
