This gives a bunch of functions that handle running pytest on a
particular buffer or part of a buffer.  This started as a direct
port of nosemacs (https://bitbucket.org/durin42/nosemacs).  A
special thanks to Jason Pellerin and Augie Fackler for writing
nose.el.

; Installation

In your Emacs config:

  (require 'pytest)

If you don't use a global installation of py.test (ie in
virtualenv) then add something like the following that points to
either the non-global version or a test runner script.:

  (add-to-list 'pytest-project-names "my/crazy/runner")

You can generate a script with py.test:

  py.test --genscript=run-tests.py

Another option is if your global pytest isn't called "pytest" is to
redefine pytest-global-name to be the command that should be used.

By default, the root of a project is found by looking for any of the files
'setup.py', '.hg' and '.git'.  You can add files to check for to the file
list:

; (add-to-list 'pytest-project-root-files "something")

or you can change the project root test to detect in some other way
whether a directory is the project root:

; (setq pytest-project-root-test (lambda (dirname) (equal dirname "foo")))

Probably also want some keybindings:
(add-hook 'python-mode-hook
          (lambda ()
            (local-set-key "\C-ca" 'pytest-all)
            (local-set-key "\C-cm" 'pytest-module)
            (local-set-key "\C-c." 'pytest-one)
            (local-set-key "\C-cd" 'pytest-directory)
            (local-set-key "\C-cpa" 'pytest-pdb-all)
            (local-set-key "\C-cpm" 'pytest-pdb-module)
            (local-set-key "\C-cp." 'pytest-pdb-one)))
