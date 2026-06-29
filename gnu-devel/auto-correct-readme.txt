To enable, use:

M-x `auto-correct-mode'

After that, any future corrections made with flyspell or Ispell (or any other
supported package) will be automatically corrected for you as you type.

For example, if you type "befroe" and fixed it with `ispell-word',
`auto-correct-mode' will change "befroe" to "before" every time you type it
from then on.

Corrections are only made when `auto-correct-mode' is enabled.  Expansion is
case-insensitive, so trying to fix alice as Alice won't work.  Use the
captain package for this instead.

Auto-correct is controlled further by `auto-correct-predicate'.  In order to
enable auto-correct in a given buffer, the function to which
`auto-correct-predicate' is set must return true at the current point.

For example, the following will tell auto-correct to only correct mistakes in
a programming mode buffer that fall within a comment:

(add-hook 'prog-mode-hook
   (lambda ()
     (setq auto-correct-predicate (lambda () (nth 8 (syntax-ppss (point)))))))

Or for text modes, work all the time:

(add-hook 'text-mode-hook
          (lambda ()
            (setq auto-correct-predicate (lambda () t))))

Or don't work in source blocks in Org mode:

(add-hook
 'org-mode-hook
 (lambda ()
   (setq auto-correct-predicate
         (lambda () (not (org-in-src-block-p))))))

Behind the scenes, auto-correct uses an abbrev table, so in order to clean
out or modify any fixes auto-correct has learned, use `list-abbrevs'.  This
also means that fixes are saved between Emacs sessions along with the abbrev
tables.

Ispell and flyspell are the only two packages that auto-correct supports out
of the box, but it's possible to add support for any package that corrects
text:

1. Create a function that calls `auto-correct--add-or-update-correction' with
the old text and the corrected text from your package.

2. Write a function to activate and deactivate support for your package.  It
should take a single argument, which is a boolean indicating whether to
activate or deactivate support.

3. Call `auto-correct-handle-support', passing t as the first argument and
your function as the second.  To disable support, pass nil as the first
argument instead.

4. You're done.