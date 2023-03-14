Org-Babel support for evaluating d2 diagram scripting source code.

d2 differs from most standard languages in that:

1) there is no such thing as a "session" in d2

2) we are only going to return results of type "file"

3) you can specify `:flags' headers to be passed to the `d2' command

4) there are no variables (at least for now)

; Requirements:

- You must have d2 installed and d2 should be in your `exec-path'. If not,
  feel free to modify `ob-d2-command' to the location of your d2
  command.

- `d2-mode' is also recommended for syntax highlighting and formatting,
  however it is not required.
