This file implements extensions for outline(-minor)-mode.

- VISIBILITY CYCLING: A *single* command to replace the many
  outline commands for showing and hiding parts of a document.

- STRUCTURE EDITING: Promotion, demotion and transposition of subtrees.

Installation
============

Byte-compile outline-magic.el, put it on the load path and copy the
following into .emacs (adapting keybindings to your own preferences)

(add-hook 'outline-mode-hook
          (lambda ()
            (require 'outline-cycle)))

(add-hook 'outline-minor-mode-hook
          (lambda ()
            (require 'outline-magic)
            (define-key outline-minor-mode-map [(f10)] 'outline-cycle)))

Usage
=====

Visibility cycling
------------------

The command `outline-cycle' changes the visibility of text and headings
in the buffer.  Instead of using many different commands to show and
hide buffer parts, `outline-cycle' cycles through the most important
states of an outline buffer.  In the major `outline-mode', it will be
bound to the TAB key.  In `outline-minor-mode', the user can choose a
different keybinding.  The action of the command depends on the current
cursor location:

1. When point is at the beginning of the buffer, `outline-cycle'
   cycles the entire buffer through 3 different states:
     - OVERVIEW: Only top-level headlines are shown.
     - CONTENTS: All headlines are shown, but no body text.
     - SHOW ALL: Everything is shown.

2. When point in a headline, `outline-cycle' cycles the subtree started
   by this line through the following states:
     - FOLDED:   Only the headline is shown.
     - CHILDREN: The headline and its direct children are shown.  From
                 this state, you can move to one of the children and
                 zoom in further.
     - SUBTREE:  The entire subtree under the heading is shown.

3. At other positions, `outline-cycle' jumps back to the current heading.
   It can also be configured to emulate TAB at those positions, see
   the option `outline-cycle-emulate-tab'.

Structure editing
-----------------

Four commands are provided for structure editing.  The commands work on
the current subtree (the current headline plus all inferior ones). In
addition to menu access, the commands are assigned to the four arrow
keys pressed with a modifier (META by default) in the following way:

                                move up
                                   ^
                       promote  <- | ->  demote
                                   v
                               move down

Thus, M-left will promote a subtree, M-up will move it up
vertically throught the structure.  Configure the variable
`outline-structedit-modifiers' to use different modifier keys.

Moving subtrees
- - - - - - - -
The commands `outline-move-subtree-up' and `outline-move-subtree-down'
move the entire current subtree (folded or not) past the next same-level
heading in the given direction.  The cursor moves with the subtree, so
these commands can be used to "drag" a subtree to the wanted position.
For example, `outline-move-subtree-down' applied with the cursor at the
beginning of the "* Level 1b" line will change the tree like this:

  * Level 1a                         * Level 1a
  * Level 1b         ===\            * Level 1c
  ** Level 2b        ===/            * Level 1b
  * Level 1c                         ** Level 2b

Promotion/Demotion
- - - - - - - - - -
The commands `outline-promote' and `outline-demote' change the current
subtree to a different outline level - i.e. the level of all headings in
the tree is decreased or increased.  For example, `outline-demote'
applied with the cursor at the beginning of the "* Level 1b" line will
change the tree like this:

  * Level 1a                         * Level 1a
  * Level 1b         ===\            ** Level 1b
  ** Level 2b        ===/            *** Level 2
  * Level 1c                         * Level 1c

The reverse operation is `outline-promote'.  Note that the scope of
"current subtree" may be changed after a promotion.  To change all
headlines in a region, use transient-mark-mode and apply the command to
the region.

NOTE: Promotion/Demotion in complex outline setups
- - - - - - - - - - - - - - - - - - - - - - - - - -
Promotion/demotion works easily in a simple outline setup where the
indicator of headings is just a polymer of a single character (e.g. "*"
in the default outline mode).  It can also work in more complicated
setups.  For example, in LaTeX-mode, sections can be promoted to
chapters and vice versa.  However, the outline setup for the mode must
meet two requirements:

1. `outline-regexp' must match the full text which has to be changed
   during promotion/demotion.  E.g. for LaTeX, it must match "\chapter"
   and not just "\chap".  Major modes like latex-mode, AUCTeX's
   latex-mode and texinfo-mode do this correctly.

2. The variable `outline-promotion-headings' must contain a sorted list
   of headings as matched by `outline-regexp'.  Each of the headings in
   `outline-promotion-headings' must be matched by `outline-regexp'.
   `outline-regexp' may match additional things - those matches will be
   ignored by the promotion commands.  If a mode has multiple sets of
   sectioning commands (for example the texinfo-mode with
   chapter...subsubsection and unnumbered...unnumberedsubsubsec), the
   different sets can all be listed in the same list, but must be
   separated by nil elements to avoid "promotion" accross sets.
   Examples:

   (add-hook 'latex-mode-hook      ; or 'LaTeX-mode-hook for AUCTeX
    (lambda ()
      (setq outline-promotion-headings
            '("\\chapter" "\\section" "\\subsection"
              "\\subsubsection" "\\paragraph" "\\subparagraph"))))

   (add-hook 'texinfo-mode-hook
    (lambda ()
     (setq outline-promotion-headings
      '("@chapter" "@section" "@subsection" "@subsubsection" nil
        "@unnumbered" "@unnumberedsec" "@unnumberedsubsec"
                                      "@unnumberedsubsubsec" nil
        "@appendix" "@appendixsec" "@appendixsubsec"
                                        "@appendixsubsubsec" nil
        "@chapheading" "@heading" "@subheading" "@subsubheading"))))

   If people find this useful enough, maybe the maintainers of the
   modes can be persuaded to set `outline-promotion-headings'
   already as part of the mode setup.

 Compatibility:
 --------------
 outline-magic was developed to work with the new outline.el
 implementation which uses text properties instead of selective display.
 If you are using XEmacs which still has the old implementation, most
 commands will work fine.  However, structure editing commands will
 require all relevant headlines to be visible.
