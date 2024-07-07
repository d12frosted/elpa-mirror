This is collection of recipes to `run-command'.

I found `run-command' package of Bard very useful, the great idea
that you have one command to run ALL compile-like commands which
have a relation to your file is very awesome.  Also it uses main
power of Emacs: extensibility.  `run-command' not only let you
ability to customization, even better you can choose the commands
that will be visible on your own and even control WHEN, HOW, WHERE.
WOW!  But without the initial start kit is useless, you can call
command but it do nothing.  I am trying to provide for you an OK
starting pack of these recipes, for all languages in which I
sometimes found that need in some help to run it.

If you're going to use all supported languages, just put the
following code into your Emacs configuration:

  (run-command-recipes-use-all)

If you're going to use only some special languages, just put the following one


  (run-command-recipes-use 'latex
                           'pandoc)


Also, Instead of LaTeX and pandoc, you can be interested in other
"build systems" (or how to call it?)

- c
- cpp
- csharp
- elixir
- go
- haskell
- java
- latex
- make
- pandoc
- python
- racket
- rust
