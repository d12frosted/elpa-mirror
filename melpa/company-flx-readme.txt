This package adds fuzzy matching to company, powered by the sophisticated sorting heuristics in flx.

Usage
=====

To install, either clone this package directly, or execute M-x package-install RET company-flx RET.

After the package is installed, you can enable `company-flx` by adding the following to your init file:

    (with-eval-after-load 'company
      (company-flx-mode +1))
