Have you ever fought long battles with the major modes out there (especially
programming-language modes) that force its indentation style on you? Worse,
have you discovered that some of these modes indent your code with a MIXTURE
of TABS *AND* SPACES?

Kakapo-mode is about giving back the control of the TAB character back to you,
the user, with some conditions:

 * The concepts of "indentation" and "leading whitespace" are the same.
 * Indentation is taken care of with TAB characters (which are hard TABS by
   default) but which can be adjusted to be expanded into SPACES.
 * If you press a TAB character *after* some text, we insert SPACES up to the
   next tab-stop column; this is a simpler version of "Smart Tabs"
   (http://www.emacswiki.org/emacs/SmartTabs).
 * If at any point we detect a mixture of tabs and spaces in the indentation,
   we display a warning message when modifying the buffer.

`kakapo-mode' is very similar to "Smart Tabs", but with a key difference: the
latter requires you to write helper functions for it to work properly;
instead, kakapo-mode relies on the human user for aesthetics.

Central to `kakapo-mode' is the idea of the kakapo tab, or "KTAB". The KTAB is
either a hard TAB character or a `tab-width' number of SPACE characters,
depending on whether `indent-tabs-mode' is set to true. `kakapo-mode' inserts
a KTAB when we are indenting (leading whitespace), or the right number of
SPACE characters when we are aligning something inside or at the end of a
line.
