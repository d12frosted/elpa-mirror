#+TITLE: Org Real

Keep track of real things as org-mode links.

=package-install RET org-real RET=

* Usage
** Inserting a link
   To create a real link in org-mode, use =C-c C-l real RET=.

   Real links are created inside-out, starting with the most specific
   item and working to the most general.

   #+begin_example

       ┌──────────────────────────────┐
       │                              │
       │           outside            │
       │              ↑               │
       │  ┌────────── ↑ ───────────┐  │
       │  │           ↑            │  │
       │  │           ↑            │  │
       │  │           ↑            │  │
       │  │  ┌─────── ↑ ────────┐  │  │
       │  │  │        ↑         │  │  │
       │  │  │      inside      │  │  │
       │  │  │                  │  │  │
       │  │  └──────────────────┘  │  │
       │  │                        │  │
       │  └────────────────────────┘  │
       │                              │
       └──────────────────────────────┘

   #+end_example

   The first prompt will be for the thing which is trying to be linked
   to, called the "primary thing". Then, the prompt will continue to
   ask if more context should be added by pressing =+= until the user
   confirms the link with =RET=.

   [[file:demo/insert-link.gif]]

** Inserting a link with completion

   Org real will help create links by parsing all existing links in
   the current buffer. When choosing an existing thing, all of the
   context for that thing is automatically added to the current
   completion.

   This is only possible because of the unique inside-out completion
   style for inserting a link and makes it very easy to add new things
   to an existing container.

   [[file:demo/insert-link-with-completion.gif]]

** Rearranging things

   In order to edit a real link, place the cursor on the link and
   press =C-c C-l=. Narrow the link down beyond the context you wish
   to change by pressing =BACKSPACE= repeatedly, then =+= to add the
   new context.

   [[file:demo/edit-link.gif]]

   If any container in the new link does not match an existing
   container in the buffer, org-real will prompt you to replace all
   occurences of that thing with the new context and relationships.

   This makes it easy to keep things in sync. If any one link changes
   location, all links in the currnet buffer are updated accordingly.

   [[file:demo/apply-changes.gif]]

   If a link is changed manually, use the interactive function
   =org-real-apply= with the cursor on top of the new link to apply
   changes from that link to the buffer.

** Opening links
   To open a real link, place the cursor within the link and press
   =C-c C-o=. This will display a popup buffer in Org Real mode
   showing the location of the link.

** =org-real-world=

   To view all real links in the current buffer in a combined diagram,
   use the interactive function =org-real-world=

   Suggested keybinding:
   #+begin_src emacs-lisp
     (define-key org-mode-map (kbd "C-c r w") 'org-real-world)
   #+end_src

** Boxy mode

   Once in boxy mode, you can cycle the visibility level of all
   children with =S-TAB= or use =TAB= to toggle the visibility of
   children for a single box.

   Emacs movement keys will navigate by boxes rather than
   characters. Each box in the diagram has these keybindings:

   - =RET / mouse-1= Jump to first occurrence of link
   - =o= Cycle occurrences of links in other window
   - =M-RET= Open all occurences of links by splitting the current window
   - =r= Jump to the box directly related to the current box
   - =TAB= expand/collapse children boxes

   [[file:demo/boxy-mode.gif]]

* License
  GPLv3
* Development

** Setup

   Install [[https://github.com/doublep/eldev#installation][eldev]]

** Commands:
*** =eldev lint=
    Lint the =org-real.el= file
*** =eldev compile=
    Test whether ELC has any complaints
*** =eldev test=
    Run all test files in =tests/=
*** =eldev package=
    Creates a dist folder with =org-real-<version>.el=
*** =eldev md5=
    Creates an md5 checksum against all files in the dist folder.
