Generate random words using user-provided rules.

Example:
(wordgen
 '((result (concat-reeval [(2 1) (5 2) (4 3)] syl))
   (syl (++ c v coda))
   (c [(4 "p") (5 "t") (5 "k") (3 "m") (4 "n") (3 "s") (4 "l") (3 "r")])
   (v ["a" "e" "i" "o" "u"])
   (coda [(4 "") "m" "n"]))
 :word-count 5)

=> ("komlamkim" "kepa" "mennem" "ne" "palu")

See the function `wordgen' for complete description.
