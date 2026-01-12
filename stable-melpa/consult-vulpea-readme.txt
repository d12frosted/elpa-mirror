This package integrates `vulpea' with `consult' to provide
enhanced minibuffer interactions, most notably live file previews
when selecting notes with `vulpea-find' and `vulpea-insert'.

To enable, simply turn on `consult-vulpea-mode':

  (consult-vulpea-mode 1)

Features:

1. **Live previews**: When selecting notes via `vulpea-find' or
   `vulpea-insert', you get a live preview of the note file as you
   navigate through candidates.

2. **Consult-powered grep/find**: Use `consult-vulpea-grep' and
   `consult-vulpea-find' to search within your vulpea directories
   with live previews.
