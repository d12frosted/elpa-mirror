#+TITLE: Boxy Headlines

View org files as a boxy diagram.

=package-install RET boxy-headlines RET=

* Usage
** =boxy-headlines=

   To view all headlines in an org-mode file as a boxy diagram, use
   the interactive function =boxy-headlines=

   Suggested keybinding:
   #+begin_src emacs-lisp
     (define-key org-mode-map (kbd "C-c r o") 'boxy-headlines)
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

   [[file:demo/headlines.gif]]
* License
  GPLv3
* Development

** Setup

   Install [[https://github.com/doublep/eldev#installation][eldev]]

** Commands:
*** =eldev lint=
    Lint the =boxy-headlines.el= file
*** =eldev compile=
    Test whether ELC has any complaints
*** =eldev package=
    Creates a dist folder with =boxy-headlines-<version>.el=
*** =eldev md5=
    Creates an md5 checksum against all files in the dist folder.
