Grizzl provides a fuzzy completion framework for general purpose
use in Emacs Lisp projects.

grizzl provides the underlying data structures and sesrch
algorithm without any UI attachment.  At the core, a fuzzy search
index is created from a list of strings, using `grizzl-make-index'.
A fuzzy search term is then used to get a result from this index
with `grizzl-search'.  Because grizzl considers the usage of a
fuzzy search index to operate in real-time as a user enters a
search term in the minibuffer, the framework optimizes for this use
case.  Any result can be passed back into `grizzl-search' as a hint
to continue searching.  The search algorithm is able to understand
insertions and deletions and therefore minimizes the work it needs
to do in this case.  The intended use here is to collect a result
on each key press and feed that result into the search for the next
key press. Once a search is complete, the matched strings are then
read, using `grizzl-result-strings'. The results are ordered on the
a combination of the Levenshtein Distance and a character-proximity
scoring calculation. This means shorter strings are favoured, but
adjacent letters are more heavily favoured.

It is assumed that the index will be re-used across multiple
searches on larger sets of data.

Call `grizzl-completing-read' with an index returned by
`grizzl-make-index':

   (defvar *index* (grizzl-make-index '("one" "two" "three")))
   (grizzl-completing-read "Number: " *index*)

When the user hits ENTER, either one of the strings is returned on
success, or nil of nothing matched.

The arrow keys can be used to navigate within the results.
