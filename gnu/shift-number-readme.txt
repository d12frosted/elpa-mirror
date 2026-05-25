
##################
Emacs Shift Number
##################

About
=====

This Emacs package provides commands to increase and decrease the number
at point (or the next number on the current line).

Supported number formats:

- Decimal: ``42``, ``-17``, ``+5``, ``007``
- Binary: ``0b101``, ``0B1010``
- Octal: ``0o42``, ``0O755``
- Hexadecimal: ``0xBEEF``, ``0xcafe``
- Superscript: ``⁴²``, ``⁻¹``
- Subscript: ``₄₂``, ``₋₁``


Installation
============


Automatic
---------

This package can be installed from `MELPA <http://melpa.org/>`__
(with ``M-x package-install`` or ``M-x list-packages``).


Manual
------

For the manual installation, clone the repository, add the directory to
``load-path`` and add autoloads for the interactive commands:

.. code-block:: elisp

   (add-to-list 'load-path "/path/to/shift-number-dir")
   (autoload 'shift-number-up "shift-number" nil t)
   (autoload 'shift-number-down "shift-number" nil t)
   (autoload 'shift-number-up-incremental "shift-number" nil t)
   (autoload 'shift-number-down-incremental "shift-number" nil t)


Usage
=====

As you can see in the gif demonstration:

- ``M-x shift-number-up`` increases the current number.

  If there is no number at point, the first number between the current position and the end of line is increased.
  With a numeric prefix ARG, the number is increased by ARG.

- ``M-x shift-number-down`` decreases the current number.

You may bind some keys to these commands in a usual manner, for example:

.. code-block:: elisp

   (global-set-key (kbd "M-+") 'shift-number-up)
   (global-set-key (kbd "M-_") 'shift-number-down)


Region and Rectangle Support
----------------------------

When a region is active, all numbers in the region are modified.
Rectangle selections (via ``rectangle-mark-mode``) are also supported.


Incremental Mode
----------------

For incrementing multiple numbers with progressively increasing values,
use the incremental commands:

- ``M-x shift-number-up-incremental`` increases each number progressively
  (first by 1, second by 2, etc.).

- ``M-x shift-number-down-incremental`` decreases each number progressively.

These commands operate on all numbers between point and mark.
The mark must be set, but the region does not need to be active.

This is useful for creating sequences. For example, with ``0 0 0`` between
point and mark, running ``shift-number-up-incremental`` produces ``1 2 3``.

The incremental count continues across lines and rectangle cells, so with
three lines of ``0 0 0`` between point and mark, incrementing produces::

   1 2 3
   4 5 6
   7 8 9


Custom Variables
----------------

``shift-number-negative``: ``t``
   When non-nil, support negative numbers.

``shift-number-motion``: ``nil``
   Control cursor movement after modifying a number. Options are:

   - ``nil``: cursor stays at beginning of number, mark unchanged.
   - ``t``: cursor moves to end of number, mark unchanged.
   - ``'mark``: cursor moves to end of number, mark set to beginning.

``shift-number-pad-default``: ``nil``
   When non-nil, preserve the number's width when it shrinks
   (e.g., ``10`` becomes ``09`` when decremented).

``shift-number-separator-chars``: ``nil``
   A string of separator characters allowed in numeric literals for visual
   grouping. For example, set to ``"_"`` to support numbers like ``1_000_000``.

``shift-number-case``: ``nil``
   Case to use for hexadecimal numbers. Options are:

   - ``nil``: preserve current case.
   - ``'upcase``: use upper case (A-F).
   - ``'downcase``: use lower case (a-f).

``shift-number-incremental-direction-from-region``: ``t``
   When non-nil, reverse incremental direction when point is before mark.
   With point before mark, ``shift-number-up-incremental`` on ``0 0 0``
   produces ``3 2 1`` instead of ``1 2 3``.

``shift-number-redo``: ``nil``
   When non-nil, repeated shift-number commands add only one entry to the
   undo history for the whole run, keeping it free of noise.

   Requires the `with-command-redo <https://codeberg.org/ideasman42/emacs-with-command-redo>`__
   package to be installed.


Related packages
================

Other packages for a similar task (modifying the number at point):

- `operate-on-number <https://github.com/knu/operate-on-number.el>`__
- `number <https://github.com/chrisdone/number>`__

Comparing with them, ``shift-number`` has the following distinctions:

- If there is no number at point, it operates on the next number on the
  current line.

- The point does not move anywhere when a number is modified
  (unless ``shift-number-motion`` is enabled).

- If a number has leading zeros (for example ``007``), they are preserved
  during shifting.

- Supports multiple number formats: decimal, binary, octal, hexadecimal,
  superscript, and subscript.

- Supports region and rectangle selections.

`evil-numbers <https://github.com/juliapath/evil-numbers>`__
   Uses ``shift-number`` as its backend, providing Evil (Vim emulation)
   integration with operators and visual state support.
