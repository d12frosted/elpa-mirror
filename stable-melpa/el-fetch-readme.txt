Show system information in Neofetch-like style (eg CPU, RAM).

Neofetch: https://github.com/dylanaraps/neofetch

Inspiration also has been driven from RKTFetch - older fetch-like program
that I have helped to write some time ago.

RKTFetch: https://github.com/mythical-linux/rktfetch

Though, this is not a re-implementation;
this program is meant to extend "fetch" to this new domain, i.e. Emacs Lisp.
El-Fetch does not implement some of Neofetch's features users of the program
may take for granted, e.g.: ASCII art.
El-Fetch adds some Emacs-specific information gathering,
e.g.: Emacs version/packages, used theme, time spent in the editor.

WARNING: El-Fetch is primarily developed on GNU/Linux,
Windows support is experimental, macOS support is totally untested.

To run El-Fetch add it to your load-path,
execute M-x load-library el-fetch and then M-x el-fetch
You may want to add it to startup or run Emacs with:
--eval "(load-library \"el-fetch\")" --eval "(el-fetch)"
