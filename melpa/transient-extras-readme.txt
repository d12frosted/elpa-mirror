This package provides a number of additional transient infixes and switches.

In particular, the following are defined:

 - `transient-extras-file-list-or-buffer' a defined argument that
   can be used in a transient.  It contains either the current
   buffer, the name of the current file, or the names of the files
   currently marked in `dired'.

 - The class `transient-extras-exclusive-switch', which allows for
   command line switches with defined options to be cycled through.
   This is similar to `transient-switches', but the `choices' slot
   is a list of cons cells, `(value . label)', with label used for
   display.  Ex:
     (transient-define-argument lp-transient--orientation ()
       :description "Print Orientation"
       :class 'transient-extras-exclusive-switch
       :key "o"
       :argument-format "-oorientation-requested=%s"
       :argument-regexp "\\(-oorientation-requested=\\(4\\|5\\|6\\)\\)"
       :choices '(("4" . "90°(landscape)")
                  ("5" . "-90°")
                  ("6" . "180°")))

- The class `transient-extras-option-dynamic-choices' allows for
  the options for option values to be determined dynamically.  This
  is particularly useful for programs which are configurable for
  what the values are, or may need more complex logic to determine
  them at run time.  It does so through the use of a
  `choices-function', as shown below.
  (transient-define-argument transient-extras-a2ps-printer ()
     :class 'transient-extras-option-dynamic-choices
     :description "Printer"
     :key "P"
     :argument "-P"
     :choices-function (transient-extras-make-command-filter-function
                        "a2ps" '("--list=printers")
                        (lambda (line)
                          (when (and (string-match-p "^-" line)
                                     (not (string-match-p "Default" line))
                                     (not (string-match-p "Unknown" line)))
                            (substring line 2))))
     :prompt "Printer? ")
   To simplify this, two additional functions are provided:
   `transient-extras-make-command-filter-function' and
   `transient-extras-filter-command-output'.  The first takes three
   arguments, a program to run, a list of argument to pass to it,
   and a function to filter lines, with nils removed; it then
   returns a closure which calls the second.
