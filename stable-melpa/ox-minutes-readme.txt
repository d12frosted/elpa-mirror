The aim of this exporter to generate meeting minutes plain text that is
convenient to send via email.
 - Unnecessary blank lines are removed from the final exported plain text.
 - Header decoration and section numbers done in the default ASCII exports
   is prevented.
 - Also TOC and author name are not exported.

This is an ox-ascii derived backed for org exports.

This backend effectively sets the `org-export-headline-levels' to 0 and,
`org-export-with-section-numbers', `org-export-with-author' and
`org-export-with-toc' to nil time being for the exports.  That is equivalent
to manually putting the below in the org file:

    #+options: H:0 num:nil author:nil toc:nil

This package has been tested to work with the latest version of org built
from the master branch ( http://orgmode.org/cgit.cgi/org-mode.git ) as of
Aug 10 2016.

EXAMPLE ORG FILE:

    #+title: My notes

    * Heading 1
    ** Sub heading
    *** More nesting
    - List item 1
    - List item 2
    - List item 3
    * Heading 2
    ** Sub heading
    - List item 1
    - List item 2
    - List item 3
    *** More nesting

MINUTES EXPORT:

                                   __________

                                    MY NOTES
                                   __________

    * Heading 1
      + Sub heading
        - More nesting
          - List item 1
          - List item 2
          - List item 3

    * Heading 2
      + Sub heading
        - List item 1
        - List item 2
        - List item 3
        - More nesting

REQUIREMENTS:

- Emacs 24 is required at minimum for lexical binding support.
- Emacs 24.4 is required as ox-ascii got added to org-mode in that Emacs
  release.
