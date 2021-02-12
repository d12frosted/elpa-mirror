This package provides Org export functionality to generate HTML
presentations with the presentation framework reveal.js.

Quickstart:
0. Install reveal.js: https://revealjs.com/
1. Activate org-re-reveal.
   (a) Place this directory into your load path or install it from MELPA
       (https://melpa.org/#/getting-started).
   (b) Load package manually ("M-x load-library" followed by
       "org-re-reveal") or place "(require 'org-re-reveal)" into your
       ~/.emacs and restart or customize org-export-backends by adding
       the symbol re-reveal.
2. Load an Org file and export it to HTML.
   (a) Make sure that reveal.js is available in your current directory
       (e.g., as sub-directory or symbolic link).
   (b) Load "Readme.org" (coming with org-re-reveal).
   (c) Export to HTML: Press "C-c C-e v v" (write HTML file) or
       "C-c C-e v b" (write HTML file and open in browser)
See "Readme.org" for introduction, details, and features added to
org-reveal:
https://gitlab.com/oer/org-re-reveal/-/blob/master/Readme.org
The Readme is also available as reveal.js presentation that is
generated with org-re-reveal in a CI/CD infrastructure on GitLab:
https://oer.gitlab.io/org-re-reveal/Readme.html

Note that emacs-reveal offers a project that embeds org-re-reveal,
reveal.js, and various reveal.js plugins:
https://gitlab.com/oer/emacs-reveal
Its howto, generated from Org source file with emacs-reveal:
https://oer.gitlab.io/emacs-reveal-howto/howto.html

The package org-re-reveal grew out of a forked version of org-reveal
when upstream development stopped:
https://github.com/yjwen/org-reveal/issues/349
https://github.com/yjwen/org-reveal/issues/342
