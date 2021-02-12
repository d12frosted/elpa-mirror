Thank you very much Josh Triplett, this code is a child of your Vim script:
http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=504244

This package provides bracketed paste mode support within emacs -nw.
- http://invisible-island.net/xterm/ctlseqs/ctlseqs.html (DECSET/DECRST)
- http://invisible-island.net/xterm/ctlseqs/ctlseqs.html#Bracketed Paste Mode

I've adapted these Vim's settings to Emacs.

- http://slashdot.jp/journal/506765/Bracketed-Paste-Mode (Japanese)
- http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=504244
- http://stackoverflow.com/a/7053522

Thank you very much for Josh Triplett, IWAMOTO Kouichi, Chris Page and
Rainer Müller to open these settings to the public! I've learned how to
get the advantage of Bracketed Paste Mode on Vim by reading your
articles.

Please put the following to your ~/.emacs file then restart Emacs:

  (require 'bracketed-paste)
  (bracketed-paste-enable)
