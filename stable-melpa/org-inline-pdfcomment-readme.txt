This package provides support for exporting org-inlinetask elements
as PDF comments using the pdfcomment.sty package for LaTeX
(https://ctan.org/pkg/pdfcomment).  It may be enabled as follows:

    (require 'org-inline-pdfcomment)
    (org-inline-pdfcomment-insinuate)

Inline tasks will then be exported as PDF comments.

**NOTE**: Loading this packages will load `org-inlinetask' if it is
not loaded.

;; Output Customization

 - `org-inline-pdfcomment-type' can be either of the symbols
   `inline' or `margin', or a string which will be used as the
   comment command.
 - `org-inline-pdfcomment-options' is an alist of pdfcomment
   options.  For more information about these, see the docstring or
   the pdfcomment.sty manual.
 - `org-inline-pdfcomment-format-todo-function' is a function used
   to format the todo state.
 - `org-inline-pdfcomment-format-tags-function' is a function used
   to format the task tags.
