To setup, insert below code into ~/.emacs:
  (add-to-list 'load-path "~/.emacs.d/lisp/")
  (autoload 'gmail2bbdb-import-file "gmail2bbdb" nil t nil)

Usage:
- Click "More->Export->vCard format->Export" at Google Contacts.
  Download "contacts.vcf".
- Run "M-x gmail2bbdb-import-file" and select contacts.vcf.
  "~/.bbdb" is created.
- Keep using BBDB.
