This library provides the Emacs built-in “C­x C­e” behaviour for
arbitrary languages, provided they have a REPL.


Minimal Working Example [Java]:

  ;; Set “C­x C­j” to evaluate Java code in a background REPL.
  (repl-driven-development [C­x C­j]
                           "jshell --enable-preview"
                           :prompt "jshell>")

  // Selece this Java snippet, then press “C­x C­j” to evaluate it
  import javax.swing.*;
  var frame = new JFrame(){{ setAlwaysOnTop(true); }};
  JOptionPane.showMessageDialog(frame, "Super nice!");

  // REPL result values are shown as overlays:
  2 + 4 // ⇒ 6


Benefits:

Whenever reading/refactoring some code, if you can make some of it
self-contained, then you can immediately try it out! No need to
load your entrie program; nor copy-paste into an external REPL.  The
benefits of Emacs' built-in “C­x C­e” for Lisp, and Lisp's Repl
Driven Development philosophy, are essentially made possible for
arbitrary languages (to some approximate degree, but not fully).


This file has been tangled from a literate, org-mode, file.
