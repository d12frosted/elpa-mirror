                            _______________

                             ORG2ELCOMMENT

                              Junpeng Qiu
                            _______________


Table of Contents
_________________

1 Overview
2 Usage
.. 2.1 Command `org2elcomment'
.. 2.2 Command `org2elcomment-anywhere'
3 Customization
.. 3.1 Org Export Backend
.. 3.2 Exporter Function


Convert `org-mode' file to Elisp comments.


1 Overview
==========

  This simple package is mainly used for Elisp package writers.  After
  you've written the `README.org' for your package, you can use
  `org2elcomment' to convert the org file to Elisp comments in the
  corresponding source code file.


2 Usage
=======

  Make sure your source code file has `;;; Commentary:' and `;;; Code:'
  lines.  The generated comments will be put between these two lines.
  If you use `auto-insert', it will take care of generating a standard
  file header that contains these two lines in your source code.


2.1 Command `org2elcomment'
~~~~~~~~~~~~~~~~~~~~~~~~~~~

  In your Org file, invoke `org2elcomment', select the source code file,
  and done! Now take a look at your source code file, you can see your
  Org file has been converted to the comments in your source code file.


2.2 Command `org2elcomment-anywhere'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  You can invoke this command anywhere in Emacs.  It requires two
  parameters.  You need to select the source code file as well as the
  org file.  After selecting the org file, you can optionally save the
  org file location as the file-local variable in the source code file
  so that you don't need to select the org file again for the same
  source code file.

  If you want to automate the process of converting the org to the
  commentary section in Elisp file in your project, you can consider
  using this command.


3 Customization
===============

3.1 Org Export Backend
~~~~~~~~~~~~~~~~~~~~~~

  Behind the scenes, this package uses `org-export-as' function and the
  default backend is `ascii'.  You can change to whatever backend that
  your org-mode export engine supports, such as `md' (for markdown):

  ,----
  | (setq org2elcomment-backend 'md)
  `----


3.2 Exporter Function
~~~~~~~~~~~~~~~~~~~~~

  In fact, it is even possible to use your own export function instead
  of the exporter of org-mode.  Write a function which accepts a file
  name of an org file and returns the string as the export result.  Here
  is how the default exporter that we use in this package looks like:

  ,----
  | (defun org2elcomment-default-exporter (org-file)
  |   (with-temp-buffer
  |     (insert-file-contents org-file)
  |     (org-export-as org2elcomment-backend)))
  `----

  After defining your own export function, say, `my-exporter', change
  the value of `org2elcomment-exporter':

  ,----
  | (setq org2elcomment-exporter 'my-exporter)
  `----
