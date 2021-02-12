
Usage: call
  M-x bibretrieve
Enter (part of) the author's name and/or title.
Matching BibTeX entries are fetched using the configured backends
and displayed in a selection buffer.
The entries can then be appended to the bibliography file
or inserted into the current buffer.

Configuration:
To select which backends to use customize the variable "bibretrieve-backends".
To select a backend for a single invocation call the function with
  C-u M-x bibretrieve

Extension:
To create a new backend define a new function
"bibretrieve-backend-NAME" that takes as input author and title
and returns a buffer that contains bibtex entries.
The function should be defined in "bibretrieve-base.el".
It is then necessary to advise bibretrieve of the new backend,
adding NAME to the list "bibretrieve-installed-backends".

The url is retrieved via mm-url.  You may want to customize the
variable mm-url-use-external and mm-url-program.

Acknowledgments: This program has been inspired by bibsnarf.  The
functions that create the urls for most backends are taken from
there.  This program uses the library mm-url.  This programs also uses
lot of function of RefTeX.  The selection process is entirely based on
reftex-sel.  Many functions have also been adapted from there.
