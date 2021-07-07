Side Hustle
===========

Hustle through a buffer's Imenu in a side window in GNU Emacs.

Side Hustle works on multiple buffers simultaneously, does not require a
global minor mode, and does not rely on timers.


Installation
------------

Add something like this to your init file:

    (define-key (current-global-map) (kbd "M-s l") #'side-hustle-toggle)


Bugs and Feature Requests
-------------------------

Send me an email (address in the package header). For bugs, please
ensure you can reproduce with:

    $ emacs -Q -l side-hustle.el

Known issues are tracked with FIXME comments in the source.


Alternatives
------------

Side Hustle takes inspiration primarily from
[imenu-list](https://github.com/bmag/imenu-list).
