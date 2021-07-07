Version: 3.0.0
Package-Requires: ((emacs "24"))
Keywords: convenience

When point is in an empty line then fill the line with a character
making it as long as the line above.

This program provides just command =underline-with-char=.

Examples
========

Notation: <!> means point.

Full underlining
................

Input:
^^^^^^

#+begin_src text
lala
<!>
#+end_src

Action:
^^^^^^^

#+begin_src text
M-x underline-with-char
#+end_src

Output:
^^^^^^^

#+begin_src text
lala
----<!>
#+end_src

Partial underlining
...................

Input:
^^^^^^

#+begin_src text
;; lolo
;; <!>
#+end_src

Action:
^^^^^^^

#+begin_src text
M-x underline-with-char
#+end_src

Output:
^^^^^^^

#+begin_src text
;; lolo
;; ----<!>
#+end_src

Use a certain char for current and subsequent underlinings
..........................................................

Input:
^^^^^^

#+begin_src text
lala
<!>
#+end_src

Action:
^^^^^^^

#+begin_src text
C-u M-x underline-with-char X
#+end_src

Output:
^^^^^^^

#+begin_src text
lala
XXXX<!>
#+end_src

Change the buffer.  Example:
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#+begin_src text
lala
XXXX

;; Worthy to be underlined
;; <!>
#+end_src

Go on without prefix argument (C-u):
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#+begin_src text
M-x underline-with-char X
#+end_src

Output:
^^^^^^^

#+begin_src text
lala
XXXX

;; Worthy to be underlined
;; XXXXXXXXXXXXXXXXXXXXXXX<!>
#+end_src
