This file provides `company-irony-c-headers`, a company backend
that completes C/C++ header files. Large chunks of code are taken
from
[company-c-headers](https://github.com/randomphrase/company-c-headers). It
also works with `irony-mode` to obtain compiler options.

Usage:
   (require 'company-irony-c-headers)
   ;; Load with `irony-mode` as a grouped backend
   (eval-after-load 'company
     '(add-to-list
       'company-backends '(company-irony-c-headers company-irony)))

When compiler options change, call
`company-irony-c-headers-reload-compiler-output` manually to
reload.
