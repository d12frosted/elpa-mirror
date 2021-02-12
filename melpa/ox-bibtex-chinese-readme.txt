* README                                                             :README:
ox-bibtex-chinese is an extension of ox-bibtex, which can help chinese user
to export bibliography to html.

[[./snapshots/ox-bibtex-chinese.gif]]

** Installation
ox-bibtex-chinese is now available from the famous Emacs package repo
[[http://melpa.milkbox.net/][melpa]], so the recommended way is to install it
through Emacs package management system.

** Usage
1. Install bibtex2html to your system
2. Configure Emacs
   #+BEGIN_EXAMPLE
   (require 'org)
   (require 'ox-bibtex)
   (require 'ox-bibtex-chinese)
   (ox-bibtex-chinese-enable)
   #+END_EXAMPLE
3. See the format of "example/thesis.org" and try export it to html file.
