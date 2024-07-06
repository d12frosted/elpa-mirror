The git-based source code hosting site <http://github.com> has
lately become popular for Emacs Lisp projects. Github has a feature
that displays files named "README[.suffix]" automatically on a
project's main page. If these files are formatted in Markdown, the
formatting is interpreted. See
<http://github.com/guides/readme-formatting> for more information.

Emacs Lisp files customarily have a header in a fairly standardized
format. md-readme extracts this header, re-formats it to Markdown,
and writes it to the file "README.md" in the same directory. If you
put your code on github, you could have this run automatically, for
instance upon saving the file or from a git pre-commit hook, so you
always have an up-to-date README on github.

It recognizes headings, the GPL license disclaimer which is
replaced by a shorter notice linking to the GNU project's license
website, lists, and normal paragraphs. It escapes `backtick-quoted'
names so they will display correctly. Lists are somewhat tricky to
recognize automatically, and the program employs a very simple
heuristic currently.
