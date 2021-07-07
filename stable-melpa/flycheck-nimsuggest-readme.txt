On the fly syntax check support using Nimsuggest and flycheck.el.
You could find another flycheck backend for Nim at https://github.com/ALSchwalm/flycheck-nim
which use `nim check` command.

Because of introducing new flymake (https://lists.gnu.org/archive/html/emacs-devel/2017-09/msg00953.html)
from Emacs 26, this package is moved outside of nim-mode repository


Manual configuration:

If you install this package from MELPA, probably this package
should work automatically, (if you followed nim-mode's instruction)
but if not, please use below manual configuration.

``` elisp
(add-hook 'nimsuggest-mode-hook 'flycheck-nimsuggest-setup)
```
