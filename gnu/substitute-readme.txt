# Substitute (substitute.el)

Efficiently replace targets in the buffer or context.

**Video demo:** <https://protesilaos.com/codelog/2023-01-16-emacs-substitute-package-demo/>

+ Package name (GNU ELPA): `substitute`
+ Git repo on SourceHut: <https://git.sr.ht/~protesilaos/substitute>
  - Mirrors:
    + GitHub: <https://github.com/protesilaos/substitute>
    + GitLab: <https://gitlab.com/protesilaos/substitute>
+ Mailing list: <https://lists.sr.ht/~protesilaos/general-issues>
+ Backronym: Some Utilities Built to Substitute Targets Independent of
  Their Utterances, Thoroughly and Easily.

## Overview

Substitute is a set of commands that perform text replacement (i)
throughout the buffer, (ii) limited to the current definition (per
`narrow-to-defun`), (iii) from point to the end of the buffer, and
(iv) from point to the beginning of the buffer.

These substitutions are meant to be as quick as possible and, as such,
differ from the standard `query-replace` (which I still use).  The
provided commands prompt for substitute text and perform the
substitution outright.

The substitution prompt mentions the target-to-be-substituted.  It is
possible to use the "future history" at this prompt (by typing `M-n`
with the default key bindings for the `next-history-element` command).
This populates the prompt with the text of the target.  As such, if we
want to operate on `FOO` to make it `FOO-BAR`, we use `M-n` and then
append `-BAR`.

By default, the design is visually austere: the substitution prompt
informs the user about the target but otherwise does not highlight
anything.  The post-substitution stage is also silent, with no report
on how many occurrences were replaced.  This can be changed so that
the substitution prompt highlights occurrences (like `isearch`) and
the post-substitution stage prints an informative message on what
changed and where.  Refer to the "Sample configuration" further below.

The substitution commands behave the same way except for their scope
of application.  What they have in common is how they identify the
target of the substitution: it is either the symbol at point or the
text within the boundaries of the active region.  The differences in
scope are as follows:

1. `substitute-target-in-buffer`: Substitute the target across the
   entire buffer.
2. `substitute-target-in-defun`: Substitute the target only in the
   current definition (per `narrow-to-defun`).
3. `substitute-target-below-point`: Substitute the target from point
   to the end of the buffer (alias
   `substitute-target-to-end-of-buffer`).
4. `substitute-target-above-point`: Substitute the target from point
   to the beginning of the buffer (alias
   `substitute-target-to-beginning-of-buffer`).

## Sample configuration

```elisp
(require 'substitute)

;; If you like visual feedback on the matching target.  Default is nil.
(setq substitute-highlight t)

;; If you want a message reporting the matches that changed in the
;; given context.  We don't do it by default.
(add-hook 'substitute-post-replace-hook #'substitute-report-operation)

;; We do not bind any keys.  This is just an idea.  The mnemonic is
;; that M-# (or M-S-3) is close to M-% (or M-S-5).
(let ((map global-map))
  (define-key map (kbd "M-# s") #'substitute-target-below-point)
  (define-key map (kbd "M-# r") #'substitute-target-above-point)
  (define-key map (kbd "M-# d") #'substitute-target-in-defun)
  (define-key map (kbd "M-# b") #'substitute-target-in-buffer))
```

## Why this instead of `multiple-cursors` or `iedit`

What I do not like about those packages is that they are visually
"busy".  Oftentimes, I want to perform a replacement in some context
with multiple occurrences of a given target.  Using either of those
echoes my input across all occurrences, resulting in a dance of sorts
as text moves around.  I find it disorienting.  Beside that, I do not
need the visual feedback as I already know what I want to do: the
default minimalist presentation of `substitute` provides all the
information I need.

Otherwise, this package is small and limited in scope.  Beside
`substitute`, I also use keyboard macros, `query-replace`, and
`rectangle-mark-mode` in tandem with `string-rectangle`.
