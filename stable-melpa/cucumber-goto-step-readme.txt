
cucumber-goto-step.el is a simple helper package that navigates
from a step in a feature file to the step definition.  While this
functionality exists in cucumber.el is requires external tools.
This package allows the user to go directly to the step definition
without the use of any external tools.  It does this by finding the
project root then searching "/features/**/*_steps.rb" for
potentially matching candidates.  It relies on pcre2el to convert
perl style regular expressions to Emacs regular expressions.

The easiest way to install cucumber-goto-step.el is to use a package
manager.  To install it manually simply add it to your load path
then require it.

    (add-to-list 'load-path "/path/to/ack-and-a-half")
    (require 'ack-and-a-half)

Once installed cucumber-goto-step can be invoked using:

    M-x jump-to-cucumber-step

There are a few variables you may wish to customize depending on
your environment.  To do this enter:

    M-x customize-group cucumber-goto-step

These variables include:
- cgs-root-markers: a list of files/directories that are found
  at the root of your project.
- cgs-step-search-path: a file global that cucumber-goto-step
  will search for step files.  This defaults to "/features/**/*_steps.rb".
- cgs-find-project-functions: a list of functions used to locate the
  project root.  A default function is provided however you may
  optionally override this is you have any special requirements.
