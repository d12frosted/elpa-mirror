Major mode for editing DNA sequence data in FASTA and phylip/bpp
format and viewing multiple sequence alignments.

Usage:

M-x sequed-mode to invoke.  Automatically invoked as major mode for .fa and .aln files.
M-x sequed-phy-mode to invoke.  Automatically invoked as major mode for .phy files.
Sequed-mode:
  C-c C-r c  sequed-reverse-complement
  C-c C-r t  sequed-translate
  C-c C-e    sequed-export
  C-c C-a    sequed-mkaln

Sequed-aln-mode:
  C-c C-b    sequed-aln-gotobase
  C-c C-f    sequed-aln-seqfeatures
  C-c C-k    sequed-aln-kill-alignment

Sequed-phy-mode:
  C-c C-a    sequed-phy-mkaln

Sequed-phy-aln-mode (inherits sequed-aln-mode bindings):
  C-c C-n    sequed-phy-aln-next-locus
  C-c C-p    sequed-phy-aln-prev-locus
  C-c C-g    sequed-phy-aln-goto-locus
  C-c C-x    sequed-phy-aln-extract-loci
  C-c C-b    sequed-aln-gotobase (inherited)
  C-c C-f    sequed-aln-seqfeatures (inherited)
  C-c C-k    sequed-aln-kill-alignment (inherited)
