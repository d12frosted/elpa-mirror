
This package allows to find files in `project-current' or any directory using 'rg --files' command.

As the ripgrep user, I have fine-tuned `.ignore` file in my projects folders to exclude
certain files from grepping.  It turned out that `rg --files` provides the list of only interesting files.

- `find-file-rg'

  Asks for project dir if needed and reads filename with completing function.
  `project-current' is used as the default directory to search in.
  If invoked with prefix argument, always asks for directory to find files in.

- `find-file-rg-at-point'

  Calls `find-file-rg' with active region or filename at point as initial value
  for completing function.
