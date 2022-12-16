orgstrap is a specification and tooling for bootstrapping Org files.

It allows Org files to describe their own requirements, and
define their own functionality, making them self-contained,
standalone computational artifacts, dependent only on Emacs,
or other implementations of the Org-babel protocol in the future.

orgstrap.el is an elisp implementation of the orgstrap conventions.
It defines a regional minor mode for `org-mode' that runs orgstrap
blocks.  It also provides `orgstrap-init' and `orgstrap-edit-mode'
to simplify authoring of orgstrapped files.  For more details see
README.org which is also the literate source for this orgstrap.el
file in the git repo at
https://github.com/tgbugs/orgstrap/blob/master/README.org
or wherever you can find git:c1b28526ef9931654b72dff559da2205feb87f75

Code in an orgstrap block is usually meant to be executed directly by its
containing Org file.  However, if the code is something that will be reused
over time outside the defining Org file, then it may be better to tangle and
load the file so that it is easier to debug/xref functions.  The code in
this orgstrap.el file in particular is tangled for inclusion in one of the
*elpas so as to protect the orgstrap namespace and to make it eaiser to
use orgstrap in Emacs.

The license for the orgstrap.el code reflects the fact that the
code for expanding and hashing blocks reuses code from ob-core.el,
which at the time of writing is licensed as part of Emacs.
