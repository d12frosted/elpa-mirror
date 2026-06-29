####################
Emacs Cycle at Point
####################

Immediately cycle text at the cursor, without prompting.

Unlike most actions to select from a list ``cycle-at-point`` replaces the text immediately,
calling again to cycle over options.

This has the following characteristics:

- Completion options are displayed in the echo-area.
- Only ever adds a single undo step.
- Supports user defined lists.

Available via `melpa <https://melpa.org/#/cycle-at-point>`__.


Motivation
==========

Some words in programming languages have direct opposites where having to remove and re-enter the text can be tedious,
a common example is ``True`` and ``False``,
however others exist such as ``public`` / ``private`` .. depending on the language.

While there are many options for completion available for Emacs,
most rely on prompts that require multiple key-strokes to activate, select and confirm.

This package handles this with a single key stroke, with the ability to cycle between multiple options if required.


Usage
=====

This package exposes the following interactive functions:

- ``cycle-at-point``


On successive calls these commands cycle to the next item.
To cycle in the reverse press ``[keyboard-quit]`` (Ctrl-G),
which causes the next completion command to reverse the direction.


Included Presets
----------------

Programming languages:

``c++-mode``
   - The same as ``c-mode`` with addition of ``public`` / ``private``.

``c-mode``
   - Cycle common terms (``true`` / ``false``, ``>=`` / ``<=``, ``==`` / ``!=``, ... etc).
   - Number bases (decimal, hexadecimal).
   - Alphabet characters.

``cmake-mode``
   - Cycle common terms (``TRUE`` / ``FALSE``, ``ON`` / ``OFF``, ``VERSION_LESS`` / ``VERSION_GREATER``, ... etc).
   - Alphabet characters.

``emacs-lisp-mode``
   - Common terms (``t`` / ``nil``, ``when`` / ``unless``, ... etc).
   - Alphabet characters.

``python-mode``
   - Cycle common terms (``True`` / ``False``, ``>=`` / ``<=``, ``is`` / ``is not`` ... etc).
   - Number bases (binary, octal, decimal, hexadecimal).
   - Alphabet characters.

Spoken languages:

``lang-en``
   - Cycle common English words (days & months).
   - Alphabet characters.

*Presets for other languages welcome!*


Key Bindings
------------

You will need to map these to keys yourself.

Key binding example for Emacs default layout, using ``Alt-P``:

.. code-block:: elisp

   (global-set-key (kbd "M-p") 'cycle-at-point)

Key binding example for evil-mode layout, using ``Alt-Z``:

.. code-block:: elisp

   (global-unset-key (kbd "M-z"))
   (define-key evil-normal-state-map (kbd "M-z") 'cycle-at-point)

If you want to bind a key directly to cycling in the reverse direction
it can be done using ``-1`` for the prefix argument.

Key binding example, using ``Alt-Shift-P``:

.. code-block:: elisp

   (global-set-key (kbd "M-P")
     (lambda ()
       (interactive)
       (let ((current-prefix-arg '(-1)))
         (call-interactively 'cycle-at-point))))


Customization
-------------

``cycle-at-point-preset-override``
   The identifier to use when loading a preset, this can be useful if you wish the use the preset
   from a different major-mode (especially in the case of tree-sitter major modes).

``cycle-at-point-list``
   Setting this value is optional, when left unset a preset will be used when available.

   Buffer local list of items to use for rotation.
   A function that returns a list is also supported.

   **List Format**

   Each list item contains keyword/value pairs:

   ``:data``
      Where the value is a list of strings,
      or a function that returns a list of strings when called (required).

      In the case multiple values may match the same literal, the more specific case must be included first.
      So data should be ordered ``'("is not" "is")``.

      Function call support allows the list of items to be dynamically generated based on the text under the cursor.
   ``:case-fold``
      Where the value is a boolean for case insensitive matching
      (optional, ``nil`` by default).

      When true, matching the literals is case insensitive.
      Replacements follow the current case: lower, upper or title-case.

   .. code-block:: elisp

      (setq cycle-at-point-list
         (list '(:data ("yes" "no") :case-fold t))
         (list '(:data ("open" "close") :case-fold t))
         (list '(:data ("hello" "goodbye") :case-fold t)))


Details
=======

- Results are cached for fast execution.
- The ``recomplete`` package is used to implement text replacement and cycling.


Installation
============

The package is `available in melpa <https://melpa.org/#/cycle-at-point>`__ as ``cycle-at-point``.

.. code-block:: elisp

   (use-package cycle-at-point)
