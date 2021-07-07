The following applications are supportted:
- Chrome
- Safari
- Firefox
- Finder
- Mail
- Terminal
- Skim
- qutebrowser

The following link types are supported:
- plain:    https://www.wikipedia.org/
- markdonw: [Wikipedia](https://www.wikipedia.org/)
- org:      [[https://www.wikipedia.org/][Wikipedia]]
- html:     <a href="https://www.wikipedia.org/">Wikipedia</a>

To use, type M-x grab-mac-link or call `grab-mac-link' from Lisp

  (grab-mac-link APP &optional LINK-TYPE)

There is a DWIM version, M-x grab-mac-link-dwim, it chooses an application
according to `grab-mac-link-dwim-favourite-app' and link type according to
`major-mode'.
