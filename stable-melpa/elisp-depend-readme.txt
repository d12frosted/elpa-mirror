
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


;; Customize:

`elisp-depend-directory-list' the install directory of Emacs.
Or you can add others directory that you want filter.

All of the above can customize by:
     M-x customize-group RET elisp-depend RET


;; Change log:

2012/04/20
     * Switched to `read' instead of parsing the file mnaually.

2010/05/10
     * Bugfix: Fixed error if file didn't start with a comment.
2010/05/08
     * Added require for `thingatpt'
     * Now slash-style module names are treated correctly.

2009/02/11
     * Add new option `built-in' to function `elisp-depend-map'
       for debug.

2009/01/18
     * Complete all check work.
       Now can generate exact depend information.
     * Modified some code to compatibility Emacs 20.
       Thanks "Drew Adams" advice.
     * Fix doc.

2009/01/17
     * Don't include user init file in depend information,
       filter by variable `user-init-file'.

2009/01/11
     * First released.


;; Acknowledgements:

     Drew Adams      <drew.adams@oracle.com>
             For advice for compatibility Emacs 20.


;; TODO

     Fix local-variable problem:
         If the some local-variable (such as lambda sentence)
         have same name with function, will got unnecessary depend
         information.
