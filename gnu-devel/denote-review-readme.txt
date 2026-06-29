1 denote-review
═══════════════

  `denote-review' aims to provide a practical and simple manner to
  implement a review process for some of your notes.

  `denote-review' adds a single line to the frontmatter, f.e.:

  `#+reviewdate: [2024-06-12]'

  This line embeds the date of your latest review of the note.

  The format of this line is according to `denote-file-type' (defaults
  to org).


2 Usage
═══════

  The aim is to implement a process for reviewing your denote notes in a
  practical and simple manner.

  Not all notes have to be part of this system. Only notes that contain
  the `reviewdate' field in the frontmatter will be part of it.  The
  `reviewdate' frontmatter can be inserted or updated with a single key
  binding.

  To get started, select a number of denote notes in Dired and bulk
  insert the `reviewdate' frontmatter (see below). Default this inserts
  a review date derived from the identifier in the file name.  With the
  Universal Argument (`C-u') this current date is used as review date.

  On a regular bases, review some notes:

  • Request a list of notes sorted by review date.
  • Review one or more notes and update their review date.


3 Commands
══════════

  • `denote-review-set-date': Insert current date as reviewdate or set
    existing reviewdate to current date.
  • `denote-review-set-date-dired-marked-files': Insert the creation
    date or the current date as review date in notes marked in Dired.
  • `denote-review-display-list': Create a tabulated list of notes order
    by review date.


3.1 Add or update the review date of a note
───────────────────────────────────────────

  Open and revew a denote note. Add or update the date in the the
  frontmatter field `reviewdate'. with the command `M-x
  denote-review-set-date'.

  To make this easy, bind this command to a key, f.e.:

  `(define-key global-map (kbd "C-c n x") #'denote-review-set-date)'

  • When the frontmatter of the note doesn't contain the `reviewdate'
    field, it will be inserted, with the current date as review date.
  • When the `reviewdate' field is already part of the frontmatter, the
    review date will be updated with the current date.

  The default location of the `reviewdate' frontmatter is right below
  the identifier frontmatter line. This can be customized by setting the
  useroption `denote-review-insert-after'.

  For example, to insert the `reviewdate' right below the "date"
  frontmatter, add the following to your Emacs configuration:

  `(setopt denote-review-insert-after "date")'

  Example screenshot of the frontmatter of a note:

  <./images/denote-review-frontmatter.png>


3.2 List notes with a review date
─────────────────────────────────

  The command `M-x denote-review-display-list' creates a tabulated list
  of the notes that contain the `reviewdate' frontmatter. Notes without
  a `reviewdate' are ignored.

  This command prompts for a keyword.  Select a keyword to display only
  notes with that keyword, or don't select any keyword to display all
  notes.

  It evaluates the value of the variables `denote-directory' and
  `denote-silo-directories'. When there is more than one directory, it
  prompts the user to select a directory, using completion.

  Example screenshot of the tabulated list with some notes:

  <./images/denote-review-tabulated-view.png>

  [Note: The filenames in the screenshots based on headers in the README
  from Protesilaos Stavrou, see <https://protesilaos.com/emacs/denote> ]

  Default the list is ordered by review date, from the oldest to the
  newest. Click on a column header to change the order.

  • Click on a column to order according to the column contents.
  • Click again to reverse the order.
  • The key `S' (shift-s) in a column performs the same actions.

  Move point up or down to select a note. Open or view the note with one
  of the keys `RET', `e', or `o'. Or request a random file from the list
  with `r'. After editing and/or updating the review date, refresh the
  list with `g'.

  Key bindings in the tabulated list:

  Specific key bindings:

  • `RET' : Open and edit the note in another window.
  • `e' : Open and edit the note.
  • `o' : Open the note in read only mode in another window.
  • `r' : Open a random note from the list in another window.

  General tabulated list key bindings:

  • `g' : Update the tabulated list.
  • `n' : Goto next line.
  • `p' : Goto previous line.
  • `SPC' : Scroll up.
  • `DEL' : (Backspace) Scroll down.
  • `S-SPC': Scroll down.
  • `q' : Close the buffer with the tabulated list.

  For more, use `M-x describe-mode' (`C-h m') in the buffer.


3.3 Bulk insert a review date according to the identifier
─────────────────────────────────────────────────────────

  There is no undo for this function. To play it safe, first commit your
  notes to a revision management system like Git, or make a backup of
  the directory.

  • Open a denote directory in Dired.
  • Mark one or more notes.
  • Issue the command `M-x denote-review-set-date-dired-marked-files'.

  This will insert the `reviewdate' frontmatter in all selected notes,
  with a date according to the identifier in the filename.

  For example, the note
  `20240117T203111--add-a-query-link__demo_denote.org' will get
  `2024-01-17' as review date.

  Notes where the `reviewdate' field is already part of the frontmatter
  will be left untouched.


3.4 Bulk insert the current date as review date
───────────────────────────────────────────────

  There is no undo for this function. To play it safe, first commit your
  notes to a revision management system like Git, or make a backup of
  the directory.

  How to bulk insert the current date as review date:

  • Open the denote directory in Dired.
  • Mark one or more notes.
  • Enter the Universal Argument `C-u'
  • Issue the command `M-x denote-review-set-date-dired-marked-files'.

  This will insert the `reviewdate' frontmatter in all selected notes,
  with the current date as review date.

  Notes where the `reviewdate' field is already part of the frontmatter,
  will be left untouched.


4 `denote-review-max-search-point'
══════════════════════════════════

  The custom variable `denote-review-max-search-point' defines the point
  where the search-forward command stops.

  Not all notes have to contain the `#+reviewdate' frontmatter.

  `denote-review' uses the `re-search-forward' command to search for the
  `#+reviewdate' frontmatter. To prevent needless searching until the
  end of the file, the command is stopped at the point defined by
  `denote-review-max-search-point'.

  Default this is set at `300'.

  If you use additional frontmatter fields, or for some other reason
  have a large frontmatter, a higher number might be needed. Set the
  point a few lines below your frontmatter and issue the command `C-x ='
  to see what a better value for `denote-review-max-search-point' could
  be.


5 Installation
══════════════

  Install from GNU ELPA.

  ┌────
  │ M-x package-refresh-contents
  │ M-x package-install
  └────


6 Source code. bugs and patches
═══════════════════════════════

  `denote-review' is developed at
  <https://codeberg.org/mattof/denote-review>

  Please use the "Issues" option in the Codeberg repository.


7 Limitations
═════════════

  The file extension of a note does not affect `denote-review'.

  Searching for the review date frontmatter uses a pattern that depends
  on the value of the variable `denote-file-type'.  Just as the format
  for inserting and updating the review date.


8 Contribute
════════════

  A copyright assignment to the FSF is required for all non-trivial code
  contributions.


9 Distribution
══════════════

  `denote-review.el' and all other source files in this directory are
  distributed under the GNU Public License, Version 3, or any later
  version.
