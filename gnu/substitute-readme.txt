# Substitute (substitute.el) for GNU Emacs

Efficiently replace targets in the buffer or context.

Substitute is a set of commands that perform text replacement (i)
throughout the buffer, (ii) limited to the current definition (per
`narrow-to-defun`), (iii) from point to the end of the buffer, and
(iv) from point to the beginning of the buffer. Variations of these
scopes are also available.

These substitutions are meant to be as quick as possible and, as such,
differ from the standard `query-replace` (which I still use when
necessary). The provided commands prompt for substitute text and
perform the substitution outright, without moving the point. The
target is the symbol/word at point or the text corresponding to the
currently marked region. All matches in the given scope are
highlighted by default.

+ Package name (GNU ELPA): `substitute`
+ Official manual: <https://protesilaos.com/emacs/substitute>
+ Git repositories:
  + GitHub: <https://github.com/protesilaos/substitute>
  + GitLab: <https://gitlab.com/protesilaos/substitute>
+ Video demo: <https://protesilaos.com/codelog/2023-01-16-emacs-substitute-package-demo/>
+ Backronym: Substitutions Uniformly Beget Standardisation for Text Invariably Transfigured Unto This Entry.
