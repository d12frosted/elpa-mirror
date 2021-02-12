This package provides more intuitive fuzzy matching behavior for Helm.
Use in conjunction with the 'helm-flx' package for best results.
`helm-fuzzier' improves Helm's "matching", meaning that it tries
to ensure the best matches appear on the result list. 'helm-flx',
on the other hand, provides on-the-fly highlighting and (dramatically)
improves Helm's "scoring" so that the results are shown ordered from
"best" to "worst" match.

Usage:

  (require 'helm-fuzzier)
  (helm-fuzzier-mode 1)


The queries you currently use should continue to work reliably.
To take advantage of 'helm-fuzzier', queries should begin with the
same letter as the desired match and should form an abbreviation of
two or more word prefixes from the match.

Query Examples:

- 'emacs-lisp-mode' can be matched by 'el','em', 'elm', 'eli', 'elmo', etc'.
- 'helm-candidate-number-limit' can be matched by 'hcn','hnl', 'hecl', etc'.
- 'package-list-packages' can be matched by 'plp','plpa', 'paclp', etc'.

Discussion:

Helm's support (As of Oct 2015) for fuzzy matching breaks down when
the number of matches exceeds its internal limit
'helm-candidate-number-limit'. Helm will stop looking once it finds
LIMIT matches, even if better matches exist among the remaining candidates.
The result is that the best matches are often not included in the results.

Helm additionally separates *matching* from *scoring* into separate
phases.  the former simply collects LIMIT matches of whatever
quality, the later sorts them from best to worst according to some
heuristic.

'helm-fuzzier' augments helm's default *matching* phase with an
additional *preferred matching* phase which examines _all
candidates for matches that are likely to score highly in the
*scoring* phase, and makes sure they are included in the result
list presented to the user. Without this, the best results are
overlooked when there are lots of low-quality fuzzy matches, and
this failure occurs most often with short queries, exactly the case
users most care about (less keystrokes).

For preferred matching to produce good results there must be good
agreement between what it and what the *scoring* function consider
a "good match".  'helm-fuzzier' was written (and tested) for use
with the new 'helm-flx' package recently added to MELPA (by
@PythonNut), which enhances Helm's *scoring* phase by using
@lewang's 'flx' library.
