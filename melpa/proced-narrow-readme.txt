This package provides live filtering of processes in proced buffers.  Open proced, call
proced-narrow, and type the query to filter the processes with.  If you type "emacs" then
proced-narrow will filter the processes listed to only the Emacs processes.  While in the
minibuffer, typing RET will exit the minibuffer and leave the proced buffer in the narrowed
state, and typing C-g will exit the minibuffer and restore the list of processes.  While in the
proced buffer, to bring back all processes, call revert-buffer (default bind is g).
