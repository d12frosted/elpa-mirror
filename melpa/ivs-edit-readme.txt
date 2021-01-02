
* IVS Editing Tool for Emacs

This file provides various IVS (Ideographic Variation Sequence)
editing tools for Emacs. IVS represents variations of CJK
Ideogrpaphs.  For details, please refer Unicode Technical Standard
#37 (http://www.unicode.org/reports/tr37/).

Data file "IVD_Sequences.txt", integrated into this tool, is
distributed from http://www.unicode.org/ivd.

** Supported Emacsen

Currenty, Emacs for X-Windows (with `libotf' linked) and Emacs Mac
Port (with Yamamoto Mituharu patch, see
https://github.com/railwaycat/emacs-mac-port for details) support
IVS.

** Supported Fonts

Most of recent Adobe-Japan1 fonts support `Adobe-Japan1' IVD
collection. Hanazono Mincho (http://fonts.jp/hanazono/) supports
`Hanyo-Denshi' IVD collection. `Moji_Joho' collection shares some
sequences with `Hanyo-Denshi' collection.

** Basic setup

: (autoload 'ivs-edit "ivs-edit" nil t)                 ; if necessary
: (global-set-key (kbd "M-J") 'ivs-edit)                ; sample keybinding
: (setq ivs-edit-preferred-collections '(Adobe-Japan1)) ; if you only use Adobe-Japan1 IVD.

** Inserting and Checking IVS characters

Executing `M-x ivs-edit' (or pressing `M-J' if configured as above)
on Kanji character will show, and replace to, a series of IVS. If
executed on IVS, the collection name and the ID of IVS will be
displayed in minibuffer.

** Converting to/from TeX representation of IVS

`ivs-edit-aj1-to-tex-region' and `ivs-edit-tex-to-aj1-region' can
convert IVS to pLaTeX CID command and vice versa. XeLaTeX supports
IVS natively.

** Converting Japanese Kanji to Old Style

`ivs-edit-old-style-region' convert Japanese Kanji to its old style
with Adobe-Japan1 IVS.

** Highlighting non-AJ1 Kanji characters.

`M-x ivs-edit-highlight-non-aj1' highlights non-AJ1 Kanji characters.
This feature is useful for writing text for e-Book readers which only
supports Adobe-Japan1 characters.
