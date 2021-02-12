
This package provides two methods for inserting mathematical
symbols:

- The command `unicode-math-input' to browse through all Unicode
  math symbols, with TeX names as specified by the unicode-math
  LaTeX package.

- A proper input method for efficient typing.  Activate with `C-u
  C-\ unicode-math RET'.  Then TeX commands (e.g., `\alpha') are
  replaced automatically as you type with the corresponding Unicode
  character.

The `unicode-math' input method is similar to Emacs's built-in
`TeX', but it differs in a couple of ways.  First, it has a much
larger collection of characters, including various alphabets
(Fraktur, script, etc.) and combining accents (note you have to
type, say, \pi\hat to get π̂).  Second, it does not include any
sequence not starting with a backslash, so it interferes less with
normal typing.

The input method can be customized by the variables
`unicode-math-input-escape', `unicode-math-input-min-prefix' and
`unicode-math-input-deterministic' (but they must be set before
loading the package).  The buffer-local variable
`unicode-math-input-insert-tex' determines the default action of
the browse command.
