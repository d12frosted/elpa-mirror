Commands inserting paired delimiters, by default literatim.

With \\[universal-argument] and with active region,
 --i.e. transient-mark-mode-- wrap around. With numerical ARG insert the
delimiter arg times

In order to insert a pair at point call `C-<space>` i.e. `set-mark-command` first maybe.

Create your own commands by just providing the delimiting
charakters as shown below with math white square brackets:

(defun simple-paren-mathematical-white-square-bracket (arg)
  "Insert MATHEMATICAL LEFT/RIGHT WHITE SQUARE BRACKETs"
 (interactive "*P") (simple-paren--intern ?⟦ ?⟧
    arg))

Or even shorter:
(simple-paren-define mathematical-white-square-bracketwhitespace ?⟦  ?⟧)

Examples, cursor as pipe-symbol:

(defun foo1 |	==> (defun foo1 ()

with active region and \\[universal-argument] until end of word
|interactive		==> (interactive)

with active region and \\[universal-argument] until end of word
int|eractive		==> int(eractive)

With ‘simple-paren-honor-padding-p’ set to ‘t’, active region
and \\[universal-argument]
| foo		==> ( foo )

Insertions are not electric, thus a mnemonic key is recommended:

(global-set-key [(super ?\()] 'simple-paren-parentize)
(global-set-key [(super ?{)] 'simple-paren-brace)
(global-set-key [(super ?\[)] 'simple-paren-bracket)
(global-set-key [(super ?')] 'simple-paren-singlequote)
(global-set-key [(super ?\")] 'simple-paren-doublequote)
(global-set-key [(super ?<)] 'simple-paren-lesser-than)
(global-set-key [(super ?>)] 'simple-paren-greater-than)

