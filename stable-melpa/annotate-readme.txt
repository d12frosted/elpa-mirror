This package provides the minor mode annotate-mode, which can add
annotations to arbitrary files without changing the files
themselves.  Annotations are saved in the annotate-file
(~/.annotations by default).

To add annotations to a file, select a region and hit C-c C-a.  The
region will be underlined, and the annotation will be displayed in
the right margin.  Annotations are saved whenever the file is saved.

Use C-c ] to jump to the next annotation and C-c [ to jump to
the previous annotation.  Use M-x annotate-export-annotations to
save annotations as a no-difference diff file.

Important note: annotation can not overlaps and newline character
can not be annotated.
