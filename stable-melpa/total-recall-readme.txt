
`total-recall.el` is a spaced repetition system for Emacs that helps users review and
retain knowledge stored in Org Mode files. It searches for definitions and exercises
in Org files under a configurable root directory, schedules reviews based on past
performance, presents exercises via a user interface, and persists results in a
SQLite database.

* Goals

- Enable users to create and review learning content (definitions and exercises) in
  Org Mode files.
- Implement spaced repetition to optimize retention by scheduling reviews at
  increasing intervals based on success.
- Provide a modular, extensible architecture using an actor model for managing system
  components.
- Offer a customizable UI and configuration options for integration into diverse
  Emacs workflows.

* User Workflows

1. *Setup*:
   - Users configure ~total-recall-root-dir~ for the search directory,
     ~total-recall-database~ for the SQLite database path, and keybindings (e.g.,
     ~total-recall-key-skip~).
   - Org files are created with headings marked by ~:TYPE:~ (matching
     ~total-recall-def-type~ or ~total-recall-ex-type~) and ~:ID:~ (UUIDs).
   - Exercises have subheadings for questions and answers; definitions have content.

2. *Running Total Recall*:
   - Invoke ~M-x total-recall~ to start the system.
   - The system searches for Org files, parses exercises, and selects those due for
     review based on prior ratings.
   - Exercises are shown in a dedicated frame (~UI~), where users press keys to reveal
     answers, mark success/failure/skip, or quit.
   - Results are saved to the database, and a report is displayed in a buffer
     (~total-recall-io-buffer-name~).

3. *Review Process*:
   - For each exercise, users view the question, choose to reveal the answer, and
     rate their performance.
   - The ~Planner~ schedules future reviews: successful reviews double the interval
     (e.g., 1, 2, 4 days), while failures reset the schedule.
   - Definitions are treated as exercises with a fixed question ("* Definition?") and
     content as the answer.

* Example Org File Structure

#+begin_example
,* Topic
:PROPERTIES:
:TYPE: f590edb9-5fa3-4a07-8f3d-f513950d5663
:ID:   123e4567-e89b-12d3-a456-426614174000
:END:
Definition content...

,* Exercise
:PROPERTIES:
:TYPE: b0d53cd4-ad89-4333-9ef1-4d9e0995a4d8
:ID:   789abcde-f012-3456-7890-abcdef123456
:END:

,** Question
What is the capital of France?

,** Answer
The capital of France is Paris.
#+end_example

* Components and Interactions

The system comprises several actors, each handling a specific responsibility:
- *Searcher*: Uses Ripgrep to find Org files containing definitions or exercises,
  identified by UUIDs in ~:ID:~ and ~:TYPE:~ properties.
- *Parser*: Extracts definitions and exercises from Org files in depth-first order,
  converting them into actors (~Definition~ and ~Exercise~).
- *Planner*: Selects exercises due for review based on a spaced repetition algorithm,
  using ratings stored in the database.
- *DB*: Manages persistence of review results (ratings) in a SQLite database, storing
  success, failure, or skip outcomes with timestamps.
- *Clock*: Provides time-related functionality, including current time and review
  scheduling logic.
- *UI*: Displays exercises to the user, collects input (success, failure, skip, quit),
  and shows reports.
- *Report*: Aggregates execution logs for user feedback.
- *IO*: Handles output to a buffer and minibuffer for reports and notifications.
- *TotalRecall*: Orchestrates the workflow, coordinating other actors to search, parse,
  schedule, display, and save results.

The workflow begins with ~total-recall~, which initializes a ~TotalRecall~ actor. This
actor:
1. Uses ~Searcher~ to locate relevant Org files.
2. Employs ~Parser~ to extract exercises and definitions.
3. Filters exercises with ~Planner~ based on review schedules stored in ~DB~.
4. Presents exercises via ~UI~, collecting user ratings.
5. Saves ratings to ~DB~ and generates a ~Report~ for output via ~IO~.

* Extensibility

The actor model allows new components (e.g., alternative UIs or scheduling
algorithms) to be added by defining new actors and messages. Users can customize
keybindings, database paths, and UI dimensions via ~defcustom~ variables.

This system integrates seamlessly with Emacs, leveraging Org Mode for content
management and SQLite for persistence, providing a robust tool for knowledge
retention.
