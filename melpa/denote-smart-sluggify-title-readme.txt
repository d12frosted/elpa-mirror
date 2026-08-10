This package improves title sluggification to save on filename
length.  This is done through one primary function: stopword
removal, otherwise, the behavior is similar to the standard
approach.  Title sluggification is performed as follows.

1. The title is filtered using
   `denote-smart-sluggify-title-pre-filter', which is intended to
   be advised with both `:filter-args' and `:filter-return' advice.
2. Non-word symbols are removed, based on
   `denote-smart-sluggify-title-symbols-regexp'.
3. Stopwords listed in `denote-smart-sluggify-title-stopwords' are
   then removed.
4. The name is hyphenated using `denote-slug-hyphenate'.
5. The name is further filtered/modified using
   `denote-smart-sluggify-title-post-filter', similar to
   `denote-smart-sluggify-title-pre-filter'.
6. Finally, the case is converted based on
   `denote-smart-sluggify-title-downcase'.  The default behavior is
   to downcase titles.

This behavior may be enabled through the use of the function
`denote-smart-sluggify-title-insinuate'.
