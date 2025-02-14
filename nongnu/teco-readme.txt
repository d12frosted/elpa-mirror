# TECO.EL

TECO is an ancient text editor written in the days before most of you
reading this were born.  It supported macros of editing commands as an
extension mechanism.  The original version of EMACS was written in
TECO by loading macros that provided the EMACS functionality and then
saving the memory image of the combined TECO command interpreter and
macros as a new program ("dumping" an EMACS).

As an editor, the TECO commands (the operators of the macro language)
were terse and powerful.  From within EMACS, one could open a
'minibuffer' by typing ESC ESC and then enter a TECO program which
would be run (by typing ESC ESC again) to modify the underlying EMACS
buffer.  E.g. if you wanted to add a new column containing the string
'EMPTY' between the second and third columns of a CSV file, you could
execute the TECO program

`<.-z; 2fwl i,EMPTY$ l>`

  * "<" loop body ">"
  * ".-z" (point - end of buffer)
  * ";" end loop test (if prefix arg ".-z" is >= 0)
  * "2fwl" is really three things: "2" => repeat count, "fw" => bounds
    of a word, "l" => move forward
  * "iSTRING-TO-INSERT$" (where $ is actually ESC)
  * "l" (with no args) move to the beginning of the next line

While this is easily done with a keyboard macro, the TECO language
offers more functionality and is often quicker to use if you're
willing to pay the cost of learning how to use it.  Personally, I'm
addicted to clearing a buffer by executing the TECO program `hk`.

Dale Worley (worley@alum.mit.edu) implemented this TECO interpreter in
Elisp.  It was originally available from the old EMACS LCD archive and
was still kicking around the EmacsWiki.  Since I still use it, I
created this package to make it available from the modern Emacs
package system.

<https://en.wikipedia.org/wiki/TECO_(text_editor)>

<https://emacswiki.org/emacs/TecoInterpreterInElisp>>

<https://www.emacswiki.org/emacs/teco.el>

<https://github.com/mtk/teco.git>

