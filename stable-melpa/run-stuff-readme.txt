Run commands from the region or current line,
with some simple specifiers to control behavior.

; Usage

(run-stuff-command-on-region-or-line)

A command to execute the current selection or the current line
using the default `run-stuff-handlers' variable.

- '$ ' Run in terminal.
- '@ ' Open in an Emacs buffer.
- '~ ' Open with default mime type (works for paths too).
- 'http://' or 'https://' opens in a web-browser.
- Open in terminal if its a directory.
- Default to running the command without a terminal
  when none of the conditions above succeed.

Note that there is support for line splitting,
so long commands may be split over multiple lines.
This is done using the '\' character, when executing the current line
all surrounding lines which end with '\' will be included.

So you can for define a shell command as follows:

$ make \
  -C /my/project \
  --no-print-directory \
  --keep-going

The entire block will be detected so you can run the command
with your cursor over any of these lines, without needing to move to the first.
