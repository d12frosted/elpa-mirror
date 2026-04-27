bible-gateway is a simple package that fetches content from
[BibleGateway.com](http://BibleGateway.com). It can:

- Fetch and display the Bible verse of the day
- Insert Bible passages/chapters at point or in a dedicated buffer
- Open audio chapters in your browser
- Search the Bible by keyword and display results in a dedicated buffer with
  clickable references and pagination
- Follow a daily reading plan from a CSV file

Usage:

A transient menu (M-x `bible-gateway') gives access to all the
commands above.

`bible-gateway-get-verse' fetches the verse of the day for use as
an emacs-dashboard footer or a scratch buffer message.

M-x `bible-gateway-get-passage' fetches a Bible passage and inserts
it at point. It can be called both interactively from
\\[execute-extended-command] or programmatically with the book name
and verse(s) as arguments.

M-x `bible-gateway-read-passage' works like `bible-gateway-get-passage'
but displays the passage in a dedicated buffer in `text-mode'.

M-x `bible-gateway-listen-passage' plays a Bible chapter from KJV
Zondervan Audio in the browser.

M-x `bible-gateway-search' prompts for a search query, fetches results
from BibleGateway, and displays them in a dedicated buffer.

M-x `bible-gateway-read-today' fetches all of today's passages from
the active reading plan (set via `bible-gateway-reading-plan') and
displays them in a single buffer.
