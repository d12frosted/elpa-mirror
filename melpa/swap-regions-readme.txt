You can swap text in two regions using

  M-x swap-regions [select the first region] C-M-c [select the second region] C-M-c

Note that C-M-c runs `exit-recursive-edit' which is bound
by default in vanilla Emacs.  And while you are selecting regions, you
can run any Emacs command thanks to (info "(elisp) Recursive Editing")
