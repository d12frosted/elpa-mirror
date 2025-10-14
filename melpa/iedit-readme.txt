This package includes Emacs minor modes (iedit-mode and iedit-rectangle-mode)
based on a API library (iedit-lib) and allows you to alter one occurrence of
some text in a buffer (possibly narrowed) or region, and simultaneously have
other occurrences changed in the same way, with visual feedback as you type.

`iedit-mode' is a great alternative of build-in replace commands:

 - A more intuitive way to alter all the occurrences at once
 - Visual feedback
 - Less keystrokes in most cases

Normal work flow of Iedit mode is like:

 - Move point to a target by `isearch' or other moving commands

 - Press C-;(The default key binding) to enable Iedit mode.  The thing under
   the point is recognized as an occurrence, and all the occurrences in the
   buffer are highlighted

 - Edit one of the occurrences
   The change is applied to other occurrences simultaneously.

 - Finish - by pressing C-; again

Many other work flows to highlight occurrences are possible, for example,
rectangle selection, incremental selection and markup tag pair selection.

You can also use Iedit mode as a quick way to temporarily show only the
buffer lines that match the current text being edited.  This gives you the
effect of a temporary `keep-lines' or `occur'.  To get this effect, hit C-'
when in Iedit mode - it toggles hiding non-matching lines.

`iedit-mode' is optimized for renaming refactoring in many ways:

 - The symbol under point is selected as occurrence by default and only complete
   symbols are matched

 - With digit prefix argument 0, only occurrences in current function are matched

 - Last renaming refactoring is remembered and can be applied to other buffers
   later

 - Once in iedit mode, you can select a region and hit C-; again to restrict
   the search area to the region

 - Restricting the search area to just the current line can be done by
   pressing M-I.

 - Restricting the search area to the lines near the current line can
   be done by pressing M-{ and M-}.  These will expand the search
   region one line at a time from the top and bottom.  Add a prefix
   argument to go the opposite direction.

Iedit-rectangle-mode provides rectangle support with *visible rectangle*
highlighting, which is similar with cua mode rectangle support.  But it's
lighter weight and uses iedit mechanisms.

There are also some other facilities you may never think about.  Refer to the
document of function `iedit-mode' (C-h f iedit-mode RET) for more details.

; Contributors
Adam Lindberg <eproxus@gmail.com> added a case sensitivity option that can be toggled.

Tassilo Horn <tassilo@member.fsf.org> added an option to match only complete
words, not inside words

Le Wang <l26wang@gmail.com> proposed to match only complete symbols,  not
inside symbols, contributed rectangle support
