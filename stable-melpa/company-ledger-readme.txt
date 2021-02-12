
`company-mode' backend for `ledger-mode', `beancount-mode' and
similar plain-text accounting modes. Provides fuzzy completion
for transactions, prices and other date prefixed entries.
See Readme for detailed setup and usage description.

Detailed Description
--------------------
- Provides auto-completion based on words on current line
- The words on the current line can be partial and in any order
- The candidate entities are reverse sorted by location in file
- Candidates are paragraphs starting with YYYY[-/]MM[-/]DD

Minimal Setup
-------------
(with-eval-after-load 'company
  (add-to-list 'company-backends 'company-ledger))

Use-Package Setup
-----------------
(use-package company-ledger
  :ensure company
  :init
  (with-eval-after-load 'company
    (add-to-list 'company-backends 'company-ledger)))
