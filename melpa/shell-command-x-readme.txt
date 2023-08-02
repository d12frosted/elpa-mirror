`shell-command-x-mode' provides an assortment of extensions for the
interactive Emacs shell commands \\[shell-command] and
\\[async-shell-command].  Its primary features are:

- The names of process buffers can be customized on a per-command basis; for
  example, the buffer name for the command `ls -la' can be automatically set
  to `*shell:ls*', `*shell:ls -la*', or any other number of desired values.

- When a command completes, its output buffer can emulate `special-mode';
  this is useful for quickly dismissing (with \\[quit-window]) or quickly
  re-running the command (with \\[revert-buffer]).

- When a command completes, the point can be moved to the beginning of the
  output buffer if the command wasn't interactive; this is useful for paging
  through the output of commands like `grep --help'.

Refer to the project homepage for a slightly more detailed overview and usage
tips.
