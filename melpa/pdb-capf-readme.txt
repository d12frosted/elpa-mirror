`completion-at-point' function that provides completions for current
pdb session.

Add `pdb-capf' to `completion-at-point-functions' in buffer with
existing pdb session, e.g.:

  (add-hook 'completion-at-point-functions 'pdb-capf nil t)
