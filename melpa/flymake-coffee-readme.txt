Based in part on http://d.hatena.ne.jp/antipop/20110508/1304838383

Usage:
  (require 'flymake-coffee)
  (add-hook 'coffee-mode-hook 'flymake-coffee-load)

Executes "coffeelint" if available, otherwise "coffee".

Uses flymake-easy, from https://github.com/purcell/flymake-easy
