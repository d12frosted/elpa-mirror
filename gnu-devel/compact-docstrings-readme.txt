=============================
 Compact docstrings in Emacs
=============================

Shrink blank lines in docstrings and doc comments

.. image:: etc/compact-docstrings.png

Setup
=====

Enable locally with ``compact-docstrings-mode``::

  (add-hook 'some-mode-hook #'compact-docstrings-mode)

Enable globally (in all programming modes) with ``global-compact-docstrings-mode``::

  (add-hook 'after-init-hook #'global-compact-docstrings-mode)

Customization
=============

Enable compaction of all comments and strings by setting ``compact-docstrings-only-doc-blocks`` to ``nil``.  Change the compact line height by customizing ``compact-docstrings-face``.
