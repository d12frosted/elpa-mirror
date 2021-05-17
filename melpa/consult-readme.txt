Consult implements a set of `consult-<thing>' commands which use
`completing-read' to select from a list of candidates. Consult provides an
enhanced buffer switcher `consult-buffer' and search and navigation commands
like `consult-imenu' and `consult-line'. Searching through multiple files is
supported by the asynchronous `consult-grep' command. Many Consult commands
allow previewing candidates - if a candidate is selected in the completion
view, the buffer shows the candidate immediately.

The Consult commands are compatible with completion systems based
on the Emacs `completing-read' API, including the default completion
system, Icomplete, Selectrum, Vertico and Embark.

Consult has been inspired by Counsel. Some of the Consult commands
originated in the Counsel package or the Selectrum wiki. See the
README for a full list of contributors.
