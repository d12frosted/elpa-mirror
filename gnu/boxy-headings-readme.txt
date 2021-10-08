#+TITLE: Boxy Headings

View org files as a boxy diagram.

=package-install RET boxy-headings RET=

* Usage
** =boxy-headings=

   To view all headings in an org-mode file as a boxy diagram, use
   the interactive function =boxy-headings=

   Suggested keybinding:
   #+begin_src emacs-lisp
     (define-key org-mode-map (kbd "C-c r o") 'boxy-headings)
   #+end_src

   To modify the relationship between a headline and its parent, add
   the property REL to the child headline. Valid values are:
   - on top of
   - in front of
   - behind
   - above
   - below
   - to the right of
   - to the left of

   The tooltip for each headline shows the values that would be
   displayed if the org file was in org columns view.

   [[file:demo/headings.gif]]
* License
  GPLv3
* Development

** Setup

   Install [[https://github.com/doublep/eldev#installation][eldev]]

** Commands:
*** =eldev lint=
    Lint the =boxy-headings.el= file
*** =eldev compile=
    Test whether ELC has any complaints
*** =eldev package=
    Creates a dist folder with =boxy-headings-<version>.el=
*** =eldev md5=
    Creates an md5 checksum against all files in the dist folder.
