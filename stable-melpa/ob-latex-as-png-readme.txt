An Org-babel “language” whose execution produces PNGs from LaTeX snippets;
useful for shipping *arbitrary* LaTeX results in HTML.

Below is an example of producing a nice diagram;
type it in and C-c C-c to obtain the png.
Then C-c C-x C-v to inline the resulting image.

   #+PROPERTY: header-args:latex-as-png :results raw value replace
   #+begin_src latex-as-png :file example :resolution 150
   \smartdiagram[bubble diagram]{Emacs,Org-mode, \LaTeX, Pretty Images, HTML}
   #+end_src

 Hint: Add the following lines to your init to *always* re-display inline images.

   ;; Always redisplay images after C-c C-c (org-ctrl-c-ctrl-c)
   (add-hook 'org-babel-after-execute-hook 'org-redisplay-inline-images)

; Requirements:

Users must have PDFLATEX and PDFTOPPM command line tools.
