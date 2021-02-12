Apply predefined folding to a buffer, based on customizable string occurrences.
The origami package is used to perform the actual folding.

Quick start:
Enable the mode origami-predef-global-mode.  This will add a find-file-hook that will fold every tagged line.
Tag the lines you need to be initialy folded with *autofold*.

  public void boringMethod(){ // *autofold*
     foo();
     bar();
  }

Sometimes, the tag can not be placed in the same line you need to be folded.  In these cases, *autofold:*
will fold the next line.

  # A very long shell variable with newlines
   # *autofold:*
  LOREM="
    Pellentesque dapibus suscipit ligula.
    Donec posuere augue in quam.
    Etiam vel tortor sodales tellus ultricies commodo.
    Suspendisse potenti.
    Aenean in sem ac leo mollis blandit.
    ...
  "

The tags can be changed with customize.

You can invoke =origami-predef-apply= to reset folding to its initial state, according to tagged lines.

It is possible to define initial folding for each major mode using the mode hook and origami-predef-apply-patterns.

More information at https://github.com/alvarogonzalezsotillo/origami-predef
