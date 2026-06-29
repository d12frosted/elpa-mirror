# TECO.EL

TECO was an ancient text editor written in the days before most of you
reading this were born.  It supported macros of editing commands as an
extension mechanism.  The original version of EMACS was written by
loading macros into TECO that provided EMACS functionality and then
saving the memory image of the combined TECO command interpreter and
the macros as a new program ("dumping an EMACS").

As an editor, the TECO commands (the operators of the macro language)
were terse and powerful.  Within TECO-based EMACS, one could open a
'minibuffer' by typing ESC ESC and then enter a TECO program which
would be run (by typing ESC ESC again) to modify the underlying EMACS
buffer.  E.g. if you wanted to add a new column containing the string
'EMPTY' between the second and third columns of a CSV file, you could
execute the TECO program

`<.-z; 2fwl i,EMPTY$ l>`

  * "<" loop body ">"
  * ".-z" - an integer expression: current point - end of buffer
  * ";" - end loop test, if prefix arg ".-z" is >= 0, you exit the loop
  * "2fwl" - really three things: "2" => repeat count, "fw" => bounds
    of a word, and "l" => move forward using prefix arg bounds
  * "iSTRING-TO-INSERT$" (where $ is actually ESC)
  * "l" - with no args, move to the beginning of the next line

While this is easily done in modern ELisp-based EMACS with a keyboard
macro, the TECO language offers more functionality than keyboard
macros and is often quicker to use.  Personally, I'm addicted to
clearing a buffer by executing the short TECO program `hk`.

Dale Worley (worley@alum.mit.edu) implemented this TECO interpreter in
Elisp.  It was originally available from the old EMACS LCD archive and
is still kicking around the EmacsWiki.  I created this package to make
it available from the modern Emacs package system.

- mtk@acm.org

[![MELPA](https://melpa.org/packages/flycheck-badge.svg)](https://melpa.org/#/flycheck)

<https://en.wikipedia.org/wiki/TECO_(text_editor)>

<https://emacswiki.org/emacs/TecoInterpreterInElisp>

<https://www.emacswiki.org/emacs/teco.el>

<https://github.com/emacsmirror/teco>

<https://github.com/mtk/teco.git>

