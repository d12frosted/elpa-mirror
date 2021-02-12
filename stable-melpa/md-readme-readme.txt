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

; Dependencies:
None.

; Installation:
(require 'md-readme), then you can call mdr-generate manually. I
have not found a way to call it automatically that I really like,
but here is one that works for me:

    (require 'md-readme)
    (dir-locals-set-class-variables
     'generate-README-with-md-readme
     '((emacs-lisp-mode . ((mdr-generate-readme . t)))))
    (dolist (dir '("~/Projects/wpmail/" "~/Projects/md-readme/"))
      (dir-locals-set-directory-class
       dir 'generate-README-with-md-readme))
    (add-hook 'after-save-hook
              '(lambda () (if (boundp 'mdr-generate-readme) (mdr-generate))))

; Binaries
`bin/md-readme` is a shell script that will generate readme.md for the
passed file. See it for usage instructions.
