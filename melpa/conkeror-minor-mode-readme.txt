
**Mode for editing conkeror javascript files.**
-----------------------------------------------

Currently, this minor-mode defines:

1. A function for sending current javascript statement to be
evaluated by conkeror. This function is
`eval-in-conkeror' bound to **C-c C-c**.
2. Syntax coloring.
3. Indentation according to
[Conkeror Guidelines](http://conkeror.org/DevelopmentGuidelines).
4. Warning colors when anything in your code is not compliant with
[Conkeror Guidelines](http://conkeror.org/DevelopmentGuidelines). If
you find this one excessive, you can set
`conkeror-warn-about-guidelines' to `nil'.

Installation:
=============

If you install from Melpa just skip to the activation instructions below.

If you install manually, make sure it's loaded

    (add-to-list 'load-path "/PATH/TO/CONKEROR-MINOR-MODE.EL/")
    (autoload 'conkeror-minor-mode "conkeror-minor-mode")

then follow activation instructions below.

Activation
==========

It is up to you to define when `conkeror-minor-mode' should be
activated. If you want it on every javascript file, just do

    (add-hook 'js-mode-hook 'conkeror-minor-mode)

If you want it only on some files, you can have it activate only on
your `.conkerorrc' file:

    (add-hook 'js-mode-hook (lambda ()
                              (when (string= ".conkerorrc" (buffer-name))
                                (conkeror-minor-mode 1))))

or, alternatively, only on files with "conkeror" somewhere in the path:

    (add-hook 'js-mode-hook (lambda ()
                              (when (string-match "conkeror" (buffer-file-name))
                                (conkeror-minor-mode 1))))
