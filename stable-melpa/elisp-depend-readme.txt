
Parse depend libraries of elisp file.

This packages is parse current elisp file and get
depend libraries that need.

Default, it will use function `symbol-file' to get
depend file with current symbol.
And then use `featurep' to test this file whether
write `provide' sentences for feature reference.
If `featurep' return t, generate depend information
as "(require 'foo)" format.
If `featurep' return nil, generate depend
as "(autoload 'foo "FooFile")" format.

This packages will always return depend information as `autoload'
format if a feature not write `provide' information in source code.

Below are commands you can use:

`elisp-depend-insert-require'        insert depends code.
`elisp-depend-insert-comment'        insert depends comment.


;; Installation:

Put elisp-depend.el to your load-path.
The load-path is usually ~/elisp/.
It's set in your ~/.emacs like this:
(add-to-list 'load-path (expand-file-name "~/elisp"))

And the following to your ~/.emacs startup file.

(require 'elisp-depend)

NOTE:

Default, if your Emacs is install at "/usr/share/emacs/",
You can ignore below setup.

Otherwise you need setup your Emacs directory with
option `elisp-depend-directory-list', like below:

(setq elisp-depend-directory-list '("YourEmacsDirectory"))
