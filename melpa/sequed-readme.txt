Major mode for editing DNA sequence data in FASTA format and viewing multiple sequence alignments.

Usage:

M-x sequed-mode to invoke.  Automatically invoked as major mode for .fa and .aln files.
Sequed-mode major mode:
M-x sequed-reverse-complement [C-c C-r c] -> generate reverse complement of selected DNA region
M-x sequed-translate [C-c C-r t] -> generate amino acid sequence by translation of selected DNA region
M-x sequed-export [C-c C-e] -> export to new buffer in BPP/Phylip format
M-x sequed-mkaln [C-c C-a] -> create an alignment view in read-only buffer in sequed-aln-mode
sequed-aln-mode major mode:
M-x sequed-aln-gotobase [C-c C-b] -> prompt for base number to move cursor to that column in alignment
M-x sequed-aln-seqfeatures [C-c C-f] -> print number of sequences and number of sites
M-x sequed-aln-kill-alignment [C-c C-k] -> quit alignment view buffer
