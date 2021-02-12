This package provides the eslintd-fix minor mode, which will use eslint_d
(https://github.com/mantoni/eslint_d.js) to automatically fix javascript code
before it is saved.

To use it, require it, make sure `eslint_d' is in your path and add it to
your favorite javascript mode:

   (add-hook 'js2-mode-hook #'eslintd-fix-mode)
