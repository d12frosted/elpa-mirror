Org-babel support for compiling solidity code.

Example block:
#+begin_src solidity :args --asm --optimize
  contract A {
  }
#+end_src

The ":args" field is optional, if provided, it forwards the arguments to "solc".

The solc binary is found from the variable `solidity-solc-path`, defined in solidity-mode.
