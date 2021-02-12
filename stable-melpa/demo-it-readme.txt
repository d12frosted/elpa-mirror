
  When making demonstrations of new products, technologies and other
  geekery, I love the versatility of using Emacs to demonstrate the
  trifecta of sprint reviews, including:

  - Presentations explaining the technologies
  - Source code ... correctly highlighted
  - Executing the code in Eshell ... or similar demonstration
  - Test a new feature

  However, I don't want to fat-finger, mentally burp, or even delay
  the gratification while I type, so I predefine each "step" as an
  Elisp function or keyboard macro, and then have =demo-it= execute
  each function when I hit either the SPACE key or the F12 key
  (advanced minor mode).

  Using the library is a four step process:

  1. Load the library in your own Elisp source code file
  2. Create a collection of functions that "do things".
  3. Create the ordered list of functions/steps with `demo-it-create'
  4. Start the demonstration with `demo-it-start'

  For instance:

      (require 'demo-it)   ;; Load this library of functions

      (defun dit-load-source-code ()
        "Load some source code in a side window."
        (demo-it-presentation-advance)
        (demo-it-load-fancy-file "example.py" :line 5 12 :side))

      (defun dit-run-code ()
        "Execute our source code in an Eshell buffer."
        ;; Close other windows and advance the presentation:
        (demo-it-presentation-return)
        (demo-it-start-shell)
        (demo-it-run-in-shell "python example.py Snoopy"))

      (demo-it-create :single-window :insert-slow :full-screen
                      (demo-it-title-screen "example-title.org")
                      (demo-it-presentation "example.org")
                       dit-load-source-code
                       dit-run-code
                      (demo-it-run-in-shell "exit" nil :instant))

      (demo-it-start)

  Each "step" is a series of Elisp functions that "do things".
  While this package has a collection of helping functions, the steps
  can use any Elisp command to show off a feature.

  I recommend installing these other Emacs packages:

  - https://github.com/takaxp/org-tree-slide
  - https://github.com/sabof/org-bullets
  - https://github.com/magnars/expand-region.el
  - https://github.com/Bruce-Connor/fancy-narrow

  See http://github.com/howardabrams/demo-it for more details and
  better examples.  You will want to walk through the source code
  for all the utility functions.
