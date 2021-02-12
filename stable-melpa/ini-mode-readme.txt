Major mode for Windows-style ini files.

Features:

* Syntax highlight support.

* Inherits from `prog-mode' (if present).  The effect is that global
  minor modes that activates themsleves in `prog-mode' buffers
  automatically work in `ini-mode'.

Example:

![Example](doc/demo.png)

Background:

There are many implementation of major modes for ini files.  This is
my attempt of a modern, simple, implementation.

Installation:

This package is designed to be installed as a "package".  Once
installed, it is automatically used when opening files the .ini
extension.

Anternatively, you can place the following lines in a suitable
initialization file:

    (autoload 'ini-mode "ini-mode" nil t)
    (add-to-list 'auto-mode-alist '("\\.ini\\'" . ini-mode))
