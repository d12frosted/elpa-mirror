This file contains library functions and commands useful for
retrieving web page content and processing it into Org-mode
content.

For example, you can copy a URL to the clipboard or kill-ring, then
run a command that downloads the page, isolates the "readable"
content with `eww-readable', converts it to Org-mode content with
Pandoc, and displays it in an Org-mode buffer.  Another command
does all of that but inserts it as an Org entry instead of
displaying it in a new buffer.

;; Commands:

`org-web-tools-insert-link-for-url': Insert an Org-mode link to the
URL in the clipboard or kill-ring.  Downloads the page to get the
HTML title.

`org-web-tools-insert-web-page-as-entry': Insert the web page for
the URL in the clipboard or kill-ring as an Org-mode entry, as a
sibling heading of the current entry.

`org-web-tools-read-url-as-org': Display the web page for the URL
in the clipboard or kill-ring as Org-mode text in a new buffer,
processed with `eww-readable'.

`org-web-tools-convert-links-to-page-entries': With point on a
list of URLs in an Org-mode buffer, replace the list of URLs with a
list of Org headings, each containing the web page content of that
URL, converted to Org-mode text and processed with `eww-readable'.

;; Functions:

These are used in the commands above and may be useful in building
your own commands.

`org-web-tools--dom-to-html': Return parsed HTML DOM as an HTML
string.  Note: This is an approximation and is not necessarily
correct HTML (e.g. IMG tags may be rendered with a closing "</img>"
tag).

`org-web-tools--eww-readable': Return "readable" part of HTML with
title.

`org-web-tools--get-url': Return content for URL as string.

`org-web-tools--html-to-org-with-pandoc': Return string of HTML
converted to Org with Pandoc.

`org-web-tools--url-as-readable-org': Return string containing Org
entry of URL's web page content.  Content is processed with
`eww-readable' and Pandoc.  Entry will be a top-level heading, with
article contents below a second-level "Article" heading, and a
timestamp in the first-level entry for writing comments.

`org-web-tools--demote-headings-below': Demote all headings in
buffer so the highest level is below LEVEL.

`org-web-tools--get-first-url': Return URL in clipboard, or first
URL in the kill-ring, or nil if none.

`org-web-tools--read-org-bracket-link': Return (TARGET . DESCRIPTION)
for Org bracket LINK or next link on current line.

`org-web-tools--remove-dos-crlf': Remove all DOS CRLF (^M) in buffer.
