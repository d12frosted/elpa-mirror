Consult implements a set of commands which use `completing-read' to select
from a list of candidates. Most provided commands follow the naming scheme
`consult-<thing>'. Some commands are drop-in replacements for existing
functions, e.g., `consult-apropos' or the enhanced buffer switcher
`consult-buffer.' Other commands provide additional functionality, e.g.,
`consult-line', to search for a line. Many commands support candidate
preview. If a candidate is selected in the completion view, the buffer shows
the candidate immediately.

Acknowledgements:

This package took inspiration from Counsel by Oleh Krehel. Some of the
commands found in this package originated in the Selectrum wiki. See the
README for a full list of contributors.
