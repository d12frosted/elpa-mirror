This library provides the Emacs built-in “C-x C-e” behaviour for
arbitrary languages, provided they have a REPL shell command.

============================Benefits===============================

Whenever reading/refactoring some code, if you can make some of it
self-contained, then you can immediately try it out! No need to
load your entire program; nor copy-paste into an external REPL.  The
benefits of Emacs' built-in “C-x C-e” for Lisp, and Lisp's Repl
Driven Development philosophy, are essentially made possible for
arbitrary languages (to some approximate degree, but not fully).

Just as “C-u C-x C-e” inserts the resulting expression at the
current cursour position, so too all repl-driven-development
commands allow for a C-u prefix which inserts the result.
This allows for a nice scripting experience where results
are kept for future use.


===============================Official Manual========================

See http://alhassy.com/repl-driven-development

“C-h o repl-driven-development” also has extensive docs,
via a JavaScript server example.

===============================Mini-Tutorial==========================

Often, while reading a README file, we will (1) copy a shell command,
(2) open a terminal, and (3) paste the shell command to run it.
We can evaluate arbitrary regions in a shell in one step via “C-x C-t”
with:

   (repl-driven-development [C-x C-t] "bash")

For example, execute “C-x C-t” anywhere on each line below and see results in an
overlay, right by your cursor.

  echo "It is $(date) and I am at $PWD, my name is $(whoami) and I have: $(ls)"

  say "My name is $(whoami) and I like Emacs"

Notice as each line is sent to the Bash process, the line is highlighted briefly in yellow.
Moreover, you can hover over the text to see a tooltip with the resulting shell output.
Finally, if you invoke “C-h k C-x C-t” you get help about this new “C-x C-t” command,
such as inserting results at point via “C-u C-x C-t” or to reset/refresh the current
Bash process with “C-u -1 C-x C-t”.

This also works for any command-line REPL; for example, for Python:

   (repl-driven-development [C-x C-p] "python3")

Then, we can submit the following Python snippets with “C-x C-p” on each line.

  sum([1, 2, 3, 4])

  list(map(lambda i: 'Fizz'*(not i%3)+'Buzz'*(not i%5) or i, range(1,101)))

These work fine, however there are some shortcomings of this REPL.
For example, echoing results could be prettier and it doesn't handle
multi-line input very well.  You can address these issues using the various
hooks / keyword arguments of the “repl-driven-development” macro.

However, this package comes with preconfigured REPLS for: python, terminal,
java, javascript.

Simply use the name of these configurations:

  (repl-driven-development [C-x C-p] python)

Now we can submit the following, with “C-x C-p”, with no issues:

  def square(x):
    return x * x

  square(5)

Since these new REPL commands are just Emacs functions, we can use
several at the time, alternating between them.  For example:

  ;; C-x C-e on the next two lines
  (repl-driven-development [C-x C-t] terminal)
  (repl-driven-development [C-x C-p] python)

  echo Hello... > /tmp/o       # C-x C-t here

  print(open("/tmp/o").read()) # C-x C-p here

  echo ...and bye >> /tmp/o    # C-x C-t again

  print(open("/tmp/o").read()) # C-x C-p again

Let's conclude with a GUI example in Java.

  ;; Set “C-x C-j” to evaluate Java code in a background REPL.
  (repl-driven-development [C-x C-j] "jshell")

  // Select this Java snippet, then press “C-x C-j” to evaluate it
  import javax.swing.*;
  JOptionPane.showMessageDialog(new JFrame(){{setAlwaysOnTop(true);}}, "Super nice!")

We can use a preconfigured Java REPL, to remove the annoying “jshell>” prompt
from overlay echos, handle multi-line input, and more.

  (repl-driven-development [C-x C-j] java)

 // REPL result values are shown as overlays:
 // See a list of 23 numbers, which are attached as a tooltip to this text.
 IntStream.range(0, 23).forEach(x -> System.out.println(x))

For more documentation, and examples,
see http://alhassy.com/repl-driven-development
