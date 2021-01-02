
memolist.el is Emacs port of memolist.vim. Org-mode is very useful and multifunction,
but it is also hard to approach and coufuse with markdown. memolist.el offer you
simple interface for writing and searching.

This program make markdown file in your `memolist-memo-directory' or
search markdown file there. By default, `memolist-memo-directory' is
set to "~/Memo" directory. If you would like to change it,
use custom-set-valiables function like this.

(custom-set-variables '(memolist-memo-directory "/path/to/your/memo/directory"))

Commands:
`memolist-show-list': Show markdown file which placed in `memolist-memo-directory'.
`memolist-memo-grep': Search contents of markdown file by arg.
`memolist-memo-grep-tag': Search tags in markdown file by arg.
`memolist-memo-new': Create new markdown file in `memolist-memo-directory'.
