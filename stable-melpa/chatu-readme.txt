When you are drawing with draw.io or plantuml and you want to
insert the svg image exported from the file, the operation is
nontrivial.  This extension provide two commands to reduce the
manual work:

- `chatu-new' add a chatu line
- `chatu-add' convert diagram to svg, and insert it to buffer
- `chatu-open' open diagram file at the point

When `chatu-mode' is activated,
in `org-mode',
- "C-c C-o" on chatu line will invoke `chatu-open'
- "C-c C-c" on chatu line will invoke `chatu-add'

in `markdown-mode'
- "C-c C-o" on chatu line will invoke `chatu-open'
- "C-c C-c C-c" on chatu line will invoke `chatu-add'
