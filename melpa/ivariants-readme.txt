* ivariants.el … Ideographic Variants Editor and Browser

`ivariants.el' and related files provide various Ideographic Variants
editing and browsing capabilities.

** Inserting Variants

`M-x ivariants-insert' inserts the variants at the current position.

** Browsing Variants

`M-x ivariants-browse' let you browse the variants.

** Converting to Simplified/Traditional/Taiwanese/Japanese forms.

Following commands for specified region are provided.

- ivariants-to-simplified
- ivariants-to-traditional
- ivariants-to-pr-china
- ivariants-to-japan
- ivariants-to-taiwan

** Configuration

Typical configurations are:

: (global-set-key (kbd "M-I")   'ivariants-insert)
: (global-set-key (kbd "C-c i") 'ivariants-browse)

* Notes

Sometimes, "traditional character" of P.R.C and Taiwanese character may
differ. For example, "说"'s traditional character is "説" while
Taiwanese character is "說".

* Variant Data

Variant data are taken from https://github.com/cjkvi/cjkvi-variants
and http://unicode.org/Public/UCD/latest/ucd/StandardizedVariants.txt.
'DailyUse' is a modified version of data from
http://kanji.zinbun.kyoto-u.ac.jp/~yasuoka/CJK.html.
