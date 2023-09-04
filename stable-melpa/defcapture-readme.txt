This is a simple convenience macro for defining org capture templates.
It uses the Doct DSL for declarations. It has a dedicated namespace
for capture templates and provides convenient functions to manage
capture templates.

Example of usage:

(defcapture parent () "Parent Capture"
 :keys "p"
 :file "~/example.org"
 :prepend t
 :template ("* %{todo-state} %^{Description}"
            ":PROPERTIES:"
            ":Created: %U"
            ":END:"
            "%?"))

(defcapture childa (parent) "First Child"
  :keys "a"
  :headline "One"
  :todo-state "TODO"
  :hook (lambda () (message "\" First Child\" selected.")))

(defcapture childb (parent) "Second Child"
  :keys "b"
  :headline "Two"
  :todo-state "NEXT")

(defcapture childc (parent) "Third Child"
  :keys "c"
  :headline "Three"
  :todo-state "MAYBE")
