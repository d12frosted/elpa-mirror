
This package provides `total-recall'.

The command `M-x total-recall' uses Ripgrep to search for Org files in
the directory set by `total-recall-root-dir' that contain
exercises. It lists the exercises from each file and provides a user
interface to view them. The list of exercises follows a depth first
order /i.e./ a bottom-up review order.

Each exercise displays its question first, followed by the answer. The
user's performance—whether they answered correctly—is recorded in an
SQLite database at `total-recall-database'. This data determines when
an exercise should be reviewed next.

An exercise is any Org file heading that meets these criteria:
- Has a `TYPE' property set to `total-recall-type-id'.
- Has an `ID' property with a UUID value.
- Contains two subheadings:
  - The first subheading is the question.
  - The second subheading is the answer.
- Is located in `total-recall-root-dir'.

Example of an exercise:

#+begin_src org
* Emacs
:PROPERTIES:⁣
:TYPE: b0d53cd4-ad89-4333-9ef1-4d9e0995a4d8
:ID: ced2b42b-bfba-4af5-913c-9d903ac78433
:END:

** What is GNU Emacs?

[optional content]

** Answer

An extensible, customizable, free/libre text editor—and more. Its core
is an interpreter for Emacs Lisp, a Lisp dialect with extensions for
text editing.
#+end_src

Exercises can be embedded in any Org Mode document for context:

#+begin_src org
* Title
** Section
*** Sub-section
**** Exercise 1
**** Exercise 2
*** Exercise 3
*** Exercise 4
#+end_src

which would lead to this review order:

1) Title/Section/Sub-section/Exercise 1
2) Title/Section/Sub-section/Exercise 2
3) Title/Section/Exercise 3
4) Title/Section/Exercise 4

which may be pruned by the scheduling algorithm to:

1) Title/Section/Sub-section/Exercise 1
2) Title/Section/Exercise 4

depending on accumulated data so far.

A reference to the exercise in its original content is displayed
as its subject using the format:

[[ref:<ExerciseID>][A/B/C]]

When interpreted with the `locs-and-refs' package, it lets you display
the exercise in context in another frame.
