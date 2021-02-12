
  Haskell-Snippets is a collection of YASnippet Haskell snippets for Emacs.

  Available Expansion Keys:

      new  - newtype
      mod  - module [simple, exports]
      main - main module and function
      let  - let bindings
      lang - language extension pragmas
      opt  - GHC options pragmas
      \    - lambda function
      inst - instance declairation
      imp  - import modules [simple, qualified]
      if   - if conditional [inline, block]
      <-   - monadic get
      fn   - top level function [simple, guarded, clauses]
      data - data type definition [inline, record]
      =>   - type constraint
      {-   - block comment
      case - case statement

  Design Ideals:

      Keep snippet keys (the prefix used to auto-complete) to four
      characters or less while still being as easy to guess as
      possible.

      Have as few keys as possible. The more keys there are to
      remember, the harder snippets are to use and learn.

      Leverage ido-mode when reasonable. For instance, to keep the
      number of snippet keys to a minimum as well as auto complete
      things like Haskell Langauge Extension Pragmas. When multiple
      snippets share a key (ex: 'fn'), the ido-mode prompts are unique to
      one character (ex: 'guarded function' and 'simple function' are 'g' and
      's' respectively).
