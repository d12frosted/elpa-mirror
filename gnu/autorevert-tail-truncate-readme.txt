`auto-revert-tail-truncate-mode' is a veneer over
`auto-revert-tail-mode' to automate truncating the tailed buffer to
a user-specified number of lines.  This allows you, for example, to
tail log files in an auto-reverting buffer forever without running
out of memory.  By default, a newly tailed buffer is immediately
truncated for the same reason.  Also, by default, the buffer's undo
log is disabled along with font-lock to both preserve memory and
optimize CPU consumption.

Use the command auto-revert-tail-truncate-file to open a file in a
new buffer with `auto-revert-tail-truncate-mode' enabled.

Add a function to `auto-revert-tail-truncate-mode-hook' to control
additional features in your tailed buffers; e.g., truncate-lines,
controlling so-long-mode threshold, disabling spell checking, or
enabling other minor modes for specific log-file formats (the
visual features of which may require you to enable font-lock for
those buffers).