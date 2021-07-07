This package provides live filtering of processes in proced buffer.  In general, after calling
proced-narrow you type a filter string into the minibuffer to filter the list of processes.  After
each change proced-narrow automatically reflects the change in the buffer.  Typing C-g will
cancel the narrowing and restore the original view, typing RET will exit the live filtering and
leave the proced buffer in the narrow state.  To bring it back to the original view, you can call
`revert buffer' (usually bound to g).
