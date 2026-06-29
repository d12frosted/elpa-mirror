==============================================================
 The Simple Emacs Interface to `Ack <http://beyondgrep.com>`_-like Tools
==============================================================

.. image:: https://elpa.gnu.org/packages/ack.svg
   :target: https://elpa.gnu.org/packages/ack.html
   :alt: GNU ELPA package

This package integrates `ack <http://beyondgrep.com>`_ with `Emacs
<http://www.gnu.org/software/emacs>`_.  The resulting ``*ack*`` buffer
is just like vanilla ``*grep*`` but results come from your tool of
choice.

Not only ack, but Ack-like tools such as `the silver searcher (ag)
<https://github.com/ggreer/the_silver_searcher>`_, `ripgrep (rg)
<https://github.com/BurntSushi/ripgrep>`_ are well supported, as are
``git grep`` and ``hg grep``.

The program guesses good defaults -- including searching for the thing
at point -- but lets you input ``C-u`` to customize the directory,
commands, switches etc...

Install
-------

Ack is part of `GNU ELPA <http://elpa.gnu.org>`_ - the official package
archive for Emacs:

``M-x package-install RET ack RET``

Usage
-----

Just ``M-x ack`` or do something like ``(global-set-key (kbd "C-c
C-g") 'ack)``.

Screenshots
-----------

* ack

.. figure:: http://i.imgur.com/VwWyzAe.png
   :target: http://i.imgur.com/VwWyzAe.png
   :alt: ack.png

* git grep

.. figure:: http://i.imgur.com/rwjC4pa.png
   :target: http://i.imgur.com/rwjC4pa.png
   :alt: ack-git-grep.png

More Usage
----------

- Type ``M-x ack`` and provide a pattern to search.
- Type ``C-u M-x ack`` to search from current project root.
- Type ``C-u C-u M-x ack`` to interactively choose a directory to search.

While reading ack command and args from the minibuffer, the following
key bindings may be useful:

- ``M-I`` => insert a template for case-insensitive file name search
- ``M-G`` => insert a template for ``git grep``, ``hg grep`` or ``bzr grep``
- ``M-Y`` => grab the symbol at point from the window before entering
  the minibuffer
- ``TAB`` => completion for ack options

If you use the above keybindings very often, stick the corresponding
command names in ``ack-minibuffer-setup-hook``. The following snippet
makes ``M-x ack`` insert a ``git|hg|bzr grep`` template if searching
from a project root. Then it will try to insert the symbol at point.

.. code-block:: lisp

  (add-hook 'ack-minibuffer-setup-hook 'ack-skel-vc-grep t)
  (add-hook 'ack-minibuffer-setup-hook 'ack-yank-symbol-at-point t)

Emacs 23
--------

Check out the `emacs23
<https://github.com/leoliu/ack-el/tree/emacs23>`_ branch.

Bugs
----

https://github.com/leoliu/ack-el/issues

Contributors
------------
Phillip Lord. The original author and previous mantainer is Leo Liu.
