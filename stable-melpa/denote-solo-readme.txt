denote-solo provides workspace-like switching between Denote
directories.  Denote calls such directories "silos"; denote-solo
keeps exactly one of them active at a time and calls it a "solo".
Unlike denote-silo, which prompts you to pick a directory on every
command, you switch once with `denote-solo-switch', and every
subsequent Denote command operates in that solo until you switch
again.

The active solo is remembered across sessions and is shown in the
mode line.  Enable the package with the global minor mode:

    (denote-solo-mode 1)

See the README for a fuller walkthrough.
