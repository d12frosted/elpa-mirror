Dylan mode is a major mode for editing Dylan programs. It provides
indenting and syntax highlighting support.

Testing

dylan-mode-test.dylan contains Dylan code that is indented in the preferred way. One
way to test this code is to open that file and press Tab on each line, or on the
specific lines you're trying to affect.

Debugging

So far I (cgay) have found it easiest to debug by adding calls to (message ...) all
over the place and keep the *Messages* window visible, since tracing doesn't say the
names of the arguments or return values.  If someone else knows a better way please
comment.

With so many cascading defvars and the fact that eval-buffer doesn't reset
their values, frequently the easiest way to test changes is to start a new
Emacs.

Bugs / to-do list

* See bugs on GitHub: https://github.com/dylan-lang/dylan-mode/issues
* Don't highlight macro variables (e.g., "?x:" in ?x:name) as keywords.
  Just highlight the "x" as a variable binding.
* Customize fill-column to some acceptable value so that auto-filled
  comments are filled at a standard place > 70.  I use 89 myself.
* It appears as though some code matches only some of the graphic-character
  BNF when it should match all graphic chars.
