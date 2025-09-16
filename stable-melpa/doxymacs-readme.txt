Doxymacs provides a minor mode `doxymacs-mode' for GNU Emacs that provides
tighter integration with Doxygen, the multi-language documentation
generator.  It provides a number of features that make working with Doxygen
comments and documentation easier:

 - Lookup documentation for symbols from Emacs in the browser of your
   choice.
 - Easily insert Doxygen style comments into source code (C, C++, Javadoc,
   and Fortran are supported).
 - Fontify Doxygen keywords in comments.
 - Optionally use an “external” (i.e., written in C) XML parser to speed up
   building the completion list.

You can just enable `doxymacs-mode' and start using doxymacs.  To enable
doxymacs in C and C++, for example, you might add the following to your
Emacs initialization file:

(use-package doxymacs
  :hook (c-mode-common-hook . doxymacs-mode)
  :bind (:map c-mode-base-map
              ;; Lookup documentation for the symbol at point.
              ("C-c d ?" . doxymacs-lookup)
              ;; Rescan your Doxygen tags file.
              ("C-c d r" . doxymacs-rescan-tags)
              ;; Prompt you for a Doxygen command to enter, and its
              ;; arguments.
              ("C-c d RET" . doxymacs-insert-command)
              ;; Insert a Doxygen comment for the next function.
              ("C-c d f" . doxymacs-insert-function-comment)
              ;; Insert a Doxygen comment for the current file.
              ("C-c d i" . doxymacs-insert-file-comment)
              ;; Insert a Doxygen comment for the current member.
              ("C-c d ;" . doxymacs-insert-member-comment)
              ;; Insert a blank multi-line Doxygen comment.
              ("C-c d m" . doxymacs-insert-blank-multiline-comment)
              ;; Insert a blank single-line Doxygen comment.
              ("C-c d s" . doxymacs-insert-blank-singleline-comment)
              ;; Insert a grouping comments around the current region.
              ("C-c d @" . doxymacs-insert-grouping-comments))
  :custom
    ;; Configure source code <-> Doxygen tag file <-> Doxygen HTML
    ;; documentation mapping:
    ;;   - Files in /home/me/project/foo/ have their tag file at
    ;;     http://someplace.com/doc/foo/foo.xml, and HTML documentation
    ;;     at http://someplace.com/doc/foo/.
    ;;   - Files in /home/me/project/bar/ have their tag file at
    ;;     ~/project/bar/doc/bar.xml, and HTML documentation at
    ;;     file:///home/me/project/bar/doc/.
    ;; This must be configured for Doxymacs to function!
    (doxymacs-doxygen-dirs
     '(("^/home/me/project/foo/"
        "http://someplace.com/doc/foo/foo.xml"
         "http://someplace.com/doc/foo/")
       ("^/home/me/project/bar/"
        "~/project/bar/doc/bar.xml"
        "file:///home/me/project/bar/doc/"))))

Doxymacs comes with an external parser for Doxygen tags files written in C.
If your tags file is quite large, you may find the external parser to be
more performant.  The external parser depends on the following packages:

  - autotools: https://www.gnu.org/software/autoconf/
  - pkg-config: https://www.freedesktop.org/wiki/Software/pkg-config/
  - libxml2: http://www.libxml.org/

Be sure these are properly configured and installed before proceeding.

  - Set `doxymacs-use-external-xml-parser' to `t' and be sure to set
    `doxymacs-external-xml-parser-executable' to where you would like the
    external XML parser to be installed.

  - Run the command `doxymacs-install-external-parser'.
