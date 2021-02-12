This is an Emacs interface to the Stack Haskell development tool.  Bind
the following useful commands:

    (global-set-key (kbd "<next> h e") #'hasky-stack-execute)
    (global-set-key (kbd "<next> h h") #'hasky-stack-package-action)
    (global-set-key (kbd "<next> h i") #'hasky-stack-new)

* `hasky-stack-execute' opens a popup with a collection of stack commands
  you can run.  Many commands have their own sub-popups like in Magit.

* `hasky-stack-package-action' allows to perform actions on package that
  the user selects from the list of all available packages.

* `hasky-stack-new' allows to create a new project in current directory
  using a Stack template.
