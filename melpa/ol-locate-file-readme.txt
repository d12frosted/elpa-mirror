This package provides an Org link type that resolves partial file path
substrings into full paths using `locate' or a configurable search command.
Instead of typing full absolute paths, you can write a distinctive substring
and let the package resolve the actual file path at link-follow or export
time:

[[lfile:20260707_journal.txt][Daily Journal on 2026-07-07]]

Three variants are provided, mirroring the standard `file:' link type:

- lfile:        => open via `org-file-apps'
- lfile+emacs:  => always open in Emacs
- lfile+sys:    => open with system application

When multiple files match, configurable resolution strategies handle
automatic selection or user prompting, with separate settings for interactive
use versus export.
