The captain handles capitalizing text as you type, freeing you to do other
things.

Invoke the captain across the globe with `global-captain-mode', or just on
one ship (buffer) at a time with `captain-mode'.

For normal people:

Automatically capitalizes the first word of a sentence as you type.  The
bounds of a sentence are determined by local variable
`captain-sentence-start-function'.  For example, you can set it to find the
start of a list or heading in `org-mode'.

In order to get the captain to start working, `captain-predicate' must be
set.  Otherwise, the slacker will just lie around all day doing nothing.

The following will tell the captain to only work on comments in programming
modes:

(add-hook 'prog-mode-hook
   (lambda ()
     (setq captain-predicate (lambda () (nth 8 (syntax-ppss (point)))))))

Or for text modes, work all the time:

(add-hook 'text-mode-hook
          (lambda ()
            (setq captain-predicate (lambda () t))))

Or don't work in source blocks in Org mode:

(add-hook
 'org-mode-hook
 (lambda ()
   (setq captain-predicate
         (lambda () (not (org-in-src-block-p))))))

It's also possible to automatically capitalize individual words using the
command `captain-capitalize-word'.  This will capitalize the word at point
and tell the captain about it, so he knows that you want it capitalized from
then on.  For a package that handles this for any automatic correction, see
the auto-correct package.

This solves a similar problem to that of Kevin Rodgers's auto-capitalize
package, but using more modern Emacs features.