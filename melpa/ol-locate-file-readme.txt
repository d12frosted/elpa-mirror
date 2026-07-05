This package provides an Org link type that resolves partial file
path substrings into full paths via the `locate' command.  Instead
of writing full absolute paths, write a distinctive substring and
let the package find the file at link-follow time:

    [[lfile:emacsclient][emacsclient]]

Three variants mirror the file: link family:

  - lfile:        => open via `org-file-apps'
  - lfile+emacs:  => always open in Emacs
  - lfile+sys:    => open with system application

When multiple files match, configurable resolution strategies
handle automatic selection or user prompting, with separate
settings for interactive follow vs. export.
