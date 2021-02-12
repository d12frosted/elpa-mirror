Smart region guesses what you want to select by one command:

- If you call this command multiple times at the same position, it
  expands the selected region (with `er/expand-region').
- Else, if you move from the mark and call this command, it selects
  the region rectangular (with `rectangle-mark-mode').
- Else, if you move from the mark and call this command at the same
  column as mark, it adds a cursor to each line (with `mc/edit-lines').

This basic concept is from sense-region: https://gist.github.com/tnoda/1776988.
