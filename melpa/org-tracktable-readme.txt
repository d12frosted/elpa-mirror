The package provides these three interactive functions:

- org-tracktable-insert-table: inserts a table to keep track of word count
  in an org-mode buffer.
- org-tracktable-write: adds an entry with the current word count to the
  table. You only need to do this when you're done writing for the
  day. If an entry for the current day already exists, this entry
  will be updated.
- org-tracktable-status: messages the total word count in the buffer, or
  region if active. If the table inserted by org-tracktable-insert-table
  exists, the count of words written the current day is shown
  together with percentage of your daily writing goal.

These three variables can be customized:

- org-tracktable-day-delay: hours after midnight for new day to start.
- org-tracktable-daily-goal: The number of words you pan to write each day.
- org-tracktable-table-name: The name given to the table inserted by
  org-tracktable-insert-table.

For additional info on use and customization, see the README in the
github repo.

Implementation is based on:
- Simon Guest's org-wc.el:
  https://github.com/dato/org-wc/blob/master/org-wc.el
- Lit Wakefield's chronicler.el:
  https://github.com/noctuid/chronicler
