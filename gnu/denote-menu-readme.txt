                           ━━━━━━━━━━━━━━━━━
                              DENOTE-MENU

                            Mohamed Suliman
                            sulimanm@tcd.ie
                           ━━━━━━━━━━━━━━━━━





1 Overview
══════════

  `denote-menu' provides an interface for viewing your denote files that
  goes beyond using the standard `dired' emacs command to view your
  `denote-directory'. Using dired is a fine method for viewing your
  denote files (among other things), however denote’s file naming scheme
  tends to clutters the buffer with hyphens and underscores. This
  package aims to declutter your view of your files by making it easy to
  view the 3 main components of denote files, that is their timestamp,
  title, and keywords. Derived from the builtin `tabulated-list-mode',
  the `*Denote*' buffer that is created with the `list-denotes' command
  is visually similar to that created by commands like `list-packages'
  and `list-processes', and provides methods to filter the denote files
  that are shown, as well as exporting to dired with the denote files
  that are currently shown for them to be operated upon further. In this
  way, `denote-menu' adheres to the core tenants of the denote package
  itself.

  It is /predictable/ as it makes use of existing emacs functionality to
  display files in a tabulated way similar to the package menu. It is
  /composable/, integrating well with other emacs packages (denote, in
  this case) and builtin functionality, opting to not reinvent the wheel
  as to how the data is displayed. The scope of this package is narrow:
  displaying and filtering denote files in a visually appealing and
  intuitive manner. `denote-menu' is also /flexible/ and /hackable/,
  providing a simple API to create your own filters, and integrates well
  with dired by providing the `denote-menu-export-to-dired' command,
  which allows for further action on denote files beyond just viewing
  and filtering them.

  <file:screenshots/screenshot.png>


2 Installation
══════════════

  `denote-menu' is available on the GNU ELPA package archive. To
  install, simply run

  ┌────
  │ M-x package-install RET denote-menu RET
  └────


  This package requires Denote `v2.0.0' or above.


3 Usage
═══════

  Assuming that you have `denote-directory' set to a directory that has
  denote files, simply run `M-x list-denotes' to open the `*Denote*'
  buffer. You will be presented with a tabulated list of your denote
  files whose filenames match the `denote-menu-initial-regex' regular
  expression. By default this is set to match all denote files in the
  `denote-directory'.

  The tabulated list includes 3 columns, one for the timestamp, title,
  and keywords of each denote file. The timestamp column includes a
  button that when followed will open the corresponding denote file
  using `find-file'.


3.1 Filtering by regular expression
───────────────────────────────────

  To filter the denote files shown by a regular expression, run `M-x
  denote-menu-filter'. This will prompt for a regular expression and
  will update the buffer to list only those denote files whose filenames
  match. Running `denote-menu-filter' again will further filter down the
  list. This is akin to running `% m' inside a `dired' buffer.


3.2 Filtering by keyword
────────────────────────

  To filter the denote files shown to those that are tagged with
  specific keywords, run `M-x denote-menu-filter-by-keyword'. This
  command will prompt for a list of comma separated keywords (with
  completion) and filter the list to those denote files that are tagged
  with at least one of the inputted keywords. To filter /out/ any denote
  files by keyword, run `M-x denote-menu-filter-out-keyword'.


3.3 Defining your own filters
─────────────────────────────

  There are two ways to define your own filters:
  1. Write an interactive function that sets `denote-menu-current-regex'
     to be a regular expression that matches your desired set of denote
     files, and then calls `denote-menu-update-entries'. For example, if
     I would like to a filter that filters out those denote files that
     were not tagged with the “biblio” keyword, I would add the
     following to my emacs configuration:
     ┌────
     │ (defun my/denote-menu-filter-biblio-only ()
     │   (interactive)
     │   (setq denote-menu-current-regex "_biblio")
     │   (denote-menu-update-entries))
     └────

  2. Write an interactive function that sets `tabulated-list-entries' to
     a be a function that maps each desired denote file path to an entry
     using `denote-menu--path-to-entry' function, and calls
     `revert-buffer'. For example, if the variable
     `my-matching-denote-paths' contains a list of file paths of the
     desired denote files, then your filter function would look
     something like the following:
     ┌────
     │ (defun my/denote-menu-filter-custom ()
     │   (interactive)
     │   (let ((my-matching-denote-paths '("/home/namilus/zettelkasten/20220719T135304--this-is-my-first-note__meta.org")))
     │     (setq tabulated-list-entries (lambda () (mapcar #'denote-menu--path-to-entry my-matching-denote-paths)))
     │     (revert-buffer)))
     └────


3.4 Clearing filters
────────────────────

  To clear the filters and revert back to the
  `denote-menu-initial-regex', run `M-x denote-menu-clear-filters'.


3.5 Exporting to `dired'
────────────────────────

  Adhering to the tenets of predictability and composability,
  `denote-menu' provides the command `denote-menu-export-to-dired' to
  allow further action on these files that is permitted in dired e.g
  copying, moving, compressing, etc. We do not reinvent the wheel here
  but instead defer to what already exists.

  When in the `*Denote*' buffer running `M-x
  denote-menu-export-to-dired' will open a `dired' buffer in the same
  window with those denote files that were displayed in the `*Denote*'
  buffer already marked.


4 Sample configuration
══════════════════════

  The user options for `denote-menu' are:
  `denote-menu-date-column-width'
        A number value for the width of the date column. Defaults to 17.
  `denote-menu-signature-column-width'
        A number value for the width of the signature column. Defaults
        to 10.
  `denote-menu-title-column-width'
        A number value for the width of the title column. Defaults to
        85.
  `denote-menu-keywords-column-width'
        A number value for the width of the keywords column. Defaults to
        30. This value is irrelevant as it is the final column and will
        take up the remaining width of the buffer.
  `denote-menu-show-file-type'
        If non-nil, appends the file type of the current denote file to
        the title.
  `denote-menu-show-file-signature'
        If non-nil, the column for file signature is added.
  `denote-menu-initial-regex'
        A string that is the regular expression that is used to
        initially populate the `*Denote*' buffer with matching
        entries. This could allow for potential workflows such as having
        a dedicated buffer to display your journal denote files (e.g
        those tagged with the “journal” keyword), etc. Defaults to the
        `.' regular expression.
  `denote-menu-action'
        A function that takes as argument the current denote file path
        and performs an action on it. Defaults to `(lambda (path)
        (find-file path))'. This function is then called whenever the
        button in the timestamp column is followed.


  A sample user configuration is given below that sets appropriate
  keybindings for the commands described in the previous section:

  ┌────
  │ (require 'denote-menu)
  │ 
  │ (global-set-key (kbd "C-c z") #'list-denotes)
  │ 
  │ (define-key denote-menu-mode-map (kbd "c") #'denote-menu-clear-filters)
  │ (define-key denote-menu-mode-map (kbd "/ r") #'denote-menu-filter)
  │ (define-key denote-menu-mode-map (kbd "/ k") #'denote-menu-filter-by-keyword)
  │ (define-key denote-menu-mode-map (kbd "/ o") #'denote-menu-filter-out-keyword)
  │ (define-key denote-menu-mode-map (kbd "e") #'denote-menu-export-to-dired)
  └────
