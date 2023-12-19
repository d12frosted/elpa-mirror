If you're going to use all supported language, just put the following
code to your Emacs configuration:

  (run-command-recipes-use-all)

If you're going to use only some special languages, just put the following
code to your Emacs configuration:


  (run-command-recipes-use latex
                           pandoc)


Also, Instead of LaTeX and pandoc, you can put anything from the
following list:

- latex
- pandoc
- haskell
- elisp
- rust
- python
- c
- cpp
- csharp
- java
- racket
- make
- go
- elixir
