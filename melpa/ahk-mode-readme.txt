A major mode for editing AutoHotkey (AHK) script.  Supports commenting,
indentation, syntax highlighting, and help lookup both localling and on
the web.

; INSTALL

Open the file, then type “M-x eval-buffer”.  You are done.  Open
any ahk script, then type “M-x ahk-mode”, you'll see the
source code syntax colored.

To have Emacs automatically load the file when it restarts, and
automatically use the mode when opening files ending in “.ahk”, do this:

This package is located within Melpa.  To install, add
("melpa" . "http://melpa.org/packages/") to package-archives and
execute "M-x package-install RET ahk-mode RET".

; FEATURES

When opening a script file you will get:
- syntax highlighting
- Commenting - provide functions for block and standard commenting
- Imenu - jump to a function / label within a buffer
- Execute scripts
- Auto complete - adds options for `company-mode' and `auto-complete-mode'

TODO:
- smart identification of ahk_l and ahk - use chm file
- Indentation - indent based on current style
- Lookup reference - both on the web and through the installed CHM file
- Execute scripts - support redirects of error to stdout
- Debugging features - work with dgdb.ahk
- add yasnippet support

Notes on indentation
Indentation is styled with bracing on current line of if / else statements
or on empty next line.

Block types that can affect indentation
comments - ; AAA
- previous block beginning brace = +0
- indentation level is skipped when determining position for current line
function - AAA(.*) { .\n. } = +1
function - AAA(.*) { } = +0
label - AAA: = 0
Keybindings (next line) AAA:: = +1
Keybindings (current line) AAA:: =+0
Open block - {( +1 on next
Close block - {( -1 on current
Class AAA.* { ... } = +1
#if block open - #[iI]f[^ \n]* (.*) = +1
#if block close - #[iI]f[^ \n]*$ = -1
return block - [Rr]eturn = -1
for .*\n { .. } = +1
loop .*\n { .. } = +1
open assignment - .*operator-regexp$ = +1

existing issues :

paren broken across multiple lines
DllCall("SetWindowPos", "uint", Window%PrevRowText%, "uint", Window%PPrevRowText%
        , "int", 0, "int", 0, "int", 0, "int", 0
          , "uint", 0x13)  ; NOSIZE|NOMOVE|NOACTIVATE (0x1|0x2|0x10)


; HISTORY

version 1.5.2, 2015-03-07 improved auto complete to work with ac and company-mode
version 1.5.3, 2015-04-05 improved commenting and added imenu options
version 1.5.4, 2015-04-06 indentation is working, with bugs
version 1.5.5, 2015-07-20 added load website
version 1.5.6, 2016-03-20 execute script works
