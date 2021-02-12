* ~tikz~ A minor mode to edit TikZ pictures with Emacs

~tikz~ is a minor mode for creating TikZ diagrams with Emacs as an
alternative to QtikZ.

** Installation

- You should have a running environment of LaTeX.
- You should install the [[https://pwmt.org/projects/zathura/][Zathura]]
viewer, or change the default configuration.
- Copy this file into your =init.el= or load it
or use =M-x package-install RET tikz=.

** Using it

- Create a Tex file with your favourite preamble.
- Once you have fixed the preamble in your document, launch the TikZ mode.
#+begin_example
M-x tikz-mode
#+end_example
- Now, when you are in idle time, the pdf will be refreshed
  automatically with the content of the current buffer.
- Every time you modify your preamble, you must turn off/on the TikZ mode.

** Screenshot

On the left side, Emacs with a LaTeX buffer with minor mode TikZ. On
the right side, Zathura viewing the pdf.

[[file:graphics/tikzscreenshot.png]]

** Configuration

- You can select another pdf viewer. Modify =tikz-zathura= with your chosen viewer.
- You can modify the idle timer to update the pdf. Modify =tikz-resume-timer=.


** How it works

- It copies the current TeX buffer into a temp file.
- [[https://ctan.org/pkg/mylatexformat][Pre-compile the preamble]].
- Pdftex the temp file.
- It uses Zathura to view the pdf.
- In idle time, copy the current buffer to the temp file and compile
  it. Zathura automatically refreshes the view.

** Alternatives
- QtikZ

** Acknowledgement
Partially supported by PGC2018-098623-B-I00.
