`magic-filetype' parse Vim-style file type header.
For example, in executable JavaScript(node) file is...

  #!/usr/bin/env node
  // vim:set ft=javascript:
  (function(){
      "use strict";
       ....

put into your own .emacs file (init.el)

  (magic-filetype-enable-vim-filetype)

`magic-filetype-exemplary-filename-alist' have dummy filename that is delegate of major-mode.
