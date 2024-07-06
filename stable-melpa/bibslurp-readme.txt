Provides a function `bibslurp-query-ads', which reads a search
string from the minibuffer, sends the query to NASA ADS
(http://adswww.harvard.edu/), and displays the results in a new
buffer called "ADS Search Results".

The "ADS Search Results" buffer opens in `bibslurp-mode', which
provides a few handy functions.  Typing the number preceding an
abstract and hitting RET calls `bibslurp-slurp-bibtex', which
fetches the bibtex entry corresponding to the abstract and saves it
to the kill ring.  Typing 'a' instead pulls up the abstract page.
At anytime, you can hit 'q' to quit bibslurp-mode and restore the
previous window configuration.
