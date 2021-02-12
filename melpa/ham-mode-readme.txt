
### Seamlessly edit an html file using markdown. ###

**H**TML **a**s **M**arkdown.

This package defines a major-mode, `ham-mode', which allows you to
edit HTML files exactly as if they were Markdown files. Activate it
while visiting an HTML file. The buffer will be converted to Markdown,
but the file will still be kept in HTML format behind the scenes. Each
time you save the Markdown buffer, the file will be updated with the
HTML.

**Why?** This is mainly designed to be used with web interfaces which
take HTML text (such as some email clients) but whose editors pale in
comparison to Emacs (obviously).

This major mode will allow you edit your email (or whatever else
you're writing) with the full power of `markdown-mode'. In fact, you
will usually be able to write richer structures then client's web
interface would normally allow you to (lists within lists, for
instance). Just check out <C-h> C-f markdown-mode RET< to> see the full
range of commands available for editing.

Instructions
------

To use this package, simply:

1. Install it from Melpa (M-x `package-install' RET ham-mode) and the
`ham-mode' command will be autoloaded.
2. Activate it inside any HTML files you'd like to edit as Markdown.
You can manually invoke M-x `ham-mode', or add it to `auto-mode-alist'
so that it can load automatically.
For instance, the following snippet will activate `ham-mode' in any
`.htm' file containing the word *email*.

        (add-to-list 'auto-mode-alist '(".*email.*\\.html?\\'" . ham-mode))

