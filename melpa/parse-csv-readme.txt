
Parse strings with CSV fields into s-expressions

This file implements `parse-csv->list' and `parse-csv-string'.

parse-csv-string is ported from Edward Marco Baringer's csv.lisp
http://common-lisp.net/project/bese/repos/arnesi_dev/src/csv.lisp
It was ported to Emacs Lisp by Matt Curtis.

(parse-csv->list "a,b,\"c,d\"")
    => ("a" "b" "c,d")

(parse-csv-string "a;b;'c;d'" ?\; ?\')
    => ("a" "b" "c;d")
