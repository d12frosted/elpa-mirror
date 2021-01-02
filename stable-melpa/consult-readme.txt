Consult implements a set of `consult-<thing>' commands which use
`completing-read' to select from a list of candidates. Consult
provides an enhanced buffer switcher `consult-buffer' and many
search and navigation commands like `consult-line' and an
asynchronous `consult-grep'. Many commands support candidate
preview - if a candidate is selected in the completion view, the
buffer shows the candidate immediately.

The Consult commands are compatible with completion systems based
on the Emacs `completing-read' API, notably the default completion
system, Icomplete, Selectrum and Embark's live-occur.

This package took inspiration from Counsel by Oleh Krehel. Some of
the commands found in this package originated in the Selectrum
wiki. See the README for a full list of contributors.
