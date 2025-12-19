Major mode for editing DNA sequence data in FASTA format and viewing
multiple sequence alignments.

Usage:

M-x sequed-mode to invoke.  Automatically invoked as major mode for .fa and .aln files.
Sequed-mode:
  C-c C-r c  sequed-reverse-complement
  C-c C-r t  sequed-translate
  C-c C-e    sequed-export
  C-c C-a    sequed-mkaln

Sequed-aln-mode:
  C-c C-b    sequed-aln-gotobase
  C-c C-f    sequed-aln-seqfeatures
  C-c C-k    sequed-aln-kill-alignment
