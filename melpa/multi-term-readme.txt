
This package is for creating and managing multiple terminal buffers in Emacs.

By default, term.el provides a great terminal emulator in Emacs.
But I have some troubles with term-mode:

1. term.el just provides commands `term' or `ansi-term'
   for creating a terminal buffer.
   And there is no special command to create or switch
   between multiple terminal buffers quickly.

2. By default, the keystrokes of term.el conflict with global-mode keystrokes,
   which makes it difficult for the user to integrate term.el with Emacs.

3. By default, executing *NIX command “exit” from term-mode,
   it will leave an unused buffer.

4. term.el won’t quit running sub-process when you kill terminal buffer forcibly.

5. Haven’t a dedicated window for debug program.

And multi-term.el is enhanced with those features.
