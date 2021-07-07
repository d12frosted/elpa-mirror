
References:
  http://www.emacswiki.org/cgi-bin/wiki/FlymakeJavaScript
  http://d.hatena.ne.jp/kazu-yamamoto/mobile?date=20071029

Works with either "jslint" from jslint.com, or "jsl" from
javascriptlint.com.  The default is "jsl", if that executable is
found at load-time.  Otherwise, "jslint" is the default.  If you want
to use the non-default checker, you can customize the values of
`flymake-jslint-command' and `flymake-jslint-args' accordingly.

Usage:
  (require 'flymake-jslint)
  (add-hook 'js-mode-hook 'flymake-jslint-load)

Uses flymake-easy, from https://github.com/purcell/flymake-easy
