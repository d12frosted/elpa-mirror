
This module copies selected regions in org-mode as formatted text on the
clipboard that can be pasted into other applications. When not in org-mode,
the htmlize library is used instead.

For Windows the html-clip-w32.py script will be installed. It works pretty
well, but I noticed that the hyperlinks in the TOC to headings don't work,
and strike-through doesn't seem to work. I have no idea how to fix either
issue.

Mac OSX needs textutils and pbcopy, which should be part of the base install.

Linux needs a relatively modern xclip, preferrably a version of at least
0.12. https://github.com/astrand/xclip

The main command is `ox-clip-formatted-copy' that should work across
Windows, Mac and Linux. By default, it copies as html.

Note: Images/equations may not copy well in html. Use `ox-clip-image-to-clipboard' to
copy the image or latex equation at point to the clipboard as an image. The
default latex scale is too small for me, so the default size for this is set
to 3 in `ox-clip-default-latex-scale'. This overrides the settings in
`org-format-latex-options'.
