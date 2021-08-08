#+STARTUP: content
* geiser-kawa-java
** Project description

geiser-kawa-java is the emacs side of a geiser-kawa implementation that uses [[https://gitlab.com/spellcard199/kawa-geiser][kawa-geiser]] for its Kawa side.

** Project status

Work in progress.

** Difference from [[https://gitlab.com/spellcard199/geiser-kawa-scheme][geiser-kawa-scheme]]

- The Kawa side of geiser-kawa-java uses [[https://gitlab.com/spellcard199/kawa-geiser][kawa-geiser]], which is written using Kawa's Java API.
- The Kawa side of geiser-kawa-scheme is written directly in Kawa Scheme.
- I'm going to add more features to geiser-kawa-java but I probably won't port them to geiser-kawa-scheme.

geiser-kawa-java VS geiser-kawa-scheme - recap table:

|                                | geiser-kawa-java | geiser-kawa-scheme |
|--------------------------------+------------------+--------------------|
| Kawa side written with         | Kawa's Java API  | Kawa Scheme        |
| I'm going to add more features | Probably yes     | Probably not       |
