
Transform LaTeX encoded non-ASCII characters to and from their
visible (utf-8) representations when visiting a file and preserve
their original encoding when saving the buffer.

TeX/LaTeX documents often contain special characters that are not
available in ASCII code in a special command form. For example, the
German umlaut ä can be written in LaTeX as {\"a}, \"{a}, \"a or
even "a. Of course, nowadays one should use an encoding like utf-8,
which contain a natural representation of these characters.
Unfortunately, old documents may still use the old encodings or
non-ASCII encodings are not allowed for other reasons. Emacs can
already automatically encode and decode such characters from and to
their LaTeX representation using the `iso-cvt' package: during
editing the document the characters are utf-8 encoded but when
saved to disk the characters are transformed to a LaTeX
representation.

Unfortunately, this an all-or-nothing approach: either all
characters are transformed or none. But when working on a document
with several authors this may be problematic. This may particularly
true if the document is stored in a revision control system. In
these cases each author may use its own editor, each editor may
have its own setting and encodes umlauts in a special preferred
way. Each time one author does a small change, *all* umlauts in the
whole document may get transformed. This may also lead to huge
diffs that consist of many hunks that only change the encoding of
some characters.

The purpose of `tex-smart-umlauts' is to automatically encode and
decode umlauts from and to their tex representation, while
*preserving* the original encoding. In other words, when a LaTeX
file is visited, the original encoding of each character is saved
and the character is transformed to its visible (utf-8)
representation. When the document is saved again, each character
that has been present when the document has been loaded is saved in
its *original* encoding. Only newly inserted non-ASCII characters
get a new encoding that depends on the user-options of
`tex-smart-umlauts'. This way, a small change in a document will
not reencode all non-ASCII charactes as `iso-cvt' would do and only
the modified parts of the document will really be modified on disk.
