
ox-twiki.el lets you convert Org files to twiki buffers
using the ox.el export engine.

Put this file into your load-path and the following into your ~/.emacs:
 (require 'ox-twiki)

Export Org files to twiki:
M-x org-twiki-export-as-twiki RET

You can set the following options inside of the document:
#+TWIKI_CODE_BEAUTIFY: t/nil
   controls whether code blocks are exported as %CODE{}% twiki
   blocks (requires the beautify twiki plugin).

originally based on ox-confluence by Sébastien Delafond
