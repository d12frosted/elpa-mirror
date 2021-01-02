This file contains library functions and commands useful for
retrieving web page content and processing it into Org-mode
content.

For example, you can copy a URL to the clipboard or kill-ring, then
run a command that downloads the page, isolates the "readable"
content with `eww-readable', converts it to Org-mode content with
Pandoc, and displays it in an Org-mode buffer.  Another command
does all of that but inserts it as an Org entry instead of
displaying it in a new buffer.
