Format of regexps is the same as used for `rx' and `sregex'.
Additions:
- (ere RE) specify regexps using the ERE syntax.
- (inter REs...) (aka `&') make a regexp that only matches
  if all its branches match.  E.g. (inter (ere ".*a.*") (ere ".*b.*"))
  match any string that contain both an "a" and a "b", in any order.
- (case-fold REs...) and (case-sensitive REs...) make a regexp that
  is case sensitive or not, regardless of case-fold-search.

Input format of lexers:

ALIST of the form ((RE . VAL) ...)

Format of compiled DFA lexers:

nil                     ; The trivial lexer that fails
(CHAR . LEXER)
(table . CHAR-TABLE)
(stop VAL . LEXER)      ; Match the empty string at point or LEXER.
(check (PREDICATE . ARG) SUCCESS-LEXER . FAILURE-LEXER)

Intermediate NFA nodes may additionally look like:
(or LEXERs...)
(orelse LEXERs...)
(and LEXERs...)
(join CONT . EXIT)
Note: we call those things "NFA"s but they're not really NFAs.

Bugs:

- `inter' doesn't work right.  Matching `join' to the corresponding `and'
  is done incorrectly in some cases.
- since `negate' uses intersections, it doesn't work right either.
- "(\<)*" leads to a DFA that gets stuck in a cycle.

Todo:

- dfa "no-fail" simplifier
- dfa minimization
- dfa compaction (different representation)
- submatches
- backrefs?
- search rather than just match
- extensions:
  - repeated submatches
  - negation
  - lookbehind and lookahead
  - match(&search?) backward
  - agrep