
This package requires the "solc" (solidity compiler) program, which can be installed
following OS specific instructions from the ethereum website.

Add to your .emacs file configuration:

  (require 'flymake-solidity)
  (add-hook 'find-file-hook 'flymake-solidity-maybe-load)

If the "solc" path is different from "/usr/local/bin/solc", then add the line below (after changing your path):

  (setq flymake-solidity-executable "/usr/local/bin/solc")


Uses flymake-easy, from https://github.com/purcell/flymake-easy
; Author: Steve Purcell <steve@sanityinc.com>
; Homepage: https://github.com/purcell/flymake-solidity
