This package is an Emacs minor mode and allows you to edit one occurrence of
some text in a buffer (possibly narrowed) or region, and simultaneously have
other occurrences edited in the same way.

Normal scenario of iedit-mode is like:

- Highlight certain contents - by press C-; (The default key binding)
  All occurrences of a symbol, string in the buffer or a region may be
  highlighted corresponding to current mark, point and prefix argument.
  Refer to the document of `iedit-mode' for details.

- Edit one of the occurrences
  The change is applied to other occurrences simultaneously.

- Finish - by pressing C-; again

You can also use Iedit mode as a quick way to temporarily show only the
buffer lines that match the current text being edited.  This gives you the
effect of a temporary `keep-lines' or `occur'.  To get this effect, hit C-'
when in Iedit mode - it toggles hiding non-matching lines.

Renaming refactoring is convenient in Iedit mode

- The symbol under point is selected as occurrence by default and only
  complete symbols are matched
- With digit prefix argument 0, only symbols in current function are matched
- Restricting symbols in current region can be done by pressing C-; again
- Last renaming refactoring is remembered and can be applied to other buffers
  later

There are also some other facilities you may never think about.  Refer to the
document of function `iedit-mode' (C-h f iedit-mode RET) for more details.

The code was developed and fully tested on Gnu Emacs 24.0.93, partially
tested on Gnu Emacs 22. If you have any compatible problem, please let me
know.

; Contributors
Adam Lindberg <eproxus@gmail.com> added a case sensitivity option that can be toggled.

Tassilo Horn <tassilo@member.fsf.org> added an option to match only complete
words, not inside words

Le Wang <l26wang@gmail.com> proposed to match only complete symbols,  not
inside symbols, contributed rectangle support
