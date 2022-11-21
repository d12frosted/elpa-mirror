This package defines a set of functions and variables for running
instruction-following language models like GPT-3.  It allows the
user to enter a command with history and completion, and optionally
use the current region as input.  The output of the command is
displayed in a temporary buffer with the same major mode as the
original buffer.  The output is streamed as it is produced by the
GPT process.  The user can view and export the command history to a
file.
