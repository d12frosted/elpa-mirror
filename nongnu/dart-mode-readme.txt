To install, see https://github.com/nex3/dart-mode/blob/master/README.md

Known bugs:

* Multiline strings using """ and ''' are not recognized. They fontify
  correctly, but only because they look like three strings in a row.
* In a map with identifier keys, the first key is fontified like a label.
* Return values for operator methods aren't fontified correctly.
* Untyped parameters aren't fontified correctly.
* Quotes immediately after string interpolation are marked as unclosed.
* Sexp movement doesn't properly ignore quotes in interpolation.
* Methods using "=>" can cause indentation woes.
* C and C++ modes seem to be hosed.

Definitions adapted from go-mode.el are

gofmt-command gofmt-args gofmt-show-errors gofmt go--apply-rcs-patch
gofmt--kill-error-buffer gofmt--process-errors gofmt-before-save
go--goto-line go--delete-whole-line