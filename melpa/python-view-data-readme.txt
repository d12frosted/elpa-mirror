View data in python.

Call `python-view-data-print', select a pandas dataframe, and then a buffer
will pop up with the data listed in a `tabulated-list' table.  Further
verbs can be done, like filter (query), select/unselect, mutate,
group/ungroup, count, unique, describe, etc.  It can be reset
(`python-view-data-reset') any time.

The data is retrieved through a small protocol (`__pv_page') sent to the
inferior Python process.  Data is transferred as tab-separated text, which
makes it robust to the encoding used by the process.

In the table view the column header is rebuilt on every redisplay from the
window's horizontal scroll (a buffer-local `pre-redisplay-functions' hook),
so the header stays aligned with the data columns when the table is wider
than the window and is scrolled horizontally.
