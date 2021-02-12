
Automagical annotation of lisp values like Ruby's xmpfilter. For
example, executing M-x lispxmp on the following buffer:

====
1 ; =>
(+ 3 4) ; =>
(dotimes (i 3)
  (* i 4)  ; =>
)
====

produces

====
1 ; => 1
(+ 3 4) ; => 7
(dotimes (i 3)
  (* i 4) ; => 0, 4, 8
)
====
