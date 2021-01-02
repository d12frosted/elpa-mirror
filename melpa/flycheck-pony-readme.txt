
Pony syntax checking support for Flycheck.  Runs "ponyc -rfinal" in the
current working directory.

You may need to customize the location of your Pony compiler if
Emacs isn't seeing it on your PATH:

(setq flycheck-pony-executable "/usr/local/bin/ponyc")
