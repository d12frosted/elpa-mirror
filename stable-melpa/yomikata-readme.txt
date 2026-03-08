This packages annotates Japanese text in an Emacs buffer with
readings for the kanji characters, using MECAB+Unidic (an external
tool).

To annotate text, run `yomikata-region', `yomikata-buffer', or
`yomikata-at-point'.  The text in the buffer won't be altered with
visible glosses (furigana/rubi); instead, it will be enriched with
interactive tooltips.  To see the reading of a kanji, either hover
the mouse pointer over it, or put the text cursor on a word and
call `yomikata-at-point' again.

You will need MECAB installed with the Unidic dictionary
(alternative dictionaries are planned but not yet supported).
On Debian you can get them with:

   apt install mecab unidic-mecab

Note that unidic-mecab is several gigabytes in size.

The annotations are saved in the `help-echo' text property of a
package-specific overlay.  To clear them, use
`yomikata-clear-tooltips-region' or
`yomikata-clear-tooltips-buffer'.

Annotated text is underlined by default.  To change this, customize
`yomikata-tooltip-available-face'.


This software currently doesn't understand Japanese words broken
between lines.  You might want to use soft line breaks for longer
text.

Automatic morphological analysis and kanji reading inference are
imperfect processes, and may make errors.  This software is
deterministic, and its errors are consistent and predictable.  The
inference is 100% offline, open source, and private.  No LLMs or
so-called “generative AI” are used at any point.  None of your
data is sent anywhere or used to train anything.  No coal plants
had to be built to train datafiles used by this software.
