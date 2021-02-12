Latexdiff.el is a backend for
[Latexdiff](https://github.com/ftilmann/latexdiff).

latexdiff requires Emacs-24.4 or later
and optionnaly [Helm](https://github.com/emacs-helm/helm).

Configuration:

latexdiff faces and behaviour can be customized through the customization
panel :
`(customize-group 'latexdiff)`
Latexdiff.el does not define default keybindings, so you may want to add
some using `define-key`.

Basic usage

File to file diff:
- `latexdiff` will ask for two tex files and generates a tex diff between
  them (that you will need to compile).
Version diff (git repo only):
- `latexdiff-vc` (and `helm-latexdiff-vc`) will ask for a previous commit
  number and make a pdf diff between this version and the current one.
- `latexdiff-vc-range` (and `helm-latexdiff-vc-range`) will ask for two
  commits number and make a pdf diff between those two versions.
