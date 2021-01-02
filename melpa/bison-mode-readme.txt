;; I wrote this since I saw one mode for yacc files out there roaming the
;; world.     I was daunted by the fact the it was written in 1990, and Emacs
;; has evolved so much since then (this I assume based on its evolution since
;; i started using it).     So I figured if i wanted one, I should make it
;; myself.     Please excuse idiosyncrasies, as this was my first major mode
;; of this kind.     The indentation code may be a bit weird, I am not sure,
;; it was my first go at doing Emacs indentation, so I look at how other
;; modes did it, but then basically did what I thought was right

;; I hope this is useful to other hackers, and happy Bison/Yacc hacking
;; If you have ideas/suggestions/problems with this code, I can be reached at
;; beuscher@eecs.tulane.edu

;; Eric --- Sat Mar  7 1:40:20 CDT 1998

;; Bison Sections:
;; there are five sections to a bison file (if you include the area above the
;; C declarations section.     most everything in this file either does
;; actions based on which section you are deemed to be in, or based on an
;; assumption that the function will only be called from certain sections.
;; the function `bison--section-p' is the section parser

;; Indentation:
;; indentations are done based on the section of code you are in.    there is
;; a procedure `bison--within-braced-c-expression-p' that checks for being in
;; C code.    if you are within c-code, indentations should occur based on
;; how you have your C indentation set up.     i am pretty sure this is the
;; case.
;; there are four variables, which control bison indentation within either
;; the bison declarations section or the bison grammar section
;; `bison-rule-separator-column'
;; `bison-rule-separator-column'
;; `bison-decl-type-column'
;; `bison-decl-token-column'

;; flaw: indentation works on a per-line basis, unless within braced C sexp,
;; i should fix this someday
;; and to make matters worse, i never took out c-indent-region, so that is
;; still the state of the `indent-region-function' variable

;; Electricity:
;; by default, there are electric -colon, -pipe, -open-brace, -close-brace,
;; -semicolon, -percent, -less-than, -greater-than
;; the indentation caused by these work closely with the 4 indentation
;; variables mentioned above.
;; any of these can be turned off individually by setting the appropriate
;; `bison-electric-...' variable.     or all of them can be turned off by
;; setting `bison-all-electricity-off'

;; todo:  should make available a way to use C-electricity if in C sexps
