ROCKTAKEY


Table of Contents
_________________

1 Usage
2 Variable
.. 2.1 ido-flex-with-migemo-excluded-func-list


1 Usage
=======

  If you turn on "ido-flex-with-migemo-mode," you can use ido with both
  flex and migemo.


2 Variable
==========

2.1 ido-flex-with-migemo-excluded-func-list
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  This is list of function you don't want to use ido-flex-with-migemo in.
  Here's an example:

  ,----
  | 1  (require 'smex)      ;;you have to install "smex" if you use this example
  | 2  (add-to-list 'ido-flex-with-migemo-excluded-func-list '(smex))
  `----
