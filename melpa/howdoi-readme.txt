Do you find yourself constantly Googling for how to do basic
programing tasks? Suppose you want to know how to format a date in
bash. Why open your browser and read through blogs when you can
just M-x howdoi-query RET format date bash

This package was inspired by Tom (adatgyujto at gmail.com). It was
his idea to make a port of command line tool such as python's
`howdoi`: https://github.com/gleitz/howdoi

Thank you, Tom!

Commands:

The following two commands show an answer in a pop up buffer:
M-x howdoi-query RET <your-query>
M-x howdoi-query-line-at-point ;; takes a query from a line at point

To get an answer containing only code snippet you could use:
M-x howdoi-query-line-at-point-replace-by-code-snippet
    this command replaces current line with a code snippet
    parsed from an answer.

In case of last command you could get situation when it returns not
good enough code snippet. Or may be after that command you would
like to get more details which relates to the original query. Then
you could use the following command:

M-x howdoi-show-current-question

This one will show (in a pop up buffer) full answer which contains
recently inserted code snippet. This command may help sometimes to
avoid additional googling when original query is a little bit
ambiguous.

By default pop up buffer displays only answers. You could change
`howdoi-display-question` custom variable to show also a question.

In the mentioned pop up buffer enables HowDoI major-mode. There are
such key bindings are available:

n - howdoi-show-next-question
p - howdoi-show-previous-question
b - howdoi-browse-current-question
u - howdoi-query
< - beginning-of-buffer
> - end-of-buffer
q - quit window

There is also howdoi-minor-mode available with a list of key
bindings:

C-c C-o n - howdoi-show-next-question
C-c C-o p - howdoi-show-previous-question
C-c C-o c - howdoi-show-current-question
C-c C-o b - howdoi-browse-current-question
C-c C-o u - howdoi-query
C-c C-o l - howdoi-query-line-at-point
C-c C-o r - howdoi-query-line-at-point-replace-by-code-snippet
C-c C-o i - howdoi-query-insert-code-snippet-at-point

