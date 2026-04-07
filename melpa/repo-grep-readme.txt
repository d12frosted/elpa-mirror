`repo-grep' runs a recursive search through the folder structure of your Git
repository, SVN working copy, or plain folder. It uses the symbol under the
cursor as the default search term, which you can edit interactively. The
search term can include a regular expression, and you can configure regex
patterns as a prefix or suffix to further refine the search.

The companion command `repo-grep-multi' extends this to a recursive search
across multiple repositories or folders located in the same parent directory.

Features include:
- VCS-aware project root detection (Git or SVN)
- Manual project root override via `repo-grep-set-root'
- Case sensitivity and binary file handling options
- Customisable include/exclude file patterns
- Clickable results in a standard *grep* buffer
- Optional ripgrep (rg) backend for faster searches
- Optional .gitignore bypass when using the rg backend
- Optional restriction to a subdirectory within the project
  (`repo-grep-set-subfolder', `repo-grep-clear-subfolder')
- Optional multiple grep buffers to keep previous results intact
- Optional in-buffer filtering via `repo-grep-filter'

To bind `repo-grep-filter' to f in grep buffers, call
`repo-grep-setup-keybindings' in your init.el.

For installation, configuration, and usage examples, see the README and
the tutorial at https://github.com/BHFock/repo-grep.
