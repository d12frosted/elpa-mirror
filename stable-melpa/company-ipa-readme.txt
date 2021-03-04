This package adds an easy way of inserting IPA (International Phonetic Alphabet) into a document

Usage
=====

To install clone this package directly and load it (load-file "PATH/company-ipa.el")

To activate: (add-to-list 'company-backends 'company-ipa-symbols-unicode)

To use: type '~pp' and you should get completions

To change the prefix, execute:
(company-ipa-set-trigger-prefix "¬")

For best performance you should use this with company-flx:
(company-flx-mode +1)
