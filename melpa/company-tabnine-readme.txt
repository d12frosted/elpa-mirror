
Description:

TabNine(https://tabnine.com/) is the all-language autocompleter.
It uses machine learning to provide responsive, reliable, and relevant suggestions.
`company-tabnine' provides TabNine completion backend for `company-mode'(https://github.com/company-mode/company-mode).
It takes care of TabNine binaries, so installation is easy.

Installation:

1. Make sure `company-mode' is installed and configured.
2. Add `company-tabnine' to `company-backends':

  (add-to-list 'company-backends #'company-tabnine)

3. Run M-x company-tabnine-install-binary to install the TabNine binary for your system.

Usage:

`company-tabnine' should work out of the box.
See M-x customize-group RET company-tabnine RET for customizations.

Recommended Configuration:

- Trigger completion immediately.

  (setq company-idle-delay 0)

- Number the candidates (use M-1, M-2 etc to select completions).

  (setq company-show-numbers t)
