
* IDS Editing Tool for Emacs

This file provides IDS (Ideographic Description Sequence)
composition/decomposition tools for Emacs. The IDS represents a
structure of Ideographs.  For example, "地" can be decomposed to
"⿰土也" in IDS, and "⿱艹化" can be composed to "花". "⿰" and "⿱"
are called IDCs (Ideographic Description Characters).

** Basic setup

Please BYTE-COMPILE the elisp file. That will integrate data files
into compiled lisp file.

: (autoload 'ids-edit-mode "ids-edit" nil t) ;; if necessary
: (autoload 'ids-edit "ids-edit" nil t)

If you want to assign other key, you can do it to any keymap.
For example:

: (global-set-key (kbd "M-u") 'ids-edit)

** IDS edit mode

Minor `ids-edit-mode' will let you input IDCs and compose/decompose
ideographs by M-U key.

| key | command       |
|-----+---------------|
| M-0 | "⿰" (U+2FF0) |
| M-1 | "⿱" (U+2FF1) |
| M-2 | "⿲" (U+2FF2) |
| M-3 | "⿳" (U+2FF3) |
| M-4 | "⿴" (U+2FF4) |
| M-5 | "⿵" (U+2FF5) |
| M-6 | "⿶" (U+2FF6) |
| M-7 | "⿷" (U+2FF7) |
| M-8 | "⿸" (U+2FF8) |
| M-9 | "⿹" (U+2FF9) |
| M-- | "⿺" (U+2FFa) |
| M-= | "⿻" (U+2FFb) |
| M-U | ids-edit      |

You can customize the key bind by defining key to `ids-edit-mode-map'.

** Decomposing CJK Ideographs to IDS

Just type `M-U' (meta-shift-u) after the position of target CJK
Ideograph. There should be no numerics, ideographs or IDCs at the
cursor.  With prefix argument given, it tries to decomposes previous
character unconditionally.

** Composing IDS to CJK Ideograph

Type `M-U' on partial IDS. It may contain a (range of) strokes
number. When there are multiple candidates, they will all be
inserted to the current position with bracket. Attaching G,T,J,K at
the end will limit the candidates to specific charset (namely,
GB2312, Big5, JISX0213/0212, KSX1001).

For example, "⿰氵20-22J", with cursor on "⿰" character, will be
composed to "[灊灝灞灣]".

** Data Sources

Data 'ids-cdp.txt' and 'ucs-strokes.txt' are taken from
http://github.com/cjkvi/. License follows their terms.
