parseedn is an Emacs Lisp library for parsing EDN (Clojure) data.
It uses parseclj's shift-reduce parser internally.

EDN and Emacs Lisp have some important differences that make
translation from one to the other not transparent (think
representing an EDN map into Elisp, or being able to differentiate
between false and nil in Elisp).  Because of this, parseedn takes
certain decisions when parsing and transforming EDN data into Elisp
data types.  For more information please refer to parseclj's design
documentation.
