jscs.el helps consistent JavaScript editing using JSCS.

Installation:

jscs.el is available on [MELPA]<http://melpa.org/>.

Usage:

To apply JSCS indentation rules to JavaScript or JSON modes,
add the following code into your .emacs:

    (add-hook 'js-mode-hook #'jscs-indent-apply)
    (add-hook 'js2-mode-hook #'jscs-indent-apply)
    (add-hook 'json-mode-hook #'jscs-indent-apply)

To run "jscs --fix" interactively, run \\[jscs-fix].

To run "jscs --fix" on JavaScript modes when saving,
add the following code into your .emacs:

    (add-hook 'js-mode-hook #'jscs-fix-run-before-save)
    (add-hook 'js2-mode-hook #'jscs-fix-run-before-save)
