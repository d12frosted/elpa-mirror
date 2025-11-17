org-tag-tree lets you describe Org tag hierarchies as ordinary Org trees.

By default, Org tag hierarchies are defined with the #+TAGS: syntax:

#+TAGS: [ GTD : Control Persp ]
#+TAGS: [ Control : Context Task ]
#+TAGS: [ Persp : Vision Goal ]

Or defined globally:

(setq org-tag-alist
      '((:startgrouptag)("GTD")(:grouptags)("Control")("Persp")(:endgrouptag)
        (:startgrouptag)("Control")(:grouptags)("Context")("Task")(:endgrouptag)
        (:startgrouptag)("Persp")(:grouptags)("Vision")("Goal")(:endgrouptag)))

org-tag-tree lets you express the same hierarchy directly in an Org outline:

* GTD                    :tag:
** Control
*** Context
    Used for each context (e.g. @home, @work)
*** Task
    Use for task-level tags
** Persp
*** Vision
    Long-term, big-picture items
*** Goal
    Concrete outcomes to measure progress

This keeps the tag inheritance visible in the document structure and lets you
include descriptions, examples, or usage notes for each tag node.
