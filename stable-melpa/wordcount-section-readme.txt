
Word count information for a buffer can be shown using
`wordcount-section'.  Basic installation is as follows.

    (add-to-list 'universal-sidecar-sections #'wordcount-section)

The wordcount display can be customized in three ways:

 - The `:header' keyword argument can be used to change the section
   header.
 - The format of word count information is controlled by the
   variable `wordcount-section-format', which supports the
   following percent escapes:
   | %w | Word Count      |
   | %s | Sentence Count  |
   | %l | Line Count      |
   | %c | Character Count |
 - The `wordcount-section-modes' variable controls the modes that
   have wordcounts shown.  This list is passed to `derived-mode-p'
   in the target buffer.
