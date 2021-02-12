To use, type `M-x helm-notmuch'.  `helm-notmuch' only starts to search when
length of your input is no less than 2.

News:
- 2019-03-20 v1.2 Improve incomplete word matching and turn on by default.
  Fix bugs with -show-search and incomplete special queries.
  Allow displaying multiple buffers and add action to display in other window.
- 2017-09-04 v1.1 Fix a regexp bug and use `notmuch-command' instead of hardcoding "notmuch".
- 2016-11-28 v1.0 Add two user options: `helm-notmuch-max-matches' and `helm-notmuch-match-incomplete-words'.
