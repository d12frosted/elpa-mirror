This package makes it easy to have one or more customizable tables of contents in Org files.
They can be updated manually, or automatically when the file is saved.  Links to headings are
created compatible with GitHub's Org renderer.

;; Installation

Install the packages `dash' and `s'.  Then put this file in your `load-path', and put this in
your init file:

  (require 'org-make-toc)

;; Usage

A document may have any number of tables of contents (TOCs), each of
which may list entries in a highly configurable way.  To make a basic
TOC, follow these steps:

1.  Choose a heading to contain a TOC and go to it.
2.  Press `C-c C-x p' (`org-set-property'), add a `TOC' property, and
    set its value to `:include all'.
3.  Run command `org-make-toc-insert' to insert the `:CONTENTS:' drawer,
    which will contain the TOC entries.
4.  Run the command `org-make-toc' to update all TOCs in the document,
    or `org-make-toc-at-point' to update the TOC for the entry at point.


Example
═══════

  Here's a simple document containing a simple TOC:

  ┌────
  │ * Heading
  │ :PROPERTIES:
  │ :TOC:      :include all
  │ :END:
  │
  │ This text appears before the TOC.
  │
  │ :CONTENTS:
  │ - [[#heading][Heading]]
  │   - [[#subheading][Subheading]]
  │ :END:
  │
  │ This text appears after it.
  │
  │ ** Subheading
  └────


Advanced
════════

  The `:TOC:' property is a property list which may set these keys and
  values.

  These keys accept one setting, like `:include all':

  ⁃ `:include' Which headings to include in the TOC.
    • `all' Include all headings in the document.
    • `descendants' Include the TOC's descendant headings.
    • `siblings' Include the TOC's sibling headings.
  ⁃ `:depth' A number >= 0 indicating a depth relative to this heading.
    Descendant headings at or above this relative depth are included in
    TOCs that include this heading.

  These keys accept either one setting or a list of settings, like
  `:force depth' or `:force (depth ignore)':

  ⁃ `:force' Heading-local settings to override when generating the TOC
    at this heading.
    • `depth' Override `:depth' settings.
    • `ignore' Override `:ignore' settings.
  ⁃ `:ignore' Which headings, relative to this heading, to exclude from
    TOCs.
    • `descendants' Exclude descendants of this heading.
    • `siblings' Exclude siblings of this heading.
    • `this' Exclude this heading (not its siblings or descendants).
  ⁃ `:local' Heading-local settings to ignore when generating TOCs at
    higher levels.
    • `depth' Ignore `:depth' settings.

  See [example.org] for a comprehensive example of the features
  described above.


[example.org]
https://github.com/alphapapa/org-make-toc/blob/master/example.org


Automatically update on save
════════════════════════════

  To automatically update a file's TOC when the file is saved, use the
  command `add-file-local-variable' to add `org-make-toc' to the Org
  file's `before-save-hook'.

  Or, you may activate it in all Org buffers like this:

  ┌────
  │ (add-hook 'org-mode-hook #'org-make-toc-mode)
  └────
