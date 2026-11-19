The `quick-fasd' package integrates the `fasd' command-line utility into
Emacs. The `fasd' cli tracks frequently and recently accessed files and
directories, ranking them by frecency (frequency and recency). Instead of
navigating through directory hierarchies or typing full paths, `quick-fasd'
can quickly find previously accessed files and directories.

The main advantage of `quick-fasd' is that it allows Emacs and the terminal
to share the same Fasd navigation history. For example, a directory
frequently visited from the terminal can be quickly accessed from Emacs, and
files opened in Emacs become available for navigation from the terminal.

After enabling `quick-fasd-mode':

- It automatically adds all visited files and directories to the local Fasd
  database.
- 'M-x quick-fasd-find-path' provides interactive prompts to filter and
  select candidates from the Fasd index. This allows you to open recent files
  and jump to frequent directories without leaving the editor.
- When called from the minibuffer, the `(quick-fasd-find-path)' function
  appends the selected path to the prompt for easier completion.

URL: https://github.com/jamescherti/quick-fasd.el
