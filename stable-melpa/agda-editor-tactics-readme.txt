Agda uses a number of editor tactics, such as C-c C-c, to perform case
analysis or to extract inner definitions to the toplevel.  We add a new
tactic.

Select an Agda record, then press M-x agda-editor-tactics-as-Σ:nested,
tabbing along the way, to obtain a transformed Σ-product form of the record.

This tactic was requested in the Agda mailing list,
I will likely produce other tactics as requested ---time permitting.

This file has been tangled from a literate, org-mode, file.
