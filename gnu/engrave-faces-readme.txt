#+title: Engrave Faces
#+author: tecosaur

There are some great packages for Exporting buffers to particular formats, but
each one seems to reinvent the core mechanism of processing the font-lock in a
buffer such that it can be exported to a particular format.

This package aims to produce a versatile generic core which can process a
fortified buffer and elegantly pass the data to any number of backends which can
deal with specific output formats.

This is very much a work in progress, a rough plan can be seen below.
I fully expect some important items to have been forgotten.

*Font lock processing*
- [X] Single faces
- [X] Merge multiple faces
- [ ] Process overlays

*Included backends*
- [X] LaTeX
- [X] HTML
- [X] ANSI
