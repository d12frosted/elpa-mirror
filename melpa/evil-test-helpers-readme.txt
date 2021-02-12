This file contains helper functions for writing tests for
evil-mode.  These helpers can also be used by other packages which
extend evil-mode.

To write a test use `evil-test-buffer':

    (require 'evil-test-helpers)

    (ert-deftest evil-test ()
      :tags '(evil)
      (evil-test-buffer
       "[T]his creates a test buffer." ; cursor on "T"
       ("w")                           ; key sequence
       "This [c]reates a test buffer."))) ; cursor moved to "c"

The initial state, the cursor syntax, etc., can be changed
with keyword arguments.  See the documentation string of
`evil-test-buffer' for more details.

This file is NOT part of Evil itself.
